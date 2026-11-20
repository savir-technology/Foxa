<?php
include "../../../connect.php";
header('Content-Type: application/json; charset=utf-8');

$itemId = isset($_GET['item_id']) ? (int) $_GET['item_id'] : 0;

if ($itemId <= 0) {
    echo json_encode(['status' => 'error', 'message' => 'Missing item_id']);
    exit;
}

try {
    $stmt = $con->prepare("
        SELECT
            filter_id,
            item_id,
            overlay_image_path,
            left_temple_image_path,
            right_temple_image_path,
            scale_factor,
            offset_x,
            offset_y,
            rotation_adjust,
            bridge_y_adjust,
            is_active
        FROM item_ar_filters
        WHERE item_id = :item_id
          AND variant_id IS NULL
        ORDER BY filter_id DESC
        LIMIT 1
    ");
    $stmt->execute([':item_id' => $itemId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo json_encode(['status' => 'success', 'data' => null]);
        exit;
    }

    $baseUrl = "https://savir-technology.online/roaqv2/";
    $row['overlay_image_url'] = !empty($row['overlay_image_path'])
        ? $baseUrl . ltrim(str_replace('\\', '/', $row['overlay_image_path']), '/')
        : null;

    echo json_encode(['status' => 'success', 'data' => $row]);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
