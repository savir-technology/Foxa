<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['master']);
requireMasterPermission($actor['master'] ?? [], 'finance.withdrawals');

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$vendorId = (int)($payload['vendor_id'] ?? 0);
if ($vendorId <= 0) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid vendor settlement payload',
    ], 400);
}

function aggregateSettlementOrderStatus(array $statusMap): string
{
    $total = array_sum($statusMap);
    if ($total <= 0) {
        return 'pending';
    }

    $paid = (int)($statusMap['paid'] ?? 0);
    $failed = (int)($statusMap['failed'] ?? 0);
    $canceled = (int)($statusMap['canceled'] ?? 0);

    if ($paid === $total) {
        return 'paid';
    }

    if ($canceled === $total) {
        return 'canceled';
    }

    if ($failed > 0 && ($failed + $canceled) === $total) {
        return 'failed';
    }

    return 'pending';
}

try {
    $con->beginTransaction();

    $orderIdsStmt = $con->prepare("
        SELECT DISTINCT order_id
        FROM vendor_orders
        WHERE vendor_id = :vendor_id
          AND vendor_status = 'pending'
    ");
    $orderIdsStmt->execute([':vendor_id' => $vendorId]);
    $orderIds = $orderIdsStmt->fetchAll(PDO::FETCH_COLUMN);

    $updateStmt = $con->prepare("
        UPDATE vendor_orders
        SET vendor_status = 'paid', updated_at = NOW()
        WHERE vendor_id = :vendor_id
          AND vendor_status = 'pending'
    ");
    $updateStmt->execute([':vendor_id' => $vendorId]);
    $updatedRows = $updateStmt->rowCount();

    $statusStmt = $con->prepare("
        SELECT vendor_status, COUNT(*) AS status_count
        FROM vendor_orders
        WHERE order_id = :order_id
        GROUP BY vendor_status
    ");

    $updateOrderStmt = $con->prepare("
        UPDATE orders
        SET orders_status = :orders_status, updated_at = NOW()
        WHERE orders_id = :order_id
    ");

    foreach ($orderIds as $orderId) {
        $statusStmt->execute([':order_id' => (int)$orderId]);
        $statusMap = [];
        foreach ($statusStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $statusMap[$row['vendor_status']] = (int)$row['status_count'];
        }

        $aggregatedStatus = aggregateSettlementOrderStatus($statusMap);
        $updateOrderStmt->execute([
            ':orders_status' => $aggregatedStatus,
            ':order_id' => (int)$orderId,
        ]);
    }

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => $updatedRows > 0
            ? 'Vendor settlement was marked as paid successfully'
            : 'No pending vendor settlements were found',
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
