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
    $printerId = (int)($payload['printer_id'] ?? 0);
    $name = trim((string)($payload['printer_name'] ?? ''));
    if ($name === '') {
        respondJson([
            'status' => 'error',
            'message' => 'Printer name is required',
        ], 400);
    }
    $data = [
        ':vendor_id' => $vendorId,
        ':printer_name' => $name,
        ':printer_model' => trim((string)($payload['printer_model'] ?? '')),
        ':printer_type' => trim((string)($payload['printer_type'] ?? 'invoice')),
        ':printer_location' => trim((string)($payload['printer_location'] ?? '')),
        ':printer_sections_json' => printingNormalizeSections($payload['printer_sections'] ?? $payload['printer_sections_json'] ?? []),
        ':printer_ip' => trim((string)($payload['printer_ip'] ?? '')),
        ':printer_port' => printingIntOrNull($payload['printer_port'] ?? null),
        ':is_connected' => printingBool($payload['is_connected'] ?? 0),
    ];
    if ($printerId > 0) {
        $stmt = $con->prepare("
            UPDATE vendor_printers
            SET
                printer_name = :printer_name,
                printer_model = :printer_model,
                printer_type = :printer_type,
                printer_location = :printer_location,
                printer_sections_json = :printer_sections_json,
                printer_ip = :printer_ip,
                printer_port = :printer_port,
                is_connected = :is_connected,
                is_active = 1
            WHERE printer_id = :printer_id
              AND vendor_id = :vendor_id
        ");
        $data[':printer_id'] = $printerId;
        $stmt->execute($data);
    } else {
        $stmt = $con->prepare("
            INSERT INTO vendor_printers (
                vendor_id,
                printer_name,
                printer_model,
                printer_type,
                printer_location,
                printer_sections_json,
                printer_ip,
                printer_port,
                is_connected
            ) VALUES (
                :vendor_id,
                :printer_name,
                :printer_model,
                :printer_type,
                :printer_location,
                :printer_sections_json,
                :printer_ip,
                :printer_port,
                :is_connected
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