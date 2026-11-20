<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterZoneFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterZoneNullableNumber($value): ?float
{
    if ($value === null || (is_string($value) && trim($value) === '')) {
        return null;
    }

    if (is_numeric($value)) {
        return (float)$value;
    }

    $text = preg_replace('/[^0-9.\-]/', '', (string)$value);
    return is_numeric($text) ? (float)$text : null;
}

function masterZoneRequireSchema(): void
{
    if (!tableExists('delivery_zones')) {
        masterZoneFail(
            'جدول مناطق التوصيل غير موجود. طبّق migration 20260818_master_delivery_zones.sql أولًا.',
            409
        );
    }
}

function masterZoneAudit(string $action, int $zoneId, string $label): void
{
    global $con;
    if (!tableExists('master_audit_logs')) {
        return;
    }

    try {
        $admin = $GLOBALS['masterAuthAdmin'] ?? [];
        $actorName = trim((string)($admin['admin_name'] ?? ''));
        $stmt = $con->prepare("\n            INSERT INTO master_audit_logs (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)\n            VALUES (:actor_name, :action_text, :entity_label, :action_time_label, :tint_hex, NOW())\n        ");
        $stmt->execute([
            ':actor_name' => $actorName !== '' ? $actorName : 'Master',
            ':action_text' => $action,
            ':entity_label' => $label !== '' ? $label : 'Zone #' . $zoneId,
            ':action_time_label' => date('H:i'),
            ':tint_hex' => '#16A34A',
        ]);
    } catch (Throwable $e) {
        error_log('master zone audit failed: ' . $e->getMessage());
    }
}

