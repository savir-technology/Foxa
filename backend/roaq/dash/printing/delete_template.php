<?php
include "../../connect.php";
require_once __DIR__ . "/printing_helpers.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
try {
    $payload = getRequestPayload();
    $vendorId = printingResolveVendorId($payload);
    if ($vendorId <= 0) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid vendor session',
        ], 401);
    }
    $templateId = (int)($payload['template_id'] ?? 0);
    if ($templateId <= 0) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid template id',
        ], 400);
    }
    $stmt = $con->prepare("
        UPDATE vendor_invoice_templates
        SET is_active = 0
        WHERE template_id = :template_id
          AND vendor_id = :vendor_id
    ");
    $stmt->execute([
        ':template_id' => $templateId,
        ':vendor_id' => $vendorId,
    ]);
    printingRespondDashboard($con, $vendorId);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}