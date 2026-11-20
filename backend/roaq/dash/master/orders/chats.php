<?php
require_once "../../../connect.php";
require_once __DIR__ . "/../../../notifications/notification_helper.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterOrderChatRequireSchema(): void
{
    $requiredColumns = [
        'chat_id',
        'order_id',
        'chat_scope',
        'sender_role',
        'sender_ref_id',
        'message',
        'audio_url',
        'is_read',
        'created_at',
    ];
    if (!tableExists('order_chat_messages')) {
        respondJson([
            'status' => 'error',
            'message' => 'جدول محادثات الطلبات غير موجود. طبّق migration 20260818_master_chat_tables.sql أولًا.',
        ], 409);
    }
    foreach ($requiredColumns as $column) {
        if (!columnExists('order_chat_messages', $column)) {
            respondJson([
                'status' => 'error',
                'message' => 'بنية محادثات الطلبات غير مكتملة. طبّق migration 20260818_master_chat_tables.sql أولًا.',
            ], 409);
        }
    }
}

function masterOrderChatRows(string $sql, array $params = []): array
{
    global $con;
    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

function masterOrderChatScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $value = $stmt->fetchColumn();
    return $value === false || $value === null ? $fallback : $value;
}

function masterOrderChatNumber($value, int $decimals = 0): string
{
    return number_format((float)$value, $decimals, '.', ',');
}

function masterOrderChatTime(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '--:--' : date('H:i', $timestamp);
}

function masterOrderChatRelative(?string $value): string
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

function masterOrderChatAssetUrl($value, string $folder): string
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

function masterOrderChatPaymentLabel($method): string
{
    $key = strtolower(trim((string)$method));
    if ($key === '2' || str_contains($key, 'wallet') || str_contains($key, 'محفظ')) {
        return 'محفظة';
    }
    if ($key === '1' || str_contains($key, 'visa') || str_contains($key, 'card') || str_contains($key, 'credit') || str_contains($key, 'master') || str_contains($key, 'online') || str_contains($key, 'paymob')) {
        return 'فيزا';
    }
    return 'كاش';
}

