<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

$property_id = $_GET['property_id'] ?? null;
if (!$property_id) {
    echo json_encode(["status"=>"fail","message"=>"missing property_id"]);
    exit;
}

$stmt = $con->prepare("SELECT * FROM property_calendar WHERE property_id = ? ORDER BY event_date DESC");
$stmt->execute([$property_id]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode(["status"=>"success","events"=>$rows]);

?>
