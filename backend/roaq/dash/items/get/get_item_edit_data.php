<?php
include "../../../connect.php";
require_once __DIR__ . "/../modifier_helpers.php";
ensureAleppoFoodOrderingSchema();

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$vendorId = $isVendor ? (int)$actor['vendor']['vendor_id'] : 0;
if (!$isVendor) {
    requireMasterPermission($actor['master'] ?? [], 'restaurants.view');
}

function respond($payload, $statusCode = 200)
{
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $itemId = isset($_GET['item_id']) ? (int)$_GET['item_id'] : 0;
    if ($itemId <= 0) {
        respond(["status" => "error", "message" => "Missing item_id"], 400);
    }

    $sql = "
        SELECT
            items_id,
            items_name_en,
            items_name_ar,
            items_desc_en,
            items_desc_ar,
            items_image,
            items_count,
            items_active,
            items_price,
            items_discount,
            items_date,
            items_cat,
            vendor_id,
            (SELECT COALESCE(v.vendor_type, 'restaurant') FROM vendors v WHERE v.vendor_id = items.vendor_id LIMIT 1) AS vendor_type,
            product_type, stock_unit, stock_step
        FROM items
        WHERE items_id = :item_id
    ";

    if ($isVendor) {
        $sql .= " AND vendor_id = :vendor_id";
    }

    $sql .= " LIMIT 1";

    $itemStmt = $con->prepare($sql);
    $params = [":item_id" => $itemId];
    if ($isVendor) {
        $params[":vendor_id"] = $vendorId;
    }
    $itemStmt->execute($params);
    $item = $itemStmt->fetch(PDO::FETCH_ASSOC);
    if (!$item) {
        respond(["status" => "error", "message" => "Item not found"], 404);
    }

    $imagesStmt = $con->prepare("
        SELECT img_id, item_id, color_id, img_path, img_type, img_order
        FROM items_images
        WHERE item_id = :item_id
        ORDER BY img_order ASC, img_id ASC
    ");
    $imagesStmt->execute([":item_id" => $itemId]);
    $images = $imagesStmt->fetchAll(PDO::FETCH_ASSOC);

    $variantsStmt = $con->prepare("
        SELECT variant_id, item_id, color_id, size_id, stock, stock_quantity, unit, unit_quantity, sku, price, image_url
        FROM item_variants
        WHERE item_id = :item_id
        ORDER BY variant_id ASC
    ");
    $variantsStmt->execute([":item_id" => $itemId]);
    $variants = strtolower((string)($item['vendor_type'] ?? 'restaurant')) === 'store'
        ? $variantsStmt->fetchAll(PDO::FETCH_ASSOC)
        : [];

    $modifierGroups = dashboardFetchItemModifierGroups($con, $itemId);
    $attributes = [];
    if (tableExists('item_attributes') && strtolower((string)($item['vendor_type'] ?? 'restaurant')) === 'store') {
        $attributeStmt = $con->prepare("SELECT a.attribute_id, a.name_ar, a.name_en, a.is_required,
                v.value_id, v.value_ar, v.value_en
            FROM item_attributes a
            LEFT JOIN item_attribute_values v ON v.attribute_id = a.attribute_id AND v.is_active = 1
            WHERE a.item_id = :item_id AND a.is_active = 1
            ORDER BY a.sort_order, a.attribute_id, v.sort_order, v.value_id");
        $attributeStmt->execute([':item_id' => $itemId]);
        foreach ($attributeStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $key = (string)$row['attribute_id'];
            if (!isset($attributes[$key])) {
                $attributes[$key] = [
                    'id' => $key,
                    'name_ar' => $row['name_ar'],
                    'name_en' => $row['name_en'],
                    'is_required' => (int)$row['is_required'] === 1,
                    'values' => [],
                ];
            }
            if ($row['value_id'] !== null) {
                $attributes[$key]['values'][] = [
                    'id' => (string)$row['value_id'],
                    'value_ar' => $row['value_ar'],
                    'value_en' => $row['value_en'],
                ];
            }
        }
    }

    $colorsStmt = $con->prepare("
        SELECT DISTINCT c.color_id, c.color_name, c.color_hex
        FROM colors c
        LEFT JOIN item_variants iv ON iv.color_id = c.color_id AND iv.item_id = :item_id
        WHERE c.color_active = 1 OR iv.variant_id IS NOT NULL
        ORDER BY color_name ASC
    ");
    $colorsStmt->execute([':item_id' => $itemId]);
    $colors = $colorsStmt->fetchAll(PDO::FETCH_ASSOC);

    $sizesStmt = $con->prepare("
        SELECT size_id, size_name, size_order, product_type
        FROM sizes
        WHERE product_type = :product_type
           OR size_id IN (SELECT size_id FROM item_variants WHERE item_id = :item_id)
        ORDER BY size_order ASC, size_name ASC
    ");
    $sizesStmt->execute([
        ':product_type' => ($item['product_type'] ?? '') === 'shoes' ? 'shoes' : 'fashion',
        ':item_id' => $itemId,
    ]);
    $sizes = $sizesStmt->fetchAll(PDO::FETCH_ASSOC);

    respond([
        "status" => "success",
        "item" => $item,
        "images" => $images,
        "variants" => $variants,
        "modifier_groups" => $modifierGroups,
        "attributes" => array_values($attributes),
        "colors" => $colors,
        "sizes" => $sizes,
    ]);
} catch (Throwable $e) {
    respond([
        "status" => "error",
        "message" => $e->getMessage(),
    ], 500);
}
?>
