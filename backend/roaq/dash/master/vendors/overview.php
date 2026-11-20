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

$masterVendorQueryFailures = [];

function masterVendorMarkQueryFailure(string $component, Throwable $error): void
{
    global $masterVendorQueryFailures;
    $masterVendorQueryFailures[] = $component;
    error_log('master vendors ' . $component . ' failed: ' . $error->getMessage());
}

function masterVendorRows(string $sql): array
{
    global $con;
    try {
        $stmt = $con->query($sql);
        return $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    } catch (Throwable $e) {
        masterVendorMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function masterVendorSelect(string $table, string $alias, string $column, string $fallback, ?string $as = null): string
{
    $asName = $as ?: $column;
    return columnExists($table, $column)
        ? "COALESCE({$alias}.{$column}, {$fallback}) AS {$asName}"
        : "{$fallback} AS {$asName}";
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'restaurants.view');
    $master = masterPublicData($admin);
    $vendorType = strtolower(trim((string)($_GET['vendor_type'] ?? '')));
    if (!in_array($vendorType, ['restaurant', 'store'], true)) {
        $vendorType = '';
    }
    $vendorTypeWhere = $vendorType !== ''
        ? "WHERE LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType)
        : '';

    $restaurants = [];
    if (tableExists('vendors')) {
        $vendorNameSelect = masterVendorSelect('vendors', 'v', 'vendor_name', "''");
        $storeNameSelect = masterVendorSelect('vendors', 'v', 'store_name', "''");
        $storeSlugSelect = masterVendorSelect('vendors', 'v', 'store_slug', "''");
        $vendorEmailSelect = masterVendorSelect('vendors', 'v', 'vendor_email', "''");
        $vendorPhoneSelect = masterVendorSelect('vendors', 'v', 'vendor_phone', "''");
        $vendorDescriptionSelect = masterVendorSelect('vendors', 'v', 'vendor_description', "''");
        $vendorLogoSelect = masterVendorSelect('vendors', 'v', 'vendor_logo', "''");
        $vendorStatusSelect = masterVendorSelect('vendors', 'v', 'vendor_status', "'active'");
        $vendorVerifiedSelect = masterVendorSelect('vendors', 'v', 'vendor_is_verified', "1");
        $vendorTypeSelect = masterVendorSelect('vendors', 'v', 'vendor_type', "'restaurant'");
        $storeCategorySelect = masterVendorSelect('vendors', 'v', 'store_category', "''");
        $vendorCreatedSelect = masterVendorSelect('vendors', 'v', 'vendor_created_at', "NOW()");
        $restaurantOrderBy = columnExists('vendors', 'vendor_created_at')
            ? "v.vendor_created_at DESC, v.vendor_id DESC"
            : "v.vendor_id DESC";
        $settingsJoin = tableExists('vendor_store_settings')
            ? "LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id"
            : "";
        $settingsSelect = tableExists('vendor_store_settings')
            ? implode(",\n                ", [
                masterVendorSelect('vendor_store_settings', 's', 'store_address', "''"),
                masterVendorSelect('vendor_store_settings', 's', 'store_latitude', '0'),
                masterVendorSelect('vendor_store_settings', 's', 'store_longitude', '0'),
                masterVendorSelect('vendor_store_settings', 's', 'coverage_km', '0', 'coverage_zones'),
            ])
            : "'' AS store_address,
                0 AS store_latitude,
                0 AS store_longitude,
                0 AS coverage_zones";
        $canJoinVendorOrders = tableExists('vendor_orders')
            && tableExists('orders')
            && columnExists('vendor_orders', 'vendor_id')
            && columnExists('vendor_orders', 'order_id')
            && columnExists('vendor_orders', 'vendor_total')
            && columnExists('orders', 'orders_id')
            && columnExists('orders', 'orders_datetime');
        $ordersJoin = $canJoinVendorOrders
            ? "LEFT JOIN (
                SELECT
                    vo.vendor_id,
                    COUNT(CASE WHEN DATE(o.orders_datetime) = CURDATE() THEN 1 END) AS today_orders,
                    COALESCE(SUM(CASE WHEN DATE(o.orders_datetime) = CURDATE() THEN vo.vendor_total ELSE 0 END), 0) AS today_revenue
                FROM vendor_orders vo
                INNER JOIN orders o ON o.orders_id = vo.order_id
                GROUP BY vo.vendor_id
            ) vo ON vo.vendor_id = v.vendor_id"
            : "";
        $ordersSelect = $canJoinVendorOrders
            ? "COALESCE(vo.today_orders, 0) AS today_orders,
                COALESCE(vo.today_revenue, 0) AS revenue"
            : "0 AS today_orders,
                0 AS revenue";
        $canJoinRatings = tableExists('ratings')
            && tableExists('items')
            && columnExists('ratings', 'rating')
            && columnExists('ratings', 'item_id')
            && columnExists('items', 'items_id')
            && columnExists('items', 'vendor_id');
        $ratingJoin = $canJoinRatings
            ? "LEFT JOIN (
                SELECT i.vendor_id, ROUND(AVG(r.rating), 1) AS average_rating
                FROM ratings r
                INNER JOIN items i ON i.items_id = r.item_id
                GROUP BY i.vendor_id
            ) rt ON rt.vendor_id = v.vendor_id"
            : "";
        $ratingSelect = $canJoinRatings
            ? "COALESCE(rt.average_rating, 0) AS rating"
            : "0 AS rating";

        $restaurants = masterVendorRows("
            SELECT
                v.vendor_id,
                {$vendorNameSelect},
                {$storeNameSelect},
                {$storeSlugSelect},
                {$vendorEmailSelect},
                {$vendorPhoneSelect},
                {$vendorDescriptionSelect},
                {$vendorLogoSelect},
                {$vendorStatusSelect},
                {$vendorVerifiedSelect},
                {$vendorTypeSelect},
                {$storeCategorySelect},
                {$vendorCreatedSelect},
                {$settingsSelect},
                {$ordersSelect},
                {$ratingSelect},
                25 AS average_prep_minutes
            FROM vendors v
            {$settingsJoin}
            {$ordersJoin}
            {$ratingJoin}
            {$vendorTypeWhere}
            ORDER BY {$restaurantOrderBy}
            LIMIT 500
        ");
    } else {
        $masterVendorQueryFailures[] = 'vendors_schema';
    }

    $categories = [];
    if (tableExists('categories')) {
        $categoriesIdSelect = masterVendorSelect('categories', 'c', 'categories_id', '0');
        $categoriesNameEnSelect = masterVendorSelect('categories', 'c', 'categories_name_en', "''");
        $categoriesNameArSelect = masterVendorSelect('categories', 'c', 'categories_name_ar', "''");
        $categoriesImageSelect = masterVendorSelect('categories', 'c', 'categories_image', "''");
        $categoriesVendorSelect = masterVendorSelect('categories', 'c', 'vendor_id', '0');
        $categoriesTypeSelect = masterVendorSelect('categories', 'c', 'category_type', "'restaurant'");
        $categoriesOrderBy = columnExists('categories', 'categories_id') ? 'c.categories_id DESC' : '1 DESC';
        $categoryVendorJoin = $vendorType !== '' && tableExists('vendors')
            ? "LEFT JOIN vendors v ON v.vendor_id = c.vendor_id"
            : '';
        $categoryTypeWhere = $vendorType !== ''
            ? "WHERE (c.vendor_id = 0 AND LOWER(COALESCE(c.category_type, 'restaurant')) = " . $con->quote($vendorType) . ")
                OR (c.vendor_id > 0 AND LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType) . ")"
            : '';
        $categories = masterVendorRows("
            SELECT
                {$categoriesIdSelect},
                {$categoriesNameEnSelect},
                {$categoriesNameArSelect},
                {$categoriesImageSelect},
                {$categoriesVendorSelect}
                ,{$categoriesTypeSelect}
            FROM categories c
            {$categoryVendorJoin}
            {$categoryTypeWhere}
            ORDER BY {$categoriesOrderBy}
            LIMIT 500
        ");
    }

    $products = [];
    if (tableExists('items')) {
        $canJoinVendors = tableExists('vendors') && columnExists('items', 'vendor_id');
        $vendorJoin = $canJoinVendors ? "LEFT JOIN vendors v ON v.vendor_id = i.vendor_id" : "";
        $joinedStoreNameSelect = $canJoinVendors
            ? (columnExists('vendors', 'store_name') ? "v.store_name" : "''")
            : "''";
        $joinedVendorNameSelect = $canJoinVendors
            ? (columnExists('vendors', 'vendor_name') ? "v.vendor_name" : "''")
            : "''";
        $vendorSelect = $canJoinVendors
            ? "COALESCE(NULLIF({$joinedStoreNameSelect}, ''), {$joinedVendorNameSelect}, '') AS store_name,
                COALESCE({$joinedVendorNameSelect}, '') AS vendor_name"
            : "'' AS store_name,
                '' AS vendor_name";
        $orderStatsJoin = tableExists('order_items')
            ? "LEFT JOIN (
                SELECT item_id, COUNT(*) AS orders_count
                FROM order_items
                GROUP BY item_id
            ) oi ON oi.item_id = i.items_id"
            : "";
        $orderStatsSelect = tableExists('order_items')
            ? "COALESCE(oi.orders_count, 0) AS orders_count"
            : "0 AS orders_count";
        $ratingStatsJoin = tableExists('ratings')
            ? "LEFT JOIN (
                SELECT item_id, ROUND(AVG(rating), 1) AS average_rating
                FROM ratings
                GROUP BY item_id
            ) ir ON ir.item_id = i.items_id"
            : "";
        $ratingStatsSelect = tableExists('ratings')
            ? "COALESCE(ir.average_rating, 0) AS average_rating"
            : "0 AS average_rating";
        $itemsIdSelect = masterVendorSelect('items', 'i', 'items_id', '0');
        $itemsNameEnSelect = masterVendorSelect('items', 'i', 'items_name_en', "''");
        $itemsNameArSelect = masterVendorSelect('items', 'i', 'items_name_ar', "''");
        $itemsDescEnSelect = masterVendorSelect('items', 'i', 'items_desc_en', "''");
        $itemsDescArSelect = masterVendorSelect('items', 'i', 'items_desc_ar', "''");
        $itemsImageSelect = masterVendorSelect('items', 'i', 'items_image', "''");
        $itemsCountSelect = masterVendorSelect('items', 'i', 'items_count', '0');
        $itemsActiveSelect = masterVendorSelect('items', 'i', 'items_active', '1');
        $itemsPriceSelect = masterVendorSelect('items', 'i', 'items_price', '0');
        $itemsDiscountSelect = masterVendorSelect('items', 'i', 'items_discount', '0');
        $itemsDateSelect = masterVendorSelect('items', 'i', 'items_date', "NOW()");
        $itemsCatSelect = masterVendorSelect('items', 'i', 'items_cat', '0');
        $itemsVendorSelect = masterVendorSelect('items', 'i', 'vendor_id', '0');
        $productsOrderBy = columnExists('items', 'items_id') ? 'i.items_id DESC' : '1 DESC';

        $productTypeWhere = $vendorType !== '' && $canJoinVendors
            ? "WHERE LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType)
            : '';
        $products = masterVendorRows("
            SELECT
                {$itemsIdSelect},
                {$itemsNameEnSelect},
                {$itemsNameArSelect},
                {$itemsDescEnSelect},
                {$itemsDescArSelect},
                {$itemsImageSelect},
                {$itemsCountSelect},
                {$itemsActiveSelect},
                {$itemsPriceSelect},
                {$itemsDiscountSelect},
                {$itemsDateSelect},
                {$itemsCatSelect},
                {$itemsVendorSelect},
                {$vendorSelect},
                {$orderStatsSelect},
                {$ratingStatsSelect}
            FROM items i
            {$vendorJoin}
            {$orderStatsJoin}
            {$ratingStatsJoin}
            {$productTypeWhere}
            ORDER BY {$productsOrderBy}
            LIMIT 1000
        ");
    }

    $toppings = [];
    if (tableExists('food_item_modifier_groups') && tableExists('food_item_modifiers')) {
        $toppingTypeWhere = $vendorType !== '' && tableExists('vendors')
            ? "WHERE LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType)
            : '';
        $toppings = masterVendorRows("
            SELECT
                m.modifier_id,
                g.group_id,
                g.item_id,
                g.name_ar AS group_name_ar,
                g.name_en AS group_name_en,
                g.group_type,
                g.min_select,
                g.max_select,
                g.is_required,
                g.is_active AS group_active,
                m.name_ar,
                m.name_en,
                m.price_delta,
                m.image_url,
                m.is_active,
                i.items_cat,
                COALESCE(NULLIF(v.store_name, ''), v.vendor_name, '') AS store_name
            FROM food_item_modifiers m
            INNER JOIN food_item_modifier_groups g ON g.group_id = m.group_id
            LEFT JOIN items i ON i.items_id = g.item_id
            LEFT JOIN vendors v ON v.vendor_id = i.vendor_id
            {$toppingTypeWhere}
            ORDER BY g.sort_order ASC, m.sort_order ASC, m.modifier_id DESC
            LIMIT 500
        ");
        foreach ($toppings as &$topping) {
            $rawImage = trim((string)($topping['image_url'] ?? ''));
            if ($rawImage === '') {
                continue;
            }
            if (stripos($rawImage, 'http://') === 0 || stripos($rawImage, 'https://') === 0) {
                $topping['image_url'] = zahra_normalize_absolute_url($rawImage);
            } elseif (strpos($rawImage, '/') !== false) {
                $topping['image_url'] = zahra_public_url($rawImage);
            } else {
                $topping['image_url'] = zahra_public_url('uploud/modifier_options/' . $rawImage);
            }
        }
        unset($topping);
    }

    $offers = [];
    if (tableExists('restaurant_banners')) {
        $bannerVendorSelect = columnExists('restaurant_banners', 'vendor_id')
            ? 'vendor_id'
            : '0 AS vendor_id';
        $bannerVendorJoin = $vendorType !== '' && columnExists('restaurant_banners', 'vendor_id') && tableExists('vendors')
            ? 'LEFT JOIN vendors v ON v.vendor_id = restaurant_banners.vendor_id'
            : '';
        $bannerTypeWhere = $vendorType !== '' && columnExists('restaurant_banners', 'vendor_id') && tableExists('vendors')
            ? "WHERE LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType)
            : '';
        $offers = masterVendorRows("
            SELECT
                banner_id,
                {$bannerVendorSelect},
                title_ar,
                title_en,
                subtitle_ar,
                subtitle_en,
                image_url,
                target_type,
                target_id,
                starts_at,
                ends_at,
                is_active,
                sort_order,
                created_at
            FROM restaurant_banners
            {$bannerVendorJoin}
            {$bannerTypeWhere}
            ORDER BY is_active DESC, sort_order ASC, banner_id DESC
            LIMIT 300
        ");
    }

    $couponVendorJoin = $vendorType !== '' && tableExists('coupon') && columnExists('coupon', 'vendor_id') && tableExists('vendors')
        ? 'LEFT JOIN vendors v ON v.vendor_id = coupon.vendor_id'
        : '';
    $couponTypeWhere = $vendorType !== '' && tableExists('coupon') && columnExists('coupon', 'vendor_id') && tableExists('vendors')
        ? "WHERE LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType)
        : '';
    $coupons = tableExists('coupon') ? masterVendorRows("
        SELECT
            coupon_id,
            coupon_name,
            coupon_count,
            coupon_expiredate,
            coupon_discount
        FROM coupon
        {$couponVendorJoin}
        {$couponTypeWhere}
        ORDER BY coupon_expiredate DESC, coupon_id DESC
        LIMIT 300
    ") : [];

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => date('c'),
            'restaurants' => $restaurants,
            'categories' => $categories,
            'products' => $products,
            'toppings' => $toppings,
            'offers' => $offers,
            'coupons' => $coupons,
            'data_quality' => empty($masterVendorQueryFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($masterVendorQueryFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [
            'restaurants' => [],
            'categories' => [],
            'products' => [],
            'toppings' => [],
            'offers' => [],
            'coupons' => [],
        ],
    ], 500);
}
