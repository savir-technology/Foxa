<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

try {
    $user = requireUserAuth();
    ensureNotificationsTable($con);
    $stmt = $con->prepare(
        'SELECT COUNT(*) FROM notifications
         WHERE notification_userid = :user_id AND notification_is_read = 0'
    );
    $stmt->execute([':user_id' => (int)$user['users_id']]);
    echo json_encode(['status' => 'success', 'unread' => (int)$stmt->fetchColumn()], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    error_log('unread_count.php error: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'server error'], JSON_UNESCAPED_UNICODE);
}
