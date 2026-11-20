<?php
include "../connect.php";

$ordersid = trim((string)filterRequest("id"));
$shareToken = trim((string)filterRequest("share_token"));

if ($ordersid === '' && $shareToken === '') {
    echo json_encode(["status" => "error", "message" => "Missing order id"]);
    exit;
}

try {
    $orderWhere = $ordersid !== ''
        ? "o.orders_id = :oid"
        : "o.orders_share_token = :token";
    $orderParams = $ordersid !== ''
        ? [":oid" => $ordersid]
        : [":token" => $shareToken];

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
        WHERE $orderWhere
        LIMIT 1
    ");
    $stmt->execute($orderParams);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        echo json_encode(["status" => "error", "message" => "Order not found"]);
        exit;
    }

    $stmt2 = $con->prepare("
        SELECT
            oi.order_item_id AS cart_id,
            oi.order_id,
            oi.item_id AS cart_itemsid,
            oi.item_id AS items_id,
            oi.vendor_id,
            vd.store_name,
            vd.vendor_name,
            vd.store_slug,
            oi.item_name AS items_name_en,
            oi.item_name AS items_name_ar,
            oi.item_color,
            oi.item_size,
            oi.item_price AS items_price,
            oi.item_discount AS items_discount,
            oi.quantity AS countitems,
            oi.quantity_weight,
            oi.lens_code AS cart_lens_code,
            oi.lens_name AS cart_lens_name,
            oi.lens_color AS cart_lens_color,
            oi.lens_features AS cart_lens_features,
            oi.lens_unit_price AS cart_lens_price,
            oi.prescription_json AS cart_prescription_json,
            oi.prescription_summary AS cart_prescription_summary,
            oi.food_item_note,
            oi.food_menu_options_json,
            oi.food_menu_options_summary,
            oi.line_total,
            ((oi.item_price - (oi.item_price * oi.item_discount / 100)) * oi.quantity) AS line_subtotal,
            i.items_active,
            COALESCE(iv.image_url, i.items_image) AS items_image_effective
        FROM order_items oi
        LEFT JOIN items i ON i.items_id = oi.item_id
        LEFT JOIN vendors vd ON vd.vendor_id = oi.vendor_id
        LEFT JOIN item_variants iv
            ON iv.item_id = oi.item_id
           AND EXISTS (
                SELECT 1
                FROM colors c
                JOIN sizes s ON s.size_name = oi.item_size
                WHERE c.color_name = oi.item_color
                  AND c.color_id = iv.color_id
                  AND s.size_id = iv.size_id
        )
        WHERE oi.order_id = :oid
        ORDER BY oi.order_item_id DESC
    ");
    $stmt2->execute([":oid" => $order['orders_id'] ?? $ordersid]);
    $items = $stmt2->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "order" => $order, "items" => $items]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
