<?php
// Admin API: Update contract status
require_once '../../../connect.php';

$contract_id = isset($_POST['contract_id']) ? intval($_POST['contract_id']) : 0;
$status = isset($_POST['status']) ? $_POST['status'] : '';
$allowed = ['pending','approved','rejected','active','canceled'];
if ($contract_id <= 0 || !in_array($status, $allowed)) {
    echo json_encode(['error' => 'Invalid contract_id or status']);
    exit;
}
$sql = "UPDATE property_contracts SET status = ? WHERE contract_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('si', $status, $contract_id);
if ($stmt->execute()) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['error' => $conn->error]);
}
