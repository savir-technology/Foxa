<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'drivers.edit');
    if (!tableExists('delivery_zones')) {
        respondJson([
            'status' => 'error',
            'message' => 'جدول مناطق التوصيل غير موجود. طبّق migration 20260818_master_delivery_zones.sql أولًا.',
        ], 409);
    }

    $payload = getRequestPayload();
    $zoneId = (int)($payload['zone_id'] ?? 0);
    $enabled = (int)($payload['enabled'] ?? -1);
    if ($zoneId <= 0 || !in_array($enabled, [0, 1], true)) {
        respondJson([
            'status' => 'error',
            'message' => 'بيانات حالة المنطقة غير صالحة',
        ], 422);
    }

    $exists = $con->prepare('SELECT zone_id FROM delivery_zones WHERE zone_id = :zone_id LIMIT 1');
    $exists->execute([':zone_id' => $zoneId]);
    if (!$exists->fetch(PDO::FETCH_ASSOC)) {
        respondJson(['status' => 'error', 'message' => 'منطقة التوصيل غير موجودة'], 404);
    }

    $stmt = $con->prepare("\n        UPDATE delivery_zones\n        SET is_active = :is_active, updated_by_admin_id = :admin_id\n        WHERE zone_id = :zone_id\n    ");
    $stmt->execute([
        ':is_active' => $enabled,
        ':admin_id' => (int)($admin['admin_id'] ?? 0) ?: null,
        ':zone_id' => $zoneId,
    ]);

    respondJson([
        'status' => 'success',
        'message' => 'تم تحديث حالة منطقة التوصيل',
        'data' => ['zone_id' => $zoneId, 'is_active' => $enabled],
    ]);
} catch (Throwable $e) {
    error_log('master update delivery zone status failed: ' . $e->getMessage());
    respondJson(['status' => 'error', 'message' => 'تعذر تحديث حالة منطقة التوصيل'], 500);
}
