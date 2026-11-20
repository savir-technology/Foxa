<?php
include "../../connect.php";
ensureAleppoFoodOrderingSchema();

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
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

if (strlen($password) < 6) {
    respondJson([
        'status' => 'error',
        'message' => 'Password must be at least 6 characters',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT vendor_id, vendor_reset_expires_at
        FROM vendors
        WHERE vendor_email = :email
          AND vendor_reset_code = :code
        LIMIT 1
    ");
    $stmt->execute([
        ':email' => $email,
        ':code' => $code,
    ]);
    $vendor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendor) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid reset code',
        ], 400);
    }

    $expiresAt = $vendor['vendor_reset_expires_at'] ?? null;
    if ($expiresAt && strtotime((string)$expiresAt) !== false && strtotime((string)$expiresAt) < time()) {
        respondJson([
            'status' => 'error',
            'message' => 'Reset code has expired',
        ], 400);
    }

    $updateStmt = $con->prepare("
        UPDATE vendors
        SET
            vendor_password = :vendor_password,
            vendor_reset_code = NULL,
            vendor_reset_expires_at = NULL
        WHERE vendor_id = :vendor_id
    ");
    $updateStmt->execute([
        ':vendor_password' => password_hash($password, PASSWORD_DEFAULT),
        ':vendor_id' => $vendor['vendor_id'],
    ]);

    respondJson([
        'status' => 'success',
        'message' => 'Password changed successfully',
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
