<?php
include "connect.php";
require_once __DIR__ . "/../notifications/notification_helper.php";

header("Content-Type: application/json; charset=utf-8");

function readRequestData(): array
{
    if (!empty($_POST)) {
        return $_POST;
    }

    $raw = trim((string)file_get_contents("php://input"));
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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"]);
    exit;
}

$data = readRequestData();
$action = trim((string)($data['action'] ?? ''));
if ($action === '') {
    $action = (isset($data['order_id']) || isset($data['driver_id'])) ? 'assign_order' : 'get_orders';
}

if ($action === "get_orders") {
    $query = $con->prepare("
        SELECT *
        FROM orders
        WHERE (
            COALESCE(status, '') IN ('new', 'pending')
            OR orders_status IN ('pending', 'paid')
        )
          AND (delivery_id IS NULL OR delivery_id = 0)
        ORDER BY orders_id DESC
    ");
    $query->execute();
    $orders = $query->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $orders,
        "orders" => $orders,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($action === "assign_order") {
    $orderId = (int)($data['order_id'] ?? $data['id'] ?? 0);
    $driverId = (int)($data['driver_id'] ?? 0);
    $vendorId = (int)($data['vendor_id'] ?? 0);

    if ($orderId <= 0 || $driverId <= 0) {
        echo json_encode(["status" => "error", "message" => "order_id and driver_id are required"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    ensureVendorOrderDeliverySchema();

    $driverStmt = $con->prepare("SELECT name, phone, vehicle_type, vehicle_number FROM delivery_users WHERE id = ? LIMIT 1");
    $driverStmt->execute([$driverId]);
    $driver = $driverStmt->fetch(PDO::FETCH_ASSOC);

    $orderStmt = $con->prepare("
        SELECT
            o.orders_id,
            o.orders_usersid,
            o.order_mode,
            o.scheduled_for,
            o.orders_estimated_minutes,
            COALESCE(o.delivery_latitude, o.orders_recipient_lat, a.address_lat) AS delivery_latitude,
            COALESCE(o.delivery_longitude, o.orders_recipient_lng, a.address_long) AS delivery_longitude,
            COALESCE(
                o.delivery_address,
                o.orders_recipient_address_name,
                a.address_name,
                ''
            ) AS delivery_address,
            COALESCE(o.orders_recipient_lat, a.address_lat) AS orders_recipient_lat,
            COALESCE(o.orders_recipient_lng, a.address_long) AS orders_recipient_lng,
            COALESCE(o.orders_recipient_address_name, a.address_name, '') AS orders_recipient_address_name,
            COALESCE(o.orders_recipient_address_line, a.address_street, '') AS orders_recipient_address_line,
            o.orders_share_token,
            vo.vendor_id,
            COALESCE(v.vendor_type, 'restaurant') AS vendor_type,
            COALESCE(v.store_category, '') AS store_category
        FROM orders o
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        WHERE o.orders_id = :order_id
          AND (:vendor_filter_enabled = 0 OR vo.vendor_id = :vendor_filter_id)
        LIMIT 1
    ");
    $orderStmt->execute([
        ':order_id' => $orderId,
        ':vendor_filter_enabled' => $vendorId > 0 ? 1 : 0,
        ':vendor_filter_id' => $vendorId,
    ]);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);

    if (!$driver || !$order) {
        echo json_encode(["status" => "error", "message" => "Order or driver not found"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $vendorId = (int)($order['vendor_id'] ?? $vendorId);
    $vendorAssignmentStmt = $con->prepare("UPDATE vendor_orders
        SET delivery_id = :driver_id, delivery_status = 'assigned',
            delivery_assigned_at = NOW(), updated_at = NOW()
        WHERE order_id = :order_id AND vendor_id = :vendor_id");
    $vendorAssignmentStmt->execute([
        ':driver_id' => $driverId,
        ':order_id' => $orderId,
        ':vendor_id' => $vendorId,
    ]);

    $query = $con->prepare("
        UPDATE orders
        SET delivery_id = ?,
            status = 'accepted',
            assigned_at = NOW(),
            accepted_at = COALESCE(accepted_at, NOW())
        WHERE orders_id = ?
          AND (delivery_id IS NULL OR delivery_id = 0)
          AND (
              COALESCE(status, '') IN ('new', 'pending')
              OR orders_status IN ('pending', 'paid')
          )
    ");

    if (!$query->execute([$driverId, $orderId])) {
        echo json_encode(["status" => "error", "message" => "Failed to assign order"], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $trackingQuery = $con->prepare("
        INSERT INTO delivery_order_tracking (
            order_id,
            driver_id,
            status,
            eta_minutes,
            recipient_latitude,
            recipient_longitude,
            driver_name,
            driver_phone,
            vehicle_type,
            vehicle_number,
            share_path,
            last_updated
        ) VALUES (
            :order_id,
            :driver_id,
            'accepted',
            :eta_minutes,
            :recipient_latitude,
            :recipient_longitude,
            :driver_name,
            :driver_phone,
            :vehicle_type,
            :vehicle_number,
            :share_path,
            NOW()
        )
        ON DUPLICATE KEY UPDATE
            driver_id = VALUES(driver_id),
            status = VALUES(status),
            eta_minutes = VALUES(eta_minutes),
            recipient_latitude = VALUES(recipient_latitude),
            recipient_longitude = VALUES(recipient_longitude),
            driver_name = VALUES(driver_name),
            driver_phone = VALUES(driver_phone),
            vehicle_type = VALUES(vehicle_type),
            vehicle_number = VALUES(vehicle_number),
            share_path = VALUES(share_path),
            last_updated = NOW()
    ");
    $trackingQuery->execute([
        ':order_id' => $orderId,
        ':driver_id' => $driverId,
        ':eta_minutes' => (int)($order['orders_estimated_minutes'] ?? 0),
        ':recipient_latitude' => $order['delivery_latitude'] ?? $order['orders_recipient_lat'] ?? null,
        ':recipient_longitude' => $order['delivery_longitude'] ?? $order['orders_recipient_lng'] ?? null,
        ':driver_name' => $driver['name'] ?? '',
        ':driver_phone' => $driver['phone'] ?? '',
        ':vehicle_type' => $driver['vehicle_type'] ?? '',
        ':vehicle_number' => $driver['vehicle_number'] ?? '',
        ':share_path' => !empty($order['orders_share_token'])
            ? '/track.php?token=' . urlencode($order['orders_share_token'])
            : null,
    ]);

    try {
        notifyDriver(
            $con,
            $driverId,
            'driver_order_assignment',
            'طلب جديد بانتظارك',
            'تم إرسال الطلب #' . $orderId . ' إليك. افتح التطبيق لقبول ومتابعة الطلب.',
            'order',
            $orderId,
            [
                'order_id' => (string)$orderId,
                'driver_id' => (string)$driverId,
                'vendor_type' => (string)($order['vendor_type'] ?? 'restaurant'),
                'store_category' => (string)($order['store_category'] ?? ''),
                'delivery_status' => 'accepted',
                'screen' => 'current_order',
            ],
            true
        );

        notifyUser(
            $con,
            (int)($order['orders_usersid'] ?? 0),
            'driver_assigned',
            'تم استلام طلبك',
            'تم استلام الطلب #' . $orderId . ' من السائق وسيتم تحديثك أثناء التوصيل.',
            'order',
            $orderId,
            [
                'order_id' => (string)$orderId,
                'driver_id' => (string)$driverId,
                'delivery_status' => 'accepted',
                'screen' => 'order_tracking',
            ],
            true
        );

        notifyVendor(
            $con,
            (int)($order['vendor_id'] ?? 0),
            'driver_assigned',
            'تم إرسال الطلب للسائق',
            'تم إرسال الطلب #' . $orderId . ' إلى السائق ' . trim((string)($driver['name'] ?? '')) . '.',
            'order',
            $orderId,
            [
                'order_id' => (string)$orderId,
                'vendor_id' => (string)($order['vendor_id'] ?? 0),
                'driver_id' => (string)$driverId,
                'driver_name' => trim((string)($driver['name'] ?? '')),
                'delivery_status' => 'accepted',
                'screen' => 'delivery_operations',
            ],
            true
        );
    } catch (Throwable $notificationError) {
        error_log('Driver direct assignment notifications failed: ' . $notificationError->getMessage());
    }

    echo json_encode(["status" => "success", "message" => "Order assigned"], JSON_UNESCAPED_UNICODE);
    exit;
}

echo json_encode(["status" => "error", "message" => "Unsupported action"], JSON_UNESCAPED_UNICODE);
