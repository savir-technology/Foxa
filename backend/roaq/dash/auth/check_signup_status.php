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
        SELECT vendor_id, vendor_status, vendor_is_verified
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

    $vendorStatus = strtolower(trim((string)($vendor['vendor_status'] ?? 'pending')));
    $vendorIsVerified = (int)($vendor['vendor_is_verified'] ?? 0) === 1;
    $isApproved = ($vendorStatus === 'active' && $vendorIsVerified);

    respondJson([
        'status' => 'success',
        'message' => $isApproved
            ? 'Vendor account approved'
            : ($vendorIsVerified
                ? 'Vendor account verified and waiting for approval'
                : 'Vendor account is waiting for verification'),
        'vendor_status' => $vendorStatus,
        'vendor_is_verified' => $vendorIsVerified ? 1 : 0,
        'is_approved' => $isApproved ? 1 : 0,
        'email' => $email,
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
