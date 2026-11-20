<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$admin = requireMasterAuth();
requireMasterPermission($admin, 'restaurants.edit');
$payload = json_decode(file_get_contents('php://input') ?: '{}', true);
$ruleId = (int)($payload['rule_id'] ?? 0);
$active = !empty($payload['is_active']) ? 1 : 0;

if ($ruleId <= 0) {
    respondJson(['status' => 'error', 'message' => 'Invalid stock rule payload'], 422);
}

try {
    $exists = $con->prepare(
        'SELECT rule_id FROM vendor_item_stock_rules WHERE rule_id = :id LIMIT 1'
    );
    $exists->execute([':id' => $ruleId]);
    if (!$exists->fetchColumn()) {
        respondJson(['status' => 'error', 'message' => 'Stock rule was not found'], 404);
    }
    $stmt = $con->prepare(
        'UPDATE vendor_item_stock_rules SET is_active = :active WHERE rule_id = :id'
    );
    $stmt->execute([':active' => $active, ':id' => $ruleId]);
    if (tableExists('master_audit_logs')) {
        $audit = $con->prepare(
            'INSERT INTO master_audit_logs
             (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
             VALUES (:actor, :action, :entity, :time_label, :tint, NOW())'
        );
        $audit->execute([
            ':actor' => (string)($admin['admin_name'] ?? 'Master'),
            ':action' => 'stock rule toggled',
            ':entity' => 'Stock rule #' . $ruleId,
            ':time_label' => date('H:i'),
            ':tint' => '#2563EB',
        ]);
    }
    respondJson(['status' => 'success', 'message' => 'Stock rule updated']);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
