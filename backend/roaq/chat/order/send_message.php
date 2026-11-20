<?php
header('Content-Type: application/json; charset=utf-8');
include "../../connect.php";
require_once __DIR__ . '/../../notifications/notification_helper.php';

function ensureOrderChatSchema(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS order_chat_messages (
            chat_id BIGINT NOT NULL AUTO_INCREMENT,
            order_id INT NOT NULL,
            chat_scope VARCHAR(32) NOT NULL DEFAULT 'order',
            sender_role VARCHAR(32) NOT NULL,
            sender_ref_id INT NOT NULL,
            message TEXT NOT NULL,
            audio_url VARCHAR(255) DEFAULT NULL,
            is_read TINYINT(1) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (chat_id),
            KEY idx_order_scope_created (order_id, chat_scope, created_at),
            KEY idx_sender_ref (sender_role, sender_ref_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

function normalizeOrderChatSenderRole(string $senderRole): string
{
    $normalized = strtolower(trim($senderRole));
    if (in_array($normalized, ['user', 'customer', 'client'], true)) {
        return 'user';
    }

    if (in_array($normalized, ['driver', 'delivery', 'courier'], true)) {
        return 'driver';
    }

    return '';
}

function collapseWhitespace(string $text): string
{
    $collapsed = preg_replace('/\s+/u', ' ', trim($text));
    if (!is_string($collapsed)) {
        return trim($text);
    }

    return trim($collapsed);
}

function truncateText(string $text, int $limit = 80): string
{
    $text = collapseWhitespace($text);
    if ($text === '') {
        return '';
    }

    $length = function_exists('mb_strlen') ? mb_strlen($text, 'UTF-8') : strlen($text);
    if ($length <= $limit) {
        return $text;
    }

    $sliceLength = max(0, $limit - 3);
    if (function_exists('mb_substr')) {
        return mb_substr($text, 0, $sliceLength, 'UTF-8') . '...';
    }

    return substr($text, 0, $sliceLength) . '...';
}

function buildMessagePreview(string $message, ?string $audioUrl): string
{
    $preview = truncateText($message);
    if ($preview !== '') {
        return $preview;
    }

    if (trim((string)$audioUrl) !== '') {
        return 'رسالة صوتية';
    }

    return 'رسالة جديدة';
}

function fetchOrderChatContext(PDO $con, int $orderId): ?array
{
    $stmt = $con->prepare("
        SELECT
            o.orders_id,
            o.orders_usersid,
            o.delivery_id,
            o.status,
            o.orders_status,
            o.orders_datetime,
            o.orders_totalprice,
            o.orders_gift_message,
            o.orders_delivery_note,
            o.orders_share_token,
            o.order_mode,
            o.scheduled_for,
            o.orders_estimated_minutes,
            o.orders_recipient_name,
            o.orders_recipient_phone,
            o.orders_recipient_label,
            o.orders_recipient_address_name,
            o.orders_recipient_address_line,
            o.orders_recipient_location_note,
            o.orders_recipient_lat,
            o.orders_recipient_lng,
            COALESCE(o.delivery_address, o.orders_recipient_address_name, a.address_name, '') AS delivery_address,
            a.address_id,
            a.address_usersid,
            a.address_name,
            a.address_city,
            a.address_street,
            a.address_lat,
            a.address_long,
            vo.vendor_id,
            COALESCE(vss.store_name, v.store_name) AS store_name,
            COALESCE(vss.vendor_name, v.vendor_name) AS vendor_name,
            COALESCE(vss.vendor_logo, v.vendor_logo) AS vendor_logo,
            vss.store_banner_url,
            COALESCE(vss.vendor_description, v.vendor_description) AS vendor_description,
            COALESCE(vss.store_address, '') AS store_address
        FROM orders o
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        WHERE o.orders_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row ?: null;
}

function resolveOrderChatRecipient(array $order, string $senderRole): array
{
    if ($senderRole === 'user') {
        return [
            'destination_role' => 'driver',
            'destination_id' => (int)($order['delivery_id'] ?? 0),
        ];
    }

    if ($senderRole === 'driver') {
        return [
            'destination_role' => 'user',
            'destination_id' => (int)($order['orders_usersid'] ?? 0),
        ];
    }

    return [
        'destination_role' => '',
        'destination_id' => 0,
    ];
}

ensureOrderChatSchema($con);

$orderId = (int)($_POST['order_id'] ?? 0);
$chatScope = trim((string)($_POST['chat_scope'] ?? 'order'));
$senderRoleInput = trim((string)($_POST['sender_role'] ?? 'driver'));
$senderRefId = (int)($_POST['sender_ref_id'] ?? 0);
$message = trim((string)($_POST['message'] ?? ''));

if ($orderId <= 0 || $senderRefId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "order_id and sender_ref_id are required",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($message === '' && empty($_FILES['audio'])) {
    echo json_encode([
        "status" => "error",
        "message" => "message or audio is required",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$order = fetchOrderChatContext($con, $orderId);
if (!$order) {
    echo json_encode([
        "status" => "error",
        "message" => "order not found",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$senderRole = normalizeOrderChatSenderRole($senderRoleInput);
if ($senderRole === '') {
    notificationFlowLog('order_chat_message invalid sender role', [
        'orderId' => $orderId,
        'senderRoleInput' => $senderRoleInput,
        'senderRefId' => $senderRefId,
    ]);
}

$audioUrl = null;
if (!empty($_FILES['audio']) && is_uploaded_file($_FILES['audio']['tmp_name'])) {
    $folder = dirname(__DIR__, 2) . "/uploads/order_chat_audio/";
    if (!is_dir($folder)) {
        mkdir($folder, 0777, true);
    }

    $extension = pathinfo($_FILES['audio']['name'] ?? '', PATHINFO_EXTENSION);
    $fileName = 'chat_' . $orderId . '_' . time() . ($extension ? '.' . $extension : '.m4a');
    $targetPath = $folder . $fileName;
    if (!move_uploaded_file($_FILES['audio']['tmp_name'], $targetPath)) {
        echo json_encode([
            "status" => "error",
            "message" => "failed to save audio",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $audioUrl = "uploads/order_chat_audio/" . $fileName;
}

try {
    $stmt = $con->prepare("
        INSERT INTO order_chat_messages (
            order_id,
            chat_scope,
            sender_role,
            sender_ref_id,
            message,
            audio_url
        ) VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $orderId,
        $chatScope,
        $senderRole !== '' ? $senderRole : $senderRoleInput,
        $senderRefId,
        $message,
        $audioUrl,
    ]);

    $messageId = (int)$con->lastInsertId();
    notificationFlowLog('order_chat_message stored', [
        'orderId' => $orderId,
        'messageId' => $messageId,
        'chatScope' => $chatScope,
        'senderRole' => $senderRole !== '' ? $senderRole : $senderRoleInput,
        'senderRefId' => $senderRefId,
        'hasAudio' => $audioUrl !== null,
    ]);

    $resolvedSenderRole = $senderRole;
    $expectedSenderId = $resolvedSenderRole === 'user'
        ? (int)($order['orders_usersid'] ?? 0)
        : ($resolvedSenderRole === 'driver'
            ? (int)($order['delivery_id'] ?? 0)
            : 0);

    if ($resolvedSenderRole !== '' && $expectedSenderId > 0 && $expectedSenderId !== $senderRefId) {
        notificationFlowLog('order_chat_message sender mismatch', [
            'orderId' => $orderId,
            'messageId' => $messageId,
            'senderRole' => $resolvedSenderRole,
            'senderRefId' => $senderRefId,
            'expectedSenderId' => $expectedSenderId,
        ]);
    }

    $recipient = resolveOrderChatRecipient($order, $resolvedSenderRole);
    $destinationRole = $recipient['destination_role'];
    $destinationId = (int)($recipient['destination_id'] ?? 0);
    $preview = buildMessagePreview($message, $audioUrl);
    $title = $destinationRole === 'driver'
        ? 'رسالة جديدة من العميل'
        : ($destinationRole === 'user'
            ? 'رسالة جديدة من السائق'
            : 'رسالة جديدة في الطلب');
    $body = 'الطلب #' . $orderId . ': ' . $preview;

    notificationFlowLog('order_chat_message recipient resolved', [
        'orderId' => $orderId,
        'messageId' => $messageId,
        'senderRole' => $resolvedSenderRole,
        'senderRefId' => $senderRefId,
        'destinationRole' => $destinationRole,
        'destinationId' => $destinationId,
        'orderCustomerId' => (int)($order['orders_usersid'] ?? 0),
        'orderDriverId' => (int)($order['delivery_id'] ?? 0),
    ]);

    $notificationAttempted = false;
    $notificationDispatchError = null;
    try {
        if ($destinationRole === 'driver' && $destinationId > 0) {
            $notificationAttempted = true;
            notifyDriver(
                $con,
                $destinationId,
                'order_chat_message',
                $title,
                $body,
                'order_chat',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'chat_scope' => $chatScope,
                    'message_id' => (string)$messageId,
                    'sender_role' => $resolvedSenderRole,
                    'sender_ref_id' => (string)$senderRefId,
                    'receiver_role' => 'driver',
                    'receiver_id' => (string)$destinationId,
                    'destination_role' => 'driver',
                    'destination_user_id' => (string)$destinationId,
                    'screen' => 'order_chat',
                    'order_status' => (string)($order['status'] ?? ''),
                    'orders_status' => (string)($order['orders_status'] ?? ''),
                    'orders_datetime' => (string)($order['orders_datetime'] ?? ''),
                    'orders_totalprice' => (string)($order['orders_totalprice'] ?? ''),
                    'orders_usersid' => (string)($order['orders_usersid'] ?? ''),
                    'delivery_id' => (string)($order['delivery_id'] ?? ''),
                    'store_name' => (string)($order['store_name'] ?? ''),
                    'vendor_name' => (string)($order['vendor_name'] ?? ''),
                    'vendor_logo' => (string)($order['vendor_logo'] ?? ''),
                    'store_banner_url' => (string)($order['store_banner_url'] ?? ''),
                    'vendor_description' => (string)($order['vendor_description'] ?? ''),
                    'store_address' => (string)($order['store_address'] ?? ''),
                    'delivery_address' => (string)($order['delivery_address'] ?? ''),
                    'orders_recipient_address_name' => (string)($order['orders_recipient_address_name'] ?? ''),
                    'orders_recipient_address_line' => (string)($order['orders_recipient_address_line'] ?? ''),
                    'orders_recipient_location_note' => (string)($order['orders_recipient_location_note'] ?? ''),
                ],
                true
            );
        } elseif ($destinationRole === 'user' && $destinationId > 0) {
            $notificationAttempted = true;
            notifyUser(
                $con,
                $destinationId,
                'order_chat_message',
                $title,
                $body,
                'order_chat',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'chat_scope' => $chatScope,
                    'message_id' => (string)$messageId,
                    'sender_role' => $resolvedSenderRole,
                    'sender_ref_id' => (string)$senderRefId,
                    'receiver_role' => 'user',
                    'receiver_id' => (string)$destinationId,
                    'destination_role' => 'user',
                    'destination_user_id' => (string)$destinationId,
                    'screen' => 'order_chat',
                    'order_status' => (string)($order['status'] ?? ''),
                    'orders_status' => (string)($order['orders_status'] ?? ''),
                    'orders_datetime' => (string)($order['orders_datetime'] ?? ''),
                    'orders_totalprice' => (string)($order['orders_totalprice'] ?? ''),
                    'orders_usersid' => (string)($order['orders_usersid'] ?? ''),
                    'delivery_id' => (string)($order['delivery_id'] ?? ''),
                    'store_name' => (string)($order['store_name'] ?? ''),
                    'vendor_name' => (string)($order['vendor_name'] ?? ''),
                    'vendor_logo' => (string)($order['vendor_logo'] ?? ''),
                    'store_banner_url' => (string)($order['store_banner_url'] ?? ''),
                    'vendor_description' => (string)($order['vendor_description'] ?? ''),
                    'store_address' => (string)($order['store_address'] ?? ''),
                    'delivery_address' => (string)($order['delivery_address'] ?? ''),
                    'orders_recipient_address_name' => (string)($order['orders_recipient_address_name'] ?? ''),
                    'orders_recipient_address_line' => (string)($order['orders_recipient_address_line'] ?? ''),
                    'orders_recipient_location_note' => (string)($order['orders_recipient_location_note'] ?? ''),
                ],
                true
            );
        } else {
            notificationFlowLog('order_chat_message push skipped', [
                'orderId' => $orderId,
                'messageId' => $messageId,
                'senderRole' => $resolvedSenderRole,
                'senderRefId' => $senderRefId,
                'destinationRole' => $destinationRole,
                'destinationId' => $destinationId,
                'reason' => $destinationRole === ''
                    ? 'unknown sender role'
                    : 'missing destination id',
            ]);
        }
    } catch (Throwable $notificationError) {
        $notificationDispatchError = $notificationError->getMessage();
        notificationFlowLog('order_chat_message notification dispatch failed', [
            'orderId' => $orderId,
            'messageId' => $messageId,
            'senderRole' => $resolvedSenderRole,
            'senderRefId' => $senderRefId,
            'destinationRole' => $destinationRole,
            'destinationId' => $destinationId,
            'error' => $notificationDispatchError,
        ]);
    }

    echo json_encode([
        "status" => "success",
        "message" => "sent",
        "data" => [
            "order_id" => $orderId,
            "chat_scope" => $chatScope,
            "sender_role" => $senderRole !== '' ? $senderRole : $senderRoleInput,
            "sender_ref_id" => $senderRefId,
            "message" => $message,
            "audio_url" => $audioUrl,
            "message_id" => $messageId,
        ],
        "notification" => [
            "attempted" => $notificationAttempted,
            "destination_role" => $destinationRole,
            "destination_id" => $destinationId,
            "ref_type" => "order_chat",
            "error" => $notificationDispatchError,
        ],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
?>
