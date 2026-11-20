<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';
require_once '../../../asset_urls.php';

try {
    $stmt = $con->prepare("
        SELECT
            a.id,
            a.title_ar,
            a.title_en,
            a.image_url,
            a.link_url,
            a.target_type,
            a.target_id,
            a.placement,
            a.sort_order,
            a.display_seconds,
            a.is_active,
            a.created_at,
            a.updated_at
        FROM ads a
        WHERE a.is_active = 1
        ORDER BY a.sort_order ASC, a.created_at DESC, a.id DESC
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    foreach ($rows as &$row) {
        $row['image_url'] = zahra_ad_image_url($row['image_url'] ?? '');
    }
    unset($row);

    echo json_encode([
        'status' => 'success',
        'data' => $rows,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
