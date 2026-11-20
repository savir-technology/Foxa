<?php
require_once "../../../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $actor = requireDashboardActor(['vendor', 'master']);
    $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $variantId = (int)($data['variant_id'] ?? $_GET['variant_id'] ?? 0);
    if ($variantId <= 0) { throw new RuntimeException('Missing variant_id'); }
    $lookup = $con->prepare('SELECT i.vendor_id FROM item_variants iv INNER JOIN items i ON i.items_id = iv.item_id WHERE iv.variant_id = :variant_id LIMIT 1');
    $lookup->execute([':variant_id' => $variantId]);
    $vendorId = $lookup->fetchColumn();
    if (!$vendorId || (($actor['role'] ?? '') === 'vendor' && (int)$vendorId !== (int)$actor['vendor']['vendor_id'])) { http_response_code(404); throw new RuntimeException('Variant not found'); }
    if (($actor['role'] ?? '') === 'master') { requireMasterPermission($actor['master'] ?? [], 'restaurants.delete'); }
    $con->prepare('DELETE FROM item_variants WHERE variant_id = :variant_id')->execute([':variant_id' => $variantId]);
    echo json_encode(['status' => 'success']);
} catch (Throwable $e) {
    http_response_code(http_response_code() >= 400 ? http_response_code() : 400);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
