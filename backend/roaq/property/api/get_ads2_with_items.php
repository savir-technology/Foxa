<?php
require_once '../../connect.php';
require_once '../../asset_urls.php';
header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $con->prepare("
        SELECT 
            a.id,
            a.image_url,
            a.created_at,
            a.link_url,
            a.target_type,
            a.target_id,
            a.placement,
            a.sort_order,
            a.display_seconds,
            a.is_active,
            a.open_in_webview,
            a.item_id,
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            i.items_image,
            i.items_price,
            i.items_discount,
            i.property_rooms,
            i.property_bathrooms,
            i.property_floor,
            i.property_area
        FROM ads2 a
        LEFT JOIN items i ON a.item_id = i.items_id
        WHERE a.is_active = 1
        ORDER BY a.sort_order ASC, a.created_at DESC
    ");

    $stmt->execute();
    $ads = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    foreach ($ads as &$ad) {
        $ad['image_url'] = zahra_ad_image_url($ad['image_url'] ?? '');
        $ad['items_image_url'] = zahra_item_image_url($ad['items_image'] ?? '');
    }
    unset($ad);

    echo json_encode([
        'status' => !empty($ads) ? 'success' : 'failure',
        'message' => !empty($ads) ? null : 'No ads found',
        'data' => $ads,
        'count' => count($ads),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Exception $e) {
    error_log("Error in get_ads2_with_items: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
