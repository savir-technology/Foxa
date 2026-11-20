<?php
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../../notifications/notification_helper.php';

header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $actor = requireDashboardActor(['master']);
    requireMasterPermission($actor['master'] ?? [], 'notifications.view');
    ensureNotificationsTable($con);
    $stmt = $con->query("SELECT notification_id, notification_userid, notification_type,
        notification_title, notification_body, notification_ref_type, notification_ref_id,
        notification_payload, notification_is_read, notification_created_at
        FROM notifications ORDER BY notification_created_at DESC, notification_id DESC LIMIT 500");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $unread = 0;
    foreach ($rows as $row) { $unread += ((int)($row['notification_is_read'] ?? 0) === 0) ? 1 : 0; }
    respondJson(['status' => 'success', 'summary' => [
        'total_count' => count($rows), 'unread_count' => $unread,
        'read_count' => count($rows) - $unread,
    ], 'data' => $rows]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage(), 'data' => []], 500);
}
