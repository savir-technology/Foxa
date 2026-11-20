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
requireMasterPermission($actor['master'] ?? [], 'notifications.send');

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$audience = trim((string)($payload['audience'] ?? 'approved_users'));
$title = trim((string)($payload['title'] ?? ''));
$body = trim((string)($payload['body'] ?? ''));

if ($title === '' || $body === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Broadcast title and body are required',
    ], 400);
}

try {
    if ($audience === 'recent_buyers') {
        $stmt = $con->query("
            SELECT DISTINCT o.orders_usersid
            FROM orders o
            WHERE o.orders_status = 'paid'
              AND o.orders_datetime >= DATE_SUB(NOW(), INTERVAL 90 DAY)
        ");
    } else {
        $stmt = $con->query("
            SELECT users_id
            FROM users
            WHERE users_approve = 1
        ");
    }

    $userIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
    $sentCount = 0;

    foreach ($userIds as $userId) {
        $userId = (int)$userId;
        if ($userId <= 0) {
            continue;
        }

        notifyUser(
            $con,
            $userId,
            'broadcast',
            $title,
            $body,
            'broadcast',
            null,
            ['audience' => $audience],
            true
        );
        $sentCount++;
    }

    respondJson([
        'status' => 'success',
        'message' => 'Broadcast sent successfully to ' . $sentCount . ' recipients',
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
