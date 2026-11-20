<?php
include "../../../connect.php";
include "../story_helpers.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    storyFailResponse("Invalid request method", 405);
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$id = (int) ($_POST['id'] ?? 0);

if ($id <= 0) {
    storyFailResponse("Invalid story id");
}

$currentStmtSql = "
    SELECT story_id, vendor_id, media_type, image_url, video_url
    FROM restaurant_stories
    WHERE story_id = ?
";
$currentParams = [$id];
if ($isVendor) {
    $currentStmtSql .= " AND vendor_id = ?";
    $currentParams[] = (int)($actor['vendor']['vendor_id'] ?? 0);
}

$currentStmt = $con->prepare($currentStmtSql);
$currentStmt->execute($currentParams);
$current = $currentStmt->fetch(PDO::FETCH_ASSOC);
if (!$current) {
    storyFailResponse("Story not found", 404);
}

$vendorId = $isVendor ? (int)($actor['vendor']['vendor_id'] ?? 0) : (int)($_POST['vendor_id'] ?? (int)($current['vendor_id'] ?? 0));
if ($vendorId <= 0) {
    storyFailResponse("Vendor id is required");
}

if (!$isVendor && $vendorId !== (int)($current['vendor_id'] ?? 0)) {
    $vendorStmt = $con->prepare("SELECT vendor_id FROM vendors WHERE vendor_id = ?");
    $vendorStmt->execute([$vendorId]);
    if (!$vendorStmt->fetchColumn()) {
        storyFailResponse("Vendor not found", 404);
    }
}

$titleAr = trim($_POST['title_ar'] ?? '');
$titleEn = trim($_POST['title_en'] ?? '');
$mediaType = strtolower(trim($_POST['media_type'] ?? ($current['media_type'] ?? 'image')));
$ctaLabelAr = trim($_POST['cta_label_ar'] ?? '');
$ctaLabelEn = trim($_POST['cta_label_en'] ?? '');
$targetType = normalizeStoryTargetType($_POST['target_type'] ?? 'restaurant');
$targetId = (int) ($_POST['target_id'] ?? 0);
$sortOrder = (int) ($_POST['sort_order'] ?? 0);
$isActive = isset($_POST['is_active']) ? (int) $_POST['is_active'] : 1;
$startsAt = storyNormalizeDateTimeInput($_POST['starts_at'] ?? '');
$endsAt = storyNormalizeDateTimeInput($_POST['ends_at'] ?? '');

if (!in_array($mediaType, ['image', 'video'], true)) {
    storyFailResponse("Media type must be image or video");
}

if (!in_array($targetType, ['restaurant', 'product'], true)) {
    storyFailResponse("Target must be restaurant or product");
}

if ($targetId <= 0) {
    storyFailResponse("Target id is required");
}

$existingImageUrl = trim((string)($current['image_url'] ?? ''));
$existingVideoUrl = trim((string)($current['video_url'] ?? ''));
$existingMediaType = strtolower(trim((string)($current['media_type'] ?? 'image')));

$imageUrl = $existingImageUrl !== '' ? $existingImageUrl : null;
$videoUrl = $existingVideoUrl !== '' ? $existingVideoUrl : null;
$newImageUploaded = isset($_FILES['image']) && is_uploaded_file($_FILES['image']['tmp_name']);
$newVideoUploaded = isset($_FILES['video']) && is_uploaded_file($_FILES['video']['tmp_name']);

try {
    if ($mediaType === 'image') {
        if ($newImageUploaded) {
            $imageUrl = storyUploadMediaFile($_FILES['image'], 'story_image');
            if ($existingImageUrl !== '' && $existingImageUrl !== $imageUrl) {
                storyDeleteLocalMedia($existingImageUrl);
            }
        }

        if (trim((string)$imageUrl) === '') {
            storyFailResponse("Story image is required");
        }

        if ($existingMediaType === 'video' && $existingVideoUrl !== '') {
            storyDeleteLocalMedia($existingVideoUrl);
        }

        $videoUrl = null;
    } else {
        if ($newVideoUploaded) {
            $videoUrl = storyUploadMediaFile($_FILES['video'], 'story_video');
            if ($existingVideoUrl !== '' && $existingVideoUrl !== $videoUrl) {
                storyDeleteLocalMedia($existingVideoUrl);
            }
        }

        if (trim((string)$videoUrl) === '') {
            storyFailResponse("Story video is required");
        }

        if ($newImageUploaded) {
            $imageUrl = storyUploadMediaFile($_FILES['image'], 'story_image');
            if ($existingImageUrl !== '' && $existingImageUrl !== $imageUrl) {
                storyDeleteLocalMedia($existingImageUrl);
            }
        }

        if (trim((string)$imageUrl) === '') {
            $imageUrl = $existingImageUrl !== '' ? $existingImageUrl : null;
        }
    }

    $updateStmt = $con->prepare("
        UPDATE restaurant_stories SET
            vendor_id = ?,
            title_ar = ?,
            title_en = ?,
            media_type = ?,
            image_url = ?,
            video_url = ?,
            cta_label_ar = ?,
            cta_label_en = ?,
            target_type = ?,
            target_id = ?,
            sort_order = ?,
            starts_at = ?,
            ends_at = ?,
            is_active = ?,
            updated_at = NOW()
        WHERE story_id = ?
    ");

    $updateStmt->execute([
        $vendorId,
        $titleAr,
        $titleEn,
        $mediaType,
        $imageUrl,
        $videoUrl,
        $ctaLabelAr,
        $ctaLabelEn,
        $targetType,
        $targetId,
        $sortOrder,
        $startsAt,
        $endsAt,
        $isActive ? 1 : 0,
        $id,
    ]);

    echo json_encode([
        "status" => "success",
        "message" => "Story updated successfully",
        "data" => [
            "id" => $id,
            "vendor_id" => $vendorId,
            "title_ar" => $titleAr,
            "title_en" => $titleEn,
            "media_type" => $mediaType,
            "image_url" => $imageUrl,
            "video_url" => $videoUrl,
            "cta_label_ar" => $ctaLabelAr,
            "cta_label_en" => $ctaLabelEn,
            "target_type" => $targetType,
            "target_id" => $targetId,
            "sort_order" => $sortOrder,
            "starts_at" => $startsAt,
            "ends_at" => $endsAt,
            "is_active" => $isActive ? 1 : 0,
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    storyFailResponse($e->getMessage(), 500);
}
