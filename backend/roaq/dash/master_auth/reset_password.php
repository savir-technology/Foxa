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
$code = trim((string)($payload['code'] ?? $payload['reset_code'] ?? ''));
$password = (string)($payload['password'] ?? '');

if ($email === '' || $code === '' || $password === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email, code and password are required',
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

try {
    $stmt = $con->prepare("
        SELECT admin_id, admin_reset_code, admin_reset_expires_at
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

    $expiresAt = $admin['admin_reset_expires_at'] ?? null;
    if ($expiresAt && strtotime((string)$expiresAt) !== false && strtotime((string)$expiresAt) < time()) {
        respondJson([
            'status' => 'error',
            'message' => 'Reset code has expired',
        ], 400);
    }

    if (!hash_equals((string)($admin['admin_reset_code'] ?? ''), $code)) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid reset code',
        ], 400);
    }

    $updateStmt = $con->prepare("
        UPDATE admin
        SET
            admin_password = :admin_password,
            admin_reset_code = NULL,
            admin_reset_expires_at = NULL
        WHERE admin_id = :admin_id
    ");
    $updateStmt->execute([
        ':admin_password' => password_hash($password, PASSWORD_DEFAULT),
        ':admin_id' => $admin['admin_id'],
    ]);

    respondJson([
        'status' => 'success',
        'message' => 'Password reset successfully',
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
