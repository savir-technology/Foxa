<?php

function isDeliveredOrderStatus(?string $status): bool
{
    $normalized = strtolower(trim((string)$status));
    return in_array($normalized, ['4', 'delivered', 'completed'], true);
}

function userCanRateItem(PDO $con, int $userId, int $itemId): bool
{
    if ($userId <= 0 || $itemId <= 0) {
        return false;
    }

    $stmt = $con->prepare("
        SELECT 1
        FROM orders o
        INNER JOIN order_items oi ON oi.order_id = o.orders_id
        WHERE o.orders_usersid = :user_id
          AND oi.item_id = :item_id
          AND (
              o.delivered_at IS NOT NULL
              OR LOWER(COALESCE(o.status, '')) IN ('4', 'delivered', 'completed')
          )
        LIMIT 1
    ");
    $stmt->execute([
        ':user_id' => $userId,
        ':item_id' => $itemId,
    ]);

    return (bool)$stmt->fetchColumn();
}
