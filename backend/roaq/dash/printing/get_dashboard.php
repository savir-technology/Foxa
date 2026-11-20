<?php
include "../../connect.php";
require_once __DIR__ . "/printing_helpers.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
try {
    $vendorId = printingResolveVendorId();
    if ($vendorId <= 0) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid vendor session',
        ], 401);
    }
    printingRespondDashboard($con, $vendorId);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}