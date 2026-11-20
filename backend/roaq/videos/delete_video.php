<?php
include "../connect.php";

$video_id = $_POST['video_id'] ?? null;

if ($video_id) {
    // استرجاع مسار الفيديو لحذفه من السيرفر
    $stmt = $con->prepare("SELECT video_url FROM videos WHERE video_id = ?");
    $stmt->execute([$video_id]);
    $video = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($video) {
        $videoPath = str_replace("https://savir-technology.online/roaqv2/", "../", $video['video_url']);
        if (file_exists($videoPath)) {
            unlink($videoPath);
        }

        $delete = $con->prepare("DELETE FROM videos WHERE video_id = ?");
        $delete->execute([$video_id]);

        echo json_encode(["status" => "success", "message" => "Video deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Video not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Missing video_id"]);
}
?>
