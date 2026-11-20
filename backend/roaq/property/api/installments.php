<?php
// API: Get installments for a user and plan
require_once '../../connect.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$plan_id = isset($_GET['plan_id']) ? intval($_GET['plan_id']) : 0;
if ($user_id <= 0 || $plan_id <= 0) {
    echo json_encode(['error' => 'Invalid user_id or plan_id']);
    exit;
}

$sql = "SELECT * FROM property_installments WHERE user_id = ? AND plan_id = ? ORDER BY due_date ASC";
$stmt = $conn->prepare($sql);
$stmt->bind_param('ii', $user_id, $plan_id);
$stmt->execute();
$result = $stmt->get_result();
header('Content-Type: application/json');
$installments = $result->fetch_all(MYSQLI_ASSOC);
echo json_encode([
    'status' => 'success',
    'installments' => $installments
]);
