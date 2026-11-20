<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

try {
    $user = requireUserAuth();
    $userId = (int)$user['users_id'];
    $notificationId = (int)($_POST['notification_id'] ?? 0);
    ensureNotificationsTable($con);
    if ((int)($_POST['mark_all'] ?? 0) === 1) {
        $stmt = $con->prepare(
            'UPDATE notifications SET notification_is_read = 1
             WHERE notification_userid = :user_id AND notification_is_read = 0'
        );
        $stmt->execute([':user_id' => $userId]);
    } else {
        if ($notificationId <= 0) {
            echo json_encode(['status' => 'fail', 'message' => 'missing notification_id']);
            exit;
        }
        $stmt = $con->prepare(
            'UPDATE notifications SET notification_is_read = 1
             WHERE notification_id = :notification_id AND notification_userid = :user_id'
        );
        $stmt->execute([':notification_id' => $notificationId, ':user_id' => $userId]);
    }
    echo json_encode(['status' => 'success', 'affected_rows' => $stmt->rowCount()]);
} catch (Throwable $e) {
    error_log('mark_as_read error: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'server error']);
}
