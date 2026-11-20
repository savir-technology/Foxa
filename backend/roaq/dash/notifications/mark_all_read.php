<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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
        UPDATE notifications n
        SET n.notification_is_read = 1
        WHERE n.notification_is_read = 0
          AND (
                (
                    n.notification_ref_type = 'order'
                    AND EXISTS (
                        SELECT 1
                        FROM vendor_orders vo
                        WHERE vo.order_id = n.notification_ref_id
                          AND vo.vendor_id = :vendor_id
                    )
                )
             OR COALESCE(JSON_UNQUOTE(JSON_EXTRACT(n.notification_payload, '$.vendor_id')), '') = :vendor_id_text
          )
    ");
    $stmt->execute([
        ':vendor_id' => $vendorId,
        ':vendor_id_text' => (string)$vendorId,
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
