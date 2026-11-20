<?php
include "../connect.php";

try {
    $stmt = $con->prepare("
        SELECT 
            v.video_id,
            v.video_title,
            v.video_desc,
            v.video_url,
            v.video_thumbnail,
            v.video_product_id,
            v.video_target_type,
            v.video_target_id,
            v.video_views,
            v.video_likes,
            v.video_userid,
            v.video_date,
            u.users_name AS uploader_name,
            i.items_name_ar AS product_name_ar,
            i.items_name_en AS product_name_en,
            i.items_image AS product_image
        FROM videos v
        LEFT JOIN users u ON u.users_id = v.video_userid
        LEFT JOIN items i ON i.items_id = v.video_product_id
        ORDER BY v.video_date DESC
    ");
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $data
    ]);
} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
