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

$email = strtolower(trim((string)($payload['email'] ?? '')));
$code = trim((string)($payload['code'] ?? $payload['verify_code'] ?? ''));

if ($email === '' || $code === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email and verification code are required',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT admin_id, admin_approve, admin_verfiycode, admin_verify_expires_at
        FROM admin
        WHERE LOWER(admin_email) = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$admin) {
        respondJson([
            'status' => 'error',
            'message' => 'Account not found',
        ], 404);
    }

    if ((int)($admin['admin_approve'] ?? 0) === 1) {
        respondJson([
            'status' => 'success',
            'message' => 'Account is already verified',
        ]);
    }

    $expiresAt = $admin['admin_verify_expires_at'] ?? null;
    if ($expiresAt && strtotime((string)$expiresAt) !== false && strtotime((string)$expiresAt) < time()) {
        respondJson([
            'status' => 'error',
            'message' => 'Verification code has expired',
        ], 400);
    }

    if (!hash_equals((string)($admin['admin_verfiycode'] ?? ''), $code)) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid verification code',
        ], 400);
    }

    // Email verification is not the same as approval by the primary admin.
    // Employee accounts must remain blocked until the master administrator
    // explicitly enables them from the administration screen.
    if (columnExists('admin', 'master_approval_status')) {
        $updateStmt = $con->prepare("
            UPDATE admin
            SET
                admin_approve = CASE WHEN admin_role_id = 1 THEN 1 ELSE 0 END,
                master_approval_status = CASE WHEN admin_role_id = 1 THEN 'approved' ELSE 'pending' END,
                admin_verfiycode = NULL,
                admin_verify_expires_at = NULL
            WHERE admin_id = :admin_id
        ");
    } else {
        $updateStmt = $con->prepare("
            UPDATE admin
            SET
                admin_approve = 1,
                admin_verfiycode = NULL,
                admin_verify_expires_at = NULL
            WHERE admin_id = :admin_id
        ");
    }
    $updateStmt->execute([':admin_id' => $admin['admin_id']]);

    respondJson([
        'status' => 'success',
        'message' => 'Account verified successfully',
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
