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

        $schemaReady = true;
    }
}

try {
    ensureDriverSupportSchema();

    $limit = (int)($_POST['limit'] ?? $_GET['limit'] ?? 150);
    if ($limit <= 0 || $limit > 500) {
        $limit = 150;
    }

    $stmt = $con->prepare("
        SELECT
            latest.driver_id,
            du.name AS driver_name,
            du.phone AS driver_phone,
            du.email AS driver_email,
            du.vehicle_type,
            du.vehicle_number,
            du.profile_image,
            latest.support_message_id AS last_message_id,
            latest.sender_role AS last_sender_role,
            latest.message AS last_message,
            latest.audio_url AS last_audio_url,
            latest.is_read_by_admin AS last_is_read_by_admin,
            latest.is_read_by_driver AS last_is_read_by_driver,
            latest.created_at AS last_message_at,
            SUM(CASE WHEN all_msgs.sender_role = 'driver' AND all_msgs.is_read_by_admin = 0 THEN 1 ELSE 0 END) AS unread_by_admin,
            SUM(CASE WHEN all_msgs.sender_role = 'admin' AND all_msgs.is_read_by_driver = 0 THEN 1 ELSE 0 END) AS unread_by_driver
        FROM (
            SELECT dm.*
            FROM driver_support_messages dm
            INNER JOIN (
                SELECT driver_id, MAX(support_message_id) AS support_message_id
                FROM driver_support_messages
                GROUP BY driver_id
            ) latest_ids
              ON latest_ids.driver_id = dm.driver_id
             AND latest_ids.support_message_id = dm.support_message_id
        ) latest
        LEFT JOIN delivery_users du ON du.id = latest.driver_id
        LEFT JOIN driver_support_messages all_msgs ON all_msgs.driver_id = latest.driver_id
        GROUP BY
            latest.driver_id,
            du.name,
            du.phone,
            du.email,
            du.vehicle_type,
            du.vehicle_number,
            du.profile_image,
            latest.support_message_id,
            latest.sender_role,
            latest.message,
            latest.audio_url,
            latest.is_read_by_admin,
            latest.is_read_by_driver,
            latest.created_at
        ORDER BY latest.created_at DESC, latest.support_message_id DESC
        LIMIT {$limit}
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $summary = [
        'total_count' => count($rows),
        'unread_by_admin' => 0,
        'unread_by_driver' => 0,
    ];

    foreach ($rows as $row) {
        $summary['unread_by_admin'] += (int)($row['unread_by_admin'] ?? 0);
        $summary['unread_by_driver'] += (int)($row['unread_by_driver'] ?? 0);
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