try {
    $admin = requireMasterAuth();
    if (!masterHasPermission($admin, 'drivers.edit') &&
        !masterHasPermission($admin, 'finance.fees')) {
        requireMasterPermission($admin, 'drivers.edit');
    }
    $GLOBALS['masterAuthAdmin'] = $admin;
    masterZoneRequireSchema();

    $payload = getRequestPayload();
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : $payload;
    $zoneId = (int)($payload['zone_id'] ?? $data['zone_id'] ?? 0);
    $name = trim((string)($data['name'] ?? $data['zone_name'] ?? ''));
    if ($name === '') {
        masterZoneFail('اسم المنطقة مطلوب', 422);
    }

    $hasLatitude = array_key_exists('center_latitude', $data)
        || array_key_exists('store_latitude', $data)
        || array_key_exists('lat', $data);
    $hasLongitude = array_key_exists('center_longitude', $data)
        || array_key_exists('store_longitude', $data)
        || array_key_exists('lng', $data);
    $latitude = masterZoneNullableNumber($data['center_latitude'] ?? $data['store_latitude'] ?? $data['lat'] ?? null);
    $longitude = masterZoneNullableNumber($data['center_longitude'] ?? $data['store_longitude'] ?? $data['lng'] ?? null);
    if ($hasLatitude !== $hasLongitude) {
        masterZoneFail('أدخل إحداثيات المركز كاملة أو اتركها فارغة', 422);
    }
    if (($latitude === null) !== ($longitude === null)) {
        masterZoneFail('أدخل إحداثيات المركز كاملة أو اتركها فارغة', 422);
    }
    if ($latitude !== null && ($latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180)) {
        masterZoneFail('إحداثيات المركز غير صالحة', 422);
    }

    $hasMinMinutes = array_key_exists('estimated_min_minutes', $data);
    $hasMaxMinutes = array_key_exists('estimated_max_minutes', $data);
    $minMinutes = masterZoneNullableNumber($data['estimated_min_minutes'] ?? null);
    $maxMinutes = masterZoneNullableNumber($data['estimated_max_minutes'] ?? null);
    if ($minMinutes !== null && $minMinutes < 0 || $maxMinutes !== null && $maxMinutes < 0) {
        masterZoneFail('وقت التوصيل لا يمكن أن يكون سالبًا', 422);
    }
    if ($minMinutes !== null && $maxMinutes !== null && $maxMinutes < $minMinutes) {
        masterZoneFail('الحد الأقصى لوقت التوصيل يجب أن يكون أكبر من أو يساوي الحد الأدنى', 422);
    }

    $coverageKm = masterZoneNullableNumber($data['coverage_km'] ?? $data['distance'] ?? null);
    $minimumOrder = masterZoneNullableNumber($data['minimum_order'] ?? null);
    $deliveryFee = masterZoneNullableNumber($data['delivery_fee'] ?? $data['fee'] ?? null);
    $pricingMode = strtolower(trim((string)($data['pricing_mode'] ?? '')));
    if ($pricingMode !== '' && !in_array($pricingMode, ['fixed', 'per_km'], true)) {
        masterZoneFail('Pricing mode must be fixed or per_km', 422);
    }
    $baseFee = masterZoneNullableNumber($data['delivery_base_fee'] ?? null);
    $costPerKm = masterZoneNullableNumber($data['delivery_cost_per_km'] ?? null);
    if (($baseFee !== null && $baseFee < 0) || ($costPerKm !== null && $costPerKm < 0)) {
        masterZoneFail('Delivery pricing values cannot be negative', 422);
    }
    if ($coverageKm !== null && $coverageKm <= 0) {
        masterZoneFail('نطاق التغطية يجب أن يكون أكبر من صفر', 422);
    }
    if (($minimumOrder !== null && $minimumOrder < 0) || ($deliveryFee !== null && $deliveryFee < 0)) {
        masterZoneFail('الرسوم والحد الأدنى للطلب لا يمكن أن تكون سالبة', 422);
    }

    if ($pricingMode !== '' || $baseFee !== null || $costPerKm !== null) {
        if (!tableExists('platform_settings') ||
            !columnExists('platform_settings', 'delivery_base_fee') ||
            !columnExists('platform_settings', 'delivery_cost_per_km')) {
            masterZoneFail('Platform delivery pricing schema is not available', 409);
        }
        $settingsBaseFee = $baseFee ?? ($pricingMode === 'per_km' ? 0 : ($deliveryFee ?? 0));
        $settingsCostPerKm = $costPerKm ?? 0;
        if ($pricingMode === 'fixed') {
            $settingsCostPerKm = 0;
        } elseif ($pricingMode === 'per_km') {
            $settingsBaseFee = 0;
        }
        $settings = $con->query('SELECT id FROM platform_settings ORDER BY id ASC LIMIT 1');
        $settingsId = (int)($settings ? ($settings->fetchColumn() ?: 0) : 0);
        if ($settingsId > 0) {
            $updateSettings = $con->prepare('UPDATE platform_settings SET delivery_base_fee = :base_fee, delivery_cost_per_km = :per_km WHERE id = :id');
            $updateSettings->execute([
                ':base_fee' => $settingsBaseFee,
                ':per_km' => $settingsCostPerKm,
                ':id' => $settingsId,
            ]);
        } else {
            $insertSettings = $con->prepare('INSERT INTO platform_settings (delivery_base_fee, delivery_cost_per_km) VALUES (:base_fee, :per_km)');
            $insertSettings->execute([
                ':base_fee' => $settingsBaseFee,
                ':per_km' => $settingsCostPerKm,
            ]);
        }
    }

    $values = [
        'zone_name' => $name,
        'updated_by_admin_id' => (int)($admin['admin_id'] ?? 0) ?: null,
    ];
    if (array_key_exists('city', $data)) {
        $values['city'] = trim((string)$data['city']) ?: null;
    }
    if (array_key_exists('coverage_area', $data)) {
        $values['coverage_area'] = trim((string)$data['coverage_area']) ?: null;
    }
    if (array_key_exists('coverage_km', $data) || array_key_exists('distance', $data)) {
        $values['coverage_km'] = $coverageKm;
    }
    if (array_key_exists('minimum_order', $data)) {
        $values['minimum_order'] = $minimumOrder;
    }
    if (array_key_exists('delivery_fee', $data) || array_key_exists('fee', $data)) {
        $values['delivery_fee'] = $deliveryFee;
    }
    if ($hasMinMinutes) {
        $values['estimated_min_minutes'] = $minMinutes === null ? null : (int)round($minMinutes);
    }
    if ($hasMaxMinutes) {
        $values['estimated_max_minutes'] = $maxMinutes === null ? null : (int)round($maxMinutes);
    }
    if ($hasLatitude && $hasLongitude) {
        $values['center_latitude'] = $latitude;
        $values['center_longitude'] = $longitude;
    }
    if (array_key_exists('is_active', $data) || array_key_exists('is_open', $data)) {
        $values['is_active'] = array_key_exists('is_active', $data)
            ? ((int)$data['is_active'] === 1 ? 1 : 0)
            : ((int)$data['is_open'] === 1 ? 1 : 0);
    }

    if ($zoneId > 0) {
        $exists = $con->prepare('SELECT zone_id FROM delivery_zones WHERE zone_id = :zone_id LIMIT 1');
        $exists->execute([':zone_id' => $zoneId]);
        if (!$exists->fetch(PDO::FETCH_ASSOC)) {
            masterZoneFail('منطقة التوصيل غير موجودة', 404);
        }

        $sets = [];
        $params = [':zone_id' => $zoneId];
        foreach ($values as $column => $value) {
            $sets[] = "{$column} = :{$column}";
            $params[':' . $column] = $value;
        }
        $stmt = $con->prepare('UPDATE delivery_zones SET ' . implode(', ', $sets) . ' WHERE zone_id = :zone_id');
        $stmt->execute($params);
        masterZoneAudit('zone update', $zoneId, $name);
    } else {
        $values['created_by_admin_id'] = (int)($admin['admin_id'] ?? 0) ?: null;
        $columns = array_keys($values);
        $params = [];
        foreach ($values as $column => $value) {
            $params[':' . $column] = $value;
        }
        $stmt = $con->prepare(
            'INSERT INTO delivery_zones (' . implode(', ', $columns) . ') VALUES (:' . implode(', :', $columns) . ')'
        );
        $stmt->execute($params);
        $zoneId = (int)$con->lastInsertId();
        masterZoneAudit('zone create', $zoneId, $name);
    }

    respondJson([
        'status' => 'success',
        'message' => 'تم حفظ منطقة التوصيل',
        'data' => ['zone_id' => $zoneId],
    ]);
} catch (Throwable $e) {
    error_log('master save delivery zone failed: ' . $e->getMessage());
    respondJson(['status' => 'error', 'message' => 'تعذر حفظ منطقة التوصيل'], 500);
}
