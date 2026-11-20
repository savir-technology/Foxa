<?php
include "../../../connect.php";
ensureAleppoFoodOrderingSchema();

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once __DIR__ . "/../modifier_helpers.php";

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
        $data = (object)$_POST;
    }

    if (empty($data->items_id)) {
        respond(["status" => "error", "message" => "Missing item id"], 400);
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

    $itemId = (int)$data->items_id;
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

    $uploadDir = realpath(__DIR__ . "/../../../") . DIRECTORY_SEPARATOR . "uploud" . DIRECTORY_SEPARATOR . "items";
    $baseImageUrl = "https://savir-technology.online/roaqv2/uploud/items";

    $variants = isset($data->variants) && is_array($data->variants) ? $data->variants : null;
    $images = isset($data->images) && is_array($data->images) ? $data->images : null;
    $modifierGroups = property_exists($data, 'modifier_groups') && is_array($data->modifier_groups)
        ? $data->modifier_groups
        : null;

    $checkSql = "
        SELECT items_id, items_image, vendor_id
        FROM items
        WHERE items_id = :item_id
    ";
    $checkParams = [":item_id" => $itemId];
    if ($isVendor) {
        $checkSql .= " AND vendor_id = :vendor_id";
        $checkParams[":vendor_id"] = (int)$actor['vendor']['vendor_id'];
    }
    $checkSql .= " LIMIT 1";

    $checkStmt = $con->prepare($checkSql);
    $checkStmt->execute($checkParams);
    $existingItem = $checkStmt->fetch(PDO::FETCH_ASSOC);
    if (!$existingItem) {
        respond(["status" => "error", "message" => "Item not found"], 404);
    }

    $vendorStmt = $con->prepare("SELECT vendor_type, store_category FROM vendors WHERE vendor_id = :vendor_id LIMIT 1");
    $vendorStmt->execute([':vendor_id' => (int)$existingItem['vendor_id']]);
    $vendor = $vendorStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    if (($vendor['vendor_type'] ?? 'restaurant') === 'store') {
        $expectedType = $vendor['store_category'] ?: 'general';
        if ($productType !== $expectedType) {
            respond(["status" => "error", "message" => "Product type must match the store specialization"], 422);
        }
        if ($modifierGroups !== null && !empty($modifierGroups)) {
            respond(["status" => "error", "message" => "Store products cannot use restaurant modifiers"], 422);
        }
    } else {
        $productType = 'food';
        $stockUnit = 'piece';
        $stockStep = 1.0;
        if ($variants !== null && !empty($variants)) {
            respond(["status" => "error", "message" => "Restaurant products cannot use generic variants; use modifier groups"], 422);
        }
    }

    // Backward compatibility: simple update when images/variants are not provided.
    if ($variants === null || $images === null) {
        $simpleImage = isset($data->items_image) ? $data->items_image : null;
        $modifierSummary = ['groups' => 0, 'options' => 0];

        $query = "
            UPDATE items SET
                items_name_en = :name_en,
                items_name_ar = :name_ar,
                items_desc_en = :desc_en,
                items_desc_ar = :desc_ar,
                items_price = :price,
                items_count = :count,
                items_discount = :discount,
                items_cat = :cat,
                items_active = :active,
                product_type = :product_type,
                stock_unit = :stock_unit,
                stock_step = :stock_step
        ";

        $isBase64 = isBase64Image($simpleImage);
        if ($isBase64) {
            $saved = saveBase64ItemImage($simpleImage, $uploadDir, $baseImageUrl);
            if ($saved === null) {
                respond(["status" => "error", "message" => "Invalid image data"], 400);
            }
            $query .= ", items_image = :image";
            $imageName = $saved["file_name"];
        }

        $query .= " WHERE items_id = :id";
        $stmt = $con->prepare($query);
        $stmt->bindValue(':id', $itemId, PDO::PARAM_INT);
        $stmt->bindValue(':name_en', $itemNameEn);
        $stmt->bindValue(':name_ar', $itemNameAr);
        $stmt->bindValue(':desc_en', $itemDescEn);
        $stmt->bindValue(':desc_ar', $itemDescAr);
        $stmt->bindValue(':price', $itemPrice);
        $stmt->bindValue(':count', isset($data->items_count) ? (int)$data->items_count : 0, PDO::PARAM_INT);
        $stmt->bindValue(':discount', isset($data->items_discount) ? (int)$data->items_discount : 0, PDO::PARAM_INT);
        $stmt->bindValue(':cat', $itemCat, PDO::PARAM_INT);
        $stmt->bindValue(':active', $itemActive, PDO::PARAM_INT);
        $stmt->bindValue(':product_type', $productType);
        $stmt->bindValue(':stock_unit', $stockUnit);
        $stmt->bindValue(':stock_step', $stockStep);
        if ($isBase64) {
            $stmt->bindValue(':image', $imageName);
        }

        if ($modifierGroups !== null) {
            $con->beginTransaction();
        }

        $stmt->execute();

        if ($modifierGroups !== null) {
            $modifierSummary = dashboardSyncItemModifierGroups($con, $itemId, $modifierGroups);
            $con->commit();
        }

        respond([
            "status" => "success",
            "message" => "Product updated successfully",
            "modifier_groups_count" => $modifierSummary['groups'],
            "modifier_options_count" => $modifierSummary['options'],
        ]);
    }

    if (empty($images)) {
        respond(["status" => "error", "message" => "At least one image is required"], 400);
    }

    $finalImages = [];
    foreach ($images as $index => $imagePayload) {
        $imgType = isset($imagePayload->img_type) ? (string)$imagePayload->img_type : "normal";
        $colorId = isset($imagePayload->color_id) && $imagePayload->color_id !== null
            ? (int)$imagePayload->color_id
            : null;

        if (isset($imagePayload->data) && isBase64Image($imagePayload->data)) {
            $saved = saveBase64ItemImage($imagePayload->data, $uploadDir, $baseImageUrl);
            if ($saved === null) {
                respond(["status" => "error", "message" => "Invalid image payload at index {$index}"], 400);
            }
            $finalImages[] = [
                "url" => $saved["url"],
                "file_name" => $saved["file_name"],
                "color_id" => $colorId,
                "img_type" => $imgType === "360" ? "360" : "normal",
            ];
            continue;
        }

        if (isset($imagePayload->url) && is_string($imagePayload->url) && trim($imagePayload->url) !== "") {
            $url = trim($imagePayload->url);
            $parsedPath = parse_url($url, PHP_URL_PATH);
            $fileName = $parsedPath ? basename($parsedPath) : basename($url);
            $finalImages[] = [
                "url" => $url,
                "file_name" => $fileName,
                "color_id" => $colorId,
                "img_type" => $imgType === "360" ? "360" : "normal",
            ];
            continue;
        }

        respond(["status" => "error", "message" => "Invalid image payload at index {$index}"], 400);
    }

    $itemCount = 0;
    $isWeightCatalog = $productType === 'fresh_food';
    foreach ($variants as $index => $variant) {
        $stock = isset($variant->stock_quantity) ? (float)$variant->stock_quantity : (isset($variant->stock) ? (float)$variant->stock : 0);
        $itemCount = $isWeightCatalog
            ? max($itemCount, max(0, $stock))
            : $itemCount + max(0, (int)$stock);
    }

    $primaryImageName = $finalImages[0]["file_name"];

    $con->beginTransaction();

    $updateItemStmt = $con->prepare("
        UPDATE items
        SET
            items_name_en = :items_name_en,
            items_name_ar = :items_name_ar,
            items_desc_en = :items_desc_en,
            items_desc_ar = :items_desc_ar,
            items_image = :items_image,
            items_count = :items_count,
            items_active = :items_active,
            items_price = :items_price,
            items_discount = :items_discount,
            items_cat = :items_cat
            , product_type = :product_type
            , stock_unit = :stock_unit
            , stock_step = :stock_step
        WHERE items_id = :items_id
    ");

    $updateItemStmt->execute([
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
        ":items_id" => $itemId,
        ":product_type" => $productType,
        ":stock_unit" => $stockUnit,
        ":stock_step" => $stockStep,
    ]);

    $deleteImagesStmt = $con->prepare("DELETE FROM items_images WHERE item_id = :item_id");
    $deleteImagesStmt->execute([":item_id" => $itemId]);

    $insertImageStmt = $con->prepare("
        INSERT INTO items_images (item_id, color_id, img_path, img_type, img_order)
        VALUES (:item_id, :color_id, :img_path, :img_type, :img_order)
    ");
    foreach ($finalImages as $index => $image) {
        $insertImageStmt->execute([
            ":item_id" => $itemId,
            ":color_id" => $image["color_id"],
            ":img_path" => $image["url"],
            ":img_type" => $image["img_type"],
            ":img_order" => $index,
        ]);
    }

    $deleteVariantsStmt = $con->prepare("DELETE FROM item_variants WHERE item_id = :item_id");
    $deleteVariantsStmt->execute([":item_id" => $itemId]);

    $insertVariantStmt = $con->prepare("
        INSERT INTO item_variants (item_id, color_id, size_id, stock, stock_quantity, unit, unit_quantity, price, image_url, sku)
        VALUES (:item_id, :color_id, :size_id, :stock, :stock_quantity, :unit, :unit_quantity, :price, :image_url, :sku)
    ");

    foreach ($variants as $variant) {
        $variantImageUrl = null;
        if (isset($variant->image) && isBase64Image($variant->image)) {
            $savedVariantImage = saveBase64ItemImage($variant->image, $uploadDir, $baseImageUrl);
            if ($savedVariantImage !== null) {
                $variantImageUrl = $savedVariantImage["url"];
            }
        } elseif (isset($variant->image_url) && is_string($variant->image_url) && trim($variant->image_url) !== "") {
            $variantImageUrl = trim($variant->image_url);
        }

        $insertVariantStmt->execute([
            ":item_id" => $itemId,
            ":color_id" => isset($variant->color_id) && $variant->color_id !== '' ? (int)$variant->color_id : null,
            ":size_id" => isset($variant->size_id) && $variant->size_id !== '' ? (int)$variant->size_id : null,
            ":stock" => isset($variant->stock) ? (int)$variant->stock : 0,
            ":stock_quantity" => isset($variant->stock_quantity) ? (float)$variant->stock_quantity : (isset($variant->stock) ? (float)$variant->stock : 0),
            ":unit" => isset($variant->unit) ? trim((string)$variant->unit) : $stockUnit,
            ":unit_quantity" => isset($variant->unit_quantity) ? max(0.001, (float)$variant->unit_quantity) : 1,
            ":price" => isset($variant->price) ? (float)$variant->price : $itemPrice,
            ":image_url" => $variantImageUrl,
            ":sku" => isset($variant->sku) ? trim((string)$variant->sku) : null,
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
    if ($modifierGroups !== null) {
        $modifierSummary = dashboardSyncItemModifierGroups($con, $itemId, $modifierGroups);
    }

    $con->commit();

    respond([
        "status" => "success",
        "message" => "Product updated successfully",
        "item_id" => $itemId,
        "images_count" => count($finalImages),
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
