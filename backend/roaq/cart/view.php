<?php
include "../connect.php";
$userid = filterRequest("usersid");
if ($userid === null || !is_numeric($userid)) {
    echo json_encode(["status" => "error", "message" => "User ID is missing or invalid."]);
    exit;
}
try {
    $stmt = $con->prepare("
        SELECT
            c.cart_id,
            c.cart_usersid,
            c.cart_itemsid,
            c.cart_variantid,
            c.cart_quantity AS countitems,
            COALESCE(c.cart_quantity_weight, c.cart_quantity * COALESCE(iv.unit_quantity, 1)) AS weight_quantity,
            COALESCE(c.cart_vendor_id, i.vendor_id) AS vendor_id,
            c.cart_lens_code,
            c.cart_lens_name,
            c.cart_lens_color,
            c.cart_lens_features,
            c.cart_lens_price,
            c.cart_prescription_json,
            c.cart_prescription_summary,
            c.cart_config_hash,
            c.cart_context_type,
            c.cart_vendor_id,
            c.cart_unit_price,
            c.cart_item_note,
            c.cart_menu_options_json,
            c.cart_menu_options_summary,
            c.cart_variant_attributes_json,
            c.cart_quantity_weight,
            COALESCE(vss.store_name, v.vendor_name, v.store_name) AS store_name,
            COALESCE(vss.vendor_name, v.vendor_name, v.store_name) AS vendor_name,
            COALESCE(vss.vendor_logo, v.vendor_logo) AS vendor_logo,
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            i.items_image,
            i.items_count,
            i.items_active,
            i.items_price,
            i.items_discount,
            i.stock_unit,
            i.items_date,
            i.items_cat,
            c2.color_name AS item_color,
            COALESCE(s.size_name, iv.sku) AS item_size,
            COALESCE(iv.image_url, i.items_image) AS items_image_effective,
            (COALESCE(c.cart_unit_price, COALESCE(iv.price, (i.items_price - (i.items_price * i.items_discount / 100)))) * CASE WHEN i.stock_unit = 'kg' THEN COALESCE(c.cart_quantity_weight, c.cart_quantity) ELSE c.cart_quantity END) AS total_items_price,
            ((COALESCE(c.cart_unit_price, COALESCE(iv.price, (i.items_price - (i.items_price * i.items_discount / 100)))) + (COALESCE(c.cart_lens_price, 0) * 2)) * CASE WHEN i.stock_unit = 'kg' THEN COALESCE(c.cart_quantity_weight, c.cart_quantity) ELSE c.cart_quantity END) AS line_total,
            ((COALESCE(iv.price, i.items_price) + COALESCE(c.cart_lens_price, 0) * 2) * c.cart_quantity) AS line_subtotal,
            ((COALESCE(iv.price, i.items_price) - COALESCE(c.cart_unit_price, COALESCE(iv.price, (i.items_price - (i.items_price * i.items_discount / 100))))) * c.cart_quantity) AS line_discount
        FROM cart c
        JOIN items i ON i.items_id = c.cart_itemsid
        LEFT JOIN item_variants iv ON iv.variant_id = c.cart_variantid
        LEFT JOIN colors c2 ON c2.color_id = iv.color_id
        LEFT JOIN sizes s ON s.size_id = iv.size_id
        LEFT JOIN vendors v ON v.vendor_id = COALESCE(c.cart_vendor_id, i.vendor_id)
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        WHERE c.cart_usersid = :uid AND c.cart_orders = 0
        ORDER BY COALESCE(c.cart_vendor_id, i.vendor_id) DESC, c.cart_id DESC
    ");
    $stmt->execute([":uid" => intval($userid)]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt2 = $con->prepare("
        SELECT
            COALESCE(SUM(((COALESCE(c.cart_unit_price, iv.price, (i.items_price - (i.items_price * i.items_discount / 100))) + (COALESCE(c.cart_lens_price, 0) * 2)) * CASE WHEN i.stock_unit = 'kg' THEN COALESCE(c.cart_quantity_weight, c.cart_quantity) ELSE c.cart_quantity END)), 0) AS totalprice,
            COALESCE(SUM(CASE WHEN i.stock_unit = 'kg' THEN COALESCE(c.cart_quantity_weight, c.cart_quantity) ELSE c.cart_quantity END), 0) AS totalcount
        FROM cart c
        JOIN items i ON i.items_id = c.cart_itemsid
        LEFT JOIN item_variants iv ON iv.variant_id = c.cart_variantid
        WHERE c.cart_usersid = :uid AND c.cart_orders = 0
    ");
    $stmt2->execute([":uid" => intval($userid)]);
    $datacountprice = $stmt2->fetch(PDO::FETCH_ASSOC);
    echo json_encode([
        "status" => "success",
        "countprice" => $datacountprice,
        "datacart" => $data
    ]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
