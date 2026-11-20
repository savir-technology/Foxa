<?php
/**
 * Read-only CLI verification for Jeeb Master portal accounts.
 *
 * Run after seed_portal_accounts.php:
 *   php dash/master_auth/verify_portal_accounts.php
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit("CLI only\n");
}

require_once __DIR__ . '/../../connect.php';
ensureMasterPortalRoles();

foreach (['master_account_type', 'master_portal_key', 'master_approval_status'] as $column) {
    if (!columnExists('admin', $column)) {
        fwrite(STDERR, "The admin table is missing {$column}; apply the master auth migration first.\n");
        exit(2);
    }
}

$expected = [
    'm_jeeb@maer.app' => [
        'type' => 'super_admin',
        'portal' => null,
        'permissions' => ['super_admin'],
    ],
    'finance@maer.app' => [
        'type' => 'employee',
        'portal' => 'finance',
        'permissions' => ['finance.view', 'finance.wallets', 'finance.fees', 'finance.expenses', 'finance.settlements', 'reports.view', 'reports.export'],
    ],
    'support@maer.app' => [
        'type' => 'employee',
        'portal' => 'support',
        'permissions' => ['support.view', 'support.reply'],
    ],
    'operations@maer.app' => [
        'type' => 'employee',
        'portal' => 'operations',
        'permissions' => ['orders.view', 'orders.edit', 'drivers.view', 'drivers.edit', 'settings.edit'],
    ],
    'merchants@maer.app' => [
        'type' => 'employee',
        'portal' => 'merchants',
        'permissions' => ['restaurants.view', 'restaurants.edit', 'marketing.view'],
    ],
    'analytics@maer.app' => [
        'type' => 'employee',
        'portal' => 'analytics',
        'permissions' => ['reports.view', 'reports.export'],
    ],
    'legal@maer.app' => [
        'type' => 'employee',
        'portal' => 'legal',
        'permissions' => ['settings.view', 'settings.edit', 'administration.view'],
    ],
];

$stmt = $con->prepare("SELECT
        a.admin_email,
        a.admin_approve,
        a.admin_role_id,
        a.master_account_type,
        a.master_portal_key,
        a.master_approval_status,
        rp.permissions_json
    FROM admin a
    LEFT JOIN master_role_profiles rp ON rp.role_id = a.admin_role_id
    WHERE LOWER(a.admin_email) = :email
    LIMIT 1");

$failed = false;
foreach ($expected as $email => $requirements) {
    $stmt->execute([':email' => $email]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    if (!$row) {
        echo "MISSING {$email}\n";
        $failed = true;
        continue;
    }

    $permissions = json_decode((string)($row['permissions_json'] ?? '[]'), true);
    $permissions = is_array($permissions) ? array_map('strval', $permissions) : [];
    $missing = array_values(array_diff($requirements['permissions'], $permissions));
    $valid = (int)$row['admin_approve'] === 1
        && strtolower((string)$row['master_approval_status']) === 'approved'
        && (string)$row['master_account_type'] === $requirements['type']
        && (string)($row['master_portal_key'] ?? '') === (string)($requirements['portal'] ?? '')
        && $missing === [];

    echo ($valid ? 'OK ' : 'FAIL ') . $email
        . ' role=' . (int)$row['admin_role_id']
        . ' type=' . (string)$row['master_account_type']
        . ' portal=' . ((string)($row['master_portal_key'] ?? '') ?: '-')
        . ' approval=' . (string)$row['master_approval_status'];
    if ($missing !== []) {
        echo ' missing=' . implode(',', $missing);
    }
    echo "\n";
    $failed = $failed || !$valid;
}

if ($failed) {
    fwrite(STDERR, "Portal account verification failed.\n");
    exit(1);
}

echo "All Jeeb Master portal accounts are ready.\n";
