<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Params: reservation_id, property_id, user_id, payment_amount, payment_due_date, payment_method (bank_transfer)
$reservation_id = $_POST['reservation_id'] ?? null;
$property_id = $_POST['property_id'] ?? null;
$user_id = $_POST['user_id'] ?? null;
$payment_amount = $_POST['payment_amount'] ?? null;
$payment_due_date = $_POST['payment_due_date'] ?? null;
$payment_method = $_POST['payment_method'] ?? 'bank_transfer';

if (!$reservation_id || !$property_id || !$user_id || !$payment_amount || !$payment_due_date) {
    echo json_encode(["status"=>"fail","message"=>"missing params"]);
    exit;
}

try {
    $stmt = $con->prepare("INSERT INTO installment_payments (reservation_id, property_id, user_id, payment_amount, payment_status, payment_method, payment_due_date, created_at) VALUES (?, ?, ?, ?, 'pending', ?, ?, current_timestamp())");
    $stmt->execute([$reservation_id, $property_id, $user_id, $payment_amount, $payment_method, $payment_due_date]);
    $payment_id = $con->lastInsertId();

    echo json_encode(["status"=>"success","payment_id"=>(int)$payment_id]);
} catch (Exception $e) {
    echo json_encode(["status"=>"error","message"=>$e->getMessage()]);
}

?>
