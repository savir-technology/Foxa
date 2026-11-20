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

$ordersQueryFailures = [];

function ordersMarkQueryFailure(string $component, Throwable $error): void
{
    global $ordersQueryFailures;
    $ordersQueryFailures[] = $component;
    error_log('master orders ' . $component . ' failed: ' . $error->getMessage());
}

function ordersScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        ordersMarkQueryFailure('scalar_query', $e);
        return $fallback;
    }
}

function ordersRows(string $sql, array $params = []): array
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        ordersMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function ordersNumber($value, int $decimals = 0): string
{
    return number_format((float)$value, $decimals, '.', ',');
}

function ordersTime(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '--:--' : date('H:i', $timestamp);
}

function ordersRelative(?string $value): string
{
    $timestamp = strtotime((string)$value);
    if ($timestamp === false) {
        return 'الآن';
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

function ordersScheduleLabel(?string $value): string
{
    $timestamp = strtotime((string)$value);
    if ($timestamp === false) {
        return '';
    }
    $date = date('Y-m-d', $timestamp);
    $today = date('Y-m-d');
    $tomorrow = date('Y-m-d', strtotime('+1 day'));
    $prefix = $date === $today ? 'اليوم' : ($date === $tomorrow ? 'غداً' : date('Y-m-d', $timestamp));
    return $prefix . ' ' . date('H:i', $timestamp);
}

function ordersAssetUrl($value, string $folder): string
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

function orderStatusMeta($status): array
{
    $key = strtolower(trim((string)$status));
    if (in_array($key, ['pending', 'new', '0'], true)) {
        return ['label' => 'جديد', 'color_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'];
    }
    if (in_array($key, ['preparing', 'accepted', 'heading_to_restaurant', 'arrived_at_restaurant'], true)) {
        return ['label' => 'قيد التحضير', 'color_hex' => '#CA7A00', 'background_hex' => '#FFF4E4'];
    }
    if (in_array($key, ['ready', 'picked_up', 'assigned'], true)) {
        return ['label' => 'جاهزة للاستلام', 'color_hex' => '#2563EB', 'background_hex' => '#EAF1FF'];
    }
    if (in_array($key, ['with_driver', 'on_driver'], true)) {
        return ['label' => 'مع السائق', 'color_hex' => '#7C3AED', 'background_hex' => '#F1ECFF'];
    }
    if (in_array($key, ['on_way', 'on_the_way', 'out_for_delivery'], true)) {
        return ['label' => 'في الطريق', 'color_hex' => '#4F46E5', 'background_hex' => '#EEF2FF'];
    }
    if (in_array($key, ['delivered', 'completed', 'paid', '4'], true)) {
        return ['label' => 'مكتملة', 'color_hex' => '#1E7D3F', 'background_hex' => '#EAF5ED'];
    }
    if (in_array($key, ['returned', 'refunded', 'return', 'refund'], true)) {
        return ['label' => 'مردود', 'color_hex' => '#64748B', 'background_hex' => '#F1F5F9'];
    }
    if (in_array($key, ['canceled', 'cancelled', 'failed', 'rejected'], true)) {
        return ['label' => 'ملغية', 'color_hex' => '#D92C2C', 'background_hex' => '#FDEEEF'];
    }
    return ['label' => $key === '' ? 'غير محدد' : $status, 'color_hex' => '#4E5660', 'background_hex' => '#F3F4F6'];
}

function normalizePaymentKey($method): string
{
    $key = strtolower(trim((string)$method));
    if ($key === '') {
        return 'cash';
    }
    if (strpos($key, 'visa') !== false || strpos($key, 'فيزا') !== false || strpos($key, 'card') !== false || strpos($key, 'credit') !== false || strpos($key, 'master') !== false) {
        return 'visa';
    }
    if (strpos($key, 'wallet') !== false || strpos($key, 'محفظ') !== false) {
        return 'wallet';
    }
    if (strpos($key, 'cash') !== false || strpos($key, 'cod') !== false || strpos($key, 'كاش') !== false) {
        return 'cash';
    }
    if (in_array($key, ['0', '1', '2'], true)) {
        if ($key === '2') {
            return 'wallet';
        }
        if ($key === '1') {
            return 'visa';
        }
        return 'cash';
    }
    return $key;
}

function paymentMeta($method): array
{
    $key = normalizePaymentKey($method);
    if ($key === 'visa') {
        return ['key' => 'visa', 'label' => 'فيزا', 'icon_key' => 'payments'];
    }
    if ($key === 'wallet') {
        return ['key' => 'wallet', 'label' => 'محفظة', 'icon_key' => 'wallet'];
    }
    return ['key' => 'cash', 'label' => 'كاش', 'icon_key' => 'payments'];
}

function hasOnlinePaymentEvidence(array $row): bool
{
    $transactionId = trim((string)($row['transaction_id'] ?? ''));
    $gatewayRef = trim((string)($row['orders_gateway_ref'] ?? ''));
    return $transactionId !== '' || $gatewayRef !== '';
}

function orderTypeLabel($type): string
{
    $key = strtolower(trim((string)$type));
    if (str_contains($key, 'pickup') || str_contains($key, 'self')) {
        return 'استلام ذاتي';
    }
    return 'توصيل';
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'orders.view');
    $master = masterPublicData($admin);

    $ordersAvailable = tableExists('orders');
    $usersAvailable = tableExists('users');
    $itemsAvailable = tableExists('order_items');
    $vendorsAvailable = tableExists('vendors');
    $settingsAvailable = tableExists('vendor_store_settings');
    $driversAvailable = tableExists('delivery_users');
    $printersAvailable = tableExists('vendor_printers');
    $printJobsAvailable = tableExists('vendor_print_jobs');
    $printSettingsAvailable = tableExists('vendor_print_settings');

    if (!$ordersAvailable) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [
                'server_now' => date('c'),
                'stats' => [],
                'orders' => [],
                'channels' => [],
                'time_channels' => [],
                'finance' => [],
                'top_restaurants' => [],
                'avg_preparation_minutes' => 0,
                'printing' => [
                    'connected_printers' => 0,
                    'printed_today' => 0,
                    'printed_invoices' => 0,
                    'printed_receipts' => 0,
                    'settings' => ['invoice_copies' => 1, 'print_logo' => true],
                    'printers' => [],
                ],
                'pagination' => ['page' => 1, 'limit' => 20, 'total' => 0],
                'data_quality' => [
                    'state' => 'degraded',
                    'failed_components' => ['orders_schema'],
                ],
            ],
        ]);
    }

    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = (int)($_GET['limit'] ?? 20);
    if ($limit <= 0 || $limit > 100) {
        $limit = 20;
    }
    $offset = ($page - 1) * $limit;
    $query = trim((string)($_GET['q'] ?? ''));
    $statusFilter = trim((string)($_GET['status'] ?? 'all'));
    $paymentFilter = normalizePaymentKey($_GET['payment'] ?? 'all');
    $typeFilter = trim((string)($_GET['type'] ?? 'all'));
    $scheduledOnly = (string)($_GET['scheduled'] ?? '') === '1';

    $where = ['1=1'];
    if ($scheduledOnly) {
        $where[] = "o.scheduled_for IS NOT NULL AND o.scheduled_for <> ''";
    }
    $params = [];
    if ($query !== '') {
        $where[] = "(CAST(o.orders_id AS CHAR) LIKE :q OR o.orders_recipient_name LIKE :q OR o.orders_recipient_phone LIKE :q" . ($usersAvailable ? " OR u.users_name LIKE :q OR u.users_phone LIKE :q" : "") . ")";
        $params[':q'] = '%' . $query . '%';
    }
    if ($statusFilter !== '' && $statusFilter !== 'all') {
        if ($statusFilter === 'pending') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('pending','new','0')";
        } elseif ($statusFilter === 'preparing') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('preparing','accepted','heading_to_restaurant','arrived_at_restaurant')";
        } elseif ($statusFilter === 'ready') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('ready','picked_up','assigned')";
        } elseif ($statusFilter === 'with_driver') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('with_driver','on_driver')";
        } elseif ($statusFilter === 'on_way') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('on_way','on_the_way','out_for_delivery')";
        } elseif ($statusFilter === 'delivered') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('delivered','completed','paid','4')";
        } elseif ($statusFilter === 'canceled') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('canceled','cancelled','failed','rejected')";
        } elseif ($statusFilter === 'returned') {
            $where[] = "COALESCE(o.status, o.orders_status, '') IN ('returned','refunded','return','refund')";
        } else {
            $where[] = "COALESCE(o.status, o.orders_status, '') = :status";
            $params[':status'] = $statusFilter;
        }
    }
    if ($paymentFilter !== '' && $paymentFilter !== 'all') {
        if ($paymentFilter === 'visa') {
            $where[] = "(LOWER(COALESCE(o.payment_method, '')) LIKE '%visa%' OR COALESCE(o.payment_method, '') LIKE '%فيزا%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%card%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%credit%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%master%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%online%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%paypal%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%paymob%' OR COALESCE(o.orders_paymentmethod, '') = '1')";
        } elseif ($paymentFilter === 'wallet') {
            $where[] = "(LOWER(COALESCE(o.payment_method, '')) LIKE '%wallet%' OR COALESCE(o.payment_method, '') LIKE '%محفظ%' OR COALESCE(o.orders_paymentmethod, '') = '2')";
        } elseif ($paymentFilter === 'cash') {
            $where[] = "(LOWER(COALESCE(o.payment_method, '')) LIKE '%cash%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%cod%' OR LOWER(COALESCE(o.payment_method, '')) LIKE '%cash_on_delivery%' OR COALESCE(o.payment_method, '') LIKE '%كاش%' OR (COALESCE(o.payment_method, '') = '' AND COALESCE(o.orders_paymentmethod, '') IN ('', '0')) OR (COALESCE(o.orders_paymentmethod, '') = '0' AND LOWER(COALESCE(o.payment_method, '')) NOT LIKE '%wallet%' AND LOWER(COALESCE(o.payment_method, '')) NOT LIKE '%visa%' AND LOWER(COALESCE(o.payment_method, '')) NOT LIKE '%card%' AND LOWER(COALESCE(o.payment_method, '')) NOT LIKE '%online%' AND LOWER(COALESCE(o.payment_method, '')) NOT LIKE '%paypal%'))";
        }
    }
    if ($typeFilter !== '' && $typeFilter !== 'all') {
        if ($typeFilter === 'pickup') {
            $where[] = "(LOWER(COALESCE(o.order_mode, o.orders_type, '')) LIKE '%pickup%' OR LOWER(COALESCE(o.order_mode, o.orders_type, '')) LIKE '%self%')";
        } elseif ($typeFilter === 'delivery') {
            $where[] = "(LOWER(COALESCE(o.order_mode, o.orders_type, '')) NOT LIKE '%pickup%' AND LOWER(COALESCE(o.order_mode, o.orders_type, '')) NOT LIKE '%self%')";
        }
    }
    $whereSql = implode(' AND ', $where);

    $userSelect = $usersAvailable
        ? "COALESCE(u.users_name, o.orders_recipient_name, 'عميل') AS customer_name,
           COALESCE(u.users_phone, o.orders_recipient_phone, '') AS customer_phone"
        : "COALESCE(o.orders_recipient_name, 'عميل') AS customer_name,
           COALESCE(o.orders_recipient_phone, '') AS customer_phone";
    $userJoin = $usersAvailable ? "LEFT JOIN users u ON u.users_id = o.orders_usersid" : "";
    $driverJoin = $driversAvailable ? "LEFT JOIN delivery_users du ON du.id = o.delivery_id" : "";
    $driverSelect = $driversAvailable ? "COALESCE(du.name, '') AS driver_name" : "'' AS driver_name";

    $vendorJoin = "";
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
        $restaurantSelect = "COALESCE(v.store_name, {$settingsName} v.vendor_name, '') AS restaurant_name";
        $restaurantLogoSelect = "COALESCE({$settingsLogo} v.vendor_logo, '') AS restaurant_logo_url";
    }

    $total = (int)ordersScalar("SELECT COUNT(*) FROM orders o {$userJoin} WHERE {$whereSql}", $params, 0);
    $rows = ordersRows("
        SELECT
            o.orders_id,
            o.orders_datetime,
            o.orders_share_token,
            o.scheduled_for,
            o.orders_recipient_address_line,
            o.orders_recipient_address_name,
            o.orders_totalprice,
            o.orders_pricedelivery,
            o.orders_type,
            o.order_mode,
            o.orders_paymentmethod,
            o.payment_method,
            o.transaction_id,
            o.orders_gateway_ref,
            o.paid_amount,
            COALESCE(o.status, o.orders_status, '') AS status_key,
            {$driverSelect},
            {$userSelect},
            {$restaurantSelect},
            {$restaurantLogoSelect}
        FROM orders o
        {$userJoin}
        {$driverJoin}
        {$vendorJoin}
        WHERE {$whereSql}
        ORDER BY " . ($scheduledOnly ? "o.scheduled_for ASC, " : "") . "o.orders_datetime DESC, o.orders_id DESC
        LIMIT {$limit} OFFSET {$offset}
    ", $params);

    $orders = [];
    foreach ($rows as $row) {
        $orderId = (int)($row['orders_id'] ?? 0);
        $status = orderStatusMeta($row['status_key'] ?? '');
        $paymentSource = trim((string)($row['payment_method'] ?? ''));
        if ($paymentSource === '') {
            $paymentSource = (string)($row['orders_paymentmethod'] ?? '');
        }
        $payment = paymentMeta($paymentSource);
        $paymentConfirmed = $payment['key'] !== 'visa' || hasOnlinePaymentEvidence($row);
        $shareToken = trim((string)($row['orders_share_token'] ?? ''));
        $items = [];
        if ($itemsAvailable && $orderId > 0) {
            $itemRows = ordersRows("
                SELECT
                    COALESCE(NULLIF(item_name, ''), CONCAT('Item #', item_id)) AS item_name,
                    item_price,
                    quantity,
                    quantity_weight,
                    COALESCE(line_total, subtotal, item_price * quantity) AS total
                FROM order_items
                WHERE order_id = :order_id
                ORDER BY order_item_id ASC
                LIMIT 8
            ", [':order_id' => $orderId]);
            foreach ($itemRows as $itemRow) {
                $items[] = [
                    'name' => (string)($itemRow['item_name'] ?? 'صنف'),
                    'quantity' => (int)($itemRow['quantity'] ?? 1),
                    'unit_price' => ordersNumber($itemRow['item_price'] ?? 0) . ' س',
                    'total' => ordersNumber($itemRow['total'] ?? 0) . ' س',
                ];
            }
        }
        $orders[] = [
            'order_id' => $orderId,
            'order_no' => '#' . $orderId,
            'share_token' => $shareToken,
            'tracking_url' => $shareToken !== ''
                ? 'https://savir-technology.online/roaqv2/track.php?token=' . rawurlencode($shareToken)
                : ($orderId > 0 ? 'https://savir-technology.online/roaqv2/orders/details.php?id=' . rawurlencode((string)$orderId) : ''),
            'customer' => (string)($row['customer_name'] ?? 'عميل'),
            'phone' => (string)($row['customer_phone'] ?? ''),
            'driver_name' => (string)($row['driver_name'] ?? ''),
            'restaurant' => (string)($row['restaurant_name'] ?? ''),
            'restaurant_logo_url' => ordersAssetUrl($row['restaurant_logo_url'] ?? '', 'uploads/vendors/logo'),
            'branch' => 'الفرع الرئيسي',
            'type_label' => orderTypeLabel($row['order_mode'] ?? $row['orders_type'] ?? ''),
            'scheduled_label' => ordersScheduleLabel($row['scheduled_for'] ?? null),
            'address_label' => trim((string)($row['orders_recipient_address_name'] ?? '')) !== ''
                ? trim((string)($row['orders_recipient_address_name'] ?? ''))
                : trim((string)($row['orders_recipient_address_line'] ?? '')),
            'status_label' => $status['label'],
            'status_color_hex' => $status['color_hex'],
            'status_background_hex' => $status['background_hex'],
            'amount_label' => ordersNumber($row['orders_totalprice'] ?? 0) . ' س',
            'payment_key' => $payment['key'],
            'payment_label' => $payment['label'],
            'payment_icon_key' => $payment['icon_key'],
            'payment_confirmed' => $paymentConfirmed,
            'time_label' => ordersTime($row['orders_datetime'] ?? null),
            'relative_label' => ordersRelative($row['orders_datetime'] ?? null),
            'items' => $items,
        ];
    }

    $todayWhere = "DATE(orders_datetime)=CURDATE()";
    $yesterdayWhere = "DATE(orders_datetime)=DATE_SUB(CURDATE(), INTERVAL 1 DAY)";
    $countToday = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE {$todayWhere}");
    $countYesterday = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE {$yesterdayWhere}");
    $newCount = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('pending','new','0')");
    $preparingCount = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('preparing','accepted','heading_to_restaurant','arrived_at_restaurant')");
    $readyCount = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('ready','picked_up','assigned')");
    $withDriverCount = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('with_driver','on_driver')");
    $onWayCount = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('on_way','on_the_way','out_for_delivery')");
    $completedToday = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('delivered','completed','paid','4') AND DATE(COALESCE(delivered_at, updated_at, orders_datetime))=CURDATE()");
    $canceledToday = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('canceled','cancelled','failed','rejected') AND DATE(COALESCE(updated_at, orders_datetime))=CURDATE()");
    $returnedCount = (int)ordersScalar("SELECT COUNT(*) FROM orders WHERE COALESCE(status, orders_status, '') IN ('returned','refunded','return','refund')");

    $stats = [
        ['title' => 'جديد', 'value' => $newCount, 'icon_key' => 'add', 'accent_hex' => '#14936B', 'background_hex' => '#EAF8F2', 'trend_label' => '+' . $newCount, 'trend_caption' => 'اليوم', 'trend_positive' => true],
        ['title' => 'قيد التحضير', 'value' => $preparingCount, 'icon_key' => 'kitchen', 'accent_hex' => '#D79A00', 'background_hex' => '#FFF8E4', 'trend_label' => '+' . $preparingCount, 'trend_caption' => 'نشط', 'trend_positive' => true],
        ['title' => 'جاهزة للاستلام', 'value' => $readyCount, 'icon_key' => 'orders', 'accent_hex' => '#2563EB', 'background_hex' => '#EAF1FF', 'trend_label' => '+' . $readyCount, 'trend_caption' => 'جاهز', 'trend_positive' => true],
        ['title' => 'مع السائق', 'value' => $withDriverCount, 'icon_key' => 'user', 'accent_hex' => '#F59E0B', 'background_hex' => '#FFF4E4', 'trend_label' => '+' . $withDriverCount, 'trend_caption' => 'جاري', 'trend_positive' => true],
        ['title' => 'في الطريق', 'value' => $onWayCount, 'icon_key' => 'delivery', 'accent_hex' => '#7C3AED', 'background_hex' => '#F1ECFF', 'trend_label' => '+' . $onWayCount, 'trend_caption' => 'توصيل', 'trend_positive' => true],
        ['title' => 'مكتملة اليوم', 'value' => $completedToday, 'icon_key' => 'check', 'accent_hex' => '#1E7D3F', 'background_hex' => '#EAF5ED', 'trend_label' => '+' . $completedToday, 'trend_caption' => 'اليوم', 'trend_positive' => true],
        ['title' => 'ملغية', 'value' => $canceledToday, 'icon_key' => 'warning', 'accent_hex' => '#D92C2C', 'background_hex' => '#FDEEEF', 'trend_label' => (string)$canceledToday, 'trend_caption' => 'اليوم', 'trend_positive' => false],
        ['title' => 'مردود', 'value' => $returnedCount, 'icon_key' => 'refund', 'accent_hex' => '#64748B', 'background_hex' => '#F1F5F9', 'trend_label' => (string)$returnedCount, 'trend_caption' => 'اليوم', 'trend_positive' => false],
    ];

    $revenueToday = (float)ordersScalar("SELECT COALESCE(SUM(orders_totalprice),0) FROM orders WHERE {$todayWhere}");
    $avgOrder = $countToday > 0 ? $revenueToday / $countToday : 0;
    $deliveryFees = (float)ordersScalar("SELECT COALESCE(SUM(orders_pricedelivery),0) FROM orders WHERE {$todayWhere}");
    $discounts = (float)ordersScalar("SELECT COALESCE(SUM(orders_coupon),0) FROM orders WHERE {$todayWhere}");

    $channels = [];
    $channelTotal = (int)ordersScalar("
        SELECT COUNT(*)
        FROM orders o
        {$userJoin}
        WHERE {$whereSql}
    ", $params, 0);
    $channelRows = ordersRows("
        SELECT COALESCE(NULLIF(o.order_mode, ''), NULLIF(o.orders_type, ''), 'delivery') AS channel, COUNT(*) AS total
        FROM orders o
        {$userJoin}
        WHERE {$whereSql}
        GROUP BY channel
        ORDER BY total DESC
        LIMIT 4
    ", $params);
    foreach ($channelRows as $row) {
        $channels[] = [
            'label' => orderTypeLabel($row['channel'] ?? ''),
            'value' => (int)($row['total'] ?? 0),
            'percent' => $channelTotal > 0 ? round(((int)$row['total'] / $channelTotal) * 100) : 0,
        ];
    }

    $timeChannels = [];
    $timeLabels = [
        'morning' => 'صباحا',
        'afternoon' => 'ظهرا',
        'evening' => 'مساء',
    ];
    $timeRows = ordersRows("
        SELECT
            CASE
                WHEN HOUR(o.orders_datetime) BETWEEN 6 AND 11 THEN 'morning'
                WHEN HOUR(o.orders_datetime) BETWEEN 12 AND 17 THEN 'afternoon'
                ELSE 'evening'
            END AS bucket,
            COUNT(*) AS total
        FROM orders o
        {$userJoin}
        WHERE {$whereSql}
        GROUP BY bucket
    ", $params);
    $timeTotals = ['morning' => 0, 'afternoon' => 0, 'evening' => 0];
    foreach ($timeRows as $row) {
        $bucket = (string)($row['bucket'] ?? '');
        if (array_key_exists($bucket, $timeTotals)) {
            $timeTotals[$bucket] = (int)($row['total'] ?? 0);
        }
    }
    $timeTotal = array_sum($timeTotals);
    foreach ($timeTotals as $bucket => $value) {
        $timeChannels[] = [
            'label' => $timeLabels[$bucket],
            'value' => $value,
            'percent' => $timeTotal > 0 ? round(($value / $timeTotal) * 100) : 0,
        ];
    }

    $avgPreparationMinutes = (float)ordersScalar("
        SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, o.accepted_at, o.picked_up_at)), 0)
        FROM orders o
        {$userJoin}
        WHERE {$whereSql}
          AND o.accepted_at IS NOT NULL
          AND o.picked_up_at IS NOT NULL
          AND o.picked_up_at >= o.accepted_at
    ", $params, 0);

    $topRestaurants = [];
    if ($itemsAvailable && $vendorsAvailable) {
        $topRows = ordersRows("
            SELECT COALESCE(NULLIF(v.store_name, ''), " . ($settingsAvailable ? "NULLIF(s.store_name, ''), " : "") . "NULLIF(v.vendor_name, ''), 'غير محدد') AS name, COUNT(DISTINCT oi.order_id) AS total
            FROM order_items oi
            JOIN orders o ON o.orders_id = oi.order_id
            {$userJoin}
            LEFT JOIN vendors v ON v.vendor_id = oi.vendor_id
            " . ($settingsAvailable ? "LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id" : "") . "
            WHERE {$whereSql}
            GROUP BY oi.vendor_id, name
            ORDER BY total DESC
            LIMIT 5
        ", $params);
        foreach ($topRows as $row) {
            $topRestaurants[] = [
                'name' => (string)($row['name'] ?? ''),
                'orders' => (int)($row['total'] ?? 0),
            ];
        }
    }

    $printing = [
        'connected_printers' => 0,
        'printed_today' => 0,
        'printed_invoices' => 0,
        'printed_receipts' => 0,
        'settings' => ['invoice_copies' => 1, 'print_logo' => true],
        'printers' => [],
        'templates' => [],
    ];
    if ($printersAvailable) {
        $printing['connected_printers'] = (int)ordersScalar("SELECT COUNT(*) FROM vendor_printers WHERE is_active=1", [], 0);
        $printerRows = ordersRows("
            SELECT printer_name, printer_type, printer_location, is_active
            FROM vendor_printers
            ORDER BY is_active DESC, printer_id DESC
            LIMIT 6
        ");
        foreach ($printerRows as $row) {
            $printing['printers'][] = [
                'name' => (string)($row['printer_name'] ?? 'طابعة'),
                'type' => (string)($row['printer_type'] ?? ''),
                'location' => (string)($row['printer_location'] ?? ''),
                'is_active' => (int)($row['is_active'] ?? 0) === 1,
            ];
        }
    }
    if ($printJobsAvailable) {
        $printing['printed_today'] = (int)ordersScalar("SELECT COUNT(*) FROM vendor_print_jobs WHERE DATE(printed_at)=CURDATE() AND job_status IN ('printed','success','completed')", [], 0);
        $printing['printed_invoices'] = (int)ordersScalar("SELECT COUNT(*) FROM vendor_print_jobs WHERE DATE(printed_at)=CURDATE() AND job_type LIKE '%invoice%' AND job_status IN ('printed','success','completed')", [], 0);
        $printing['printed_receipts'] = (int)ordersScalar("SELECT COUNT(*) FROM vendor_print_jobs WHERE DATE(printed_at)=CURDATE() AND (job_type LIKE '%receipt%' OR job_type LIKE '%order%') AND job_status IN ('printed','success','completed')", [], 0);
    }
    if ($printSettingsAvailable) {
        $settingsRow = ordersRows("
            SELECT invoice_copies, print_logo
            FROM vendor_print_settings
            ORDER BY updated_at DESC, setting_id DESC
            LIMIT 1
        ");
        if (!empty($settingsRow)) {
            $printing['settings'] = [
                'invoice_copies' => max(1, (int)($settingsRow[0]['invoice_copies'] ?? 1)),
                'print_logo' => (int)($settingsRow[0]['print_logo'] ?? 1) === 1,
            ];
        }
    }
    if (tableExists('vendor_invoice_templates')) {
        $templateRows = ordersRows("\n            SELECT template_name\n            FROM vendor_invoice_templates\n            WHERE is_active=1\n            ORDER BY updated_at DESC, template_id DESC\n            LIMIT 12\n        ");
        foreach ($templateRows as $row) {
            $templateName = trim((string)($row['template_name'] ?? ''));
            if ($templateName !== '') {
                $printing['templates'][] = $templateName;
            }
        }
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => date('c'),
            'stats' => $stats,
            'orders' => $orders,
            'channels' => $channels,
            'time_channels' => $timeChannels,
            'finance' => [
                ['label' => 'إجمالي الطلبات', 'value' => ordersNumber($countToday)],
                ['label' => 'الإيرادات', 'value' => ordersNumber($revenueToday) . ' س'],
                ['label' => 'متوسط قيمة الطلب', 'value' => ordersNumber($avgOrder) . ' س'],
                ['label' => 'رسوم التوصيل', 'value' => ordersNumber($deliveryFees) . ' س'],
                ['label' => 'الخصومات', 'value' => ordersNumber($discounts) . ' س'],
            ],
            'top_restaurants' => $topRestaurants,
            'avg_preparation_minutes' => round($avgPreparationMinutes),
            'printing' => $printing,
            'pagination' => ['page' => $page, 'limit' => $limit, 'total' => $total],
            'today_count' => $countToday,
            'yesterday_count' => $countYesterday,
            'data_quality' => empty($ordersQueryFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($ordersQueryFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
