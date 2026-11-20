<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Admin view: list plans or a specific property_id
$property_id = $_GET['property_id'] ?? null;
if ($property_id) {
    $stmt = $con->prepare("SELECT * FROM installment_plans WHERE property_id = ? ORDER BY created_at DESC");
    $stmt->execute([$property_id]);
} else {
    $stmt = $con->prepare("SELECT * FROM installment_plans ORDER BY created_at DESC");
    $stmt->execute();
}

$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["status"=>"success","plans"=>$rows]);

?>
