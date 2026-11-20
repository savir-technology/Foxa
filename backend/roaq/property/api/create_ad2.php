<?php
// API: Create a new ad2 (property ad) - Admin only
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$image_url = isset($_POST['image_url']) ? trim($_POST['image_url']) : '';
$item_id = isset($_POST['item_id']) ? intval($_POST['item_id']) : 0;

if (empty($image_url)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'image_url is required'
    ]);
    exit;
}

try {
    // التحقق من وجود العقار (اختياري)
    if ($item_id > 0) {
        $itemStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = ?");
        $itemStmt->execute([$item_id]);
        if ($itemStmt->rowCount() === 0) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Item not found'
            ]);
            exit;
        }
    }

    // إنشاء الإعلان
    $stmt = $con->prepare("
        INSERT INTO ads2 (image_url, item_id, created_at)
        VALUES (?, ?, NOW())
    ");

    $stmt->execute([
        $image_url,
        $item_id > 0 ? $item_id : null
    ]);

    $ad_id = $con->lastInsertId();

    echo json_encode([
        'status' => 'success',
        'message' => 'Ad created successfully',
        'ad_id' => $ad_id,
        'ad' => [
            'id' => $ad_id,
            'image_url' => $image_url,
            'item_id' => $item_id > 0 ? $item_id : null,
            'created_at' => date('Y-m-d H:i:s')
        ]
    ]);

} catch (Exception $e) {
    error_log("Error in create_ad2: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
