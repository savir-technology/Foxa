<?php
include "../connect.php";
require_once __DIR__ . "/../notifications/notification_helper.php";

$commentid = filterRequest("commentid");
$userid = filterRequest("userid");

if (!$commentid || !$userid) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    // تحقق إذا المستخدم عمل لايك قبل كده
    $check = $con->prepare("SELECT * FROM comment_likes WHERE comment_id = ? AND user_id = ?");
    $check->execute([$commentid, $userid]);
    $exists = $check->fetch(PDO::FETCH_ASSOC);

    if ($exists) {
        // إلغاء الإعجاب
        $delete = $con->prepare("DELETE FROM comment_likes WHERE comment_id = ? AND user_id = ?");
        $delete->execute([$commentid, $userid]);

        $con->prepare("UPDATE video_comments SET comment_likes = comment_likes - 1 WHERE comment_id = ?")
            ->execute([$commentid]);

        echo json_encode(["status" => "success", "action" => "unliked"]);
    } else {
        // إضافة إعجاب
        $insert = $con->prepare("INSERT INTO comment_likes (comment_id, user_id) VALUES (?, ?)");
        $insert->execute([$commentid, $userid]);

        $con->prepare("UPDATE video_comments SET comment_likes = comment_likes + 1 WHERE comment_id = ?")
            ->execute([$commentid]);

        $ownerStmt = $con->prepare("
            SELECT vc.user_id, vc.video_id, u.users_name
            FROM video_comments vc
            LEFT JOIN users u ON u.users_id = vc.user_id
            WHERE vc.comment_id = ?
            LIMIT 1
        ");
        $ownerStmt->execute([$commentid]);
        $owner = $ownerStmt->fetch(PDO::FETCH_ASSOC);

        if ($owner && (int)$owner['user_id'] !== (int)$userid) {
            $actorStmt = $con->prepare("SELECT users_name FROM users WHERE users_id = ? LIMIT 1");
            $actorStmt->execute([$userid]);
            $actor = $actorStmt->fetch(PDO::FETCH_ASSOC);
            $actorName = trim((string)($actor['users_name'] ?? 'مستخدم'));

            notifyUser(
                $con,
                (int)$owner['user_id'],
                'comment_like',
                'تفاعل جديد على تعليقك',
                $actorName . ' أعجب بتعليقك',
                'video_comment',
                (int)$commentid,
                [
                    'video_id' => (string)($owner['video_id'] ?? ''),
                    'comment_id' => (string)$commentid,
                ],
                true
            );
        }

        echo json_encode(["status" => "success", "action" => "liked"]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
