<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterBranchesRespond(array $payload, int $status = 200): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $admin = requireMasterAuth();
    $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    requireMasterPermission($admin, $method === 'POST' ? 'restaurants.edit' : 'restaurants.view');

    if (!tableExists('restaurant_branches') || !tableExists('restaurant_hours')) {
        masterBranchesRespond(['status' => 'error', 'message' => 'Branches or hours tables are unavailable'], 409);
    }

    if ($method === 'GET') {
        $vendorType = strtolower(trim((string)($_GET['vendor_type'] ?? '')));
        if (!in_array($vendorType, ['restaurant', 'store'], true)) {
            $vendorType = '';
        }
        $where = $vendorType !== ''
            ? "WHERE LOWER(COALESCE(v.vendor_type, 'restaurant')) = " . $con->quote($vendorType)
            : '';
        $branchesStmt = $con->query("SELECT b.*, v.store_name, v.vendor_name, v.vendor_type
            FROM restaurant_branches b
            INNER JOIN vendors v ON v.vendor_id = b.vendor_id
            {$where}
            ORDER BY b.vendor_id, b.branch_id DESC");
        $hoursStmt = $con->query("SELECT h.*, v.store_name, v.vendor_name, v.vendor_type
            FROM restaurant_hours h
            INNER JOIN vendors v ON v.vendor_id = h.vendor_id
            {$where}
            ORDER BY h.vendor_id, h.day_key, h.hour_id DESC");
        masterBranchesRespond([
            'status' => 'success',
            'data' => [
                'branches' => $branchesStmt ? ($branchesStmt->fetchAll(PDO::FETCH_ASSOC) ?: []) : [],
                'hours' => $hoursStmt ? ($hoursStmt->fetchAll(PDO::FETCH_ASSOC) ?: []) : [],
            ],
        ]);
    }

    $payload = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $action = strtolower(trim((string)($payload['action'] ?? 'save_branch')));
    $vendorId = (int)($payload['vendor_id'] ?? 0);
    if ($vendorId <= 0) {
        masterBranchesRespond(['status' => 'error', 'message' => 'Missing vendor_id'], 400);
    }
    $vendorStmt = $con->prepare('SELECT vendor_id FROM vendors WHERE vendor_id = :vendor_id LIMIT 1');
    $vendorStmt->execute([':vendor_id' => $vendorId]);
    if (!$vendorStmt->fetchColumn()) {
        masterBranchesRespond(['status' => 'error', 'message' => 'Vendor not found'], 404);
    }

    if ($action === 'save_hour') {
        $hourId = (int)($payload['hour_id'] ?? 0);
        $data = [
            ':vendor_id' => $vendorId,
            ':day_key' => trim((string)($payload['day_key'] ?? '')),
            ':opens_at' => trim((string)($payload['opens_at'] ?? '')) ?: null,
            ':closes_at' => trim((string)($payload['closes_at'] ?? '')) ?: null,
            ':is_open' => !empty($payload['is_open']) ? 1 : 0,
            ':is_active' => array_key_exists('is_active', $payload) ? (!empty($payload['is_active']) ? 1 : 0) : 1,
        ];
        if ($data[':day_key'] === '') {
            masterBranchesRespond(['status' => 'error', 'message' => 'Missing day_key'], 400);
        }
        if ($hourId > 0) {
            $stmt = $con->prepare('UPDATE restaurant_hours SET day_key=:day_key, opens_at=:opens_at, closes_at=:closes_at, is_open=:is_open, is_active=:is_active WHERE hour_id=:hour_id AND vendor_id=:vendor_id');
            $data[':hour_id'] = $hourId;
        } else {
            $stmt = $con->prepare('INSERT INTO restaurant_hours (vendor_id, day_key, opens_at, closes_at, is_open, is_active) VALUES (:vendor_id, :day_key, :opens_at, :closes_at, :is_open, :is_active)');
        }
        $stmt->execute($data);
        masterBranchesRespond(['status' => 'success', 'id' => $hourId > 0 ? $hourId : (int)$con->lastInsertId()]);
    }

    $branchId = (int)($payload['branch_id'] ?? 0);
    $branchData = [
        ':vendor_id' => $vendorId,
        ':branch_name_ar' => trim((string)($payload['branch_name_ar'] ?? '')),
        ':branch_name_en' => trim((string)($payload['branch_name_en'] ?? '')),
        ':latitude' => ($payload['latitude'] ?? null) !== null && ($payload['latitude'] ?? '') !== '' ? (float)$payload['latitude'] : null,
        ':longitude' => ($payload['longitude'] ?? null) !== null && ($payload['longitude'] ?? '') !== '' ? (float)$payload['longitude'] : null,
        ':delivery_fee' => (float)($payload['delivery_fee'] ?? 0),
        ':estimated_min_minutes' => (int)($payload['estimated_min_minutes'] ?? 25),
        ':estimated_max_minutes' => (int)($payload['estimated_max_minutes'] ?? 45),
        ':is_active' => array_key_exists('is_active', $payload) ? (!empty($payload['is_active']) ? 1 : 0) : 1,
    ];
    if ($branchId > 0) {
        $stmt = $con->prepare('UPDATE restaurant_branches SET branch_name_ar=:branch_name_ar, branch_name_en=:branch_name_en, latitude=:latitude, longitude=:longitude, delivery_fee=:delivery_fee, estimated_min_minutes=:estimated_min_minutes, estimated_max_minutes=:estimated_max_minutes, is_active=:is_active WHERE branch_id=:branch_id AND vendor_id=:vendor_id');
        $branchData[':branch_id'] = $branchId;
    } else {
        $stmt = $con->prepare('INSERT INTO restaurant_branches (vendor_id, branch_name_ar, branch_name_en, latitude, longitude, delivery_fee, estimated_min_minutes, estimated_max_minutes, is_active) VALUES (:vendor_id, :branch_name_ar, :branch_name_en, :latitude, :longitude, :delivery_fee, :estimated_min_minutes, :estimated_max_minutes, :is_active)');
    }
    $stmt->execute($branchData);
    masterBranchesRespond(['status' => 'success', 'id' => $branchId > 0 ? $branchId : (int)$con->lastInsertId()]);
} catch (Throwable $e) {
    masterBranchesRespond(['status' => 'error', 'message' => $e->getMessage()], 500);
}
