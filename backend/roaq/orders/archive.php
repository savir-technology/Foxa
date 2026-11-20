<?php
include "../connect.php";

$userid = filterRequest("userid");

if (!$userid || !is_numeric($userid)) {
    echo json_encode(["status" => "error", "message" => "Invalid user ID"]);
    exit();
}

try {
    $stmt = $con->prepare("
        SELECT
            o.orders_id,
            o.orders_datetime,
            o.orders_totalprice,
            o.orders_status,
            o.orders_type,
            oi.vendor_id,
            vd.store_name,
            vd.vendor_name,
            vd.store_slug,
            vd.vendor_logo,
            vss.store_banner_url,
            oi.item_name,
            oi.item_color,
            oi.item_size,
            oi.item_price,
            oi.item_discount,
            oi.quantity,
            oi.quantity_weight,
            oi.lens_name,
            oi.lens_color,
            oi.lens_features,
            oi.lens_unit_price,
            oi.lens_total_price,
            oi.prescription_summary,
            oi.line_total,
            COALESCE(iv.image_url, i.items_image) AS items_image
        FROM orders o
        JOIN order_items oi ON o.orders_id = oi.order_id
        LEFT JOIN vendors vd ON vd.vendor_id = oi.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = vd.vendor_id
        LEFT JOIN items i ON oi.item_id = i.items_id
        LEFT JOIN item_variants iv
            ON iv.item_id = oi.item_id
           AND (
                (oi.item_color IS NOT NULL AND oi.item_color <> '' AND oi.item_size IS NOT NULL AND oi.item_size <> '')
                AND EXISTS (
                    SELECT 1
                    FROM colors c
                    JOIN sizes s ON s.size_name = oi.item_size
                    WHERE c.color_name = oi.item_color
                      AND c.color_id = iv.color_id
                      AND s.size_id = iv.size_id
                )
           )
        WHERE o.orders_usersid = :userid
        ORDER BY o.orders_datetime DESC, oi.order_item_id DESC
    ");
    $stmt->execute([":userid" => $userid]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($data && count($data) > 0) {
        echo json_encode(["status" => "success", "data" => $data]);
    } else {
        echo json_encode(["status" => "empty", "message" => "No archived orders found"]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
