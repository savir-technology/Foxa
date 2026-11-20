<?php
require_once "../../../connect.php";
require_once __DIR__ . "/common.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function rolePayload(): array
{
    $payload = json_decode(file_get_contents("php://input"), true);
    if (!is_array($payload)) {
        $payload = $_POST;
    }
    return is_array($payload) ? $payload : [];
}

function nextRoleId(): int
{
    global $con;
    return (int)$con->query("SELECT COALESCE(MAX(role_id), 0) + 1 FROM master_role_profiles")->fetchColumn();
}

function normalizePermissionsPayload($value): array
{
    if (is_string($value)) {
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            $value = $decoded;
        } elseif (trim($value) !== '') {
            $value = preg_split('/[,\n|]+/', $value);
        } else {
            $value = [];
        }
    }
    if (!is_array($value)) {
        return [];
    }
    return array_values(array_unique(array_filter(array_map(static function ($permission) {
        return trim((string)$permission);
    }, $value), static function ($permission) {
        return $permission !== '';
    })));
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'administration.manage_roles');

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        respondJson([
            'status' => 'success',
            'data' => [
                'roles' => adminModuleRoleRows(),
                'permissions' => adminModulePermissionRows(),
            ],
        ]);
    }

    $payload = rolePayload();
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : $payload;
    $roleId = (int)($payload['role_id'] ?? $data['role_id'] ?? 0);

    if ($action === '') {
        respondJson(['status' => 'error', 'message' => 'action is required'], 400);
    }

    if ($action === 'create') {
        $roleName = trim((string)($data['role_name'] ?? ''));
        $roleScope = trim((string)($data['role_scope'] ?? ''));
        $permissions = normalizePermissionsPayload($data['permissions'] ?? $data['permissions_json'] ?? []);
        $tintHex = trim((string)($data['tint_hex'] ?? '#3B82F6'));
        $sortOrder = (int)($data['sort_order'] ?? 100);

        if ($roleName === '') {
            respondJson(['status' => 'error', 'message' => 'role_name is required'], 400);
        }
        adminModuleRejectUndelegablePermissions($admin, $permissions);

        $roleId = nextRoleId();
        $stmt = $con->prepare("
            INSERT INTO master_role_profiles (
                role_id,
                role_name,
                role_scope,
                permissions_json,
                tint_hex,
                sort_order
            ) VALUES (
                :role_id,
                :role_name,
                :role_scope,
                :permissions_json,
                :tint_hex,
                :sort_order
            )
        ");
        $stmt->execute([
            ':role_id' => $roleId,
            ':role_name' => $roleName,
            ':role_scope' => $roleScope,
            ':permissions_json' => json_encode($permissions, JSON_UNESCAPED_UNICODE),
            ':tint_hex' => $tintHex !== '' ? $tintHex : '#3B82F6',
            ':sort_order' => $sortOrder,
        ]);
        adminModuleSyncRolePermissions($roleId, $permissions);

        respondJson([
            'status' => 'success',
            'message' => 'Role created',
            'data' => ['role_id' => $roleId],
        ]);
    }

    if ($roleId <= 0) {
        respondJson(['status' => 'error', 'message' => 'role_id is required'], 400);
    }
    if ($roleId === 1 && $action !== 'assign_permissions' && $action !== 'update') {
        respondJson(['status' => 'error', 'message' => 'The Super Admin role cannot be deleted or disabled'], 403);
    }

    if ($action === 'update' || $action === 'assign_permissions') {
        $currentStmt = $con->prepare("SELECT * FROM master_role_profiles WHERE role_id = :role_id LIMIT 1");
        $currentStmt->execute([':role_id' => $roleId]);
        $current = $currentStmt->fetch(PDO::FETCH_ASSOC);
        if (!$current) {
            respondJson(['status' => 'error', 'message' => 'Role not found'], 404);
        }

        $roleName = trim((string)($data['role_name'] ?? $current['role_name'] ?? ''));
        $roleScope = trim((string)($data['role_scope'] ?? $current['role_scope'] ?? ''));
        $permissions = normalizePermissionsPayload($data['permissions'] ?? $data['permissions_json'] ?? adminModuleRolePermissions($roleId, $current['permissions_json'] ?? '[]'));
        $tintHex = trim((string)($data['tint_hex'] ?? $current['tint_hex'] ?? '#3B82F6'));
        $sortOrder = (int)($data['sort_order'] ?? $current['sort_order'] ?? 100);

        if ($roleId === 1) {
            adminModuleRequireSuperAdmin($admin);
            $allPermissionKeys = array_map(static function ($row) {
                return $row['permission_key'];
            }, adminModulePermissionRows());
            $permissions = array_values(array_unique(array_merge($allPermissionKeys, ['super_admin'])));
            $roleName = 'Super Admin';
            $roleScope = 'Full platform administration access';
        } else {
            adminModuleRejectUndelegablePermissions($admin, $permissions);
        }

        $stmt = $con->prepare("
            UPDATE master_role_profiles
            SET role_name = :role_name,
                role_scope = :role_scope,
                tint_hex = :tint_hex,
                sort_order = :sort_order
            WHERE role_id = :role_id
        ");
        $stmt->execute([
            ':role_name' => $roleName,
            ':role_scope' => $roleScope,
            ':tint_hex' => $tintHex !== '' ? $tintHex : '#3B82F6',
            ':sort_order' => $sortOrder,
            ':role_id' => $roleId,
        ]);
        adminModuleSyncRolePermissions($roleId, $permissions);

        respondJson(['status' => 'success', 'message' => 'Role updated']);
    }

    if ($action === 'delete') {
        $countStmt = $con->prepare("SELECT COUNT(*) FROM admin WHERE admin_role_id = :role_id");
        $countStmt->execute([':role_id' => $roleId]);
        if ((int)$countStmt->fetchColumn() > 0) {
            respondJson(['status' => 'error', 'message' => 'Cannot delete a role assigned to administrators'], 409);
        }

        $deletePerms = $con->prepare("DELETE FROM master_role_permissions WHERE role_id = :role_id");
        $deletePerms->execute([':role_id' => $roleId]);
        $deleteRole = $con->prepare("DELETE FROM master_role_profiles WHERE role_id = :role_id AND role_id <> 1");
        $deleteRole->execute([':role_id' => $roleId]);
        respondJson(['status' => 'success', 'message' => 'Role deleted']);
    }

    respondJson(['status' => 'error', 'message' => 'Unsupported role action'], 400);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
