<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

$installment_id = intval($_POST['installment_id'] ?? 0);
$new_amount = isset($_POST['amount']) ? floatval($_POST['amount']) : null;
$posted_contract_id = intval($_POST['contract_id'] ?? 0);

if ($installment_id <= 0 || $new_amount === null) {
    echo json_encode(['status' => 'fail', 'message' => 'Invalid installment_id or amount']);
    exit;
}

try {
    $select = $con->prepare(
        "SELECT pi.installment_id, pi.contract_id, pi.plan_id, pi.user_id, pi.due_date, pi.status,
                pc.down_payment_amount, pp.total_price
         FROM property_installments pi
         LEFT JOIN property_contracts pc ON pc.contract_id = pi.contract_id
         LEFT JOIN property_plans pp ON pp.plan_id = pi.plan_id
         WHERE pi.installment_id = :id
         LIMIT 1"
    );
    $select->execute([':id' => $installment_id]);
    $row = $select->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo json_encode(['status' => 'fail', 'message' => 'Installment not found']);
        exit;
    }

    $contract_id = intval($row['contract_id'] ?? 0);
    if ($posted_contract_id > 0) {
        $contract_id = $posted_contract_id;
    }
    $plan_id = intval($row['plan_id'] ?? 0);
    $user_id = intval($row['user_id'] ?? 0);
    $down_payment = floatval($row['down_payment_amount'] ?? 0);
    $total_price = floatval($row['total_price'] ?? 0);

    if ($contract_id <= 0) {
        $contractStmt = $con->prepare(
            "SELECT contract_id, down_payment_amount
             FROM property_contracts
             WHERE user_id = :user_id AND plan_id = :plan_id
             ORDER BY contract_id DESC
             LIMIT 1"
        );
        $contractStmt->execute([':user_id' => $user_id, ':plan_id' => $plan_id]);
        $contract_id = intval($contractStmt->fetchColumn() ?: 0);
        if ($contract_id <= 0) {
            echo json_encode(['status' => 'fail', 'message' => 'Contract not found']);
            exit;
        }
        $downStmt = $con->prepare(
            "SELECT down_payment_amount FROM property_contracts WHERE contract_id = :id"
        );
        $downStmt->execute([':id' => $contract_id]);
        $down_payment = floatval($downStmt->fetchColumn() ?: 0);
    }

    if ($new_amount < 0) {
        echo json_encode(['status' => 'fail', 'message' => 'Amount must be positive']);
        exit;
    }

    $today = (new DateTime('today'))->format('Y-m-d');

    $allStmt = $con->prepare(
        "SELECT installment_id, due_date, status, amount
         FROM property_installments
         WHERE contract_id = :contract_id
         ORDER BY due_date ASC, installment_id ASC"
    );
    $allStmt->execute([':contract_id' => $contract_id]);
    $all = $allStmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    if (empty($all)) {
        echo json_encode(['status' => 'fail', 'message' => 'No installments found']);
        exit;
    }

    $future = [];
    $fixedTotal = 0.0;
    $editedInFuture = false;
    $editedOldAmount = 0.0;
    $editedIsFixed = false;
    foreach ($all as $inst) {
        $status = (string) ($inst['status'] ?? '');
        $due = (string) ($inst['due_date'] ?? '');
        $isFuture = ($status !== 'paid') && ($due >= $today);

        if ($isFuture) {
            $future[] = $inst;
            if (intval($inst['installment_id']) === $installment_id) {
                $editedInFuture = true;
            }
        } else {
            $fixedTotal += floatval($inst['amount'] ?? 0);
            if (intval($inst['installment_id']) === $installment_id) {
                $editedOldAmount = floatval($inst['amount'] ?? 0);
                $editedIsFixed = true;
            }
        }
    }

    if ($editedIsFixed) {
        $fixedTotal = $fixedTotal - $editedOldAmount + $new_amount;
    }

    $remainingTotal = $total_price - $down_payment - $fixedTotal;
    if ($remainingTotal < 0) $remainingTotal = 0;

    $con->beginTransaction();

    if (!$editedInFuture) {
        $updateOne = $con->prepare(
            "UPDATE property_installments SET amount = :amount WHERE installment_id = :id"
        );
        $updateOne->execute([':amount' => $new_amount, ':id' => $installment_id]);
    }

    $targets = $future;
    $targetCount = count($targets);

    if ($targetCount === 0) {
        $remainingStmt = $con->prepare(
            "SELECT COUNT(*) AS cnt, COALESCE(SUM(amount), 0) AS total
             FROM property_installments
             WHERE contract_id = :contract_id AND status <> 'paid'"
        );
        $remainingStmt->execute([':contract_id' => $contract_id]);
        $remainingRow = $remainingStmt->fetch(PDO::FETCH_ASSOC) ?: ['cnt' => 0, 'total' => 0];
        $remainingCount = intval($remainingRow['cnt'] ?? 0);
        $remainingSum = floatval($remainingRow['total'] ?? 0);
        $avgInstallment = $remainingCount > 0 ? round($remainingSum / $remainingCount, 2) : 0;

        $updateContract = $con->prepare(
            "UPDATE property_contracts
             SET monthly_installment = :avg
             WHERE contract_id = :id"
        );
        $updateContract->execute([
            ':avg' => $avgInstallment,
            ':id' => $contract_id,
        ]);

        $con->commit();
        echo json_encode([
            'status' => 'success',
            'installment_id' => $installment_id,
            'new_amount' => $new_amount,
            'redistributed_count' => 0,
            'monthly_installment' => $avgInstallment,
        ]);
        exit;
    }

    $remainingForOthers = $remainingTotal;
    if ($editedInFuture) {
        $remainingForOthers = $remainingTotal - $new_amount;
    }
    if ($remainingForOthers < 0) $remainingForOthers = 0;

    $otherTargets = array_values(array_filter($targets, function ($inst) use ($installment_id) {
        return intval($inst['installment_id']) !== $installment_id;
    }));
    $otherCount = count($otherTargets);

    $base = $otherCount > 0 ? round($remainingForOthers / $otherCount, 2) : 0.0;

    $update = $con->prepare(
        "UPDATE property_installments SET amount = :amount WHERE installment_id = :id"
    );

    if ($editedInFuture) {
        $update->execute([':amount' => $new_amount, ':id' => $installment_id]);
    }

    if ($otherCount > 0) {
        for ($i = 0; $i < $otherCount; $i++) {
            $inst = $otherTargets[$i];
            $amount = $base;
            if ($i === $otherCount - 1) {
                $amount = round($remainingForOthers - ($base * ($otherCount - 1)), 2);
            }
            $update->execute([
                ':amount' => $amount,
                ':id' => intval($inst['installment_id']),
            ]);
        }
    }

    $avgInstallment = $targetCount > 0 ? round($remainingTotal / $targetCount, 2) : null;
    $updateContract = $con->prepare(
        "UPDATE property_contracts
         SET monthly_installment = :avg
         WHERE contract_id = :id"
    );
    $updateContract->execute([
        ':avg' => $avgInstallment,
        ':id' => $contract_id,
    ]);

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'installment_id' => $installment_id,
        'new_amount' => $new_amount,
        'redistributed_count' => $otherCount,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    error_log('update_installment_amount.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
