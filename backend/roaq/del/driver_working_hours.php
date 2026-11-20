<?php
include __DIR__ . "/connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Pragma: no-cache");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $rows = fetchDeliveryWorkingHoursRows();
    $responseRows = deliveryWorkingHoursRowsToResponse($rows);

    respondJson([
        'status' => 'success',
        'data' => $responseRows,
        'delivery_working_hours_json' => $responseRows,
        'working_hours_json' => $responseRows,
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
