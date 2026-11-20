<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../connect.php';
require_once __DIR__ . '/../../notifications/notification_helper.php';

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);
    ensureNotificationsTable($con);

    $stmt = $con->prepare("
        SELECT
            n.notification_id,
            n.notification_userid,
            n.notification_type,
            n.notification_title,
            n.notification_body,
            n.notification_ref_type,
            n.notification_ref_id,
            n.notification_payload,
            n.notification_is_read,
            n.notification_created_at
        FROM notifications n
        WHERE (
                n.notification_ref_type = 'order'
                AND EXISTS (
                    SELECT 1
                    FROM vendor_orders vo
                    WHERE vo.order_id = n.notification_ref_id
                      AND vo.vendor_id = :vendor_id
                )
            )
           OR (
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(n.notification_payload, '$.vendor_id')), '') = :vendor_id_text
            )
        ORDER BY n.notification_created_at DESC, n.notification_id DESC
        LIMIT 500
    ");
    $stmt->execute([
        ':vendor_id' => $vendorId,
        ':vendor_id_text' => (string)$vendorId,
    ]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $unread = 0;
    foreach ($rows as $row) {
        if ((int)($row['notification_is_read'] ?? 0) === 0) {
            $unread++;
        }
    }

    echo json_encode([
        'status' => 'success',
        'summary' => [
            'total_count' => count($rows),
            'unread_count' => $unread,
            'read_count' => count($rows) - $unread,
        ],
        'data' => $rows,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
