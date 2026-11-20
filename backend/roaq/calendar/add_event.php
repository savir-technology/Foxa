<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Params: property_id, user_id, event_type (visit|payment|meeting), event_date (YYYY-MM-DD), note
$property_id = $_POST['property_id'] ?? null;
$user_id = $_POST['user_id'] ?? null;
$event_type = $_POST['event_type'] ?? 'visit';
$event_date = $_POST['event_date'] ?? null;
$note = $_POST['note'] ?? null;

if (!$property_id || !$user_id || !$event_date) {
    echo json_encode(["status"=>"fail","message"=>"missing params"]);
    exit;
}

try {
    $stmt = $con->prepare("INSERT INTO property_calendar (property_id, user_id, event_type, event_date, note, created_at) VALUES (?, ?, ?, ?, ?, current_timestamp())");
    $stmt->execute([$property_id, $user_id, $event_type, $event_date, $note]);
    $id = $con->lastInsertId();
    echo json_encode(["status"=>"success","id"=>(int)$id]);
} catch (Exception $e) {
    echo json_encode(["status"=>"error","message"=>$e->getMessage()]);
}

?>
