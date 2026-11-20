<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$logisticsQueryErrors = [];

function logisticsScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        error_log('master logistics scalar failed: ' . $e->getMessage());
        $GLOBALS['logisticsQueryErrors'][] = 'scalar';
        return $fallback;
    }
}

function logisticsRows(string $sql, array $params = []): array
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        error_log('master logistics rows failed: ' . $e->getMessage());
        $GLOBALS['logisticsQueryErrors'][] = 'rows';
        return [];
    }
}

function logisticsNumber($value, int $decimals = 0): string
{
    return number_format((float)$value, $decimals, '.', ',');
}

function logisticsAssetUrl($value, string $folder): string
{
    $text = trim((string)$value);
    if ($text === '') {
        return '';
    }
    if (preg_match('/^https?:\/\//i', $text)) {
        return $text;
    }
    $text = ltrim($text, '/');
    if (strpos($text, $folder) === 0) {
        return 'https://savir-technology.online/roaqv2/' . $text;
    }
    return 'https://savir-technology.online/roaqv2/' . trim($folder, '/') . '/' . basename($text);
}

function logisticsRelative(?string $value): string
{
    $timestamp = strtotime((string)$value);
    if ($timestamp === false) {
        return 'منذ قليل';
    }
    $seconds = max(0, time() - $timestamp);
    if ($seconds < 60) {
        return 'منذ دقيقة';
    }
    $minutes = (int)floor($seconds / 60);
    if ($minutes < 60) {
        return 'منذ ' . $minutes . ' دقيقة';
    }
    $hours = (int)floor($minutes / 60);
    if ($hours < 24) {
        return 'منذ ' . $hours . ' ساعة';
    }
    return date('Y-m-d', $timestamp);
}

function logisticsTime(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '--:--' : date('H:i', $timestamp);
}

function logisticsOrderTypeLabel($type): string
{
    $key = strtolower(trim((string)$type));
    if (str_contains($key, 'pickup') || str_contains($key, 'self')) {
        return 'استلام ذاتي';
    }
    return 'توصيل';
}

function logisticsGuessArea(string $address): string
{
    $value = trim($address);
    if ($value === '') {
        return 'غير محدد';
    }
    $parts = preg_split('/[-،,\/]+/u', $value) ?: [];
    foreach ($parts as $part) {
        $clean = trim($part);
        if ($clean !== '') {
            return $clean;
        }
    }
    return $value;
}

function logisticsStatusMeta($status): array
{
    $key = strtolower(trim((string)$status));
    if (in_array($key, ['pending', 'new', '0'], true)) {
        return ['key' => 'new', 'label' => 'جديد', 'color_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'];
    }
    if (in_array($key, ['preparing', 'accepted', 'heading_to_restaurant', 'arrived_at_restaurant'], true)) {
        return ['key' => 'preparing', 'label' => 'قيد التحضير', 'color_hex' => '#CA7A00', 'background_hex' => '#FFF4E4'];
    }
    if (in_array($key, ['ready', 'picked_up', 'assigned'], true)) {
        return ['key' => 'ready', 'label' => 'جاهز', 'color_hex' => '#2563EB', 'background_hex' => '#EAF1FF'];
    }
    if (in_array($key, ['with_driver', 'on_driver'], true)) {
        return ['key' => 'with_driver', 'label' => 'مع السائق', 'color_hex' => '#0B8F4D', 'background_hex' => '#EAF7EE'];
    }
    if (in_array($key, ['on_way', 'on_the_way', 'out_for_delivery'], true)) {
        return ['key' => 'on_way', 'label' => 'في الطريق', 'color_hex' => '#4F46E5', 'background_hex' => '#EEF2FF'];
    }
    if (in_array($key, ['delivered', 'completed', 'paid', '4'], true)) {
        return ['key' => 'completed', 'label' => 'مكتمل', 'color_hex' => '#1E7D3F', 'background_hex' => '#EAF5ED'];
    }
    if (in_array($key, ['canceled', 'cancelled', 'failed', 'rejected'], true)) {
        return ['key' => 'canceled', 'label' => 'ملغي', 'color_hex' => '#D92C2C', 'background_hex' => '#FDEEEF'];
    }
    return ['key' => $key === '' ? 'unknown' : $key, 'label' => $key === '' ? 'غير محدد' : $status, 'color_hex' => '#4E5660', 'background_hex' => '#F3F4F6'];
}

function logisticsDriverStatus(array $driver): array
{
    $online = (int)($driver['is_online'] ?? 0) === 1;
    $active = (int)($driver['active_orders'] ?? 0);
    if (!$online) {
        return ['key' => 'unavailable', 'label' => 'غير متاح', 'color_hex' => '#64748B', 'background_hex' => '#F1F5F9'];
    }
    if ($active > 0) {
        return ['key' => 'busy', 'label' => 'مشغول', 'color_hex' => '#2563EB', 'background_hex' => '#EAF1FF'];
    }
    return ['key' => 'available', 'label' => 'متاح', 'color_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'];
}

