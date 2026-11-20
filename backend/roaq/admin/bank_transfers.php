<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Simple admin list of bank transfers. Optional status filter
$status = $_GET['status'] ?? null;
if ($status) {
    $stmt = $con->prepare("SELECT * FROM bank_transfers WHERE status = ? ORDER BY created_at DESC");
    $stmt->execute([$status]);
} else {
    $stmt = $con->prepare("SELECT * FROM bank_transfers ORDER BY created_at DESC");
    $stmt->execute();
}

$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["status"=>"success","transfers"=>$rows]);

?>
