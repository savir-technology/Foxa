<?php
include "../../../connect.php";
require_once __DIR__ . "/../../../chat/firebase/send_notification.php";
require_once __DIR__ . "/../../../notifications/notification_helper.php";
header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
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
$isVendor = $actor['role'] === 'vendor';
$actorVendorId = $isVendor ? (int)($actor['vendor']['vendor_id'] ?? 0) : 0;
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "status" => "error",
        "message" => "يجب استخدام POST",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
$orderId = (int)($_POST['order_id'] ?? 0);
$driverId = (int)($_POST['driver_id'] ?? 0);
$requestedVendorId = (int)($_POST['vendor_id'] ?? 0);
if ($orderId <= 0 || $driverId <= 0) {
    $requestData = readRequestData();
    $orderId = (int)($requestData['order_id'] ?? $orderId);
    $driverId = (int)($requestData['driver_id'] ?? $driverId);
    $requestedVendorId = (int)($requestData['vendor_id'] ?? $requestedVendorId);
}
if ($orderId <= 0 || $driverId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "order_id و driver_id مطلوبان",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
function fetchOrderVendorId(PDO $con, int $orderId): int
{
    $stmt = $con->prepare("
        SELECT vo.vendor_id
        FROM vendor_orders vo
        WHERE vo.order_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId]);
    return (int)($stmt->fetchColumn() ?: 0);
}
function sendDriverAssignmentNotification(PDO $con, int $driverId, array $order, array $driver): int
{
    $tokenStmt = $con->prepare("
        SELECT push_token
        FROM delivery_driver_push_tokens
        WHERE driver_id = ?
          AND is_active = 1
        ORDER BY updated_at DESC, created_at DESC
    ");
    $tokenStmt->execute([$driverId]);
    $tokens = $tokenStmt->fetchAll(PDO::FETCH_COLUMN);
    $sent = 0;
    if (!$tokens) {
        return $sent;
    }
    $restaurantName = trim((string)($order['store_name'] ?? $order['vendor_name'] ?? 'Restaurant'));
    $orderLabel = '#' . (string)($order['orders_id'] ?? $order['order_id'] ?? '');
    $title = 'تم إسناد طلب جديد';
    $body = sprintf(
        'الطلب %s من %s',
        $orderLabel,
        $restaurantName !== '' ? $restaurantName : 'Restaurant'
    );
    $payload = [
        'type' => 'driver_order_assignment',
        'order_id' => (string)($order['orders_id'] ?? 0),
        'driver_id' => (string)$driverId,
        'restaurant_name' => $restaurantName,
        'vendor_type' => (string)($order['vendor_type'] ?? 'restaurant'),
        'store_category' => (string)($order['store_category'] ?? ''),
        'driver_name' => (string)($driver['name'] ?? ''),
        'delivery_id' => (string)$driverId,
        'gift_message' => trim((string)($order['orders_gift_message'] ?? '')),
        'delivery_note' => trim((string)($order['orders_delivery_note'] ?? '')),
    ];
    notifyDriver(
        $con,
        $driverId,
        'driver_order_assignment',
        $title,
        $body,
        'order',
        (int)($order['orders_id'] ?? $order['order_id'] ?? 0),
        $payload,
        true
    );
    $sent = count($tokens);
    return $sent;
}
function normalizeTrackingCoordinate($value): ?float
{
    if ($value === null) {
        return null;
    }
    $number = (float)trim((string)$value);
    if (!is_finite($number) || $number == 0.0) {
        return null;
    }
    return $number;
}
function isDriverOnline(array $driver): bool
{
    if (($driver['status'] ?? '') === 'online') {
        return true;
    }
    $lastSeenAt = trim((string)($driver['last_seen_at'] ?? ''));
    if ($lastSeenAt === '') {
        return false;
    }
    $timestamp = strtotime($lastSeenAt);
    if ($timestamp === false) {
        return false;
    }
    return $timestamp >= (time() - 300);
}
function fetchDriverActiveOrdersCount(PDO $con, int $driverId): int
{
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM orders
        WHERE delivery_id = ?
          AND COALESCE(status, '') NOT IN ('delivered', 'completed', 'canceled', 'cancelled')
    ");
    $stmt->execute([$driverId]);
    return (int)($stmt->fetchColumn() ?: 0);
}
function distanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float
{
    $earthRadius = 6371.0;
    $lat1Rad = deg2rad($lat1);
    $lat2Rad = deg2rad($lat2);
    $deltaLat = deg2rad($lat2 - $lat1);
    $deltaLng = deg2rad($lng2 - $lng1);
    $a = sin($deltaLat / 2) * sin($deltaLat / 2)
        + cos($lat1Rad) * cos($lat2Rad)
        * sin($deltaLng / 2) * sin($deltaLng / 2);
    $c = 2 * atan2(sqrt($a), sqrt(max(0.0, 1 - $a)));
    return $earthRadius * $c;
}
function resolveRouteDistanceKm(
    ?float $driverLat,
    ?float $driverLng,
    ?float $restaurantLat,
    ?float $restaurantLng,
    ?float $recipientLat,
    ?float $recipientLng
): float {
    if ($driverLat !== null && $driverLng !== null && $recipientLat !== null && $recipientLng !== null) {
        return distanceKm($driverLat, $driverLng, $recipientLat, $recipientLng);
    }
    if ($restaurantLat !== null && $restaurantLng !== null && $recipientLat !== null && $recipientLng !== null) {
        return distanceKm($restaurantLat, $restaurantLng, $recipientLat, $recipientLng);
    }
    if ($driverLat !== null && $driverLng !== null && $restaurantLat !== null && $restaurantLng !== null) {
        return distanceKm($driverLat, $driverLng, $restaurantLat, $restaurantLng);
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
        FROM vendor_orders vo
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        WHERE vo.order_id = ?
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
function pushTrackingSnapshot(PDO $con, int $orderId, int $driverId): void
{
    $snapshotStmt = $con->prepare("
        SELECT
            o.orders_id,
            o.orders_share_token,
            o.order_mode,
            o.scheduled_for,
            o.orders_estimated_minutes,
            o.orders_gift_message,
            o.orders_delivery_note,
            COALESCE(o.delivery_latitude, o.orders_recipient_lat, a.address_lat) AS delivery_latitude,
            COALESCE(o.delivery_longitude, o.orders_recipient_lng, a.address_long) AS delivery_longitude,
            COALESCE(
                o.delivery_address,
                o.orders_recipient_address_name,
                a.address_name,
                ''
            ) AS delivery_address,
            COALESCE(o.orders_recipient_address_name, a.address_name, '') AS orders_recipient_address_name,
            COALESCE(o.orders_recipient_address_line, a.address_street, '') AS orders_recipient_address_line,
            COALESCE(o.proof_code, o.orders_share_token) AS delivery_code,
            o.status,
            o.orders_status,
            du.name AS driver_name,
            du.phone AS driver_phone,
            du.vehicle_type,
            du.vehicle_number,
            du.latitude AS driver_latitude,
            du.longitude AS driver_longitude,
            vss.store_latitude,
            vss.store_longitude
        FROM orders o
        LEFT JOIN delivery_users du ON du.id = o.delivery_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        LEFT JOIN (
            SELECT oi.order_id, MIN(oi.vendor_id) AS vendor_id
            FROM order_items oi
            WHERE oi.order_id = ?
            GROUP BY oi.order_id
            LIMIT 1
        ) ov ON ov.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = ov.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        WHERE o.orders_id = ?
        LIMIT 1
    ");
    $snapshotStmt->execute([$orderId, $orderId]);
    $snapshot = $snapshotStmt->fetch(PDO::FETCH_ASSOC);
    if (!$snapshot) {
        return;
    }
    $trackingStmt = $con->prepare("
        SELECT
            recipient_latitude,
            recipient_longitude,
            support_phone,
            share_path
        FROM delivery_order_tracking
        WHERE order_id = ?
        LIMIT 1
    ");
    $trackingStmt->execute([$orderId]);
    $tracking = $trackingStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $restaurantCoords = fetchRestaurantCoordinates($con, $orderId);
    $recipientCoords = deliveryResolveCoordinatePair(
        $tracking['recipient_latitude'] ?? $snapshot['delivery_latitude'] ?? null,
        $tracking['recipient_longitude'] ?? $snapshot['delivery_longitude'] ?? null,
        trim(
            (string)($snapshot['delivery_address'] ?? $snapshot['orders_recipient_address_name'] ?? '') .
            ' ' .
            (string)($snapshot['orders_recipient_address_line'] ?? '')
        )
    );
    $routeDistanceKm = resolveRouteDistanceKm(
        normalizeTrackingCoordinate($snapshot['driver_latitude'] ?? null),
        normalizeTrackingCoordinate($snapshot['driver_longitude'] ?? null),
        $restaurantCoords['lat'],
        $restaurantCoords['lng'],
        $recipientCoords['lat'],
        $recipientCoords['lng']
    );
    $etaMinutes = estimateEtaMinutesFromDistance(
        $routeDistanceKm,
        (int)($snapshot['orders_estimated_minutes'] ?? 0)
    );
    $shareToken = trim((string)($snapshot['orders_share_token'] ?? ''));
    $sharePath = trim((string)($tracking['share_path'] ?? ''));
    if ($sharePath === '' && $shareToken !== '') {
        $sharePath = '/track.php?token=' . urlencode($shareToken);
    }
    $payload = [
        'status' => 'assigned',
        'eta_minutes' => $etaMinutes,
        'last_updated' => gmdate('c'),
        'driver_id' => (string)$driverId,
        'driver' => [
            'id' => (string)$driverId,
            'name' => trim((string)($snapshot['driver_name'] ?? '')),
            'phone' => trim((string)($snapshot['driver_phone'] ?? '')),
            'vehicle' => trim(trim((string)($snapshot['vehicle_type'] ?? '')) . ' - ' . trim((string)($snapshot['vehicle_number'] ?? '')), ' -'),
            'photo_url' => '',
        ],
        'driver_location' => [
            'lat' => normalizeTrackingCoordinate($snapshot['driver_latitude'] ?? null),
            'lng' => normalizeTrackingCoordinate($snapshot['driver_longitude'] ?? null),
        ],
        'restaurant_location' => [
            'lat' => $restaurantCoords['lat'],
            'lng' => $restaurantCoords['lng'],
        ],
        'recipient_location' => [
            'lat' => $recipientCoords['lat'],
            'lng' => $recipientCoords['lng'],
        ],
        'delivery_location' => [
            'lat' => $recipientCoords['lat'],
            'lng' => $recipientCoords['lng'],
        ],
        'delivery_address' => trim((string)($snapshot['delivery_address'] ?? '')),
        'gift_message' => trim((string)($snapshot['orders_gift_message'] ?? '')),
        'delivery_note' => trim((string)($snapshot['orders_delivery_note'] ?? '')),
        'order_mode' => $snapshot['order_mode'] ?? 'asap',
        'scheduled_for' => $snapshot['scheduled_for'] ?? null,
        'route_distance_km' => $resolveRouteDistanceKm(
            normalizeTrackingCoordinate($snapshot['driver_latitude'] ?? null),
            normalizeTrackingCoordinate($snapshot['driver_longitude'] ?? null),
            $restaurantCoords['lat'],
            $restaurantCoords['lng'],
            $recipientCoords['lat'],
            $recipientCoords['lng']
        ),
        'delivery_proof' => [
            'image_url' => '',
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
try {
    ensureVendorOrderDeliverySchema();
    $con->beginTransaction();
    $vendorFilterSql = $requestedVendorId > 0 ? ' AND vo.vendor_id = ?' : '';
    $orderStmt = $con->prepare("
        SELECT
            o.orders_id,
            o.orders_usersid,
            o.delivery_id,
            o.status,
            o.orders_status,
            o.orders_estimated_minutes,
            o.orders_gift_message,
            o.orders_delivery_note,
            o.orders_totalprice,
            o.orders_datetime,
            COALESCE(o.orders_recipient_lat, a.address_lat) AS orders_recipient_lat,
            COALESCE(o.orders_recipient_lng, a.address_long) AS orders_recipient_lng,
            vo.vendor_id,
            v.store_name,
            v.vendor_name,
            COALESCE(v.vendor_type, 'restaurant') AS vendor_type,
            COALESCE(v.store_category, '') AS store_category
        FROM orders o
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        WHERE o.orders_id = ?{$vendorFilterSql}
        LIMIT 1
        FOR UPDATE
    ");
    $orderParams = [$orderId];
    if ($requestedVendorId > 0) {
        $orderParams[] = $requestedVendorId;
    }
    $orderStmt->execute($orderParams);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
    if (!$order) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "الطلب غير موجود",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $orderVendorId = (int)($order['vendor_id'] ?? 0);
    if ($orderVendorId <= 0) {
        $orderVendorId = fetchOrderVendorId($con, $orderId);
    }
    $vendorAssignmentStmt = $con->prepare("
        UPDATE vendor_orders
        SET delivery_id = :driver_id,
            delivery_status = 'assigned',
            delivery_assigned_at = NOW(),
            updated_at = NOW()
        WHERE order_id = :order_id
          AND vendor_id = :vendor_id
    ");
    $vendorAssignmentStmt->execute([
        ':driver_id' => $driverId,
        ':order_id' => $orderId,
        ':vendor_id' => $orderVendorId,
    ]);
    if ($orderVendorId <= 0) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "تعذر تحديد المطعم الخاص بالطلب",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if ($isVendor && $actorVendorId > 0 && $orderVendorId !== $actorVendorId) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "الطلب لا يتبع هذا المطعم",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $driverStmt = $con->prepare("
        SELECT
            id,
            name,
            phone,
            vehicle_type,
            vehicle_number,
            latitude,
            longitude,
            status,
            last_seen_at
        FROM delivery_users
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
    ");
    $driverStmt->execute([$driverId]);
    $driver = $driverStmt->fetch(PDO::FETCH_ASSOC);
    if (!$driver) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "السائق غير موجود",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if (!isDriverOnline($driver)) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "السائق غير متصل حالياً",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $activeOrdersCount = fetchDriverActiveOrdersCount($con, $driverId);
    if ($activeOrdersCount > 0) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "السائق لديه طلبات نشطة حالياً",
            "active_orders_count" => $activeOrdersCount,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $currentDeliveryId = (int)($order['delivery_id'] ?? 0);
    $isReassignment = $currentDeliveryId > 0 && $currentDeliveryId !== $driverId;
    if (in_array((string)($order['status'] ?? ''), ['delivered', 'completed', 'canceled', 'cancelled'], true)) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "هذا الطلب مغلق بالفعل",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    // Any online driver can serve any restaurant/store. Distance is not used
    // as a dispatch restriction.
    $driverLatitude = normalizeTrackingCoordinate($driver['latitude'] ?? null);
    $driverLongitude = normalizeTrackingCoordinate($driver['longitude'] ?? null);
    $updateStmt = $con->prepare("
        UPDATE orders
        SET delivery_id = :driver_id,
            status = 'assigned',
            assigned_at = NOW(),
            updated_at = NOW()
        WHERE orders_id = :order_id
    ");
    $updateStmt->execute([
        ':driver_id' => $driverId,
        ':order_id' => $orderId,
    ]);
    $recipientLatitude = normalizeTrackingCoordinate($order['delivery_latitude'] ?? $order['orders_recipient_lat'] ?? null);
    $recipientLongitude = normalizeTrackingCoordinate($order['delivery_longitude'] ?? $order['orders_recipient_lng'] ?? null);
    $routeDistanceKm = resolveRouteDistanceKm(
        $driverLatitude,
        $driverLongitude,
        null,
        null,
        $recipientLatitude,
        $recipientLongitude
    );
    $etaMinutes = estimateEtaMinutesFromDistance(
        $routeDistanceKm,
        (int)($order['orders_estimated_minutes'] ?? 0)
    );
    $trackingStmt = $con->prepare("
        INSERT INTO delivery_order_tracking (
            order_id,
            driver_id,
            status,
            eta_minutes,
            driver_latitude,
            driver_longitude,
            recipient_latitude,
            recipient_longitude,
            driver_name,
            driver_phone,
            vehicle_type,
            vehicle_number,
            delivery_proof_image_url,
            support_phone,
            share_path,
            route_distance_km,
            last_updated
        ) VALUES (
            :order_id,
            :driver_id,
            'assigned',
            :eta_minutes,
            :driver_latitude,
            :driver_longitude,
            :recipient_latitude,
            :recipient_longitude,
            :driver_name,
            :driver_phone,
            :vehicle_type,
            :vehicle_number,
            NULL,
            NULL,
            NULL,
            :route_distance_km,
            NOW()
        )
        ON DUPLICATE KEY UPDATE
            driver_id = VALUES(driver_id),
            status = VALUES(status),
            eta_minutes = VALUES(eta_minutes),
            driver_latitude = VALUES(driver_latitude),
            driver_longitude = VALUES(driver_longitude),
            recipient_latitude = VALUES(recipient_latitude),
            recipient_longitude = VALUES(recipient_longitude),
            driver_name = VALUES(driver_name),
            driver_phone = VALUES(driver_phone),
            vehicle_type = VALUES(vehicle_type),
            vehicle_number = VALUES(vehicle_number),
            route_distance_km = VALUES(route_distance_km),
            last_updated = NOW()
    ");
    $trackingStmt->execute([
        ':order_id' => $orderId,
        ':driver_id' => $driverId,
        ':eta_minutes' => $etaMinutes,
        ':driver_latitude' => $driverLatitude,
        ':driver_longitude' => $driverLongitude,
        ':recipient_latitude' => $recipientLatitude,
        ':recipient_longitude' => $recipientLongitude,
        ':driver_name' => $driver['name'] ?? '',
        ':driver_phone' => $driver['phone'] ?? '',
        ':vehicle_type' => $driver['vehicle_type'] ?? '',
        ':vehicle_number' => $driver['vehicle_number'] ?? '',
        ':route_distance_km' => $routeDistanceKm,
    ]);
    $con->commit();
    $sentCount = sendDriverAssignmentNotification($con, $driverId, $order, $driver);
    try {
        notifyUser(
            $con,
            (int)($order['orders_usersid'] ?? 0),
            $isReassignment ? 'driver_reassigned' : 'driver_assigned',
            $isReassignment ? 'تم تحديث سائق طلبك' : 'تم تعيين سائق لطلبك',
            'تم تعيين السائق ' . trim((string)($driver['name'] ?? '')) . ' للطلب #' . $orderId . ' ويمكنك متابعة الحركة الآن.',
            'order',
            $orderId,
            [
                'order_id' => (string)$orderId,
                'driver_id' => (string)$driverId,
                'driver_name' => trim((string)($driver['name'] ?? '')),
                'delivery_status' => 'assigned',
                'screen' => 'order_tracking',
            ],
            true
        );
        notifyVendor(
            $con,
            $orderVendorId,
            $isReassignment ? 'driver_reassigned' : 'driver_assigned',
            $isReassignment ? 'تم تحديث سائق الطلب' : 'تم تعيين سائق للطلب',
            'تم تعيين السائق ' . trim((string)($driver['name'] ?? '')) . ' للطلب #' . $orderId . '.',
            'order',
            $orderId,
            [
                'order_id' => (string)$orderId,
                'vendor_id' => (string)$orderVendorId,
                'driver_id' => (string)$driverId,
                'driver_name' => trim((string)($driver['name'] ?? '')),
                'delivery_status' => 'assigned',
                'screen' => 'delivery_operations',
            ],
            true
        );
    } catch (Throwable $notificationError) {
        error_log('Assignment side notifications failed: ' . $notificationError->getMessage());
    }
    try {
        pushTrackingSnapshot($con, $orderId, $driverId);
    } catch (Throwable $trackingError) {
        // Keep the assignment even if the live feed update fails.
    }
    echo json_encode([
        "status" => "success",
        "message" => $isReassignment
            ? "Order reassigned successfully"
            : "Order assigned successfully",
        "order_id" => $orderId,
        "driver_id" => $driverId,
        "reassigned" => $isReassignment,
        "driver_notifications_sent" => $sentCount,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
