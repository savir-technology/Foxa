<?php
// API: Get user investments (investor-only) with installments calendar data.
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

function hasColumn(PDO $con, string $table, string $column): bool
{
    $stmt = $con->prepare("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :table AND COLUMN_NAME = :column");
    $stmt->execute([':table' => $table, ':column' => $column]);
    return ((int) $stmt->fetchColumn()) > 0;
}

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if ($user_id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid user_id',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

try {
    $hasLeadStatus = hasColumn($con, 'chats', 'lead_status');

    $investorOnlyWhere = $hasLeadStatus
        ? " AND EXISTS (
                SELECT 1
                FROM chats ch
                WHERE ch.user_id = pc.user_id
                  AND ch.item_id = pc.item_id
                  AND ch.lead_status = 'investor'
                  AND (ch.selected_plan_id IS NULL OR ch.selected_plan_id = pc.plan_id)
            )"
        : "";

    $stmt = $con->prepare(" 
        SELECT
            pc.contract_id,
            pc.user_id,
            pc.item_id,
            pc.plan_id,
            pc.status AS contract_status,
            pc.created_at,
            i.items_name_ar AS property_name_ar,
            i.items_name_en AS property_name_en,
            i.asset_kind,
            pp.plan_type,
            pp.total_price,
            pp.down_payment,
            pp.duration_months,
            pp.installment_amount,
            pp.start_date,
            COUNT(pi.installment_id) AS total_installments,
            COALESCE(SUM(CASE WHEN pi.status = 'paid' THEN 1 ELSE 0 END), 0) AS paid_installments,
            COALESCE(SUM(CASE WHEN pi.status IN ('pending', 'late') THEN 1 ELSE 0 END), 0) AS remaining_installments,
            COALESCE(SUM(CASE WHEN pi.status = 'paid' THEN pi.amount ELSE 0 END), 0) AS paid_amount,
            MIN(CASE WHEN pi.status IN ('pending', 'late') THEN pi.due_date END) AS next_due_date
        FROM property_contracts pc
        INNER JOIN items i ON i.items_id = pc.item_id
        INNER JOIN property_plans pp ON pp.plan_id = pc.plan_id
        LEFT JOIN property_installments pi ON pi.plan_id = pc.plan_id AND pi.user_id = pc.user_id
        WHERE pc.user_id = :user_id
          AND pc.status IN ('active', 'approved')
          $investorOnlyWhere
        GROUP BY
            pc.contract_id,
            pc.user_id,
            pc.item_id,
            pc.plan_id,
            pc.status,
            pc.created_at,
            i.items_name_ar,
            i.items_name_en,
            i.asset_kind,
            pp.plan_type,
            pp.total_price,
            pp.down_payment,
            pp.duration_months,
            pp.installment_amount,
            pp.start_date
        ORDER BY pc.contract_id DESC
    ");
    $stmt->execute([':user_id' => $user_id]);
    $investments = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    if (count($investments) === 0) {
        echo json_encode([
            'status' => 'success',
            'message' => 'No investments found',
            'data' => [],
            'upcoming_installments' => [],
            'summary' => [
                'total_investment' => 0,
                'total_paid' => 0,
                'total_remaining' => 0,
                'contracts_count' => 0,
            ],
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $installmentsStmt = $con->prepare(" 
        SELECT
            pc.contract_id,
            pi.installment_id,
            pi.due_date,
            pi.amount,
            pi.status,
            pi.payment_receipt,
            pi.paid_at,
            pi.created_at
        FROM property_contracts pc
        INNER JOIN property_installments pi
            ON pi.plan_id = pc.plan_id AND pi.user_id = pc.user_id
        WHERE pc.user_id = :user_id
          AND pc.status IN ('active', 'approved')
          $investorOnlyWhere
        ORDER BY pi.due_date ASC, pi.installment_id ASC
    ");
    $installmentsStmt->execute([':user_id' => $user_id]);
    $allInstallments = $installmentsStmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    $installmentsByContract = [];
    $upcoming = [];
    $today = date('Y-m-d');

    foreach ($allInstallments as $inst) {
        $contractId = (int) ($inst['contract_id'] ?? 0);
        if (!isset($installmentsByContract[$contractId])) {
            $installmentsByContract[$contractId] = [];
        }
        $installmentsByContract[$contractId][] = $inst;

        $status = (string) ($inst['status'] ?? 'pending');
        $due = (string) ($inst['due_date'] ?? '');
        if ($due !== '' && $status !== 'paid' && $due >= $today) {
            $upcoming[] = $inst;
        }
    }

    $totalInvestment = 0.0;
    $totalPaid = 0.0;
    $totalRemaining = 0.0;

    foreach ($investments as &$investment) {
        $contractId = (int) ($investment['contract_id'] ?? 0);
        $totalPrice = (float) ($investment['total_price'] ?? 0);
        $paidAmount = (float) ($investment['paid_amount'] ?? 0);
        $remainingAmount = max(0, $totalPrice - $paidAmount);

        $investment['installments'] = $installmentsByContract[$contractId] ?? [];
        $investment['remaining_amount'] = $remainingAmount;

        $totalInvestment += $totalPrice;
        $totalPaid += $paidAmount;
        $totalRemaining += $remainingAmount;
    }
    unset($investment);

    echo json_encode([
        'status' => 'success',
        'data' => $investments,
        'upcoming_installments' => $upcoming,
        'summary' => [
            'total_investment' => $totalInvestment,
            'total_paid' => $totalPaid,
            'total_remaining' => $totalRemaining,
            'contracts_count' => count($investments),
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('Error in get_my_investments.php: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
