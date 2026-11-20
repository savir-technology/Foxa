<?php
include "../../../connect.php";
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $maxOverlayBytes = 700 * 1024;
    $maxImageWidth = 1400;
    $maxImageHeight = 1400;

    $data = json_decode(file_get_contents("php://input"));

    $itemId = isset($data->item_id) ? (int) $data->item_id : 0;
    $overlayImage = isset($data->overlay_image) ? trim((string) $data->overlay_image) : '';
    $scaleFactor = isset($data->scale_factor) ? (float) $data->scale_factor : 0.10;
    $offsetX = isset($data->offset_x) ? (float) $data->offset_x : 0.000;
    $offsetY = isset($data->offset_y) ? (float) $data->offset_y : 0.000;
    $rotationAdjust = isset($data->rotation_adjust) ? (float) $data->rotation_adjust : 0.000;
    $bridgeYAdjust = isset($data->bridge_y_adjust) ? (float) $data->bridge_y_adjust : 0.000;

    if ($itemId <= 0 || $overlayImage === '') {
        echo json_encode(['status' => 'error', 'message' => 'Missing item_id or overlay_image']);
        exit;
    }

    $decodedImage = base64_decode($overlayImage, true);
    if ($decodedImage === false) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid overlay_image encoding']);
        exit;
    }

    if (strlen($decodedImage) > $maxOverlayBytes) {
        echo json_encode(['status' => 'error', 'message' => 'AR frame image must be 700 KB or smaller']);
        exit;
    }

    $imageInfo = @getimagesizefromstring($decodedImage);
    if ($imageInfo === false) {
        echo json_encode(['status' => 'error', 'message' => 'Uploaded file is not a valid image']);
        exit;
    }

    if ($imageInfo[0] > $maxImageWidth || $imageInfo[1] > $maxImageHeight) {
        echo json_encode([
            'status' => 'error',
            'message' => 'AR frame dimensions must not exceed 1400x1400 pixels'
        ]);
        exit;
    }

    $uploadDir = __DIR__ . "/../../../uploud/ar_filters/";
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $imageName = uniqid('ar_', true) . ".png";
    file_put_contents($uploadDir . $imageName, $decodedImage);
    $relativePath = "uploud/ar_filters/" . $imageName;

    $existingStmt = $con->prepare("
        SELECT filter_id
        FROM item_ar_filters
        WHERE item_id = :item_id
          AND variant_id IS NULL
        ORDER BY filter_id DESC
        LIMIT 1
    ");
    $existingStmt->execute([':item_id' => $itemId]);
    $existing = $existingStmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        $stmt = $con->prepare("
            UPDATE item_ar_filters
            SET overlay_image_path = :overlay_image_path,
                scale_factor = :scale_factor,
                offset_x = :offset_x,
                offset_y = :offset_y,
                rotation_adjust = :rotation_adjust,
                bridge_y_adjust = :bridge_y_adjust,
                is_active = 1
            WHERE filter_id = :filter_id
        ");
        $stmt->execute([
            ':overlay_image_path' => $relativePath,
            ':scale_factor' => $scaleFactor,
            ':offset_x' => $offsetX,
            ':offset_y' => $offsetY,
            ':rotation_adjust' => $rotationAdjust,
            ':bridge_y_adjust' => $bridgeYAdjust,
            ':filter_id' => (int) $existing['filter_id'],
        ]);
        $filterId = (int) $existing['filter_id'];
    } else {
        $stmt = $con->prepare("
            INSERT INTO item_ar_filters (
                item_id,
                variant_id,
                overlay_image_path,
                scale_factor,
                offset_x,
                offset_y,
                rotation_adjust,
                bridge_y_adjust,
                is_active
            ) VALUES (
                :item_id,
                NULL,
                :overlay_image_path,
                :scale_factor,
                :offset_x,
                :offset_y,
                :rotation_adjust,
                :bridge_y_adjust,
                1
            )
        ");
        $stmt->execute([
            ':item_id' => $itemId,
            ':overlay_image_path' => $relativePath,
            ':scale_factor' => $scaleFactor,
            ':offset_x' => $offsetX,
            ':offset_y' => $offsetY,
            ':rotation_adjust' => $rotationAdjust,
            ':bridge_y_adjust' => $bridgeYAdjust,
        ]);
        $filterId = (int) $con->lastInsertId();
    }

    echo json_encode([
        'status' => 'success',
        'data' => [
            'filter_id' => $filterId,
            'item_id' => $itemId,
            'overlay_image_path' => $relativePath,
            'overlay_image_url' => "https://savir-technology.online/roaqv2/" . $relativePath,
        ],
    ]);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>

