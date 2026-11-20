<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");

function readRequestData(): array
{
    if (!empty($_POST)) {
        return $_POST;
    }

    $raw = trim((string)file_get_contents('php://input'));
    if ($raw === '') {
        return [];
    }

    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        return $decoded;
    }

    parse_str($raw, $parsed);
    return is_array($parsed) ? $parsed : [];
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "failed", "message" => "يجب استخدام طلب POST"], JSON_UNESCAPED_UNICODE);
    exit();
}

$data = readRequestData();
$driver_id = (int)($data['driver_id'] ?? 0);
$latitude = trim((string)($data['latitude'] ?? ''));
$longitude = trim((string)($data['longitude'] ?? ''));

if ($driver_id <= 0 || $latitude === '' || $longitude === '') {
    echo json_encode(["status" => "failed", "message" => "جميع الحقول مطلوبة"], JSON_UNESCAPED_UNICODE);
    exit();
}

if (!is_numeric($latitude) || !is_numeric($longitude)) {
    echo json_encode(["status" => "failed", "message" => "إحداثيات غير صالحة"], JSON_UNESCAPED_UNICODE);
    exit();
}

if (function_exists('driverColumnExists') && driverColumnExists('delivery_users', 'approval_status')) {
    $approvalStmt = $con->prepare("SELECT approval_status FROM delivery_users WHERE id = ? LIMIT 1");
    $approvalStmt->execute([$driver_id]);
    $approvalStatus = strtolower(trim((string)$approvalStmt->fetchColumn()));
    if ($approvalStatus !== 'approved') {
        echo json_encode([
            "status" => "failed",
            "message" => "Driver account is pending approval",
            "approval_status" => $approvalStatus !== '' ? $approvalStatus : 'pending',
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
}

$stmt = $con->prepare("
    UPDATE delivery_users
    SET latitude = ?,
        longitude = ?,
        last_seen_at = NOW(),
        status = 'online'
    WHERE id = ?
");
$result = $stmt->execute([(float)$latitude, (float)$longitude, $driver_id]);

if ($result) {
    echo json_encode(["status" => "success", "message" => "تم تحديث الموقع بنجاح"], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode(["status" => "failed", "message" => "فشل في تحديث الموقع"], JSON_UNESCAPED_UNICODE);
}
?>
