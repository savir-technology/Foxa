<?php
include "../connect.php";
ensureAleppoFoodOrderingSchema();
header('Content-Type: application/json; charset=utf-8');
$payload = getRequestPayload();
$restaurantId = isset($payload['restaurant_id']) ? (int)$payload['restaurant_id'] : 0;
$userLat = isset($payload['lat']) && is_numeric($payload['lat']) ? (float)$payload['lat'] : null;
$userLng = isset($payload['lng']) && is_numeric($payload['lng']) ? (float)$payload['lng'] : null;
if ($restaurantId <= 0) {
    respondJson([
        'status' => 'failure',
        'message' => 'Restaurant id is required',
    ], 422);
}
function assetUrlForRestaurant($path, $fallbackFolder = 'uploads/restaurants')
{
    $value = trim((string)$path);
    if ($value === '') {
        return '';
    }
    if (strpos($value, 'http://') === 0 || strpos($value, 'https://') === 0) {
        return $value;
    }
    $value = ltrim($value, '/');
    if (strpos($value, 'uploads/') === 0 || strpos($value, 'uploud/') === 0) {
        return 'https://savir-technology.online/roaqv2/' . $value;
    }
    return 'https://savir-technology.online/roaqv2/' . $fallbackFolder . '/' . $value;
}
function restaurantTables()
{
    return [
        'profiles' => tableExists('restaurant_profiles'),
        'branches' => tableExists('restaurant_branches'),
        'hours' => tableExists('restaurant_hours'),
        'settings' => tableExists('vendor_store_settings'),
    ];
}
function restaurantDayKeys()
{
    $index = (int)date('N');
    $map = [
        1 => ['mon', 'monday'],
        2 => ['tue', 'tuesday'],
        3 => ['wed', 'wednesday'],
        4 => ['thu', 'thursday'],
        5 => ['fri', 'friday'],
        6 => ['sat', 'saturday'],
        7 => ['sun', 'sunday'],
    ];
    return $map[$index] ?? ['mon', 'monday'];
}
function restaurantHoursForVendor($vendorId, $fallbackJson = null)
{
    global $con;
    if (tableExists('restaurant_hours')) {
        $stmt = $con->prepare("
            SELECT day_key, opens_at, closes_at, is_open
            FROM restaurant_hours
            WHERE vendor_id = :vendor_id
              AND is_active = 1
        ");
        $stmt->execute([':vendor_id' => $vendorId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($rows)) {
            return $rows;
        }
    }
    return workingHoursRowsFromPayload($fallbackJson, $vendorId);
}
function restaurantHoursMap($rows)
{
    $map = [];
    foreach ($rows as $row) {
        $map[strtolower(trim((string)$row['day_key']))] = $row;
    }
    return $map;
}
function restaurantOpenState($restaurant, $hoursRows)
{
    $map = restaurantHoursMap($hoursRows);
    return restaurantOpenFromSchedule($restaurant, $map, time());
}
function slotPayload($time, $isTomorrow = false)
{
    $dateLabelAr = $isTomorrow ? 'غداً' : 'اليوم';
    $dateLabelEn = $isTomorrow ? 'Tomorrow' : 'Today';
    return [
        'label_ar' => $dateLabelAr . ' ' . date('g:i A', strtotime($time)),
        'label_en' => $dateLabelEn . ' ' . date('g:i A', strtotime($time)),
        'value' => date('Y-m-d', strtotime($isTomorrow ? '+1 day' : 'today')) . 'T' . date('H:i:s', strtotime($time)),
    ];
}
function buildRestaurantSlots($isOpen, $hoursRows)
{
    $scheduled = [];
    $preorder = [];
    if (empty($hoursRows)) {
        for ($i = 1; $i <= 5; $i++) {
            $scheduled[] = slotPayload('+' . ($i * 30) . ' minutes');
        }
        return [$scheduled, $preorder];
    }
    $map = restaurantHoursMap($hoursRows);
    $todayRow = null;
    foreach (restaurantDayKeys() as $key) {
        if (isset($map[$key])) {
            $todayRow = $map[$key];
            break;
        }
    }
    $openAt = trim((string)($todayRow['opens_at'] ?? '10:00:00'));
    $closeAt = trim((string)($todayRow['closes_at'] ?? '23:00:00'));
    $start = strtotime(date('Y-m-d') . ' ' . $openAt);
    $end = strtotime(date('Y-m-d') . ' ' . $closeAt);
    if ($end <= $start) {
        $end += 86400;
    }
    $cursor = max(time() + 1800, $start);
    while ($cursor < $end && count($scheduled) < 6) {
        $scheduled[] = [
            'label_ar' => date('g:i A', $cursor),
            'label_en' => date('g:i A', $cursor),
            'value' => date('Y-m-d\TH:i:s', $cursor),
        ];
        $cursor += 1800;
    }
    if (!$isOpen) {
        for ($i = 0; $i < 4; $i++) {
            $preorder[] = slotPayload(date('H:i:s', $start + ($i * 7200)), $i > 1);
        }
    }
    return [$scheduled, $preorder];
}
try {
    $tables = restaurantTables();
    $profileJoin = $tables['profiles']
        ? "LEFT JOIN restaurant_profiles rp ON rp.vendor_id = v.vendor_id"
        : "";
    $profileSelect = $tables['profiles']
        ? "COALESCE(rp.tagline_ar, '') AS tagline_ar,
           COALESCE(rp.tagline_en, '') AS tagline_en,
           COALESCE(rp.cover_image, '') AS cover_image,
           COALESCE(rp.supports_scheduled_orders, 1) AS supports_scheduled_orders,
           COALESCE(rp.supports_pickup, 1) AS supports_pickup,
           rp.open_override AS manual_open_override,
           COALESCE(rp.family_score, 0) AS family_score"
        : "'' AS tagline_ar,
           '' AS tagline_en,
           '' AS cover_image,
           1 AS supports_scheduled_orders,
           1 AS supports_pickup,
           NULL AS manual_open_override,
           0 AS family_score";
    $branchJoin = $tables['branches']
        ? "LEFT JOIN (
                SELECT
                    vendor_id,
                    MIN(delivery_fee) AS delivery_fee,
                    MIN(estimated_min_minutes) AS estimated_min_minutes,
                    MAX(estimated_max_minutes) AS estimated_max_minutes,
                    AVG(latitude) AS latitude,
                    AVG(longitude) AS longitude
                FROM restaurant_branches
                WHERE is_active = 1
                GROUP BY vendor_id
            ) rb ON rb.vendor_id = v.vendor_id"
        : "";
    $branchSelect = $tables['branches']
        ? "COALESCE(rb.delivery_fee, 0) AS delivery_fee,
           COALESCE(rb.estimated_min_minutes, 25) AS estimated_min_minutes,
           COALESCE(rb.estimated_max_minutes, 45) AS estimated_max_minutes,
           rb.latitude,
           rb.longitude"
        : "0 AS delivery_fee,
           25 AS estimated_min_minutes,
           45 AS estimated_max_minutes,
           NULL AS latitude,
           NULL AS longitude";
    $settingsJoin = $tables['settings']
        ? "LEFT JOIN vendor_store_settings vs ON vs.vendor_id = v.vendor_id"
        : "";
    $settingsSelect = $tables['settings']
        ? "COALESCE(
               NULLIF(TRIM(vs.vendor_description), ''),
               NULLIF(TRIM(v.vendor_description), ''),
               ''
           ) AS vendor_description,
           COALESCE(vs.is_open, 1) AS store_is_open,
           vs.restaurant_working_hours_json,
           vs.working_hours_json,
           vs.store_name AS settings_store_name,
           vs.vendor_name AS settings_vendor_name,
           vs.vendor_logo AS settings_vendor_logo,
           vs.store_banner_url AS settings_store_banner_url,
           vs.store_latitude AS settings_store_latitude,
           vs.store_longitude AS settings_store_longitude"
        : "'' AS vendor_description,
           1 AS store_is_open,
           NULL AS restaurant_working_hours_json,
           NULL AS working_hours_json,
           '' AS settings_store_name,
           '' AS settings_vendor_name,
           NULL AS settings_vendor_logo,
           NULL AS settings_store_banner_url,
           NULL AS settings_store_latitude,
           NULL AS settings_store_longitude";
    $stmt = $con->prepare("
        SELECT
            v.vendor_id,
            v.vendor_name,
            v.store_name,
            v.store_slug,
            v.vendor_logo,
            COALESCE(v.vendor_type, 'restaurant') AS vendor_type,
            v.store_category,
            {$profileSelect},
            {$settingsSelect},
            {$branchSelect},
            COALESCE(rating_stats.average_rating, 0) AS average_rating,
            COALESCE(rating_stats.total_reviews, 0) AS total_reviews,
            COALESCE(item_stats.max_discount, 0) AS max_discount
        FROM vendors v
        {$profileJoin}
        {$settingsJoin}
        {$branchJoin}
        LEFT JOIN (
            SELECT
                i.vendor_id,
                ROUND(AVG(r.rating), 1) AS average_rating,
                COUNT(r.rating) AS total_reviews
            FROM items i
            LEFT JOIN ratings r ON r.item_id = i.items_id
            GROUP BY i.vendor_id
        ) rating_stats ON rating_stats.vendor_id = v.vendor_id
        LEFT JOIN (
            SELECT vendor_id, MAX(items_discount) AS max_discount
            FROM items
            WHERE items_active = 1
            GROUP BY vendor_id
        ) item_stats ON item_stats.vendor_id = v.vendor_id
        WHERE v.vendor_id = :vendor_id
          AND v.vendor_status = 'active'
          AND v.vendor_is_verified = 1
        LIMIT 1
    ");
    $stmt->execute([':vendor_id' => $restaurantId]);
    $restaurant = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$restaurant) {
        respondJson(['status' => 'failure', 'message' => 'Restaurant not found'], 404);
    }
    $restaurantLat = $restaurant['settings_store_latitude'] ?? $restaurant['latitude'] ?? null;
    $restaurantLng = $restaurant['settings_store_longitude'] ?? $restaurant['longitude'] ?? null;
    $distanceKm = null;
    if ($userLat !== null && $userLng !== null && is_numeric($restaurantLat) && is_numeric($restaurantLng)) {
        $distanceKm = round(distance($userLat, $userLng, (float)$restaurantLat, (float)$restaurantLng), 1);
    }
    $hoursRows = restaurantHoursForVendor(
        $restaurantId,
        $restaurant['restaurant_working_hours_json'] ?? $restaurant['working_hours_json'] ?? null
    );
    $isOpen = restaurantOpenState($restaurant, $hoursRows);
    list($scheduledSlots, $preorderSlots) = buildRestaurantSlots($isOpen, $hoursRows);
    $logoSource = trim((string)($restaurant['settings_vendor_logo'] ?? ''));
    if ($logoSource === '') {
        $logoSource = trim((string)($restaurant['vendor_logo'] ?? ''));
    }
    $coverSource = trim((string)($restaurant['settings_store_banner_url'] ?? ''));
    if ($coverSource === '') {
        $coverSource = trim((string)($restaurant['cover_image'] ?? ''));
    }
    if ($coverSource === '') {
        $coverSource = $logoSource;
    }
    $restaurantName = trim((string)(
        $restaurant['settings_store_name']
        ?: $restaurant['store_name']
        ?: $restaurant['settings_vendor_name']
        ?: $restaurant['vendor_name']
    ));
    if ($restaurantName === '') {
        $restaurantName = 'Restaurant';
    }
    $itemsStmt = $con->prepare("
        SELECT
            i.items_id,
            i.vendor_id,
            i.items_name_ar,
            i.items_name_en,
            i.items_desc_ar,
            i.items_desc_en,
            i.items_image,
            i.items_price,
            i.items_discount,
            i.items_count,
            i.items_cat,
            i.product_type,
            i.stock_unit,
            i.stock_step,
            c.categories_name_ar,
            c.categories_name_en,
            c.categories_id,
            COALESCE(mods.modifier_groups_count, 0) AS modifier_groups_count
        FROM items i
        LEFT JOIN categories c ON c.categories_id = i.items_cat
        LEFT JOIN (
            SELECT item_id, COUNT(*) AS modifier_groups_count
            FROM food_item_modifier_groups
            WHERE is_active = 1
            GROUP BY item_id
        ) mods ON mods.item_id = i.items_id
        WHERE i.vendor_id = :vendor_id
          AND i.items_active = 1
        ORDER BY c.categories_id ASC, i.items_id DESC
    ");
    $itemsStmt->execute([':vendor_id' => $restaurantId]);
    $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
    $categories = [];
    $categorySeen = [];
    $menuItems = [];
    foreach ($items as $item) {
        $categoryId = (string)($item['categories_id'] ?? 'uncategorized');
        if (!isset($categorySeen[$categoryId])) {
            $categories[] = [
                'id' => $categoryId,
                'name_ar' => trim((string)($item['categories_name_ar'] ?? 'وجبات')),
                'name_en' => trim((string)($item['categories_name_en'] ?? 'Meals')),
            ];
            $categorySeen[$categoryId] = true;
        }
        $originalPrice = (float)($item['items_price'] ?? 0);
        $discount = (float)($item['items_discount'] ?? 0);
        $finalPrice = $originalPrice - ($originalPrice * ($discount / 100));
        $menuItems[] = [
            'id' => (string)$item['items_id'],
            'vendor_id' => (string)$item['vendor_id'],
            'category_id' => $categoryId,
            'name_ar' => trim((string)($item['items_name_ar'] ?? '')),
            'name_en' => trim((string)($item['items_name_en'] ?? '')),
            'description_ar' => trim((string)($item['items_desc_ar'] ?? '')),
            'description_en' => trim((string)($item['items_desc_en'] ?? '')),
            'image_url' => assetUrlForRestaurant($item['items_image'], 'uploud/items'),
            'price' => round($finalPrice, 2),
            'compare_price' => $discount > 0 ? round($originalPrice, 2) : null,
            'has_discount' => $discount > 0,
            'is_available' => (int)($item['items_count'] ?? 0) > 0,
            'items_count' => (string)($item['items_count'] ?? 0),
            'has_modifiers' => (int)($item['modifier_groups_count'] ?? 0) > 0,
            'product_type' => (string)($item['product_type'] ?? 'food'),
            'stock_unit' => (string)($item['stock_unit'] ?? 'piece'),
            'stock_step' => (string)($item['stock_step'] ?? '1'),
            'store_category' => (string)($restaurant['store_category'] ?? ''),
        ];
    }
    $response = [
        'status' => 'success',
        'data' => [
            'restaurant' => [
                'id' => (int)$restaurant['vendor_id'],
                'vendor_type' => ($restaurant['vendor_type'] ?? 'restaurant') === 'store' ? 'store' : 'restaurant',
                'entity_label_ar' => ($restaurant['vendor_type'] ?? 'restaurant') === 'store' ? 'متجر' : 'مطعم',
                'entity_label_en' => ($restaurant['vendor_type'] ?? 'restaurant') === 'store' ? 'Store' : 'Restaurant',
                'name' => $restaurantName,
                'slug' => trim((string)($restaurant['store_slug'] ?? '')),
                'vendor_description' => trim((string)($restaurant['vendor_description'] ?? '')),
                'tagline_ar' => trim((string)($restaurant['tagline_ar'] ?? '')),
                'tagline_en' => trim((string)($restaurant['tagline_en'] ?? '')),
                'logo_url' => assetUrlForRestaurant($logoSource, 'uploads/vendors/logo'),
                'cover_image_url' => $coverSource !== ''
                    ? assetUrlForRestaurant($coverSource)
                    : '',
                'rating' => round((float)($restaurant['average_rating'] ?? 0), 1),
                'reviews_count' => (int)($restaurant['total_reviews'] ?? 0),
                'delivery_fee' => round((float)($restaurant['delivery_fee'] ?? 0), 2),
                'estimated_min_minutes' => (int)($restaurant['estimated_min_minutes'] ?? 25),
                'estimated_max_minutes' => (int)($restaurant['estimated_max_minutes'] ?? 45),
                'is_open' => $isOpen,
                'supports_scheduled_orders' => (int)($restaurant['supports_scheduled_orders'] ?? 1) === 1,
                'supports_pickup' => (int)($restaurant['supports_pickup'] ?? 1) === 1,
                'distance_km' => $distanceKm,
                'badges_ar' => (float)($restaurant['delivery_fee'] ?? 0) <= 0 ? ['توصيل مجاني'] : [],
                'badges_en' => (float)($restaurant['delivery_fee'] ?? 0) <= 0
                    ? ['Free delivery for this ' . (($restaurant['vendor_type'] ?? 'restaurant') === 'store' ? 'store' : 'restaurant')]
                    : [],
            ],
            'order_modes' => [
                'asap_enabled' => $isOpen,
                'asap_label_ar' => 'أسرع وقت ممكن',
                'asap_label_en' => 'As soon as possible',
                'scheduled_slots' => $scheduledSlots,
                'preorder_slots' => $preorderSlots,
            ],
            'menu_categories' => $categories,
            'menu_items' => $menuItems,
        ],
    ];
    respondJson($response);
} catch (Throwable $e) {
    respondJson([
        'status' => 'failure',
        'message' => $e->getMessage(),
    ], 500);
}
