<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, OPTIONS');

require_once __DIR__ . '/../../connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    echo json_encode([
        'status' => 'success',
        'data' => getPlatformCurrencySettings(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Unable to load currency settings',
    ], JSON_UNESCAPED_UNICODE);
}
