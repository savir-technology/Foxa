<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function readRequestData(): array
{
    if (!empty($_POST)) {
        return $_POST;
    }

    $raw = trim((string)file_get_contents('php://input'));
    if ($raw === '') {
        return [];
    }

    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        return $decoded;
    }

    parse_str($raw, $parsed);
    return is_array($parsed) ? $parsed : [];
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = ($actor['role'] ?? '') === 'vendor';
$actorVendorId = $isVendor ? (int)($actor['vendor']['vendor_id'] ?? 0) : 0;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => 'error',
        'message' => 'يجب استخدام POST',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$payload = readRequestData();
$orderId = (int)($payload['order_id'] ?? 0);
$vendorId = $isVendor ? $actorVendorId : (int)($payload['vendor_id'] ?? 0);
$status = trim((string)($payload['status'] ?? ''));

if ($orderId <= 0 || $vendorId <= 0 || $status === '') {
    echo json_encode([
        'status' => 'error',
        'message' => 'order_id و vendor_id و status مطلوبة.',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$allowedStatuses = ['arrived_at_restaurant'];
if (!in_array($status, $allowedStatuses, true)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'حالة التدفق غير مدعومة.',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $con->beginTransaction();

    $orderStmt = $con->prepare("
        SELECT
            o.orders_id,
            o.status AS flow_status,
            o.delivery_id,
            o.arrived_at_restaurant_at,
            vo.vendor_status
        FROM orders o
        INNER JOIN vendor_orders vo ON vo.order_id = o.orders_id
        WHERE o.orders_id = :order_id
          AND vo.vendor_id = :vendor_id
        LIMIT 1
        FOR UPDATE
    ");
    $orderStmt->execute([
        ':order_id' => $orderId,
        ':vendor_id' => $vendorId,
    ]);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        $con->rollBack();
        echo json_encode([
            'status' => 'error',
            'message' => 'الطلب غير موجود لهذا المطعم.',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $currentStatus = strtolower(trim((string)($order['flow_status'] ?? '')));
    if (in_array($currentStatus, ['delivered', 'completed', 'canceled', 'cancelled'], true)) {
        $con->rollBack();
        echo json_encode([
            'status' => 'error',
            'message' => 'لا يمكن تعديل طلب مكتمل أو ملغي.',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($currentStatus === $status) {
        $con->commit();
        echo json_encode([
            'status' => 'success',
            'message' => 'لا يوجد تغيير في حالة الطلب.',
            'order_id' => $orderId,
            'status_key' => $status,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $updateStmt = $con->prepare("
        UPDATE orders
        SET status = :status,
            arrived_at_restaurant_at = NOW(),
            updated_at = NOW()
        WHERE orders_id = :order_id
    ");
    $updateStmt->execute([
        ':status' => $status,
        ':order_id' => $orderId,
    ]);

    $trackingStmt = $con->prepare("
        UPDATE delivery_order_tracking
        SET status = :status,
            last_updated = NOW()
        WHERE order_id = :order_id
    ");
    $trackingStmt->execute([
        ':status' => $status,
        ':order_id' => $orderId,
    ]);

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'message' => 'تم تحديث حالة الطلب بنجاح.',
        'order_id' => $orderId,
        'status_key' => $status,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
?>
