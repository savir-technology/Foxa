<?php
include "../connect.php";
$userid = filterRequest("id");
if (!$userid) {
    echo json_encode(["status" => "error", "message" => "Missing user id"]);
    exit;
}
try {
    $stmt = $con->prepare("
        SELECT
            o.*,
            COALESCE(vo.vendor_id, oi_vendor.vendor_id) AS vendor_id,
            v.vendor_name,
            v.store_name,
            v.store_slug,
            v.vendor_logo,
            v.vendor_description,
            vss.store_banner_url,
            COALESCE(vss.store_address, v.vendor_description, '') AS store_address,
            vss.store_latitude,
            vss.store_longitude,
            a.address_id,
            a.address_usersid,
            a.address_name,
            a.address_city,
            a.address_street,
            a.address_lat,
            a.address_long
        FROM orders o
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN (
            SELECT order_id, MIN(vendor_id) AS vendor_id
            FROM order_items
            GROUP BY order_id
        ) oi_vendor ON oi_vendor.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = COALESCE(vo.vendor_id, oi_vendor.vendor_id)
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        WHERE o.orders_usersid = :userid
          AND o.orders_status NOT IN ('4', 'archive', 'archived', 'delivered', 'completed')
        ORDER BY o.orders_datetime DESC
    ");
    $stmt->execute([":userid" => $userid]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if ($data && count($data) > 0) {
        echo json_encode(["status" => "success", "data" => $data]);
    } else {
        echo json_encode(["status" => "failure"]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}