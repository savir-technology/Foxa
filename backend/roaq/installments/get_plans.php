<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

$property_id = $_GET['property_id'] ?? null;

if (!$property_id) {
    echo json_encode(["status"=>"fail","message"=>"missing property_id"]);
    exit;
}

$stmt = $con->prepare("SELECT * FROM installment_plans WHERE property_id = ?");
$stmt->execute([$property_id]);
$plans = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode(["status"=>"success","plans"=>$plans]);

?>
