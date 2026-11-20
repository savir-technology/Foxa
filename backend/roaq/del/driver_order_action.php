<?php
include "connect.php";
require_once __DIR__ . "/../notifications/notification_helper.php";
header("Content-Type: application/json; charset=utf-8");
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
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"]);
    exit;
}
$data = readRequestData();
$driverId = (int)($data['driver_id'] ?? 0);
$orderId = (int)($data['order_id'] ?? 0);
$vendorId = (int)($data['vendor_id'] ?? 0);
$action = trim((string)($data['action'] ?? ''));
$proofCode = trim((string)($data['proof_code'] ?? ''));
if ($driverId <= 0 || $orderId <= 0 || $action === '') {
    echo json_encode(["status" => "error", "message" => "driver_id, order_id and action are required"]);
    exit;
}
if (function_exists('driverColumnExists') && driverColumnExists('delivery_users', 'approval_status')) {
    $approvalStmt = $con->prepare("SELECT approval_status FROM delivery_users WHERE id = ? LIMIT 1");
    $approvalStmt->execute([$driverId]);
    $approvalStatus = strtolower(trim((string)$approvalStmt->fetchColumn()));
    if ($approvalStatus !== 'approved') {
        echo json_encode([
            "status" => "error",
            "message" => "driver account is pending approval",
            "approval_status" => $approvalStatus !== '' ? $approvalStatus : 'pending',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
}
$statusMap = [
    'accept' => 'accepted',
    'heading_to_restaurant' => 'heading_to_restaurant',
    'arrived_at_restaurant' => 'arrived_at_restaurant',
    'picked_up' => 'picked_up',
    'heading_to_customer' => 'heading_to_customer',
    'arrived_at_customer' => 'arrived_at_customer',
    'delivered' => 'delivered',
];
function fetchRestaurantCoordinates(PDO $con, int $orderId): array
{
    $stmt = $con->prepare("
        SELECT
            COALESCE(
                vss.store_latitude,
                (
                    SELECT MIN(rb.latitude)
                    FROM order_items oi_lat
                    JOIN vendors v_lat ON v_lat.vendor_id = oi_lat.vendor_id
                    LEFT JOIN restaurant_branches rb
                        ON rb.vendor_id = v_lat.vendor_id
                       AND rb.is_active = 1
                    WHERE oi_lat.order_id = ?
                )
            ) AS store_latitude,
            COALESCE(
                vss.store_longitude,
                (
                    SELECT MIN(rb.longitude)
                    FROM order_items oi_lng
                    JOIN vendors v_lng ON v_lng.vendor_id = oi_lng.vendor_id
                    LEFT JOIN restaurant_branches rb
                        ON rb.vendor_id = v_lng.vendor_id
                        AND rb.is_active = 1
                    WHERE oi_lng.order_id = ?
                )
            ) AS store_longitude,
            COALESCE(
                vss.store_address,
                v.vendor_description,
                (
                    SELECT CONCAT_WS(' - ', rb.branch_name_en, rb.branch_name_ar)
                    FROM order_items oi_branch
                    LEFT JOIN vendors v_branch ON v_branch.vendor_id = oi_branch.vendor_id
                    LEFT JOIN restaurant_branches rb
                        ON rb.vendor_id = v_branch.vendor_id
                       AND rb.is_active = 1
                    WHERE oi_branch.order_id = ?
                    ORDER BY oi_branch.order_item_id ASC
                    LIMIT 1
                ),
                ''
            ) AS store_address
        FROM orders o
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        WHERE o.orders_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId, $orderId, $orderId, $orderId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $coordinates = deliveryResolveCoordinatePair(
        $row['store_latitude'] ?? null,
        $row['store_longitude'] ?? null,
        $row['store_address'] ?? null
    );
    return [
        'lat' => $coordinates['lat'],
        'lng' => $coordinates['lng'],
    ];
}
function fetchCustomerCoordinates(PDO $con, int $orderId): array
{
    $stmt = $con->prepare("
        SELECT
            COALESCE(o.delivery_latitude, o.orders_recipient_lat, a.address_lat) AS customer_lat,
            COALESCE(o.delivery_longitude, o.orders_recipient_lng, a.address_long) AS customer_lng,
            COALESCE(
                o.delivery_address,
                o.orders_recipient_address_name,
                a.address_name,
                ''
            ) AS customer_address_name,
            COALESCE(o.orders_recipient_address_line, a.address_street, '') AS customer_address_line
        FROM orders o
        LEFT JOIN address a ON a.address_id = o.orders_address
        WHERE o.orders_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $coordinates = deliveryResolveCoordinatePair(
        $row['customer_lat'] ?? null,
        $row['customer_lng'] ?? null,
        trim(
            (string)($row['customer_address_name'] ?? '') .
            ' ' .
            (string)($row['customer_address_line'] ?? '')
        )
    );
    return [
        'lat' => $coordinates['lat'],
        'lng' => $coordinates['lng'],
        'address_name' => trim((string)($row['customer_address_name'] ?? '')),
        'address_line' => trim((string)($row['customer_address_line'] ?? '')),
    ];
}
function resolveDistanceKmForOrder(
    array $driver,
    array $restaurantCoords,
    array $customerCoords
): float
{
    $normalize = static function ($value): ?float {
        if ($value === null) {
            return null;
        }
        $number = (float)trim((string)$value);
        if (!is_finite($number) || $number == 0.0) {
            return null;
        }
        return $number;
    };
    $hasCoordinate = static function (?float $lat, ?float $lng): bool {
        return $lat !== null && $lng !== null && ($lat != 0.0 || $lng != 0.0);
    };
    $driverLat = $normalize($driver['latitude'] ?? null);
    $driverLng = $normalize($driver['longitude'] ?? null);
    $restaurantLat = $normalize($restaurantCoords['lat'] ?? null);
    $restaurantLng = $normalize($restaurantCoords['lng'] ?? null);
    $customerLat = $customerCoords['lat'];
    $customerLng = $customerCoords['lng'];
    if ($hasCoordinate($driverLat, $driverLng) && $hasCoordinate($customerLat, $customerLng)) {
        return distance($driverLat, $driverLng, $customerLat, $customerLng);
    }
    if ($hasCoordinate($restaurantLat, $restaurantLng) && $hasCoordinate($customerLat, $customerLng)) {
        return distance($restaurantLat, $restaurantLng, $customerLat, $customerLng);
    }
    if ($hasCoordinate($driverLat, $driverLng) && $hasCoordinate($restaurantLat, $restaurantLng)) {
        return distance($driverLat, $driverLng, $restaurantLat, $restaurantLng);
    }
    return 0.0;
}
function estimateEtaMinutesFromDistance(float $distanceKm, int $fallbackMinutes): int
{
    if ($distanceKm > 0) {
        return max(1, (int)ceil(($distanceKm / 25.0) * 60.0));
    }
    return max(1, $fallbackMinutes);
}
function sendDriverOrderStatusNotification(PDO $con, array $order, int $driverId, string $action): void
{
    $orderId = (int)($order['orders_id'] ?? $order['order_id'] ?? 0);
    if ($driverId <= 0 || $orderId <= 0) {
        return;
    }
    $orderLabel = '#' . $orderId;
    $titleMap = [
        'accept' => 'تم قبول الطلب',
        'heading_to_restaurant' => 'في الطريق إلى المطعم',
        'arrived_at_restaurant' => 'وصلت إلى المطعم',
        'picked_up' => 'تم استلام الطلب',
        'heading_to_customer' => 'في الطريق إلى العميل',
        'arrived_at_customer' => 'وصلت إلى العميل',
        'delivered' => 'تم تسليم الطلب',
    ];
    $bodyMap = [
        'accept' => "تم تثبيت الطلب {$orderLabel} عليك بنجاح ويمكنك متابعة التنفيذ الآن.",
        'heading_to_restaurant' => "بدأت التوجه إلى المطعم للطلب {$orderLabel}.",
        'arrived_at_restaurant' => "وصلت إلى المطعم الخاص بالطلب {$orderLabel}.",
        'picked_up' => "تم استلام الطلب {$orderLabel} من المطعم وجاهز للانتقال.",
        'heading_to_customer' => "أنت الآن في الطريق إلى العميل للطلب {$orderLabel}.",
        'arrived_at_customer' => "وصلت إلى العميل للطلب {$orderLabel}.",
        'delivered' => "تم تحديث حالة الطلب {$orderLabel} إلى تم التسليم.",
    ];
    $title = $titleMap[$action] ?? 'تم تحديث حالة الطلب';
    $body = $bodyMap[$action] ?? "تم تحديث حالة الطلب {$orderLabel} بنجاح.";
    notifyDriver(
        $con,
        $driverId,
        'delivery_update',
        $title,
        $body,
        'order',
        $orderId,
        [
            'order_id' => (string)$orderId,
            'driver_id' => (string)$driverId,
            'action' => $action,
            'delivery_status' => trim((string)($order['status'] ?? '')),
        ],
        true
    );
}
function pushTrackingSnapshot(PDO $con, array $order, array $driver): void
{
    $orderId = (int)($order['orders_id'] ?? 0);
    if ($orderId <= 0) {
        return;
    }
    $trackingStmt = $con->prepare("
        SELECT
            recipient_latitude,
            recipient_longitude,
            support_phone,
            share_path,
            delivery_proof_image_url,
            eta_minutes
        FROM delivery_order_tracking
        WHERE order_id = ?
        LIMIT 1
    ");
    $trackingStmt->execute([$orderId]);
    $tracking = $trackingStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $vendorStmt = $con->prepare("
        SELECT
            vss.store_latitude,
            vss.store_longitude
        FROM order_items oi
        LEFT JOIN vendors v ON v.vendor_id = oi.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        WHERE oi.order_id = ?
        ORDER BY oi.order_item_id ASC
        LIMIT 1
    ");
    $vendorStmt->execute([$orderId]);
    $vendorRow = $vendorStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $restaurantCoords = fetchRestaurantCoordinates($con, $orderId);
    $customerCoords = fetchCustomerCoordinates($con, $orderId);
    $shareToken = trim((string)($order['orders_share_token'] ?? ''));
    $sharePath = trim((string)($tracking['share_path'] ?? ''));
    if ($sharePath === '' && $shareToken !== '') {
        $sharePath = '/track.php?token=' . urlencode($shareToken);
    }
    $normalizeCoordinate = static function ($value): ?float {
        if ($value === null) {
            return null;
        }
        $number = (float)trim((string)$value);
        if (!is_finite($number) || $number == 0.0) {
            return null;
        }
        return $number;
    };
    $resolveRouteDistanceKm = static function (
        ?float $driverLat,
        ?float $driverLng,
        ?float $restaurantLat,
        ?float $restaurantLng,
        ?float $recipientLat,
        ?float $recipientLng
    ): float {
        if ($restaurantLat !== null && $restaurantLng !== null && $recipientLat !== null && $recipientLng !== null) {
            return distance($restaurantLat, $restaurantLng, $recipientLat, $recipientLng);
        }
        if ($driverLat !== null && $driverLng !== null && $recipientLat !== null && $recipientLng !== null) {
            return distance($driverLat, $driverLng, $recipientLat, $recipientLng);
        }
        if ($driverLat !== null && $driverLng !== null && $restaurantLat !== null && $restaurantLng !== null) {
            return distance($driverLat, $driverLng, $restaurantLat, $restaurantLng);
        }
        return 0.0;
    };
    $payload = [
        'status' => (string)($order['status'] ?? 'pending'),
        'eta_minutes' => (int)($tracking['eta_minutes'] ?? $order['orders_estimated_minutes'] ?? 0),
        'route_distance_km' => $resolveRouteDistanceKm(
            $normalizeCoordinate($driver['latitude'] ?? null),
            $normalizeCoordinate($driver['longitude'] ?? null),
            $restaurantCoords['lat'],
            $restaurantCoords['lng'],
            $normalizeCoordinate($tracking['recipient_latitude'] ?? $customerCoords['lat'] ?? null),
            $normalizeCoordinate($tracking['recipient_longitude'] ?? $customerCoords['lng'] ?? null)
        ),
        'last_updated' => gmdate('c'),
        'driver_id' => (string)$driverId,
        'driver' => [
            'id' => (string)$driverId,
            'name' => trim((string)($driver['name'] ?? '')),
            'phone' => trim((string)($driver['phone'] ?? '')),
            'vehicle' => trim(trim((string)($driver['vehicle_type'] ?? '')) . ' - ' . trim((string)($driver['vehicle_number'] ?? '')), ' -'),
            'photo_url' => '',
        ],
        'driver_location' => [
            'lat' => $normalizeCoordinate($driver['latitude'] ?? null),
            'lng' => $normalizeCoordinate($driver['longitude'] ?? null),
        ],
        'restaurant_location' => [
            'lat' => $restaurantCoords['lat'],
            'lng' => $restaurantCoords['lng'],
        ],
        'recipient_location' => [
            'lat' => $normalizeCoordinate($tracking['recipient_latitude'] ?? $customerCoords['lat'] ?? null),
            'lng' => $normalizeCoordinate($tracking['recipient_longitude'] ?? $customerCoords['lng'] ?? null),
        ],
        'delivery_location' => [
            'lat' => $normalizeCoordinate($tracking['recipient_latitude'] ?? $customerCoords['lat'] ?? null),
            'lng' => $normalizeCoordinate($tracking['recipient_longitude'] ?? $customerCoords['lng'] ?? null),
        ],
        'delivery_address' => trim((string)($customerCoords['address_name'] ?? '')),
        'delivery_proof' => [
            'image_url' => trim((string)($tracking['delivery_proof_image_url'] ?? '')),
        ],
        'support_phone' => trim((string)($tracking['support_phone'] ?? '')),
        'share_path' => $sharePath,
    ];
    $payloadJson = json_encode($payload, JSON_UNESCAPED_UNICODE);
    if ($payloadJson === false) {
        return;
    }
    $firebaseUrl = 'https://savirv604-default-rtdb.firebaseio.com/order_tracking/' . rawurlencode((string)$orderId) . '.json';
    if (function_exists('curl_init')) {
        $ch = curl_init($firebaseUrl);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => 'PUT',
            CURLOPT_POSTFIELDS => $payloadJson,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json; charset=utf-8',
                'Accept: application/json',
            ],
            CURLOPT_TIMEOUT => 12,
        ]);
        curl_exec($ch);
        curl_close($ch);
        return;
    }
    $context = stream_context_create([
        'http' => [
            'method' => 'PUT',
            'header' => "Content-Type: application/json; charset=utf-8\r\nAccept: application/json\r\n",
            'content' => $payloadJson,
            'timeout' => 12,
        ],
    ]);
    @file_get_contents($firebaseUrl, false, $context);
}
if (!array_key_exists($action, $statusMap)) {
    echo json_encode(["status" => "error", "message" => "Unsupported action"]);
    exit;
}
try {
    ensureVendorOrderDeliverySchema();
    $stage = 'driver_lookup';
    $driverStmt = $con->prepare("
        SELECT
            id,
            name,
            phone,
            vehicle_type,
            vehicle_number,
            latitude,
            longitude
        FROM delivery_users
        WHERE id = ?
        LIMIT 1
    ");
    $driverStmt->execute([$driverId]);
    $driver = $driverStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    if (!$driver) {
        echo json_encode([
            "status" => "error",
            "message" => "Driver not found",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $targetStatus = $statusMap[$action];
    $assignmentStmt = $con->prepare("SELECT vendor_id FROM vendor_orders
        WHERE order_id = :order_id AND delivery_id = :driver_id
          AND (:vendor_filter_enabled = 0 OR vendor_id = :vendor_filter_id)
        ORDER BY vendor_order_id ASC LIMIT 1");
    $assignmentStmt->execute([
        ':order_id' => $orderId,
        ':driver_id' => $driverId,
        ':vendor_filter_enabled' => $vendorId > 0 ? 1 : 0,
        ':vendor_filter_id' => $vendorId,
    ]);
    $assignedVendorId = (int)($assignmentStmt->fetchColumn() ?: 0);
    if ($assignedVendorId <= 0) {
        echo json_encode(["status" => "error", "message" => "Order is not assigned to this driver"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $vendorId = $assignedVendorId;
    $vendorStatusStmt = $con->prepare("UPDATE vendor_orders
        SET delivery_status = :delivery_status, updated_at = NOW()
        WHERE order_id = :order_id AND vendor_id = :vendor_id AND delivery_id = :driver_id");
    $vendorStatusStmt->execute([
        ':delivery_status' => $targetStatus,
        ':order_id' => $orderId,
        ':vendor_id' => $vendorId,
        ':driver_id' => $driverId,
    ]);
    if ($action === 'accept') {
        $stage = 'accept_update';
        $stmt = $con->prepare("
            UPDATE orders
            SET delivery_id = ?,
                status = ?,
                assigned_at = NOW(),
                accepted_at = NOW()
            WHERE orders_id = ?
              AND (delivery_id IS NULL OR delivery_id = 0 OR delivery_id = ?)
        ");
        $stmt->execute([$driverId, $targetStatus, $orderId, $driverId]);
    } elseif ($action === 'arrived_at_restaurant') {
        $stage = 'arrived_at_restaurant_update';
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?,
                arrived_at_restaurant_at = NOW()
            WHERE orders_id = ?
              AND delivery_id = ?
        ");
        $stmt->execute([$targetStatus, $orderId, $driverId]);
    } elseif ($action === 'picked_up') {
        $stage = 'picked_up_update';
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?,
                picked_up_at = NOW()
            WHERE orders_id = ?
              AND delivery_id = ?
        ");
        $stmt->execute([$targetStatus, $orderId, $driverId]);
    } elseif ($action === 'arrived_at_customer') {
        $stage = 'arrived_at_customer_update';
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?,
                arrived_at_customer_at = NOW()
            WHERE orders_id = ?
              AND delivery_id = ?
        ");
        $stmt->execute([$targetStatus, $orderId, $driverId]);
    } elseif ($action === 'delivered') {
        $stage = 'delivered_update';
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?,
                delivered_at = NOW(),
                proof_code = COALESCE(NULLIF(?, ''), proof_code)
            WHERE orders_id = ?
              AND delivery_id = ?
        ");
        $stmt->execute([$targetStatus, $proofCode, $orderId, $driverId]);
    } else {
        $stage = 'generic_update';
        $stmt = $con->prepare("
            UPDATE orders
            SET status = ?
            WHERE orders_id = ?
              AND delivery_id = ?
        ");
        $stmt->execute([$targetStatus, $orderId, $driverId]);
    }
    $stage = 'order_fetch';
    $fetch = $con->prepare("SELECT * FROM orders WHERE orders_id = ? LIMIT 1");
    $fetch->execute([$orderId]);
    $order = $fetch->fetch(PDO::FETCH_ASSOC) ?: null;
    if (!$order) {
        echo json_encode([
            "status" => "error",
            "message" => "Order not found",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $orderDriverId = (int)($order['delivery_id'] ?? 0);
    $orderStatus = trim((string)($order['status'] ?? ''));
    $restaurantCoords = fetchRestaurantCoordinates($con, $orderId);
    $customerCoords = fetchCustomerCoordinates($con, $orderId);
    $distanceKm = resolveDistanceKmForOrder($driver, $restaurantCoords, $customerCoords);
    $etaMinutes = estimateEtaMinutesFromDistance(
        $distanceKm,
        (int)($order['orders_estimated_minutes'] ?? 0)
    );
    $routeDistanceKm = $distanceKm > 0 ? $distanceKm : 0.0;
    $order['restaurant_lat'] = $restaurantCoords['lat'];
    $order['restaurant_lng'] = $restaurantCoords['lng'];
    $order['restaurant_location'] = [
        'lat' => $restaurantCoords['lat'],
        'lng' => $restaurantCoords['lng'],
    ];
    $order['customer_lat'] = $customerCoords['lat'];
    $order['customer_lng'] = $customerCoords['lng'];
    $order['customer_location'] = [
        'lat' => $customerCoords['lat'],
        'lng' => $customerCoords['lng'],
    ];
    $order['driver_current_latitude'] = $driver['latitude'] ?? null;
    $order['driver_current_longitude'] = $driver['longitude'] ?? null;
    $order['driver_location'] = [
        'lat' => $driver['latitude'] ?? null,
        'lng' => $driver['longitude'] ?? null,
    ];
    $order['distance_km'] = $distanceKm;
    $order['route_distance_km'] = $routeDistanceKm;
    $order['eta_minutes'] = $etaMinutes;
    $order['restaurant_name'] = $order['restaurant_name'] ?? '';
    $order['vendor_id'] = $vendorId;
    $order['restaurant_phone'] = $order['restaurant_phone'] ?? '';
    $order['restaurant_address'] = $order['restaurant_address'] ?? '';
    unset($order['proof_code'], $order['delivery_code']);
    if ($action === 'accept') {
        if ($orderDriverId !== $driverId || !in_array($orderStatus, ['accepted', 'assigned'], true)) {
            echo json_encode([
                "status" => "error",
                "message" => "Order is no longer available",
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    } elseif ($orderDriverId !== $driverId || $orderStatus !== $targetStatus) {
        echo json_encode([
            "status" => "error",
            "message" => "Order update failed",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if ($action === 'accept') {
        try {
            notifyUser(
                $con,
                (int)($order['orders_usersid'] ?? 0),
                'delivery_update',
                'تم قبول طلبك',
                'تم قبول طلبك من السائق، ويمكنك متابعة حركة الطلب الآن.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'accepted',
                ],
                true
            );
        } catch (Throwable $notificationError) {
            // Keep the order action successful even if notification delivery fails.
        }
    } elseif ($action === 'picked_up') {
        try {
            notifyUser(
                $con,
                (int)($order['orders_usersid'] ?? 0),
                'delivery_update',
                'تم استلام الأوردر',
                'استلم السائق طلبك من المطعم وسيبدأ التحرك إليك قريباً.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'picked_up',
                    'screen' => 'order_tracking',
                ],
                true
            );
        } catch (Throwable $notificationError) {
            // Keep the order action successful even if notification delivery fails.
        }
    } elseif ($action === 'heading_to_customer') {
        try {
            notifyUser(
                $con,
                (int)($order['orders_usersid'] ?? 0),
                'delivery_update',
                'طلبك في الطريق',
                'السائق في الطريق إلى وجهتك الآن ويمكنك متابعة الخريطة مباشرة.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'on_the_way',
                    'screen' => 'order_tracking',
                ],
                true
            );
        } catch (Throwable $notificationError) {
            // Keep the order action successful even if notification delivery fails.
        }
    } elseif ($action === 'arrived_at_customer') {
        try {
            notifyUser(
                $con,
                (int)($order['orders_usersid'] ?? 0),
                'delivery_update',
                'تم الوصول للوجهة',
                'وصل السائق إلى وجهتك للطلب #' . $orderId . '. يرجى تجهيز رمز الاستلام إن وجد.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'arrived_at_customer',
                    'screen' => 'order_tracking',
                ],
                true
            );
        } catch (Throwable $notificationError) {
            // Keep the order action successful even if notification delivery fails.
        }
    } elseif ($action === 'delivered' && trim((string)($order['proof_image'] ?? '')) === '') {
        try {
            notifyUser(
                $con,
                (int)($order['orders_usersid'] ?? 0),
                'delivery_update',
                'تم تسليم طلبك',
                'وصل طلبك. من فضلك قيّم السائق بعد استلام الطلب.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'delivered',
                ],
                true
            );
        } catch (Throwable $notificationError) {
            // Ignore notification issues here as well.
        }
    }
    try {
        $vendorTitleMap = [
            'accept' => 'قبل السائق الطلب',
            'heading_to_restaurant' => 'السائق في الطريق للمطعم',
            'arrived_at_restaurant' => 'وصل السائق للمطعم',
            'picked_up' => 'تم استلام الطلب من المطعم',
            'heading_to_customer' => 'الطلب في الطريق للعميل',
            'arrived_at_customer' => 'وصل السائق للعميل',
            'delivered' => 'تم تسليم الطلب',
        ];
        $vendorBodyMap = [
            'accept' => 'قبل السائق ' . trim((string)($driver['name'] ?? '')) . ' الطلب #' . $orderId . '.',
            'heading_to_restaurant' => 'السائق في الطريق إلى المطعم لاستلام الطلب #' . $orderId . '.',
            'arrived_at_restaurant' => 'وصل السائق إلى المطعم لاستلام الطلب #' . $orderId . '.',
            'picked_up' => 'استلم السائق الطلب #' . $orderId . ' من المطعم.',
            'heading_to_customer' => 'الطلب #' . $orderId . ' في الطريق إلى العميل.',
            'arrived_at_customer' => 'وصل السائق إلى العميل للطلب #' . $orderId . '.',
            'delivered' => 'تم تسليم الطلب #' . $orderId . ' بنجاح.',
        ];
        notifyOrderVendors(
            $con,
            $orderId,
            'delivery_update',
            $vendorTitleMap[$action] ?? 'تحديث حالة التوصيل',
            $vendorBodyMap[$action] ?? 'تم تحديث حالة التوصيل للطلب #' . $orderId . '.',
            [
                'driver_id' => (string)$driverId,
                'driver_name' => trim((string)($driver['name'] ?? '')),
                'delivery_status' => $targetStatus,
                'action' => $action,
                'screen' => 'delivery_operations',
            ],
            true
        );
    } catch (Throwable $notificationError) {
        error_log('Vendor delivery update notification failed: ' . $notificationError->getMessage());
    }
    try {
        sendDriverOrderStatusNotification($con, $order, $driverId, $action);
    } catch (Throwable $notificationError) {
        // Keep the order action successful even if the driver feed notification fails.
    }
    echo json_encode([
        "status" => "success",
        "message" => "Order updated",
        "order" => $order,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
        "stage" => $stage ?? null,
    ], JSON_UNESCAPED_UNICODE);
}
