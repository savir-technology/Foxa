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

if (!function_exists('ensureDriverSupportSchema')) {
    function ensureDriverSupportSchema()
    {
        global $con;
        static $schemaReady = false;

        if ($schemaReady) {
            return;
        }

        try {
            $con->exec("
                CREATE TABLE IF NOT EXISTS driver_support_messages (
                    support_message_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                    driver_id INT(11) NOT NULL,
                    sender_role VARCHAR(32) NOT NULL DEFAULT 'driver',
                    message TEXT NOT NULL,
                    audio_url VARCHAR(255) DEFAULT NULL,
                    is_read_by_driver TINYINT(1) NOT NULL DEFAULT 0,
                    is_read_by_admin TINYINT(1) NOT NULL DEFAULT 0,
                    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (support_message_id),
                    KEY idx_driver_support_driver_created (driver_id, created_at, support_message_id),
                    KEY idx_driver_support_sender (sender_role, driver_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ");
        } catch (Throwable $schemaError) {
            error_log('ensureDriverSupportSchema failed: ' . $schemaError->getMessage());
        }

        $schemaReady = true;
    }
}

try {
    ensureDriverSupportSchema();

    $driverId = (int)($_POST['driver_id'] ?? $_GET['driver_id'] ?? 0);
    if ($driverId <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'driver_id is required',
            'data' => [],
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("
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
        ORDER BY created_at ASC, support_message_id ASC
    ");
    $stmt->execute([$driverId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $unreadByDriver = 0;
    $unreadByAdmin = 0;
    foreach ($rows as $row) {
        if ((int)($row['is_read_by_driver'] ?? 0) === 0 && strtolower((string)($row['sender_role'] ?? '')) === 'admin') {
            $unreadByDriver++;
        }
        if ((int)($row['is_read_by_admin'] ?? 0) === 0 && strtolower((string)($row['sender_role'] ?? '')) === 'driver') {
            $unreadByAdmin++;
        }
    }

    $markRead = trim((string)($_POST['mark_read'] ?? $_GET['mark_read'] ?? '1'));
    if ($markRead !== '0') {
        $update = $con->prepare("
            UPDATE driver_support_messages
            SET is_read_by_driver = 1
            WHERE driver_id = ?
              AND sender_role = 'admin'
              AND is_read_by_driver = 0
        ");
        $update->execute([$driverId]);
    }

    $markAdminRead = trim((string)($_POST['mark_admin_read'] ?? $_GET['mark_admin_read'] ?? '0'));
    if ($markAdminRead !== '0') {
        $updateAdmin = $con->prepare("
            UPDATE driver_support_messages
            SET is_read_by_admin = 1
            WHERE driver_id = ?
              AND sender_role = 'driver'
              AND is_read_by_admin = 0
        ");
        $updateAdmin->execute([$driverId]);
    }

    echo json_encode([
        'status' => 'success',
        'summary' => [
            'total_count' => count($rows),
            'unread_by_driver' => $unreadByDriver,
            'unread_by_admin' => $unreadByAdmin,
        ],
        'data' => $rows,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
