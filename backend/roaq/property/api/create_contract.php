<?php
// API: Create a new property contract for a user
require_once '../../connect.php';
require_once '../../functions.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$item_id = isset($_POST['item_id']) ? intval($_POST['item_id']) : 0;
$plan_id = isset($_POST['plan_id']) ? intval($_POST['plan_id']) : 0;

if ($user_id <= 0 || $item_id <= 0 || $plan_id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid parameters'
    ]);
    exit;
}

try {
    // التحقق من وجود المستخدم والعقار والخطة
    $userStmt = $con->prepare("SELECT users_id FROM users WHERE users_id = ?");
    $userStmt->execute([$user_id]);
    if ($userStmt->rowCount() === 0) {
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
        exit;
    }

    $itemStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = ?");
    $itemStmt->execute([$item_id]);
    if ($itemStmt->rowCount() === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Item not found']);
        exit;
    }

    $planStmt = $con->prepare(
        "SELECT plan_id, duration_months, start_date, down_payment, installment_amount
         FROM property_plans WHERE plan_id = ? AND item_id = ?"
    );
    $planStmt->execute([$plan_id, $item_id]);
    $plan = $planStmt->fetch(PDO::FETCH_ASSOC);
    if (!$plan) {
        echo json_encode(['status' => 'error', 'message' => 'Plan not found']);
        exit;
    }

    // إنشاء العقد
    $status = 'pending'; // الحالة الافتراضية للعقد الجديد
    $contractStmt = $con->prepare("
        INSERT INTO property_contracts
        (user_id, item_id, plan_id, down_payment_amount, down_payment_paid, monthly_installment, status, created_at)
        VALUES (?, ?, ?, ?, 0, ?, ?, NOW())
    ");
    
    $contractStmt->execute([
        $user_id,
        $item_id,
        $plan_id,
        floatval($plan['down_payment'] ?? 0),
        floatval($plan['installment_amount'] ?? 0),
        $status
    ]);
    $contract_id = $con->lastInsertId();

    // إنشاء الأقساط تلقائياً
    $planStmt = $con->prepare("
        SELECT 
            plan_id, 
            total_price, 
            down_payment, 
            installment_amount, 
            duration_months, 
            start_date
        FROM property_plans
        WHERE plan_id = ?
    ");
    $planStmt->execute([$plan_id]);
    $planData = $planStmt->fetch(PDO::FETCH_ASSOC);

    // حساب تواريخ الأقساط
    $startRaw = trim((string) ($planData['start_date'] ?? ''));
    if ($startRaw === '' || $startRaw === '0000-00-00') {
        $start_date = new DateTime('today');
    } else {
        $start_date = new DateTime($startRaw);
    }
    
    for ($i = 0; $i < $planData['duration_months']; $i++) {
        $due_date = clone $start_date;
        $due_date->modify('+' . $i . ' months');
        
        $installmentStmt = $con->prepare("
            INSERT INTO property_installments 
            (contract_id, plan_id, user_id, due_date, amount, status, created_at)
            VALUES (?, ?, ?, ?, ?, 'pending', NOW())
        ");
        
        $installmentStmt->execute([
            $contract_id,
            $plan_id,
            $user_id,
            $due_date->format('Y-m-d'),
            $planData['installment_amount']
        ]);
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'Contract created successfully',
        'contract_id' => $contract_id,
        'total_installments' => $planData['duration_months']
    ]);

} catch (Exception $e) {
    error_log("Error in create_contract: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
