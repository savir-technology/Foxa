<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['master']);
$admin = $actor['master'] ?? [];
requireMasterPermission($admin, 'drivers.view');

function requireDriverMasterSchema(): void
{
    $required = [
        'driver_notifications' => [
            'notification_id', 'driver_id', 'notification_type',
            'notification_title', 'notification_body', 'notification_is_read',
            'notification_created_at',
        ],
        'driver_support_messages' => [
            'support_message_id', 'driver_id', 'sender_role', 'message',
            'audio_url', 'is_read_by_driver', 'is_read_by_admin', 'created_at',
        ],
        'delivery_driver_shift_logs' => [
            'shift_log_id', 'driver_id', 'shift_started_at', 'shift_ended_at',
            'status', 'created_at',
        ],
        'driver_ratings' => [
            'rating_id', 'order_id', 'driver_id', 'user_id', 'rating', 'created_at',
        ],
    ];

    foreach ($required as $table => $columns) {
        if (!tableExists($table)) {
            respondJson([
                'status' => 'error',
                'message' => 'جداول بيانات السائقين غير مكتملة. طبّق migration 20260818_master_driver_auxiliary_tables.sql أولًا.',
            ], 409);
        }
        foreach ($columns as $column) {
            if (!columnExists($table, $column)) {
                respondJson([
                    'status' => 'error',
                    'message' => 'بنية بيانات السائقين غير مكتملة. طبّق migration 20260818_master_driver_auxiliary_tables.sql أولًا.',
                ], 409);
            }
        }
    }
}

function resolvePublicMediaUrl(?string $path): ?string
{
    $raw = trim((string)$path);
    if ($raw === '' || strtolower($raw) === 'null') {
        return null;
    }

    if (preg_match('#^https?://#i', $raw)) {
        return $raw;
    }

    return 'https://savir-technology.online/roaqv2/' . ltrim($raw, '/');
}

function safeDateTimeLabel(?string $value): string
{
    $raw = trim((string)$value);
    if ($raw === '' || strtolower($raw) === 'null') {
        return '--';
    }

    $timestamp = strtotime($raw);
    if ($timestamp === false) {
        return $raw;
    }

    return date('Y-m-d H:i', $timestamp);
}

function safeFloat($value): ?float
{
    if ($value === null) {
        return null;
    }

    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }

    $number = (float)$text;
    if (!is_finite($number)) {
        return null;
    }

    return $number;
}

function safeInt($value): int
{
    return (int)($value ?? 0);
}

function liveStatusExpr(): string
{
    return "(du.status = 'online' OR (du.last_seen_at IS NOT NULL AND du.last_seen_at >= (NOW() - INTERVAL 5 MINUTE)))";
}

