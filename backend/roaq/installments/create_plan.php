<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Params: property_id, total_amount, down_payment, installment_type (monthly|yearly), installment_count
$property_id = $_POST['property_id'] ?? null;
$total_amount = $_POST['total_amount'] ?? null;
$down_payment = $_POST['down_payment'] ?? 0;
$installment_type = $_POST['installment_type'] ?? 'monthly';
$installment_count = $_POST['installment_count'] ?? null;

if (!$property_id || !$total_amount || !$installment_count) {
    echo json_encode(["status"=>"fail","message"=>"missing params"]);
    exit;
}

$installment_value = ($total_amount - $down_payment) / max(1, (int)$installment_count);

try {
    $stmt = $con->prepare("INSERT INTO installment_plans (property_id, total_amount, down_payment, installment_type, installment_count, installment_value, created_at) VALUES (?, ?, ?, ?, ?, ?, current_timestamp())");
    $stmt->execute([$property_id, $total_amount, $down_payment, $installment_type, $installment_count, $installment_value]);
    $plan_id = $con->lastInsertId();

    echo json_encode(["status"=>"success","plan_id"=>(int)$plan_id,"installment_value"=>(float)$installment_value]);
} catch (Exception $e) {
    echo json_encode(["status"=>"error","message"=>$e->getMessage()]);
}

?>
