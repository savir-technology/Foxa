<?php
/**
 * One-time CLI migration for the Jeeb master portals.
 *
 * Run on the backend server with:
 *   php dash/master_auth/seed_portal_accounts.php
 * Then verify with:
 *   php dash/master_auth/verify_portal_accounts.php
 *
 * It is intentionally CLI-only so the initial credentials cannot be used as
 * a public provisioning endpoint. Existing accounts are updated by email so
 * the migration is repeatable.
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit("CLI only\n");
}

require_once __DIR__ . '/../../connect.php';
ensureMasterAuthSchema();

foreach (['master_account_type', 'master_portal_key', 'master_approval_status', 'master_approved_at'] as $column) {
    if (!columnExists('admin', $column)) {
        throw new RuntimeException(
            'The admin table is missing ' . $column . '. Apply migrations/20260909_master_auth_accounts.sql first.'
        );
    }
}

$password = getenv('JEEB_MASTER_BOOTSTRAP_PASSWORD');
if (!is_string($password) || $password === '') {
    throw new RuntimeException(
        'Set JEEB_MASTER_BOOTSTRAP_PASSWORD in the server environment before running this command.'
    );
}
$password = trim($password);
if (strlen($password) < 8) {
    throw new RuntimeException('JEEB_MASTER_BOOTSTRAP_PASSWORD must be at least 8 characters.');
}
$passwordHash = password_hash($password, PASSWORD_DEFAULT);

$portals = [
    [
        'role_id' => 10,
        'role_name' => 'Finance Manager',
        'role_scope' => 'Jeeb financial portal',
        'email' => 'finance@maer.app',
        'name' => 'Jeeb Finance',
        'permissions' => ['finance.view', 'finance.refund', 'finance.withdrawals', 'finance.wallets', 'finance.fees', 'finance.expenses', 'finance.settlements', 'coupons.view', 'coupons.create', 'coupons.edit', 'coupons.delete', 'reports.view', 'reports.export'],
        'tint' => '#F59E0B',
    ],
    [
        'role_id' => 11,
        'role_name' => 'Support Manager',
        'role_scope' => 'Jeeb technical support portal',
        'email' => 'support@maer.app',
        'name' => 'Jeeb Support',
        'permissions' => ['support.view', 'support.reply', 'support.assign', 'customers.view', 'drivers.view', 'restaurants.view', 'orders.view'],
        'tint' => '#EC4899',
    ],
    [
        'role_id' => 12,
        'role_name' => 'Operations Manager',
        'role_scope' => 'Jeeb operations portal',
        'email' => 'operations@maer.app',
        'name' => 'Jeeb Operations',
        'permissions' => ['orders.view', 'orders.edit', 'orders.cancel', 'orders.assign_driver', 'drivers.view', 'drivers.edit', 'drivers.approve', 'drivers.reject', 'drivers.suspend', 'restaurants.view', 'restaurants.approve', 'restaurants.reject', 'customers.view', 'customers.block', 'settings.view', 'settings.edit'],
        'tint' => '#2563EB',
    ],
    [
        'role_id' => 13,
        'role_name' => 'Merchants Manager',
        'role_scope' => 'Jeeb restaurants and stores portal',
        'email' => 'merchants@maer.app',
        'name' => 'Jeeb Merchants',
        'permissions' => ['restaurants.view', 'restaurants.approve', 'restaurants.reject', 'restaurants.suspend', 'restaurants.delete', 'restaurants.edit', 'marketing.view', 'marketing.create', 'marketing.edit', 'marketing.delete', 'coupons.view', 'coupons.create', 'coupons.edit', 'coupons.delete'],
        'tint' => '#10B981',
    ],
    [
        'role_id' => 14,
        'role_name' => 'Analytics Manager',
        'role_scope' => 'Jeeb monitoring and analytics portal',
        'email' => 'analytics@maer.app',
        'name' => 'Jeeb Analytics',
        'permissions' => ['reports.view', 'reports.export', 'orders.view', 'customers.view', 'drivers.view', 'restaurants.view', 'finance.view', 'marketing.view'],
        'tint' => '#8B5CF6',
    ],
    [
        'role_id' => 15,
        'role_name' => 'Legal and Security Manager',
        'role_scope' => 'Jeeb security and legal portal',
        'email' => 'legal@maer.app',
        'name' => 'Jeeb Legal',
        'permissions' => ['settings.view', 'settings.edit', 'administration.view', 'reports.view'],
        'tint' => '#64748B',
    ],
];

$roleStmt = $con->prepare("
    INSERT INTO master_role_profiles
        (role_id, role_name, role_scope, permissions_json, tint_hex, sort_order)
    VALUES
        (:role_id, :role_name, :role_scope, :permissions_json, :tint_hex, :sort_order)
    ON DUPLICATE KEY UPDATE
        role_name = IF(role_name = '', VALUES(role_name), role_name),
        role_scope = IF(role_scope = '', VALUES(role_scope), role_scope),
        permissions_json = VALUES(permissions_json),
        tint_hex = IF(tint_hex = '' OR tint_hex IS NULL, VALUES(tint_hex), tint_hex),
        sort_order = IF(sort_order = 0, VALUES(sort_order), sort_order)
");

$accountStmt = $con->prepare("
    INSERT INTO admin
        (admin_name, admin_password, admin_email, admin_phone, admin_approve, admin_role_id,
         master_account_type, master_portal_key, master_approval_status, master_approved_at)
    VALUES
        (:admin_name, :admin_password, :admin_email, :admin_phone, 1, :admin_role_id,
         :master_account_type, :master_portal_key, 'approved', NOW())
    ON DUPLICATE KEY UPDATE
        admin_name = VALUES(admin_name),
        admin_password = VALUES(admin_password),
        admin_approve = 1,
        admin_role_id = VALUES(admin_role_id),
        master_account_type = VALUES(master_account_type),
        master_portal_key = VALUES(master_portal_key),
        master_approval_status = 'approved',
        master_approved_at = NOW(),
        master_rejection_reason = NULL
");

$permissionStmt = $con->prepare("INSERT IGNORE INTO master_role_permissions (role_id, permission_key) VALUES (:role_id, :permission_key)");
$existingRoleStmt = $con->prepare('SELECT permissions_json FROM master_role_profiles WHERE role_id = :role_id LIMIT 1');

foreach ($portals as $index => $portal) {
    $permissions = array_values(array_unique($portal['permissions']));
    array_unshift($permissions, 'dashboard.view');
    $permissions = array_values(array_unique($permissions));
    $existingRoleStmt->execute([':role_id' => $portal['role_id']]);
    $existingPermissions = json_decode((string)$existingRoleStmt->fetchColumn(), true);
    $hasExistingPermissions = is_array($existingPermissions) && $existingPermissions !== [];
    if ($hasExistingPermissions) {
        $permissions = array_values(array_unique(array_merge($permissions, $existingPermissions)));
    }
    $roleStmt->execute([
        ':role_id' => $portal['role_id'],
        ':role_name' => $portal['role_name'],
        ':role_scope' => $portal['role_scope'],
        ':permissions_json' => json_encode($permissions, JSON_UNESCAPED_UNICODE),
        ':tint_hex' => $portal['tint'],
        ':sort_order' => $index + 10,
    ]);
    if (!$hasExistingPermissions) {
        $con->prepare('DELETE FROM master_role_permissions WHERE role_id = :role_id')->execute([':role_id' => $portal['role_id']]);
    }
    foreach ($permissions as $permission) {
        $permissionStmt->execute([
            ':role_id' => $portal['role_id'],
            ':permission_key' => $permission,
        ]);
    }
    $accountStmt->execute([
        ':admin_name' => $portal['name'],
        ':admin_password' => $passwordHash,
        ':admin_email' => $portal['email'],
        ':admin_phone' => '',
        ':admin_role_id' => $portal['role_id'],
        ':master_account_type' => 'employee',
        ':master_portal_key' => array_search($portal['role_id'], array_column($portals, 'role_id'), true) !== false
            ? ['finance', 'support', 'operations', 'merchants', 'analytics', 'legal'][$index]
            : null,
    ]);
}

$jokerRolePermissions = json_encode(['*', 'super_admin'], JSON_UNESCAPED_UNICODE);
$con->prepare("UPDATE master_role_profiles SET permissions_json = :permissions_json WHERE role_id = 1")
    ->execute([':permissions_json' => $jokerRolePermissions]);
$con->prepare("UPDATE master_role_permissions SET permission_key = permission_key WHERE role_id = 1")
    ->execute();
$accountStmt->execute([
    ':admin_name' => 'Jeeb Master Joker',
    ':admin_password' => $passwordHash,
    ':admin_email' => 'm_jeeb@maer.app',
    ':admin_phone' => '',
    ':admin_role_id' => 1,
    ':master_account_type' => 'super_admin',
    ':master_portal_key' => null,
]);

echo "Jeeb portal accounts provisioned successfully.\n";
