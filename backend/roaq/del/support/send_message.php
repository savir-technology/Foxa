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
require_once __DIR__ . '/../../chat/firebase/send_notification.php';
require_once __DIR__ . '/../../notifications/notification_helper.php';

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

    $driverId = (int)($_POST['driver_id'] ?? 0);
    $senderRole = trim((string)($_POST['sender_role'] ?? 'driver'));
    $message = trim((string)($_POST['message'] ?? ''));

    if ($driverId <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'driver_id is required',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($message === '' && empty($_FILES['audio'])) {
        echo json_encode([
            'status' => 'error',
            'message' => 'message or audio is required',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $audioUrl = null;
    if (!empty($_FILES['audio']) && is_uploaded_file($_FILES['audio']['tmp_name'])) {
        $folder = dirname(__DIR__) . '/uploads/driver_support_audio/';
        if (!is_dir($folder)) {
            mkdir($folder, 0777, true);
        }

        $extension = pathinfo($_FILES['audio']['name'] ?? '', PATHINFO_EXTENSION);
        $fileName = 'support_' . $driverId . '_' . time() . ($extension ? '.' . $extension : '.m4a');
        $filePath = $folder . $fileName;
        if (!move_uploaded_file($_FILES['audio']['tmp_name'], $filePath)) {
            echo json_encode([
                'status' => 'error',
                'message' => 'failed to save audio',
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $audioUrl = 'uploads/driver_support_audio/' . $fileName;
    }

    $stmt = $con->prepare("
        INSERT INTO driver_support_messages (
            driver_id,
            sender_role,
            message,
            audio_url,
            is_read_by_driver,
            is_read_by_admin
        ) VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $driverId,
        $senderRole,
        $message,
        $audioUrl,
        $senderRole === 'driver' ? 1 : 0,
        $senderRole === 'admin' ? 1 : 0,
    ]);

    $messageId = (int)$con->lastInsertId();
    $preview = $message !== '' ? $message : 'رسالة صوتية جديدة';

    if ($senderRole === 'driver') {
        sendFCMToTopic(
            'رسالة دعم جديدة من سائق',
            $preview,
            'admin_chat',
            [
                'type' => 'driver_support_message',
                'driver_id' => (string)$driverId,
                'support_message_id' => (string)$messageId,
                'screen' => 'support',
            ]
        );
    } else {
        notifyDriver(
            $con,
            $driverId,
            'support_reply',
            'رد من الدعم الفني',
            $preview,
            'support',
            $messageId,
            [
                'driver_id' => (string)$driverId,
                'support_message_id' => (string)$messageId,
                'sender_role' => $senderRole,
                'screen' => 'support',
            ],
            true
        );
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'sent',
        'data' => [
            'support_message_id' => $messageId,
            'driver_id' => $driverId,
            'sender_role' => $senderRole,
            'message' => $message,
            'audio_url' => $audioUrl,
        ],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
