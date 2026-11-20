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
    $direction = trim((string)($payload['default_direction'] ?? 'rtl_ar'));
    if (!in_array($direction, ['rtl_ar', 'ltr_en'], true)) {
        $direction = 'rtl_ar';
    }
    $fontSize = trim((string)($payload['default_font_size'] ?? 'medium'));
    if (!in_array($fontSize, ['small', 'medium', 'large'], true)) {
        $fontSize = 'medium';
    }
    $copies = max(1, min(5, (int)($payload['invoice_copies'] ?? 1)));
    $printLogo = printingBool($payload['print_logo'] ?? 1, true);
    $stmt = $con->prepare("
        INSERT INTO vendor_print_settings (
            vendor_id,
            default_direction,
            default_font_size,
            invoice_copies,
            print_logo
        ) VALUES (
            :vendor_id,
            :default_direction,
            :default_font_size,
            :invoice_copies,
            :print_logo
        )
        ON DUPLICATE KEY UPDATE
            default_direction = VALUES(default_direction),
            default_font_size = VALUES(default_font_size),
            invoice_copies = VALUES(invoice_copies),
            print_logo = VALUES(print_logo)
    ");
    $stmt->execute([
        ':vendor_id' => $vendorId,
        ':default_direction' => $direction,
        ':default_font_size' => $fontSize,
        ':invoice_copies' => $copies,
        ':print_logo' => $printLogo,
    ]);
    printingRespondDashboard($con, $vendorId);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}