function buildDriverBaseSql(): string
{
    $onlineExpr = liveStatusExpr();

    return <<<SQL
SELECT
    du.id AS driver_id,
    du.name AS driver_name,
    du.phone AS driver_phone,
    du.email AS driver_email,
    du.vehicle_type,
    du.vehicle_number,
    du.status AS raw_status,
    CASE WHEN $onlineExpr THEN 'online' ELSE 'offline' END AS live_status,
    CASE WHEN $onlineExpr THEN 1 ELSE 0 END AS is_online,
    du.latitude,
    du.longitude,
    du.notifications_enabled,
    du.location_sharing_enabled,
    du.locale_code,
    du.theme_mode,
    du.last_seen_at,
    du.created_at,
    du.vendor_id,
    du.auth_provider,
    du.profile_completed,
    du.profile_image,
    du.email_verified_at,
    du.password_set_at,
    du.last_login_at,
    COALESCE(v.vendor_name, '') AS vendor_name,
    COALESCE(v.store_name, '') AS store_name,
    COALESCE(v.vendor_status, '') AS vendor_status,
    COALESCE(o_stats.total_orders, 0) AS total_orders,
    COALESCE(o_stats.today_orders, 0) AS today_orders,
    COALESCE(o_stats.active_orders, 0) AS active_orders,
    COALESCE(o_stats.completed_orders, 0) AS completed_orders,
    COALESCE(o_stats.canceled_orders, 0) AS canceled_orders,
    o_stats.last_order_at,
    COALESCE(r_stats.rating_count, 0) AS rating_count,
    COALESCE(r_stats.average_rating, 0) AS average_rating,
    COALESCE(s_stats.message_count, 0) AS support_messages_count,
    COALESCE(s_stats.unread_by_admin, 0) AS unread_support_by_admin,
    COALESCE(s_stats.unread_by_driver, 0) AS unread_support_by_driver,
    s_stats.last_support_at,
    COALESCE(n_stats.total_notifications, 0) AS notifications_count,
    COALESCE(n_stats.unread_notifications, 0) AS unread_notifications,
    n_stats.last_notification_at,
    COALESCE(sh_stats.total_shifts, 0) AS total_shifts,
    COALESCE(sh_stats.active_shift_count, 0) AS active_shift_count,
    sh_stats.last_shift_started_at,
    sh_stats.last_shift_ended_at,
    COALESCE(sh_stats.today_shift_minutes, 0) AS today_shift_minutes,
    COALESCE(sh_stats.total_shift_minutes, 0) AS total_shift_minutes
FROM delivery_users du
LEFT JOIN vendors v
    ON v.vendor_id = du.vendor_id
LEFT JOIN (
    SELECT
        delivery_id AS driver_id,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN DATE(orders_datetime) = CURDATE() THEN 1 ELSE 0 END) AS today_orders,
        SUM(CASE WHEN COALESCE(status, '') NOT IN ('delivered', 'completed', 'canceled', 'cancelled') THEN 1 ELSE 0 END) AS active_orders,
        SUM(CASE WHEN COALESCE(status, '') IN ('delivered', 'completed') THEN 1 ELSE 0 END) AS completed_orders,
        SUM(CASE WHEN COALESCE(status, '') IN ('canceled', 'cancelled') THEN 1 ELSE 0 END) AS canceled_orders,
        MAX(COALESCE(delivered_at, updated_at, orders_datetime)) AS last_order_at
    FROM orders
    WHERE delivery_id IS NOT NULL
      AND delivery_id > 0
    GROUP BY delivery_id
) o_stats ON o_stats.driver_id = du.id
LEFT JOIN (
    SELECT
        driver_id,
        COUNT(*) AS rating_count,
        ROUND(AVG(rating), 2) AS average_rating
    FROM driver_ratings
    GROUP BY driver_id
) r_stats ON r_stats.driver_id = du.id
LEFT JOIN (
    SELECT
        driver_id,
        COUNT(*) AS message_count,
        SUM(CASE WHEN sender_role = 'driver' AND is_read_by_admin = 0 THEN 1 ELSE 0 END) AS unread_by_admin,
        SUM(CASE WHEN sender_role = 'admin' AND is_read_by_driver = 0 THEN 1 ELSE 0 END) AS unread_by_driver,
        MAX(created_at) AS last_support_at
    FROM driver_support_messages
    GROUP BY driver_id
) s_stats ON s_stats.driver_id = du.id
LEFT JOIN (
    SELECT
        driver_id,
        COUNT(*) AS total_notifications,
        SUM(CASE WHEN notification_is_read = 0 THEN 1 ELSE 0 END) AS unread_notifications,
        MAX(notification_created_at) AS last_notification_at
    FROM driver_notifications
    GROUP BY driver_id
) n_stats ON n_stats.driver_id = du.id
LEFT JOIN (
    SELECT
        driver_id,
        COUNT(*) AS total_shifts,
        SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS active_shift_count,
        MAX(shift_started_at) AS last_shift_started_at,
        MAX(shift_ended_at) AS last_shift_ended_at,
        SUM(
            CASE
                WHEN DATE(shift_started_at) = CURDATE() THEN TIMESTAMPDIFF(MINUTE, shift_started_at, COALESCE(shift_ended_at, NOW()))
                ELSE 0
            END
        ) AS today_shift_minutes,
        SUM(TIMESTAMPDIFF(MINUTE, shift_started_at, COALESCE(shift_ended_at, NOW()))) AS total_shift_minutes
    FROM delivery_driver_shift_logs
    GROUP BY driver_id
) sh_stats ON sh_stats.driver_id = du.id
WHERE 1=1
SQL;
}

