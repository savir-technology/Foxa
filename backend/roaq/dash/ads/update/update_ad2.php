<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

try {
    $adId = intval($_POST['ad_id'] ?? 0);
    $itemId = intval($_POST['item_id'] ?? 0);
    if ($adId <= 0 || $itemId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'ad_id and item_id are required']);
        exit;
    }

    $itemStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = :id LIMIT 1");
    $itemStmt->execute([':id' => $itemId]);
    if (!$itemStmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode(['status' => 'error', 'message' => 'Item not found']);
        exit;
    }

    $stmt = $con->prepare("UPDATE ads2 SET item_id = :item_id WHERE id = :id");
    $stmt->execute([
        ':item_id' => $itemId,
        ':id' => $adId,
    ]);

    echo json_encode(['status' => 'success'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
