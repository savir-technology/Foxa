<?php
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = intval($_POST['user_id'] ?? 0);
$plan_id = intval($_POST['plan_id'] ?? 0);

if ($user_id <= 0 || $plan_id <= 0) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid data']);
    exit;
}

// هل الأقساط موجودة؟
$check = $con->prepare(
    "SELECT COUNT(*) FROM property_installments WHERE user_id = ? AND plan_id = ?"
);
$check->execute([$user_id, $plan_id]);
$count = intval($check->fetchColumn() ?: 0);

if ($count > 0) {
    echo json_encode(['status' => 'exists']);
    exit;
}

// بيانات الخطة
$stmt = $con->prepare(
    "SELECT duration_months, installment_amount, start_date
     FROM property_plans WHERE plan_id = ?"
);
$stmt->execute([$plan_id]);
$plan = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$plan) {
    echo json_encode(['status' => 'error', 'message' => 'Plan not found']);
    exit;
}

$contractStmt = $con->prepare(
    "SELECT contract_id FROM property_contracts
     WHERE user_id = ? AND plan_id = ?
     ORDER BY contract_id DESC
     LIMIT 1"
);
$contractStmt->execute([$user_id, $plan_id]);
$contract_id = intval($contractStmt->fetchColumn() ?: 0);

$startRaw = trim((string) ($plan['start_date'] ?? ''));
if ($startRaw === '' || $startRaw === '0000-00-00') {
    $start_date = new DateTime('today');
} else {
    $start_date = new DateTime($startRaw);
}

$con->beginTransaction();

try {
    $ins = $con->prepare(
        "INSERT INTO property_installments (contract_id, user_id, plan_id, due_date, amount)
         VALUES (?, ?, ?, ?, ?)"
    );
    for ($i = 0; $i < intval($plan['duration_months']); $i++) {
        $due_date = clone $start_date;
        $due_date->modify('+' . $i . ' months');
        $ins->execute([
            $contract_id > 0 ? $contract_id : null,
            $user_id,
            $plan_id,
            $due_date->format('Y-m-d'),
            $plan['installment_amount'],
        ]);
    }
    $con->commit();
    echo json_encode(['status' => 'success']);
} catch (Exception $e) {
    $con->rollBack();
    http_response_code(500);
    echo json_encode(['status' => 'error']);
}
