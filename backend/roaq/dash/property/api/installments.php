<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

try {
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    $plan_id = isset($_GET['plan_id']) ? intval($_GET['plan_id']) : 0;
    $contract_id = isset($_GET['contract_id']) ? intval($_GET['contract_id']) : 0;
    $status = trim((string) ($_GET['status'] ?? ''));
    $month = trim((string) ($_GET['month'] ?? ''));

    $where = [];
    $params = [];
    if ($user_id > 0) {
        $where[] = "user_id = :user_id";
        $params[':user_id'] = $user_id;
    }
    if ($plan_id > 0) {
        $where[] = "plan_id = :plan_id";
        $params[':plan_id'] = $plan_id;
    }
    if ($contract_id > 0) {
        $where[] = "contract_id = :contract_id";
        $params[':contract_id'] = $contract_id;
    }
    if ($status !== '') {
        $allowed = ['pending', 'paid', 'late', 'receipt_uploaded', 'rejected'];
        if (in_array($status, $allowed, true)) {
            $where[] = "pi.status = :status";
            $params[':status'] = $status;
        }
    }
    if ($month !== '') {
        $where[] = "DATE_FORMAT(pi.due_date, '%Y-%m') = :month";
        $params[':month'] = $month;
    }

    $whereSql = count($where) ? ('WHERE ' . implode(' AND ', $where)) : '';
    $sql = "
        SELECT
            pi.*,
            u.users_name,
            u.users_email,
            pp.item_id,
            i.items_name_ar,
            i.items_name_en
        FROM property_installments pi
        LEFT JOIN users u ON u.users_id = pi.user_id
        LEFT JOIN property_plans pp ON pp.plan_id = pi.plan_id
        LEFT JOIN items i ON i.items_id = pp.item_id
        $whereSql
        ORDER BY pi.due_date ASC, pi.installment_id ASC
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
?>
