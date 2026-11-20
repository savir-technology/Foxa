<?php

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

$batchSize = max(1, min(100, (int)($argv[1] ?? 25)));
$claimed = [];

try {
    $con->beginTransaction();
    $stmt = $con->prepare("\n        SELECT *
        FROM notification_outbox
        WHERE (status = 'pending' OR (status = 'processing' AND locked_at < DATE_SUB(NOW(), INTERVAL 5 MINUTE)))
          AND available_at <= NOW()
        ORDER BY event_id
        LIMIT :limit
        FOR UPDATE SKIP LOCKED
    ");
    $stmt->bindValue(':limit', $batchSize, PDO::PARAM_INT);
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($events as $event) {
        $claim = $con->prepare("\n            UPDATE notification_outbox
            SET status = 'processing', attempts = attempts + 1, locked_at = NOW()
            WHERE event_id = :event_id
        ");
        $claim->execute([':event_id' => (int)$event['event_id']]);
        $claimed[] = $event;
    }
    $con->commit();

    foreach ($claimed as $event) {
        try {
            $payload = json_decode((string)($event['payload'] ?? ''), true);
            $payload = is_array($payload) ? $payload : [];
            $type = (string)$event['recipient_type'];
            if ($type === 'user') {
                notifyUser($con, (int)$event['recipient_id'], (string)$event['notification_type'],
                    (string)$event['title'], (string)$event['body'], $event['ref_type'] ?: null,
                    $event['ref_id'] !== null ? (int)$event['ref_id'] : null, $payload, true);
            } elseif ($type === 'vendor') {
                notifyVendor($con, (int)$event['recipient_id'], (string)$event['notification_type'],
                    (string)$event['title'], (string)$event['body'], $event['ref_type'] ?: null,
                    $event['ref_id'] !== null ? (int)$event['ref_id'] : null, $payload, true);
            } elseif ($type === 'topic') {
                sendFCMToTopic((string)$event['title'], (string)$event['body'], (string)$event['topic'], $payload);
            }
            $done = $con->prepare("UPDATE notification_outbox SET status = 'sent', locked_at = NULL WHERE event_id = :event_id");
            $done->execute([':event_id' => (int)$event['event_id']]);
        } catch (Throwable $error) {
            $failed = $con->prepare("\n                UPDATE notification_outbox
                SET status = IF(attempts >= 5, 'failed', 'pending'),
                    available_at = DATE_ADD(NOW(), INTERVAL LEAST(attempts * 30, 900) SECOND),
                    locked_at = NULL, last_error = :last_error
                WHERE event_id = :event_id
            ");
            $failed->execute([
                ':event_id' => (int)$event['event_id'],
                ':last_error' => substr($error->getMessage(), 0, 2000),
            ]);
            error_log('Notification outbox worker failed: ' . $error->getMessage());
        }
    }
    echo json_encode(['claimed' => count($claimed)]);
} catch (Throwable $error) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    error_log('Notification outbox worker transaction failed: ' . $error->getMessage());
    exit(1);
}
