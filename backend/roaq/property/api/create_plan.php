<?php
// API: Create a new property plan (Admin only)
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$item_id = isset($_POST['item_id']) ? intval($_POST['item_id']) : 0;
$plan_type = isset($_POST['plan_type']) ? trim($_POST['plan_type']) : '';
$duration_months = isset($_POST['duration_months']) ? intval($_POST['duration_months']) : 0;
$total_price = isset($_POST['total_price']) ? floatval($_POST['total_price']) : 0;
$down_payment = isset($_POST['down_payment']) ? floatval($_POST['down_payment']) : 0;
$start_date = isset($_POST['start_date']) ? trim($_POST['start_date']) : '';

// التحقق من الصحة
$errors = [];

if ($item_id <= 0) {
    $errors[] = 'Invalid item_id';
}

if (!in_array($plan_type, ['monthly', 'yearly', 'Quarterly'])) {
    $errors[] = 'Invalid plan_type (monthly, yearly, or Quarterly)';
}

if ($duration_months <= 0) {
    $errors[] = 'Duration months must be positive';
}

if ($total_price <= 0) {
    $errors[] = 'Total price must be positive';
}

if ($down_payment < 0) {
    $errors[] = 'Down payment cannot be negative';
}

if (empty($start_date) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $start_date)) {
    $errors[] = 'Invalid start_date format (use YYYY-MM-DD)';
}

if (!empty($errors)) {
    echo json_encode([
        'status' => 'error',
        'errors' => $errors
    ]);
    exit;
}

try {
    // التحقق من وجود العقار
    $itemStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = ?");
    $itemStmt->execute([$item_id]);
    if ($itemStmt->rowCount() === 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Item not found'
        ]);
        exit;
    }

    // حساب مبلغ القسط
    $remaining_price = $total_price - $down_payment;
    $installment_amount = round($remaining_price / $duration_months, 2);

    // إنشاء الخطة
    $stmt = $con->prepare("
        INSERT INTO property_plans 
        (item_id, plan_type, duration_months, total_price, down_payment, installment_amount, start_date, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    ");

    $stmt->execute([
        $item_id,
        $plan_type,
        $duration_months,
        $total_price,
        $down_payment,
        $installment_amount,
        $start_date
    ]);

    $plan_id = $con->lastInsertId();

    echo json_encode([
        'status' => 'success',
        'message' => 'Plan created successfully',
        'plan_id' => $plan_id,
        'plan' => [
            'plan_id' => $plan_id,
            'item_id' => $item_id,
            'plan_type' => $plan_type,
            'duration_months' => $duration_months,
            'total_price' => $total_price,
            'down_payment' => $down_payment,
            'installment_amount' => $installment_amount,
            'start_date' => $start_date
        ]
    ]);

} catch (Exception $e) {
    error_log("Error in create_plan: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
