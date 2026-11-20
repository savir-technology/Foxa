<?php
require_once "../../../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $actor = requireDashboardActor(['vendor', 'master']);
    $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $itemId = (int)($data['item_id'] ?? 0);
    if ($itemId <= 0) { throw new RuntimeException('Missing item_id'); }
    $stmt = $con->prepare("SELECT i.vendor_id, COALESCE(v.vendor_type, 'restaurant') AS vendor_type
        FROM items i LEFT JOIN vendors v ON v.vendor_id = i.vendor_id
        WHERE i.items_id = :item_id LIMIT 1");
    $stmt->execute([':item_id' => $itemId]);
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$item || (($actor['role'] ?? '') === 'vendor' && (int)$item['vendor_id'] !== (int)$actor['vendor']['vendor_id'])) { http_response_code(404); throw new RuntimeException('Item not found'); }
    if (strtolower((string)($item['vendor_type'] ?? 'restaurant')) !== 'store') {
        throw new RuntimeException('Generic variants are available for stores only; use restaurant modifiers');
    }
    if (($actor['role'] ?? '') === 'master') { requireMasterPermission($actor['master'] ?? [], 'restaurants.edit'); }
    if (($data['color_id'] ?? null) === null && ($data['size_id'] ?? null) === null && trim((string)($data['sku'] ?? '')) === '') { throw new RuntimeException('A color, size, or SKU is required'); }
    $insert = $con->prepare('INSERT INTO item_variants (item_id, sku, color_id, size_id, stock, stock_quantity, unit, unit_quantity, price, image_url) VALUES (:item_id, :sku, :color_id, :size_id, :stock, :stock_quantity, :unit, :unit_quantity, :price, :image_url)');
    $insert->execute([
        ':item_id' => $itemId,
        ':sku' => trim((string)($data['sku'] ?? '')) ?: null,
        ':color_id' => ($data['color_id'] ?? '') !== '' ? (int)$data['color_id'] : null,
        ':size_id' => ($data['size_id'] ?? '') !== '' ? (int)$data['size_id'] : null,
        ':stock' => (int)($data['stock'] ?? $data['stock_quantity'] ?? 0),
        ':stock_quantity' => (float)($data['stock_quantity'] ?? $data['stock'] ?? 0),
        ':unit' => trim((string)($data['unit'] ?? 'piece')) ?: 'piece',
        ':unit_quantity' => (float)($data['unit_quantity'] ?? 1),
        ':price' => (float)($data['price'] ?? 0),
        ':image_url' => trim((string)($data['image_url'] ?? '')) ?: null,
    ]);
    echo json_encode(['status' => 'success', 'variant_id' => (int)$con->lastInsertId()]);
} catch (Throwable $e) {
    http_response_code(http_response_code() >= 400 ? http_response_code() : 400);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
