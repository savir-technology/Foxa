<?php

include "connect.php";
require_once __DIR__ . "/notifications/notification_helper.php";

$user = requireUserAuth();
$userid = (int)($user['users_id'] ?? 0);

if ($userid <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "User id is required",
        "data" => []
    ]);
    exit;
}

try {
    ensureNotificationsTable($con);

    $stmt = $con->prepare("
        SELECT
            notification_id,
            notification_userid,
            notification_type,
            notification_title,
            notification_body,
            notification_ref_type,
            notification_ref_id,
            notification_payload,
            notification_is_read,
            notification_created_at
        FROM notifications
        WHERE notification_userid = :uid
        ORDER BY notification_created_at DESC, notification_id DESC
    ");
    $stmt->execute([":uid" => $userid]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $data
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
        "data" => []
    ], JSON_UNESCAPED_UNICODE);
}
