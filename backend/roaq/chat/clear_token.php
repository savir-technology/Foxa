<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../connect.php';

$user_id = intval($_POST['user_id'] ?? 0);
if ($user_id <= 0) {
    echo json_encode([
        'status' => 'fail',
        'message' => 'missing user_id',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

try {
    $stmt = $con->prepare('UPDATE users SET fcm_token = NULL WHERE users_id = :id');
    $ok = $stmt->execute([':id' => $user_id]);

    echo json_encode([
        'status' => $ok ? 'success' : 'fail',
        'message' => $ok ? 'token cleared' : 'database error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('clear_token.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

