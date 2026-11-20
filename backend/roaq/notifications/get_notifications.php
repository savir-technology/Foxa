<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

try {
    $user = requireUserAuth();
    $limit = (int)($_GET['limit'] ?? $_POST['limit'] ?? 100);
    $limit = ($limit > 0 && $limit <= 200) ? $limit : 100;
    ensureNotificationsTable($con);
    $stmt = $con->prepare(
        "SELECT notification_id, notification_userid, notification_type,
                notification_title, notification_body, notification_ref_type,
                notification_ref_id, notification_payload, notification_is_read,
                notification_created_at
         FROM notifications
         WHERE notification_userid = :user_id
         ORDER BY notification_created_at DESC, notification_id DESC
         LIMIT $limit"
    );
    $stmt->execute([':user_id' => (int)$user['users_id']]);
    echo json_encode(['status' => 'success', 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC) ?: []], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    error_log('get_notifications.php error: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'server error'], JSON_UNESCAPED_UNICODE);
}
