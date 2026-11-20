<?php
require_once dirname(__DIR__) . '/config/database.php';

$databaseConfig = roaqDatabaseConfig();
$dsn = $databaseConfig['dsn'];
$user = $databaseConfig['user'];
$pass = $databaseConfig['pass'];
$option = [PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8mb4'];
$countrowinpage = 9;

try {
    $con = new PDO($dsn, $user, $pass, $option);
    $con->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Access-Control-Allow-Origin');
    header('Access-Control-Allow-Methods: POST, OPTIONS, GET');
    require_once __DIR__ . '/functions.php';
} catch (Throwable $e) {
    error_log('Delivery database connection failed: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']);
    exit;
}
