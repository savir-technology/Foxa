<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['master']);
$admin = $actor['master'] ?? [];

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$vendorId = (int)($payload['vendor_id'] ?? 0);
$status = trim((string)($payload['vendor_status'] ?? ''));

if ($vendorId <= 0 || !in_array($status, ['pending', 'active', 'suspended'], true)) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid vendor data',
    ], 400);
}

if ($status === 'active') {
    requireMasterPermission($admin, 'restaurants.approve');
} elseif ($status === 'suspended') {
    requireMasterPermission($admin, 'restaurants.suspend');
} else {
    requireMasterPermission($admin, 'restaurants.edit');
}

try {
    $stmt = $con->prepare("
        UPDATE vendors
        SET
            vendor_status = :vendor_status,
            vendor_is_verified = CASE WHEN :vendor_status_verified = 'active' THEN 1 ELSE vendor_is_verified END,
            vendor_approval_status = CASE
                WHEN :vendor_status_approval = 'active' THEN 'approved'
                WHEN :vendor_status_approval = 'suspended' THEN 'suspended'
                ELSE vendor_approval_status
            END
        WHERE vendor_id = :vendor_id
    ");
    $stmt->execute([
        ':vendor_status' => $status,
        ':vendor_status_verified' => $status,
        ':vendor_status_approval' => $status,
        ':vendor_id' => $vendorId,
    ]);

    respondJson([
        'status' => 'success',
        'message' => 'Vendor status updated successfully',
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
