<?php
include "../../../connect.php";
include "../story_helpers.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$vendorId = $isVendor ? (int)($actor['vendor']['vendor_id'] ?? 0) : 0;
$requestedVendorId = isset($_GET['vendor_id']) ? (int)$_GET['vendor_id'] : 0;
$targetVendorId = $isVendor ? $vendorId : $requestedVendorId;

try {
    $sql = "
        SELECT
            s.story_id,
            s.vendor_id,
            s.title_ar,
            s.title_en,
            s.media_type,
            s.image_url,
            s.video_url,
            s.cta_label_ar,
            s.cta_label_en,
            s.target_type,
            s.target_id,
            s.sort_order,
            s.starts_at,
            s.ends_at,
            s.is_active,
            s.created_at,
            s.updated_at,
            v.vendor_name,
            v.store_name
        FROM restaurant_stories s
        LEFT JOIN vendors v ON v.vendor_id = s.vendor_id
    ";

    $params = [];
    if ($targetVendorId > 0) {
        $sql .= " WHERE s.vendor_id = :vendor_id";
        $params[':vendor_id'] = $targetVendorId;
    }

    $sql .= " ORDER BY s.vendor_id DESC, s.sort_order ASC, s.story_id DESC";

    $stmt = $con->prepare($sql);
    $stmt->execute($params);

    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $data = array_map(function ($row) {
        $vendorId = (int) ($row['vendor_id'] ?? 0);
        $targetType = normalizeStoryTargetType($row['target_type'] ?? 'restaurant');
        $targetId = (int) ($row['target_id'] ?? 0);
        if ($targetId <= 0 && $vendorId > 0) {
            $targetId = $vendorId;
        }

        return [
            'id' => (int) ($row['story_id'] ?? 0),
            'vendor_id' => $vendorId,
            'vendor_name' => trim((string) ($row['vendor_name'] ?? '')),
            'store_name' => trim((string) ($row['store_name'] ?? '')),
            'title_ar' => trim((string) ($row['title_ar'] ?? '')),
            'title_en' => trim((string) ($row['title_en'] ?? '')),
            'media_type' => strtolower(trim((string) ($row['media_type'] ?? 'image'))) ?: 'image',
            'image_url' => storyResolveMediaUrl($row['image_url'] ?? ''),
            'video_url' => storyResolveMediaUrl($row['video_url'] ?? ''),
            'cta_label_ar' => trim((string) ($row['cta_label_ar'] ?? '')),
            'cta_label_en' => trim((string) ($row['cta_label_en'] ?? '')),
            'target_type' => $targetType,
            'target_id' => $targetId,
            'sort_order' => (int) ($row['sort_order'] ?? 0),
            'starts_at' => $row['starts_at'] ?? null,
            'ends_at' => $row['ends_at'] ?? null,
            'is_active' => (int) ($row['is_active'] ?? 1),
            'created_at' => $row['created_at'] ?? null,
            'updated_at' => $row['updated_at'] ?? null,
        ];
    }, $rows);

    echo json_encode([
        'status' => 'success',
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'failure',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
