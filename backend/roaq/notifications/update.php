<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

try {
    requireDashboardActor(['master']);
    $id = (int)($_POST['id'] ?? 0);
    if ($id <= 0) {
        echo json_encode(['status' => 'fail', 'message' => 'missing id']);
        exit;
    }
    $fields = [];
    $params = [':id' => $id];
    if (isset($_POST['title'])) { $fields[] = 'notification_title = :title'; $params[':title'] = trim((string)$_POST['title']); }
    if (isset($_POST['body'])) { $fields[] = 'notification_body = :body'; $params[':body'] = trim((string)$_POST['body']); }
    if (isset($_POST['is_read'])) { $fields[] = 'notification_is_read = :is_read'; $params[':is_read'] = (int)$_POST['is_read'] === 1 ? 1 : 0; }
    if ($fields === []) {
        echo json_encode(['status' => 'fail', 'message' => 'no fields to update']);
        exit;
    }
    ensureNotificationsTable($con);
    $stmt = $con->prepare('UPDATE notifications SET ' . implode(', ', $fields) . ' WHERE notification_id = :id');
    $stmt->execute($params);
    echo json_encode(['status' => 'success', 'updated_id' => $id, 'affected_rows' => $stmt->rowCount()]);
} catch (Throwable $e) {
    error_log('notification update error: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'server error']);
}
