<?php
include "../connect.php";
require_once "../asset_urls.php";

header("Content-Type: application/json; charset=utf-8");

function normalizeAdsTargetRow(array $row)
{
    $linkUrl = trim((string) ($row['link_url'] ?? ''));
    $currentType = strtolower(trim((string) ($row['target_type'] ?? '')));
    $currentId = (int) ($row['target_id'] ?? 0);

    $targetType = '';
    $targetId = 0;

    if (in_array($currentType, ['restaurant', 'product'], true)) {
        $targetType = $currentType;
        $targetId = $currentId > 0 ? $currentId : 0;
    }

    if (preg_match('/^(product|item|restaurant):\s*(\d+)$/i', $linkUrl, $matches)) {
        $targetType = strtolower($matches[1]);
        if ($targetType === 'item') {
            $targetType = 'product';
        }
        $targetId = (int) $matches[2];
    }

    if (!in_array($targetType, ['restaurant', 'product'], true)) {
        $targetType = 'restaurant';
        $targetId = 0;
    }

    $canonicalLink = $targetId > 0 ? $targetType . ':' . $targetId : null;

    return [
        'target_type' => $targetType,
        'target_id' => $targetId > 0 ? $targetId : null,
        'link_url' => $canonicalLink,
    ];
}

try {
    $query = "
        SELECT
            id,
            title_ar,
            title_en,
            image_url,
            link_url,
            target_type,
            target_id,
            placement,
            sort_order,
            display_seconds,
            is_active,
            open_in_webview,
            created_at
        FROM ads
        WHERE is_active = 1
        ORDER BY sort_order ASC, created_at DESC
    ";

    $stmt = $con->prepare($query);
    $stmt->execute();

    $ads = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $normalizedTarget = normalizeAdsTargetRow($row);
        $ads[] = [
            "id" => $row["id"],
            "title" => trim((string)($row["title_ar"] ?? $row["title_en"] ?? "")),
            "title_ar" => $row["title_ar"],
            "title_en" => $row["title_en"],
            "image_url" => zahra_ad_image_url($row["image_url"] ?? ""),
            "link_url" => $normalizedTarget["link_url"],
            "target_type" => $normalizedTarget["target_type"] ?? "restaurant",
            "target_id" => $normalizedTarget["target_id"],
            "placement" => trim((string)($row["placement"] ?? "home_middle")),
            "sort_order" => isset($row["sort_order"]) ? (int)$row["sort_order"] : 0,
            "display_seconds" => isset($row["display_seconds"]) ? (int)$row["display_seconds"] : 8,
            "is_active" => isset($row["is_active"]) ? (int)$row["is_active"] : 1,
            "open_in_webview" => isset($row["open_in_webview"]) ? (int)$row["open_in_webview"] : 0,
            "created_at" => $row["created_at"]
        ];
    }

    echo json_encode($ads);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
