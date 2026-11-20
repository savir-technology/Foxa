<?php
require_once __DIR__ . '/../config/database.php';

$databaseConfig = roaqDatabaseConfig();
$options = [PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8mb4'];

try {
    $con = new PDO($databaseConfig['dsn'], $databaseConfig['user'], $databaseConfig['pass'], $options);
    $con->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    header('Access-Control-Allow-Origin: *');
    header('Content-Type: application/json; charset=UTF-8');

    $values = [
        ':user_name' => $_GET['user_name'] ?? null,
        ':user_phone' => $_GET['user_phone'] ?? null,
        ':user_email' => $_GET['user_email'] ?? null,
        ':complaint_description' => $_GET['complaint_description'] ?? null,
    ];
    if (in_array(null, $values, true) || in_array('', $values, true)) {
        http_response_code(422);
        echo json_encode(['error' => 'All fields are required']);
        exit;
    }

    $stmt = $con->prepare(
        'INSERT INTO complaints (user_name, user_phone, user_email, complaint_description)
         VALUES (:user_name, :user_phone, :user_email, :complaint_description)'
    );
    $stmt->execute($values);
    echo json_encode(['message' => 'Complaint submitted successfully']);
} catch (Throwable $e) {
    error_log('Complaint submission failed: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Database operation failed']);
}
