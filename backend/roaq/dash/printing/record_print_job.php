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
    $printerId = printingIntOrNull($payload['printer_id'] ?? null);
    $templateId = printingIntOrNull($payload['template_id'] ?? null);
    $orderId = printingIntOrNull($payload['order_id'] ?? null);
    $jobType = trim((string)($payload['job_type'] ?? 'invoice'));
    if ($jobType === '') {
        $jobType = 'invoice';
    }
    if ($printerId !== null) {
        $printerStmt = $con->prepare("
            SELECT printer_id
            FROM vendor_printers
            WHERE printer_id = :printer_id
              AND vendor_id = :vendor_id
              AND is_active = 1
            LIMIT 1
        ");
        $printerStmt->execute([
            ':printer_id' => $printerId,
            ':vendor_id' => $vendorId,
        ]);
        if (!$printerStmt->fetchColumn()) {
            respondJson([
                'status' => 'error',
                'message' => 'Printer not found',
            ], 404);
        }
    }
    if ($templateId !== null) {
        $templateStmt = $con->prepare("
            SELECT template_id
            FROM vendor_invoice_templates
            WHERE template_id = :template_id
              AND vendor_id = :vendor_id
              AND is_active = 1
            LIMIT 1
        ");
        $templateStmt->execute([
            ':template_id' => $templateId,
            ':vendor_id' => $vendorId,
        ]);
        if (!$templateStmt->fetchColumn()) {
            respondJson([
                'status' => 'error',
                'message' => 'Template not found',
            ], 404);
        }
    }
    if ($orderId !== null) {
        $orderStmt = $con->prepare("
            SELECT vendor_order_id
            FROM vendor_orders
            WHERE order_id = :order_id
              AND vendor_id = :vendor_id
            LIMIT 1
        ");
        $orderStmt->execute([
            ':order_id' => $orderId,
            ':vendor_id' => $vendorId,
        ]);
        if (!$orderStmt->fetchColumn()) {
            respondJson([
                'status' => 'error',
                'message' => 'Order does not belong to this vendor',
            ], 404);
        }
    }
    $stmt = $con->prepare("
        INSERT INTO vendor_print_jobs (
            vendor_id,
            order_id,
            printer_id,
            template_id,
            job_type,
            job_status,
            job_payload,
            printed_at
        ) VALUES (
            :vendor_id,
            :order_id,
            :printer_id,
            :template_id,
            :job_type,
            'printed',
            :job_payload,
            NOW()
        )
    ");
    $stmt->execute([
        ':vendor_id' => $vendorId,
        ':order_id' => $orderId,
        ':printer_id' => $printerId,
        ':template_id' => $templateId,
        ':job_type' => $jobType,
        ':job_payload' => json_encode($payload['job_payload'] ?? [], JSON_UNESCAPED_UNICODE),
    ]);
    if ($printerId !== null) {
        $updatePrinter = $con->prepare("
            UPDATE vendor_printers
            SET
                is_connected = 1,
                last_print_at = NOW()
            WHERE printer_id = :printer_id
              AND vendor_id = :vendor_id
        ");
        $updatePrinter->execute([
            ':printer_id' => $printerId,
            ':vendor_id' => $vendorId,
        ]);
    }
    printingRespondDashboard($con, $vendorId);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}