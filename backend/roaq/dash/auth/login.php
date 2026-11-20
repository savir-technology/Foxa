<?php
include "../../connect.php";

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
$password = (string)($payload['password'] ?? '');

if ($email === '' || $password === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email and password are required',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT
            v.*,
            s.store_address,
            s.store_latitude,
            s.store_longitude
        FROM vendors v
        LEFT JOIN vendor_store_settings s
            ON s.vendor_id = v.vendor_id
        WHERE v.vendor_email = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $vendor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendor || !password_verify($password, $vendor['vendor_password'])) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid email or password',
        ], 401);
    }

    if ((int)($vendor['vendor_is_verified'] ?? 0) !== 1) {
        respondJson([
            'status' => 'error',
            'message' => 'Account is not verified yet',
        ], 403);
    }

    $vendorStatus = strtolower(trim((string)($vendor['vendor_status'] ?? 'pending')));
    if ($vendorStatus === 'pending') {
        respondJson([
            'status' => 'error',
            'message' => 'Vendor account is pending approval',
        ], 403);
    }

    if ($vendorStatus !== 'active') {
        respondJson([
            'status' => 'error',
            'message' => 'Vendor account is not active',
        ], 403);
    }

    $session = createVendorSession((int)$vendor['vendor_id']);

    respondJson([
        'status' => 'success',
        'message' => 'Login successful',
        'token' => $session['token'],
        'expires_at' => $session['expires_at'],
        'vendor' => vendorPublicData($vendor),
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
