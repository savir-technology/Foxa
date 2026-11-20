<?php
include "connect.php";

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

function resolveRouteDistanceKm(?float $driverLat, ?float $driverLng, ?float $restaurantLat, ?float $restaurantLng, ?float $recipientLat, ?float $recipientLng): float
{
    if ($driverLat !== null && $driverLng !== null && $recipientLat !== null && $recipientLng !== null) {
        return distance($driverLat, $driverLng, $recipientLat, $recipientLng);
    }

    if ($restaurantLat !== null && $restaurantLng !== null && $recipientLat !== null && $recipientLng !== null) {
        return distance($restaurantLat, $restaurantLng, $recipientLat, $recipientLng);
    }

    if ($driverLat !== null && $driverLng !== null && $restaurantLat !== null && $restaurantLng !== null) {
        return distance($driverLat, $driverLng, $restaurantLat, $restaurantLng);
    }

    return 0.0;
}

function estimateEtaMinutes(float $routeDistanceKm, int $fallbackMinutes): int
{
    if ($routeDistanceKm > 0) {
        return max(1, (int)ceil(($routeDistanceKm / 25.0) * 60.0));
    }

    return max(1, $fallbackMinutes);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"], JSON_UNESCAPED_UNICODE);
    exit;
}

$data = readRequestData();
$orderId = (int)($data['order_id'] ?? 0);
$driverId = (int)($data['driver_id'] ?? 0);
$status = trim((string)($data['status'] ?? 'pending'));
$etaMinutes = (int)($data['eta_minutes'] ?? 0);
$driverLatitude = normalizeTrackingCoordinate($data['driver_latitude'] ?? null);
$driverLongitude = normalizeTrackingCoordinate($data['driver_longitude'] ?? null);
$restaurantLatitude = normalizeTrackingCoordinate($data['restaurant_latitude'] ?? $data['store_latitude'] ?? null);
$restaurantLongitude = normalizeTrackingCoordinate($data['restaurant_longitude'] ?? $data['store_longitude'] ?? null);
$recipientLatitude = normalizeTrackingCoordinate($data['recipient_latitude'] ?? null);
$recipientLongitude = normalizeTrackingCoordinate($data['recipient_longitude'] ?? null);
$driverName = trim((string)($data['driver_name'] ?? ''));
$driverPhone = trim((string)($data['driver_phone'] ?? ''));
$vehicleType = trim((string)($data['vehicle_type'] ?? ''));
$vehicleNumber = trim((string)($data['vehicle_number'] ?? ''));
$proofImageUrl = trim((string)($data['delivery_proof_image_url'] ?? ''));
$supportPhone = trim((string)($data['support_phone'] ?? ''));
$sharePath = trim((string)($data['share_path'] ?? ''));

if ($orderId <= 0 || $driverId <= 0) {
    echo json_encode(["status" => "error", "message" => "order_id and driver_id are required"], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $orderStmt = $con->prepare("
        SELECT
            o.orders_share_token,
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
            ) AS delivery_address
        FROM orders o
        LEFT JOIN address a ON a.address_id = o.orders_address
        WHERE o.orders_id = ?
        LIMIT 1
    ");
    $orderStmt->execute([$orderId]);
    $orderMeta = $orderStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $resolvedRecipientLatitude = $recipientLatitude;
    $resolvedRecipientLongitude = $recipientLongitude;
    if ($resolvedRecipientLatitude === null) {
        $resolvedRecipientLatitude = normalizeTrackingCoordinate($orderMeta['delivery_latitude'] ?? null);
    }
    if ($resolvedRecipientLongitude === null) {
        $resolvedRecipientLongitude = normalizeTrackingCoordinate($orderMeta['delivery_longitude'] ?? null);
    }

    $routeDistanceKm = resolveRouteDistanceKm(
        $driverLatitude,
        $driverLongitude,
        $restaurantLatitude,
        $restaurantLongitude,
        $resolvedRecipientLatitude,
        $resolvedRecipientLongitude
    );
    $resolvedEtaMinutes = estimateEtaMinutes(
        $routeDistanceKm,
        $etaMinutes > 0 ? $etaMinutes : (int)($orderMeta['orders_estimated_minutes'] ?? 0)
    );

    $stmt = $con->prepare("
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
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
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
            delivery_proof_image_url = COALESCE(NULLIF(VALUES(delivery_proof_image_url), ''), delivery_proof_image_url),
            support_phone = VALUES(support_phone),
            share_path = VALUES(share_path),
            route_distance_km = VALUES(route_distance_km),
            last_updated = NOW()
    ");
    $stmt->execute([
        $orderId,
        $driverId,
        $status,
        $resolvedEtaMinutes,
        $driverLatitude,
        $driverLongitude,
        $resolvedRecipientLatitude,
        $resolvedRecipientLongitude,
        $driverName,
        $driverPhone,
        $vehicleType,
        $vehicleNumber,
        $proofImageUrl,
        $supportPhone,
        $sharePath,
        $routeDistanceKm,
    ]);

    $firebaseUrl = 'https://savirv604-default-rtdb.firebaseio.com/order_tracking/' . rawurlencode((string)$orderId) . '.json';
    $resolvedSharePath = $sharePath;
    if ($resolvedSharePath === '' && !empty($orderMeta['orders_share_token'])) {
        $resolvedSharePath = '/track.php?token=' . urlencode(trim((string)$orderMeta['orders_share_token']));
    }

    $payload = [
        'status' => $status,
        'eta_minutes' => $resolvedEtaMinutes,
        'route_distance_km' => $routeDistanceKm,
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
            'lat' => $restaurantLatitude,
            'lng' => $restaurantLongitude,
        ],
        'recipient_location' => [
            'lat' => $resolvedRecipientLatitude,
            'lng' => $resolvedRecipientLongitude,
        ],
        'delivery_location' => [
            'lat' => $resolvedRecipientLatitude,
            'lng' => $resolvedRecipientLongitude,
        ],
        'delivery_address' => trim((string)($orderMeta['delivery_address'] ?? '')),
        'order_mode' => $orderMeta['order_mode'] ?? 'asap',
        'scheduled_for' => $orderMeta['scheduled_for'] ?? null,
        'delivery_proof' => [
            'image_url' => $proofImageUrl,
        ],
        'support_phone' => $supportPhone,
        'share_path' => $resolvedSharePath,
    ];

    $payloadJson = json_encode($payload, JSON_UNESCAPED_UNICODE);
    if ($payloadJson !== false) {
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
        } else {
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
    }

    echo json_encode([
        "status" => "success",
        "message" => "Tracking feed updated",
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