function masterOrderChatStatusMeta($status): array
{
    $key = strtolower(trim((string)$status));
    if (in_array($key, ['pending', 'new', '0'], true)) {
        return ['label' => 'جديد', 'color_hex' => '#1A8B4A', 'background_hex' => '#EAF5ED'];
    }
    if (in_array($key, ['preparing', 'accepted', 'heading_to_restaurant', 'arrived_at_restaurant'], true)) {
        return ['label' => 'قيد التحضير', 'color_hex' => '#CA7A00', 'background_hex' => '#FFF4E4'];
    }
    if (in_array($key, ['ready', 'picked_up', 'assigned'], true)) {
        return ['label' => 'جاهز للاستلام', 'color_hex' => '#2563EB', 'background_hex' => '#EAF1FF'];
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
    return ['label' => $key === '' ? 'غير محدد' : (string)$status, 'color_hex' => '#4E5660', 'background_hex' => '#F3F4F6'];
}

function masterOrderChatTypeLabel($type): string
{
    $key = strtolower(trim((string)$type));
    if ($key === '1' || str_contains($key, 'pickup') || str_contains($key, 'self')) {
        return 'استلام ذاتي';
    }
    return 'توصيل';
}

function masterOrderChatMessagePreview(array $row): string
{
    $message = trim((string)($row['last_message'] ?? ''));
    if ($message !== '') {
        return $message;
    }
    if (trim((string)($row['last_audio_url'] ?? '')) !== '') {
        return 'رسالة صوتية';
    }
    return 'لا توجد رسائل بعد';
}

function masterOrderChatSenderLabel(string $role): string
{
    $role = strtolower(trim($role));
    if ($role === 'driver') {
        return 'السائق';
    }
    if ($role === 'user' || $role === 'customer') {
        return 'العميل';
    }
    if ($role === 'admin' || $role === 'support') {
        return 'الدعم';
    }
    return 'النظام';
}

function masterOrderChatBaseSelect(): string
{
    return "
        SELECT
            o.orders_id,
            o.orders_usersid,
            o.delivery_id,
            o.status,
            o.orders_status,
            o.orders_type,
            o.orders_paymentmethod,
            o.payment_method,
            o.orders_totalprice,
            o.orders_datetime,
            o.orders_recipient_name,
            o.orders_recipient_phone,
            COALESCE(o.delivery_address, o.orders_recipient_address_name, a.address_name, '') AS address_label,
            u.users_name,
            u.users_phone,
            du.name AS driver_name,
            du.phone AS driver_phone,
            du.status AS driver_status,
            vo.vendor_id,
            COALESCE(vss.store_name, v.store_name, v.vendor_name, 'FOXA') AS restaurant,
            COALESCE(vss.vendor_logo, v.vendor_logo, '') AS restaurant_logo,
            lm.chat_id AS last_chat_id,
            lm.sender_role AS last_sender_role,
            lm.message AS last_message,
            lm.audio_url AS last_audio_url,
            lm.created_at AS last_message_time,
            COALESCE(mc.total_messages, 0) AS total_messages,
            COALESCE(mc.unread_for_admin, 0) AS unread_for_admin
        FROM orders o
        LEFT JOIN users u ON u.users_id = o.orders_usersid
        LEFT JOIN delivery_users du ON du.id = o.delivery_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        LEFT JOIN (
            SELECT order_id, MAX(chat_id) AS max_chat_id
            FROM order_chat_messages
            WHERE chat_scope = 'order'
            GROUP BY order_id
        ) last_ids ON last_ids.order_id = o.orders_id
        LEFT JOIN order_chat_messages lm ON lm.chat_id = last_ids.max_chat_id
        LEFT JOIN (
            SELECT
                order_id,
                COUNT(*) AS total_messages,
                SUM(CASE WHEN sender_role IN ('user','driver') AND is_read = 0 THEN 1 ELSE 0 END) AS unread_for_admin
            FROM order_chat_messages
            WHERE chat_scope = 'order'
            GROUP BY order_id
        ) mc ON mc.order_id = o.orders_id
    ";
}

function masterOrderChatFormatConversation(array $row): array
{
    $status = masterOrderChatStatusMeta($row['status'] ?? $row['orders_status'] ?? '');
    $customerName = trim((string)($row['orders_recipient_name'] ?? ''));
    if ($customerName === '') {
        $customerName = trim((string)($row['users_name'] ?? ''));
    }
    if ($customerName === '') {
        $customerName = 'عميل';
    }
    $phone = trim((string)($row['orders_recipient_phone'] ?? ''));
    if ($phone === '') {
        $phone = trim((string)($row['users_phone'] ?? ''));
    }
    $driverName = trim((string)($row['driver_name'] ?? ''));
    $hasDriver = (int)($row['delivery_id'] ?? 0) > 0;
    $paymentSource = trim((string)($row['payment_method'] ?? ''));
    if ($paymentSource === '') {
        $paymentSource = (string)($row['orders_paymentmethod'] ?? '');
    }
    return [
        'order_id' => (int)$row['orders_id'],
        'order_no' => '#' . (int)$row['orders_id'],
        'customer_id' => (int)($row['orders_usersid'] ?? 0),
        'customer_name' => $customerName,
        'customer_phone' => $phone,
        'driver_id' => (int)($row['delivery_id'] ?? 0),
        'driver_name' => $driverName !== '' ? $driverName : ($hasDriver ? 'سائق' : 'لم يتم تعيين سائق'),
        'driver_phone' => (string)($row['driver_phone'] ?? ''),
        'driver_status' => (string)($row['driver_status'] ?? ''),
        'restaurant' => (string)($row['restaurant'] ?? 'FOXA'),
        'restaurant_logo_url' => masterOrderChatAssetUrl($row['restaurant_logo'] ?? '', 'upload'),
        'type_label' => masterOrderChatTypeLabel($row['orders_type'] ?? ''),
        'status_label' => $status['label'],
        'status_color_hex' => $status['color_hex'],
        'status_background_hex' => $status['background_hex'],
        'amount_label' => masterOrderChatNumber($row['orders_totalprice'] ?? 0) . ' س',
        'payment_label' => masterOrderChatPaymentLabel($paymentSource),
        'time_label' => masterOrderChatTime($row['last_message_time'] ?? $row['orders_datetime'] ?? null),
        'relative_label' => masterOrderChatRelative($row['last_message_time'] ?? $row['orders_datetime'] ?? null),
        'address_label' => (string)($row['address_label'] ?? ''),
        'last_message' => masterOrderChatMessagePreview($row),
        'last_sender_role' => (string)($row['last_sender_role'] ?? ''),
        'last_sender_label' => masterOrderChatSenderLabel((string)($row['last_sender_role'] ?? '')),
        'last_message_time' => $row['last_message_time'] ?? null,
        'total_messages' => (int)($row['total_messages'] ?? 0),
        'unread_for_admin' => (int)($row['unread_for_admin'] ?? 0),
        'has_driver' => $hasDriver,
        'critical' => !$hasDriver || (int)($row['unread_for_admin'] ?? 0) >= 3,
    ];
}

function masterOrderChatMessages(int $orderId): array
{
    $rows = masterOrderChatRows("
        SELECT
            m.chat_id,
            m.order_id,
            m.sender_role,
            m.sender_ref_id,
            m.message,
            m.audio_url,
            m.is_read,
            m.created_at,
            u.users_name,
            du.name AS driver_name,
            a.admin_name
        FROM order_chat_messages m
        LEFT JOIN users u ON m.sender_role IN ('user','customer') AND u.users_id = m.sender_ref_id
        LEFT JOIN delivery_users du ON m.sender_role = 'driver' AND du.id = m.sender_ref_id
        LEFT JOIN admin a ON m.sender_role IN ('admin','support') AND a.admin_id = m.sender_ref_id
        WHERE m.order_id = :order_id AND m.chat_scope = 'order'
        ORDER BY m.created_at ASC, m.chat_id ASC
    ", [':order_id' => $orderId]);

    $messages = [];
    foreach ($rows as $row) {
        $role = strtolower((string)($row['sender_role'] ?? ''));
        $senderName = trim((string)($row['users_name'] ?? ''));
        if ($role === 'driver') {
            $senderName = trim((string)($row['driver_name'] ?? '')) ?: 'السائق';
        } elseif ($role === 'admin' || $role === 'support') {
            $senderName = trim((string)($row['admin_name'] ?? '')) ?: 'الدعم';
        } elseif ($senderName === '') {
            $senderName = 'العميل';
        }
        $messages[] = [
            'chat_id' => (int)$row['chat_id'],
            'order_id' => (int)$row['order_id'],
            'sender_role' => $role,
            'sender_name' => $senderName,
            'sender_ref_id' => (int)($row['sender_ref_id'] ?? 0),
            'message' => (string)($row['message'] ?? ''),
            'audio_url' => masterOrderChatAssetUrl($row['audio_url'] ?? '', ''),
            'is_read' => (int)($row['is_read'] ?? 0) === 1,
            'created_at' => $row['created_at'],
            'time_label' => masterOrderChatTime($row['created_at'] ?? null),
            'relative_label' => masterOrderChatRelative($row['created_at'] ?? null),
        ];
    }
    return $messages;
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, $_SERVER['REQUEST_METHOD'] === 'POST' ? 'orders.edit' : 'orders.view');
    masterOrderChatRequireSchema();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $payload = json_decode(file_get_contents('php://input') ?: '{}', true);
        if (!is_array($payload)) {
            $payload = $_POST;
        }
        $orderId = (int)($payload['order_id'] ?? 0);
        $message = trim((string)($payload['message'] ?? ''));
        if ($orderId <= 0 || $message === '') {
            respondJson(['status' => 'error', 'message' => 'order_id and message are required'], 400);
        }
        $exists = (int)masterOrderChatScalar("SELECT COUNT(*) FROM orders WHERE orders_id = :order_id", [':order_id' => $orderId], 0);
        if ($exists <= 0) {
            respondJson(['status' => 'error', 'message' => 'order not found'], 404);
        }
        $stmt = $con->prepare("
            INSERT INTO order_chat_messages (
                order_id, chat_scope, sender_role, sender_ref_id, message, is_read
            ) VALUES (
                :order_id, 'order', 'admin', :admin_id, :message, 0
            )
        ");
        $stmt->execute([
            ':order_id' => $orderId,
            ':admin_id' => (int)($admin['admin_id'] ?? 0),
            ':message' => $message,
        ]);
        $messageId = (int)$con->lastInsertId();
        $userId = (int)masterOrderChatScalar("SELECT orders_usersid FROM orders WHERE orders_id = :order_id", [':order_id' => $orderId], 0);
        $notificationAttempted = false;
        $notificationError = null;
        if ($userId > 0 && function_exists('notifyUser')) {
            try {
                $notificationAttempted = true;
                notifyUser(
                    $con,
                    $userId,
                    'order_chat_admin_message',
                    'رسالة جديدة من الدعم',
                    $message,
                    'order_chat',
                    $orderId,
                    [
                        'order_id' => (string)$orderId,
                        'chat_scope' => 'order',
                        'message_id' => (string)$messageId,
                        'sender_role' => 'admin',
                        'sender_ref_id' => (string)((int)($admin['admin_id'] ?? 0)),
                        'screen' => 'order_chat',
                    ],
                    true
                );
            } catch (Throwable $notifyError) {
                $notificationError = $notifyError->getMessage();
            }
        }
        respondJson([
            'status' => 'success',
            'message' => 'sent',
            'data' => [
                'message_id' => $messageId,
                'order_id' => $orderId,
                'messages' => masterOrderChatMessages($orderId),
            ],
            'notification' => [
                'attempted' => $notificationAttempted,
                'user_id' => $userId,
                'error' => $notificationError,
            ],
        ]);
    }

    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = (int)($_GET['limit'] ?? 30);
    if ($limit <= 0 || $limit > 100) {
        $limit = 30;
    }
    $offset = ($page - 1) * $limit;
    $query = trim((string)($_GET['q'] ?? ''));
    $statusFilter = trim((string)($_GET['status'] ?? 'all'));
    $stateFilter = trim((string)($_GET['state'] ?? 'all'));
    $selectedOrderId = (int)($_GET['order_id'] ?? 0);

    $where = ["o.orders_type = 0"];
    $params = [];
    if ($query !== '') {
        $where[] = "(CAST(o.orders_id AS CHAR) LIKE :q OR o.orders_recipient_name LIKE :q OR o.orders_recipient_phone LIKE :q OR u.users_name LIKE :q OR u.users_phone LIKE :q OR du.name LIKE :q OR du.phone LIKE :q)";
        $params[':q'] = '%' . $query . '%';
    }
    if ($statusFilter !== '' && $statusFilter !== 'all') {
        $statusMap = [
            'pending' => ['pending', 'new', '0'],
            'preparing' => ['preparing', 'accepted', 'heading_to_restaurant', 'arrived_at_restaurant'],
            'ready' => ['ready', 'picked_up', 'assigned'],
            'with_driver' => ['with_driver', 'on_driver'],
            'on_way' => ['on_way', 'on_the_way', 'out_for_delivery'],
            'delivered' => ['delivered', 'completed', 'paid', '4'],
            'canceled' => ['canceled', 'cancelled', 'failed', 'rejected'],
            'returned' => ['returned', 'refunded', 'return', 'refund'],
        ];
        if (isset($statusMap[$statusFilter])) {
            $keys = [];
            foreach ($statusMap[$statusFilter] as $index => $value) {
                $key = ':status_' . $index;
                $keys[] = $key;
                $params[$key] = $value;
            }
            $where[] = "COALESCE(o.status, o.orders_status, '') IN (" . implode(',', $keys) . ")";
        }
    }
    if ($stateFilter === 'unread') {
        $where[] = "COALESCE(mc.unread_for_admin, 0) > 0";
    } elseif ($stateFilter === 'critical') {
        $where[] = "(o.delivery_id IS NULL OR COALESCE(mc.unread_for_admin, 0) >= 3)";
    } elseif ($stateFilter === 'with_driver') {
        $where[] = "o.delivery_id IS NOT NULL";
    }

    $whereSql = implode(' AND ', $where);
    $base = masterOrderChatBaseSelect();
    $total = (int)masterOrderChatScalar("
        SELECT COUNT(*) FROM (
            SELECT o.orders_id
            FROM orders o
            LEFT JOIN users u ON u.users_id = o.orders_usersid
            LEFT JOIN delivery_users du ON du.id = o.delivery_id
            LEFT JOIN (
                SELECT
                    order_id,
                    SUM(CASE WHEN sender_role IN ('user','driver') AND is_read = 0 THEN 1 ELSE 0 END) AS unread_for_admin
                FROM order_chat_messages
                WHERE chat_scope = 'order'
                GROUP BY order_id
            ) mc ON mc.order_id = o.orders_id
            WHERE $whereSql
        ) counted
    ", $params, 0);

    $rows = masterOrderChatRows("
        $base
        WHERE $whereSql
        GROUP BY o.orders_id
        ORDER BY COALESCE(lm.created_at, o.orders_datetime) DESC, o.orders_id DESC
        LIMIT $limit OFFSET $offset
    ", $params);

    $conversations = [];
    foreach ($rows as $row) {
        $conversations[] = masterOrderChatFormatConversation($row);
    }
    if ($selectedOrderId <= 0 && !empty($conversations)) {
        $selectedOrderId = (int)$conversations[0]['order_id'];
    }
    $selectedOrder = null;
    if ($selectedOrderId > 0) {
        foreach ($conversations as $conversation) {
            if ((int)$conversation['order_id'] === $selectedOrderId) {
                $selectedOrder = $conversation;
                break;
            }
        }
        if ($selectedOrder === null) {
            $selectedRows = masterOrderChatRows("$base WHERE o.orders_id = :order_id GROUP BY o.orders_id LIMIT 1", [':order_id' => $selectedOrderId]);
            if (!empty($selectedRows)) {
                $selectedOrder = masterOrderChatFormatConversation($selectedRows[0]);
            }
        }
    }

    if ($selectedOrderId > 0) {
        $markStmt = $con->prepare("UPDATE order_chat_messages SET is_read = 1 WHERE order_id = :order_id AND chat_scope = 'order' AND sender_role IN ('user','driver')");
        $markStmt->execute([':order_id' => $selectedOrderId]);
    }

    $statsTotal = (int)masterOrderChatScalar("SELECT COUNT(*) FROM orders WHERE orders_type = 0", [], 0);
    $openConversations = (int)masterOrderChatScalar("SELECT COUNT(DISTINCT order_id) FROM order_chat_messages WHERE chat_scope = 'order'", [], 0);
    $waiting = (int)masterOrderChatScalar("SELECT COUNT(DISTINCT order_id) FROM order_chat_messages WHERE chat_scope = 'order' AND sender_role IN ('user','driver') AND is_read = 0", [], 0);
    $resolvedToday = (int)masterOrderChatScalar("SELECT COUNT(DISTINCT order_id) FROM order_chat_messages WHERE chat_scope = 'order' AND sender_role IN ('admin','support') AND DATE(created_at) = CURDATE()", [], 0);
    $critical = (int)masterOrderChatScalar("
        SELECT COUNT(*) FROM (
            SELECT o.orders_id
            FROM orders o
            LEFT JOIN (
                SELECT order_id, SUM(CASE WHEN sender_role IN ('user','driver') AND is_read = 0 THEN 1 ELSE 0 END) unread_count
                FROM order_chat_messages
                WHERE chat_scope = 'order'
                GROUP BY order_id
            ) m ON m.order_id = o.orders_id
            WHERE o.orders_type = 0 AND (o.delivery_id IS NULL OR COALESCE(m.unread_count, 0) >= 3)
        ) critical_orders
    ", [], 0);

    respondJson([
        'status' => 'success',
        'data' => [
            'server_now' => date('c'),
            'stats' => [
                'total' => $statsTotal,
                'open' => $openConversations,
                'waiting' => $waiting,
                'resolved_today' => $resolvedToday,
                'critical' => $critical,
                'rating' => null,
            ],
            'conversations' => $conversations,
            'selected_order' => $selectedOrder,
            'messages' => $selectedOrderId > 0 ? masterOrderChatMessages($selectedOrderId) : [],
            'pagination' => ['page' => $page, 'limit' => $limit, 'total' => $total],
        ],
    ]);
} catch (Throwable $e) {
    error_log('master order chats failed: ' . $e->getMessage());
    respondJson([
        'status' => 'error',
        'message' => 'Failed to load order chats',
        'error' => $e->getMessage(),
    ], 500);
}
