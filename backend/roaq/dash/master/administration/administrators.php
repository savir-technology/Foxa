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

function adminPayload(): array
{
    $payload = json_decode(file_get_contents("php://input"), true);
    if (!is_array($payload)) {
        $payload = $_POST;
    }
    return is_array($payload) ? $payload : [];
}

function masterPortalForRoleId(int $roleId): ?string
{
    return [
        2 => 'finance',
        10 => 'finance',
        11 => 'support',
        12 => 'operations',
        13 => 'merchants',
        14 => 'analytics',
        15 => 'legal',
    ][$roleId] ?? null;
}

function adminRowById(int $adminId): ?array
{
    global $con;
    $stmt = $con->prepare("SELECT * FROM admin WHERE admin_id = :admin_id LIMIT 1");
    $stmt->execute([':admin_id' => $adminId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return $row ?: null;
}

function protectSuperAdminTarget(array $actor, int $targetAdminId, string $action): void
{
    if ($targetAdminId <= 0) {
        respondJson(['status' => 'error', 'message' => 'admin_id is required'], 400);
    }

    $target = adminRowById($targetAdminId);
    if (!$target) {
        respondJson(['status' => 'error', 'message' => 'Administrator not found'], 404);
    }

    $targetIsSuper = (int)($target['admin_role_id'] ?? 0) === 1;
    $actorIsSame = (int)($actor['admin_id'] ?? 0) === $targetAdminId;
    if ($targetIsSuper && ($action === 'delete' || !$actorIsSame)) {
        respondJson([
            'status' => 'error',
            'message' => 'The Super Admin account cannot be modified by another administrator',
        ], 403);
    }
}

function ensureAssignableRole(array $actor, int $roleId): void
{
    global $con;
    if ($roleId <= 0) {
        respondJson(['status' => 'error', 'message' => 'role_id is required'], 400);
    }
    $stmt = $con->prepare("SELECT role_id, permissions_json FROM master_role_profiles WHERE role_id = :role_id LIMIT 1");
    $stmt->execute([':role_id' => $roleId]);
    $role = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$role) {
        respondJson(['status' => 'error', 'message' => 'Role not found'], 404);
    }
    adminModuleRejectUndelegablePermissions($actor, adminModuleRolePermissions($roleId, $role['permissions_json'] ?? '[]'));
}

try {
    ensureMasterPortalRoles();
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'administration.view');

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        respondJson([
            'status' => 'success',
            'data' => adminModuleAdminRows(),
        ]);
    }

    $payload = adminPayload();
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : $payload;
    $adminId = (int)($payload['admin_id'] ?? $data['admin_id'] ?? 0);

    if ($action === '') {
        respondJson(['status' => 'error', 'message' => 'action is required'], 400);
    }

    if ($action === 'create') {
        requireMasterPermission($admin, 'administration.create');

        $name = trim((string)($data['admin_name'] ?? $data['name'] ?? ''));
        $email = strtolower(trim((string)($data['admin_email'] ?? $data['email'] ?? '')));
        $phone = trim((string)($data['admin_phone'] ?? $data['phone'] ?? ''));
        $password = (string)($data['password'] ?? '');
        $roleId = (int)($data['admin_role_id'] ?? $data['role_id'] ?? 0);

        if ($name === '' || $email === '' || $password === '' || $roleId <= 0) {
            respondJson([
                'status' => 'error',
                'message' => 'name, email, password, and role_id are required',
            ], 400);
        }
        if ($roleId === 1) {
            respondJson([
                'status' => 'error',
                'message' => 'Create another role-based administrator instead of duplicating Super Admin',
            ], 403);
        }
        if (masterPortalForRoleId($roleId) === null) {
            respondJson([
                'status' => 'error',
                'message' => 'Employee accounts must use one of the six Jeeb portals',
            ], 400);
        }
        ensureAssignableRole($admin, $roleId);

        $stmt = $con->prepare("
            INSERT INTO admin (
                admin_name,
                admin_email,
                admin_phone,
                admin_password,
                admin_role_id,
                master_account_type,
                master_portal_key,
                master_approval_status,
                admin_approve,
                admin_create
            ) VALUES (
                :admin_name,
                :admin_email,
                :admin_phone,
                :admin_password,
                :admin_role_id,
                'employee',
                :master_portal_key,
                'pending',
                0,
                NOW()
            )
        ");
        $stmt->execute([
            ':admin_name' => $name,
            ':admin_email' => $email,
            ':admin_phone' => $phone,
            ':admin_password' => password_hash($password, PASSWORD_DEFAULT),
            ':admin_role_id' => $roleId,
            ':master_portal_key' => masterPortalForRoleId($roleId),
        ]);

        respondJson([
            'status' => 'success',
            'message' => 'Administrator created',
            'data' => ['admin_id' => (int)$con->lastInsertId()],
        ]);
    }

    protectSuperAdminTarget($admin, $adminId, $action);

    if ($action === 'update') {
        requireMasterPermission($admin, 'administration.edit');

        $name = trim((string)($data['admin_name'] ?? $data['name'] ?? ''));
        $email = strtolower(trim((string)($data['admin_email'] ?? $data['email'] ?? '')));
        $phone = trim((string)($data['admin_phone'] ?? $data['phone'] ?? ''));
        $roleId = (int)($data['admin_role_id'] ?? $data['role_id'] ?? 0);

        if ($name === '' || $email === '' || $roleId <= 0) {
            respondJson(['status' => 'error', 'message' => 'name, email, and role_id are required'], 400);
        }
        if ($roleId === 1 && $adminId !== (int)($admin['admin_id'] ?? 0)) {
            respondJson(['status' => 'error', 'message' => 'Only the original Super Admin can keep the Super Admin role'], 403);
        }
        if ($roleId !== 1 && masterPortalForRoleId($roleId) === null) {
            respondJson([
                'status' => 'error',
                'message' => 'Employee accounts must use one of the six Jeeb portals',
            ], 400);
        }
        ensureAssignableRole($admin, $roleId);

        $stmt = $con->prepare("
            UPDATE admin
            SET admin_name = :admin_name,
                admin_email = :admin_email,
                admin_phone = :admin_phone,
                admin_role_id = :admin_role_id,
                master_account_type = CASE WHEN :role_for_type = 1 THEN 'super_admin' ELSE 'employee' END,
                master_portal_key = :master_portal_key
            WHERE admin_id = :admin_id
        ");
        $stmt->execute([
            ':admin_name' => $name,
            ':admin_email' => $email,
            ':admin_phone' => $phone,
            ':admin_role_id' => $roleId,
            ':role_for_type' => $roleId,
            ':master_portal_key' => $roleId === 1 ? null : masterPortalForRoleId($roleId),
            ':admin_id' => $adminId,
        ]);

        respondJson(['status' => 'success', 'message' => 'Administrator updated']);
    }

    if ($action === 'enable' || $action === 'disable') {
        requireMasterPermission($admin, 'administration.edit');
        adminModuleRequireSuperAdmin($admin);

        $approve = $action === 'enable' ? 1 : 0;
        $status = $action === 'enable' ? 'approved' : 'suspended';
        $stmt = $con->prepare("UPDATE admin
            SET admin_approve = :approve,
                master_approval_status = :approval_status,
                master_approved_by = CASE WHEN :approve_for_date = 1 THEN :approved_by ELSE master_approved_by END,
                master_approved_at = CASE WHEN :approve_for_date_2 = 1 THEN NOW() ELSE master_approved_at END
            WHERE admin_id = :admin_id");
        $stmt->execute([
            ':approve' => $approve,
            ':approval_status' => $status,
            ':approve_for_date' => $approve,
            ':approved_by' => (int)($admin['admin_id'] ?? 0),
            ':approve_for_date_2' => $approve,
            ':admin_id' => $adminId,
        ]);
        if (tableExists('master_auth_audit_log')) {
            $audit = $con->prepare("INSERT INTO master_auth_audit_log
                (actor_admin_id, target_admin_id, action_key, portal_key, metadata_json, ip_address, user_agent)
                VALUES (:actor, :target, :action_key, :portal_key, :metadata, :ip, :agent)");
            $audit->execute([
                ':actor' => (int)($admin['admin_id'] ?? 0),
                ':target' => $adminId,
                ':action_key' => $action === 'enable' ? 'approve_employee' : 'suspend_employee',
                ':portal_key' => null,
                ':metadata' => json_encode(['source' => 'administrators'], JSON_UNESCAPED_UNICODE),
                ':ip' => substr($_SERVER['REMOTE_ADDR'] ?? '', 0, 64),
                ':agent' => substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255),
            ]);
        }
        respondJson(['status' => 'success', 'message' => 'Administrator status updated']);
    }

    if ($action === 'reset_password') {
        requireMasterPermission($admin, 'administration.edit');
        adminModuleRequireSuperAdmin($admin);
        $password = (string)($data['password'] ?? '');
        if (strlen($password) < 8) {
            respondJson(['status' => 'error', 'message' => 'Password must be at least 8 characters'], 400);
        }
        $stmt = $con->prepare("UPDATE admin SET admin_password = :password WHERE admin_id = :admin_id");
        $stmt->execute([
            ':password' => password_hash($password, PASSWORD_DEFAULT),
            ':admin_id' => $adminId,
        ]);
        respondJson(['status' => 'success', 'message' => 'Password reset successfully']);
    }

    if ($action === 'delete') {
        requireMasterPermission($admin, 'administration.delete');
        adminModuleRequireSuperAdmin($admin);

        if ($adminId === (int)($admin['admin_id'] ?? 0)) {
            respondJson(['status' => 'error', 'message' => 'You cannot delete your own account'], 403);
        }

        $stmt = $con->prepare("DELETE FROM admin WHERE admin_id = :admin_id AND admin_role_id <> 1");
        $stmt->execute([':admin_id' => $adminId]);
        respondJson(['status' => 'success', 'message' => 'Administrator deleted']);
    }

    respondJson(['status' => 'error', 'message' => 'Unsupported administrator action'], 400);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
