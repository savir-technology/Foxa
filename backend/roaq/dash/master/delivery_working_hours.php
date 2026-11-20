<?php
include __DIR__ . "/../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Pragma: no-cache");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $actor = requireDashboardActor(['master']);
    requireMasterPermission(
        $actor['master'] ?? [],
        $_SERVER['REQUEST_METHOD'] === 'POST' ? 'settings.edit' : 'settings.view'
    );

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $payload = getRequestPayload();
        $rowsPayload = $payload['delivery_working_hours']
            ?? $payload['working_hours']
            ?? $payload['hours']
            ?? null;

        if (!is_array($rowsPayload)) {
            respondJson([
                'status' => 'error',
                'message' => 'delivery_working_hours is required',
            ], 400);
        }

        replaceDeliveryWorkingHoursRows($rowsPayload);
    }

    $rows = fetchDeliveryWorkingHoursRows();
    $responseRows = deliveryWorkingHoursRowsToResponse($rows);

    respondJson([
        'status' => 'success',
        'data' => $responseRows,
        'working_hours' => $responseRows,
        'delivery_working_hours_json' => $responseRows,
        'updated_by' => masterPublicData($actor['master'] ?? []),
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
