<?php
include "../../../connect.php";
require_once __DIR__ . "/../../../notifications/notification_helper.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['master']);
requireMasterPermission($actor['master'] ?? [], 'reports.export');

try {
    ensureNotificationsTable($con);

    $ordersCount = (int)$con->query("SELECT COUNT(*) FROM orders")->fetchColumn();
    $vendorsCount = (int)$con->query("SELECT COUNT(*) FROM vendors")->fetchColumn();
    $videosCount = (int)$con->query("SELECT COUNT(*) FROM videos")->fetchColumn();
    $notificationsCount = (int)$con->query("SELECT COUNT(*) FROM notifications")->fetchColumn();
    $pendingSettlements = (int)$con->query("
        SELECT COUNT(DISTINCT vendor_id)
        FROM vendor_orders
        WHERE vendor_status = 'pending'
    ")->fetchColumn();

    respondJson([
        'status' => 'success',
        'message' => 'Master export snapshot generated successfully',
        'snapshot' => [
            'generated_at' => date('Y-m-d H:i'),
            'orders' => $ordersCount,
            'vendors' => $vendorsCount,
            'videos' => $videosCount,
            'notifications' => $notificationsCount,
            'pending_settlement_vendors' => $pendingSettlements,
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
