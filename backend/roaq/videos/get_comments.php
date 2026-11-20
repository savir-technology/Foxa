<?php
include "../connect.php";

$videoid = filterRequest("videoid");

if (!$videoid) {
    echo json_encode(["status" => "error", "message" => "Missing video ID"]);
    exit;
}

try {
    // جلب التعليقات الأساسية
    $stmt = $con->prepare("
        SELECT 
            c.comment_id,
            c.video_id,
            c.user_id,
            c.comment_text,
            c.comment_likes,
            c.comment_date,
            u.users_name,
            u.user_role
        FROM video_comments c
        JOIN users u ON c.user_id = u.users_id
        WHERE c.video_id = ? AND c.parent_id IS NULL
        ORDER BY c.comment_date DESC
    ");
    $stmt->execute([$videoid]);
    $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // جلب الردود لكل تعليق
    foreach ($comments as &$comment) {
        $stmt2 = $con->prepare("
            SELECT 
                c.comment_id,
                c.user_id,
                c.comment_text,
                c.comment_likes,
                c.comment_date,
                u.users_name,
                u.user_role
            FROM video_comments c
            JOIN users u ON c.user_id = u.users_id
            WHERE c.parent_id = ?
            ORDER BY c.comment_date ASC
        ");
        $stmt2->execute([$comment['comment_id']]);
        $comment['replies'] = $stmt2->fetchAll(PDO::FETCH_ASSOC);
    }

    echo json_encode([
        "status" => "success",
        "data" => $comments
    ]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
