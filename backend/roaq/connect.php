<?php
require_once __DIR__ . '/config/database.php';
$databaseConfig = roaqDatabaseConfig();
$dsn = $databaseConfig['dsn'];
$user = $databaseConfig['user'];
$pass = $databaseConfig['pass'];

$option = [
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4",
];

$countrowinpage = 9;

// CORS is restricted to the production dashboard and local development.
$requestOrigin = trim((string)($_SERVER['HTTP_ORIGIN'] ?? ''));
$isAllowedOrigin = in_array(
    $requestOrigin,
    [
        'https://savir-technology.online',
        'https://www.savir-technology.online',
    ],
    true
) || (bool)preg_match(
    '/^https?:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/i',
    $requestOrigin
);
if ($isAllowedOrigin) {
    header('Access-Control-Allow-Origin: ' . $requestOrigin);
    header('Vary: Origin');
}
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Access-Control-Allow-Origin");
header("Access-Control-Allow-Methods: POST, OPTIONS, GET");

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $con = new PDO($dsn, $user, $pass, $option);
    $con->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $con->exec("SET NAMES utf8mb4");
    $con->exec("SET CHARACTER SET utf8mb4");
    $con->exec("SET COLLATION_CONNECTION = 'utf8mb4_unicode_ci'");
    date_default_timezone_set("Africa/Cairo");
    require_once __DIR__ . '/functions.php';
    // The Master setting is the single source of truth for platform dates.
    applyPlatformTimezone();
} catch (Throwable $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    http_response_code(503);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed',
    ]);
    exit();
}
