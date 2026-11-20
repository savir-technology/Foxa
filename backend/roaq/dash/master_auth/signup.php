<?php
include "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$adminName = trim((string)($payload['admin_name'] ?? $payload['full_name'] ?? $payload['name'] ?? ''));
$email = strtolower(trim((string)($payload['email'] ?? '')));
$phone = trim((string)($payload['phone'] ?? ''));
$password = (string)($payload['password'] ?? '');
$roleId = (int)($payload['role_id'] ?? 0);
$ownerEmail = strtolower(trim((string)($payload['owner_email'] ?? '')));
$ownerCode = trim((string)($payload['owner_code'] ?? ''));
$employeeRoleIds = [10, 11, 12, 13, 14, 15];
$portalByRole = [
    10 => 'finance',
    11 => 'support',
    12 => 'operations',
    13 => 'merchants',
    14 => 'analytics',
    15 => 'legal',
];

if ($adminName === '' || $email === '' || $phone === '' || $password === '' || $roleId <= 0) {
    respondJson([
        'status' => 'error',
        'message' => 'All signup fields are required',
    ], 400);
}

if ($ownerEmail === '' || $ownerCode === '') {
    respondJson(['status' => 'error', 'message' => 'يجب تأكيد كود بريد الماستر أولاً'], 403);
}

if (!in_array($roleId, $employeeRoleIds, true)) {
    respondJson([
        'status' => 'error',
        'message' => 'Select one of the six employee departments',
    ], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid email address',
    ], 400);
}

if (strlen($password) < 8) {
    respondJson([
        'status' => 'error',
        'message' => 'Password must be at least 8 characters',
    ], 400);
}

if (!preg_match('/[A-Z]/', $password) || !preg_match('/[a-z]/', $password) || !preg_match('/\d/', $password) || !preg_match('/[^A-Za-z0-9]/', $password)) {
    respondJson([
        'status' => 'error',
        'message' => 'Password must include upper, lower, number and symbol',
    ], 400);
}

if (!preg_match('/^\+?[0-9]{7,20}$/', preg_replace('/\s+/', '', $phone))) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid phone number',
    ], 400);
}

try {
    ensureMasterPortalRoles();
    $existingStmt = $con->prepare("
        SELECT admin_id, admin_approve, admin_role_id
        FROM admin
        WHERE LOWER(admin_email) = :email
        LIMIT 1
    ");
    $existingStmt->execute([':email' => $email]);
    $existing = $existingStmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        respondJson([
            'status' => 'error',
            'message' => 'Email is already registered',
        ], 409);
    }

    $ownerStmt = $con->prepare("SELECT admin_id, admin_reset_code, admin_reset_expires_at FROM admin WHERE admin_role_id = 1 AND LOWER(admin_email) = :email LIMIT 1");
    $ownerStmt->execute([':email' => $ownerEmail]);
    $owner = $ownerStmt->fetch(PDO::FETCH_ASSOC);
    if (!$owner || ($owner['admin_reset_expires_at'] && strtotime((string)$owner['admin_reset_expires_at']) < time()) || !hash_equals((string)($owner['admin_reset_code'] ?? ''), $ownerCode)) {
        respondJson(['status' => 'error', 'message' => 'كود بريد الماستر غير صحيح أو منتهي الصلاحية'], 403);
    }

    $roleStmt = $con->prepare("
        SELECT role_id, role_name, role_scope
        FROM master_role_profiles
        WHERE role_id = :role_id
        LIMIT 1
    ");
    $roleStmt->execute([':role_id' => $roleId]);
    $role = $roleStmt->fetch(PDO::FETCH_ASSOC);

    if (!$role) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid role',
        ], 400);
    }

    $superAdminCount = (int)$con->query("
        SELECT COUNT(*)
        FROM admin
        WHERE admin_role_id = 1
    ")->fetchColumn();

    if ($superAdminCount === 0 && $roleId !== 1) {
        respondJson([
            'status' => 'error',
            'message' => 'The first master account must be the primary admin',
        ], 403);
    }

    if ($superAdminCount > 0 && $roleId === 1) {
        respondJson([
            'status' => 'error',
            'message' => 'Primary admin account already exists',
        ], 409);
    }

    $passwordHash = password_hash($password, PASSWORD_DEFAULT);

    $con->beginTransaction();

    $insertStmt = $con->prepare("
        INSERT INTO admin (
            admin_name,
            admin_password,
            admin_email,
            admin_phone,
            admin_approve,
            admin_role_id,
            master_account_type,
            master_portal_key,
            master_approval_status,
            admin_create
        ) VALUES (
            :admin_name,
            :admin_password,
            :admin_email,
            :admin_phone,
            0,
            :admin_role_id,
            'employee',
            :master_portal_key,
            'pending',
            NOW()
        )
    ");
    $insertStmt->execute([
        ':admin_name' => $adminName,
        ':admin_password' => $passwordHash,
        ':admin_email' => $email,
        ':admin_phone' => $phone,
        ':admin_role_id' => $roleId,
        ':master_portal_key' => $portalByRole[$roleId],
    ]);

    $con->prepare("UPDATE admin SET admin_reset_code = NULL, admin_reset_expires_at = NULL WHERE admin_id = :admin_id")
        ->execute([':admin_id' => $owner['admin_id']]);

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Signup completed. The account is waiting for primary admin approval.',
        'data' => [
            'email' => $email,
            'role' => masterRolePublicData($role),
            'verification_required' => false,
            'expires_in' => 0,
        ],
    ], 201);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
