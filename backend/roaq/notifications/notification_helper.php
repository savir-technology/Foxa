<?php

require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/../chat/firebase/send_notification.php';
require_once __DIR__ . '/driver_notification_helper.php';
require_once __DIR__ . '/fcm_token_utils.php';

function notificationOutboxEnabled(): bool
{
    return getenv('ROAQ_NOTIFICATION_OUTBOX') === '1';
}

function enqueueNotificationOutbox(
    PDO $con,
    string $recipientType,
    int $recipientId,
    ?string $topic,
    string $notificationType,
    string $title,
    string $body,
    ?string $refType,
    ?int $refId,
    array $payload = []
): void {
    $stmt = $con->prepare('
        INSERT INTO notification_outbox
            (recipient_type, recipient_id, topic, notification_type, title, body,
             ref_type, ref_id, payload)
        VALUES
            (:recipient_type, :recipient_id, :topic, :notification_type, :title, :body,
             :ref_type, :ref_id, :payload)
        ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP
    ');
    $stmt->execute([
        ':recipient_type' => $recipientType,
        ':recipient_id' => $recipientId,
        ':topic' => $topic,
        ':notification_type' => $notificationType,
        ':title' => $title,
        ':body' => $body,
        ':ref_type' => $refType,
        ':ref_id' => $refId,
        ':payload' => $payload ? json_encode($payload, JSON_UNESCAPED_UNICODE) : null,
    ]);
}

function ensureNotificationsTable(PDO $con): void
{
    static $ensured = false;
    if ($ensured) {
        return;
    }

    $con->exec("
        CREATE TABLE IF NOT EXISTS notifications (
            notification_id INT(11) NOT NULL AUTO_INCREMENT,
            notification_userid INT(11) NOT NULL,
            notification_type VARCHAR(64) NOT NULL DEFAULT 'general',
            notification_title VARCHAR(255) NOT NULL,
            notification_body TEXT NOT NULL,
            notification_ref_type VARCHAR(64) DEFAULT NULL,
            notification_ref_id INT(11) DEFAULT NULL,
            notification_payload LONGTEXT DEFAULT NULL,
            notification_is_read TINYINT(1) NOT NULL DEFAULT 0,
            notification_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (notification_id),
            KEY idx_notification_user (notification_userid),
            KEY idx_notification_created (notification_created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    $ensured = true;
}

function fetchUserFcmToken(PDO $con, int $userId): ?string
{
    $stmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $token = normalizeFcmToken($row['fcm_token'] ?? null);
    return $token !== '' ? $token : null;
}

function storeNotification(
    PDO $con,
    int $userId,
    string $type,
    string $title,
    string $body,
    ?string $refType = null,
    ?int $refId = null,
    array $payload = []
): int {
    ensureNotificationsTable($con);

    $stmt = $con->prepare("
        INSERT INTO notifications (
            notification_userid,
            notification_type,
            notification_title,
            notification_body,
            notification_ref_type,
            notification_ref_id,
            notification_payload
        ) VALUES (
            :uid,
            :type,
            :title,
            :body,
            :ref_type,
            :ref_id,
            :payload
        )
    ");

    $stmt->execute([
        ':uid' => $userId,
        ':type' => $type,
        ':title' => $title,
        ':body' => $body,
        ':ref_type' => $refType,
        ':ref_id' => $refId,
        ':payload' => !empty($payload) ? json_encode($payload, JSON_UNESCAPED_UNICODE) : null,
    ]);

    return (int)$con->lastInsertId();
}

function notifyUser(
    PDO $con,
    int $userId,
    string $type,
    string $title,
    string $body,
    ?string $refType = null,
    ?int $refId = null,
    array $payload = [],
    bool $sendPush = true,
    array $excludeTokens = []
): void {
    if ($userId <= 0) {
        return;
    }

    $notificationId = storeNotification($con, $userId, $type, $title, $body, $refType, $refId, $payload);
    notificationFlowLog('notifyUser() stored notification', [
        'userId' => $userId,
        'notificationId' => $notificationId,
        'type' => $type,
        'sendPush' => $sendPush,
    ]);

    if (!$sendPush) {
        return;
    }

    $token = fetchUserFcmToken($con, $userId);
    if (!$token) {
        notificationFlowLog('notifyUser() no active token', [
            'userId' => $userId,
            'notificationId' => $notificationId,
            'type' => $type,
        ]);
        return;
    }

    $normalizedExcludeTokens = normalizeFcmTokenList($excludeTokens);
    if (!empty($normalizedExcludeTokens) && in_array($token, $normalizedExcludeTokens, true)) {
        notificationFlowLog('notifyUser() skipped excluded token', [
            'userId' => $userId,
            'notificationId' => $notificationId,
            'type' => $type,
            'tokenFingerprint' => fcmTokenFingerprint($token),
            'excludeFingerprints' => array_map('fcmTokenFingerprint', $normalizedExcludeTokens),
        ]);
        return;
    }

    $data = array_merge([
        'type' => $type,
        'notification_id' => (string)$notificationId,
        'ref_type' => $refType ?? '',
        'ref_id' => $refId ? (string)$refId : '',
    ], $payload);

    notificationFlowLog('notifyUser() sending push', [
        'userId' => $userId,
        'destinationRole' => 'user',
        'destinationUserId' => $userId,
        'notificationId' => $notificationId,
        'type' => $type,
        'incomingFcmTokenFingerprint' => fcmTokenFingerprint($token),
        'excludeFingerprints' => array_map('fcmTokenFingerprint', $normalizedExcludeTokens),
        'dataKeys' => array_keys($data),
    ]);

    $result = sendFCM($title, $body, $token, $data);
    $errorCode = strtoupper((string)($result['error_code'] ?? ''));
    notificationFlowLog('notifyUser() push result', [
        'userId' => $userId,
        'destinationRole' => 'user',
        'destinationUserId' => $userId,
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
        notificationFlowLog('notifyUser() clearing invalid token', [
            'userId' => $userId,
            'destinationRole' => 'user',
            'destinationUserId' => $userId,
            'notificationId' => $notificationId,
            'type' => $type,
            'incomingFcmTokenFingerprint' => fcmTokenFingerprint($token),
            'errorCode' => $errorCode,
        ]);
        $clearTokenStmt = $con->prepare(
            "UPDATE users SET fcm_token = NULL WHERE users_id = :id"
        );
        $clearTokenStmt->execute([':id' => $userId]);
    }
}

function broadcastNotification(
    PDO $con,
    string $type,
    string $title,
    string $body,
    ?string $refType = null,
    ?int $refId = null,
    array $payload = [],
    ?int $excludeUserId = null
): void {
    ensureNotificationsTable($con);

    $sql = "SELECT users_id FROM users WHERE users_approve = 1";
    $params = [];

    if ($excludeUserId !== null) {
        $sql .= " AND users_id != ?";
        $params[] = $excludeUserId;
    }

    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $userIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

    foreach ($userIds as $userId) {
        notifyUser(
            $con,
            (int)$userId,
            $type,
            $title,
            $body,
            $refType,
            $refId,
            $payload,
            true
        );
    }
}

if (!function_exists('ensureDashboardWebPushTokensTable')) {
    function ensureDashboardWebPushTokensTable(PDO $con): void
    {
        $con->exec("CREATE TABLE IF NOT EXISTS dashboard_web_push_tokens (
            token_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            role VARCHAR(20) NOT NULL,
            owner_id INT NOT NULL,
            push_token TEXT NOT NULL,
            token_hash CHAR(64) NOT NULL,
            platform VARCHAR(20) NOT NULL DEFAULT 'web',
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (token_id),
            UNIQUE KEY uniq_dashboard_web_push_token (token_hash),
            KEY idx_dashboard_web_push_owner (role, owner_id, is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    }
}

if (!function_exists('fetchDashboardWebPushTokens')) {
    function fetchDashboardWebPushTokens(PDO $con, string $role, ?int $ownerId = null): array
    {
        ensureDashboardWebPushTokensTable($con);
        $sql = 'SELECT token_id, push_token FROM dashboard_web_push_tokens
                WHERE role = :role AND is_active = 1';
        $params = [':role' => $role];
        if ($ownerId !== null) {
            $sql .= ' AND owner_id = :owner_id';
            $params[':owner_id'] = $ownerId;
        }
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }
}

if (!function_exists('sendDashboardWebPush')) {
    function sendDashboardWebPush(
        PDO $con,
        string $role,
        ?int $ownerId,
        string $title,
        string $body,
        array $payload = []
    ): void {
        foreach (fetchDashboardWebPushTokens($con, $role, $ownerId) as $row) {
            $token = trim((string)($row['push_token'] ?? ''));
            if ($token === '') {
                continue;
            }
            $data = array_merge($payload, [
                'role' => $role,
                'owner_id' => (string)($ownerId ?? 0),
            ]);
            $result = sendFCM($title, $body, $token, $data);
            $errorCode = strtoupper((string)($result['error_code'] ?? ''));
            if (empty($result['ok']) && in_array($errorCode, ['UNREGISTERED', 'NOT_FOUND'], true)) {
                $clear = $con->prepare('UPDATE dashboard_web_push_tokens SET is_active = 0 WHERE token_id = :id');
                $clear->execute([':id' => (int)$row['token_id']]);
            }
        }
    }
}

if (!function_exists('notifyMasterWebPush')) {
    function notifyMasterWebPush(
        PDO $con,
        string $type,
        string $title,
        string $body,
        array $payload = []
    ): void {
        sendDashboardWebPush($con, 'master', null, $title, $body, array_merge([
            'type' => $type,
            'screen' => 'notifications',
        ], $payload));
    }
}

if (!function_exists('notifyVendor')) {
    function notifyVendor(
        PDO $con,
        int $vendorId,
        string $type,
        string $title,
        string $body,
        ?string $refType = null,
        ?int $refId = null,
        array $payload = [],
        bool $sendPush = true
    ): void {
        if ($vendorId <= 0) {
            return;
        }

        $payload['vendor_id'] = (string)$vendorId;
        storeNotification($con, 0, $type, $title, $body, $refType, $refId, $payload);

        if ($sendPush) {
            $data = array_merge($payload, [
                'type' => $type,
                'ref_type' => $refType ?? '',
                'ref_id' => $refId ? (string)$refId : '',
                'vendor_id' => (string)$vendorId,
            ]);
            sendFCMToTopic($title, $body, 'vendor_orders_' . $vendorId, $data);
            sendDashboardWebPush($con, 'vendor', $vendorId, $title, $body, $data);
        }

        notifyMasterWebPush($con, $type, $title, $body, $payload);
    }
}
