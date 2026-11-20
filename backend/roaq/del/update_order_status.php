<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "failed", "message" => "POST required"], JSON_UNESCAPED_UNICODE);
    exit;
}

$driverId = (int)($_POST['driver_id'] ?? 0);
$orderId = (int)($_POST['order_id'] ?? 0);
$status = trim((string)($_POST['status'] ?? ''));

if ($driverId <= 0 || $orderId <= 0 || $status === '' || !in_array($status, ['on_the_way', 'delivered'], true)) {
    echo json_encode(["status" => "failed", "message" => "Invalid input"], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    if ($status === 'delivered') {
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?,
                delivered_at = NOW()
            WHERE orders_id = ? AND delivery_id = ?
        ");
    } else {
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?
            WHERE orders_id = ? AND delivery_id = ?
        ");
    }

    $result = $stmt->execute([$status, $orderId, $driverId]);

    if ($result) {
        echo json_encode(["status" => "success", "message" => "Order status updated"], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(["status" => "failed", "message" => "Failed to update order status"], JSON_UNESCAPED_UNICODE);
    }
} catch (Throwable $e) {
    echo json_encode(["status" => "failed", "message" => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
