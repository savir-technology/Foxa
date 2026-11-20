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
$code = trim((string)($payload['code'] ?? $payload['verify_code'] ?? ''));

if ($email === '' || $code === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email and verification code are required',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT *
        FROM vendors
        WHERE vendor_email = :email
          AND vendor_verify_code = :code
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
            'message' => 'Invalid verification code',
        ], 400);
    }

    $updateStmt = $con->prepare("
        UPDATE vendors
        SET
            vendor_is_verified = 1,
            vendor_verify_code = NULL
        WHERE vendor_id = :vendor_id
    ");
    $updateStmt->execute([':vendor_id' => $vendor['vendor_id']]);

    respondJson([
        'status' => 'success',
        'message' => 'Vendor account verified successfully and is waiting for approval',
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
