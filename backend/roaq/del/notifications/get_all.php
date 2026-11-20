<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../connect.php';

if (!function_exists('ensureDriverNotificationsTable')) {
    function ensureDriverNotificationsTable(PDO $con): void
    {
        static $ensured = false;
        if ($ensured) {
            return;
        }

        $con->exec("
            CREATE TABLE IF NOT EXISTS driver_notifications (
                notification_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                driver_id INT(11) NOT NULL,
                notification_type VARCHAR(64) NOT NULL DEFAULT 'general',
                notification_title VARCHAR(255) NOT NULL,
                notification_body TEXT NOT NULL,
                notification_ref_type VARCHAR(64) DEFAULT NULL,
                notification_ref_id INT(11) DEFAULT NULL,
                notification_payload LONGTEXT DEFAULT NULL,
                notification_is_read TINYINT(1) NOT NULL DEFAULT 0,
                notification_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                notification_updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (notification_id),
                KEY idx_driver_notification_driver (driver_id, notification_created_at, notification_id),
                KEY idx_driver_notification_read (driver_id, notification_is_read)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");

        $ensured = true;
    }
}

try {
    ensureDriverNotificationsTable($con);

    $driverId = (int)($_POST['driver_id'] ?? $_GET['driver_id'] ?? 0);
    if ($driverId <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'driver_id is required',
            'data' => [],
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $limit = (int)($_POST['limit'] ?? $_GET['limit'] ?? 150);
    if ($limit <= 0 || $limit > 500) {
        $limit = 150;
    }

    $stmt = $con->prepare("
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
        LIMIT {$limit}
    ");
    $stmt->execute([$driverId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $summary = [
        'total_count' => count($rows),
        'unread_count' => 0,
        'read_count' => 0,
        'orders_count' => 0,
        'support_count' => 0,
        'system_count' => 0,
    ];

    foreach ($rows as $row) {
        $isRead = (int)($row['notification_is_read'] ?? 0) === 1;
        if ($isRead) {
            $summary['read_count']++;
        } else {
            $summary['unread_count']++;
        }

        $type = strtolower(trim((string)($row['notification_type'] ?? 'general')));
        $refType = strtolower(trim((string)($row['notification_ref_type'] ?? '')));
        if (
            $type === 'support' ||
            strpos($type, 'chat') !== false ||
            strpos($type, 'support') !== false ||
            $refType === 'support'
        ) {
            $summary['support_count']++;
        } elseif (
            $refType === 'order' ||
            strpos($type, 'order') !== false ||
            strpos($type, 'delivery') !== false
        ) {
            $summary['orders_count']++;
        } else {
            $summary['system_count']++;
        }
    }

    echo json_encode([
        'status' => 'success',
        'summary' => $summary,
        'data' => $rows,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
