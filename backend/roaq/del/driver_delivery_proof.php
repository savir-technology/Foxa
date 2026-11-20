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
$driverId = (int)($data['driver_id'] ?? 0);
$orderId = (int)($data['order_id'] ?? $data['id'] ?? 0);
$proofType = trim((string)($data['proof_type'] ?? ''));
$proofCode = trim((string)($data['proof_code'] ?? ''));
$imageBase64 = trim((string)($data['image_base64'] ?? $data['image'] ?? ''));
$imageName = trim((string)($data['image_name'] ?? $data['file_name'] ?? ''));
if ($driverId <= 0 || $orderId <= 0 || $proofType === '') {
    echo json_encode([
        "status" => "error",
        "message" => "driver_id, order_id and proof_type are required",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
function ensureDeliveryProofColumns(PDO $con): void
{
    $requiredColumns = [
        'proof_type' => "VARCHAR(20) NULL",
        'proof_code' => "VARCHAR(32) NULL",
        'proof_image' => "VARCHAR(255) NULL",
        'delivered_at' => "DATETIME NULL",
    ];
    foreach ($requiredColumns as $column => $definition) {
        $stmt = $con->prepare("SHOW COLUMNS FROM orders LIKE ?");
        $stmt->execute([$column]);
        $exists = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$exists) {
            $con->exec("ALTER TABLE orders ADD COLUMN {$column} {$definition}");
        }
    }
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
        FROM orders o
        LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        WHERE o.orders_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId, $orderId, $orderId, $orderId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
    return deliveryResolveCoordinatePair(
        $row['store_latitude'] ?? null,
        $row['store_longitude'] ?? null,
        $row['store_address'] ?? null
    );
}
function pushTrackingSnapshot(PDO $con, int $orderId, int $driverId, string $proofImagePath): void
{
    $snapshotStmt = $con->prepare("
        SELECT
            o.orders_id,
            o.orders_share_token,
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
            o.driver_latitude,
            o.driver_longitude,
            o.status,
            o.orders_status,
            o.delivered_at,
            o.assigned_at,
            o.accepted_at,
            o.arrived_at_restaurant_at,
            o.picked_up_at,
            o.arrived_at_customer_at,
            du.name AS driver_name,
            du.phone AS driver_phone,
            du.vehicle_type,
            du.vehicle_number,
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
            driver_latitude,
            driver_longitude,
            recipient_latitude,
            recipient_longitude,
            driver_name,
            driver_phone,
            vehicle_type,
            vehicle_number,
            support_phone,
            share_path,
            eta_minutes
        FROM delivery_order_tracking
        WHERE order_id = ?
        LIMIT 1
    ");
    $trackingStmt->execute([$orderId]);
    $tracking = $trackingStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $driverName = trim((string)($tracking['driver_name'] ?? $snapshot['driver_name'] ?? ''));
    $driverPhone = trim((string)($tracking['driver_phone'] ?? $snapshot['driver_phone'] ?? ''));
    $vehicleType = trim((string)($tracking['vehicle_type'] ?? $snapshot['vehicle_type'] ?? ''));
    $vehicleNumber = trim((string)($tracking['vehicle_number'] ?? $snapshot['vehicle_number'] ?? ''));
    $supportPhone = trim((string)($tracking['support_phone'] ?? ''));
    $shareToken = trim((string)($snapshot['orders_share_token'] ?? ''));
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
    $status = trim((string)($snapshot['status'] ?? ''));
    if ($status === '') {
        $status = 'delivered';
    }
    $etaMinutes = (int)($tracking['eta_minutes'] ?? $snapshot['orders_estimated_minutes'] ?? 0);
    $driverLatitude = $normalizeCoordinate($tracking['driver_latitude'] ?? $snapshot['driver_latitude'] ?? null);
    $driverLongitude = $normalizeCoordinate($tracking['driver_longitude'] ?? $snapshot['driver_longitude'] ?? null);
    $recipientLatitude = $normalizeCoordinate($tracking['recipient_latitude'] ?? $snapshot['delivery_latitude'] ?? null);
    $recipientLongitude = $normalizeCoordinate($tracking['recipient_longitude'] ?? $snapshot['delivery_longitude'] ?? null);
    $restaurantCoords = fetchRestaurantCoordinates($con, $orderId);
    $recipientCoords = deliveryResolveCoordinatePair(
        $recipientLatitude,
        $recipientLongitude,
        trim(
            (string)($snapshot['delivery_address'] ?? $snapshot['orders_recipient_address_name'] ?? '') .
            ' ' .
            (string)($snapshot['orders_recipient_address_line'] ?? '')
        )
    );
    $payload = [
        'status' => $status,
        'eta_minutes' => $etaMinutes,
        'route_distance_km' => $resolveRouteDistanceKm(
            $driverLatitude,
            $driverLongitude,
            $restaurantCoords['lat'],
            $restaurantCoords['lng'],
            $recipientCoords['lat'],
            $recipientCoords['lng']
        ),
        'last_updated' => gmdate('c'),
        'driver_id' => (string)$driverId,
        'driver' => [
            'id' => (string)$driverId,
            'name' => $driverName,
            'phone' => $driverPhone,
            'vehicle' => trim($vehicleType . ' - ' . $vehicleNumber, ' -'),
            'photo_url' => '',
        ],
        'driver_location' => [
            'lat' => $driverLatitude,
            'lng' => $driverLongitude,
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
        'delivery_proof' => [
            'image_url' => $proofImagePath,
        ],
        'support_phone' => $supportPhone,
        'share_path' => $sharePath,
    ];
    $firebaseUrl = 'https://savirv604-default-rtdb.firebaseio.com/order_tracking/' . rawurlencode((string)$orderId) . '.json';
    $payloadJson = json_encode($payload, JSON_UNESCAPED_UNICODE);
    if ($payloadJson === false) {
        return;
    }
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
    try {
        ensureDeliveryProofColumns($con);
    } catch (Throwable $schemaError) {
        // Keep going if schema upgrades are not allowed.
    }
    $orderStmt = $con->prepare("
        SELECT orders_id, delivery_id, status, proof_image, delivery_code
        FROM orders
        WHERE orders_id = ? LIMIT 1
    ");
    $orderStmt->execute([$orderId]);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
    if (!$order) {
        echo json_encode(["status" => "error", "message" => "Order not found"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $assignedDriverId = (int)($order['delivery_id'] ?? 0);
    if ($assignedDriverId !== $driverId) {
        echo json_encode(["status" => "error", "message" => "Order does not belong to this driver"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $currentStatus = strtolower(trim((string)($order['status'] ?? '')));
    $existingProofImage = trim((string)($order['proof_image'] ?? ''));
    $proofImagePath = null;
    $finalStatus = $currentStatus;
    if ($proofType === 'image') {
        if ($imageBase64 === '') {
            echo json_encode(["status" => "error", "message" => "image_base64 is required"], JSON_UNESCAPED_UNICODE);
            exit;
        }
        if (strpos($imageBase64, 'base64,') !== false) {
            $imageBase64 = substr($imageBase64, strpos($imageBase64, 'base64,') + 7);
        }
        $decodedImage = base64_decode($imageBase64, true);
        if ($decodedImage === false) {
            echo json_encode(["status" => "error", "message" => "Invalid image payload"], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $uploadDir = __DIR__ . '/uploads/proofs/';
        if (!is_dir($uploadDir)) {
            @mkdir($uploadDir, 0775, true);
        }
        $safeName = preg_replace('/[^a-zA-Z0-9._-]+/', '_', $imageName);
        if ($safeName === '') {
            $safeName = 'proof_' . $orderId . '_' . time() . '.jpg';
        }
        $fileName = uniqid('proof_', true) . '_' . $safeName;
        $filePath = $uploadDir . $fileName;
        if (file_put_contents($filePath, $decodedImage) === false) {
            echo json_encode(["status" => "error", "message" => "Failed to save image"], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $proofImagePath = 'uploads/proofs/' . $fileName;
        $finalStatus = 'awaiting_delivery_code';
    } elseif ($proofType !== 'code') {
        echo json_encode(["status" => "error", "message" => "Unsupported proof type"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if ($proofType === 'code' && $proofCode === '') {
        echo json_encode(["status" => "error", "message" => "proof_code is required for code proof"], JSON_UNESCAPED_UNICODE);
        exit;
    }
    if ($proofType === 'code') {
        if ($currentStatus !== 'awaiting_delivery_code' && $currentStatus !== 'awaiting_verification') {
            echo json_encode([
                "status" => "error",
                "message" => "Delivery photo must be uploaded first",
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $expectedCode = trim((string)($order['delivery_code'] ?? ''));
        if ($expectedCode === '' || !preg_match('/^\d{4}$/', $proofCode) || !hash_equals($expectedCode, $proofCode)) {
            echo json_encode([
                "status" => "error",
                "message" => "Invalid delivery verification code",
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        if ($existingProofImage === '') {
            echo json_encode([
                "status" => "error",
                "message" => "Delivery photo is required before confirming the code",
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        $proofImagePath = $existingProofImage;
        $finalStatus = 'delivered';
    }
    $deliveredAtSql = $proofType === 'code' ? 'NOW()' : 'NULL';
    $update = $con->prepare("
        UPDATE orders
        SET status = ?,
            proof_type = ?,
            proof_code = ?,
            proof_image = ?,
            delivered_at = {$deliveredAtSql}
        WHERE orders_id = ? AND delivery_id = ?
    ");
    $update->execute([
        $finalStatus,
        $proofType,
        $proofType === 'code' ? $proofCode : null,
        $proofImagePath,
        $orderId,
        $driverId,
    ]);
    $trackingUpdate = $con->prepare("
        INSERT INTO delivery_order_tracking (
            order_id,
            driver_id,
            status,
            delivery_proof_image_url,
            last_updated
        ) VALUES (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            driver_id = VALUES(driver_id),
            status = VALUES(status),
            delivery_proof_image_url = COALESCE(NULLIF(VALUES(delivery_proof_image_url), ''), delivery_proof_image_url),
            last_updated = NOW()
    ");
    $trackingUpdate->execute([
        $orderId,
        $driverId,
        $finalStatus,
        $proofImagePath,
    ]);
    $refresh = $con->prepare("SELECT * FROM orders WHERE orders_id = ? LIMIT 1");
    $refresh->execute([$orderId]);
    $updatedOrder = $refresh->fetch(PDO::FETCH_ASSOC);
    try {
        pushTrackingSnapshot($con, $orderId, $driverId, $proofImagePath ?? '');
    } catch (Throwable $trackingError) {
        // Keep the delivery success even if the live feed update fails.
    }
    try {
        if ($finalStatus === 'awaiting_delivery_code') {
            notifyUser(
                $con,
                (int)($updatedOrder['orders_usersid'] ?? 0),
                'delivery_update',
                'طلبك بانتظار رمز التحقق',
                'قام السائق بتصوير الطلب. يرجى مشاركة رمز التحقق من 4 أرقام مع السائق لإكمال التسليم.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'awaiting_delivery_code',
                    'proof_image' => $proofImagePath ?? '',
                ],
                true
            );
        } else {
            notifyUser(
                $con,
                (int)($updatedOrder['orders_usersid'] ?? 0),
                'delivery_update',
                'تم تسليم طلبك',
                'تم التحقق من رمز التسليم وتم إكمال الطلب بنجاح.',
                'order',
                $orderId,
                [
                    'order_id' => (string)$orderId,
                    'driver_id' => (string)$driverId,
                    'delivery_status' => 'delivered',
                    'proof_image' => $proofImagePath ?? '',
                ],
                true
            );
        }
        notifyDriver(
            $con,
            $driverId,
            'delivery_update',
            $finalStatus === 'awaiting_delivery_code'
                ? 'تم حفظ إثبات التسليم'
                : 'تم تأكيد التسليم',
            $finalStatus === 'awaiting_delivery_code'
                ? 'تم حفظ إثبات التسليم، والطلب ما زال بانتظار رمز العميل لإتمام الإغلاق النهائي.'
                : 'تم التحقق من إثبات التسليم وإغلاق الطلب بنجاح.',
            'order',
            $orderId,
            [
                'order_id' => (string)$orderId,
                'driver_id' => (string)$driverId,
                'delivery_status' => $finalStatus,
                'proof_image' => $proofImagePath ?? '',
                'proof_type' => $proofType,
            ],
            true
        );
        notifyOrderVendors(
            $con,
            $orderId,
            'delivery_proof',
            $finalStatus === 'awaiting_delivery_code'
                ? 'تم رفع إثبات التسليم'
                : 'تم تأكيد تسليم الطلب',
            $finalStatus === 'awaiting_delivery_code'
                ? 'قام السائق برفع صورة إثبات التسليم للطلب #' . $orderId . ' وفي انتظار رمز العميل.'
                : 'تم تأكيد رمز العميل وإغلاق الطلب #' . $orderId . ' بنجاح.',
            [
                'order_id' => (string)$orderId,
                'driver_id' => (string)$driverId,
                'delivery_status' => $finalStatus,
                'proof_image' => $proofImagePath ?? '',
                'proof_type' => $proofType,
                'screen' => 'delivery_operations',
            ],
            true
        );
    } catch (Throwable $notificationError) {
        // Ignore notification issues here as well.
    }
    unset($updatedOrder['delivery_code']);
    unset($updatedOrder['proof_code']);
    echo json_encode([
        "status" => "success",
        "message" => "Delivery proof saved",
        "order" => $updatedOrder,
        "proof_image" => $proofImagePath,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}