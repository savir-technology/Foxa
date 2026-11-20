<?php
include "../connect.php";

$videoid = filterRequest("videoid");
$userid = filterRequest("userid");

if (!$videoid) {
    echo json_encode(["status" => "error", "message" => "Missing video ID"]);
    exit;
}

try {
    // تسجيل المشاهدة
    $ins = $con->prepare("INSERT INTO video_views (video_id, user_id) VALUES (?, ?)");
    $ins->execute([$videoid, $userid ?? null]);

    // زيادة العدد الإجمالي
    $upd = $con->prepare("UPDATE videos SET video_views = video_views + 1 WHERE video_id = ?");
    $upd->execute([$videoid]);

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
