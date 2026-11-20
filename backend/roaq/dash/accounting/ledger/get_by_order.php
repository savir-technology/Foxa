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
    $orderId = (int)($_GET['order_id'] ?? 0);

    if ($orderId <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'order_id is required',
            'data' => [],
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $ownershipStmt = $con->prepare("
        SELECT 1
        FROM vendor_orders
        WHERE order_id = :order_id
          AND vendor_id = :vendor_id
        LIMIT 1
    ");
    $ownershipStmt->execute([
        ':order_id' => $orderId,
        ':vendor_id' => $vendorId,
    ]);
    if (!$ownershipStmt->fetchColumn()) {
        echo json_encode([
            'status' => 'failure',
            'message' => 'Order not found',
            'data' => [],
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("
        SELECT
            entry_type,
            debit,
            credit,
            description,
            entry_date
        FROM accounting_entries
        WHERE reference_table = 'orders'
          AND reference_id = :order_id
        ORDER BY entry_date ASC, entry_id ASC
    ");
    $stmt->execute([':order_id' => $orderId]);
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
