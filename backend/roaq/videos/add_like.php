<?php
include "../connect.php";

$videoid = filterRequest("videoid");
$userid = filterRequest("userid");

if (!$videoid || !$userid) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    // تحقق إذا المستخدم عمل لايك قبل كده
    $check = $con->prepare("SELECT * FROM video_likes WHERE video_id = ? AND user_id = ?");
    $check->execute([$videoid, $userid]);
    $exists = $check->fetch(PDO::FETCH_ASSOC);

    if ($exists) {
        // إلغاء اللايك
        $delete = $con->prepare("DELETE FROM video_likes WHERE video_id = ? AND user_id = ?");
        $delete->execute([$videoid, $userid]);

        // ناقص نحدث عدد اللايكات في الجدول الرئيسي
        $con->prepare("UPDATE videos SET video_likes = video_likes - 1 WHERE video_id = ?")
            ->execute([$videoid]);

        echo json_encode(["status" => "success", "action" => "unliked"]);
    } else {
        // إضافة لايك جديد
        $insert = $con->prepare("INSERT INTO video_likes (video_id, user_id) VALUES (?, ?)");
        $insert->execute([$videoid, $userid]);

        // تحديث عدد اللايكات في الجدول الرئيسي
        $con->prepare("UPDATE videos SET video_likes = video_likes + 1 WHERE video_id = ?")
            ->execute([$videoid]);

        echo json_encode(["status" => "success", "action" => "liked"]);
    }
} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
