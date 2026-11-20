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
    $payload = json_decode(file_get_contents('php://input'), true);
    $id = (int)($payload['notification_id'] ?? $_POST['notification_id'] ?? 0);
    if ($id <= 0) { respondJson(['status' => 'error', 'message' => 'Invalid notification id'], 422); }
    ensureNotificationsTable($con);
    $stmt = $con->prepare('UPDATE notifications SET notification_is_read = 1 WHERE notification_id = :id');
    $stmt->execute([':id' => $id]);
    respondJson(['status' => 'success', 'updated' => $stmt->rowCount()]);
} catch (Throwable $e) { respondJson(['status' => 'error', 'message' => $e->getMessage()], 500); }
