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
    $variantId = (int)($data['variant_id'] ?? 0);
    if ($variantId <= 0) { throw new RuntimeException('Missing variant_id'); }
    $lookup = $con->prepare("SELECT iv.item_id, i.vendor_id, COALESCE(v.vendor_type, 'restaurant') AS vendor_type
        FROM item_variants iv INNER JOIN items i ON i.items_id = iv.item_id
        LEFT JOIN vendors v ON v.vendor_id = i.vendor_id
        WHERE iv.variant_id = :variant_id LIMIT 1");
    $lookup->execute([':variant_id' => $variantId]);
    $row = $lookup->fetch(PDO::FETCH_ASSOC);
    if (!$row || (($actor['role'] ?? '') === 'vendor' && (int)$row['vendor_id'] !== (int)$actor['vendor']['vendor_id'])) { http_response_code(404); throw new RuntimeException('Variant not found'); }
    if (strtolower((string)($row['vendor_type'] ?? 'restaurant')) !== 'store') {
        throw new RuntimeException('Generic variants are available for stores only; use restaurant modifiers');
    }
    if (($actor['role'] ?? '') === 'master') { requireMasterPermission($actor['master'] ?? [], 'restaurants.edit'); }
    $allowed = ['sku', 'color_id', 'size_id', 'stock', 'stock_quantity', 'unit', 'unit_quantity', 'price', 'image_url'];
    $fields = [];
    $params = [':variant_id' => $variantId];
    foreach ($allowed as $field) {
        if (!array_key_exists($field, $data)) continue;
        $fields[] = "{$field} = :{$field}";
        $params[":{$field}"] = in_array($field, ['color_id', 'size_id'], true) && $data[$field] === '' ? null : $data[$field];
    }
    if (!$fields) { throw new RuntimeException('No fields to update'); }
    $con->prepare('UPDATE item_variants SET ' . implode(', ', $fields) . ' WHERE variant_id = :variant_id')->execute($params);
    echo json_encode(['status' => 'success']);
} catch (Throwable $e) {
    http_response_code(http_response_code() >= 400 ? http_response_code() : 400);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
