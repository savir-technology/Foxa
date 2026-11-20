<?php
// API: Get all videos related to a property item
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$item_id = isset($_GET['item_id']) ? intval($_GET['item_id']) : 0;
$page = isset($_GET['page']) ? intval($_GET['page']) : 1;
$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;

if ($item_id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid item_id'
    ]);
    exit;
}

try {
    // حساب الـ offset
    $offset = ($page - 1) * $limit;

    // جلب الفيديوهات
    $stmt = $con->prepare("
        SELECT 
            v.video_id,
            v.video_title,
            v.video_desc,
            v.video_url,
            v.video_thumbnail,
            v.video_views,
            v.video_likes,
            u.users_id,
            u.users_name,
            u.users_image,
            v.video_date,
            COUNT(DISTINCT vc.comment_id) as comments_count
        FROM videos v
        LEFT JOIN users u ON v.video_userid = u.users_id
        LEFT JOIN video_comments vc ON v.video_id = vc.video_id
        WHERE v.video_product_id = ?
        GROUP BY v.video_id
        ORDER BY v.video_date DESC
        LIMIT ?, ?
    ");
    
    $stmt->execute([$item_id, $offset, $limit]);
    $videos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // جلب العدد الكلي
    $countStmt = $con->prepare("
        SELECT COUNT(*) as total
        FROM videos
        WHERE video_product_id = ?
    ");
    $countStmt->execute([$item_id]);
    $countResult = $countStmt->fetch(PDO::FETCH_ASSOC);
    $totalVideos = intval($countResult['total']);

    if (count($videos) > 0) {
        echo json_encode([
            'status' => 'success',
            'data' => $videos,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $totalVideos,
                'pages' => ceil($totalVideos / $limit)
            ]
        ]);
    } else {
        echo json_encode([
            'status' => 'failure',
            'message' => 'No videos found',
            'data' => [],
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => 0,
                'pages' => 0
            ]
        ]);
    }

} catch (Exception $e) {
    error_log("Error in get_item_videos: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
