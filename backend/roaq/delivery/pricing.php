<?php
include "../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

function pricingNumber($value, float $fallback = 0): float
{
    return is_numeric($value) ? max(0, (float)$value) : $fallback;
}

try {
    $payload = getRequestPayload();
    $distanceKm = pricingNumber($payload['distance_km'] ?? 0);

    $baseFee = 10.0;
    $costPerKm = 2.5;
    $maxDistanceKm = 25.0;

    if (tableExists('platform_settings')) {
        $stmt = $con->query("SELECT delivery_base_fee, delivery_cost_per_km, max_delivery_distance_km FROM platform_settings WHERE id = 1 LIMIT 1");
        $settings = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
        $baseFee = pricingNumber($settings['delivery_base_fee'] ?? $baseFee, $baseFee);
        $costPerKm = pricingNumber($settings['delivery_cost_per_km'] ?? $costPerKm, $costPerKm);
        $maxDistanceKm = pricingNumber($settings['max_delivery_distance_km'] ?? $maxDistanceKm, $maxDistanceKm);
    }

    // A zero per-km value means the admin chose a fixed delivery fee.
    $fee = $costPerKm > 0
        ? $baseFee + ($distanceKm * $costPerKm)
        : $baseFee;

    echo json_encode([
        'status' => 'success',
        'data' => [
            'delivery_fee' => round($fee, 2),
            'distance_km' => round($distanceKm, 2),
            'pricing_mode' => $costPerKm > 0 ? 'per_km' : 'fixed',
            'base_fee' => round($baseFee, 2),
            'cost_per_km' => round($costPerKm, 2),
            'max_delivery_distance_km' => round($maxDistanceKm, 2),
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Unable to calculate delivery fee',
    ], JSON_UNESCAPED_UNICODE);
}
