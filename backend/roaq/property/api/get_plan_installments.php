<?php
// API: Get detailed installments for a specific plan/contract
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$plan_id = isset($_GET['plan_id']) ? intval($_GET['plan_id']) : 0;

if ($user_id <= 0 || $plan_id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid user_id or plan_id'
    ]);
    exit;
}

try {
    // جلب معلومات الخطة
    $planStmt = $con->prepare("
        SELECT 
            pp.plan_id,
            pp.item_id,
            pp.plan_type,
            pp.duration_months,
            pp.total_price,
            pp.down_payment,
            pp.installment_amount,
            pp.start_date,
            i.items_name_en,
            i.items_name_ar,
            i.property_rooms,
            i.property_bathrooms,
            i.property_floor
        FROM property_plans pp
        JOIN items i ON pp.item_id = i.items_id
        WHERE pp.plan_id = ?
    ");
    $planStmt->execute([$plan_id]);
    $plan = $planStmt->fetch(PDO::FETCH_ASSOC);

    if (!$plan) {
        echo json_encode([
            'status' => 'failure',
            'message' => 'Plan not found'
        ]);
        exit;
    }

    // جلب الأقساط
    $installmentsStmt = $con->prepare("
        SELECT 
            installment_id,
            plan_id,
            user_id,
            due_date,
            amount,
            status,
            payment_receipt,
            paid_at,
            created_at
        FROM property_installments
        WHERE user_id = ? AND plan_id = ?
        ORDER BY due_date ASC
    ");
    $installmentsStmt->execute([$user_id, $plan_id]);
    $installments = $installmentsStmt->fetchAll(PDO::FETCH_ASSOC);

    // حساب الإحصائيات
    $paid_count = 0;
    $pending_count = 0;
    $late_count = 0;
    $total_paid = 0;

    foreach ($installments as $inst) {
        if ($inst['status'] === 'paid') {
            $paid_count++;
            $total_paid += floatval($inst['amount']);
        } elseif ($inst['status'] === 'late') {
            $late_count++;
        } else {
            $pending_count++;
        }
    }

    echo json_encode([
        'status' => 'success',
        'plan' => $plan,
        'installments' => $installments,
        'statistics' => [
            'total_installments' => count($installments),
            'paid_installments' => $paid_count,
            'pending_installments' => $pending_count,
            'late_installments' => $late_count,
            'total_paid_amount' => $total_paid,
            'remaining_amount' => (floatval($plan['total_price']) - $total_paid)
        ]
    ]);

} catch (Exception $e) {
    error_log("Error in get_plan_installments: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
