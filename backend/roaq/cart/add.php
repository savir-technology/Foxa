<?php
include "../connect.php";
$usersid = filterRequest("usersid");
$itemsid = filterRequest("itemsid");
$cartid = filterRequest("cartid");
$variantid = filterRequest("variantid");
$itemColor = filterRequest("item_color");
$itemSize = filterRequest("item_size");
$lensCode = filterRequest("lens_code");
$lensName = filterRequest("lens_name");
$lensColor = filterRequest("lens_color");
$lensFeatures = filterRequest("lens_features");
$lensPrice = filterRequest("lens_price");
$prescriptionJson = filterRequest("prescription_json");
$prescriptionSummary = filterRequest("prescription_summary");
$configHash = filterRequest("config_hash");
$cartContextType = filterRequest("cart_context_type");
$cartVendorId = filterRequest("cart_vendor_id");
$cartUnitPrice = filterRequest("cart_unit_price");
$cartItemNote = filterRequest("cart_item_note");
$cartMenuOptionsJson = filterRequest("cart_menu_options_json");
$cartMenuOptionsSummary = filterRequest("cart_menu_options_summary");
$cartVariantAttributesJson = filterRequest("cart_variant_attributes_json");
$cartQuantityWeight = filterRequest("quantity_weight");
if (!$usersid || !$itemsid) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}
try {
    $resolvedCartVendorId = null;
    if ($cartVendorId !== null && $cartVendorId !== '') {
        $resolvedCartVendorId = (int) $cartVendorId;
    } else {
        $vendorStmt = $con->prepare("
            SELECT vendor_id
            FROM items
            WHERE items_id = :item_id
            LIMIT 1
        ");
        $vendorStmt->execute([':item_id' => $itemsid]);
        $resolvedCartVendorId = (int)($vendorStmt->fetchColumn() ?: 0);
        if ($resolvedCartVendorId <= 0) {
            $resolvedCartVendorId = null;
        }
    }
    if ($variantid) {
        $variantStmt = $con->prepare("
            SELECT v.variant_id, c.color_name, s.size_name
            FROM item_variants v
            LEFT JOIN colors c ON c.color_id = v.color_id
            LEFT JOIN sizes s ON s.size_id = v.size_id
            WHERE v.variant_id = :variantid AND v.item_id = :itemid
            LIMIT 1
        ");
        $variantStmt->execute([
            ":variantid" => $variantid,
            ":itemid" => $itemsid,
        ]);
        $variantRow = $variantStmt->fetch(PDO::FETCH_ASSOC);
        if (!$variantRow) {
            echo json_encode(["status" => "error", "message" => "Invalid variant"]);
            exit;
        }
        $itemColor = $variantRow['color_name'] ?? $itemColor;
        $itemSize = $variantRow['size_name'] ?? $itemSize;
    } else {
        $variantid = null;
    }
    if ($cartid) {
        $stmt = $con->prepare("
            SELECT cart_id, cart_quantity, cart_quantity_weight
            FROM cart
            WHERE cart_id = :cartid AND cart_usersid = :uid AND cart_orders = 0
            LIMIT 1
        ");
        $stmt->execute([":cartid" => $cartid, ":uid" => $usersid]);
    } else if ($configHash) {
        $stmt = $con->prepare("
            SELECT cart_id, cart_quantity, cart_quantity_weight
            FROM cart
            WHERE cart_usersid = :uid
              AND cart_itemsid = :iid
              AND COALESCE(cart_variantid, 0) = COALESCE(:variantid, 0)
              AND cart_config_hash = :hash
              AND cart_orders = 0
            LIMIT 1
        ");
        $stmt->execute([
            ":uid" => $usersid,
            ":iid" => $itemsid,
            ":variantid" => $variantid,
            ":hash" => $configHash
        ]);
    } else {
        $stmt = $con->prepare("
            SELECT cart_id, cart_quantity, cart_quantity_weight
            FROM cart
            WHERE cart_usersid = :uid
              AND cart_itemsid = :iid
              AND COALESCE(cart_variantid, 0) = COALESCE(:variantid, 0)
              AND cart_orders = 0
              AND (cart_config_hash IS NULL OR cart_config_hash = '')
            LIMIT 1
        ");
        $stmt->execute([
            ":uid" => $usersid,
            ":iid" => $itemsid,
            ":variantid" => $variantid
        ]);
    }
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        $isWeightCart = $cartQuantityWeight !== null && $cartQuantityWeight !== '' && $row['cart_quantity_weight'] !== null;
        $newQ = $isWeightCart ? 1 : ((int) $row['cart_quantity']) + 1;
        $newWeight = $isWeightCart
            ? (float)$row['cart_quantity_weight'] + (float)$cartQuantityWeight
            : null;
        $upd = $con->prepare("UPDATE cart SET cart_quantity = :q, cart_quantity_weight = :weight WHERE cart_id = :id");
        $upd->execute([":q" => $newQ, ":weight" => $newWeight, ":id" => $row['cart_id']]);
        echo json_encode([
            "status" => "success",
            "action" => "increment",
            "quantity" => $newQ,
            "cart_id" => $row['cart_id']
        ]);
    } else {
        $ins = $con->prepare("
            INSERT INTO cart (
                cart_usersid,
                cart_itemsid,
                cart_variantid,
                cart_quantity,
                cart_orders,
                cart_lens_code,
                cart_lens_name,
                cart_lens_color,
                cart_lens_features,
                cart_lens_price,
                cart_prescription_json,
                cart_prescription_summary,
                cart_config_hash,
                cart_context_type,
                cart_vendor_id,
                cart_unit_price,
                cart_item_note,
                cart_menu_options_json,
                cart_menu_options_summary,
                cart_variant_attributes_json,
                cart_quantity_weight
            ) VALUES (
                :uid, :iid, :variantid, 1, 0, :lens_code, :lens_name, :lens_color,
                :lens_features, :lens_price, :prescription_json,
                :prescription_summary, :config_hash, :cart_context_type, :cart_vendor_id,
                :cart_unit_price, :cart_item_note, :cart_menu_options_json, :cart_menu_options_summary,
                :cart_variant_attributes_json,
                :cart_quantity_weight
            )
        ");
        $ins->execute([
            ":uid" => $usersid,
            ":iid" => $itemsid,
            ":variantid" => $variantid,
            ":lens_code" => $lensCode ?: null,
            ":lens_name" => $lensName ?: null,
            ":lens_color" => $lensColor ?: null,
            ":lens_features" => $lensFeatures ?: null,
            ":lens_price" => $lensPrice !== null && $lensPrice !== '' ? $lensPrice : 0,
            ":prescription_json" => $prescriptionJson ?: null,
            ":prescription_summary" => $prescriptionSummary ?: null,
            ":config_hash" => $configHash ?: null,
            ":cart_context_type" => $cartContextType ?: 'product',
            ":cart_vendor_id" => $resolvedCartVendorId,
            ":cart_unit_price" => $cartUnitPrice !== null && $cartUnitPrice !== '' ? $cartUnitPrice : null,
            ":cart_item_note" => $cartItemNote ?: null,
            ":cart_menu_options_json" => $cartMenuOptionsJson ?: null,
            ":cart_menu_options_summary" => $cartMenuOptionsSummary ?: null,
            ":cart_variant_attributes_json" => $cartVariantAttributesJson ?: null,
            ":cart_quantity_weight" => $cartQuantityWeight !== null && $cartQuantityWeight !== '' ? $cartQuantityWeight : null,
        ]);
        echo json_encode([
            "status" => "success",
            "action" => "insert",
            "cart_id" => $con->lastInsertId(),
            "item_color" => $itemColor,
            "item_size" => $itemSize
        ]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
