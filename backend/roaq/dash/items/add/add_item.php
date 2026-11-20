<?php
include "../../../connect.php";
ensureAleppoFoodOrderingSchema();
require_once __DIR__ . "/../../../notifications/notification_helper.php";
require_once __DIR__ . "/../modifier_helpers.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';

function respond($payload, $statusCode = 200)
{
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

function isBase64Image($value)
{
    return is_string($value) && strlen($value) > 100;
}

function saveBase64ItemImage($base64Image, $uploadDir, $baseUrl)
{
    if (!isBase64Image($base64Image)) {
        return null;
    }

    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $decoded = base64_decode($base64Image, true);
    if ($decoded === false) {
        return null;
    }

    $fileName = uniqid("item_", true) . ".png";
    $filePath = $uploadDir . DIRECTORY_SEPARATOR . $fileName;

    if (file_put_contents($filePath, $decoded) === false) {
        return null;
    }

    return [
        "file_name" => $fileName,
        "url" => rtrim($baseUrl, "/") . "/" . $fileName,
    ];
}

try {
    $rawInput = file_get_contents("php://input");
    $data = json_decode($rawInput);

    if (!$data) {
        respond(["status" => "error", "message" => "Invalid JSON body"], 400);
    }

    $requiredFields = [
        "items_name_en",
        "items_name_ar",
        "items_desc_en",
        "items_desc_ar",
        "items_price",
        "items_discount",
        "items_cat",
    ];

    foreach ($requiredFields as $field) {
        if (!isset($data->$field) || $data->$field === "") {
            respond(["status" => "error", "message" => "Missing required field: {$field}"], 400);
        }
    }

    $variants = isset($data->variants) && is_array($data->variants) ? $data->variants : [];
    $images = isset($data->images) && is_array($data->images) ? $data->images : [];

    if (empty($images)) {
        respond(["status" => "error", "message" => "At least one image is required"], 400);
    }

    $uploadDir = realpath(__DIR__ . "/../../../") . DIRECTORY_SEPARATOR . "uploud" . DIRECTORY_SEPARATOR . "items";
    $baseImageUrl = "https://savir-technology.online/roaqv2/uploud/items";

    $savedImages = [];
    foreach ($images as $index => $imagePayload) {
        $base64Image = isset($imagePayload->data) ? $imagePayload->data : null;
        $saved = saveBase64ItemImage($base64Image, $uploadDir, $baseImageUrl);
        if ($saved === null) {
            respond([
                "status" => "error",
                "message" => "Invalid image payload at index {$index}"
            ], 400);
        }
        $savedImages[] = $saved;
    }

    $itemCount = 0;
    $isWeightCatalog = (($data->product_type ?? '') === 'fresh_food');
    foreach ($variants as $index => $variant) {
        $stock = isset($variant->stock_quantity) ? (float)$variant->stock_quantity : (isset($variant->stock) ? (float)$variant->stock : 0);
        $itemCount = $isWeightCatalog
            ? max($itemCount, max(0, $stock))
            : $itemCount + max(0, (int)$stock);
    }

    $itemNameEn = trim((string)$data->items_name_en);
    $itemNameAr = trim((string)$data->items_name_ar);
    $itemDescEn = trim((string)$data->items_desc_en);
    $itemDescAr = trim((string)$data->items_desc_ar);
    $itemPrice = (float)$data->items_price;
    $itemDiscount = (int)$data->items_discount;
    $itemCat = (int)$data->items_cat;
    $itemActive = isset($data->items_active) ? (int)$data->items_active : 1;
    $productType = trim((string)($data->product_type ?? 'food')) ?: 'food';
    $stockUnit = trim((string)($data->stock_unit ?? 'piece')) ?: 'piece';
    $stockStep = isset($data->stock_step) ? (float)$data->stock_step : 1.0;
    $primaryImageName = $savedImages[0]["file_name"];
    $targetVendorId = $isVendor
        ? (int)$actor['vendor']['vendor_id']
        : (int)($data->vendor_id ?? 0);

    if ($targetVendorId <= 0) {
        respond(["status" => "error", "message" => "Vendor id is required"], 400);
    }

    $vendorStmt = $con->prepare("
        SELECT vendor_id, vendor_type, store_category
        FROM vendors
        WHERE vendor_id = :vendor_id
        LIMIT 1
    ");
    $vendorStmt->execute([":vendor_id" => $targetVendorId]);
    $vendor = $vendorStmt->fetch(PDO::FETCH_ASSOC);
    if (!$vendor) {
        respond(["status" => "error", "message" => "Vendor not found"], 404);
    }
    if (($vendor['vendor_type'] ?? 'restaurant') === 'store') {
        $expectedType = $vendor['store_category'] ?: 'general';
        if ($productType !== $expectedType) {
            respond(["status" => "error", "message" => "Product type must match the store specialization"], 422);
        }
        if (!empty($data->modifier_groups)) {
            respond(["status" => "error", "message" => "Store products cannot use restaurant modifiers"], 422);
        }
    } else {
        $productType = 'food';
        $stockUnit = 'piece';
        $stockStep = 1.0;
        if (!empty($variants)) {
            respond(["status" => "error", "message" => "Restaurant products cannot use generic variants; use modifier groups"], 422);
        }
    }

    $con->beginTransaction();

    $itemStmt = $con->prepare("
        INSERT INTO items (
            items_name_en,
            items_name_ar,
            items_desc_en,
            items_desc_ar,
            items_image,
            items_count,
            items_active,
            items_price,
            items_discount,
            items_cat,
            vendor_id,
            product_type,
            stock_unit,
            stock_step
        ) VALUES (
            :items_name_en,
            :items_name_ar,
            :items_desc_en,
            :items_desc_ar,
            :items_image,
            :items_count,
            :items_active,
            :items_price,
            :items_discount,
            :items_cat,
            :vendor_id,
            :product_type,
            :stock_unit,
            :stock_step
        )
    ");

    $itemStmt->execute([
        ":items_name_en" => $itemNameEn,
        ":items_name_ar" => $itemNameAr,
        ":items_desc_en" => $itemDescEn,
        ":items_desc_ar" => $itemDescAr,
        ":items_image" => $primaryImageName,
        ":items_count" => $itemCount,
        ":items_active" => $itemActive,
        ":items_price" => $itemPrice,
        ":items_discount" => $itemDiscount,
        ":items_cat" => $itemCat,
        ":vendor_id" => $targetVendorId,
        ":product_type" => $productType,
        ":stock_unit" => $stockUnit,
        ":stock_step" => $stockStep,
    ]);

    $itemId = (int)$con->lastInsertId();

    $imagesStmt = $con->prepare("
        INSERT INTO items_images (
            item_id,
            color_id,
            img_path,
            img_type,
            img_order
        ) VALUES (
            :item_id,
            :color_id,
            :img_path,
            :img_type,
            :img_order
        )
    ");

    foreach ($savedImages as $index => $savedImage) {
        $colorId = isset($images[$index]->color_id) && $images[$index]->color_id !== null
            ? (int)$images[$index]->color_id
            : null;
        $imgType = isset($images[$index]->img_type) ? (string)$images[$index]->img_type : "normal";

        $imagesStmt->execute([
            ":item_id" => $itemId,
            ":color_id" => $colorId,
            ":img_path" => $savedImage["url"],
            ":img_type" => $imgType === "360" ? "360" : "normal",
            ":img_order" => $index,
        ]);
    }

    $variantStmt = $con->prepare("
        INSERT INTO item_variants (
            item_id,
            color_id,
            size_id,
            stock,
            price,
            image_url,
            sku,
            stock_quantity,
            unit,
            unit_quantity
        ) VALUES (
            :item_id,
            :color_id,
            :size_id,
            :stock,
            :price,
            :image_url,
            :sku,
            :stock_quantity,
            :unit,
            :unit_quantity
        )
    ");

    foreach ($variants as $variant) {
        $variantImageUrl = null;
        if (isset($variant->image) && isBase64Image($variant->image)) {
            $savedVariantImage = saveBase64ItemImage($variant->image, $uploadDir, $baseImageUrl);
            if ($savedVariantImage !== null) {
                $variantImageUrl = $savedVariantImage["url"];
            }
        }

        $variantStmt->execute([
            ":item_id" => $itemId,
            ":color_id" => isset($variant->color_id) && $variant->color_id !== '' ? (int)$variant->color_id : null,
            ":size_id" => isset($variant->size_id) && $variant->size_id !== '' ? (int)$variant->size_id : null,
            ":stock" => isset($variant->stock) ? (int)$variant->stock : 0,
            ":stock_quantity" => isset($variant->stock_quantity) ? (float)$variant->stock_quantity : (isset($variant->stock) ? (float)$variant->stock : 0),
            ":price" => isset($variant->price) ? (float)$variant->price : $itemPrice,
            ":image_url" => $variantImageUrl,
            ":sku" => isset($variant->sku) ? trim((string)$variant->sku) : null,
            ":unit" => isset($variant->unit) ? trim((string)$variant->unit) : $stockUnit,
            ":unit_quantity" => isset($variant->unit_quantity) ? max(0.001, (float)$variant->unit_quantity) : 1,
        ]);
        $newVariantId = (int)$con->lastInsertId();
        if (isset($variant->attribute_values) && is_array($variant->attribute_values)) {
            $linkStmt = $con->prepare("INSERT IGNORE INTO item_variant_values (variant_id, value_id)
                SELECT :variant_id, av.value_id
                FROM item_attribute_values av
                INNER JOIN item_attributes a ON a.attribute_id = av.attribute_id
                WHERE av.value_id = :value_id AND a.item_id = :item_id");
            foreach ($variant->attribute_values as $valueId) {
                $linkStmt->execute([
                    ':variant_id' => $newVariantId,
                    ':value_id' => (int)$valueId,
                    ':item_id' => $itemId,
                ]);
            }
        }
    }

    $modifierSummary = ['groups' => 0, 'options' => 0];
    if (property_exists($data, 'modifier_groups') && is_array($data->modifier_groups)) {
        $modifierSummary = dashboardSyncItemModifierGroups($con, $itemId, $data->modifier_groups);
    }

    $con->commit();

    broadcastNotification(
        $con,
        "new_product",
        "تمت إضافة منتج جديد",
        $itemNameAr !== "" ? $itemNameAr : ($itemNameEn !== "" ? $itemNameEn : "منتج جديد متاح الآن"),
        "item",
        $itemId,
        [
            "item_id" => (string)$itemId,
            "vendor_id" => (string)$targetVendorId,
        ],
        null
    );

    respond([
        "status" => "success",
        "message" => "Product added successfully",
        "item_id" => $itemId,
        "primary_image" => $savedImages[0]["url"],
        "images_count" => count($savedImages),
        "variants_count" => count($variants),
        "modifier_groups_count" => $modifierSummary['groups'],
        "modifier_options_count" => $modifierSummary['options'],
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    respond([
        "status" => "error",
        "message" => $e->getMessage(),
    ], 500);
}
?>
