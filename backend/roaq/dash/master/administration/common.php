<?php

/**
 * التحقق من وجود عمود في جدول معين
 * @param string $tableName اسم الجدول
 * @param string $columnName اسم العمود
 * @return bool
 */
if (!function_exists('columnExists')) {
function columnExists(string $tableName, string $columnName): bool
{
    global $con;
    try {
        $stmt = $con->prepare("
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table_name
              AND COLUMN_NAME = :column_name
            LIMIT 1
        ");
        $stmt->execute([
            ':table_name' => $tableName,
            ':column_name' => $columnName,
        ]);
        return (bool)$stmt->fetchColumn();
    } catch (Exception $e) {
        error_log("Error checking column existence: " . $e->getMessage());
        return false;
    }
}
}

/**
 * التحقق من وجود جدول في قاعدة البيانات
 * @param string $tableName اسم الجدول
 * @return bool
 */
if (!function_exists('tableExists')) {
function tableExists(string $tableName): bool
{
    global $con;
    try {
        $stmt = $con->prepare("
            SELECT 1
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table_name
            LIMIT 1
        ");
        $stmt->execute([':table_name' => $tableName]);
        return (bool)$stmt->fetchColumn();
    } catch (Exception $e) {
        error_log("Error checking table existence: " . $e->getMessage());
        return false;
    }
}

}

function adminModuleIsSuperAdmin(array $admin): bool
{
    return (int)($admin['admin_role_id'] ?? $admin['master_role_id'] ?? 0) === 1
        || masterHasPermission($admin, 'super_admin');
}

function adminModuleRequireSuperAdmin(array $admin): void
{
    if (!adminModuleIsSuperAdmin($admin)) {
        respondJson([
            'status' => 'error',
            'message' => 'Only the Super Admin can perform this action',
        ], 403);
    }
}

/**
 * A role manager may only delegate permissions that they themselves hold.
 * Super Admin is the sole exception and may delegate any registered permission.
 */
function adminModuleFilterDelegatedPermissions(array $admin, array $permissions): array
{
    $permissions = array_values(array_unique(array_filter(array_map('strval', $permissions), static function ($key) {
        return trim($key) !== '';
    })));

    if (adminModuleIsSuperAdmin($admin)) {
        return array_values(array_filter($permissions, static function ($key) {
            return $key !== '*' && $key !== 'super_admin';
        }));
    }

    $allowed = array_flip(masterPermissionKeysFromAdmin($admin));
    $result = [];
    foreach ($permissions as $permission) {
        if ($permission !== '*' && $permission !== 'super_admin' && isset($allowed[$permission])) {
            $result[] = $permission;
        }
    }
    return array_values(array_unique($result));
}

function adminModuleRejectUndelegablePermissions(array $admin, array $permissions): void
{
    $filtered = adminModuleFilterDelegatedPermissions($admin, $permissions);
    $requested = array_values(array_unique(array_filter(array_map('strval', $permissions), static function ($key) {
        return trim($key) !== '' && $key !== '*' && $key !== 'super_admin';
    })));
    $invalid = array_values(array_diff($requested, $filtered));
    if ($invalid !== []) {
        respondJson([
            'status' => 'error',
            'message' => 'You cannot delegate permissions that you do not have',
            'undelegable_permissions' => $invalid,
        ], 403);
    }
}

function adminModulePermissionRows(): array
{
    global $con;
    $rows = [];
    if (!tableExists('master_permissions')) {
        return $rows;
    }

    $stmt = $con->query("
        SELECT permission_key, permission_group, permission_label
        FROM master_permissions
        ORDER BY permission_group ASC, permission_label ASC, permission_key ASC
    ");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $rows[] = [
            'permission_key' => (string)($row['permission_key'] ?? ''),
            'permission_group' => (string)($row['permission_group'] ?? ''),
            'permission_label' => (string)($row['permission_label'] ?? ''),
        ];
    }

    // Keep newly introduced governance capabilities visible even when an older
    // database dump has not yet been re-imported with the latest catalog rows.
    $knownKeys = array_column($rows, 'permission_key');
    foreach ([
        ['returns.view', 'Returns', 'View supplier returns'],
        ['returns.edit', 'Returns', 'Update supplier return status'],
    ] as $fallback) {
        if (!in_array($fallback[0], $knownKeys, true)) {
            $rows[] = [
                'permission_key' => $fallback[0],
                'permission_group' => $fallback[1],
                'permission_label' => $fallback[2],
            ];
        }
    }
    return $rows;
}

function adminModuleRolePermissions(int $roleId, $fallbackJson = '[]'): array
{
    global $con;
    $permissions = [];
    if (is_string($fallbackJson)) {
        $decoded = json_decode($fallbackJson, true);
        if (is_array($decoded)) {
            $permissions = array_map('strval', $decoded);
        }
    } elseif (is_array($fallbackJson)) {
        $permissions = array_map('strval', $fallbackJson);
    }

    if ($roleId > 0 && tableExists('master_role_permissions')) {
        $stmt = $con->prepare("
            SELECT permission_key
            FROM master_role_permissions
            WHERE role_id = :role_id
            ORDER BY permission_key ASC
        ");
        $stmt->execute([':role_id' => $roleId]);
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $permissions[] = (string)($row['permission_key'] ?? '');
        }
    }

    return array_values(array_unique(array_filter($permissions, static function ($key) {
        return trim((string)$key) !== '';
    })));
}

function adminModuleRoleRows(): array
{
    global $con;
    $rows = [];
    $stmt = $con->query("
        SELECT
            rp.role_id,
            rp.role_name,
            rp.role_scope,
            rp.permissions_json,
            rp.tint_hex,
            rp.sort_order,
            COUNT(a.admin_id) AS admin_count
        FROM master_role_profiles rp
        LEFT JOIN admin a ON a.admin_role_id = rp.role_id
        GROUP BY rp.role_id, rp.role_name, rp.role_scope, rp.permissions_json, rp.tint_hex, rp.sort_order
        ORDER BY rp.sort_order ASC, rp.role_id ASC
    ");

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $roleId = (int)($row['role_id'] ?? 0);
        $permissions = adminModuleRolePermissions($roleId, $row['permissions_json'] ?? '[]');
        $rows[] = [
            'role_id' => $roleId,
            'role_name' => (string)($row['role_name'] ?? ''),
            'role_scope' => (string)($row['role_scope'] ?? ''),
            'permissions' => $permissions,
            'permissions_json' => json_encode($permissions, JSON_UNESCAPED_UNICODE),
            'tint_hex' => (string)($row['tint_hex'] ?? '#3B82F6'),
            'sort_order' => (int)($row['sort_order'] ?? 0),
            'admin_count' => (int)($row['admin_count'] ?? 0),
        ];
    }
    return $rows;
}

function adminModuleAdminRows(): array
{
    global $con;
    $rows = [];
    $stmt = $con->query("
        SELECT
            a.admin_id,
            a.admin_name,
            a.admin_email,
            a.admin_phone,
            a.admin_profile_image,
            a.admin_approve,
            a.admin_role_id,
            a.admin_last_login_at,
            a.admin_create,
            rp.role_name,
            rp.role_scope,
            rp.tint_hex
        FROM admin a
        LEFT JOIN master_role_profiles rp ON rp.role_id = a.admin_role_id
        ORDER BY a.admin_create DESC, a.admin_id DESC
    ");

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $approved = (int)($row['admin_approve'] ?? 0) === 1;
        $status = $approved ? 'نشط' : 'معطل';
        $roleLabel = trim((string)($row['role_name'] ?? ''));
        if ($roleLabel === '') {
            $roleLabel = 'Role #' . (int)($row['admin_role_id'] ?? 0);
        }
        $rows[] = [
            'admin_id' => (int)($row['admin_id'] ?? 0),
            'name' => (string)($row['admin_name'] ?? ''),
            'admin_name' => (string)($row['admin_name'] ?? ''),
            'email' => (string)($row['admin_email'] ?? ''),
            'admin_email' => (string)($row['admin_email'] ?? ''),
            'phone' => (string)($row['admin_phone'] ?? ''),
            'admin_phone' => (string)($row['admin_phone'] ?? ''),
            'profile_image' => $row['admin_profile_image'] ?? null,
            'admin_profile_image' => $row['admin_profile_image'] ?? null,
            'role_id' => (int)($row['admin_role_id'] ?? 0),
            'admin_role_id' => (int)($row['admin_role_id'] ?? 0),
            'role_label' => $roleLabel,
            'role_name' => $roleLabel,
            'department' => (string)($row['role_scope'] ?? 'Master Dashboard'),
            'job_title' => $roleLabel,
            'status' => $status,
            'status_key' => $approved ? 'active' : 'disabled',
            'status_hex' => $approved ? '#1A8B4A' : '#D92C2C',
            'account_status' => $status,
            'last_login' => (string)($row['admin_last_login_at'] ?? ''),
            'admin_last_login_at' => $row['admin_last_login_at'] ?? null,
            'created_at' => (string)($row['admin_create'] ?? ''),
            'admin_create' => $row['admin_create'] ?? null,
            'avatar_hex' => (string)($row['tint_hex'] ?? '#1A8B4A'),
            'is_super_admin' => (int)($row['admin_role_id'] ?? 0) === 1,
        ];
    }
    return $rows;
}

function adminModuleSyncRolePermissions(int $roleId, array $permissions): void
{
    global $con;
    $permissions = array_values(array_unique(array_filter(array_map('strval', $permissions), static function ($key) {
        return trim($key) !== '';
    })));

    $json = json_encode($permissions, JSON_UNESCAPED_UNICODE);
    $stmt = $con->prepare("UPDATE master_role_profiles SET permissions_json = :permissions_json WHERE role_id = :role_id");
    $stmt->execute([':permissions_json' => $json, ':role_id' => $roleId]);

    if (!tableExists('master_role_permissions')) {
        return;
    }

    $deleteStmt = $con->prepare("DELETE FROM master_role_permissions WHERE role_id = :role_id");
    $deleteStmt->execute([':role_id' => $roleId]);

    $insertStmt = $con->prepare("
        INSERT IGNORE INTO master_role_permissions (role_id, permission_key)
        VALUES (:role_id, :permission_key)
    ");
    foreach ($permissions as $permission) {
        $insertStmt->execute([
            ':role_id' => $roleId,
            ':permission_key' => $permission,
        ]);
    }
}
