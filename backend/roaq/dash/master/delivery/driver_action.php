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

function masterDriverActionFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterDriverAudit(string $action, int $driverId, string $label = ''): void
{
    global $con;
    if (!tableExists('master_audit_logs')) {
        return;
    }
    try {
        $admin = $GLOBALS['masterAuthAdmin'] ?? [];
        $actorName = trim((string)($admin['admin_name'] ?? 'Master'));
        $stmt = $con->prepare("
            INSERT INTO master_audit_logs (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
            VALUES (:actor_name, :action_text, :entity_label, :action_time_label, :tint_hex, NOW())
        ");
        $stmt->execute([
            ':actor_name' => $actorName !== '' ? $actorName : 'Master',
            ':action_text' => 'driver ' . $action,
            ':entity_label' => trim($label) !== '' ? $label : 'Driver #' . $driverId,
            ':action_time_label' => date('H:i'),
            ':tint_hex' => in_array($action, ['save', 'activate'], true) ? '#16A34A' : '#DC2626',
        ]);
    } catch (Throwable $e) {
        error_log('master driver audit failed: ' . $e->getMessage());
    }
}

function masterDriverWritableData(array $data): array
{
    $map = [
        'name' => trim((string)($data['name'] ?? '')),
        'phone' => trim((string)($data['phone'] ?? '')),
        'vehicle_type' => trim((string)($data['vehicle_type'] ?? '')),
        'vehicle_number' => trim((string)($data['vehicle_number'] ?? '')),
        'status' => trim((string)($data['status'] ?? 'offline')),
        'vendor_id' => max(0, (int)($data['vendor_id'] ?? 0)),
    ];
    if ($map['status'] === '') {
        $map['status'] = 'offline';
    }
    return $map;
}

try {
    $admin = requireMasterAuth();
    $GLOBALS['masterAuthAdmin'] = $admin;

    if (!tableExists('delivery_users')) {
        masterDriverActionFail('delivery_users table is not available', 404);
    }

    $payload = getRequestPayload();
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $id = (int)($payload['id'] ?? $payload['driver_id'] ?? 0);
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];

    if ($action === '') {
        masterDriverActionFail('Driver action is required');
    }

    if ($action === 'activate' || $action === 'approve' || $action === 'reject') {
        if ($action === 'approve' || $action === 'reject') {
            requireMasterPermission($admin, 'drivers.approve');
            if ($id <= 0) masterDriverActionFail('driver_id is required');
            if (!columnExists('delivery_users', 'approval_status')) masterDriverActionFail('approval_status column is missing', 500);
            $approval = $action === 'approve' ? 'approved' : 'rejected';
            $note = trim((string)($data['note'] ?? ''));
            $stmt = $con->prepare('UPDATE delivery_users SET approval_status = :approval, approval_note = :note WHERE id = :id');
            $stmt->execute([':approval' => $approval, ':note' => $note !== '' ? $note : null, ':id' => $id]);
            masterDriverAudit($action, $id);
            respondJson(['status' => 'success', 'message' => 'driver approval updated']);
        }
        requireMasterPermission($admin, 'drivers.approve');
    } elseif ($action === 'disable') {
        requireMasterPermission($admin, 'drivers.suspend');
    } else {
        requireMasterPermission($admin, 'drivers.edit');
    }

    if ($action === 'activate' || $action === 'disable') {
        if ($id <= 0) {
            masterDriverActionFail('driver_id is required');
        }
        $status = $action === 'activate' ? 'online' : 'offline';
        $sets = [];
        $params = [':id' => $id];
        if (columnExists('delivery_users', 'status')) {
            $sets[] = 'status = :status';
            $params[':status'] = $status;
        }
        if (columnExists('delivery_users', 'last_seen_at') && $action === 'activate') {
            $sets[] = 'last_seen_at = NOW()';
        }
        if (empty($sets)) {
            masterDriverActionFail('No writable driver status column was found', 500);
        }
        $stmt = $con->prepare('UPDATE delivery_users SET ' . implode(', ', $sets) . ' WHERE id = :id');
        $stmt->execute($params);
        masterDriverAudit($action, $id);
        respondJson(['status' => 'success', 'message' => 'driver updated']);
    }

    if ($action !== 'save') {
        masterDriverActionFail('Unsupported driver action');
    }

    $writable = masterDriverWritableData($data);
    if ($writable['name'] === '' || $writable['phone'] === '') {
        masterDriverActionFail('Driver name and phone are required');
    }

    if ($writable['vendor_id'] > 0) {
        $vendorStmt = $con->prepare("
            SELECT vendor_id
            FROM vendors
            WHERE vendor_id = :vendor_id
              AND vendor_status = 'active'
              AND vendor_is_verified = 1
              AND (vendor_approval_status = 'approved' OR vendor_approval_status IS NULL)
            LIMIT 1
        ");
        $vendorStmt->execute([':vendor_id' => $writable['vendor_id']]);
        if (!$vendorStmt->fetchColumn()) {
            masterDriverActionFail('Only an approved active restaurant can be linked to a driver');
        }
    }

    $columns = [];
    $params = [];
    foreach ($writable as $column => $value) {
        if (columnExists('delivery_users', $column)) {
            $columns[$column] = $value;
            $params[':' . $column] = $value;
        }
    }
    if (empty($columns)) {
        masterDriverActionFail('No writable driver columns were found', 500);
    }

    if ($id > 0) {
        $sets = [];
        foreach (array_keys($columns) as $column) {
            $sets[] = "{$column} = :{$column}";
        }
        $params[':id'] = $id;
        $stmt = $con->prepare('UPDATE delivery_users SET ' . implode(', ', $sets) . ' WHERE id = :id');
        $stmt->execute($params);
    } else {
        $columnNames = array_keys($columns);
        $stmt = $con->prepare(
            'INSERT INTO delivery_users (' . implode(', ', $columnNames) . ') VALUES (:' . implode(', :', $columnNames) . ')'
        );
        $stmt->execute($params);
        $id = (int)$con->lastInsertId();
    }

    masterDriverAudit('save', $id, $writable['name']);
    respondJson([
        'status' => 'success',
        'message' => 'driver saved',
        'data' => ['driver_id' => $id],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
