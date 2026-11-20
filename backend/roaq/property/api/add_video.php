<?php
// API: Add a new video for a property item
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$video_title = isset($_POST['video_title']) ? trim($_POST['video_title']) : '';
$video_desc = isset($_POST['video_desc']) ? trim($_POST['video_desc']) : '';
$video_url = isset($_POST['video_url']) ? trim($_POST['video_url']) : '';
$video_product_id = isset($_POST['video_product_id']) ? intval($_POST['video_product_id']) : 0;
$video_userid = isset($_POST['video_userid']) ? intval($_POST['video_userid']) : 0;
$video_thumbnail = isset($_POST['video_thumbnail']) ? trim($_POST['video_thumbnail']) : '';

if (empty($video_title) || empty($video_url) || $video_product_id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'video_title, video_url, and video_product_id are required'
    ]);
    exit;
}

try {
    // التحقق من وجود العقار
    $itemStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = ?");
    $itemStmt->execute([$video_product_id]);
    if ($itemStmt->rowCount() === 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Item not found'
        ]);
        exit;
    }

    // إدراج الفيديو
    $stmt = $con->prepare("
        INSERT INTO videos 
        (video_title, video_desc, video_url, video_thumbnail, video_product_id, video_views, video_likes, video_userid, video_date)
        VALUES (?, ?, ?, ?, ?, 0, 0, ?, NOW())
    ");

    $stmt->execute([
        $video_title,
        $video_desc,
        $video_url,
        $video_thumbnail,
        $video_product_id,
        $video_userid > 0 ? $video_userid : null
    ]);

    $video_id = $con->lastInsertId();

    echo json_encode([
        'status' => 'success',
        'message' => 'Video added successfully',
        'video_id' => $video_id,
        'video' => [
            'video_id' => $video_id,
            'video_title' => $video_title,
            'video_desc' => $video_desc,
            'video_url' => $video_url,
            'video_thumbnail' => $video_thumbnail,
            'video_product_id' => $video_product_id,
            'video_date' => date('Y-m-d H:i:s')
        ]
    ]);

} catch (Exception $e) {
    error_log("Error in add_video: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
