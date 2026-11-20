<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);

    $stmt = $con->prepare("
        SELECT
            COALESCE(NULLIF(items.items_name_ar, ''), NULLIF(items.items_name_en, ''), CONCAT('Item #', items.items_id)) AS product_name,
            COUNT(favorite.favorite_itemsid) AS interested_users
        FROM favorite
        INNER JOIN items ON favorite.favorite_itemsid = items.items_id
        WHERE items.vendor_id = :vendor_id
        GROUP BY favorite.favorite_itemsid, items.items_id, items.items_name_ar, items.items_name_en
        ORDER BY interested_users DESC, product_name ASC
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'success',
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