function fetchDriverBaseRows(PDO $con, ?int $driverId, string $search, string $status, int $limit): array
{
    $sql = buildDriverBaseSql();
    $params = [];

    if ($driverId !== null && $driverId > 0) {
        $sql .= " AND du.id = :driver_id";
        $params[':driver_id'] = $driverId;
    }

    $query = trim($search);
    if ($query !== '') {
        $sql .= "
            AND (
                du.name LIKE :search
                OR du.phone LIKE :search
                OR COALESCE(du.email, '') LIKE :search
                OR COALESCE(du.vehicle_type, '') LIKE :search
                OR COALESCE(du.vehicle_number, '') LIKE :search
                OR CAST(du.id AS CHAR) LIKE :search
                OR COALESCE(v.vendor_name, '') LIKE :search
                OR COALESCE(v.store_name, '') LIKE :search
            )
        ";
        $params[':search'] = '%' . $query . '%';
    }

    $filter = strtolower(trim($status));
    if ($filter !== '' && $filter !== 'all') {
        $onlineExpr = liveStatusExpr();
        switch ($filter) {
            case 'online':
                $sql .= " AND $onlineExpr";
                break;
            case 'offline':
                $sql .= " AND NOT $onlineExpr";
                break;
            case 'complete':
            case 'profile_completed':
                $sql .= " AND du.profile_completed = 1";
                break;
            case 'incomplete':
            case 'profile_pending':
                $sql .= " AND COALESCE(du.profile_completed, 0) = 0";
                break;
            case 'support':
                $sql .= " AND COALESCE(s_stats.message_count, 0) > 0";
                break;
            case 'notifications_off':
                $sql .= " AND COALESCE(du.notifications_enabled, 1) = 0";
                break;
        }
    }

    $sql .= "
        ORDER BY
            is_online DESC,
            COALESCE(du.last_seen_at, du.last_login_at, du.created_at) DESC,
            COALESCE(o_stats.total_orders, 0) DESC,
            COALESCE(r_stats.average_rating, 0) DESC,
            du.name ASC
        LIMIT {$limit}
    ";

    $stmt = $con->prepare($sql);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->execute();

    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function fetchDriverDetail(PDO $con, int $driverId): array
{
    $base = fetchDriverBaseRows($con, $driverId, '', 'all', 1);
    if (empty($base)) {
        return [];
    }

    $driver = $base[0];

    $ordersStmt = $con->prepare("
        SELECT
            o.orders_id AS order_id,
            COALESCE(o.status, 'new') AS status,
            o.orders_status,
            o.orders_datetime,
            o.order_mode,
            o.scheduled_for,
            o.assigned_at,
            o.accepted_at,
            o.arrived_at_restaurant_at,
            o.picked_up_at,
            o.arrived_at_customer_at,
            o.delivered_at,
            o.orders_estimated_minutes,
            o.orders_totalprice,
            o.orders_recipient_name,
            o.orders_recipient_phone,
            o.orders_recipient_address_name,
            o.orders_recipient_address_line,
            o.orders_share_token,
            o.driver_emergency_reason,
            o.driver_emergency_at
        FROM orders o
        WHERE o.delivery_id = ?
        ORDER BY o.orders_id DESC
        LIMIT 20
    ");
    $ordersStmt->execute([$driverId]);
    $orders = $ordersStmt->fetchAll(PDO::FETCH_ASSOC);

    $supportStmt = $con->prepare("
        SELECT
            support_message_id,
            driver_id,
            sender_role,
            message,
            audio_url,
            is_read_by_driver,
            is_read_by_admin,
            created_at,
            updated_at
        FROM driver_support_messages
        WHERE driver_id = ?
        ORDER BY created_at DESC, support_message_id DESC
        LIMIT 20
    ");
    $supportStmt->execute([$driverId]);
    $supportMessages = $supportStmt->fetchAll(PDO::FETCH_ASSOC);

    $notificationsStmt = $con->prepare("
        SELECT
            notification_id,
            driver_id,
            notification_type,
            notification_title,
            notification_body,
            notification_ref_type,
            notification_ref_id,
            notification_payload,
            notification_is_read,
            notification_created_at,
            notification_updated_at
        FROM driver_notifications
        WHERE driver_id = ?
        ORDER BY notification_created_at DESC, notification_id DESC
        LIMIT 20
    ");
    $notificationsStmt->execute([$driverId]);
    $notifications = $notificationsStmt->fetchAll(PDO::FETCH_ASSOC);

    $shiftStmt = $con->prepare("
        SELECT
            shift_log_id,
            driver_id,
            shift_started_at,
            shift_ended_at,
            start_latitude,
            start_longitude,
            end_latitude,
            end_longitude,
            status,
            created_at,
            TIMESTAMPDIFF(MINUTE, shift_started_at, COALESCE(shift_ended_at, NOW())) AS duration_minutes
        FROM delivery_driver_shift_logs
        WHERE driver_id = ?
        ORDER BY shift_started_at DESC, shift_log_id DESC
        LIMIT 20
    ");
    $shiftStmt->execute([$driverId]);
    $shiftLogs = $shiftStmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($driver as $key => $value) {
        if (strpos((string)$key, '_at') !== false || in_array($key, ['last_seen_at', 'created_at', 'last_order_at', 'last_support_at', 'last_notification_at', 'last_shift_started_at', 'last_shift_ended_at'], true)) {
            $driver[$key . '_label'] = safeDateTimeLabel(is_string($value) ? $value : null);
        }
    }

    $driver['profile_image_url'] = resolvePublicMediaUrl($driver['profile_image'] ?? null);
    $driver['latitude_value'] = safeFloat($driver['latitude'] ?? null);
    $driver['longitude_value'] = safeFloat($driver['longitude'] ?? null);
    $driver['live_status_label'] = ((int)($driver['is_online'] ?? 0) === 1) ? 'متصل الآن' : 'غير متصل';
    $driver['display_name'] = trim((string)($driver['driver_name'] ?? '')) !== ''
        ? trim((string)$driver['driver_name'])
        : 'سائق #' . $driverId;
    $driver['display_vehicle'] = trim((string)($driver['vehicle_type'] ?? '')) !== '' && trim((string)($driver['vehicle_number'] ?? '')) !== ''
        ? trim((string)$driver['vehicle_type']) . ' - ' . trim((string)$driver['vehicle_number'])
        : trim((string)($driver['vehicle_type'] ?? $driver['vehicle_number'] ?? 'غير محددة'));

    return [
        'driver' => $driver,
        'recent_orders' => array_map(static function (array $row): array {
            $row['orders_datetime_label'] = safeDateTimeLabel($row['orders_datetime'] ?? null);
            $row['assigned_at_label'] = safeDateTimeLabel($row['assigned_at'] ?? null);
            $row['accepted_at_label'] = safeDateTimeLabel($row['accepted_at'] ?? null);
            $row['delivered_at_label'] = safeDateTimeLabel($row['delivered_at'] ?? null);
            return $row;
        }, $orders),
        'support_messages' => array_map(static function (array $row): array {
            $row['created_at_label'] = safeDateTimeLabel($row['created_at'] ?? null);
            $row['updated_at_label'] = safeDateTimeLabel($row['updated_at'] ?? null);
            $row['audio_url'] = resolvePublicMediaUrl($row['audio_url'] ?? null);
            return $row;
        }, $supportMessages),
        'notifications' => array_map(static function (array $row): array {
            $row['notification_created_at_label'] = safeDateTimeLabel($row['notification_created_at'] ?? null);
            $row['notification_updated_at_label'] = safeDateTimeLabel($row['notification_updated_at'] ?? null);
            return $row;
        }, $notifications),
        'shift_logs' => array_map(static function (array $row): array {
            $row['shift_started_at_label'] = safeDateTimeLabel($row['shift_started_at'] ?? null);
            $row['shift_ended_at_label'] = safeDateTimeLabel($row['shift_ended_at'] ?? null);
            $row['created_at_label'] = safeDateTimeLabel($row['created_at'] ?? null);
            return $row;
        }, $shiftLogs),
    ];
}

function buildSummary(array $rows): array
{
    $summary = [
        'total_count' => count($rows),
        'total_orders_count' => 0,
        'online_count' => 0,
        'offline_count' => 0,
        'profile_completed_count' => 0,
        'active_orders_count' => 0,
        'today_orders_count' => 0,
        'support_messages_count' => 0,
        'unread_support_count' => 0,
        'notifications_count' => 0,
        'unread_notifications_count' => 0,
        'total_shifts_count' => 0,
        'active_shift_count' => 0,
        'today_shift_minutes' => 0,
        'total_shift_minutes' => 0,
        'rating_count' => 0,
        'average_rating' => 0,
    ];

    $ratingNumerator = 0.0;

    foreach ($rows as $row) {
        $isOnline = safeInt($row['is_online'] ?? 0) === 1;
        if ($isOnline) {
            $summary['online_count']++;
        } else {
            $summary['offline_count']++;
        }

        if (safeInt($row['profile_completed'] ?? 0) === 1) {
            $summary['profile_completed_count']++;
        }

        $summary['total_orders_count'] += safeInt($row['total_orders'] ?? 0);
        $summary['active_orders_count'] += safeInt($row['active_orders'] ?? 0);
        $summary['today_orders_count'] += safeInt($row['today_orders'] ?? 0);
        $summary['support_messages_count'] += safeInt($row['support_messages_count'] ?? 0);
        $summary['unread_support_count'] += safeInt($row['unread_support_by_admin'] ?? 0);
        $summary['notifications_count'] += safeInt($row['notifications_count'] ?? 0);
        $summary['unread_notifications_count'] += safeInt($row['unread_notifications'] ?? 0);
        $summary['total_shifts_count'] += safeInt($row['total_shifts'] ?? 0);
        $summary['active_shift_count'] += safeInt($row['active_shift_count'] ?? 0);
        $summary['today_shift_minutes'] += safeInt($row['today_shift_minutes'] ?? 0);
        $summary['total_shift_minutes'] += safeInt($row['total_shift_minutes'] ?? 0);

        $ratingCount = safeInt($row['rating_count'] ?? 0);
        $ratingValue = (float)($row['average_rating'] ?? 0);
        $summary['rating_count'] += $ratingCount;
        $ratingNumerator += $ratingValue * $ratingCount;
    }

    if ($summary['rating_count'] > 0) {
        $summary['average_rating'] = round($ratingNumerator / $summary['rating_count'], 2);
    }

    return $summary;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    respondJson([
        'status' => 'error',
        'message' => 'GET or POST required',
    ], 405);
}

try {
    requireDriverMasterSchema();

    $driverId = (int)($_GET['driver_id'] ?? $_POST['driver_id'] ?? 0);
    $search = trim((string)($_GET['query'] ?? $_POST['query'] ?? ''));
    $status = trim((string)($_GET['status'] ?? $_POST['status'] ?? 'all'));
    $limit = (int)($_GET['limit'] ?? $_POST['limit'] ?? 300);
    if ($limit <= 0 || $limit > 500) {
        $limit = 300;
    }

    if ($driverId > 0) {
        $detail = fetchDriverDetail($con, $driverId);
        if (empty($detail)) {
            respondJson([
                'status' => 'error',
                'message' => 'Driver not found',
            ], 404);
        }

        respondJson([
            'status' => 'success',
            'driver_id' => $driverId,
            'data' => $detail,
            'summary' => [
                'recent_orders_count' => count($detail['recent_orders']),
                'support_messages_count' => count($detail['support_messages']),
                'notifications_count' => count($detail['notifications']),
                'shift_logs_count' => count($detail['shift_logs']),
            ],
        ], 200);
    }

    $rows = fetchDriverBaseRows($con, null, $search, $status, $limit);
    $rows = array_map(static function (array $row): array {
        $row['profile_image_url'] = resolvePublicMediaUrl($row['profile_image'] ?? null);
        $row['latitude_value'] = safeFloat($row['latitude'] ?? null);
        $row['longitude_value'] = safeFloat($row['longitude'] ?? null);
        $row['display_name'] = trim((string)($row['driver_name'] ?? '')) !== ''
            ? trim((string)$row['driver_name'])
            : 'سائق #' . (int)($row['driver_id'] ?? 0);
        $row['display_vehicle'] = trim((string)($row['vehicle_type'] ?? '')) !== '' && trim((string)($row['vehicle_number'] ?? '')) !== ''
            ? trim((string)$row['vehicle_type']) . ' - ' . trim((string)$row['vehicle_number'])
            : trim((string)($row['vehicle_type'] ?? $row['vehicle_number'] ?? 'غير محددة'));
        $row['live_status_label'] = ((int)($row['is_online'] ?? 0) === 1) ? 'متصل الآن' : 'غير متصل';
        $row['last_seen_at_label'] = safeDateTimeLabel($row['last_seen_at'] ?? null);
        $row['created_at_label'] = safeDateTimeLabel($row['created_at'] ?? null);
        $row['last_order_at_label'] = safeDateTimeLabel($row['last_order_at'] ?? null);
        $row['last_support_at_label'] = safeDateTimeLabel($row['last_support_at'] ?? null);
        $row['last_notification_at_label'] = safeDateTimeLabel($row['last_notification_at'] ?? null);
        $row['last_shift_started_at_label'] = safeDateTimeLabel($row['last_shift_started_at'] ?? null);
        $row['last_shift_ended_at_label'] = safeDateTimeLabel($row['last_shift_ended_at'] ?? null);
        return $row;
    }, $rows);

    respondJson([
        'status' => 'success',
        'summary' => buildSummary($rows),
        'data' => $rows,
    ], 200);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], 500);
}
