<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

    $driverId = (int)($_POST['driver_id'] ?? 0);
    $notificationId = (int)($_POST['notification_id'] ?? 0);

    if ($driverId <= 0 || $notificationId <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'driver_id and notification_id are required',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("
        UPDATE driver_notifications
        SET notification_is_read = 1
        WHERE notification_id = ?
          AND driver_id = ?
    ");
    $stmt->execute([$notificationId, $driverId]);

    echo json_encode([
        'status' => 'success',
        'affected_rows' => $stmt->rowCount(),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
