<?php
include "../connect.php";

$itemid = filterRequest("itemid");
$colorId = filterRequest("color_id");

if ($colorId !== null && $colorId !== '') {
    $stmt = $con->prepare("
        SELECT img_path, img_type, img_order, color_id
        FROM items_images
        WHERE item_id = ? AND (color_id = ? OR color_id IS NULL)
        ORDER BY
            CASE WHEN color_id = ? THEN 0 ELSE 1 END,
            img_order ASC
    ");
    $stmt->execute([$itemid, $colorId, $colorId]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
} else {
    $stmt = $con->prepare("
        SELECT img_path, img_type, img_order, color_id
        FROM items_images
        WHERE item_id = ? AND color_id IS NULL
        ORDER BY img_order ASC
    ");
    $stmt->execute([$itemid]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($data) === 0) {
        $stmt = $con->prepare("
            SELECT img_path, img_type, img_order, color_id
            FROM items_images
            WHERE item_id = ?
            ORDER BY img_order ASC
        ");
        $stmt->execute([$itemid]);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

if (count($data) > 0) {
    echo json_encode([
        "status" => "success",
        "data" => $data
    ]);
} else {
    echo json_encode([
        "status" => "empty",
        "data" => []
    ]);
}
