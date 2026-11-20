<?php
include "../../../connect.php";
$actor = requireDashboardActor(['master']);

$order_id = isset($_GET['order_id']) ? $_GET['order_id'] : null;

if ($order_id) {
    try {
        $con->beginTransaction();

        // احذف تفاصيل الأوردر
        $stmt = $con->prepare("DELETE FROM order_items WHERE order_id = :oid");
        $stmt->execute([":oid" => $order_id]);

        // احذف الأوردر نفسه
        $stmt = $con->prepare("DELETE FROM orders WHERE orders_id = :oid");
        $stmt->execute([":oid" => $order_id]);

        $con->commit();
        echo json_encode(["status" => "success", "message" => "تم حذف الأوردر بالكامل."]);
    } catch (PDOException $e) {
        $con->rollBack();
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "order_id غير موجود."]);
}
