<?php
include "../../../connect.php";
$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$vendorId = $isVendor ? (int)$actor['vendor']['vendor_id'] : 0;

header('Content-Type: application/json');

$order_id = isset($_GET['order_id']) ? $_GET['order_id'] : null;
$requestedVendorId = isset($_GET['vendor_id']) ? (int)$_GET['vendor_id'] : 0;

if (!$order_id) {
    echo json_encode(["status" => "error", "message" => "order_id مفقود"]);
    exit;
}

try {
    $sql = "
        SELECT 
            oi.order_item_id, 
            oi.vendor_id,
            oi.item_id, 
            oi.item_name, 
            oi.item_color,
            oi.item_size,
            oi.item_price, 
            oi.item_discount, 
            oi.quantity, 
            oi.quantity_weight,
            oi.lens_code,
            oi.lens_name,
            oi.lens_color,
            oi.lens_features,
            oi.lens_unit_price,
            oi.lens_total_price,
            oi.prescription_json,
            oi.prescription_summary,
            oi.food_item_note,
            oi.food_menu_options_json,
            oi.food_menu_options_summary,
            oi.subtotal,
            oi.line_total,
            (oi.item_price - (oi.item_price * oi.item_discount / 100)) * oi.quantity AS total_after_discount
        FROM order_items oi
        WHERE oi.order_id = :oid
    ";

    $params = [":oid" => $order_id];
    if ($isVendor) {
        $sql .= " AND oi.vendor_id = :vendor_id";
        $params[":vendor_id"] = $vendorId;
    } elseif ($requestedVendorId > 0) {
        $sql .= " AND oi.vendor_id = :vendor_id";
        $params[":vendor_id"] = $requestedVendorId;
    }

    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($items) {
        echo json_encode(["status" => "success", "data" => $items]);
    } else {
        echo json_encode(["status" => "error", "message" => "لا يوجد منتجات لهذا الطلب"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
