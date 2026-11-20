<?php
include "../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    ensurePlatformSettingsSchema();
    $stmt = $con->query(
        'SELECT default_currency_code, default_currency_symbol,
                default_currency_name, default_currency_name_en,
                delivery_base_fee, delivery_cost_per_km,
                max_delivery_distance_km, support_phone, support_email
                , platform_timezone
         FROM platform_settings WHERE id = 1 LIMIT 1'
    );
    $settings = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];

    echo json_encode([
        'status' => 'success',
        'data' => $settings,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Unable to load platform settings',
    ], JSON_UNESCAPED_UNICODE);
}
