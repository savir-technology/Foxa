<?php
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

function hasColumn(PDO $con, string $table, string $column): bool
{
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table
          AND COLUMN_NAME = :column
    ");
    $stmt->execute([':table' => $table, ':column' => $column]);
    return ((int) $stmt->fetchColumn()) > 0;
}

$itemId = isset($_GET['item_id']) ? intval($_GET['item_id']) : 0;
$planType = isset($_GET['plan_type']) ? trim((string) $_GET['plan_type']) : '';

if ($itemId <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid item_id',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

try {
    $hasPlanType = hasColumn($con, 'property_plans', 'plan_type');
    $hasInstallmentAmount = hasColumn($con, 'property_plans', 'installment_amount');
    $hasStartDate = hasColumn($con, 'property_plans', 'start_date');

    $baseSelect = "
        SELECT
            plan_id,
            item_id,
            " . ($hasPlanType ? "plan_type" : "'monthly' AS plan_type") . ",
            duration_months,
            total_price,
            down_payment,
            " . ($hasInstallmentAmount ? "installment_amount" : "ROUND((COALESCE(total_price,0)-COALESCE(down_payment,0))/NULLIF(duration_months,0),2) AS installment_amount") . ",
            " . ($hasStartDate ? "start_date" : "NULL AS start_date") . ",
            is_active
        FROM property_plans
        WHERE item_id = :item_id
          AND is_active = 1
    ";

    if ($planType !== '' && $hasPlanType) {
        $sql = $baseSelect . " AND plan_type = :plan_type ORDER BY duration_months ASC, plan_id ASC LIMIT 1";
        $stmt = $con->prepare($sql);
        $stmt->execute([
            ':item_id' => $itemId,
            ':plan_type' => $planType,
        ]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
        echo json_encode([
            'status' => 'success',
            'plan' => $plan,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $sql = $baseSelect . " ORDER BY duration_months ASC, plan_id ASC";
    $stmt = $con->prepare($sql);
    $stmt->execute([':item_id' => $itemId]);
    $plans = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    echo json_encode([
        'status' => 'success',
        'plans' => $plans,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
