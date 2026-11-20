<?php

include "../connect.php";
ensureAleppoFoodOrderingSchema();

header('Content-Type: application/json; charset=utf-8');

$payload = getRequestPayload();
$userLat = isset($payload['lat']) && is_numeric($payload['lat']) ? (float)$payload['lat'] : null;
$userLng = isset($payload['lng']) && is_numeric($payload['lng']) ? (float)$payload['lng'] : null;
$userId = isset($payload['userid']) && is_numeric($payload['userid']) ? (int)$payload['userid'] : 0;

$hasProfiles = tableExists('restaurant_profiles');
$hasBranches = tableExists('restaurant_branches');
$hasHours = tableExists('restaurant_hours');
$hasStoreSettings = tableExists('vendor_store_settings');
$hasStories = tableExists('restaurant_stories');
$hasBanners = tableExists('restaurant_banners');
$hasOccasions = tableExists('restaurant_occasions');

// Keep the home feed local to the user's current area. This also prevents
// vendors from another city from appearing just because they are active.
const HOME_NEARBY_RADIUS_KM = 25.0;

function mediaUrl($path, $fallbackFolder = 'uploads/restaurants')
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
        return appAssetUrl($value);
    }

    return appAssetUrl($fallbackFolder . '/' . $value);
}

function appAssetUrl($path)
{
    $base = 'https://savir-technology.online/roaqv2/';
    return $base . ltrim((string)$path, '/');
}

function safeColor($value, $fallback)
{
    $color = trim((string)$value);
    if (preg_match('/^#[0-9a-fA-F]{6}$/', $color)) {
        return $color;
    }
    return $fallback;
}

function boolValue($value)
{
    return (int)$value === 1 || $value === true || $value === '1';
}

function buildDayKeys()
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

