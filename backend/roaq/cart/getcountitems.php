<?php
include "../connect.php";

$usersid = filterRequest("usersid");
$itemsid = filterRequest("itemsid");

if (!$usersid || !$itemsid) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

try {
    $stmt = $con->prepare("SELECT COALESCE(SUM(cart_quantity),0) as countitems FROM cart WHERE cart_usersid = :uid AND cart_itemsid = :iid AND cart_orders = 0");
    $stmt->execute([":uid" => $usersid, ":iid" => $itemsid]);
    $data = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $data['countitems']]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
