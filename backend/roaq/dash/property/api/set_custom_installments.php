<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

$contract_id = intval($_POST['contract_id'] ?? 0);
$items_raw = trim((string) ($_POST['items'] ?? ''));
$auto_adjust = isset($_POST['auto_adjust']) ? intval($_POST['auto_adjust']) : 1;

if ($contract_id <= 0 || $items_raw === '') {
    echo json_encode(['status' => 'fail', 'message' => 'contract_id and items are required']);
    exit;
}

try {
    $items = json_decode($items_raw, true);
    if (!is_array($items) || count($items) === 0) {
        echo json_encode(['status' => 'fail', 'message' => 'Invalid items payload']);
        exit;
    }

    $contractStmt = $con->prepare(
        "SELECT pc.contract_id, pc.user_id, pc.plan_id,
                pp.total_price,
                COALESCE(pc.down_payment_amount, pp.down_payment, 0) AS down_payment
         FROM property_contracts pc
         INNER JOIN property_plans pp ON pp.plan_id = pc.plan_id
         WHERE pc.contract_id = :id
         LIMIT 1"
    );
    $contractStmt->execute([':id' => $contract_id]);
    $contract = $contractStmt->fetch(PDO::FETCH_ASSOC);

    if (!$contract) {
        echo json_encode(['status' => 'fail', 'message' => 'Contract not found']);
        exit;
    }

    $allowedStatus = ['pending', 'paid', 'late', 'receipt_uploaded', 'rejected'];
    $rows = [];
    $sum = 0.0;

    foreach ($items as $row) {
        $due_date = trim((string) ($row['due_date'] ?? ''));
        $amount = isset($row['amount']) ? floatval($row['amount']) : null;
        $status = trim((string) ($row['status'] ?? 'pending'));

        if ($due_date === '' || $amount === null || $amount < 0) {
            echo json_encode(['status' => 'fail', 'message' => 'Invalid item values']);
            exit;
        }
        $date = DateTime::createFromFormat('Y-m-d', $due_date);
        if (!$date || $date->format('Y-m-d') !== $due_date) {
            echo json_encode(['status' => 'fail', 'message' => 'Invalid date format']);
            exit;
        }
        if (!in_array($status, $allowedStatus, true)) {
            $status = 'pending';
        }

        $rows[] = [
            'due_date' => $due_date,
            'amount' => $amount,
            'status' => $status,
        ];
        $sum += $amount;
    }

    $total_price = floatval($contract['total_price'] ?? 0);
    $down_payment = floatval($contract['down_payment'] ?? 0);
    $remaining = $total_price - $down_payment;
    if ($remaining < 0) $remaining = 0;

    $diff = round($remaining - $sum, 2);
    $adjusted = false;
    if (abs($diff) > 0.01) {
        if ($auto_adjust === 1 && count($rows) > 0) {
            $lastIndex = count($rows) - 1;
            $rows[$lastIndex]['amount'] = round($rows[$lastIndex]['amount'] + $diff, 2);
            if ($rows[$lastIndex]['amount'] < 0) {
                echo json_encode([
                    'status' => 'fail',
                    'message' => 'Adjusted installment became negative',
                    'remaining' => $remaining,
                    'sum' => round($sum, 2),
                ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
                exit;
            }
            $sum = round($sum + $diff, 2);
            $adjusted = true;
        } else {
            echo json_encode([
                'status' => 'fail',
                'message' => 'Sum of installments does not match remaining amount',
                'remaining' => $remaining,
                'sum' => round($sum, 2),
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            exit;
        }
    }

    $con->beginTransaction();

    $del = $con->prepare(
        "DELETE FROM property_installments WHERE contract_id = :id"
    );
    $del->execute([':id' => $contract_id]);

    $ins = $con->prepare(
        "INSERT INTO property_installments
         (contract_id, plan_id, user_id, due_date, amount, status, created_at)
         VALUES (:contract_id, :plan_id, :user_id, :due_date, :amount, :status, NOW())"
    );

    foreach ($rows as $row) {
        $ins->execute([
            ':contract_id' => $contract_id,
            ':plan_id' => intval($contract['plan_id']),
            ':user_id' => intval($contract['user_id']),
            ':due_date' => $row['due_date'],
            ':amount' => $row['amount'],
            ':status' => $row['status'],
        ]);
    }

    $avg = count($rows) > 0 ? round($sum / count($rows), 2) : null;
    $upd = $con->prepare(
        "UPDATE property_contracts
         SET monthly_installment = :avg
         WHERE contract_id = :id"
    );
    $upd->execute([':avg' => $avg, ':id' => $contract_id]);

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'contract_id' => $contract_id,
        'count' => count($rows),
        'total' => round($sum, 2),
        'adjusted' => $adjusted,
        'adjust_diff' => $diff,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    error_log('set_custom_installments.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
