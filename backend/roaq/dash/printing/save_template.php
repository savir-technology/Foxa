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
    $name = trim((string)($payload['template_name'] ?? ''));
    if ($name === '') {
        respondJson([
            'status' => 'error',
            'message' => 'Template name is required',
        ], 400);
    }
    $data = [
        ':vendor_id' => $vendorId,
        ':template_name' => $name,
        ':template_type' => trim((string)($payload['template_type'] ?? 'invoice')),
        ':paper_width_mm' => printingIntOrNull($payload['paper_width_mm'] ?? 80) ?? 80,
        ':paper_height_mm' => printingIntOrNull($payload['paper_height_mm'] ?? null),
        ':template_usage' => trim((string)($payload['template_usage'] ?? '')),
    ];
    if ($templateId > 0) {
        $stmt = $con->prepare("
            UPDATE vendor_invoice_templates
            SET
                template_name = :template_name,
                template_type = :template_type,
                paper_width_mm = :paper_width_mm,
                paper_height_mm = :paper_height_mm,
                template_usage = :template_usage,
                is_active = 1
            WHERE template_id = :template_id
              AND vendor_id = :vendor_id
        ");
        $data[':template_id'] = $templateId;
        $stmt->execute($data);
    } else {
        $stmt = $con->prepare("
            INSERT INTO vendor_invoice_templates (
                vendor_id,
                template_name,
                template_type,
                paper_width_mm,
                paper_height_mm,
                template_usage
            ) VALUES (
                :vendor_id,
                :template_name,
                :template_type,
                :paper_width_mm,
                :paper_height_mm,
                :template_usage
            )
        ");
        $stmt->execute($data);
    }
    printingRespondDashboard($con, $vendorId);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}