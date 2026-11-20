<?php

function userCanRateDriver(PDO $con, int $userId, int $orderId, int $driverId): bool
{
    if ($userId <= 0 || $orderId <= 0 || $driverId <= 0) {
        return false;
    }

    $stmt = $con->prepare("
        SELECT 1
        FROM orders o
        WHERE o.orders_id = :order_id
          AND o.orders_usersid = :user_id
          AND TRIM(COALESCE(o.delivery_id, '')) = :driver_id
          AND (
              o.delivered_at IS NOT NULL
              OR LOWER(COALESCE(o.status, '')) IN ('4', 'delivered', 'completed')
          )
        LIMIT 1
    ");
    $stmt->execute([
        ':order_id' => $orderId,
        ':user_id' => $userId,
        ':driver_id' => (string)$driverId,
    ]);

    return (bool)$stmt->fetchColumn();
}
