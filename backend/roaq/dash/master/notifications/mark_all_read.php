<?php
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../../notifications/notification_helper.php';
header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $actor = requireDashboardActor(['master']);
    requireMasterPermission($actor['master'] ?? [], 'notifications.view');
    ensureNotificationsTable($con);
    $stmt = $con->query('UPDATE notifications SET notification_is_read = 1 WHERE notification_is_read = 0');
    respondJson(['status' => 'success', 'updated' => $stmt->rowCount()]);
} catch (Throwable $e) { respondJson(['status' => 'error', 'message' => $e->getMessage()], 500); }
