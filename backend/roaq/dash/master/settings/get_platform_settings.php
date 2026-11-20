<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Pragma: no-cache");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireMasterAuth();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    requireMasterPermission($actor, 'settings.view');
    ensurePlatformSettingsSchema();
    try {
        $stmt = $con->prepare("SELECT * FROM platform_settings WHERE id = 1 LIMIT 1");
        $stmt->execute();
        $settings = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$settings) {
            $settings = [
                'id' => 1,
                'default_currency_code' => 'SAR',
                'default_currency_symbol' => 'ر.س',
                'default_currency_name' => 'الريال السعودي',
                'default_currency_name_en' => 'Saudi Riyal',
                'platform_commission_percent' => 15.00,
                'delivery_base_fee' => 10.00,
                'delivery_cost_per_km' => 2.50,
                'max_delivery_distance_km' => 25.00,
                'min_vendor_payout' => 500.00,
                'support_phone' => '',
                'support_email' => '',
                'platform_name_ar' => 'منصة سفير',
                'platform_name_en' => 'Savir Platform',
                'platform_timezone' => 'Africa/Cairo',
            ];
        }

        echo json_encode([
            'status' => 'success',
            'data' => $settings,
        ], JSON_UNESCAPED_UNICODE);
    } catch (Throwable $e) {
        echo json_encode([
            'status' => 'error',
            'message' => $e->getMessage(),
        ], JSON_UNESCAPED_UNICODE);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireMasterPermission($actor, 'settings.edit');
    ensurePlatformSettingsSchema();
    $payload = getRequestPayload();

    try {
        $stmt = $con->prepare("
            INSERT INTO platform_settings (
                id,
                default_currency_code,
                default_currency_symbol,
                default_currency_name,
                default_currency_name_en,
                platform_commission_percent,
                delivery_base_fee,
                delivery_cost_per_km,
                max_delivery_distance_km,
                min_vendor_payout,
                support_phone,
                support_email,
                platform_name_ar,
                platform_name_en,
                platform_timezone
            ) VALUES (
                1,
                :default_currency_code,
                :default_currency_symbol,
                :default_currency_name,
                :default_currency_name_en,
                :platform_commission_percent,
                :delivery_base_fee,
                :delivery_cost_per_km,
                :max_delivery_distance_km,
                :min_vendor_payout,
                :support_phone,
                :support_email,
                :platform_name_ar,
                :platform_name_en,
                :platform_timezone
            ) ON DUPLICATE KEY UPDATE
                default_currency_code = VALUES(default_currency_code),
                default_currency_symbol = VALUES(default_currency_symbol),
                default_currency_name = VALUES(default_currency_name),
                default_currency_name_en = VALUES(default_currency_name_en),
                platform_commission_percent = VALUES(platform_commission_percent),
                delivery_base_fee = VALUES(delivery_base_fee),
                delivery_cost_per_km = VALUES(delivery_cost_per_km),
                max_delivery_distance_km = VALUES(max_delivery_distance_km),
                min_vendor_payout = VALUES(min_vendor_payout),
                support_phone = VALUES(support_phone),
                support_email = VALUES(support_email),
                platform_name_ar = VALUES(platform_name_ar),
                platform_name_en = VALUES(platform_name_en),
                platform_timezone = VALUES(platform_timezone)
        ");

        $stmt->execute([
            ':default_currency_code' => $payload['default_currency_code'] ?? 'SAR',
            ':default_currency_symbol' => $payload['default_currency_symbol'] ?? 'ر.س',
            ':default_currency_name' => $payload['default_currency_name'] ?? 'الريال السعودي',
            ':default_currency_name_en' => $payload['default_currency_name_en'] ?? 'Saudi Riyal',
            ':platform_commission_percent' => floatval($payload['platform_commission_percent'] ?? 15),
            ':delivery_base_fee' => floatval($payload['delivery_base_fee'] ?? 10),
            ':delivery_cost_per_km' => floatval($payload['delivery_cost_per_km'] ?? 2.5),
            ':max_delivery_distance_km' => floatval($payload['max_delivery_distance_km'] ?? 25),
            ':min_vendor_payout' => floatval($payload['min_vendor_payout'] ?? 500),
            ':support_phone' => $payload['support_phone'] ?? '',
            ':support_email' => $payload['support_email'] ?? '',
            ':platform_name_ar' => $payload['platform_name_ar'] ?? 'منصة سفير',
            ':platform_name_en' => $payload['platform_name_en'] ?? 'Savir Platform',
            ':platform_timezone' => in_array(
                trim((string)($payload['platform_timezone'] ?? 'Africa/Cairo')),
                DateTimeZone::listIdentifiers(),
                true
            ) ? trim((string)$payload['platform_timezone']) : 'Africa/Cairo',
        ]);

        echo json_encode([
            'status' => 'success',
            'message' => 'تم حفظ إعدادات المنصة بنجاح',
        ], JSON_UNESCAPED_UNICODE);
    } catch (Throwable $e) {
        echo json_encode([
            'status' => 'error',
            'message' => $e->getMessage(),
        ], JSON_UNESCAPED_UNICODE);
    }
}
