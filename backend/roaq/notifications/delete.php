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
    ensureNotificationsTable($con);
    $stmt = $con->prepare('DELETE FROM notifications WHERE notification_id = :id');
    $stmt->execute([':id' => $id]);
    echo json_encode(['status' => 'success', 'deleted_id' => $id, 'affected_rows' => $stmt->rowCount()]);
} catch (Throwable $e) {
    error_log('notification delete error: ' . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'server error']);
}
