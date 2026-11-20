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
requireMasterPermission($admin, 'orders.edit');
$payload = json_decode(file_get_contents('php://input') ?: '{}', true);
$copies = max(1, min(10, (int)($payload['invoice_copies'] ?? 1)));
$printLogo = !empty($payload['print_logo']) ? 1 : 0;
$vendorId = (int)($payload['vendor_id'] ?? 0);

try {
    $current = $con->prepare(
        'SELECT setting_id FROM vendor_print_settings
         WHERE vendor_id = :vendor_id ORDER BY setting_id DESC LIMIT 1'
    );
    $current->execute([':vendor_id' => $vendorId]);
    $settingId = (int)($current->fetchColumn() ?: 0);

    if ($settingId > 0) {
        $stmt = $con->prepare(
            'UPDATE vendor_print_settings
             SET invoice_copies = :copies, print_logo = :logo, updated_at = NOW()
             WHERE setting_id = :id'
        );
        $stmt->execute([':copies' => $copies, ':logo' => $printLogo, ':id' => $settingId]);
    } else {
        $stmt = $con->prepare(
            'INSERT INTO vendor_print_settings
             (vendor_id, default_direction, default_font_size, invoice_copies, print_logo)
             VALUES (:vendor_id, :direction, :font_size, :copies, :logo)'
        );
        $stmt->execute([
            ':vendor_id' => $vendorId,
            ':direction' => 'rtl_ar',
            ':font_size' => 'medium',
            ':copies' => $copies,
            ':logo' => $printLogo,
        ]);
    }

    respondJson(['status' => 'success', 'message' => 'Print settings saved']);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
