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
requireMasterPermission($admin, 'returns.edit');

$payload = json_decode(file_get_contents('php://input') ?: '{}', true);
$returnId = (int)($payload['return_id'] ?? 0);
$status = trim((string)($payload['status_label'] ?? ''));
$allowedStatuses = ['Awaiting pickup', 'Approved', 'Rejected', 'Review needed', 'Completed'];

if ($returnId <= 0 || !in_array($status, $allowedStatuses, true)) {
    respondJson(['status' => 'error', 'message' => 'Invalid return status payload'], 422);
}

try {
    $exists = $con->prepare(
        'SELECT return_id FROM vendor_return_requests WHERE return_id = :id LIMIT 1'
    );
    $exists->execute([':id' => $returnId]);
    if (!$exists->fetchColumn()) {
        respondJson(['status' => 'error', 'message' => 'Return request was not found'], 404);
    }
    $stmt = $con->prepare(
        'UPDATE vendor_return_requests SET status_label = :status WHERE return_id = :id'
    );
    $stmt->execute([':status' => $status, ':id' => $returnId]);

    if (tableExists('master_audit_logs')) {
        $audit = $con->prepare(
            'INSERT INTO master_audit_logs
             (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
             VALUES (:actor, :action, :entity, :time_label, :tint, NOW())'
        );
        $audit->execute([
            ':actor' => (string)($admin['admin_name'] ?? 'Master'),
            ':action' => 'return status updated to ' . $status,
            ':entity' => 'Return #' . $returnId,
            ':time_label' => date('H:i'),
            ':tint' => '#2563EB',
        ]);
    }

    respondJson(['status' => 'success', 'message' => 'Return status updated']);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
