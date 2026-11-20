<?php
// Admin API: Get all property contracts, filter by status if needed
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

$status = trim((string) ($_GET['status'] ?? ''));

try {
    $where = '';
    $params = [];
    if ($status !== '') {
        $where = "WHERE pc.status = :status";
        $params[':status'] = $status;
    }

    $sql = "
        SELECT
            pc.contract_id,
            pc.user_id,
            pc.item_id,
            pc.plan_id,
            pc.status,
            pc.created_at,
            pc.down_payment_amount,
            pc.down_payment_paid,
            pc.down_payment_paid_at,
            pc.monthly_installment,
            u.users_name,
            u.users_email,
            i.items_name_ar,
            i.items_name_en,
            pp.total_price,
            pp.duration_months,
            pp.down_payment AS plan_down_payment,
            pp.installment_amount AS plan_installment_amount,
            pp.start_date
        FROM property_contracts pc
        LEFT JOIN users u ON u.users_id = pc.user_id
        LEFT JOIN items i ON i.items_id = pc.item_id
        LEFT JOIN property_plans pp ON pp.plan_id = pc.plan_id
        $where
        ORDER BY pc.created_at DESC, pc.contract_id DESC
    ";

    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    echo json_encode($rows, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
