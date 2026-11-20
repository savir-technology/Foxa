<?php
include "../connect.php";

$usersid = filterRequest("usersid");
$itemsid = filterRequest("itemsid");
$cartid = filterRequest("cartid");
$cartQuantityWeight = filterRequest("quantity_weight");

if (!$usersid || (!$itemsid && !$cartid)) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    if ($cartid) {
        $stmt = $con->prepare("SELECT cart_id, cart_quantity, cart_quantity_weight FROM cart WHERE cart_id = :cartid AND cart_usersid = :usersid AND cart_orders = 0 LIMIT 1");
        $stmt->execute([":cartid" => $cartid, ":usersid" => $usersid]);
    } else {
        $stmt = $con->prepare("SELECT cart_id, cart_quantity, cart_quantity_weight FROM cart WHERE cart_usersid = :usersid AND cart_itemsid = :itemsid AND cart_orders = 0 LIMIT 1");
        $stmt->execute([":usersid" => $usersid, ":itemsid" => $itemsid]);
    }

    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row) {
        $isWeightCart = $cartQuantityWeight !== null && $cartQuantityWeight !== '' && $row['cart_quantity_weight'] !== null;
        if ($isWeightCart && (float)$row['cart_quantity_weight'] > (float)$cartQuantityWeight) {
            $newWeight = max(0, (float)$row['cart_quantity_weight'] - (float)$cartQuantityWeight);
            $updateStmt = $con->prepare("UPDATE cart SET cart_quantity = 1, cart_quantity_weight = :weight WHERE cart_id = :id");
            $updateStmt->execute([":weight" => $newWeight, ":id" => $row['cart_id']]);
        } elseif (!$isWeightCart && (int)$row["cart_quantity"] > 1) {
            $newQuantity = ((int)$row["cart_quantity"]) - 1;
            $updateStmt = $con->prepare("UPDATE cart SET cart_quantity = :q WHERE cart_id = :id");
            $updateStmt->execute([":q" => $newQuantity, ":id" => $row["cart_id"]]);
        } else {
            $deleteStmt = $con->prepare("DELETE FROM cart WHERE cart_id = :id");
            $deleteStmt->execute([":id" => $row["cart_id"]]);
        }
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Item not found"]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
