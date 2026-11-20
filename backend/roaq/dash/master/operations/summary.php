<?php
require_once "../../../connect.php";

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

$operationsQueryFailures = [];

function operationsMarkQueryFailure(string $component, Throwable $error): void
{
    global $operationsQueryFailures;
    $operationsQueryFailures[] = $component;
    error_log('master operations ' . $component . ' failed: ' . $error->getMessage());
}

function opScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        operationsMarkQueryFailure('scalar_query', $e);
        return $fallback;
    }
}

function opRows(string $sql, array $params = []): array
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        operationsMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function opCount(string $table, string $where = '1=1'): int
{
    if (!tableExists($table)) {
        return 0;
    }
    return (int)opScalar("SELECT COUNT(*) FROM {$table} WHERE {$where}", [], 0);
}

function opNumber($value, int $decimals = 0): string
{
    return number_format((float)$value, $decimals, '.', ',');
}

function opTime(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '--:--' : date('H:i:s', $timestamp);
}

function opRelative(?string $value): string
{
    $timestamp = strtotime((string)$value);
    if ($timestamp === false) {
        return 'الآن';
    }

    $seconds = max(0, time() - $timestamp);
    if ($seconds < 60) {
        return 'منذ ' . max(1, $seconds) . ' ثانية';
    }
    $minutes = (int)floor($seconds / 60);
    if ($minutes < 60) {
        return 'منذ ' . $minutes . ' دقيقة';
    }
    $hours = (int)floor($minutes / 60);
    if ($hours < 24) {
        return 'منذ ' . $hours . ' ساعة';
    }
    return 'منذ ' . (int)floor($hours / 24) . ' يوم';
}

function opStatusColor(string $status): string
{
    $status = strtolower(trim($status));
    if (in_array($status, ['paid', 'delivered', 'completed', 'complete'], true)) {
        return '#1A8B4A';
    }
    if (in_array($status, ['pending', 'assigned', 'accepted', 'picked_up', 'on_the_way', 'heading_to_customer'], true)) {
        return '#2563EB';
    }
    if (in_array($status, ['preparing', 'ready', 'arrived_at_restaurant', 'heading_to_restaurant'], true)) {
        return '#F59E0B';
    }
    if (in_array($status, ['failed', 'canceled', 'cancelled', 'rejected'], true)) {
        return '#D92C2C';
    }
    return '#4E5660';
}

function opStatusLabel(string $status): string
{
    $status = strtolower(trim($status));
    $map = [
        'pending' => 'جديد',
        'paid' => 'مدفوع',
        'assigned' => 'مع السائق',
        'accepted' => 'مقبول',
        'preparing' => 'قيد التحضير',
        'ready' => 'جاهز للاستلام',
        'heading_to_restaurant' => 'إلى المطعم',
        'arrived_at_restaurant' => 'وصل المطعم',
        'picked_up' => 'تم الاستلام',
        'heading_to_customer' => 'على الطريق',
        'on_the_way' => 'على الطريق',
        'arrived_at_customer' => 'وصل العميل',
        'delivered' => 'مكتمل',
        'completed' => 'مكتمل',
        'failed' => 'فشل',
        'canceled' => 'ملغي',
        'cancelled' => 'ملغي',
        'rejected' => 'مرفوض',
    ];
    return $map[$status] ?? ($status !== '' ? $status : 'غير محدد');
}

function opOrderType($value): string
{
    $type = strtolower(trim((string)$value));
    if (in_array($type, ['restaurant', 'restaurants', 'food', 'meal', 'meals'], true)) {
        return 'food';
    }
    if (in_array($type, ['store', 'stores', 'market', 'supermarket', 'shop'], true)) {
        return 'store';
    }
    return $type;
}

function opStatCard($title, $value, $iconKey, $accent, $background, $detailLine, $trendLabel = '', $trendCaption = '', $trendPositive = true): array
{
    return [
        'title' => $title,
        'value' => (string)$value,
        'icon_key' => $iconKey,
        'accent_hex' => $accent,
        'background_hex' => $background,
        'detail_line' => $detailLine,
        'trend_label' => $trendLabel,
        'trend_caption' => $trendCaption,
        'trend_positive' => (bool)$trendPositive,
    ];
}

function opCoordinate($value): ?float
{
    if ($value === null || $value === '' || !is_numeric($value)) {
        return null;
    }
    $number = (float)$value;
    if (!is_finite($number) || abs($number) < 0.000001) {
        return null;
    }
    return $number;
}