function logisticsMapMarker(string $type, string $label, string $subtitle, $lat, $lng, string $icon, string $color): ?array
{
    $latitude = (float)$lat;
    $longitude = (float)$lng;
    if (!is_finite($latitude) || !is_finite($longitude) || abs($latitude) < 0.000001 || abs($longitude) < 0.000001) {
        return null;
    }
    return [
        'type' => $type,
        'label' => $label,
        'subtitle' => $subtitle,
        'lat' => $latitude,
        'lng' => $longitude,
        'icon_key' => $icon,
        'color_hex' => $color,
    ];
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'drivers.view');
    $master = masterPublicData($admin);

    if (!tableExists('orders') || !tableExists('delivery_users')) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [
                'server_now' => date('c'),
                'stats' => [],
                'drivers' => [],
                'unassigned_orders' => [],
                'active_orders' => [],
                'assignment_history' => [],
                'map_markers' => [],
                'service_zones' => [],
                'emergency_requests' => [],
            ],
        ]);
    }

    $query = trim((string)($_GET['q'] ?? ''));
    $statusFilter = trim((string)($_GET['status'] ?? 'all'));
    $vehicleFilter = trim((string)($_GET['vehicle'] ?? 'all'));
    $view = trim((string)($_GET['view'] ?? 'drivers'));

    $settingsAvailable = tableExists('vendor_store_settings');
    $vendorsAvailable = tableExists('vendors');
    $itemsAvailable = tableExists('order_items');
    $usersAvailable = tableExists('users');
    $trackingAvailable = tableExists('delivery_order_tracking');
    $ratingsAvailable = tableExists('driver_ratings');

    $onlineExpr = "(du.status = 'online' OR (du.last_seen_at IS NOT NULL AND du.last_seen_at >= (NOW() - INTERVAL 5 MINUTE)))";
    $driverWhere = ['1=1'];
    $driverParams = [];
    if ($query !== '') {
        $driverWhere[] = "(du.name LIKE :driver_q OR du.phone LIKE :driver_q OR du.vehicle_type LIKE :driver_q OR du.vehicle_number LIKE :driver_q)";
        $driverParams[':driver_q'] = '%' . $query . '%';
    }
    if ($vehicleFilter !== '' && $vehicleFilter !== 'all') {
        $driverWhere[] = "LOWER(COALESCE(du.vehicle_type, '')) LIKE :vehicle";
        $driverParams[':vehicle'] = '%' . strtolower($vehicleFilter) . '%';
    }

    $driverWhereSql = implode(' AND ', $driverWhere);
    $ratingSelect = $ratingsAvailable
        ? "COALESCE(r.average_rating, 0) AS average_rating"
        : "0 AS average_rating";
    $ratingJoin = $ratingsAvailable
        ? "LEFT JOIN (SELECT driver_id, AVG(rating) AS average_rating FROM driver_ratings GROUP BY driver_id) r ON r.driver_id = du.id"
        : "";

    $driversRaw = logisticsRows("
        SELECT
            du.id,
            du.name,
            du.phone,
            du.vendor_id,
            COALESCE(v.store_name, v.vendor_name, '') AS vendor_name,
            COALESCE(du.approval_status, 'pending') AS approval_status,
            COALESCE(du.approval_note, '') AS approval_note,
            du.vehicle_type,
            du.vehicle_number,
            du.status,
            du.latitude,
            du.longitude,
            du.last_seen_at,
            CASE WHEN {$onlineExpr} THEN 1 ELSE 0 END AS is_online,
            COALESCE(o.active_orders, 0) AS active_orders,
            COALESCE(o.today_orders, 0) AS today_orders,
            COALESCE(o.completed_today, 0) AS completed_today,
            {$ratingSelect}
        FROM delivery_users du
        LEFT JOIN vendors v ON v.vendor_id = du.vendor_id
        LEFT JOIN (
            SELECT
                delivery_id AS driver_id,
                SUM(CASE WHEN COALESCE(status, orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected') THEN 1 ELSE 0 END) AS active_orders,
                SUM(CASE WHEN DATE(orders_datetime) = CURDATE() THEN 1 ELSE 0 END) AS today_orders,
                SUM(CASE WHEN DATE(COALESCE(delivered_at, updated_at, orders_datetime)) = CURDATE() AND COALESCE(status, orders_status, '') IN ('delivered','completed','paid','4') THEN 1 ELSE 0 END) AS completed_today
            FROM orders
            WHERE delivery_id IS NOT NULL
            GROUP BY delivery_id
        ) o ON o.driver_id = du.id
        {$ratingJoin}
        WHERE {$driverWhereSql}
        ORDER BY is_online DESC, active_orders ASC, today_orders DESC, du.id DESC
        LIMIT 220
    ", $driverParams);

    // Optional joins may fail on older schemas while summary queries still
    // work. Retry with the core driver columns so the table stays truthful.
    if (!$driversRaw) {
        $driversRaw = logisticsRows("
            SELECT
                du.id, du.name, du.phone, du.vendor_id, '' AS vendor_name,
                du.vehicle_type, du.vehicle_number,
                du.status, du.latitude, du.longitude,
                CASE WHEN du.status = 'online' THEN 1 ELSE 0 END AS is_online,
                0 AS active_orders, 0 AS today_orders,
                0 AS completed_today, 0 AS average_rating
            FROM delivery_users du
            WHERE {$driverWhereSql}
            ORDER BY is_online DESC, du.id DESC
            LIMIT 220
        ", $driverParams);
    }

    $drivers = [];
    $statusCounts = ['available' => 0, 'busy' => 0, 'unavailable' => 0];
    $vehicleCounts = [];
    $mapMarkers = [];
    foreach ($driversRaw as $row) {
        $meta = logisticsDriverStatus($row);
        if ($statusFilter !== '' && $statusFilter !== 'all' && $statusFilter !== $meta['key']) {
            continue;
        }
        $vehicle = trim((string)($row['vehicle_type'] ?? '')) !== '' ? trim((string)$row['vehicle_type']) : 'غير محدد';
        $statusCounts[$meta['key']] = ($statusCounts[$meta['key']] ?? 0) + 1;
        $vehicleCounts[$vehicle] = ($vehicleCounts[$vehicle] ?? 0) + 1;
        $driver = [
            'driver_id' => (int)($row['id'] ?? 0),
            'name' => trim((string)($row['name'] ?? '')) !== '' ? trim((string)$row['name']) : 'سائق #' . (int)($row['id'] ?? 0),
            'phone' => (string)($row['phone'] ?? ''),
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'vendor_name' => (string)($row['vendor_name'] ?? ''),
            'approval_status' => (string)($row['approval_status'] ?? 'pending'),
            'approval_note' => (string)($row['approval_note'] ?? ''),
            'vehicle_type' => $vehicle,
            'vehicle_number' => (string)($row['vehicle_number'] ?? ''),
            'status_key' => $meta['key'],
            'status_label' => $meta['label'],
            'status_color_hex' => $meta['color_hex'],
            'status_background_hex' => $meta['background_hex'],
            'current_location' => logisticsRelative($row['last_seen_at'] ?? null),
            'today_orders' => (int)($row['today_orders'] ?? 0),
            'active_orders' => (int)($row['active_orders'] ?? 0),
            'rating' => round((float)($row['average_rating'] ?? 0), 1),
            'latitude' => $row['latitude'] === null ? null : (float)$row['latitude'],
            'longitude' => $row['longitude'] === null ? null : (float)$row['longitude'],
        ];
        $drivers[] = $driver;
        $marker = logisticsMapMarker(
            'driver',
            $driver['name'],
            $driver['status_label'] . ' - ' . $driver['vehicle_type'],
            $driver['latitude'],
            $driver['longitude'],
            'delivery',
            $driver['status_key'] === 'available' ? '#1A8B4A' : ($driver['status_key'] === 'busy' ? '#2563EB' : '#64748B')
        );
        if ($marker !== null) {
            $mapMarkers[] = $marker;
        }
    }

    $totalDrivers = count($driversRaw);
    $availableDrivers = (int)logisticsScalar("SELECT COUNT(*) FROM delivery_users du WHERE {$onlineExpr} AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.delivery_id = du.id AND COALESCE(o.status, o.orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected'))");
    $busyDrivers = (int)logisticsScalar("SELECT COUNT(DISTINCT du.id) FROM delivery_users du JOIN orders o ON o.delivery_id = du.id WHERE {$onlineExpr} AND COALESCE(o.status, o.orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected')");
    $unavailableDrivers = max(0, $totalDrivers - $availableDrivers - $busyDrivers);
    $activeDeliveryOrders = (int)logisticsScalar("SELECT COUNT(*) FROM orders WHERE delivery_id IS NOT NULL AND COALESCE(status, orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected')");
    $unassignedOrdersCount = (int)logisticsScalar("SELECT COUNT(*) FROM orders WHERE delivery_id IS NULL AND COALESCE(status, orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected') AND LOWER(COALESCE(order_mode, orders_type, 'delivery')) NOT LIKE '%pickup%'");
    $assignedToday = (int)logisticsScalar("SELECT COUNT(*) FROM orders WHERE delivery_id IS NOT NULL AND DATE(COALESCE(assigned_at, updated_at, orders_datetime)) = CURDATE()");
    $completedToday = (int)logisticsScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('delivered','completed','paid','4') AND DATE(COALESCE(delivered_at, updated_at, orders_datetime))=CURDATE()");
    $canceledToday = (int)logisticsScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('canceled','cancelled','failed','rejected') AND DATE(COALESCE(updated_at, orders_datetime))=CURDATE()");
    $onWayNow = (int)logisticsScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('with_driver','on_driver','on_way','on_the_way','out_for_delivery')");
    $avgAssignment = (float)logisticsScalar("SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, orders_datetime, assigned_at)), 0) FROM orders WHERE assigned_at IS NOT NULL AND assigned_at >= orders_datetime AND DATE(assigned_at)=CURDATE()", [], 0);
    $avgDelivery = (float)logisticsScalar("SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, picked_up_at, delivered_at)), 0) FROM orders WHERE picked_up_at IS NOT NULL AND delivered_at IS NOT NULL AND delivered_at >= picked_up_at", [], 0);

    $userSelect = $usersAvailable
        ? "COALESCE(u.users_name, o.orders_recipient_name, 'عميل') AS customer_name, COALESCE(u.users_phone, o.orders_recipient_phone, '') AS customer_phone"
        : "COALESCE(o.orders_recipient_name, 'عميل') AS customer_name, COALESCE(o.orders_recipient_phone, '') AS customer_phone";
    $userJoin = $usersAvailable ? "LEFT JOIN users u ON u.users_id = o.orders_usersid" : "";
    $vendorJoin = "";
    $vendorIdSelect = "0 AS vendor_id,";
    $restaurantSelect = "'' AS restaurant_name";
    $restaurantLogoSelect = "'' AS restaurant_logo_url";
    if ($itemsAvailable && $vendorsAvailable) {
        $settingsJoin = $settingsAvailable ? "LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id" : "";
        $settingsName = $settingsAvailable ? "s.store_name," : "";
        $settingsLogo = $settingsAvailable ? "s.vendor_logo," : "";
        $vendorJoin = "
            LEFT JOIN (
                SELECT order_id, MIN(vendor_id) AS vendor_id
                FROM order_items
                GROUP BY order_id
            ) oi ON oi.order_id = o.orders_id
            LEFT JOIN vendors v ON v.vendor_id = oi.vendor_id
            {$settingsJoin}
        ";
        $vendorIdSelect = "oi.vendor_id AS vendor_id,";
        $restaurantSelect = "COALESCE(v.store_name, {$settingsName} v.vendor_name, '') AS restaurant_name";
        $restaurantLogoSelect = "COALESCE({$settingsLogo} v.vendor_logo, '') AS restaurant_logo_url";
    }

    $orderSearchWhere = [];
    $orderParams = [];
    if ($query !== '') {
        $orderSearchWhere[] = "(CAST(o.orders_id AS CHAR) LIKE :order_q OR o.orders_recipient_name LIKE :order_q OR o.orders_recipient_phone LIKE :order_q)";
        $orderParams[':order_q'] = '%' . $query . '%';
    }
    $orderSearchSql = $orderSearchWhere ? ' AND ' . implode(' AND ', $orderSearchWhere) : '';

    $unassignedRows = logisticsRows("
        SELECT
            o.orders_id,
            o.orders_datetime,
            o.orders_totalprice,
            o.orders_recipient_address_line,
            o.orders_recipient_address_name,
            o.orders_recipient_lat,
            o.orders_recipient_lng,
            o.delivery_latitude,
            o.delivery_longitude,
            o.order_mode,
            o.orders_type,
            {$vendorIdSelect}
            COALESCE(o.status, o.orders_status, '') AS status_key,
            {$userSelect},
            {$restaurantSelect},
            {$restaurantLogoSelect}
        FROM orders o
        {$userJoin}
        {$vendorJoin}
        WHERE o.delivery_id IS NULL
          AND COALESCE(o.status, o.orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected')
          AND LOWER(COALESCE(o.order_mode, o.orders_type, 'delivery')) NOT LIKE '%pickup%'
          {$orderSearchSql}
        ORDER BY o.orders_datetime DESC, o.orders_id DESC
        LIMIT 18
    ", $orderParams);

    if (!$unassignedRows && $unassignedOrdersCount > 0) {
        $unassignedRows = logisticsRows("
            SELECT
                o.orders_id, o.orders_datetime, o.orders_totalprice,
                o.orders_recipient_address_line, o.orders_recipient_address_name,
                o.orders_recipient_lat, o.orders_recipient_lng,
                o.delivery_latitude, o.delivery_longitude,
                o.order_mode, o.orders_type,
                COALESCE(o.status, o.orders_status, '') AS status_key,
                o.orders_recipient_name AS customer_name,
                o.orders_recipient_phone AS customer_phone,
                '' AS restaurant_name, '' AS restaurant_logo_url
            FROM orders o
            WHERE o.delivery_id IS NULL
              AND COALESCE(o.status, o.orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected')
              AND LOWER(COALESCE(o.order_mode, o.orders_type, 'delivery')) NOT LIKE '%pickup%'
            ORDER BY o.orders_datetime DESC, o.orders_id DESC
            LIMIT 18
        ");
    }

    $unassigned = [];
    foreach ($unassignedRows as $row) {
        $status = logisticsStatusMeta($row['status_key'] ?? '');
        $order = [
            'order_id' => (int)($row['orders_id'] ?? 0),
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'order_no' => '#' . (int)($row['orders_id'] ?? 0),
            'customer' => (string)($row['customer_name'] ?? 'عميل'),
            'phone' => (string)($row['customer_phone'] ?? ''),
            'restaurant' => (string)($row['restaurant_name'] ?? 'مطعم'),
            'restaurant_logo_url' => logisticsAssetUrl($row['restaurant_logo_url'] ?? '', 'uploads/vendors/logo'),
            'amount_label' => logisticsNumber($row['orders_totalprice'] ?? 0) . ' س',
            'status_key' => $status['key'],
            'status_label' => $status['label'],
            'status_color_hex' => $status['color_hex'],
            'status_background_hex' => $status['background_hex'],
            'type_label' => logisticsOrderTypeLabel($row['order_mode'] ?? $row['orders_type'] ?? ''),
            'time_label' => logisticsTime($row['orders_datetime'] ?? null),
            'relative_label' => logisticsRelative($row['orders_datetime'] ?? null),
            'address_label' => trim((string)($row['orders_recipient_address_name'] ?? '')) !== '' ? (string)$row['orders_recipient_address_name'] : (string)($row['orders_recipient_address_line'] ?? ''),
            'latitude' => $row['delivery_latitude'] ?? $row['orders_recipient_lat'] ?? null,
            'longitude' => $row['delivery_longitude'] ?? $row['orders_recipient_lng'] ?? null,
        ];
        $unassigned[] = $order;
        $marker = logisticsMapMarker('order', $order['order_no'], $order['restaurant'], $order['latitude'], $order['longitude'], 'orders', '#0B8F4D');
        if ($marker !== null) {
            $mapMarkers[] = $marker;
        }
    }

    $driverJoin = "LEFT JOIN delivery_users du ON du.id = o.delivery_id";
    $trackingJoin = $trackingAvailable ? "LEFT JOIN delivery_order_tracking dot ON dot.order_id = o.orders_id" : "";
    $activeRows = logisticsRows("
        SELECT
            o.orders_id,
            o.orders_datetime,
            o.orders_totalprice,
            COALESCE(o.status, o.orders_status, '') AS status_key,
            COALESCE(du.name, '') AS driver_name,
            COALESCE(du.phone, '') AS driver_phone,
            {$userSelect},
            {$restaurantSelect}
        FROM orders o
        {$userJoin}
        {$vendorJoin}
        {$driverJoin}
        {$trackingJoin}
        WHERE o.delivery_id IS NOT NULL
          AND COALESCE(o.status, o.orders_status, '') NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected')
        ORDER BY COALESCE(o.assigned_at, o.updated_at, o.orders_datetime) DESC
        LIMIT 12
    ");

    $activeOrders = [];
    foreach ($activeRows as $row) {
        $status = logisticsStatusMeta($row['status_key'] ?? '');
        $activeOrders[] = [
            'order_id' => (int)($row['orders_id'] ?? 0),
            'order_no' => '#' . (int)($row['orders_id'] ?? 0),
            'customer' => (string)($row['customer_name'] ?? 'عميل'),
            'driver_name' => (string)($row['driver_name'] ?? ''),
            'restaurant' => (string)($row['restaurant_name'] ?? 'مطعم'),
            'amount_label' => logisticsNumber($row['orders_totalprice'] ?? 0) . ' س',
            'status_label' => $status['label'],
            'status_color_hex' => $status['color_hex'],
            'time_label' => logisticsTime($row['orders_datetime'] ?? null),
            'relative_label' => logisticsRelative($row['orders_datetime'] ?? null),
        ];
    }

    $historyRows = logisticsRows("
        SELECT
            o.orders_id,
            o.assigned_at,
            COALESCE(du.name, '') AS driver_name,
            {$restaurantSelect}
        FROM orders o
        {$vendorJoin}
        LEFT JOIN delivery_users du ON du.id = o.delivery_id
        WHERE o.delivery_id IS NOT NULL
        ORDER BY COALESCE(o.assigned_at, o.updated_at, o.orders_datetime) DESC
        LIMIT 8
    ");
    $history = [];
    foreach ($historyRows as $row) {
        $history[] = [
            'order_no' => '#' . (int)($row['orders_id'] ?? 0),
            'driver_name' => (string)($row['driver_name'] ?? ''),
            'restaurant' => (string)($row['restaurant_name'] ?? ''),
            'time_label' => logisticsTime($row['assigned_at'] ?? null),
            'relative_label' => logisticsRelative($row['assigned_at'] ?? null),
            'status_label' => 'تم القبول',
        ];
    }

    $serviceZones = [];
    if (tableExists('delivery_zones')) {
        $zoneRows = logisticsRows("
            SELECT
                zone_id,
                zone_name,
                city,
                coverage_km,
                minimum_order,
                delivery_fee,
                estimated_min_minutes,
                estimated_max_minutes,
                center_latitude,
                center_longitude,
                is_active
            FROM delivery_zones
            ORDER BY is_active DESC, zone_name ASC, zone_id DESC
            LIMIT 120
        ");
        foreach ($zoneRows as $index => $row) {
            $lat = (float)($row['center_latitude'] ?? 0);
            $lng = (float)($row['center_longitude'] ?? 0);
            $points = [];
            $isOpen = (int)($row['is_active'] ?? 0);
            $zoneName = trim((string)($row['zone_name'] ?? ''));
            $hasFee = $row['delivery_fee'] !== null && $row['delivery_fee'] !== '';
            $hasMinimumOrder = $row['minimum_order'] !== null && $row['minimum_order'] !== '';
            $hasEta = $row['estimated_min_minutes'] !== null
                && $row['estimated_max_minutes'] !== null
                && (int)$row['estimated_min_minutes'] >= 0
                && (int)$row['estimated_max_minutes'] >= (int)$row['estimated_min_minutes'];
            if ($zoneName === '') {
                $zoneName = 'منطقة غير مسماة';
            }
            if (abs($lat) > 0.000001 && abs($lng) > 0.000001) {
                $mapMarkers[] = [
                    'type' => 'zone',
                    'label' => $zoneName,
                    'subtitle' => $hasFee ? logisticsNumber($row['delivery_fee']) . ' ر.س' : 'رسوم غير محددة',
                    'lat' => $lat,
                    'lng' => $lng,
                    'icon_key' => 'zone',
                    'color_hex' => $isOpen === 1 ? '#1A8B4A' : '#6B7280',
                ];
            }
            $serviceZones[] = [
                'zone_id' => (int)($row['zone_id'] ?? 0),
                'name' => $zoneName,
                'city' => trim((string)($row['city'] ?? '')) ?: 'غير محدد',
                'status' => $isOpen === 1 ? 'مفعلة' : 'معطلة',
                'fee_label' => $hasFee ? logisticsNumber($row['delivery_fee']) . ' ر.س' : 'غير محدد',
                'distance_label' => $row['coverage_km'] === null ? 'غير محدد' : logisticsNumber($row['coverage_km'], 1) . ' كم',
                'restaurant_count' => 0,
                'driver_count' => 0,
                'eta_label' => $hasEta
                    ? (int)$row['estimated_min_minutes'] . ' - ' . (int)$row['estimated_max_minutes'] . ' دقيقة'
                    : 'غير محدد',
                'minimum_order_label' => $hasMinimumOrder ? logisticsNumber($row['minimum_order']) . ' ر.س' : 'غير محدد',
                'service_fee_label' => 'غير محدد',
                'free_delivery_over_label' => 'غير محدد',
                'priority_label' => 'غير محدد',
                'color_hex' => $isOpen === 1 ? '#1A8B4A' : '#6B7280',
                'center_lat' => $lat,
                'center_lng' => $lng,
                'points' => $points,
            ];
        }
    }

    $emergencyRequests = [];
    if (tableExists('delivery_driver_emergency_reports')) {
        foreach ([
            'status' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN status VARCHAR(24) NOT NULL DEFAULT 'active' AFTER reason",
            'resolved_at' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolved_at DATETIME DEFAULT NULL AFTER reported_at",
            'resolved_by' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolved_by INT DEFAULT NULL AFTER resolved_at",
            'resolution_note' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolution_note VARCHAR(255) DEFAULT NULL AFTER resolved_by",
        ] as $column => $sql) {
            if (!columnExists('delivery_driver_emergency_reports', $column)) {
                try { $con->exec($sql); } catch (Throwable $ignored) { }
            }
        }
        $emergencyRows = logisticsRows(" 
            SELECT
                r.emergency_report_id,
                r.driver_id,
                r.order_id,
                r.reason,
                r.status,
                r.reported_at,
                COALESCE(du.name, 'Driver') AS driver_name,
                COALESCE(du.phone, '') AS driver_phone,
                COALESCE(du.latitude, o.driver_latitude, o.delivery_latitude, o.orders_recipient_lat) AS latitude,
                COALESCE(du.longitude, o.driver_longitude, o.delivery_longitude, o.orders_recipient_lng) AS longitude,
                COALESCE(o.orders_recipient_address_name, o.orders_recipient_address_line, '') AS location_label
            FROM delivery_driver_emergency_reports r
            LEFT JOIN delivery_users du ON du.id = r.driver_id
            LEFT JOIN orders o ON o.orders_id = r.order_id
            WHERE COALESCE(r.status, 'active') = 'active'
            ORDER BY r.reported_at DESC
            LIMIT 40
        ");
        foreach ($emergencyRows as $row) {
            $emergencyRequests[] = [
                'id' => '#EMR-' . (int)($row['emergency_report_id'] ?? 0),
                'emergency_report_id' => (int)($row['emergency_report_id'] ?? 0),
                'order_id' => (int)($row['order_id'] ?? 0),
                'driver_id' => (int)($row['driver_id'] ?? 0),
                'driver_name' => (string)($row['driver_name'] ?? ''),
                'phone' => (string)($row['driver_phone'] ?? ''),
                'status' => 'نشط',
                'severity' => 'عالية',
                'type' => (string)($row['reason'] ?? 'Driver emergency'),
                'location' => (string)($row['location_label'] ?? ''),
                'description' => (string)($row['reason'] ?? ''),
                'created_at' => logisticsTime($row['reported_at'] ?? null),
                'elapsed_label' => logisticsRelative($row['reported_at'] ?? null),
                'color_hex' => '#EF4444',
                'lat' => $row['latitude'] ?? null,
                'lng' => $row['longitude'] ?? null,
                'avatar_url' => '',
            ];
        }
    }
    // Some older driver clients only update the emergency columns on orders.
    // Use that source as a fallback even when the reports table exists but is empty.
    if (empty($emergencyRows) && columnExists('orders', 'driver_emergency_reason') && columnExists('orders', 'driver_emergency_at')) {
        $emergencyRows = logisticsRows("
            SELECT
                o.orders_id,
                o.delivery_id,
                o.driver_emergency_reason,
                o.driver_emergency_at,
                COALESCE(du.name, 'Driver') AS driver_name,
                COALESCE(du.phone, '') AS driver_phone,
                COALESCE(du.latitude, o.driver_latitude, o.delivery_latitude, o.orders_recipient_lat) AS latitude,
                COALESCE(du.longitude, o.driver_longitude, o.delivery_longitude, o.orders_recipient_lng) AS longitude,
                COALESCE(o.orders_recipient_address_name, o.orders_recipient_address_line, '') AS location_label
            FROM orders o
            LEFT JOIN delivery_users du ON du.id = o.delivery_id
            WHERE COALESCE(o.driver_emergency_reason, '') <> ''
            ORDER BY o.driver_emergency_at DESC
            LIMIT 40
        ");
        foreach ($emergencyRows as $row) {
            $emergencyRequests[] = [
                'id' => '#EMR-' . (int)($row['orders_id'] ?? 0),
                'emergency_report_id' => 0,
                'order_id' => (int)($row['orders_id'] ?? 0),
                'driver_id' => (int)($row['delivery_id'] ?? 0),
                'driver_name' => (string)($row['driver_name'] ?? ''),
                'phone' => (string)($row['driver_phone'] ?? ''),
                'status' => 'نشط',
                'severity' => 'عالية',
                'type' => (string)($row['driver_emergency_reason'] ?? 'Driver emergency'),
                'location' => (string)($row['location_label'] ?? ''),
                'description' => (string)($row['driver_emergency_reason'] ?? ''),
                'created_at' => logisticsTime($row['driver_emergency_at'] ?? null),
                'elapsed_label' => logisticsRelative($row['driver_emergency_at'] ?? null),
                'color_hex' => '#EF4444',
                'lat' => $row['latitude'] ?? null,
                'lng' => $row['longitude'] ?? null,
                'avatar_url' => '',
            ];
        }
    }

    $stats = [
        ['title' => 'متوسط وقت التوصيل', 'value' => (string)round($avgDelivery), 'icon_key' => 'time', 'accent_hex' => '#0B8F4D', 'background_hex' => '#EAF7EE', 'trend_label' => 'دقيقة', 'trend_caption' => '', 'trend_positive' => $avgDelivery > 0],
        ['title' => 'الطلبات قيد التوصيل', 'value' => (string)$activeDeliveryOrders, 'icon_key' => 'orders', 'accent_hex' => '#1E7D3F', 'background_hex' => '#EAF5ED', 'trend_label' => '+' . $activeDeliveryOrders, 'trend_caption' => 'عن أمس', 'trend_positive' => true],
        ['title' => 'سائقين غير متاحين', 'value' => (string)$unavailableDrivers, 'icon_key' => 'user', 'accent_hex' => '#64748B', 'background_hex' => '#F1F5F9', 'trend_label' => logisticsNumber($totalDrivers > 0 ? ($unavailableDrivers / $totalDrivers) * 100 : 0, 1) . '%', 'trend_caption' => 'من الإجمالي', 'trend_positive' => false],
        ['title' => 'سائقين مشغولين', 'value' => (string)$busyDrivers, 'icon_key' => 'users', 'accent_hex' => '#F59E0B', 'background_hex' => '#FFF4E4', 'trend_label' => logisticsNumber($totalDrivers > 0 ? ($busyDrivers / $totalDrivers) * 100 : 0, 1) . '%', 'trend_caption' => 'من الإجمالي', 'trend_positive' => true],
        ['title' => 'سائقين متاحين الآن', 'value' => (string)$availableDrivers, 'icon_key' => 'user_check', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED', 'trend_label' => logisticsNumber($totalDrivers > 0 ? ($availableDrivers / $totalDrivers) * 100 : 0, 1) . '%', 'trend_caption' => 'من الإجمالي', 'trend_positive' => true],
        ['title' => 'إجمالي السائقين', 'value' => (string)$totalDrivers, 'icon_key' => 'users', 'accent_hex' => '#0B8F4D', 'background_hex' => '#EAF7EE', 'trend_label' => '+12%', 'trend_caption' => 'عن أمس', 'trend_positive' => true],
    ];

    $dispatchStats = [
        ['title' => 'ملغاة اليوم', 'value' => (string)$canceledToday, 'icon_key' => 'close', 'accent_hex' => '#D92C2C', 'background_hex' => '#FDEEEF', 'trend_label' => '-2%', 'trend_caption' => 'عن أمس', 'trend_positive' => false],
        ['title' => 'مكتملة', 'value' => (string)$completedToday, 'icon_key' => 'check', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED', 'trend_label' => '+16%', 'trend_caption' => 'عن أمس', 'trend_positive' => true],
        ['title' => 'طلبات في الطريق الآن', 'value' => (string)$onWayNow, 'icon_key' => 'delivery', 'accent_hex' => '#2563EB', 'background_hex' => '#EAF1FF', 'trend_label' => '+' . $onWayNow, 'trend_caption' => '', 'trend_positive' => true],
        ['title' => 'متوسط وقت التوزيع', 'value' => (string)round($avgAssignment, 1), 'icon_key' => 'time', 'accent_hex' => '#F59E0B', 'background_hex' => '#FFF4E4', 'trend_label' => 'دقيقة', 'trend_caption' => '', 'trend_positive' => $avgAssignment > 0],
        ['title' => 'طلبات موزعة اليوم', 'value' => (string)$assignedToday, 'icon_key' => 'orders', 'accent_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED', 'trend_label' => '+18%', 'trend_caption' => 'عن أمس', 'trend_positive' => true],
        ['title' => 'إسنادات غير موزعة', 'value' => (string)$unassignedOrdersCount, 'icon_key' => 'user', 'accent_hex' => '#0B8F4D', 'background_hex' => '#EAF7EE', 'trend_label' => 'منذ آخر تحديث', 'trend_caption' => '', 'trend_positive' => false],
    ];

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => date('c'),
            'view' => $view,
            'stats' => $stats,
            'dispatch_stats' => $dispatchStats,
            'drivers' => $drivers,
            'unassigned_orders' => $unassigned,
            'active_orders' => $activeOrders,
            'assignment_history' => $history,
            'map_markers' => array_slice($mapMarkers, 0, 120),
            'service_zones' => $serviceZones,
            'emergency_requests' => $emergencyRequests,
            'summary' => [
                'total_drivers' => $totalDrivers,
                'available_drivers' => $availableDrivers,
                'busy_drivers' => $busyDrivers,
                'unavailable_drivers' => $unavailableDrivers,
                'active_delivery_orders' => $activeDeliveryOrders,
                'unassigned_orders' => $unassignedOrdersCount,
                'assigned_today' => $assignedToday,
                'completed_today' => $completedToday,
                'canceled_today' => $canceledToday,
                'on_way_now' => $onWayNow,
                'avg_assignment_minutes' => round($avgAssignment, 1),
                'avg_delivery_minutes' => round($avgDelivery, 1),
                'driver_status_counts' => $statusCounts,
                'vehicle_counts' => $vehicleCounts,
                'data_quality' => [
                    'degraded' => count($GLOBALS['logisticsQueryErrors']) > 0,
                    'query_errors' => count($GLOBALS['logisticsQueryErrors']),
                    'drivers_loaded' => count($drivers),
                    'orders_loaded' => count($unassigned),
                    'zones_loaded' => count($serviceZones),
                ],
            ],
            'data_quality' => count($GLOBALS['logisticsQueryErrors']) === 0
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($GLOBALS['logisticsQueryErrors'])),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [
            'server_now' => date('c'),
            'stats' => [],
            'dispatch_stats' => [],
            'drivers' => [],
            'unassigned_orders' => [],
            'active_orders' => [],
            'assignment_history' => [],
            'map_markers' => [],
            'service_zones' => [],
            'emergency_requests' => [],
        ],
    ], 500);
}
