<?php
include "../connect.php";

$commentid = filterRequest("commentid");
$userid = filterRequest("userid");

if (!$commentid || !$userid) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    // جلب نوع المستخدم
    $stmt = $con->prepare("SELECT user_role FROM users WHERE users_id = ?");
    $stmt->execute([$userid]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user || $user['user_role'] !== 'admin') {
        echo json_encode(["status" => "error", "message" => "Unauthorized"]);
        exit;
    }

    // حذف التعليق (وأي ردود عليه بفضل ON DELETE CASCADE)
    $del = $con->prepare("DELETE FROM video_comments WHERE comment_id = ?");
    $del->execute([$commentid]);

    echo json_encode(["status" => "success", "message" => "Comment deleted"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
