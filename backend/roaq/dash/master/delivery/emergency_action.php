<?php
require_once "../../../connect.php";
require_once __DIR__ . "/../../../notifications/notification_helper.php";
header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'drivers.edit');
    $payload = getRequestPayload();
    $reportId = (int)($payload['emergency_report_id'] ?? 0);
    $orderId = (int)($payload['order_id'] ?? 0);
    $driverId = (int)($payload['driver_id'] ?? 0);
    $note = trim((string)($payload['note'] ?? 'Resolved by Master'));
    if ($reportId <= 0 && ($orderId <= 0 || $driverId <= 0)) {
        respondJson(['status' => 'error', 'message' => 'Emergency identifier is required'], 400);
    }
    if (tableExists('delivery_driver_emergency_reports')) {
        foreach ([
            'status' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN status VARCHAR(24) NOT NULL DEFAULT 'active' AFTER reason",
            'resolved_at' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolved_at DATETIME DEFAULT NULL AFTER reported_at",
            'resolved_by' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolved_by INT DEFAULT NULL AFTER resolved_at",
            'resolution_note' => "ALTER TABLE delivery_driver_emergency_reports ADD COLUMN resolution_note VARCHAR(255) DEFAULT NULL AFTER resolved_by",
        ] as $column => $sql) {
            if (!columnExists('delivery_driver_emergency_reports', $column)) $con->exec($sql);
        }
        if ($reportId > 0) {
            $find = $con->prepare('SELECT order_id, driver_id FROM delivery_driver_emergency_reports WHERE emergency_report_id = :id LIMIT 1');
            $find->execute([':id' => $reportId]);
            $row = $find->fetch(PDO::FETCH_ASSOC) ?: [];
            $orderId = (int)($row['order_id'] ?? $orderId);
            $driverId = (int)($row['driver_id'] ?? $driverId);
            $stmt = $con->prepare("UPDATE delivery_driver_emergency_reports SET status='resolved', resolved_at=NOW(), resolved_by=:admin_id, resolution_note=:note WHERE emergency_report_id=:id AND COALESCE(status,'active')='active'");
            $stmt->execute([':admin_id' => (int)$admin['admin_id'], ':note' => $note, ':id' => $reportId]);
        } else {
            $stmt = $con->prepare("UPDATE delivery_driver_emergency_reports SET status='resolved', resolved_at=NOW(), resolved_by=:admin_id, resolution_note=:note WHERE order_id=:order_id AND driver_id=:driver_id AND COALESCE(status,'active')='active'");
            $stmt->execute([':admin_id' => (int)$admin['admin_id'], ':note' => $note, ':order_id' => $orderId, ':driver_id' => $driverId]);
        }
    }
    if ($orderId > 0) {
        $stmt = $con->prepare('UPDATE orders SET driver_emergency_reason=NULL, driver_emergency_at=NULL WHERE orders_id=:order_id AND delivery_id=:driver_id');
        $stmt->execute([':order_id' => $orderId, ':driver_id' => $driverId]);
    }
    if ($driverId > 0 && function_exists('notifyDriver')) {
        try { notifyDriver($con, $driverId, 'driver_emergency_resolved', 'تم إنهاء حالة الطوارئ', 'قام الماستر بإلغاء وضع الطوارئ للسائق.', 'emergency', $orderId, ['order_id' => (string)$orderId, 'driver_id' => (string)$driverId, 'screen' => 'current_order'], true); } catch (Throwable $ignored) {}
    }
    respondJson(['status' => 'success', 'message' => 'Emergency resolved']);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
