<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../connect.php';
require_once '../../notifications/notification_service.php';

function normalizeRole(string $role): string
{
    $r = strtolower(trim($role));
    return match ($r) {
        'admin' => 'admin',
        'account', 'accounts' => 'account',
        'conect', 'connect', 'crm' => 'conect',
        'property', 'content' => 'property',
        default => 'user',
    };
}

function fail(string $message, int $http = 200): void
{
    http_response_code($http);
    echo json_encode([
        'status' => 'fail',
        'message' => $message,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

try {
    $actor = requireDashboardActor(['master']);
    $adminId = intval($actor['master']['admin_id'] ?? $actor['master']['master_id'] ?? 0);
    $title = trim((string)($_POST['title'] ?? ''));
    $body = trim((string)($_POST['body'] ?? ''));
    $type = strtolower(trim((string)($_POST['type'] ?? 'contract')));

    if ($adminId <= 0) fail('invalid_admin_session', 403);
    if ($title === '' || $body === '') fail('title_and_body_required');
    if (mb_strlen($title) > 255) fail('title_too_long');
    if (mb_strlen($body) > 5000) fail('body_too_long');

    $allowedTypes = ['chat', 'installment', 'receipt', 'contract'];
    if (!in_array($type, $allowedTypes, true)) {
        $type = 'contract';
    }

    $eventKeyPrefix = 'global_' . date('Ymd_His') . '_' . substr(md5((string)microtime(true)), 0, 8);
    $meta = [
        'source' => 'admin_global',
        'admin_id' => $adminId,
    ];

    $usersStmt = $con->query("
        SELECT users_id, COALESCE(user_role, '') AS user_role
        FROM users
        WHERE users_approve = 1
    ");
    $rows = $usersStmt ? $usersStmt->fetchAll(PDO::FETCH_ASSOC) : [];

    $createdCount = 0;
    foreach ($rows as $row) {
        $uid = intval($row['users_id'] ?? 0);
        if ($uid <= 0) continue;
        $uRole = normalizeRole((string)($row['user_role'] ?? ''));
        // Broadcast to end users only (exclude all dashboard roles).
        if (in_array($uRole, ['admin', 'account', 'conect', 'property'], true)) {
            continue;
        }

        $eventKey = $eventKeyPrefix . '_' . $uid;
        if (notifyUser($uid, $title, $body, $type, $meta, $eventKey)) {
            $createdCount++;
        }
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'global_notification_sent',
        'data' => [
            'created_notifications' => intval($createdCount),
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('send_global.php error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'server_error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