function fetchHoursMap()
{
    global $con, $hasHours;
    if (!$hasHours) {
        return [];
    }

    $stmt = $con->prepare("
        SELECT vendor_id, day_key, is_open, opens_at, closes_at
        FROM restaurant_hours
        WHERE is_active = 1
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $map = [];
    foreach ($rows as $row) {
        $vendorId = (int)$row['vendor_id'];
        $dayKey = strtolower(trim((string)$row['day_key']));
        if (!isset($map[$vendorId])) {
            $map[$vendorId] = [];
        }
        $map[$vendorId][$dayKey] = $row;
    }

    return $map;
}

function restaurantIsOpen($restaurant, $hoursMap)
{
    return restaurantOpenFromSchedule($restaurant, $hoursMap, time());
}

function fetchRestaurants($userLat, $userLng, $hasProfiles, $hasBranches)
{
    global $con, $hasStoreSettings;

    $profileSelect = $hasProfiles
        ? "
            COALESCE(rp.tagline_ar, '') AS tagline_ar,
            COALESCE(rp.tagline_en, '') AS tagline_en,
            COALESCE(rp.cover_image, '') AS cover_image,
            COALESCE(rp.is_featured, 0) AS is_featured,
            COALESCE(rp.is_new, 0) AS is_new,
            COALESCE(rp.family_score, 0) AS family_score,
            COALESCE(rp.supports_scheduled_orders, 1) AS supports_scheduled_orders,
            COALESCE(rp.supports_pickup, 1) AS supports_pickup,
            rp.open_override AS manual_open_override,
            COALESCE(rp.sort_order, 0) AS profile_sort_order
        "
        : "
            '' AS tagline_ar,
            '' AS tagline_en,
            '' AS cover_image,
            0 AS is_featured,
            0 AS is_new,
            0 AS family_score,
            1 AS supports_scheduled_orders,
            1 AS supports_pickup,
            NULL AS manual_open_override,
            0 AS profile_sort_order
        ";

    $profileJoin = $hasProfiles
        ? "LEFT JOIN restaurant_profiles rp ON rp.vendor_id = v.vendor_id"
        : "";

    $branchSelect = $hasBranches
        ? "
            COALESCE(rb.delivery_fee, 0) AS delivery_fee,
            COALESCE(rb.estimated_min_minutes, 25) AS estimated_min_minutes,
            COALESCE(rb.estimated_max_minutes, 45) AS estimated_max_minutes,
            rb.latitude,
            rb.longitude
        "
        : "
            0 AS delivery_fee,
            25 AS estimated_min_minutes,
            45 AS estimated_max_minutes,
            NULL AS latitude,
            NULL AS longitude
        ";

    $branchJoin = $hasBranches
        ? "
            LEFT JOIN (
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
            ) rb ON rb.vendor_id = v.vendor_id
        "
        : "";

    $settingsJoin = $hasStoreSettings
        ? "LEFT JOIN vendor_store_settings vs ON vs.vendor_id = v.vendor_id"
        : "";
    $settingsSelect = $hasStoreSettings
        ? "
            COALESCE(vs.is_open, 1) AS store_is_open,
            vs.restaurant_working_hours_json,
            vs.working_hours_json,
            vs.store_name AS settings_store_name,
            vs.vendor_name AS settings_vendor_name,
            vs.vendor_logo AS settings_vendor_logo,
            vs.store_banner_url AS settings_store_banner_url,
            vs.store_latitude AS settings_store_latitude,
            vs.store_longitude AS settings_store_longitude
        "
        : "
            1 AS store_is_open,
            NULL AS restaurant_working_hours_json,
            NULL AS working_hours_json,
            '' AS settings_store_name,
            '' AS settings_vendor_name,
            NULL AS settings_vendor_logo,
            NULL AS settings_store_banner_url,
            NULL AS settings_store_latitude,
            NULL AS settings_store_longitude
        ";

    $stmt = $con->prepare("
        SELECT
            v.vendor_id,
            v.vendor_name,
            v.store_name,
            v.store_slug,
            v.vendor_logo,
            COALESCE(v.vendor_type, 'restaurant') AS vendor_type,
            {$profileSelect},
            {$settingsSelect},
            {$branchSelect},
            COALESCE(item_stats.menu_item_count, 0) AS menu_item_count,
            COALESCE(item_stats.discounted_items_count, 0) AS discounted_items_count,
            COALESCE(item_stats.max_discount, 0) AS max_discount,
            COALESCE(rating_stats.average_rating, 0) AS average_rating,
            COALESCE(rating_stats.total_reviews, 0) AS total_reviews
        FROM vendors v
        {$profileJoin}
        {$settingsJoin}
        {$branchJoin}
        LEFT JOIN (
            SELECT
                vendor_id,
                COUNT(*) AS menu_item_count,
                SUM(CASE WHEN items_discount > 0 THEN 1 ELSE 0 END) AS discounted_items_count,
                MAX(items_discount) AS max_discount
            FROM items
            WHERE items_active = 1
            GROUP BY vendor_id
        ) item_stats ON item_stats.vendor_id = v.vendor_id
        LEFT JOIN (
            SELECT
                i.vendor_id,
                ROUND(AVG(r.rating), 1) AS average_rating,
                COUNT(r.rating) AS total_reviews
            FROM items i
            LEFT JOIN ratings r ON r.item_id = i.items_id
            GROUP BY i.vendor_id
        ) rating_stats ON rating_stats.vendor_id = v.vendor_id
        WHERE v.vendor_status = 'active'
          AND v.vendor_is_verified = 1
        ORDER BY COALESCE(profile_sort_order, 0) ASC, v.vendor_id DESC
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $hoursMap = fetchHoursMap();
    $restaurants = [];

    foreach ($rows as $row) {
        $vendorId = (int)$row['vendor_id'];
        $restaurantFallbackJson = $row['restaurant_working_hours_json'] ?? $row['working_hours_json'] ?? null;
        if ((!isset($hoursMap[$vendorId]) || empty($hoursMap[$vendorId])) && !empty($restaurantFallbackJson)) {
            $fallbackHours = workingHoursRowsFromPayload($restaurantFallbackJson, $vendorId);
            if (!empty($fallbackHours)) {
                $hoursMap[$vendorId] = workingHoursRowsByDayKey($fallbackHours);
            }
        }

        $name = trim((string)(
            $row['settings_store_name']
            ?: $row['store_name']
            ?: $row['settings_vendor_name']
            ?: $row['vendor_name']
        ));
        if ($name === '') {
            $name = (($row['vendor_type'] ?? 'restaurant') === 'store') ? 'Store' : 'Restaurant';
        }

        $logoSource = trim((string)($row['settings_vendor_logo'] ?? ''));
        if ($logoSource === '') {
            $logoSource = trim((string)($row['vendor_logo'] ?? ''));
        }

        $coverSource = trim((string)($row['settings_store_banner_url'] ?? ''));
        if ($coverSource === '') {
            $coverSource = trim((string)($row['cover_image'] ?? ''));
        }
        if ($coverSource === '') {
            $coverSource = $logoSource;
        }

        $distanceKm = null;
        $lat = $row['settings_store_latitude'] ?? $row['latitude'] ?? null;
        $lng = $row['settings_store_longitude'] ?? $row['longitude'] ?? null;
        if ($userLat !== null && $userLng !== null && is_numeric($lat) && is_numeric($lng)) {
            $distanceKm = round(distance($userLat, $userLng, (float)$lat, (float)$lng), 1);
        }

        if ($userLat !== null && $userLng !== null &&
            ($distanceKm === null || $distanceKm > HOME_NEARBY_RADIUS_KM)) {
            continue;
        }

        $maxDiscount = (int)($row['max_discount'] ?? 0);
        $badgesAr = [];
        $badgesEn = [];

        if ((int)($row['discounted_items_count'] ?? 0) > 0) {
            $badgesAr[] = 'عروض';
            $badgesEn[] = 'Offers';
        }
        if ((int)($row['is_new'] ?? 0) === 1) {
            $badgesAr[] = 'جديد';
            $badgesEn[] = 'New';
        }
        if ((int)($row['family_score'] ?? 0) > 0) {
            $badgesAr[] = 'مناسب للإهداء';
            $badgesEn[] = 'Great for gifting';
        }
        if ((float)($row['delivery_fee'] ?? 0) <= 0) {
            $badgesAr[] = 'توصيل مجاني';
            $badgesEn[] = 'Free delivery';
        }

        $restaurants[] = [
            'id' => $vendorId,
            'vendor_id' => $vendorId,
            'vendor_type' => ($row['vendor_type'] ?? 'restaurant') === 'store' ? 'store' : 'restaurant',
            'entity_label_ar' => (($row['vendor_type'] ?? 'restaurant') === 'store') ? 'متجر' : 'مطعم',
            'entity_label_en' => (($row['vendor_type'] ?? 'restaurant') === 'store') ? 'Store' : 'Restaurant',
            'name' => $name,
            'slug' => trim((string)($row['store_slug'] ?? '')),
            'tagline_ar' => trim((string)($row['tagline_ar'] ?? '')),
            'tagline_en' => trim((string)($row['tagline_en'] ?? '')),
            'logo_url' => mediaUrl($logoSource, 'uploads/vendors/logo'),
            'cover_image_url' => $coverSource !== ''
                ? mediaUrl($coverSource)
                : '',
            'rating' => round((float)($row['average_rating'] ?? 0), 1),
            'reviews_count' => (int)($row['total_reviews'] ?? 0),
            'delivery_fee' => round((float)($row['delivery_fee'] ?? 0), 2),
            'estimated_min_minutes' => (int)($row['estimated_min_minutes'] ?? 25),
            'estimated_max_minutes' => (int)($row['estimated_max_minutes'] ?? 45),
            'distance_km' => $distanceKm,
            'is_open' => restaurantIsOpen($row, $hoursMap[$vendorId] ?? []),
            'is_new' => (int)($row['is_new'] ?? 0) === 1,
            'discount_label_ar' => $maxDiscount > 0 ? ('خصم ' . $maxDiscount . '%') : '',
            'discount_label_en' => $maxDiscount > 0 ? ($maxDiscount . '% OFF') : '',
            'badges_ar' => $badgesAr,
            'badges_en' => $badgesEn,
            '_score' => [
                'featured' => (int)($row['is_featured'] ?? 0),
                'new' => (int)($row['is_new'] ?? 0),
                'family' => (int)($row['family_score'] ?? 0),
                'menu_items' => (int)($row['menu_item_count'] ?? 0),
                'discounted_items' => (int)($row['discounted_items_count'] ?? 0),
                'max_discount' => $maxDiscount,
                'reviews' => (int)($row['total_reviews'] ?? 0),
                'rating' => (float)($row['average_rating'] ?? 0),
            ],
        ];
    }

    return $restaurants;
}

function fetchStories($restaurants, $hasStories)
{
    global $con;

    if ($hasStories) {
        $stmt = $con->prepare("
            SELECT
                story_id,
                vendor_id,
                title_ar,
                title_en,
                media_type,
                image_url,
                video_url,
                cta_label_ar,
                cta_label_en,
                target_type,
                target_id
            FROM restaurant_stories
            WHERE is_active = 1
              AND (starts_at IS NULL OR starts_at <= NOW())
              AND (ends_at IS NULL OR ends_at >= NOW())
            ORDER BY sort_order ASC, story_id DESC
            LIMIT 10
        ");
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($rows)) {
            return array_map(function ($row) {
                return [
                    'id' => (int)$row['story_id'],
                    'restaurant_id' => (int)$row['vendor_id'],
                    'target_type' => normalizeStoryTargetType($row['target_type'] ?? 'restaurant'),
                    'target_id' => (int)($row['target_id'] ?? 0) > 0
                        ? (int)$row['target_id']
                        : (int)$row['vendor_id'],
                    'title_ar' => trim((string)($row['title_ar'] ?? '')),
                    'title_en' => trim((string)($row['title_en'] ?? '')),
                    'image_url' => mediaUrl($row['image_url']),
                    'video_url' => mediaUrl($row['video_url']),
                    'media_type' => trim((string)($row['media_type'] ?? 'image')),
                    'cta_label_ar' => trim((string)($row['cta_label_ar'] ?? 'الانتقال للعرض')),
                    'cta_label_en' => trim((string)($row['cta_label_en'] ?? 'Go To Offer')),
                ];
            }, $rows);
        }
    }

    return [];
}

function fetchBanners($restaurants, $hasBanners)
{
    global $con;

    if ($hasBanners) {
        $stmt = $con->prepare("
            SELECT
                banner_id,
                title_ar,
                title_en,
                subtitle_ar,
                subtitle_en,
                image_url,
                background_color,
                text_color,
                cta_label_ar,
                cta_label_en,
                cta_target,
                placement
            FROM restaurant_banners
            WHERE is_active = 1
              AND placement IN ('home', 'carousel', 'launch_popup')
              AND (starts_at IS NULL OR starts_at <= NOW())
              AND (ends_at IS NULL OR ends_at >= NOW())
            ORDER BY sort_order ASC, banner_id DESC
        ");
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($rows)) {
            return array_map(function ($row) {
                return [
                    'id' => (int)$row['banner_id'],
                    'title_ar' => trim((string)($row['title_ar'] ?? '')),
                    'title_en' => trim((string)($row['title_en'] ?? '')),
                    'subtitle_ar' => trim((string)($row['subtitle_ar'] ?? '')),
                    'subtitle_en' => trim((string)($row['subtitle_en'] ?? '')),
                    'image_url' => mediaUrl($row['image_url']),
                    'background_color' => safeColor($row['background_color'], '#274e1b'),
                    'text_color' => safeColor($row['text_color'], '#ffffff'),
                    'cta_label_ar' => trim((string)($row['cta_label_ar'] ?? 'عرض التفاصيل')),
                    'cta_label_en' => trim((string)($row['cta_label_en'] ?? 'View Details')),
                    'cta_target' => trim((string)($row['cta_target'] ?? '')),
                    'placement' => trim((string)($row['placement'] ?? 'home')),
                ];
            }, $rows);
        }
    }

    $banners = [];
    $topOffer = null;
    foreach ($restaurants as $restaurant) {
        if ($topOffer === null || $restaurant['_score']['max_discount'] > $topOffer['_score']['max_discount']) {
            $topOffer = $restaurant;
        }
    }

    if ($topOffer) {
        $banners[] = [
            'id' => 1,
            'title_ar' => $topOffer['discount_label_ar'] !== '' ? $topOffer['discount_label_ar'] : 'عروض المطاعم',
            'title_en' => $topOffer['discount_label_en'] !== '' ? $topOffer['discount_label_en'] : 'Restaurant Offers',
            'subtitle_ar' => 'استفد من أفضل العروض المفعلة الآن.',
            'subtitle_en' => 'Take advantage of the best live restaurant offers.',
            'image_url' => $topOffer['cover_image_url'],
            'background_color' => '#274e1b',
            'text_color' => '#ffffff',
            'cta_label_ar' => 'الانتقال للعرض',
            'cta_label_en' => 'View Offer',
            'cta_target' => 'restaurant:' . $topOffer['id'],
            'placement' => 'home',
        ];
    }

    $banners[] = [
        'id' => 2,
        'title_ar' => 'توصيل مجاني',
        'title_en' => 'Free Delivery',
        'subtitle_ar' => 'اختر المطاعم المشاركة واستمتع بإرسال الطلب بسهولة.',
        'subtitle_en' => 'Pick participating restaurants and send orders with ease.',
        'image_url' => $topOffer['cover_image_url'] ?? '',
        'background_color' => '#5e7a2f',
        'text_color' => '#ffffff',
        'cta_label_ar' => 'اكتشف المطاعم',
        'cta_label_en' => 'Explore Restaurants',
        'cta_target' => 'section:open_now',
        'placement' => 'home',
    ];
    $banners[] = [
        'id' => 3,
        'title_ar' => 'أرسل لأهلك في مصر',
        'title_en' => 'Send To Family In Egypt',
        'subtitle_ar' => 'مطاعم، هدايا، ورسالة لطيفة مع الطلب.',
        'subtitle_en' => 'Restaurants, gifting, and a sweet note with every order.',
        'image_url' => $topOffer['logo_url'] ?? '',
        'background_color' => '#d8b35f',
        'text_color' => '#2b2416',
        'cta_label_ar' => 'ابدأ الآن',
        'cta_label_en' => 'Start Now',
        'cta_target' => 'flow:start',
        'placement' => 'home',
    ];

    return $banners;
}

function fetchCategories()
{
    global $con;

    ensureVendorCategorySchema();

    $stmt = $con->prepare("
        SELECT
            categories_id,
            categories_name_ar,
            categories_name_en,
            categories_image,
            category_type
        FROM categories
        ORDER BY categories_id ASC
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $categories = array_map(function ($row) {
        return [
            'id' => (int)$row['categories_id'],
            'name_ar' => trim((string)($row['categories_name_ar'] ?? '')),
            'name_en' => trim((string)($row['categories_name_en'] ?? '')),
            'image_url' => mediaUrl($row['categories_image'], 'uploud/categories'),
            'icon' => (($row['category_type'] ?? 'restaurant') === 'store') ? 'store' : 'food',
            'category_type' => (($row['category_type'] ?? 'restaurant') === 'store') ? 'store' : 'restaurant',
        ];
    }, $rows);

    if (empty($categories)) {
        return defaultFoodCategories();
    }

    return $categories;
}

function hasFoodCategorySignal(array $categories)
{
    $signals = [
        'shawarma',
        'shawar',
        'grill',
        'grills',
        'pizza',
        'burger',
        'sandwich',
        'wrap',
        'kebab',
        'fries',
        'dessert',
        'sweet',
        'juice',
        'coffee',
        'breakfast',
        'meal',
        'food',
        'مشاوي',
        'شاورما',
        'بيتزا',
        'برغر',
        'سندويش',
        'سندويتش',
        'كباب',
        'بطاطا',
        'حلويات',
        'عصائر',
        'قهوة',
        'فطور',
    ];

    foreach ($categories as $category) {
        $haystack = strtolower(trim(
            ($category['name_ar'] ?? '') . ' ' . ($category['name_en'] ?? '')
        ));
        if ($haystack === '') {
            continue;
        }

        foreach ($signals as $signal) {
            if (strpos($haystack, $signal) !== false) {
                return true;
            }
        }
    }

    return false;
}

function defaultFoodCategories()
{
    return [
        ['id' => 1, 'name_ar' => 'شاورما', 'name_en' => 'Shawarma', 'image_url' => '', 'icon' => 'wrap'],
        ['id' => 2, 'name_ar' => 'بيتزا', 'name_en' => 'Pizza', 'image_url' => '', 'icon' => 'pizza'],
        ['id' => 3, 'name_ar' => 'مشاوي', 'name_en' => 'Grills', 'image_url' => '', 'icon' => 'grill'],
        ['id' => 4, 'name_ar' => 'برجر', 'name_en' => 'Burger', 'image_url' => '', 'icon' => 'burger'],
    ];
}

function fetchOccasions($hasOccasions)
{
    global $con;

    if ($hasOccasions) {
        $stmt = $con->prepare("
            SELECT occasion_id, name_ar, name_en, color
            FROM restaurant_occasions
            WHERE is_active = 1
            ORDER BY sort_order ASC, occasion_id ASC
            LIMIT 8
        ");
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($rows)) {
            return array_map(function ($row) {
                return [
                    'id' => (int)$row['occasion_id'],
                    'name_ar' => trim((string)($row['name_ar'] ?? '')),
                    'name_en' => trim((string)($row['name_en'] ?? '')),
                    'color' => safeColor($row['color'], '#f4eedf'),
                ];
            }, $rows);
        }
    }

    return [
        ['id' => 1, 'name_ar' => 'عيد ميلاد', 'name_en' => 'Birthday', 'color' => '#f9e1dc'],
        ['id' => 2, 'name_ar' => 'نجاح', 'name_en' => 'Success', 'color' => '#e3f0d1'],
        ['id' => 3, 'name_ar' => 'عيد الأم', 'name_en' => "Mother's Day", 'color' => '#f4dfeb'],
        ['id' => 4, 'name_ar' => 'رمضان', 'name_en' => 'Ramadan', 'color' => '#e7efe1'],
        ['id' => 5, 'name_ar' => 'العيد', 'name_en' => 'Eid', 'color' => '#f8ecd3'],
    ];
}

function sortedRestaurants($restaurants, $compare, $limit = 10, $onlyOpen = false)
{
    $filtered = array_values(array_filter($restaurants, function ($restaurant) use ($onlyOpen) {
        return !$onlyOpen || !empty($restaurant['is_open']);
    }));
    usort($filtered, $compare);
    return array_slice($filtered, 0, $limit);
}

function fetchProductSectionItems($userId, $mode, $limit = 8)
{
    global $con;

    if ($mode === 'personalized' && $userId <= 0) {
        return [];
    }

    $orderFilters = ["COALESCE(o.orders_status, '') NOT IN ('failed', 'canceled', 'cancelled')"];
    $params = [':favorite_user_id' => $userId > 0 ? $userId : 0];

    if ($mode === 'personalized') {
        $orderFilters[] = 'o.orders_usersid = :user_id';
        $params[':user_id'] = $userId;
    }

    $orderWhere = implode(' AND ', $orderFilters);
    $orderStatsSql = "
        SELECT
            oi.item_id,
            SUM(CASE WHEN oi.quantity IS NULL OR oi.quantity <= 0 THEN 1 ELSE oi.quantity END) AS order_quantity,
            COUNT(DISTINCT oi.order_id) AS order_count,
            MAX(o.orders_datetime) AS last_order_at
        FROM order_items oi
        INNER JOIN orders o ON o.orders_id = oi.order_id
        WHERE {$orderWhere}
        GROUP BY oi.item_id
    ";

    $orderBySql = $mode === 'personalized'
        ? "COALESCE(order_stats.order_count, 0) DESC,
           COALESCE(order_stats.last_order_at, '1970-01-01 00:00:00') DESC,
           COALESCE(order_stats.order_quantity, 0) DESC,
           COALESCE(r.average_rating, 0) DESC,
           IFNULL(r.ratings_count, 0) DESC,
           i.items_id DESC"
        : "COALESCE(order_stats.order_quantity, 0) DESC,
           COALESCE(order_stats.order_count, 0) DESC,
           COALESCE(r.average_rating, 0) DESC,
           IFNULL(r.ratings_count, 0) DESC,
           i.items_id DESC";

    $stmt = $con->prepare("
        SELECT
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            i.items_image,
            i.items_count,
            i.items_active,
            i.items_price,
            i.items_discount,
            i.items_date,
            i.items_cat,
            i.vendor_id,
            i.product_type,
            i.stock_unit,
            c.categories_id,
            c.categories_name_en,
            c.categories_name_ar,
            c.categories_image,
            c.categories_datetime,
            v.vendor_name,
            v.store_name,
            v.store_slug,
            v.vendor_logo,
            v.vendor_type,
            v.store_category,
            CASE WHEN f.favorite_id IS NULL THEN 0 ELSE 1 END AS favorite,
            (i.items_price - (i.items_price * i.items_discount / 100)) AS items_discount_price,
            (i.items_price - (i.items_price * i.items_discount / 100)) AS itemspricedisount,
            COALESCE(g.gallery_images, i.items_image) AS gallery_images,
            ROUND(IFNULL(r.average_rating, 0), 1) AS average_rating,
            IFNULL(r.ratings_count, 0) AS ratings_count,
            ROUND((IFNULL(r.average_rating, 0) / 5) * 100) AS rating_percentage,
            CASE
                WHEN IFNULL(r.average_rating, 0) >= 4 AND IFNULL(r.ratings_count, 0) >= 3 THEN 1
                ELSE 0
            END AS is_top_rated,
            COALESCE(order_stats.order_quantity, 0) AS order_quantity,
            COALESCE(order_stats.order_count, 0) AS order_count,
            order_stats.last_order_at
        FROM items i
        JOIN categories c ON c.categories_id = i.items_cat
        JOIN vendors v ON v.vendor_id = i.vendor_id
        LEFT JOIN favorite f
            ON f.favorite_itemsid = i.items_id
           AND f.favorite_usersid = :favorite_user_id
        LEFT JOIN (
            SELECT
                item_id,
                AVG(rating) AS average_rating,
                COUNT(*) AS ratings_count
            FROM ratings
            GROUP BY item_id
        ) r ON r.item_id = i.items_id
        LEFT JOIN (
            SELECT
                item_id,
                GROUP_CONCAT(img_path ORDER BY img_order ASC SEPARATOR '||') AS gallery_images
            FROM items_images
            GROUP BY item_id
        ) g ON g.item_id = i.items_id
        LEFT JOIN (
            {$orderStatsSql}
        ) order_stats ON order_stats.item_id = i.items_id
        WHERE i.items_active = 1
          AND v.vendor_status = 'active'
          AND v.vendor_is_verified = 1
          AND COALESCE(order_stats.order_count, 0) > 0
        ORDER BY {$orderBySql}
        LIMIT {$limit}
    ");
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function buildProductSections($userId)
{
    $mostOrdered = fetchProductSectionItems($userId, 'most_ordered', 8);
    $personalized = fetchProductSectionItems($userId, 'personalized', 8);

    if (empty($personalized)) {
        $personalized = $mostOrdered;
    }

    return [
        [
            'key' => 'most_ordered_products',
            'title_ar' => 'المنتجات الأكثر طلباً',
            'title_en' => 'Most ordered products',
            'items' => $mostOrdered,
        ],
        [
            'key' => 'recommended_for_you',
            'title_ar' => 'المنتجات المخصصة لك',
            'title_en' => 'Recommended for you',
            'items' => $personalized,
        ],
    ];
}

function buildSections($restaurants, $userLat, $userLng)
{
    $nearest = sortedRestaurants(
        $restaurants,
        function ($a, $b) use ($userLat, $userLng) {
            $aDistance = $a['distance_km'] ?? 999999;
            $bDistance = $b['distance_km'] ?? 999999;
            if ($aDistance === $bDistance) {
                return $b['_score']['reviews'] <=> $a['_score']['reviews'];
            }
            return $aDistance <=> $bDistance;
        }
    );

    return [
        [
            'key' => 'most_ordered',
            'title_ar' => 'الأكثر طلباً',
            'title_en' => 'Most Ordered',
            'restaurants' => sortedRestaurants($restaurants, function ($a, $b) {
                return [$b['_score']['menu_items'], $b['_score']['reviews'], $b['_score']['rating']]
                    <=> [$a['_score']['menu_items'], $a['_score']['reviews'], $a['_score']['rating']];
            }),
        ],
        [
            'key' => 'nearest_delivery',
            'title_ar' => 'الأقرب للتوصيل',
            'title_en' => 'Closest To Delivery',
            'restaurants' => !empty($nearest)
                ? $nearest
                : sortedRestaurants($restaurants, function ($a, $b) {
                    return $a['delivery_fee'] <=> $b['delivery_fee'];
                }),
        ],
        [
            'key' => 'offers',
            'title_ar' => 'العروض',
            'title_en' => 'Offers',
            'restaurants' => sortedRestaurants($restaurants, function ($a, $b) {
                return [$b['_score']['discounted_items'], $b['_score']['max_discount'], $b['_score']['reviews']]
                    <=> [$a['_score']['discounted_items'], $a['_score']['max_discount'], $a['_score']['reviews']];
            }),
        ],
        [
            'key' => 'open_now',
            'title_ar' => 'المطاعم المفتوحة الآن',
            'title_en' => 'Open Now',
            'restaurants' => sortedRestaurants($restaurants, function ($a, $b) {
                return [$b['_score']['featured'], $b['_score']['reviews'], $b['_score']['rating']]
                    <=> [$a['_score']['featured'], $a['_score']['reviews'], $a['_score']['rating']];
            }, 10, true),
        ],
        [
            'key' => 'new_restaurants',
            'title_ar' => 'مطاعم جديدة',
            'title_en' => 'New Restaurants',
            'restaurants' => sortedRestaurants($restaurants, function ($a, $b) {
                return [$b['_score']['new'], $b['id']]
                    <=> [$a['_score']['new'], $a['id']];
            }),
        ],
        [
            'key' => 'family_favorites',
            'title_ar' => 'الأكثر إرسالاً للأهل',
            'title_en' => 'Most Sent To Family',
            'restaurants' => sortedRestaurants($restaurants, function ($a, $b) {
                return [$b['_score']['family'], $b['_score']['reviews'], $b['_score']['rating']]
                    <=> [$a['_score']['family'], $a['_score']['reviews'], $a['_score']['rating']];
            }),
        ],
    ];
}

function fetchNotificationBanner($banners)
{
    if (empty($banners)) {
        return null;
    }

    foreach ($banners as $banner) {
        if (($banner['placement'] ?? '') === 'launch_popup') {
            return $banner;
        }
    }

    $first = $banners[0];
    $first['placement'] = 'launch_popup';
    return $first;
}

try {
    $restaurants = fetchRestaurants($userLat, $userLng, $hasProfiles, $hasBranches);
    $stories = fetchStories($restaurants, $hasStories);
    $banners = fetchBanners($restaurants, $hasBanners);
    $categories = fetchCategories();
    $restaurantCategories = array_values(array_filter($categories, function ($category) {
        return ($category['category_type'] ?? 'restaurant') === 'restaurant';
    }));
    $storeCategories = array_values(array_filter($categories, function ($category) {
        return ($category['category_type'] ?? '') === 'store';
    }));
    $occasions = fetchOccasions($hasOccasions);
    $sections = buildSections($restaurants, $userLat, $userLng);
    $productSections = buildProductSections($userId);

    $response = [
        'status' => 'success',
        'data' => [
            'marketing_headline_ar' => 'اطلب لأحبائك في مصر من أي مكان في العالم',
            'marketing_headline_en' => 'Order for your loved ones in Egypt from anywhere in the world',
            'marketing_subtitle_ar' => 'مطاعم موثوقة، عروض موسمية، وتتبع حي للطلب حتى لحظة التسليم.',
            'marketing_subtitle_en' => 'Trusted restaurants, seasonal offers, and live tracking until delivery.',
            'delivery_prompt_ar' => 'حدد عنوان التوصيل',
            'delivery_prompt_en' => 'Choose delivery address',
            'notification_banner' => fetchNotificationBanner($banners),
            'stories' => $stories,
            'banners' => $banners,
            'categories' => $categories,
            'restaurant_categories' => $restaurantCategories,
            'store_categories' => $storeCategories,
            'occasions' => $occasions,
            'sections' => $sections,
            'product_sections' => $productSections,
        ],
    ];

    respondJson($response);
} catch (Throwable $e) {
    respondJson([
        'status' => 'failure',
        'message' => $e->getMessage(),
    ], 500);
}
