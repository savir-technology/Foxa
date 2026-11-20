<?php
require_once __DIR__ . '/../config/database.php';

$databaseConfig = roaqDatabaseConfig();
$options = [PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8mb4'];

try {
    $con = new PDO($databaseConfig['dsn'], $databaseConfig['user'], $databaseConfig['pass'], $options);
    $con->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    header('Access-Control-Allow-Origin: *');
    header('Content-Type: application/json; charset=UTF-8');
    $stmt = $con->prepare('SELECT * FROM complaints');
    $stmt->execute();
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Throwable $e) {
    error_log('Complaint list failed: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Database operation failed']);
}
