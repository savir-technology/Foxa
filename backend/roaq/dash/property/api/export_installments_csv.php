<?php
require_once '../../../connect.php';

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="installments_export.csv"');

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$contract_id = isset($_GET['contract_id']) ? intval($_GET['contract_id']) : 0;
$status = trim((string) ($_GET['status'] ?? ''));
$month = trim((string) ($_GET['month'] ?? ''));

$where = [];
$params = [];
if ($user_id > 0) {
    $where[] = "pi.user_id = :user_id";
    $params[':user_id'] = $user_id;
}
if ($contract_id > 0) {
    $where[] = "pi.contract_id = :contract_id";
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
        pi.installment_id,
        pi.contract_id,
        pi.user_id,
        u.users_name,
        u.users_email,
        i.items_name_ar,
        i.items_name_en,
        pi.due_date,
        pi.amount,
        pi.status
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

$output = fopen('php://output', 'w');
fputcsv($output, [
    'installment_id',
    'contract_id',
    'user_id',
    'user_name',
    'user_email',
    'property_name_ar',
    'property_name_en',
    'due_date',
    'amount',
    'status',
]);

foreach ($rows as $row) {
    fputcsv($output, [
        $row['installment_id'],
        $row['contract_id'],
        $row['user_id'],
        $row['users_name'],
        $row['users_email'],
        $row['items_name_ar'],
        $row['items_name_en'],
        $row['due_date'],
        $row['amount'],
        $row['status'],
    ]);
}
fclose($output);
