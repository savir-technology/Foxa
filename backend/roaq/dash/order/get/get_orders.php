<?php
include "../../../connect.php";

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$vendorId = $isVendor ? (int)$actor['vendor']['vendor_id'] : 0;
$scope = strtolower(trim((string)($_GET['scope'] ?? 'all')));

function dashboardOrderPaymentMeta($method, $numericMethod = null): array
{
    $key = strtolower(trim((string)$method));
    $numeric = trim((string)($numericMethod ?? ''));
    if ($key === '' || $key === 'null') {
        $key = $numeric;
    }
    if ($key === '2' || strpos($key, 'wallet') !== false || strpos($key, 'محفظ') !== false) {
        return ['key' => 'wallet', 'label' => 'محفظة'];
    }
    if (
        $key === '1' ||
        strpos($key, 'visa') !== false ||
        strpos($key, 'card') !== false ||
        strpos($key, 'credit') !== false ||
        strpos($key, 'master') !== false ||
        strpos($key, 'online') !== false ||
        strpos($key, 'paymob') !== false ||
        strpos($key, 'meeza') !== false ||
        strpos($key, 'فيزا') !== false
    ) {
        return ['key' => 'visa', 'label' => 'فيزا / بطاقة'];
    }
    return ['key' => 'cash', 'label' => 'الدفع عند الاستلام'];
}

    try {
        $sql = "SELECT 
                o.orders_id,
                o.orders_usersid,
                u.users_name,
                u.users_email,
                a.address_city,
                a.address_street,
                a.address_phone,
                COALESCE(o.orders_recipient_lat, a.address_lat) AS orders_recipient_lat,
                COALESCE(o.orders_recipient_lng, a.address_long) AS orders_recipient_lng,
                vss.store_latitude,
                vss.store_longitude,
                vo.vendor_total AS orders_totalprice,
                o.orders_paymentmethod,
                o.payment_method,
                o.paid_amount,
                o.transaction_id,
                o.orders_gateway_ref,
                vo.vendor_status AS orders_status,
                o.orders_gift_message,
                o.orders_delivery_note,
                o.orders_rejection_reason,
                o.orders_datetime,
                o.order_mode,
                o.scheduled_for,
                o.orders_estimated_minutes,
                o.orders_type,
                o.delivery_id,
                COALESCE(
                    (
                        SELECT COUNT(*)
                        FROM order_items oi_count
                        WHERE oi_count.order_id = o.orders_id
                          AND oi_count.vendor_id = vo.vendor_id
                    ),
                    0
                ) AS orders_items_count,
                du.name AS driver_name,
                du.phone AS driver_phone,
                du.status AS driver_status,
                du.latitude AS driver_latitude,
                du.longitude AS driver_longitude,
                o.delivery_code,
                o.proof_type,
                o.proof_image,
                o.assigned_at,
                o.accepted_at,
                o.arrived_at_restaurant_at,
                o.picked_up_at,
                o.arrived_at_customer_at,
                o.delivered_at,
                o.status,
                vo.vendor_id,
                v.store_name,
                v.vendor_name
            FROM vendor_orders vo
            JOIN orders o ON o.orders_id = vo.order_id
            JOIN vendors v ON v.vendor_id = vo.vendor_id
            JOIN users u ON u.users_id = o.orders_usersid
            LEFT JOIN address a ON a.address_id = o.orders_address
            LEFT JOIN vendor_store_settings vss ON vss.vendor_id = vo.vendor_id
            LEFT JOIN delivery_users du ON du.id = o.delivery_id";

    if ($isVendor) {
        $sql .= " WHERE vo.vendor_id = :vendor_id";
    }

    if ($scope === 'scheduled') {
        $sql .= $isVendor ? " AND" : " WHERE";
        $sql .= " o.scheduled_for IS NOT NULL AND o.scheduled_for > NOW()";
    }

    if ($scope === 'active') {
        $sql .= $isVendor ? " AND" : " WHERE";
        $sql .= " COALESCE(o.status, '') NOT IN ('delivered', 'completed', 'paid', 'canceled', 'cancelled', 'failed', 'rejected')";
        $sql .= " AND COALESCE(vo.vendor_status, '') NOT IN ('delivered', 'completed', 'canceled', 'cancelled', 'failed', 'rejected')";
        $sql .= " AND (o.scheduled_for IS NULL OR o.scheduled_for <= NOW())";
    }

    $sql .= " ORDER BY o.orders_datetime DESC";

    $stmt = $con->prepare($sql);
    if ($isVendor) {
        $stmt->execute([':vendor_id' => $vendorId]);
    } else {
        $stmt->execute();
    }
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($orders as &$order) {
        $payment = dashboardOrderPaymentMeta(
            $order['payment_method'] ?? '',
            $order['orders_paymentmethod'] ?? ''
        );
        $order['payment_key'] = $payment['key'];
        $order['payment_label'] = $payment['label'];
    }
    unset($order);

    echo json_encode([
        "status" => "success",
        "data" => $orders
    ]);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
