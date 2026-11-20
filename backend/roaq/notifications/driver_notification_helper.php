<?php

require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/../chat/firebase/send_notification.php';
require_once __DIR__ . '/fcm_token_utils.php';

if (!function_exists('ensureDriverNotificationsTable')) {
    function ensureDriverNotificationsTable(PDO $con): void
    {
        static $ensured = false;
        if ($ensured) {
            return;
        }

        try {
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
        } catch (Throwable $schemaError) {
            error_log('ensureDriverNotificationsTable failed: ' . $schemaError->getMessage());
        }

        $ensured = true;
    }
}

if (!function_exists('fetchDriverPushTokens')) {
    function fetchDriverPushTokens(PDO $con, int $driverId): array
    {
        $stmt = $con->prepare("
            SELECT push_token
            FROM delivery_driver_push_tokens
            WHERE driver_id = ?
              AND is_active = 1
            ORDER BY updated_at DESC, created_at DESC
        ");
        $stmt->execute([$driverId]);
        $tokens = $stmt->fetchAll(PDO::FETCH_COLUMN);
        if (!is_array($tokens)) {
            return [];
        }

        return normalizeFcmTokenList($tokens);
    }
}

if (!function_exists('storeDriverNotification')) {
    function storeDriverNotification(
        PDO $con,
        int $driverId,
        string $type,
        string $title,
        string $body,
        ?string $refType = null,
        ?int $refId = null,
        array $payload = []
    ): int {
        ensureDriverNotificationsTable($con);

        $stmt = $con->prepare("
            INSERT INTO driver_notifications (
                driver_id,
                notification_type,
                notification_title,
                notification_body,
                notification_ref_type,
                notification_ref_id,
                notification_payload
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $driverId,
            $type,
            $title,
            $body,
            $refType,
            $refId,
            !empty($payload) ? json_encode($payload, JSON_UNESCAPED_UNICODE) : null,
        ]);

        return (int)$con->lastInsertId();
    }
}

if (!function_exists('notifyDriver')) {
    function notifyDriver(
        PDO $con,
        int $driverId,
        string $type,
        string $title,
        string $body,
        ?string $refType = null,
        ?int $refId = null,
        array $payload = [],
        bool $sendPush = true,
        array $excludeTokens = []
    ): void {
        if ($driverId <= 0) {
            return;
        }

        $notificationId = storeDriverNotification(
            $con,
            $driverId,
            $type,
            $title,
            $body,
            $refType,
            $refId,
            $payload
        );
        notificationFlowLog('notifyDriver() stored notification', [
            'driverId' => $driverId,
            'notificationId' => $notificationId,
            'type' => $type,
            'sendPush' => $sendPush,
        ]);

        if (!$sendPush || !function_exists('sendFCM')) {
            return;
        }

        $tokens = fetchDriverPushTokens($con, $driverId);
        $normalizedExcludeTokens = normalizeFcmTokenList($excludeTokens);
        if (!empty($normalizedExcludeTokens)) {
            $excludeMap = array_fill_keys($normalizedExcludeTokens, true);
            $tokens = array_values(array_filter($tokens, static function (string $token) use ($excludeMap): bool {
                return !isset($excludeMap[$token]);
            }));
        }
        if (empty($tokens)) {
            notificationFlowLog('notifyDriver() no eligible tokens', [
                'driverId' => $driverId,
                'destinationRole' => 'driver',
                'destinationUserId' => $driverId,
                'notificationId' => $notificationId,
                'type' => $type,
                'excludeFingerprints' => array_map('fcmTokenFingerprint', $normalizedExcludeTokens),
            ]);
            return;
        }

        $data = array_merge([
            'type' => $type,
            'notification_id' => (string)$notificationId,
            'ref_type' => $refType ?? '',
            'ref_id' => $refId ? (string)$refId : '',
            'driver_id' => (string)$driverId,
        ], $payload);

        foreach ($tokens as $token) {
            try {
                notificationFlowLog('notifyDriver() sending push', [
                    'driverId' => $driverId,
                    'destinationRole' => 'driver',
                    'destinationUserId' => $driverId,
                    'notificationId' => $notificationId,
                    'type' => $type,
                    'incomingFcmTokenFingerprint' => fcmTokenFingerprint($token),
                    'excludeFingerprints' => array_map('fcmTokenFingerprint', $normalizedExcludeTokens),
                    'dataKeys' => array_keys($data),
                ]);
                $result = sendFCM($title, $body, $token, $data);
                $errorCode = strtoupper((string)($result['error_code'] ?? ''));
                notificationFlowLog('notifyDriver() push result', [
                    'driverId' => $driverId,
                    'destinationRole' => 'driver',
                    'destinationUserId' => $driverId,
                    'notificationId' => $notificationId,
                    'type' => $type,
                    'incomingFcmTokenFingerprint' => fcmTokenFingerprint($token),
                    'ok' => !empty($result['ok']),
                    'httpCode' => (int)($result['http_code'] ?? 0),
                    'errorCode' => $errorCode,
                ]);
                if (
                    empty($result['ok']) &&
                    in_array($errorCode, ['SENDER_ID_MISMATCH', 'UNREGISTERED', 'NOT_FOUND'], true)
                ) {
                    notificationFlowLog('notifyDriver() deactivating invalid token', [
                        'driverId' => $driverId,
                        'destinationRole' => 'driver',
                        'destinationUserId' => $driverId,
                        'notificationId' => $notificationId,
                        'type' => $type,
                        'incomingFcmTokenFingerprint' => fcmTokenFingerprint($token),
                        'errorCode' => $errorCode,
                    ]);
                    $deactivateStmt = $con->prepare("
                        UPDATE delivery_driver_push_tokens
                        SET is_active = 0,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE push_token = ?
                    ");
                    $deactivateStmt->execute([$token]);
                }
            } catch (Throwable $pushError) {
                error_log('notifyDriver push failed for driver ' . $driverId . ': ' . $pushError->getMessage());
                notificationFlowLog('notifyDriver() push exception', [
                    'driverId' => $driverId,
                    'destinationRole' => 'driver',
                    'destinationUserId' => $driverId,
                    'notificationId' => $notificationId,
                    'type' => $type,
                    'incomingFcmTokenFingerprint' => fcmTokenFingerprint($token),
                    'error' => $pushError->getMessage(),
                ]);
            }
        }
    }
}
