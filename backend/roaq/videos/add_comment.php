<?php
include "../connect.php";
require_once __DIR__ . "/../notifications/notification_helper.php";

$videoid = filterRequest("videoid");
$userid = filterRequest("userid");
$comment = filterRequest("comment");
$parentid = filterRequest("parentid"); // لو رد على تعليق

if (!$videoid || !$userid || !$comment) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    $stmt = $con->prepare("
        INSERT INTO video_comments (video_id, user_id, parent_id, comment_text)
        VALUES (:videoid, :userid, :parentid, :comment)
    ");
    $stmt->execute([
        ":videoid" => $videoid,
        ":userid" => $userid,
        ":parentid" => $parentid ?: null,
        ":comment" => $comment
    ]);

    $commentId = (int)$con->lastInsertId();

    if (!empty($parentid)) {
        $parentStmt = $con->prepare("
            SELECT vc.user_id, u.users_name
            FROM video_comments vc
            LEFT JOIN users u ON u.users_id = vc.user_id
            WHERE vc.comment_id = ?
            LIMIT 1
        ");
        $parentStmt->execute([$parentid]);
        $parentComment = $parentStmt->fetch(PDO::FETCH_ASSOC);

        if ($parentComment && (int)$parentComment['user_id'] !== (int)$userid) {
            $authorStmt = $con->prepare("SELECT users_name FROM users WHERE users_id = ? LIMIT 1");
            $authorStmt->execute([$userid]);
            $author = $authorStmt->fetch(PDO::FETCH_ASSOC);
            $authorName = trim((string)($author['users_name'] ?? 'مستخدم'));

            notifyUser(
                $con,
                (int)$parentComment['user_id'],
                'comment_reply',
                'رد جديد على تعليقك',
                $authorName . ' رد على تعليقك: ' . substr($comment, 0, 80),
                'video_comment',
                $commentId,
                [
                    'video_id' => (string)$videoid,
                    'comment_id' => (string)$commentId,
                    'parent_comment_id' => (string)$parentid,
                ],
                true
            );
        }
    }

    echo json_encode([
        "status" => "success",
        "message" => "Comment added successfully",
        "comment_id" => $commentId
    ]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
