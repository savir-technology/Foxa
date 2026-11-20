<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['master']);
$admin = $actor['master'] ?? [];
requireMasterPermission($admin, 'restaurants.view');

try {
    $stmt = $con->prepare("
        SELECT
            v.vendor_id,
            v.vendor_name,
            v.store_name,
            v.vendor_type,
            v.store_category,
            v.store_slug,
            v.vendor_email,
            v.vendor_phone,
            v.vendor_logo,
            v.vendor_status,
            v.vendor_is_verified,
            v.vendor_approval_status,
            v.vendor_approval_note,
            v.vendor_created_at,
            s.store_address,
            s.store_latitude,
            s.store_longitude,
            s.currency_code,
            s.currency_symbol,
            s.currency_name
        FROM vendors v
        LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
        WHERE v.vendor_approval_status = 'pending'
           OR v.vendor_approval_status = 'more_info'
        ORDER BY v.vendor_created_at DESC
    ");
    $stmt->execute();
    $vendors = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'success',
        'data' => $vendors,
        'count' => count($vendors),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
