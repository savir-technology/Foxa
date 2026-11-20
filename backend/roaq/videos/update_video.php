<?php
include "../connect.php";

$video_id = $_POST['video_id'] ?? null;
$video_title = trim((string) ($_POST['video_title'] ?? ''));
$video_desc = trim((string) ($_POST['video_desc'] ?? ''));

if (!$video_id) {
    echo json_encode(["status" => "error", "message" => "Missing video_id"]);
    exit;
}

$stmtCurrent = $con->prepare("
    SELECT video_url, video_target_type, video_target_id, video_product_id
    FROM videos
    WHERE video_id = ?
");
$stmtCurrent->execute([$video_id]);
$current = $stmtCurrent->fetch(PDO::FETCH_ASSOC) ?: [];

if (empty($current)) {
    echo json_encode(["status" => "error", "message" => "Video not found"]);
    exit;
}

$existingTargetType = $current['video_target_type'] ?? '';
$existingTargetId = $current['video_target_id'] ?? 0;
$existingProductId = $current['video_product_id'] ?? 0;
$normalizedTarget = normalizeVideoTargetPair(
    $_POST['target_type'] ?? $existingTargetType,
    $_POST['target_id'] ?? $existingTargetId,
    $existingProductId
);
$legacyProductId = $normalizedTarget['video_product_id'];
$targetId = $normalizedTarget['target_id'] > 0 ? $normalizedTarget['target_id'] : null;

// لو فيه ملف جديد اترفع
if (isset($_FILES['video_file'])) {
    // حذف الفيديو القديم من السيرفر
    if (!empty($current['video_url'])) {
        $oldPath = str_replace("https://savir-technology.online/roaqv2/", "../", $current['video_url']);
        if (file_exists($oldPath)) {
            unlink($oldPath);
        }
    }

    // رفع الجديد
    $videoName = $_FILES['video_file']['name'];
    $videoTmp = $_FILES['video_file']['tmp_name'];
    $uploadDir = "../uploud/video/";
    $newFileName = uniqid() . "_" . basename($videoName);
    $filePath = $uploadDir . $newFileName;

    if (move_uploaded_file($videoTmp, $filePath)) {
        $videoUrl = "https://savir-technology.online/roaqv2/uploud/video/" . $newFileName;

        $stmt = $con->prepare("
            UPDATE videos
            SET video_title=?,
                video_desc=?,
                video_url=?,
                video_product_id=?,
                video_target_type=?,
                video_target_id=?
            WHERE video_id=?
        ");
        $stmt->execute([
            $video_title,
            $video_desc,
            $videoUrl,
            $legacyProductId,
            $normalizedTarget['target_type'],
            $targetId,
            $video_id,
        ]);

        echo json_encode(["status" => "success", "message" => "Video updated successfully", "url" => $videoUrl]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to upload new video"]);
    }
} else {
    // تحديث العنوان والوصف والتوجيه
    $stmt = $con->prepare("
        UPDATE videos
        SET video_title=?,
            video_desc=?,
            video_product_id=?,
            video_target_type=?,
            video_target_id=?
        WHERE video_id=?
    ");
    $stmt->execute([
        $video_title,
        $video_desc,
        $legacyProductId,
        $normalizedTarget['target_type'],
        $targetId,
        $video_id,
    ]);

    echo json_encode(["status" => "success", "message" => "Video info updated successfully"]);
}
?>
