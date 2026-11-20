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

if ($email === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email is required',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT vendor_id
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

    $code = generateOtpCode();
    $expiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));
    $con->beginTransaction();
    $updateStmt = $con->prepare("
        UPDATE vendors
        SET vendor_reset_code = :code,
            vendor_reset_expires_at = :expires_at
        WHERE vendor_id = :vendor_id
    ");
    $updateStmt->execute([
        ':code' => $code,
        ':expires_at' => $expiresAt,
        ':vendor_id' => $vendor['vendor_id'],
    ]);

    // Use the configured SMTP transport first and the local mail transport
    // as a fallback, so vendor and restaurant accounts are not blocked by a
    // temporary Gmail SMTP failure.
    if (!sendEmailWithFallback($email, 'Vendor Password Reset', "Reset Code $code")) {
        throw new RuntimeException('Unable to send reset email');
    }

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Reset code sent successfully',
        'email' => $email,
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