function opMapMarker($type, $label, $lat, $lng, $iconKey, $color, $subtitle = '', $entityId = 0, $statusKey = ''): ?array
{
    $lat = opCoordinate($lat);
    $lng = opCoordinate($lng);
    if ($lat === null || $lng === null) {
        return null;
    }

    return [
        'type' => $type,
        'label' => (string)$label,
        'subtitle' => (string)$subtitle,
        'lat' => $lat,
        'lng' => $lng,
        'icon_key' => $iconKey,
        'color_hex' => $color,
        'entity_id' => (int)$entityId,
        'status_key' => strtolower((string)$statusKey),
    ];
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'dashboard.view');
    $master = masterPublicData($admin);

    $ordersAvailable = tableExists('orders');
    $vendorsAvailable = tableExists('vendors');
    $driversAvailable = tableExists('delivery_users');
    $branchesAvailable = tableExists('restaurant_branches');
    $accountingAvailable = tableExists('accounting_entries');
    $notificationsAvailable = tableExists('notifications');

    if (!$ordersAvailable) {
        $operationsQueryFailures[] = 'orders_schema';
    }

    $activeOrderWhere = "COALESCE(status, orders_status, '') NOT IN ('delivered','completed','canceled','cancelled','failed','archive','archived','4')";
    $activeOrderWhereO = "COALESCE(o.status, o.orders_status, '') NOT IN ('delivered','completed','canceled','cancelled','failed','archive','archived','4')";
    $orderCounts = [
        'new' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE DATE(orders_datetime)=CURDATE()") : 0,
        'pending' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(orders_status, status, '') IN ('pending','new')") : 0,
        'preparing' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('preparing','accepted','heading_to_restaurant','arrived_at_restaurant')") : 0,
        'ready' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('ready','picked_up','assigned')") : 0,
        'active' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE {$activeOrderWhere}") : 0,
        'completed_today' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('delivered','completed','paid') AND DATE(COALESCE(delivered_at, updated_at, orders_datetime))=CURDATE()") : 0,
        'canceled_today' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('canceled','cancelled','failed','rejected') AND DATE(COALESCE(updated_at, orders_datetime))=CURDATE()") : 0,
        'late' => $ordersAvailable ? (int)opScalar("SELECT COUNT(*) FROM orders WHERE {$activeOrderWhere} AND orders_datetime <= DATE_SUB(NOW(), INTERVAL 45 MINUTE)") : 0,
    ];

    $driverCounts = [
        'total' => opCount('delivery_users'),
        'online' => $driversAvailable ? (int)opScalar("SELECT COUNT(*) FROM delivery_users WHERE status='online' OR (last_seen_at IS NOT NULL AND last_seen_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE))") : 0,
        'busy' => $ordersAvailable ? (int)opScalar("SELECT COUNT(DISTINCT delivery_id) FROM orders WHERE delivery_id IS NOT NULL AND delivery_id > 0 AND {$activeOrderWhere}") : 0,
    ];
    $driverCounts['available'] = max(0, $driverCounts['online'] - $driverCounts['busy']);
    $driverCounts['offline'] = max(0, $driverCounts['total'] - $driverCounts['online']);

    $vendorCounts = [
        'total' => opCount('vendors'),
        'open' => $vendorsAvailable ? (int)opScalar("
            SELECT COUNT(*)
            FROM vendors v
            LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
            WHERE v.vendor_status = 'active'
              AND v.vendor_is_verified = 1
              AND COALESCE(s.is_open, 1) = 1
        ") : 0,
        'pending' => $vendorsAvailable ? (int)opScalar("SELECT COUNT(*) FROM vendors WHERE vendor_status='pending' OR vendor_is_verified = 0") : 0,
        'suspended' => $vendorsAvailable ? (int)opScalar("SELECT COUNT(*) FROM vendors WHERE vendor_status='suspended'") : 0,
    ];
    $vendorCounts['closed'] = max(0, $vendorCounts['total'] - $vendorCounts['open']);

    $financeCounts = [
        'entries_today' => $accountingAvailable ? (int)opScalar("SELECT COUNT(*) FROM accounting_entries WHERE DATE(entry_date)=CURDATE()") : 0,
        'refunds_today' => $accountingAvailable ? (int)opScalar("SELECT COUNT(*) FROM accounting_entries WHERE entry_type='refund' AND DATE(entry_date)=CURDATE()") : 0,
        'sales_today' => $accountingAvailable ? (float)opScalar("SELECT COALESCE(SUM(credit),0) FROM accounting_entries WHERE entry_type='sale' AND DATE(entry_date)=CURDATE()") : 0,
        'delivery_fees_today' => $ordersAvailable ? (float)opScalar("SELECT COALESCE(SUM(orders_pricedelivery),0) FROM orders WHERE DATE(orders_datetime)=CURDATE()") : 0,
        'orders_total_today' => $ordersAvailable ? (float)opScalar("SELECT COALESCE(SUM(orders_totalprice),0) FROM orders WHERE DATE(orders_datetime)=CURDATE()") : 0,
    ];

    $notificationsUnread = $notificationsAvailable ? (int)opScalar("SELECT COUNT(*) FROM notifications WHERE notification_is_read = 0") : 0;
    $supportCount = tableExists('support') ? (int)opScalar("SELECT COUNT(*) FROM support WHERE DATE(created_at)=CURDATE()") : 0;
    $activityTotal = $orderCounts['new'] + $orderCounts['active'] + $driverCounts['online'] + $vendorCounts['open'] + $financeCounts['entries_today'] + $notificationsUnread;

    $overviewCards = [
        opStatCard('طلبات جديدة', $orderCounts['new'], 'orders', '#CA7A00', '#FFF5E6', 'اليوم', '+' . $orderCounts['new'], 'من قاعدة البيانات', true),
        opStatCard('بانتظار قبول المطعم', $orderCounts['pending'], 'hourglass', '#F59E0B', '#FFF4E4', 'طلبات معلقة', (string)$orderCounts['pending'], 'مباشر', true),
        opStatCard('قيد التحضير', $orderCounts['preparing'], 'kitchen', '#6F4DFF', '#F1EEFF', 'داخل المطاعم', (string)$orderCounts['preparing'], 'مباشر', true),
        opStatCard('جاهزة للاستلام', $orderCounts['ready'], 'delivery', '#1E7D3F', '#EAF5ED', 'بانتظار السائق', (string)$orderCounts['ready'], 'مباشر', true),
        opStatCard('على الطريق', max(0, $orderCounts['active'] - $orderCounts['pending'] - $orderCounts['preparing'] - $orderCounts['ready']), 'scooter', '#12A4A0', '#E6F9F7', 'حركة نشطة', (string)$orderCounts['active'], 'نشط', true),
        opStatCard('مكتملة اليوم', $orderCounts['completed_today'], 'check', '#1A8B4A', '#EAF5ED', 'تم التسليم', (string)$orderCounts['completed_today'], 'اليوم', true),
        opStatCard('ملغاة اليوم', $orderCounts['canceled_today'], 'cancel', '#D92C2C', '#FDEEEF', 'من قاعدة البيانات', (string)$orderCounts['canceled_today'], 'اليوم', false),
        opStatCard('مستخدمون جدد', tableExists('users') ? (int)opScalar("SELECT COUNT(*) FROM users WHERE DATE(users_creat)=CURDATE()") : 0, 'users', '#6F4DFF', '#F1EEFF', 'اليوم', '', '', true),
        opStatCard('سائقون متأخرون', $orderCounts['late'], 'warning', '#D92C2C', '#FDEEEF', 'بحاجة متابعة', (string)$orderCounts['late'], 'تنبيه', false),
        opStatCard('سائقون مشغولون', $driverCounts['busy'], 'delivery', '#F59E0B', '#FFF4E4', 'من أصل ' . $driverCounts['total'], '', '', true),
        opStatCard('سائقون متاحون', $driverCounts['available'], 'delivery', '#1E7D3F', '#EAF5ED', 'من أصل ' . $driverCounts['total'], '', '', true),
        opStatCard('المطاعم المغلقة', $vendorCounts['closed'], 'store', '#525A64', '#F3F5F6', 'من أصل ' . $vendorCounts['total'], '', '', false),
        opStatCard('المطاعم المفتوحة', $vendorCounts['open'], 'store', '#1E7D3F', '#EAF5ED', 'من أصل ' . $vendorCounts['total'], '', '', true),
        opStatCard('رسوم التوصيل', opNumber($financeCounts['delivery_fees_today']), 'scooter', '#2563EB', '#EAF1FF', 'إيراد التوصيل اليوم', '', '', true),
        opStatCard('مبيعات اليوم', opNumber($financeCounts['orders_total_today']), 'payments', '#1A8B4A', '#EAF5ED', 'قيمة الطلبات اليوم', '', '', true),
    ];

    $branchSelect = $branchesAvailable
        ? "COALESCE(s.store_latitude, rb.latitude) AS restaurant_lat,
            COALESCE(s.store_longitude, rb.longitude) AS restaurant_lng,"
        : "s.store_latitude AS restaurant_lat,
            s.store_longitude AS restaurant_lng,";
    $branchJoin = $branchesAvailable
        ? "LEFT JOIN (
            SELECT vendor_id, AVG(latitude) AS latitude, AVG(longitude) AS longitude
            FROM restaurant_branches
            GROUP BY vendor_id
        ) rb ON rb.vendor_id = v.vendor_id"
        : "";

    $confirmationCodeSelect = "'' AS confirmation_code,";
    $hasDeliveryCode = columnExists('orders', 'delivery_code');
    $hasProofCode = columnExists('orders', 'proof_code');
    if ($hasDeliveryCode && $hasProofCode) {
        $confirmationCodeSelect = "COALESCE(NULLIF(o.delivery_code, ''), NULLIF(o.proof_code, ''), '') AS confirmation_code,";
    } elseif ($hasDeliveryCode) {
        $confirmationCodeSelect = "COALESCE(o.delivery_code, '') AS confirmation_code,";
    } elseif ($hasProofCode) {
        $confirmationCodeSelect = "COALESCE(o.proof_code, '') AS confirmation_code,";
    }

    $vendorTypeSelect = columnExists('vendors', 'vendor_type')
        ? "NULLIF(v.vendor_type, '')"
        : "NULL";
    $orderTypeSelect = columnExists('orders', 'orders_type')
        ? "COALESCE(NULLIF(o.orders_type, ''), {$vendorTypeSelect}, 'food') AS order_type,"
        : "COALESCE({$vendorTypeSelect}, 'food') AS order_type,";

    $orders = $ordersAvailable ? opRows("
        SELECT
            o.orders_id,
            COALESCE(u.users_name, o.orders_recipient_name, 'عميل') AS customer_name,
            COALESCE(o.orders_recipient_address_name, a.address_city, a.address_street, '') AS destination,
            COALESCE(o.status, o.orders_status, '') AS live_status,
            o.orders_status,
            o.orders_datetime,
            {$orderTypeSelect}
            o.orders_totalprice,
            {$confirmationCodeSelect}
            COALESCE(o.orders_recipient_lat, o.delivery_latitude, a.address_lat) AS recipient_lat,
            COALESCE(o.orders_recipient_lng, o.delivery_longitude, a.address_long) AS recipient_lng,
            COALESCE(o.driver_latitude, du.latitude) AS driver_lat,
            COALESCE(o.driver_longitude, du.longitude) AS driver_lng,
            du.id AS driver_entity_id,
            oi.vendor_id AS restaurant_vendor_id,
            {$branchSelect}
            COALESCE(v.store_name, v.vendor_name, '') AS restaurant_name,
            du.name AS driver_name
        FROM orders o
        LEFT JOIN users u ON u.users_id = o.orders_usersid
        LEFT JOIN address a ON a.address_id = o.orders_address
        LEFT JOIN delivery_users du ON du.id = o.delivery_id
        LEFT JOIN (
            SELECT order_id, MIN(vendor_id) AS vendor_id
            FROM order_items
            GROUP BY order_id
        ) oi ON oi.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = oi.vendor_id
        LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
        {$branchJoin}
        WHERE {$activeOrderWhereO}
        ORDER BY o.orders_datetime DESC
        LIMIT 20
    ") : [];

    $trackingOrders = [];
    $trackingRoutes = [];
    $activityFeed = [];
    $mapMarkers = [];
    foreach ($orders as $row) {
        $status = (string)($row['live_status'] ?: $row['orders_status'] ?: '');
        $statusLabel = opStatusLabel($status);
        $statusColor = opStatusColor($status);
        $time = (string)($row['orders_datetime'] ?? '');
        $orderNo = '#' . (int)($row['orders_id'] ?? 0);
        $trackingOrders[] = [
            'order_no' => $orderNo,
            'confirmation_code' => (string)($row['confirmation_code'] ?? ''),
            'customer' => (string)($row['customer_name'] ?? 'عميل'),
            'status_key' => strtolower($status),
            'order_type' => opOrderType($row['order_type'] ?? ''),
            'date_key' => $time !== '' ? date('Y-m-d', strtotime($time)) : '',
            'destination' => 'إلى: ' . (string)($row['destination'] ?? ''),
            'time_label' => opTime($time),
            'status_label' => $statusLabel,
            'status_color_hex' => $statusColor,
            'avatar_background_hex' => $statusColor === '#D92C2C' ? '#FDEEEF' : '#EAF5ED',
            'avatar_icon_key' => 'user',
        ];

        $recipientMarker = opMapMarker(
            'order',
            $orderNo,
            $row['recipient_lat'] ?? null,
            $row['recipient_lng'] ?? null,
            'orders',
            $statusColor,
            $statusLabel,
            (int)($row['orders_id'] ?? 0),
            $status
        );
        if ($recipientMarker !== null) {
            $mapMarkers[] = $recipientMarker;
        }

        $driverMarker = opMapMarker(
            'driver',
            (string)($row['driver_name'] ?? 'Driver'),
            $row['driver_lat'] ?? null,
            $row['driver_lng'] ?? null,
            'delivery',
            '#1E7D3F',
            $orderNo,
            (int)($row['driver_entity_id'] ?? 0),
            $status
        );
        if ($driverMarker !== null) {
            $mapMarkers[] = $driverMarker;
        }

        $restaurantMarker = opMapMarker(
            'restaurant',
            (string)($row['restaurant_name'] ?? 'Restaurant'),
            $row['restaurant_lat'] ?? null,
            $row['restaurant_lng'] ?? null,
            'store',
            '#F59E0B',
            $orderNo,
            (int)($row['restaurant_vendor_id'] ?? 0)
        );
        if ($restaurantMarker !== null) {
            $mapMarkers[] = $restaurantMarker;
        }

        $driverLat = opCoordinate($row['driver_lat'] ?? null);
        $driverLng = opCoordinate($row['driver_lng'] ?? null);
        $customerLat = opCoordinate($row['recipient_lat'] ?? null);
        $customerLng = opCoordinate($row['recipient_lng'] ?? null);
        $restaurantLat = opCoordinate($row['restaurant_lat'] ?? null);
        $restaurantLng = opCoordinate($row['restaurant_lng'] ?? null);

        if ($driverLat !== null && $driverLng !== null && $restaurantLat !== null && $restaurantLng !== null) {
            $trackingRoutes[] = [
                'order_no' => $orderNo,
                'label' => 'السائق ← المطعم',
                'color_hex' => '#F59E0B',
                'points' => [
                    ['lat' => $driverLat, 'lng' => $driverLng],
                    ['lat' => $restaurantLat, 'lng' => $restaurantLng],
                ],
            ];
        }
        if ($driverLat !== null && $driverLng !== null && $customerLat !== null && $customerLng !== null) {
            $trackingRoutes[] = [
                'order_no' => $orderNo,
                'label' => 'السائق ← العميل',
                'color_hex' => '#2563EB',
                'points' => [
                    ['lat' => $driverLat, 'lng' => $driverLng],
                    ['lat' => $customerLat, 'lng' => $customerLng],
                ],
            ];
        }
        $activityFeed[] = [
            'time_label' => opTime($time),
            'relative_label' => opRelative($time),
            'title' => 'تحديث طلب ' . $orderNo,
            'subtitle' => 'الحالة: ' . $statusLabel,
            'detail' => trim('المطعم: ' . (string)($row['restaurant_name'] ?? '')),
            'pill_label' => 'عرض الطلب',
            'icon_key' => 'orders',
            'accent_hex' => $statusColor,
            'background_hex' => $statusColor === '#D92C2C' ? '#FDEEEF' : '#EAF5ED',
        ];
    }

    $drivers = $driversAvailable ? opRows("
        SELECT
            du.id,
            COALESCE(du.name, CONCAT('Driver #', du.id)) AS driver_name,
            du.status,
            du.latitude,
            du.longitude,
            du.last_seen_at,
            COALESCE(stats.active_orders, 0) AS active_orders,
            COALESCE(ratings.average_rating, 0) AS average_rating
        FROM delivery_users du
        LEFT JOIN (
            SELECT delivery_id, COUNT(*) AS active_orders
            FROM orders
            WHERE delivery_id IS NOT NULL AND delivery_id > 0 AND {$activeOrderWhere}
            GROUP BY delivery_id
        ) stats ON stats.delivery_id = du.id
        LEFT JOIN (
            SELECT driver_id, ROUND(AVG(rating), 1) AS average_rating
            FROM driver_ratings
            GROUP BY driver_id
        ) ratings ON ratings.driver_id = du.id
        ORDER BY active_orders DESC, du.last_seen_at DESC
        LIMIT 8
    ") : [];

    $trackingDrivers = [];
    foreach ($drivers as $row) {
        $activeOrders = (int)($row['active_orders'] ?? 0);
        $isOnline = strtolower((string)($row['status'] ?? '')) === 'online';
        $trackingDrivers[] = [
            'title' => (string)($row['driver_name'] ?? ''),
            'subtitle' => $activeOrders > 0 ? 'على طلبات نشطة: ' . $activeOrders : 'آخر تحديث ' . opRelative($row['last_seen_at'] ?? null),
            'note' => (string)($row['average_rating'] ?: '--'),
            'status_label' => $activeOrders > 0 ? 'مشغول' : ($isOnline ? 'متاح' : 'متوقف'),
            'status_color_hex' => $activeOrders > 0 ? '#F59E0B' : ($isOnline ? '#1E7D3F' : '#D92C2C'),
            'icon_key' => 'delivery',
            'icon_color_hex' => '#1E7D3F',
            'background_hex' => '#EAF5ED',
        ];

        $activityFeed[] = [
            'time_label' => opTime($row['last_seen_at'] ?? null),
            'relative_label' => opRelative($row['last_seen_at'] ?? null),
            'title' => 'تحديث حالة سائق',
            'subtitle' => $activeOrders > 0 ? 'مشغول' : ($isOnline ? 'متصل الآن' : 'غير متصل'),
            'detail' => (string)($row['driver_name'] ?? 'سائق'),
            'pill_label' => 'عرض السائق',
            'icon_key' => 'delivery',
            'accent_hex' => $activeOrders > 0 ? '#F59E0B' : ($isOnline ? '#1E7D3F' : '#D92C2C'),
            'background_hex' => $activeOrders > 0 ? '#FFF4E4' : ($isOnline ? '#EAF5ED' : '#FDEEEF'),
        ];

        $driverMapMarker = opMapMarker(
            'driver',
            (string)($row['driver_name'] ?? ''),
            $row['latitude'] ?? null,
            $row['longitude'] ?? null,
            'delivery',
            $activeOrders > 0 ? '#F59E0B' : ($isOnline ? '#1E7D3F' : '#D92C2C'),
            $activeOrders > 0 ? ('Active orders: ' . $activeOrders) : opRelative($row['last_seen_at'] ?? null),
            (int)($row['id'] ?? 0)
        );
        if ($driverMapMarker !== null) {
            $mapMarkers[] = $driverMapMarker;
        }
    }

    // Surface recent driver emergency reports directly on the live operations map.
    // The report table is created by the driver emergency endpoint, so keep this
    // block optional for installations that have not received a report yet.
    $emergencyRows = [];
    if (tableExists('delivery_driver_emergency_reports') && $driversAvailable && $ordersAvailable) {
        $emergencyRows = opRows("
            SELECT
                r.emergency_report_id,
                r.driver_id,
                r.order_id,
                r.reason,
                r.reported_at,
                COALESCE(du.name, CONCAT('Driver #', r.driver_id)) AS driver_name,
                COALESCE(o.driver_latitude, du.latitude) AS latitude,
                COALESCE(o.driver_longitude, du.longitude) AS longitude
            FROM delivery_driver_emergency_reports r
            LEFT JOIN delivery_users du ON du.id = r.driver_id
            LEFT JOIN orders o ON o.orders_id = r.order_id
            WHERE r.reported_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
            ORDER BY r.reported_at DESC
            LIMIT 40
        ");
        foreach ($emergencyRows as $row) {
            $marker = opMapMarker(
                'emergency',
                'SOS #' . (int)($row['order_id'] ?? 0),
                $row['latitude'] ?? null,
                $row['longitude'] ?? null,
                'emergency',
                '#D92C2C',
                trim((string)($row['driver_name'] ?? 'Driver') . ' • ' . (string)($row['reason'] ?? 'Emergency')),
                (int)($row['driver_id'] ?? 0)
            );
            if ($marker !== null) {
                $mapMarkers[] = $marker;
            }
        }
    }
    // Older driver clients may only write the emergency fields on orders.
    if (empty($emergencyRows) && $ordersAvailable && columnExists('orders', 'driver_emergency_reason') && columnExists('orders', 'driver_emergency_at')) {
        $legacyEmergencyRows = opRows("
            SELECT
                o.orders_id AS order_id,
                o.delivery_id AS driver_id,
                o.driver_emergency_reason AS reason,
                o.driver_emergency_at AS reported_at,
                COALESCE(du.name, CONCAT('Driver #', o.delivery_id)) AS driver_name,
                COALESCE(o.driver_latitude, du.latitude) AS latitude,
                COALESCE(o.driver_longitude, du.longitude) AS longitude
            FROM orders o
            LEFT JOIN delivery_users du ON du.id = o.delivery_id
            WHERE COALESCE(o.driver_emergency_reason, '') <> ''
              AND o.driver_emergency_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
            ORDER BY o.driver_emergency_at DESC
            LIMIT 40
        ");
        foreach ($legacyEmergencyRows as $row) {
            $marker = opMapMarker(
                'emergency',
                'SOS #' . (int)($row['order_id'] ?? 0),
                $row['latitude'] ?? null,
                $row['longitude'] ?? null,
                'emergency',
                '#D92C2C',
                trim((string)($row['driver_name'] ?? 'Driver') . ' • ' . (string)($row['reason'] ?? 'Emergency')),
                (int)($row['driver_id'] ?? 0)
            );
            if ($marker !== null) {
                $mapMarkers[] = $marker;
            }
        }
    }

    $restaurantCoordinateSelect = $branchesAvailable
        ? "COALESCE(s.store_latitude, rb.latitude) AS latitude,
            COALESCE(s.store_longitude, rb.longitude) AS longitude,"
        : "s.store_latitude AS latitude,
            s.store_longitude AS longitude,";
    $restaurantBranchJoin = $branchesAvailable
        ? "LEFT JOIN (
            SELECT vendor_id, AVG(latitude) AS latitude, AVG(longitude) AS longitude
            FROM restaurant_branches
            GROUP BY vendor_id
        ) rb ON rb.vendor_id = v.vendor_id"
        : "";

    $restaurants = $vendorsAvailable ? opRows("
        SELECT
            v.vendor_id,
            COALESCE(NULLIF(v.store_name, ''), NULLIF(v.vendor_name, ''), 'غير محدد') AS restaurant_name,
            v.vendor_status,
            v.vendor_is_verified,
            COALESCE(s.is_open, 1) AS is_open,
            {$restaurantCoordinateSelect}
            COALESCE(stats.active_orders, 0) AS active_orders
        FROM vendors v
        LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
        {$restaurantBranchJoin}
        LEFT JOIN (
            SELECT oi.vendor_id, COUNT(DISTINCT oi.order_id) AS active_orders
            FROM order_items oi
            JOIN orders o ON o.orders_id = oi.order_id
            WHERE {$activeOrderWhereO}
            GROUP BY oi.vendor_id
        ) stats ON stats.vendor_id = v.vendor_id
        ORDER BY active_orders DESC, v.vendor_id DESC
        LIMIT 8
    ") : [];

    $trackingRestaurants = [];
    foreach ($restaurants as $row) {
        $isOpen = (int)($row['is_open'] ?? 1) === 1 && ($row['vendor_status'] ?? '') === 'active' && (int)($row['vendor_is_verified'] ?? 0) === 1;
        $trackingRestaurants[] = [
            'title' => (string)($row['restaurant_name'] ?? ''),
            'subtitle' => 'طلبات نشطة ' . (int)($row['active_orders'] ?? 0),
            'note' => $isOpen ? 'جاهز' : 'متوقف',
            'status_label' => $isOpen ? 'مفتوح' : 'مغلق',
            'status_color_hex' => $isOpen ? '#1E7D3F' : '#D92C2C',
            'icon_key' => 'store',
            'icon_color_hex' => $isOpen ? '#1E7D3F' : '#D92C2C',
            'background_hex' => $isOpen ? '#EAF5ED' : '#FDEEEF',
        ];

        $activityFeed[] = [
            'time_label' => date('H:i:s'),
            'relative_label' => 'اليوم',
            'title' => 'تحديث حالة مطعم',
            'subtitle' => $isOpen ? 'المطعم مفتوح' : 'المطعم مغلق',
            'detail' => (string)($row['restaurant_name'] ?? 'مطعم'),
            'pill_label' => 'عرض المطعم',
            'icon_key' => 'store',
            'accent_hex' => $isOpen ? '#1E7D3F' : '#D92C2C',
            'background_hex' => $isOpen ? '#EAF5ED' : '#FDEEEF',
        ];

        $restaurantMapMarker = opMapMarker(
            'restaurant',
            (string)($row['restaurant_name'] ?? ''),
            $row['latitude'] ?? null,
            $row['longitude'] ?? null,
            'store',
            $isOpen ? '#1E7D3F' : '#D92C2C',
            'Active orders ' . (int)($row['active_orders'] ?? 0),
            (int)($row['vendor_id'] ?? 0)
        );
        if ($restaurantMapMarker !== null) {
            $mapMarkers[] = $restaurantMapMarker;
        }
    }

    if (count($mapMarkers) < 3 && $driversAvailable) {
        $fallbackDrivers = opRows("
            SELECT
                id,
                COALESCE(name, CONCAT('Driver #', id)) AS driver_name,
                status,
                latitude,
                longitude,
                last_seen_at
            FROM delivery_users
            WHERE latitude IS NOT NULL AND longitude IS NOT NULL
            ORDER BY last_seen_at DESC, id DESC
            LIMIT 80
        ");
        foreach ($fallbackDrivers as $row) {
            $isOnline = strtolower((string)($row['status'] ?? '')) === 'online';
            $marker = opMapMarker(
                'driver',
                (string)($row['driver_name'] ?? 'Driver'),
                $row['latitude'] ?? null,
                $row['longitude'] ?? null,
                'delivery',
                $isOnline ? '#1E7D3F' : '#D92C2C',
                $isOnline ? 'Online' : opRelative($row['last_seen_at'] ?? null),
                (int)($row['id'] ?? 0)
            );
            if ($marker !== null) {
                $mapMarkers[] = $marker;
            }
        }
    }

    if (count($mapMarkers) < 12 && $vendorsAvailable) {
        $fallbackRestaurants = opRows("
            SELECT
                v.vendor_id,
                COALESCE(NULLIF(v.store_name, ''), NULLIF(s.store_name, ''), NULLIF(v.vendor_name, ''), 'غير محدد') AS restaurant_name,
                v.vendor_status,
                COALESCE(s.is_open, 1) AS is_open,
                s.store_latitude,
                s.store_longitude
            FROM vendors v
            LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
            WHERE s.store_latitude IS NOT NULL AND s.store_longitude IS NOT NULL
            ORDER BY v.vendor_id DESC
            LIMIT 80
        ");
        foreach ($fallbackRestaurants as $row) {
            $isOpen = (int)($row['is_open'] ?? 1) === 1 && strtolower((string)($row['vendor_status'] ?? '')) === 'active';
            $marker = opMapMarker(
                'restaurant',
                (string)($row['restaurant_name'] ?? 'Restaurant'),
                $row['store_latitude'] ?? null,
                $row['store_longitude'] ?? null,
                'store',
                $isOpen ? '#F59E0B' : '#D92C2C',
                $isOpen ? 'Open' : (string)($row['vendor_status'] ?? ''),
                (int)($row['vendor_id'] ?? 0)
            );
            if ($marker !== null) {
                $mapMarkers[] = $marker;
            }
        }
    }

    $activityStats = [
        opStatCard('إجمالي الأنشطة الآن', $activityTotal, 'activity', '#1A8B4A', '#EAF5ED', 'من قاعدة البيانات', '+' . $activityTotal, 'نشاط', true),
        opStatCard('تغييرات الطلبات', $orderCounts['active'], 'orders', '#2563EB', '#EAF1FF', 'طلبات نشطة', '+' . $orderCounts['active'], 'تغيير', true),
        opStatCard('نشاط المطاعم', $vendorCounts['open'], 'store', '#F59E0B', '#FFF4E4', 'مطاعم مفتوحة', '+' . $vendorCounts['open'], 'حركة', true),
        opStatCard('نشاط السائقين', $driverCounts['online'], 'delivery', '#7C3AED', '#F1ECFF', 'سائقون متصلون', '+' . $driverCounts['online'], 'حركة', true),
        opStatCard('العمليات المالية', $financeCounts['entries_today'], 'finance', '#1E7D3F', '#EAF5ED', 'اليوم', '+' . $financeCounts['entries_today'], 'عملية', true),
        opStatCard('التحذيرات الحرجة', $orderCounts['late'] + $vendorCounts['suspended'], 'warning', '#D92C2C', '#FDEEEF', 'تحتاج متابعة', (string)($orderCounts['late'] + $vendorCounts['suspended']), 'تنبيه', false),
    ];

    $avgAcceptMinutes = $ordersAvailable ? (float)opScalar("
        SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, orders_datetime, accepted_at)), 0)
        FROM orders
        WHERE accepted_at IS NOT NULL AND DATE(orders_datetime)=CURDATE()
    ") : 0;
    $avgPreparingMinutes = $ordersAvailable ? (float)opScalar("
        SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, accepted_at, picked_up_at)), 0)
        FROM orders
        WHERE accepted_at IS NOT NULL AND picked_up_at IS NOT NULL AND DATE(orders_datetime)=CURDATE()
    ") : 0;
    $avgDeliveryMinutes = $ordersAvailable ? (float)opScalar("
        SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, picked_up_at, delivered_at)), 0)
        FROM orders
        WHERE picked_up_at IS NOT NULL AND delivered_at IS NOT NULL AND DATE(orders_datetime)=CURDATE()
    ") : 0;

    $performanceCards = [
        opStatCard('متوسط وقت قبول الطلب', opNumber($avgAcceptMinutes, 0), 'time', '#1E7D3F', '#EAF5ED', 'دقيقة', '', 'من قاعدة البيانات', true),
        opStatCard('متوسط وقت التحضير', opNumber($avgPreparingMinutes, 0), 'kitchen', '#D92C2C', '#FDEEEF', 'دقيقة', '', 'من قاعدة البيانات', false),
        opStatCard('متوسط وقت التوصيل', opNumber($avgDeliveryMinutes, 0), 'truck', '#7C3AED', '#F1ECFF', 'دقيقة', '', 'من قاعدة البيانات', false),
    ];

    $alertCards = [
        opStatCard('طلبات متأخرة', $orderCounts['late'], 'time', '#D92C2C', '#FDEEEF', 'عرض التفاصيل', '', '', false),
        opStatCard('مطاعم تحتاج مراجعة', $vendorCounts['pending'], 'store', '#F59E0B', '#FFF4E4', 'عرض التفاصيل', '', '', false),
        opStatCard('سائقون غير متاحين', $driverCounts['offline'], 'delivery', '#D92C2C', '#FDEEEF', 'عرض التفاصيل', '', '', false),
        opStatCard('شكاوى جديدة', $supportCount, 'warning', '#7C3AED', '#F1ECFF', 'عرض التفاصيل', '', '', false),
        opStatCard('رسائل غير مقروءة', $notificationsUnread, 'communication', '#2563EB', '#EAF1FF', 'عرض التفاصيل', '', '', false),
        opStatCard('تنبيهات حرجة', $orderCounts['canceled_today'] + $vendorCounts['suspended'], 'warning', '#D92C2C', '#FDEEEF', 'عرض التفاصيل', '', '', false),
    ];

    $summaryGroups = [
        [
            'title' => 'الطلبات',
            'header_accent_hex' => '#1A8B4A',
            'items' => [
                ['label' => 'جديد', 'value' => (string)$orderCounts['new'], 'icon_key' => 'add', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'],
                ['label' => 'قيد التحضير', 'value' => (string)$orderCounts['preparing'], 'icon_key' => 'kitchen', 'accent_hex' => '#F59E0B', 'background_hex' => '#FFF4E4'],
                ['label' => 'جاهز للاستلام', 'value' => (string)$orderCounts['ready'], 'icon_key' => 'delivery', 'accent_hex' => '#2563EB', 'background_hex' => '#EAF1FF'],
                ['label' => 'مكتمل اليوم', 'value' => (string)$orderCounts['completed_today'], 'icon_key' => 'check', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'],
                ['label' => 'ملغي اليوم', 'value' => (string)$orderCounts['canceled_today'], 'icon_key' => 'cancel', 'accent_hex' => '#D92C2C', 'background_hex' => '#FDEEEF', 'value_color_hex' => '#D92C2C'],
            ],
        ],
        [
            'title' => 'المطاعم',
            'header_accent_hex' => '#F59E0B',
            'items' => [
                ['label' => 'مفتوح', 'value' => (string)$vendorCounts['open'], 'icon_key' => 'store', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'],
                ['label' => 'قيد المراجعة', 'value' => (string)$vendorCounts['pending'], 'icon_key' => 'hourglass', 'accent_hex' => '#F59E0B', 'background_hex' => '#FFF4E4'],
                ['label' => 'معطل', 'value' => (string)$vendorCounts['suspended'], 'icon_key' => 'block', 'accent_hex' => '#D92C2C', 'background_hex' => '#FDEEEF', 'value_color_hex' => '#D92C2C'],
            ],
        ],
        [
            'title' => 'السائقون',
            'header_accent_hex' => '#2563EB',
            'items' => [
                ['label' => 'متاح', 'value' => (string)$driverCounts['available'], 'icon_key' => 'delivery', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'],
                ['label' => 'مشغول', 'value' => (string)$driverCounts['busy'], 'icon_key' => 'truck', 'accent_hex' => '#2563EB', 'background_hex' => '#EAF1FF'],
                ['label' => 'متوقف', 'value' => (string)$driverCounts['offline'], 'icon_key' => 'pause', 'accent_hex' => '#D92C2C', 'background_hex' => '#FDEEEF', 'value_color_hex' => '#D92C2C'],
            ],
        ],
        [
            'title' => 'المالية',
            'header_accent_hex' => '#7C3AED',
            'items' => [
                ['label' => 'دفعات', 'value' => (string)$financeCounts['entries_today'], 'icon_key' => 'payments', 'accent_hex' => '#7C3AED', 'background_hex' => '#F1ECFF'],
                ['label' => 'استردادات', 'value' => (string)$financeCounts['refunds_today'], 'icon_key' => 'refund', 'accent_hex' => '#F59E0B', 'background_hex' => '#FFF4E4'],
            ],
        ],
    ];

    $events = [];
    foreach (array_slice($orders, 0, 6) as $row) {
        $status = (string)($row['live_status'] ?: $row['orders_status'] ?: '');
        $events[] = [
            'title' => in_array(strtolower($status), ['canceled', 'cancelled', 'failed'], true) ? 'طلب حساس' : 'تحديث طلب',
            'reference' => '#' . (int)($row['orders_id'] ?? 0),
            'role' => 'نظام الطلبات',
            'time_label' => opRelative($row['orders_datetime'] ?? null),
            'note' => opStatusLabel($status),
            'icon_key' => in_array(strtolower($status), ['canceled', 'cancelled', 'failed'], true) ? 'warning' : 'orders',
            'accent_hex' => opStatusColor($status),
            'background_hex' => opStatusColor($status) === '#D92C2C' ? '#FDEEEF' : '#EAF5ED',
            'button_label' => 'عرض السجل',
        ];
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => (new DateTimeImmutable('now'))->format(DateTimeInterface::ATOM),
            'badges' => [
                'notifications' => $notificationsUnread,
                'messages' => $supportCount,
                'alerts' => $orderCounts['late'] + $vendorCounts['suspended'] + $orderCounts['canceled_today'],
            ],
            'overview' => [
                'stat_cards' => $overviewCards,
                'live_items' => array_slice($activityFeed, 0, 6),
                'map_markers' => array_slice($mapMarkers, 0, 80),
                'performance_cards' => $performanceCards,
                'alert_cards' => $alertCards,
            ],
            'tracking' => [
                'orders' => $trackingOrders,
                'drivers' => $trackingDrivers,
                'restaurants' => $trackingRestaurants,
                'map_markers' => array_slice($mapMarkers, 0, 120),
                'routes' => array_slice($trackingRoutes, 0, 80),
                'moment_metrics' => [
                    ['label' => 'معدل الالتزام', 'value' => $orderCounts['active'] > 0 ? opNumber(($orderCounts['completed_today'] / max(1, $orderCounts['completed_today'] + $orderCounts['late'])) * 100) . '%' : '0%', 'progress' => $orderCounts['active'] > 0 ? min(1, ($orderCounts['completed_today'] / max(1, $orderCounts['completed_today'] + $orderCounts['late']))) : 0, 'color_hex' => '#1E7D3F', 'background_hex' => '#E7F4EA'],
                    ['label' => 'سائقون متاحون', 'value' => (string)$driverCounts['available'], 'progress' => $driverCounts['total'] > 0 ? min(1, $driverCounts['available'] / $driverCounts['total']) : 0, 'color_hex' => '#0F766E', 'background_hex' => '#DFF7F2'],
                    ['label' => 'نسبة التوصيل', 'value' => $orderCounts['completed_today'] . '/' . max(1, $orderCounts['new']), 'progress' => $orderCounts['new'] > 0 ? min(1, $orderCounts['completed_today'] / $orderCounts['new']) : 0, 'color_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'],
                    ['label' => 'طلبات متأخرة', 'value' => (string)$orderCounts['late'], 'progress' => $orderCounts['active'] > 0 ? min(1, $orderCounts['late'] / $orderCounts['active']) : 0, 'color_hex' => '#D92C2C', 'background_hex' => '#FDEEEF'],
                ],
                'live_stats' => [
                    ['label' => 'طلبات نشطة الآن', 'value' => (string)$orderCounts['active'], 'icon_key' => 'location', 'color_hex' => '#2563EB', 'background_hex' => '#EAF1FF'],
                    ['label' => 'سائقين على المنصة', 'value' => (string)$driverCounts['online'], 'icon_key' => 'delivery', 'color_hex' => '#1E7D3F', 'background_hex' => '#EAF5ED'],
                    ['label' => 'مطاعم مفتوحة', 'value' => (string)$vendorCounts['open'], 'icon_key' => 'store', 'color_hex' => '#F59E0B', 'background_hex' => '#FFF4E4'],
                    ['label' => 'آخر تحديث', 'value' => date('H:i:s'), 'icon_key' => 'time', 'color_hex' => '#4E5660', 'background_hex' => '#F3F5F4'],
                ],
                'pressure_areas' => [],
                'shortage_areas' => [],
            ],
            'activity' => [
                'stats' => $activityStats,
                'summary_groups' => $summaryGroups,
                'feed_items' => $activityFeed,
                'event_items' => $events,
                'footer_status_items' => [
                    ['label' => 'قاعدة البيانات', 'is_healthy' => true, 'dot_hex' => '#1A8B4A'],
                    ['label' => 'خدمة الطلبات', 'is_healthy' => $ordersAvailable, 'dot_hex' => $ordersAvailable ? '#1A8B4A' : '#D92C2C'],
                    ['label' => 'خدمة التنبيهات', 'is_healthy' => $notificationsAvailable, 'dot_hex' => $notificationsAvailable ? '#1A8B4A' : '#D92C2C'],
                    ['label' => 'خدمة الخرائط', 'is_healthy' => $vendorsAvailable, 'dot_hex' => $vendorsAvailable ? '#1A8B4A' : '#D92C2C'],
                ],
            ],
            'data_quality' => empty($operationsQueryFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($operationsQueryFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
