<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

requireDashboardActor(['vendor', 'master']);

function normalizeCoordinateValue($value): ?float
{
    if ($value === null) {
        return null;
    }

    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }

    $number = (float)$text;
    return is_finite($number) ? $number : null;
}

function normalizeDistanceValue($value): ?float
{
    if ($value === null) {
        return null;
    }

    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }

    $number = (float)$text;
    if (!is_finite($number) || $number <= 0) {
        return null;
    }

    return $number;
}

function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
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

function hasCoordinatePair(?float $lat, ?float $lng): bool
{
    return $lat !== null && $lng !== null && ($lat != 0.0 || $lng != 0.0);
}

$vendorId = (int)($_GET['vendor_id'] ?? 0);
$restaurantLatitude = normalizeCoordinateValue($_GET['restaurant_latitude'] ?? $_GET['store_latitude'] ?? null);
$restaurantLongitude = normalizeCoordinateValue($_GET['restaurant_longitude'] ?? $_GET['store_longitude'] ?? null);
$onlyAvailable = filter_var($_GET['only_available'] ?? true, FILTER_VALIDATE_BOOLEAN);
$maxDistanceKm = normalizeDistanceValue($_GET['max_distance_km'] ?? null);

if (!hasCoordinatePair($restaurantLatitude, $restaurantLongitude) && $vendorId > 0) {
    $stmt = $con->prepare("
        SELECT store_latitude, store_longitude
        FROM vendor_store_settings
        WHERE vendor_id = ?
        LIMIT 1
    ");
    $stmt->execute([$vendorId]);
    $store = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $restaurantLatitude = normalizeCoordinateValue($store['store_latitude'] ?? null);
    $restaurantLongitude = normalizeCoordinateValue($store['store_longitude'] ?? null);
}

try {
    $sql = "
        SELECT
            du.id,
            du.name,
            du.phone,
            du.email,
            du.vehicle_type,
            du.vehicle_number,
            CASE
                WHEN du.status = 'online'
                     OR (du.last_seen_at IS NOT NULL AND du.last_seen_at >= (NOW() - INTERVAL 5 MINUTE))
                THEN 'online'
                ELSE du.status
            END AS status,
            du.latitude,
            du.longitude,
            du.last_seen_at,
            du.created_at,
            0 AS vendor_id,
            COALESCE(active.active_orders_count, 0) AS active_orders_count,
            CASE
                WHEN (
                    du.status = 'online'
                    OR (du.last_seen_at IS NOT NULL AND du.last_seen_at >= (NOW() - INTERVAL 5 MINUTE))
                ) AND COALESCE(active.active_orders_count, 0) = 0
                THEN 1
                ELSE 0
            END AS is_available
        FROM delivery_users du
        LEFT JOIN (
            SELECT
                delivery_id,
                COUNT(*) AS active_orders_count
            FROM orders
            WHERE delivery_id IS NOT NULL
              AND delivery_id > 0
              AND COALESCE(status, '') NOT IN ('delivered', 'completed', 'canceled', 'cancelled')
            GROUP BY delivery_id
        ) active ON active.delivery_id = du.id
        WHERE (
            du.status = 'online'
            OR (du.last_seen_at IS NOT NULL AND du.last_seen_at >= (NOW() - INTERVAL 5 MINUTE))
        )
        ORDER BY is_available DESC, du.last_seen_at DESC, du.name ASC
    ";

    $stmt = $con->prepare($sql);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $drivers = array_values($rows);

    if (hasCoordinatePair($restaurantLatitude, $restaurantLongitude)) {
        foreach ($drivers as &$driver) {
            $driverLat = normalizeCoordinateValue($driver['latitude'] ?? null);
            $driverLng = normalizeCoordinateValue($driver['longitude'] ?? null);
            $driver['distance_km'] = hasCoordinatePair($driverLat, $driverLng)
                ? round(haversineKm($restaurantLatitude, $restaurantLongitude, $driverLat, $driverLng), 2)
                : null;
        }
        unset($driver);

        usort($drivers, static function (array $a, array $b): int {
            $aDistance = isset($a['distance_km']) && $a['distance_km'] !== null
                ? (float)$a['distance_km']
                : PHP_FLOAT_MAX;
            $bDistance = isset($b['distance_km']) && $b['distance_km'] !== null
                ? (float)$b['distance_km']
                : PHP_FLOAT_MAX;

            if ($aDistance === $bDistance) {
                return strcmp((string)($a['name'] ?? ''), (string)($b['name'] ?? ''));
            }

            return $aDistance <=> $bDistance;
        });
    } else {
        foreach ($drivers as &$driver) {
            $driver['distance_km'] = null;
        }
        unset($driver);
    }

    if ($onlyAvailable) {
        $drivers = array_values(array_filter(
            $drivers,
            static fn(array $driver): bool => (int)($driver['is_available'] ?? 0) === 1
        ));
    }

    if ($maxDistanceKm !== null) {
        $drivers = array_values(array_filter(
            $drivers,
            static function (array $driver) use ($maxDistanceKm): bool {
                if (!isset($driver['distance_km']) || $driver['distance_km'] === null) {
                    return false;
                }

                return (float)$driver['distance_km'] <= $maxDistanceKm;
            }
        ));
    }

    echo json_encode([
        "status" => "success",
        "data" => $drivers,
        "total" => count($drivers),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
