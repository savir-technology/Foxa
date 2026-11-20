<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

try {
    $item_id = isset($_GET['item_id']) ? intval($_GET['item_id']) : 0;

    if ($item_id > 0) {
        $stmt = $con->prepare("SELECT * FROM property_plans WHERE item_id = :item_id ORDER BY plan_id DESC");
        $stmt->execute([':item_id' => $item_id]);
    } else {
        $stmt = $con->prepare("SELECT * FROM property_plans ORDER BY plan_id DESC");
        $stmt->execute();
    }

    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    echo json_encode($rows, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
