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

$actor = requireDashboardActor(['master']);
$admin = $actor['master'] ?? [];
$payload = getRequestPayload();

$vendorId = intval($payload['vendor_id'] ?? 0);
$action = $payload['action'] ?? ''; // approve | reject | request_info
$note = $payload['note'] ?? '';

if ($vendorId <= 0 || !in_array($action, ['approve', 'reject', 'request_info'])) {
    respondJson(['status' => 'error', 'message' => 'Invalid request'], 400);
}

if ($action === 'approve') {
    requireMasterPermission($admin, 'restaurants.approve');
} elseif ($action === 'reject') {
    requireMasterPermission($admin, 'restaurants.reject');
} else {
    requireMasterPermission($admin, 'restaurants.edit');
}

try {
    $con->beginTransaction();

    if ($action === 'approve') {
        $stmt = $con->prepare("
            UPDATE vendors 
            SET vendor_approval_status = 'approved',
                vendor_status = 'active',
                vendor_is_verified = 1,
                vendor_approval_note = :note
            WHERE vendor_id = :vendor_id
        ");
    } elseif ($action === 'reject') {
        $stmt = $con->prepare("
            UPDATE vendors 
            SET vendor_approval_status = 'rejected',
                vendor_status = 'inactive',
                vendor_is_verified = 0,
                vendor_approval_note = :note
            WHERE vendor_id = :vendor_id
        ");
    } else {
        $stmt = $con->prepare("
            UPDATE vendors 
            SET vendor_approval_status = 'more_info',
                vendor_approval_note = :note
            WHERE vendor_id = :vendor_id
        ");
    }

    $stmt->execute([
        ':vendor_id' => $vendorId,
        ':note' => $note,
    ]);

    // إنشاء إعدادات المطعم إذا ما كانت موجودة
    if ($action === 'approve') {
        $checkStmt = $con->prepare("SELECT COUNT(*) FROM vendor_store_settings WHERE vendor_id = :vendor_id");
        $checkStmt->execute([':vendor_id' => $vendorId]);
        if ((int)$checkStmt->fetchColumn() === 0) {
            $insertStmt = $con->prepare("
                INSERT INTO vendor_store_settings (vendor_id, currency_code, currency_symbol, currency_name)
                VALUES (:vendor_id, 'SAR', 'ر.س', 'الريال السعودي')
            ");
            $insertStmt->execute([':vendor_id' => $vendorId]);
        }
    }

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'message' => $action === 'approve' ? 'تم الموافقة على المطعم بنجاح' : 
                     ($action === 'reject' ? 'تم رفض المطعم' : 'تم طلب معلومات إضافية'),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    if ($con->inTransaction()) $con->rollBack();
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
