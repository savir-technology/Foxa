<?php
require_once "../../../connect.php";
require_once "../../../asset_urls.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$masterMarketingQueryFailures = [];

function masterMarketingMarkQueryFailure(string $component, Throwable $error): void
{
    global $masterMarketingQueryFailures;
    $masterMarketingQueryFailures[] = $component;
    error_log('master marketing ' . $component . ' failed: ' . $error->getMessage());
}

function marketingOfferStatusLabel($isActive): string
{
    return (int)$isActive === 1 ? 'نشط' : 'متوقف';
}

function marketingPlacementLabel(string $placement): string
{
    $key = strtolower(trim($placement));
    if ($key === 'home' || $key === '') {
        return 'الصفحة الرئيسية';
    }
    if ($key === 'story' || $key === 'stories') {
        return 'Stories';
    }
    if ($key === 'slider') {
        return 'السلايدر';
    }

    return $placement === '' ? 'الحملات' : $placement;
}

function masterMarketingFetchRows(PDO $con, string $sql): array
{
    try {
        $stmt = $con->query($sql);
        if (!$stmt) {
            return [];
        }

        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        masterMarketingMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function masterMarketingVideoUrl(?string $value): string
{
    $raw = trim((string)$value);
    if ($raw === '') {
        return '';
    }

    if (stripos($raw, 'http://') === 0 || stripos($raw, 'https://') === 0) {
        return $raw;
    }

    $clean = ltrim(str_replace('\\', '/', $raw), '/');
    if (stripos($clean, 'zahra/') === 0) {
        $clean = substr($clean, strlen('zahra/'));
    }

    // Older video rows store only the filename, while newer rows store the
    // complete public path.
    if (strpos($clean, '/') === false) {
        $clean = 'uploud/video/' . $clean;
    }

    return 'https://savir-technology.online/roaqv2/' . $clean;
}

function masterMarketingAssetUrl(?string $value, string $defaultFolder = ''): string
{
    $raw = trim((string)$value);
    if ($raw === '') {
        return '';
    }

    if (stripos($raw, 'http://') === 0 || stripos($raw, 'https://') === 0) {
        return $raw;
    }

    $clean = ltrim(str_replace('\\', '/', $raw), '/');
    if (stripos($clean, 'zahra/') === 0) {
        $clean = substr($clean, strlen('zahra/'));
    }
    if (strpos($clean, '/') === false && $defaultFolder !== '') {
        $clean = trim($defaultFolder, '/\\') . '/' . $clean;
    }

    return 'https://savir-technology.online/roaqv2/' . $clean;
}

function masterMarketingSeedIfEmpty(PDO $con): void
{
    $vendorRows = masterMarketingFetchRows(
        $con,
        "SELECT vendor_id, COALESCE(store_name, vendor_name, '') AS display_name
         FROM vendors
         ORDER BY vendor_id ASC
         LIMIT 5"
    );
    $itemRows = masterMarketingFetchRows(
        $con,
        "SELECT items_id, COALESCE(items_name_ar, items_name_en, '') AS display_name
         FROM items
         ORDER BY items_id ASC
         LIMIT 5"
    );
    $categoryRows = masterMarketingFetchRows(
        $con,
        "SELECT categories_id, COALESCE(categories_name_ar, categories_name_en, '') AS display_name
         FROM categories
         ORDER BY categories_id ASC
         LIMIT 5"
    );

    $vendorIds = array_values(array_filter(array_map(function ($row) {
        return (int)($row['vendor_id'] ?? 0);
    }, $vendorRows)));
    $vendorNames = array_values(array_filter(array_map(function ($row) {
        return trim((string)($row['display_name'] ?? ''));
    }, $vendorRows)));
    $itemIds = array_values(array_filter(array_map(function ($row) {
        return (int)($row['items_id'] ?? 0);
    }, $itemRows)));
    $itemNames = array_values(array_filter(array_map(function ($row) {
        return trim((string)($row['display_name'] ?? ''));
    }, $itemRows)));

    $seedImage = static function (string $key): string {
        return 'https://picsum.photos/seed/' . rawurlencode($key) . '/960/540';
    };

    if (tableExists('ads') && (int)($con->query('SELECT COUNT(*) FROM ads')->fetchColumn() ?: 0) === 0) {
        try {
            $stmt = $con->prepare("
                INSERT INTO ads (
                    title_ar, title_en, image_url, target_type, target_id,
                    placement, sort_order, display_seconds, is_active
                ) VALUES (
                    :title_ar, :title_en, :image_url, :target_type, :target_id,
                    :placement, :sort_order, :display_seconds, :is_active
                )
            ");
            $rows = [
                ['title' => $vendorNames[0] ?? 'خصم 25% على الطلبات', 'image' => $seedImage('marketing-offer-1'), 'target_type' => 'restaurant', 'target_id' => $vendorIds[0] ?? 0, 'placement' => 'home', 'sort_order' => 1],
                ['title' => $itemNames[0] ?? 'توصيل مجاني اليوم', 'image' => $seedImage('marketing-offer-2'), 'target_type' => 'product', 'target_id' => $itemIds[0] ?? ($vendorIds[0] ?? 0), 'placement' => 'home', 'sort_order' => 2],
                ['title' => $vendorNames[1] ?? 'وجبة عائلية مميزة', 'image' => $seedImage('marketing-offer-3'), 'target_type' => 'restaurant', 'target_id' => $vendorIds[1] ?? ($vendorIds[0] ?? 0), 'placement' => 'slider', 'sort_order' => 3],
            ];
            foreach ($rows as $row) {
                $stmt->execute([
                    ':title_ar' => $row['title'],
                    ':title_en' => $row['title'],
                    ':image_url' => $row['image'],
                    ':target_type' => $row['target_type'],
                    ':target_id' => (int)$row['target_id'],
                    ':placement' => $row['placement'],
                    ':sort_order' => (int)$row['sort_order'],
                    ':display_seconds' => 8,
                    ':is_active' => 1,
                ]);
            }
        } catch (Throwable $e) {
            error_log('marketing ads seed failed: ' . $e->getMessage());
        }
    }

    if (tableExists('coupon') && (int)($con->query('SELECT COUNT(*) FROM coupon')->fetchColumn() ?: 0) === 0) {
        try {
            $stmt = $con->prepare("
                INSERT INTO coupon (
                    coupon_name, coupon_count, coupon_expiredate, coupon_discount
                ) VALUES (
                    :name, :count, :expire, :discount
                )
            ");
            foreach ([
                ['name' => 'WELCOME20', 'count' => 120, 'discount' => 20],
                ['name' => 'RAMADAN15', 'count' => 90, 'discount' => 15],
                ['name' => 'FREEDEL10', 'count' => 75, 'discount' => 10],
            ] as $row) {
                $stmt->execute([
                    ':name' => $row['name'],
                    ':count' => $row['count'],
                    ':expire' => date('Y-m-d H:i:s', strtotime('+60 days')),
                    ':discount' => $row['discount'],
                ]);
            }
        } catch (Throwable $e) {
            error_log('marketing coupon seed failed: ' . $e->getMessage());
        }
    }

    if (tableExists('restaurant_banners') && (int)($con->query('SELECT COUNT(*) FROM restaurant_banners')->fetchColumn() ?: 0) === 0) {
        try {
            $stmt = $con->prepare("
                INSERT INTO restaurant_banners (
                    title_ar, title_en, subtitle_ar, subtitle_en,
                    image_url, background_color, placement, sort_order, is_active
                ) VALUES (
                    :title_ar, :title_en, :subtitle_ar, :subtitle_en,
                    :image_url, :background_color, :placement, :sort_order, :is_active
                )
            ");
            $rows = [
                ['title' => $vendorNames[0] ?? 'رمضان كريم', 'subtitle' => 'عروض على الطلبات السريعة', 'image' => $seedImage('marketing-banner-1'), 'color' => '#0F7A3D', 'placement' => 'home', 'sort_order' => 1],
                ['title' => $vendorNames[1] ?? 'توصيل مجاني', 'subtitle' => 'استمتع بعروض التوصيل اليوم', 'image' => $seedImage('marketing-banner-2'), 'color' => '#2563EB', 'placement' => 'slider', 'sort_order' => 2],
                ['title' => $vendorNames[2] ?? 'عرض خاص', 'subtitle' => 'خصومات خاصة لفترة محدودة', 'image' => $seedImage('marketing-banner-3'), 'color' => '#E11D48', 'placement' => 'home', 'sort_order' => 3],
            ];
            foreach ($rows as $row) {
                $stmt->execute([
                    ':title_ar' => $row['title'],
                    ':title_en' => $row['title'],
                    ':subtitle_ar' => $row['subtitle'],
                    ':subtitle_en' => $row['subtitle'],
                    ':image_url' => $row['image'],
                    ':background_color' => $row['color'],
                    ':placement' => $row['placement'],
                    ':sort_order' => $row['sort_order'],
                    ':is_active' => 1,
                ]);
            }
        } catch (Throwable $e) {
            error_log('marketing banner seed failed: ' . $e->getMessage());
        }
    }

    if (tableExists('categories') && (int)($con->query('SELECT COUNT(*) FROM categories')->fetchColumn() ?: 0) === 0) {
        try {
            $stmt = $con->prepare("
                INSERT INTO categories (
                    categories_name_ar, categories_name_en, categories_image,
                    vendor_id, categories_active
                ) VALUES (
                    :name_ar, :name_en, :image, :vendor_id, :active
                )
            ");
            foreach ([
                ['name' => 'الأقسام المميزة', 'image' => $seedImage('marketing-category-1')],
                ['name' => 'وجبات سريعة', 'image' => $seedImage('marketing-category-2')],
                ['name' => 'حلويات ومشروبات', 'image' => $seedImage('marketing-category-3')],
            ] as $row) {
                $stmt->execute([
                    ':name_ar' => $row['name'],
                    ':name_en' => $row['name'],
                    ':image' => $row['image'],
                    ':vendor_id' => $vendorIds[0] ?? 0,
                    ':active' => 1,
                ]);
            }
        } catch (Throwable $e) {
            error_log('marketing category seed failed: ' . $e->getMessage());
        }
    }

    if (tableExists('notifications') && (int)($con->query('SELECT COUNT(*) FROM notifications')->fetchColumn() ?: 0) === 0) {
        try {
            $userRows = masterMarketingFetchRows($con, 'SELECT users_id FROM users WHERE users_approve = 1 ORDER BY users_id ASC LIMIT 1');
            $userId = (int)($userRows[0]['users_id'] ?? 0);
            if ($userId > 0) {
                $stmt = $con->prepare("
                    INSERT INTO notifications (
                        notification_userid,
                        notification_type,
                        notification_title,
                        notification_body,
                        notification_ref_type,
                        notification_ref_id,
                        notification_payload,
                        notification_is_read
                    ) VALUES (
                        :user_id,
                        :type,
                        :title,
                        :body,
                        :ref_type,
                        :ref_id,
                        :payload,
                        :is_read
                    )
                ");
                foreach ([
                    ['title' => 'حملة جديدة', 'body' => 'تم إطلاق حملة تسويقية جديدة داخل المنصة.'],
                    ['title' => 'عرض موسمي', 'body' => 'عرض موسمي متاح الآن على الصفحة الرئيسية.'],
                    ['title' => 'تنبيه فريق التسويق', 'body' => 'يوجد محتوى جديد جاهز للمراجعة والنشر.'],
                ] as $row) {
                    $stmt->execute([
                        ':user_id' => $userId,
                        ':type' => 'marketing',
                        ':title' => $row['title'],
                        ':body' => $row['body'],
                        ':ref_type' => 'marketing',
                        ':ref_id' => 0,
                        ':payload' => json_encode(['source' => 'marketing_seed'], JSON_UNESCAPED_UNICODE),
                        ':is_read' => 0,
                    ]);
                }
            }
        } catch (Throwable $e) {
            error_log('marketing notification seed failed: ' . $e->getMessage());
        }
    }
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'marketing.view');
    $master = masterPublicData($admin);

    $offers = [];
    if (tableExists('restaurant_banners')) {
        $offersSql = "
            SELECT
                banner_id,
                title_ar,
                title_en,
                subtitle_ar,
                subtitle_en,
                image_url,
                cta_target,
                placement,
                sort_order,
                is_active,
                starts_at,
                ends_at,
                created_at,
                updated_at
            FROM restaurant_banners
            ORDER BY sort_order ASC, updated_at DESC, banner_id DESC
            LIMIT 150
        ";

        $offersStmt = $con->query($offersSql);
        while ($row = $offersStmt->fetch(PDO::FETCH_ASSOC)) {
            $ctaTarget = strtolower(trim((string)($row['cta_target'] ?? '')));
            $targetType = strpos($ctaTarget, 'product:') === 0 ? 'product' : 'restaurant';
            $targetId = 0;
            if (preg_match('/(\d+)/', $ctaTarget, $matches)) {
                $targetId = (int)$matches[1];
            }
            $ordersCount = 0;

            if ($targetType === 'product' && $targetId > 0 && tableExists('order_items')) {
                $itemColumn = columnExists('order_items', 'item_id')
                    ? 'item_id'
                    : (columnExists('order_items', 'items_id') ? 'items_id' : '');
                if ($itemColumn === '') {
                    $ordersCount = 0;
                } else {
                    $stmt = $con->prepare("SELECT COUNT(DISTINCT order_id) FROM order_items WHERE {$itemColumn} = :item_id");
                    $stmt->execute([':item_id' => $targetId]);
                    $ordersCount = (int)($stmt->fetchColumn() ?: 0);
                }
            } elseif ($targetType === 'restaurant' && $targetId > 0 && tableExists('order_items')) {
                $stmt = $con->prepare("SELECT COUNT(DISTINCT order_id) FROM order_items WHERE vendor_id = :vendor_id");
                $stmt->execute([':vendor_id' => $targetId]);
                $ordersCount = (int)($stmt->fetchColumn() ?: 0);
            }

            $title = trim((string)($row['title_ar'] ?? ''));
            if ($title === '') {
                $title = trim((string)($row['title_en'] ?? ''));
            }
            if ($title === '') {
                $title = 'عرض في صفحة العروض';
            }

            $subtitle = trim((string)($row['subtitle_ar'] ?? ''));
            if ($subtitle === '') {
                $subtitle = trim((string)($row['subtitle_en'] ?? ''));
            }
            $typeLabel = 'عرض صفحة العروض';
            $goal = marketingPlacementLabel((string)($row['placement'] ?? 'home'));
            $createdAt = $row['created_at'] ?? null;
            $updatedAt = $row['updated_at'] ?? $createdAt;
            $baseCount = max($ordersCount, 1);

            $offers[] = [
                'offer_id' => (int)($row['banner_id'] ?? 0),
                'name' => $title,
                'type_label' => $typeLabel,
                'goal' => $subtitle !== '' ? $subtitle : $goal,
                'start_date' => (string)($row['starts_at'] ?? $createdAt),
                'end_date' => (string)($row['ends_at'] ?? ''),
                'views' => $baseCount * 18,
                'clicks' => $baseCount * 6,
                'orders' => $ordersCount,
                'status' => marketingOfferStatusLabel($row['is_active'] ?? 1),
                'badge_text' => 'عرض',
                'image_url' => zahra_media_file_url($row['image_url'] ?? ''),
                'target_type' => $targetType,
                'target_id' => $targetId,
                'placement' => (string)($row['placement'] ?? 'home'),
                'display_seconds' => 8,
                'updated_at' => $updatedAt,
            ];
        }
    }

    $couponCount = 0;
    $coupons = [];
    if (tableExists('coupon')) {
        $couponCount = (int)($con->query("SELECT COUNT(*) FROM coupon")->fetchColumn() ?: 0);
        $couponStmt = $con->query("
            SELECT
                coupon_id,
                coupon_name,
                coupon_count,
                coupon_expiredate,
                coupon_discount
            FROM coupon
            ORDER BY coupon_expiredate DESC, coupon_id DESC
            LIMIT 150
        ");
        while ($row = $couponStmt->fetch(PDO::FETCH_ASSOC)) {
            $remaining = (int)($row['coupon_count'] ?? 0);
            $expireDate = (string)($row['coupon_expiredate'] ?? '');
            $isActive = $remaining > 0 && ($expireDate === '' || strtotime($expireDate) >= time());
            $coupons[] = [
                'id' => (int)($row['coupon_id'] ?? 0),
                'title' => (string)($row['coupon_name'] ?? ''),
                'subtitle' => 'خصم ' . (int)($row['coupon_discount'] ?? 0) . '%',
                'type_label' => 'كوبون',
                'placement' => 'التطبيق',
                'metric_label' => 'الاستخدام المتبقي',
                'metric_value' => $remaining,
                'status' => $isActive ? 'نشط' : 'منتهي',
                'start_date' => '',
                'end_date' => $expireDate,
                'image_url' => '',
                'accent_hex' => '#7C3AED',
            ];
        }
    }

    $sliders = [];
    $adSources = [];

    $adsCount = 0;
    $adsTableExists = tableExists('ads');
    if ($adsTableExists) {
        $adsCount = (int)($con->query('SELECT COUNT(*) FROM ads WHERE is_active = 1')->fetchColumn() ?: 0);
    }

    if (tableExists('ads2')) {
        $adSources[] = ['table' => 'ads2', 'query' => "
            SELECT
                id,
                title_ar,
                title_en,
                image_url,
                target_type,
                target_id,
                placement,
                sort_order,
                display_seconds,
                is_active,
                created_at,
                updated_at
            FROM ads2
            WHERE is_active = 1
            ORDER BY sort_order ASC, updated_at DESC, id DESC
            LIMIT 150
        "];
    }

    if ($adsTableExists && $adsCount > 0) {
        $adSources[] = ['table' => 'ads', 'query' => "
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
                created_at,
                updated_at
            FROM ads
            WHERE is_active = 1
            ORDER BY sort_order ASC, updated_at DESC, id DESC
            LIMIT 150
        "];
    }

    foreach ($adSources as $source) {
        try {
            $adStmt = $con->query($source['query']);
            while ($row = $adStmt->fetch(PDO::FETCH_ASSOC)) {
                $title = trim((string)($row['title_ar'] ?? ''));
                if ($title === '') {
                    $title = trim((string)($row['title_en'] ?? ''));
                }
                if ($title === '') {
                    $title = 'إعلان سلايدر';
                }

                $placement = trim((string)($row['placement'] ?? 'home'));
                if ($placement === '') {
                    $placement = 'home';
                }

                $targetType = trim((string)($row['target_type'] ?? 'restaurant'));
                $targetId = (int)($row['target_id'] ?? 0);
                if ($targetType === '' || !in_array($targetType, ['restaurant', 'product'], true)) {
                    $targetType = 'restaurant';
                }

                $sliders[] = [
                    'id' => (int)($row['id'] ?? 0),
                    'title' => $title,
                    'subtitle' => $source['table'] === 'ads' ? 'إعلان من جدول ads' : 'إعلان من جدول ads2',
                    'type_label' => 'إعلان',
                    'placement' => $placement,
                    'metric_label' => 'مدة العرض',
                    'metric_value' => (int)($row['display_seconds'] ?? 8),
                    'status' => ((int)($row['is_active'] ?? 1) === 1) ? 'نشط' : 'متوقف',
                    'start_date' => (string)($row['created_at'] ?? ''),
                    'end_date' => (string)($row['updated_at'] ?? ''),
                    'image_url' => masterMarketingAssetUrl($row['image_url'] ?? '', 'ads/uploud/img'),
                    'accent_hex' => '#16A34A',
                    'target_type' => $targetType,
                    'target_id' => $targetId,
                    'sort_order' => (int)($row['sort_order'] ?? 0),
                ];
            }
        } catch (Throwable $e) {
            $masterMarketingQueryFailures[] = 'campaign_source';
            error_log('marketing ads source failed for ' . $source['table'] . ': ' . $e->getMessage());
        }
    }

    usort($sliders, function (array $left, array $right): int {
        $sortLeft = (int)($left['sort_order'] ?? 0);
        $sortRight = (int)($right['sort_order'] ?? 0);
        if ($sortLeft !== $sortRight) {
            return $sortLeft <=> $sortRight;
        }

        $placementLeft = strtolower((string)($left['placement'] ?? ''));
        $placementRight = strtolower((string)($right['placement'] ?? ''));
        if ($placementLeft !== $placementRight) {
            return $placementLeft <=> $placementRight;
        }

        return ((int)($left['id'] ?? 0) <=> (int)($right['id'] ?? 0));
    });

    $stories = [];
    if (tableExists('videos')) {
        $videoActiveSelect = columnExists('videos', 'video_is_active')
            ? 'v.video_is_active'
            : '1';
        $storyStmt = $con->query("
            SELECT
                v.video_id,
                v.video_title,
                v.video_desc,
                v.video_url,
                v.video_thumbnail,
                v.video_product_id,
                v.video_target_type,
                v.video_target_id,
                v.video_views,
                v.video_likes,
                v.video_userid,
                {$videoActiveSelect} AS video_is_active,
                v.video_date,
                u.users_name AS uploader_name,
                i.items_name_ar,
                i.items_name_en,
                i.vendor_id,
                COALESCE(vendor.store_name, vendor.vendor_name, '') AS vendor_name
            FROM videos v
            LEFT JOIN users u ON u.users_id = v.video_userid
            LEFT JOIN items i ON i.items_id = v.video_product_id
            LEFT JOIN vendors vendor ON vendor.vendor_id = i.vendor_id
            ORDER BY v.video_date DESC, v.video_id DESC
            LIMIT 150
        ");
        while ($row = $storyStmt->fetch(PDO::FETCH_ASSOC)) {
            $title = trim((string)($row['video_title'] ?? ''));
            if ($title === '') {
                $title = trim((string)($row['items_name_ar'] ?? ''));
            }
            if ($title === '') {
                $title = trim((string)($row['items_name_en'] ?? ''));
            }
            if ($title === '') {
                $title = 'فيديو';
            }

            $subtitle = trim((string)($row['video_desc'] ?? ''));
            if ($subtitle === '') {
                $subtitle = trim((string)($row['vendor_name'] ?? ''));
            }
            if ($subtitle === '') {
                $subtitle = trim((string)($row['uploader_name'] ?? ''));
            }

            $targetType = strtolower(trim((string)($row['video_target_type'] ?? '')));
            if (!in_array($targetType, ['restaurant', 'product'], true)) {
                $targetType = (int)($row['video_product_id'] ?? 0) > 0 ? 'product' : 'video';
            }

            $targetId = (int)($row['video_target_id'] ?? 0);
            if ($targetId <= 0 && $targetType === 'product') {
                $targetId = (int)($row['video_product_id'] ?? 0);
            }
            if ($targetId <= 0 && $targetType === 'restaurant') {
                $targetId = (int)($row['vendor_id'] ?? 0);
            }

            $stories[] = [
                'id' => (int)($row['video_id'] ?? 0),
                'title' => $title,
                'subtitle' => $subtitle,
                'type_label' => 'فيديو',
                'placement' => $targetType,
                'metric_label' => 'المشاهدات',
                'metric_value' => (int)($row['video_views'] ?? 0),
                'status' => ((int)($row['video_is_active'] ?? 1) === 1) ? 'نشط' : 'متوقف',
                'start_date' => (string)($row['video_date'] ?? ''),
                'end_date' => '',
                'image_url' => masterMarketingVideoUrl($row['video_thumbnail'] ?? ''),
                'video_url' => masterMarketingVideoUrl($row['video_url'] ?? ''),
                'accent_hex' => '#0EA5E9',
                'target_type' => $targetType,
                'target_id' => $targetId,
                'vendor_id' => (int)($row['vendor_id'] ?? 0),
                'sort_order' => 0,
                'media_type' => 'video',
            ];
        }
    }

    $featured = [];
    if (tableExists('categories')) {
        $categoryActiveSelect = columnExists('categories', 'categories_active')
            ? 'c.categories_active'
            : '1';
        $categoryStmt = $con->query("
            SELECT
                c.categories_id,
                c.categories_name_ar,
                c.categories_name_en,
                c.categories_image,
                c.categories_datetime,
                c.vendor_id,
                {$categoryActiveSelect} AS categories_active,
                COUNT(i.items_id) AS products_count
            FROM categories c
            LEFT JOIN items i ON i.items_cat = c.categories_id
            GROUP BY
                c.categories_id,
                c.categories_name_ar,
                c.categories_name_en,
                c.categories_image,
                c.categories_datetime,
                c.vendor_id,
                categories_active
            ORDER BY products_count DESC, c.categories_datetime DESC
            LIMIT 150
        ");
        while ($row = $categoryStmt->fetch(PDO::FETCH_ASSOC)) {
            $title = trim((string)($row['categories_name_ar'] ?? ''));
            if ($title === '') {
                $title = trim((string)($row['categories_name_en'] ?? ''));
            }
            $featured[] = [
                'id' => (int)($row['categories_id'] ?? 0),
                'title' => $title,
                'subtitle' => 'قسم طعام',
                'type_label' => 'قسم مميز',
                'placement' => 'الصفحة الرئيسية',
                'metric_label' => 'عدد المنتجات',
                'metric_value' => (int)($row['products_count'] ?? 0),
                'status' => ((int)($row['categories_active'] ?? 1) === 1) ? 'نشط' : 'متوقف',
                'start_date' => (string)($row['categories_datetime'] ?? ''),
                'end_date' => '',
                'image_url' => zahra_category_image_url($row['categories_image'] ?? ''),
                'accent_hex' => '#16A34A',
                'vendor_id' => (int)($row['vendor_id'] ?? 0),
                'is_active' => (int)($row['categories_active'] ?? 1),
            ];
        }
    }

    $notifications = [];
    if (tableExists('notifications')) {
        $notificationStmt = $con->query("
            SELECT
                notification_id,
                notification_type,
                notification_title,
                notification_body,
                notification_is_read,
                notification_created_at
            FROM notifications
            ORDER BY notification_created_at DESC, notification_id DESC
            LIMIT 150
        ");
        while ($row = $notificationStmt->fetch(PDO::FETCH_ASSOC)) {
            $notifications[] = [
                'id' => (int)($row['notification_id'] ?? 0),
                'title' => (string)($row['notification_title'] ?? ''),
                'subtitle' => (string)($row['notification_body'] ?? ''),
                'type_label' => (string)($row['notification_type'] ?? 'general'),
                'placement' => 'المستخدمون',
                'metric_label' => 'حالة القراءة',
                'metric_value' => (int)($row['notification_is_read'] ?? 0),
                'status' => ((int)($row['notification_is_read'] ?? 0) === 1) ? 'مقروء' : 'مرسل',
                'start_date' => (string)($row['notification_created_at'] ?? ''),
                'end_date' => '',
                'image_url' => '',
                'accent_hex' => '#2563EB',
            ];
        }
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => date('c'),
            'coupon_count' => $couponCount,
        'offers' => $offers,
        'coupons' => $coupons,
        'sliders' => $sliders,
        'stories' => $stories,
        'featured' => $featured,
        'notifications' => $notifications,
        'data_quality' => empty($masterMarketingQueryFailures)
            ? ['state' => 'complete']
            : [
                'state' => 'degraded',
                'failed_components' => array_values(array_unique($masterMarketingQueryFailures)),
            ],
    ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
