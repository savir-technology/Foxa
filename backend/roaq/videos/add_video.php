<?php
include "../connect.php";
require_once __DIR__ . "/../notifications/notification_helper.php";

// فحص هل تم رفع ملف
if (isset($_FILES['video_file'])) {
    $videoName = $_FILES['video_file']['name'];
    $videoTmp = $_FILES['video_file']['tmp_name'];
    $videoTitle = trim((string) ($_POST['video_title'] ?? ''));
    $videoDesc = trim((string) ($_POST['video_desc'] ?? ''));
    $normalizedTarget = normalizeVideoTargetPair(
        $_POST['target_type'] ?? '',
        $_POST['target_id'] ?? 0
    );
    $legacyProductId = $normalizedTarget['video_product_id'];
    $targetId = $normalizedTarget['target_id'] > 0 ? $normalizedTarget['target_id'] : null;

    $uploadDir = "../uploud/video/";
    $newFileName = uniqid() . "_" . basename($videoName);
    $filePath = $uploadDir . $newFileName;

    if (move_uploaded_file($videoTmp, $filePath)) {
        $videoUrl = "https://savir-technology.online/roaqv2/uploud/video/" . $newFileName;

        $stmt = $con->prepare("
            INSERT INTO videos (
                video_title,
                video_desc,
                video_url,
                video_product_id,
                video_target_type,
                video_target_id
            ) VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $videoTitle,
            $videoDesc,
            $videoUrl,
            $legacyProductId,
            $normalizedTarget['target_type'],
            $targetId,
        ]);
        $videoId = (int)$con->lastInsertId();

        broadcastNotification(
            $con,
            'new_video',
            'تمت إضافة فيديو جديد',
            $videoTitle ?: 'شاهد أحدث فيديو تمت إضافته الآن',
            'video',
            $videoId,
            [
                'video_id' => (string)$videoId,
            ],
            null
        );

        echo json_encode(["status" => "success", "message" => "Video uploaded successfully", "url" => $videoUrl]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to upload video"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "No video file provided"]);
}
?>
