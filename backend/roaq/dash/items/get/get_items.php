<?php
include "../../../connect.php";
ensureAleppoFoodOrderingSchema();

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$vendorId = $isVendor ? (int)$actor['vendor']['vendor_id'] : 0;
if (!$isVendor) {
    requireMasterPermission($actor['master'] ?? [], 'restaurants.view');
}

try {
    $sql = "
        SELECT
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            i.items_image,
            i.items_count,
            i.items_active,
            i.items_price,
            i.items_discount,
            i.items_date,
            i.items_cat,
            i.vendor_id,
            i.product_type,
            i.stock_unit,
            i.stock_step,
            v.vendor_name,
            v.store_name,
            v.store_slug
        FROM items i
        JOIN vendors v ON v.vendor_id = i.vendor_id
    ";

    if ($isVendor) {
        $sql .= " WHERE i.vendor_id = :vendor_id";
    }

    $sql .= " ORDER BY i.items_id DESC";

    $stmt = $con->prepare($sql);
    if ($isVendor) {
        $stmt->execute([':vendor_id' => $vendorId]);
    } else {
        $stmt->execute();
    }

    echo json_encode([
        'status' => 'success',
        'data' => $stmt->fetchAll(PDO::FETCH_ASSOC),
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
?>
