<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

$itemid = (int) filterRequest("itemid");

if ($itemid <= 0) {
    echo json_encode(["status" => "error", "message" => "itemid required"]);
    exit();
}

try {
    // Ensure the shared catalogue tables exist on installations that use the
    // application's online schema upgrader.
    if (function_exists('ensureAleppoFoodOrderingSchema')) {
        ensureAleppoFoodOrderingSchema();
    }
    $vendorTypeStmt = $con->prepare("SELECT COALESCE(v.vendor_type, 'restaurant')
        FROM items i LEFT JOIN vendors v ON v.vendor_id = i.vendor_id
        WHERE i.items_id = :itemid LIMIT 1");
    $vendorTypeStmt->execute([':itemid' => $itemid]);
    if (strtolower((string)$vendorTypeStmt->fetchColumn()) !== 'store') {
        echo json_encode([
            'status' => 'success',
            'data' => [],
            'variants' => [],
            'colors' => [],
            'sizes' => [],
            'attributes' => [],
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
    $sql = "
        SELECT
            v.variant_id,
            v.item_id,
            v.color_id,
            v.size_id,
            COALESCE(v.stock, 0) AS stock,
            COALESCE(v.stock_quantity, v.stock, 0) AS stock_quantity,
            COALESCE(v.unit, 'piece') AS unit,
            COALESCE(v.unit_quantity, 1) AS unit_quantity,
            COALESCE(v.sku, '') AS sku,
            COALESCE(v.price, 0) AS price,
            COALESCE(v.image_url, '') AS image_url,
            c.color_name AS color_name,
            c.color_name AS color_name_ar,
            c.color_name AS color_name_en,
            c.color_hex,
            s.size_name AS size_name,
            s.size_name AS size_name_ar,
            s.size_name AS size_name_en,
            COALESCE(s.size_order, 0) AS size_order
        FROM item_variants v
        LEFT JOIN colors c ON v.color_id = c.color_id
        LEFT JOIN sizes s ON v.size_id = s.size_id
        WHERE v.item_id = :itemid
        ORDER BY COALESCE(s.size_order, 0) ASC, v.variant_id ASC
    ";

    $stmt = $con->prepare($sql);
    $stmt->execute([":itemid" => $itemid]);
    $variants = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Attach arbitrary catalogue attributes (volume, weight, model, etc.)
    // without changing the legacy colour/size response used by the app.
    $variantAttributeValues = [];
    if (tableExists('item_variant_values')) {
        $valueStmt = $con->prepare("SELECT vv.variant_id, av.value_id, av.value_ar, av.value_en
            FROM item_variant_values vv
            INNER JOIN item_attribute_values av ON av.value_id = vv.value_id
            INNER JOIN item_attributes a ON a.attribute_id = av.attribute_id
            WHERE a.item_id = :itemid AND a.is_active = 1 AND av.is_active = 1");
        $valueStmt->execute([':itemid' => $itemid]);
        foreach ($valueStmt->fetchAll(PDO::FETCH_ASSOC) as $value) {
            $variantAttributeValues[(string)$value['variant_id']][] = [
                'id' => (string)$value['value_id'],
                'value_ar' => (string)$value['value_ar'],
                'value_en' => (string)$value['value_en'],
            ];
        }
        foreach ($variants as &$variant) {
            $variant['attribute_values'] = $variantAttributeValues[(string)$variant['variant_id']] ?? [];
        }
        unset($variant);
    }

    $colors = [];
    $sizes = [];
    $attributes = [];

    if (tableExists('item_attributes') && tableExists('item_attribute_values')) {
        $attributeStmt = $con->prepare("SELECT a.attribute_id, a.name_ar, a.name_en,
                a.is_required, v.value_id, v.value_ar, v.value_en
            FROM item_attributes a
            LEFT JOIN item_attribute_values v ON v.attribute_id = a.attribute_id AND v.is_active = 1
            WHERE a.item_id = :itemid AND a.is_active = 1
            ORDER BY a.sort_order, a.attribute_id, v.sort_order, v.value_id");
        $attributeStmt->execute([':itemid' => $itemid]);
        foreach ($attributeStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $id = (string)$row['attribute_id'];
            if (!isset($attributes[$id])) {
                $attributes[$id] = [
                    'id' => $id,
                    'name_ar' => (string)$row['name_ar'],
                    'name_en' => (string)$row['name_en'],
                    'is_required' => (int)$row['is_required'] === 1,
                    'values' => [],
                ];
            }
            if ($row['value_id'] !== null) {
                $attributes[$id]['values'][] = [
                    'id' => (string)$row['value_id'],
                    'value_ar' => (string)$row['value_ar'],
                    'value_en' => (string)$row['value_en'],
                ];
            }
        }
    }

    foreach ($variants as $variant) {
        if (!empty($variant['color_id'])) {
            $colors[$variant['color_id']] = [
                'color_id' => (int) $variant['color_id'],
                'color_name' => $variant['color_name'] ?? '',
                'color_name_ar' => $variant['color_name_ar'] ?? '',
                'color_name_en' => $variant['color_name_en'] ?? '',
                'color_hex' => $variant['color_hex'] ?? '#D1D5DB',
            ];
        }

        if (!empty($variant['size_id'])) {
            $sizes[$variant['size_id']] = [
                'size_id' => (int) $variant['size_id'],
                'size_name' => $variant['size_name'] ?? '',
                'size_name_ar' => $variant['size_name_ar'] ?? '',
                'size_name_en' => $variant['size_name_en'] ?? '',
                'size_order' => (int) ($variant['size_order'] ?? 0),
            ];
        }
    }

    if (!empty($variants)) {
        echo json_encode([
            "status" => "success",
            "data" => $variants,
            "colors" => array_values($colors),
            "sizes" => array_values($sizes),
            "attributes" => array_values($attributes)
        ]);
    } else {
        echo json_encode([
            "status" => "failure",
            "message" => "No variants found for this item",
            "data" => [],
            "colors" => [],
            "sizes" => [],
            "attributes" => array_values($attributes)
        ]);
    }
} catch (PDOException $e) {
    error_log("Error fetching variants: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to fetch item variants."
    ]);
}
?>
