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

if ($email === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email is required',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT vendor_id, vendor_is_verified
        FROM vendors
        WHERE vendor_email = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $vendor = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendor) {
        respondJson([
            'status' => 'error',
            'message' => 'Vendor account not found',
        ], 404);
    }

    if ((int)$vendor['vendor_is_verified'] === 1) {
        respondJson([
            'status' => 'success',
            'message' => 'Account is already verified',
        ]);
    }

    $code = generateOtpCode();
    $con->beginTransaction();
    $updateStmt = $con->prepare("
        UPDATE vendors
        SET vendor_verify_code = :code
        WHERE vendor_id = :vendor_id
    ");
    $updateStmt->execute([
        ':code' => $code,
        ':vendor_id' => $vendor['vendor_id'],
    ]);

    if (!sendEmailWithFallback($email, 'Vendor Signup Verification', $code)) {
        throw new RuntimeException('Unable to send verification email');
    }

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Verification code sent successfully',
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
