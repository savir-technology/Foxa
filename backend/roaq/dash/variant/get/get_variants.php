<?php
require_once "../../../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $actor = requireDashboardActor(['vendor', 'master']);
    $itemId = (int)($_GET['item_id'] ?? 0);
    if ($itemId <= 0) { throw new RuntimeException('Missing item_id'); }
    $itemSql = "SELECT i.vendor_id, COALESCE(v.vendor_type, 'restaurant') AS vendor_type
        FROM items i LEFT JOIN vendors v ON v.vendor_id = i.vendor_id
        WHERE i.items_id = :item_id LIMIT 1";
    $itemStmt = $con->prepare($itemSql);
    $itemStmt->execute([':item_id' => $itemId]);
    $item = $itemStmt->fetch(PDO::FETCH_ASSOC);
    if (!$item || (($actor['role'] ?? '') === 'vendor' && (int)$item['vendor_id'] !== (int)$actor['vendor']['vendor_id'])) {
        http_response_code(404); throw new RuntimeException('Item not found');
    }
    if (strtolower((string)($item['vendor_type'] ?? 'restaurant')) !== 'store') {
        echo json_encode(['status' => 'success', 'data' => []], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if (($actor['role'] ?? '') === 'master') { requireMasterPermission($actor['master'] ?? [], 'restaurants.view'); }
    $stmt = $con->prepare('SELECT variant_id, item_id, sku, color_id, size_id, stock, stock_quantity, unit, unit_quantity, price, image_url FROM item_variants WHERE item_id = :item_id ORDER BY variant_id ASC');
    $stmt->execute([':item_id' => $itemId]);
    echo json_encode(['status' => 'success', 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC) ?: []], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(http_response_code() >= 400 ? http_response_code() : 400);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
