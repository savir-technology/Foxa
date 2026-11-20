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
$vendorId = $isVendor ? (int)($actor['vendor']['vendor_id'] ?? 0) : (int)($_POST['vendor_id'] ?? 0);

if ($vendorId <= 0) {
    storyFailResponse("Vendor id is required");
}

if (!$isVendor) {
    $vendorStmt = $con->prepare("SELECT vendor_id FROM vendors WHERE vendor_id = ?");
    $vendorStmt->execute([$vendorId]);
    if (!$vendorStmt->fetchColumn()) {
        storyFailResponse("Vendor not found", 404);
    }
}

$titleAr = trim($_POST['title_ar'] ?? '');
$titleEn = trim($_POST['title_en'] ?? '');
$mediaType = strtolower(trim($_POST['media_type'] ?? 'image'));
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

$hasImage = isset($_FILES['image']) && is_uploaded_file($_FILES['image']['tmp_name']);
$hasVideo = isset($_FILES['video']) && is_uploaded_file($_FILES['video']['tmp_name']);

if ($mediaType === 'image' && !$hasImage) {
    storyFailResponse("Story image is required");
}

if ($mediaType === 'video' && !$hasVideo) {
    storyFailResponse("Story video is required");
}

$imageUrl = null;
$videoUrl = null;

try {
    if ($mediaType === 'image') {
        $imageUrl = storyUploadMediaFile($_FILES['image'], 'story_image');
    } else {
        $videoUrl = storyUploadMediaFile($_FILES['video'], 'story_video');
    }

    $stmt = $con->prepare("
        INSERT INTO restaurant_stories (
            vendor_id,
            title_ar,
            title_en,
            media_type,
            image_url,
            video_url,
            cta_label_ar,
            cta_label_en,
            target_type,
            target_id,
            sort_order,
            starts_at,
            ends_at,
            is_active,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ");

    $stmt->execute([
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
    ]);

    echo json_encode([
        "status" => "success",
        "message" => "Story created successfully",
        "data" => [
            "id" => (int)$con->lastInsertId(),
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
    if ($imageUrl !== null) {
        storyDeleteLocalMedia($imageUrl);
    }
    if ($videoUrl !== null) {
        storyDeleteLocalMedia($videoUrl);
    }

    storyFailResponse($e->getMessage(), 500);
}
