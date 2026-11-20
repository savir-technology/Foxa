<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

$contract_id = intval($_POST['contract_id'] ?? 0);
$down_payment = isset($_POST['down_payment']) ? floatval($_POST['down_payment']) : null;
$down_payment_paid = intval($_POST['down_payment_paid'] ?? 0) ? 1 : 0;
$start_date_input = trim((string) ($_POST['start_date'] ?? ''));
$frequency = trim((string) ($_POST['frequency'] ?? 'monthly'));

if ($contract_id <= 0 || $down_payment === null) {
    echo json_encode(['status' => 'fail', 'message' => 'contract_id and down_payment are required']);
    exit;
}

try {
    $contractStmt = $con->prepare(
        "SELECT pc.contract_id, pc.user_id, pc.plan_id, pc.item_id,
                pp.total_price, pp.duration_months, pp.start_date
         FROM property_contracts pc
         INNER JOIN property_plans pp ON pp.plan_id = pc.plan_id
         WHERE pc.contract_id = :contract_id
         LIMIT 1"
    );
    $contractStmt->execute([':contract_id' => $contract_id]);
    $contract = $contractStmt->fetch(PDO::FETCH_ASSOC);

    if (!$contract) {
        echo json_encode(['status' => 'fail', 'message' => 'Contract not found']);
        exit;
    }

    $total_price = floatval($contract['total_price'] ?? 0);
    $duration = intval($contract['duration_months'] ?? 0);

    if ($duration <= 0) {
        echo json_encode(['status' => 'fail', 'message' => 'Invalid plan duration']);
        exit;
    }

    if ($down_payment < 0 || $down_payment > $total_price) {
        echo json_encode(['status' => 'fail', 'message' => 'Down payment out of range']);
        exit;
    }

    $remaining = $total_price - $down_payment;
    $monthly = round($remaining / $duration, 2);

    $startRaw = $start_date_input !== '' ? $start_date_input : trim((string) ($contract['start_date'] ?? ''));
    if ($startRaw === '' || $startRaw === '0000-00-00') {
        $startDate = new DateTime('today');
    } else {
        $startDate = new DateTime($startRaw);
    }

    $allowedFreq = ['monthly', 'quarterly', 'semiannual'];
    if (!in_array($frequency, $allowedFreq, true)) {
        $frequency = 'monthly';
    }
    $intervalMonths = $frequency === 'quarterly' ? 3 : ($frequency === 'semiannual' ? 6 : 1);

    $con->beginTransaction();

    $updateContract = $con->prepare(
        "UPDATE property_contracts
         SET down_payment_amount = :down_payment,
             down_payment_paid = :down_payment_paid,
             down_payment_paid_at = CASE
                 WHEN :down_payment_paid = 1 THEN COALESCE(down_payment_paid_at, NOW())
                 ELSE NULL
             END,
             monthly_installment = :monthly_installment
         WHERE contract_id = :contract_id"
    );
    $updateContract->execute([
        ':down_payment' => $down_payment,
        ':down_payment_paid' => $down_payment_paid,
        ':monthly_installment' => $monthly,
        ':contract_id' => $contract_id,
    ]);

    $deleteInstallments = $con->prepare(
        "DELETE FROM property_installments
         WHERE contract_id = :contract_id
            OR (contract_id IS NULL AND plan_id = :plan_id AND user_id = :user_id)"
    );
    $deleteInstallments->execute([
        ':contract_id' => $contract_id,
        ':plan_id' => intval($contract['plan_id']),
        ':user_id' => intval($contract['user_id']),
    ]);

    $insertInstallment = $con->prepare(
        "INSERT INTO property_installments
         (contract_id, plan_id, user_id, due_date, amount, status, created_at)
         VALUES (:contract_id, :plan_id, :user_id, :due_date, :amount, 'pending', NOW())"
    );

    for ($i = 0; $i < $duration; $i++) {
        $due = clone $startDate;
        $due->modify('+' . ($i * $intervalMonths) . ' months');
        $insertInstallment->execute([
            ':contract_id' => $contract_id,
            ':plan_id' => intval($contract['plan_id']),
            ':user_id' => intval($contract['user_id']),
            ':due_date' => $due->format('Y-m-d'),
            ':amount' => $monthly,
        ]);
    }

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'contract_id' => $contract_id,
        'down_payment' => $down_payment,
        'remaining' => $remaining,
        'monthly_installment' => $monthly,
        'total_installments' => $duration,
        'start_date' => $startDate->format('Y-m-d'),
        'frequency' => $frequency,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    error_log('set_contract_installments.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
