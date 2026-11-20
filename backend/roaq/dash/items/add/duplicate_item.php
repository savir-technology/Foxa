<?php
include "../../../connect.php";
ensureAleppoFoodOrderingSchema();

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function respond($payload, $status = 200)
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $actor = requireDashboardActor(['vendor', 'master']);
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    $sourceId = (int)($input['item_id'] ?? 0);
    if ($sourceId <= 0) respond(['status' => 'error', 'message' => 'Item id is required'], 400);

    $sourceStmt = $con->prepare('SELECT * FROM items WHERE items_id = :id LIMIT 1');
    $sourceStmt->execute([':id' => $sourceId]);
    $source = $sourceStmt->fetch(PDO::FETCH_ASSOC);
    if (!$source) respond(['status' => 'error', 'message' => 'Item not found'], 404);

    $sourceVendor = (int)($source['vendor_id'] ?? 0);
    if ($actor['role'] === 'vendor' && $sourceVendor !== (int)$actor['vendor']['vendor_id']) {
        respond(['status' => 'error', 'message' => 'You cannot duplicate this item'], 403);
    }

    $con->beginTransaction();
    $newNameAr = trim((string)($source['items_name_ar'] ?? '')) . ' (نسخة)';
    $newNameEn = trim((string)($source['items_name_en'] ?? '')) . ' (Copy)';
    $columns = [
        'items_name_en', 'items_name_ar', 'items_desc_en', 'items_desc_ar',
        'items_image', 'items_count', 'items_active', 'items_price',
        'items_discount', 'items_cat', 'vendor_id', 'product_type',
        'stock_unit', 'stock_step'
    ];
    $insert = $con->prepare(
        'INSERT INTO items (' . implode(',', $columns) . ') VALUES (' .
        implode(',', array_map(fn($column) => ':' . $column, $columns)) . ')'
    );
    $values = [];
    foreach ($columns as $column) $values[':' . $column] = $source[$column] ?? null;
    $values[':items_name_ar'] = $newNameAr;
    $values[':items_name_en'] = $newNameEn;
    $insert->execute($values);
    $newId = (int)$con->lastInsertId();

    $copyImages = $con->prepare(
        'INSERT INTO items_images (item_id, color_id, img_path, img_type, img_order)
         SELECT :new_id, color_id, img_path, img_type, img_order
         FROM items_images WHERE item_id = :source_id'
    );
    $copyImages->execute([':new_id' => $newId, ':source_id' => $sourceId]);

    $copyVariants = $con->prepare(
        'INSERT INTO item_variants
         (item_id, color_id, size_id, stock, price, image_url, sku, stock_quantity, unit, unit_quantity)
         SELECT :new_id, color_id, size_id, 0, price, image_url, sku, stock_quantity, unit, unit_quantity
         FROM item_variants WHERE item_id = :source_id'
    );
    $copyVariants->execute([':new_id' => $newId, ':source_id' => $sourceId]);

    $con->commit();
    respond(['status' => 'success', 'item_id' => $newId, 'message' => 'Item duplicated successfully']);
} catch (Throwable $e) {
    if ($con->inTransaction()) $con->rollBack();
    respond(['status' => 'error', 'message' => 'Unable to duplicate item'], 500);
}
