<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);

    $stmt = $con->prepare("
        SELECT
            ae.entry_id,
            ae.entry_date,
            ae.entry_type,
            ae.debit,
            ae.credit,
            ae.description
        FROM accounting_entries ae
        LEFT JOIN vendor_orders vo
            ON ae.reference_table = 'orders'
           AND vo.order_id = ae.reference_id
        LEFT JOIN expenses e
            ON ae.reference_table = 'expenses'
           AND e.expense_id = ae.reference_id
        WHERE (
                ae.reference_table = 'orders'
                AND vo.vendor_id = :vendor_id
            )
           OR (
                ae.reference_table = 'expenses'
                AND e.vendor_id = :vendor_id
            )
        ORDER BY ae.entry_date DESC, ae.entry_id DESC
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'success',
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
