<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

$property_id = $_GET['property_id'] ?? null;
$user_id = $_GET['user_id'] ?? null;

if (!$property_id && !$user_id) {
    echo json_encode(["status"=>"fail","message"=>"missing property_id or user_id"]);
    exit;
}

if ($property_id) {
    $stmt = $con->prepare("SELECT * FROM property_calendar WHERE property_id = ? ORDER BY event_date");
    $stmt->execute([$property_id]);
} else {
    $stmt = $con->prepare("SELECT * FROM property_calendar WHERE user_id = ? ORDER BY event_date");
    $stmt->execute([$user_id]);
}

$events = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["status"=>"success","events"=>$events]);

?>
