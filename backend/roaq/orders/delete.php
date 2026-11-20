<?php
include "../connect.php";

$ordersid = filterRequest("id");

if (!$ordersid) {
    echo json_encode(["status" => "error", "message" => "Missing order id"]);
    exit;
}

// نحذف الأوردر فقط لو لسه pending (لم يتم الدفع)
try {
    $stmt = $con->prepare("DELETE FROM orders WHERE orders_id = :oid AND orders_status = 'pending'");
    $stmt->execute([":oid" => $ordersid]);

    if ($stmt->rowCount() > 0) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Order not found or cannot be deleted"]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
