<?php
// orderStatus.php
header("Content-Type: application/json; charset=UTF-8");
require_once "connect.php";

$userid = isset($_GET['userid']) ? (int)$_GET['userid'] : 0;
if (!$userid) { echo json_encode(["error"=>"missing userid"]); exit; }

$stmt = $con->prepare("SELECT orders_id, orders_totalprice, orders_status, orders_datetime, orders_pricedelivery FROM orders WHERE orders_usersid = ? ORDER BY orders_id DESC LIMIT 5");
$stmt->execute([$userid]);
$orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["orders"=>$orders], JSON_UNESCAPED_UNICODE);
