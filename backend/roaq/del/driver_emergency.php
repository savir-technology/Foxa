<?php
include "connect.php";
require_once __DIR__ . '/../notifications/notification_helper.php';

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"], JSON_UNESCAPED_UNICODE);
    exit;
}

$driverId = (int)($_POST['driver_id'] ?? 0);
$orderId = (int)($_POST['order_id'] ?? 0);
$reason = trim((string)($_POST['reason'] ?? ''));

if ($driverId <= 0 || $orderId <= 0 || $reason === '') {
    echo json_encode([
        "status" => "error",
        "message" => "driver_id, order_id and reason are required",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function ensureDriverEmergencySchema(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS delivery_driver_emergency_reports (
            emergency_report_id BIGINT NOT NULL AUTO_INCREMENT,
            driver_id INT NOT NULL,
            order_id INT NOT NULL,
            reason VARCHAR(255) NOT NULL,
            status VARCHAR(24) NOT NULL DEFAULT 'active',
            reported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            resolved_at DATETIME DEFAULT NULL,
            resolved_by INT DEFAULT NULL,
            resolution_note VARCHAR(255) DEFAULT NULL,
            PRIMARY KEY (emergency_report_id),
            KEY idx_driver_emergency_driver (driver_id, reported_at),
            KEY idx_driver_emergency_order (order_id, reported_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    $columns = [
        'status' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN status VARCHAR(24) NOT NULL DEFAULT 'active' AFTER reason",
        'resolved_at' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolved_at DATETIME DEFAULT NULL AFTER reported_at",
        'resolved_by' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolved_by INT DEFAULT NULL AFTER resolved_at",
        'resolution_note' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolution_note VARCHAR(255) DEFAULT NULL AFTER resolved_by",
    ];
    foreach ($columns as $column => $sql) {
        $check = $con->prepare("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'delivery_driver_emergency_reports' AND COLUMN_NAME = ?");
        $check->execute([$column]);
        if ((int)$check->fetchColumn() === 0) {
            $con->exec($sql);
        }
    }
}

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

function fetchOrderContext(PDO $con, int $orderId): ?array
{
    $stmt = $con->prepare("
        SELECT
            orders_id,
            orders_usersid,
            delivery_id,
            COALESCE(driver_emergency_reason, '') AS driver_emergency_reason
        FROM orders
        WHERE orders_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return $row ?: null;
}

function insertOrderChatMessage(
    PDO $con,
    int $orderId,
    string $chatScope,
    int $senderRefId,
    string $message
): void {
    $stmt = $con->prepare("
        INSERT INTO order_chat_messages (
            order_id,
            chat_scope,
            sender_role,
            sender_ref_id,
            message,
            audio_url
        ) VALUES (?, ?, 'driver', ?, ?, NULL)
    ");
    $stmt->execute([
        $orderId,
        $chatScope,
        $senderRefId,
        $message,
    ]);
}

try {
    ensureDriverEmergencySchema($con);
    ensureOrderChatSchema($con);

    $order = fetchOrderContext($con, $orderId);
    if (!$order) {
        echo json_encode([
            "status" => "error",
            "message" => "order not found",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $assignedDriverId = (int)($order['delivery_id'] ?? 0);
    if ($assignedDriverId > 0 && $assignedDriverId !== $driverId) {
        echo json_encode([
            "status" => "error",
            "message" => "order is not assigned to this driver",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $chatMessage = '🚨 طارئ من السائق: ' . $reason;
    $chatScopes = ['order', 'restaurant', 'master'];

    $con->beginTransaction();

    $insertReport = $con->prepare("
        INSERT INTO delivery_driver_emergency_reports (
            driver_id,
            order_id,
            reason,
            reported_at
        ) VALUES (?, ?, ?, NOW())
    ");
    $insertReport->execute([$driverId, $orderId, $reason]);

    $updateOrder = $con->prepare("
        UPDATE orders
        SET driver_emergency_reason = ?,
            driver_emergency_at = NOW()
        WHERE orders_id = ?
    ");
    $updateOrder->execute([$reason, $orderId]);

    foreach ($chatScopes as $scope) {
        insertOrderChatMessage($con, $orderId, $scope, $driverId, $chatMessage);
    }

    $con->commit();

    try {
        $customerId = (int)($order['orders_usersid'] ?? 0);
        if ($customerId > 0) {
            notifyUser(
                $con,
                $customerId,
                'driver_emergency',
                'تنبيه طارئ في الطلب',
                'وصلت رسالة طوارئ من السائق على الطلب #' . $orderId . ': ' . $reason,
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'reason' => $reason,
                    'chat_scopes' => implode(',', $chatScopes),
                ],
                true
            );
        }
    } catch (Throwable $notificationError) {
        // Keep the emergency report successful even if push delivery fails.
    }

    echo json_encode([
        "status" => "success",
        "message" => "Emergency reported",
        "chat_scopes" => $chatScopes,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    $line = sprintf(
        "[%s] driver_id=%d order_id=%d reason=%s error=%s\n",
        date('Y-m-d H:i:s'),
        $driverId,
        $orderId,
        $reason,
        $e->getMessage()
    );
    @file_put_contents(__DIR__ . '/driver_emergency.log', $line, FILE_APPEND);

    echo json_encode([
        "status" => "error",
        "message" => "تعذر إرسال رسالة الطوارئ",
    ], JSON_UNESCAPED_UNICODE);
}
