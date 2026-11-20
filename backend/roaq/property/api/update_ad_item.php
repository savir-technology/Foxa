<?php
// API: Update ads2 to link with property item (Admin only)
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$ad_id = isset($_POST['ad_id']) ? intval($_POST['ad_id']) : 0;
$item_id = isset($_POST['item_id']) ? intval($_POST['item_id']) : 0;

if ($ad_id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid ad_id'
    ]);
    exit;
}

try {
    // تحديث الإعلان
    $stmt = $con->prepare("
        UPDATE ads2
        SET item_id = ?
        WHERE id = ?
    ");
    
    $stmt->execute([$item_id > 0 ? $item_id : null, $ad_id]);
    $rowCount = $stmt->rowCount();

    if ($rowCount > 0) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Ad updated successfully'
        ]);
    } else {
        echo json_encode([
            'status' => 'failure',
            'message' => 'Ad not found or no changes made'
        ]);
    }

} catch (Exception $e) {
    error_log("Error in update_ad_item: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
