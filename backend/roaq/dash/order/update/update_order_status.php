<?php
include "../../../connect.php";
require_once __DIR__ . "/../../../notifications/notification_helper.php";
$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';

header('Content-Type: application/json');

$order_id = isset($_GET['order_id']) ? $_GET['order_id'] : null;
$orderStatus = isset($_GET['orderStatus']) ? $_GET['orderStatus'] : null;
$estimatedMinutes = isset($_GET['estimated_minutes']) ? (int)$_GET['estimated_minutes'] : 0;
$reason = isset($_GET['reason']) ? trim((string)$_GET['reason']) : '';
$requestedVendorId = isset($_GET['vendor_id']) ? (int)$_GET['vendor_id'] : 0;
$targetVendorId = $isVendor ? (int)$actor['vendor']['vendor_id'] : $requestedVendorId;

if (!$order_id || !$orderStatus || $targetVendorId <= 0) {
    echo json_encode(["status" => "error", "message" => "order_id أو orderStatus غير موجود."]);
    exit;
}

$allowedStatuses = ['pending', 'paid', 'failed', 'canceled'];
if (!in_array($orderStatus, $allowedStatuses, true)) {
    echo json_encode(["status" => "error", "message" => "حالة الطلب غير صالحة."]);
    exit;
}

function aggregateVendorOrderStatus($statusMap)
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

    $vendorOrderStmt = $con->prepare("
        SELECT
            vo.order_id,
            vo.vendor_id,
            vo.customer_user_id,
            vo.vendor_status,
            o.orders_status,
            o.orders_usersid,
            v.store_name
        FROM vendor_orders vo
        JOIN orders o ON o.orders_id = vo.order_id
        JOIN vendors v ON v.vendor_id = vo.vendor_id
        WHERE vo.order_id = :order_id
          AND vo.vendor_id = :vendor_id
        LIMIT 1
        FOR UPDATE
    ");
    $vendorOrderStmt->execute([
        ':order_id' => $order_id,
        ':vendor_id' => $targetVendorId,
    ]);
    $vendorOrder = $vendorOrderStmt->fetch(PDO::FETCH_ASSOC);

    if (!$vendorOrder) {
        $con->rollBack();
        echo json_encode(["status" => "error", "message" => "الطلب غير موجود لهذا البائع."]);
        exit;
    }

    $oldVendorStatus = $vendorOrder['vendor_status'];
    $oldGlobalStatus = $vendorOrder['orders_status'];

    if ($oldVendorStatus === $orderStatus) {
        $con->commit();
        echo json_encode(["status" => "success", "message" => "لا يوجد تغيير في حالة الطلب."]);
        exit;
    }

    if ($estimatedMinutes > 0) {
        $prepStmt = $con->prepare("
            UPDATE orders
            SET orders_estimated_minutes = :estimated_minutes,
                updated_at = NOW()
            WHERE orders_id = :order_id
        ");
        $prepStmt->execute([
            ':estimated_minutes' => $estimatedMinutes,
            ':order_id' => $order_id,
        ]);
    }

    if ($oldGlobalStatus === 'paid' && $oldVendorStatus === 'paid' && $orderStatus === 'canceled') {
        $itemsStmt = $con->prepare("
            SELECT item_id, quantity
            FROM order_items
            WHERE order_id = :order_id
              AND vendor_id = :vendor_id
        ");
        $itemsStmt->execute([
            ':order_id' => $order_id,
            ':vendor_id' => $targetVendorId,
        ]);
        $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);

        $restoreStmt = $con->prepare("
            UPDATE items
            SET items_count = items_count + :quantity
            WHERE items_id = :item_id
              AND vendor_id = :vendor_id
        ");

        foreach ($items as $item) {
            $restoreStmt->execute([
                ':quantity' => (int)$item['quantity'],
                ':item_id' => (int)$item['item_id'],
                ':vendor_id' => $targetVendorId,
            ]);
        }
    }

    $updateVendorOrderStmt = $con->prepare("
        UPDATE vendor_orders
        SET vendor_status = :vendor_status, updated_at = NOW()
        WHERE order_id = :order_id
          AND vendor_id = :vendor_id
    ");
    $updateVendorOrderStmt->execute([
        ':vendor_status' => $orderStatus,
        ':order_id' => $order_id,
        ':vendor_id' => $targetVendorId,
    ]);

    $statusesStmt = $con->prepare("
        SELECT vendor_status, COUNT(*) AS status_count
        FROM vendor_orders
        WHERE order_id = :order_id
        GROUP BY vendor_status
    ");
    $statusesStmt->execute([':order_id' => $order_id]);

    $statusMap = [];
    foreach ($statusesStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $statusMap[$row['vendor_status']] = (int)$row['status_count'];
    }

    $aggregatedStatus = aggregateVendorOrderStatus($statusMap);

    $updateOrderStmt = $con->prepare("
        UPDATE orders
        SET orders_status = :orders_status,
            orders_rejection_reason = :rejection_reason,
            updated_at = NOW()
        WHERE orders_id = :order_id
    ");
    $updateOrderStmt->execute([
        ':orders_status' => $aggregatedStatus,
        ':rejection_reason' =>
            ($orderStatus === 'failed' || $orderStatus === 'canceled') && $reason !== ''
                ? $reason
                : null,
        ':order_id' => $order_id,
    ]);

    $statusLabels = [
        'pending' => 'قيد المراجعة',
        'paid' => 'مدفوع',
        'failed' => 'فشل الدفع',
        'canceled' => 'ملغي',
    ];

    $reasonSuffix = ($orderStatus === 'failed' || $orderStatus === 'canceled') && $reason !== ''
        ? ' - ' . $reason
        : '';

    $con->commit();

    try {
        notifyUser(
        $con,
        (int)$vendorOrder['orders_usersid'],
        'order_status',
        'تم تحديث حالة طلبك',
        'تم تحديث حالة طلبك لدى ' . ($vendorOrder['store_name'] ?? 'المتجر') . ' إلى: ' . ($statusLabels[$orderStatus] ?? $orderStatus) . $reasonSuffix,
        'order',
        (int)$order_id,
        [
            'order_id' => (string)$order_id,
            'vendor_id' => (string)$targetVendorId,
            'vendor_status' => $orderStatus,
            'global_status' => $aggregatedStatus,
            'rejection_reason' => $reason,
        ],
        true
    );
    } catch (Throwable $notificationError) {
        error_log('Order status notification failed: ' . $notificationError->getMessage());
    }

    if (!$isVendor) {
        try {
            notifyVendor(
                $con,
                $targetVendorId,
                'order_status',
                'تم تحديث حالة طلب',
                'تم تحديث حالة الطلب #' . (int)$order_id . ' إلى: ' . ($statusLabels[$orderStatus] ?? $orderStatus) . $reasonSuffix,
                'order',
                (int)$order_id,
                [
                    'order_id' => (string)$order_id,
                    'vendor_id' => (string)$targetVendorId,
                    'vendor_status' => $orderStatus,
                    'global_status' => $aggregatedStatus,
                    'rejection_reason' => $reason,
                    'screen' => 'orders',
                ],
                true
            );
        } catch (Throwable $notificationError) {
            error_log('Vendor order status notification failed: ' . $notificationError->getMessage());
        }
    }

    echo json_encode([
        "status" => "success",
        "message" => "تم تحديث حالة الطلب بنجاح.",
        "vendor_status" => $orderStatus,
        "global_status" => $aggregatedStatus,
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
