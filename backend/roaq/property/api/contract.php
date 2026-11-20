<?php
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = intval($_POST['user_id'] ?? 0);
$item_id = intval($_POST['item_id'] ?? 0);
$plan_id = isset($_POST['plan_id']) ? intval($_POST['plan_id']) : null;

if ($user_id <= 0 || $item_id <= 0) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid data']);
    exit;
}

$sql = "INSERT INTO property_contracts (user_id, item_id, plan_id, status)
        VALUES (?, ?, ?, 'pending')";
$stmt = $conn->prepare($sql);
$stmt->bind_param('iii', $user_id, $item_id, $plan_id);

if ($stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'contract_id' => $conn->insert_id
    ]);
} else {
    http_response_code(500);
    echo json_encode(['status' => 'error']);
}
