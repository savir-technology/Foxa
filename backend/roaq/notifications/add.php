<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

try {
    $user = requireUserAuth();
    $title = trim((string)($_POST['title'] ?? ''));
    $body = trim((string)($_POST['body'] ?? ''));
    if ($title === '') {
        echo json_encode(['status' => 'fail', 'message' => 'missing title']);
        exit;
    }
    ensureNotificationsTable($con);
    $stmt = $con->prepare(
        'INSERT INTO notifications
            (notification_userid, notification_type, notification_title, notification_body)
         VALUES (:user_id, :type, :title, :body)'
    );
    $stmt->execute([
        ':user_id' => (int)$user['users_id'],
        ':type' => trim((string)($_POST['type'] ?? 'general')) ?: 'general',
        ':title' => $title,
        ':body' => $body,
    ]);
    echo json_encode(['status' => 'success', 'notification_id' => (int)$con->lastInsertId()]);
} catch (Throwable $e) {
    error_log('add notification error: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'server error']);
}
