<?php

require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/../chat/firebase/send_notification.php';

/** Compatibility service for legacy callers. Uses the canonical notifications schema. */
function notifyUser(
    int $userId,
    string $title,
    string $body,
    string $type = 'chat',
    array $meta = [],
    ?string $eventKey = null
): bool {
    global $con;

    if ($userId <= 0 || trim($title) === '' || trim($body) === '') {
        return false;
    }

    try {
        $eventKey = $eventKey !== null ? trim($eventKey) : null;
        if ($eventKey !== null && $eventKey !== '') {
            $check = $con->prepare(
                "SELECT notification_id FROM notifications
                 WHERE notification_userid = :user_id
                   AND JSON_UNQUOTE(JSON_EXTRACT(notification_payload, '$._event_key')) = :event_key
                 LIMIT 1"
            );
            $check->execute([':user_id' => $userId, ':event_key' => $eventKey]);
            if ($check->fetch(PDO::FETCH_ASSOC)) {
                return true;
            }
        }

        $payload = $meta;
        if ($eventKey !== null && $eventKey !== '') {
            $payload['_event_key'] = $eventKey;
        }

        $insert = $con->prepare(
            'INSERT INTO notifications
                (notification_userid, notification_type, notification_title,
                 notification_body, notification_payload)
             VALUES (:user_id, :type, :title, :body, :payload)'
        );
        $insert->execute([
            ':user_id' => $userId,
            ':type' => $type,
            ':title' => $title,
            ':body' => $body,
            ':payload' => $payload !== []
                ? json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
                : null,
        ]);

        $notificationId = (int)$con->lastInsertId();
        $tokenQuery = $con->prepare('SELECT fcm_token FROM users WHERE users_id = :id LIMIT 1');
        $tokenQuery->execute([':id' => $userId]);
        $token = trim((string)$tokenQuery->fetchColumn());
        if ($token !== '') {
            $data = array_merge($meta, [
                'type' => $type,
                'notification_id' => (string)$notificationId,
            ]);
            $result = @sendFCM($title, $body, $token, $data);
            $errorCode = strtoupper((string)($result['error_code'] ?? ''));
            if (empty($result['ok']) && in_array($errorCode, ['SENDER_ID_MISMATCH', 'UNREGISTERED', 'NOT_FOUND'], true)) {
                $clear = $con->prepare('UPDATE users SET fcm_token = NULL WHERE users_id = :id');
                $clear->execute([':id' => $userId]);
            }
        }

        return true;
    } catch (Throwable $e) {
        error_log('notifyUser error: ' . $e->getMessage());
        return false;
    }
}

function notifyAllUsers(
    string $title,
    string $body,
    string $type = 'contract',
    array $meta = [],
    ?string $eventKeyPrefix = null
): int {
    global $con;
    $count = 0;
    try {
        $stmt = $con->query('SELECT users_id FROM users WHERE users_approve = 1');
        foreach (($stmt ? $stmt->fetchAll(PDO::FETCH_COLUMN) : []) as $uid) {
            $uid = (int)$uid;
            if ($uid > 0 && notifyUser($uid, $title, $body, $type, $meta, $eventKeyPrefix ? $eventKeyPrefix . '_' . $uid : null)) {
                $count++;
            }
        }
    } catch (Throwable $e) {
        error_log('notifyAllUsers error: ' . $e->getMessage());
    }
    return $count;
}
