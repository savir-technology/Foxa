<?php

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../connect.php';
require_once __DIR__ . '/notification_helper.php';

$user = requireUserAuth();
$userId = (int)($user['users_id'] ?? 0);

if ($userId <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'user_id is required',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    ensureNotificationsTable($con);

    $stmt = $con->prepare("
        UPDATE notifications
        SET notification_is_read = 1
        WHERE notification_userid = :user_id
          AND notification_is_read = 0
    ");
    $stmt->execute([
        ':user_id' => $userId,
    ]);

    echo json_encode([
        'status' => 'success',
        'affected_rows' => $stmt->rowCount(),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
