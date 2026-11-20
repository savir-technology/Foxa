<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"]);
    exit;
}

$email = trim((string)($_POST['email'] ?? ''));
$password = trim((string)($_POST['password'] ?? ''));

if ($email === '' || $password === '') {
    echo json_encode(["status" => "error", "message" => "email and password are required"]);
    exit;
}

try {
    $stmt = $con->prepare("
        SELECT du.*
        FROM delivery_users du
        WHERE LOWER(du.email) = LOWER(?)
        LIMIT 1
    ");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode(["status" => "error", "message" => "invalid credentials"]);
        exit;
    }

    $storedPassword = (string)($user['password'] ?? '');
    $passwordOk = false;

    if ($storedPassword !== '' && password_verify($password, $storedPassword)) {
        $passwordOk = true;
    } elseif ($storedPassword !== '' && hash_equals($storedPassword, $password)) {
        $passwordOk = true;
    }

    if (!$passwordOk) {
        echo json_encode(["status" => "error", "message" => "invalid credentials"]);
        exit;
    }

    if (function_exists('driverColumnExists') && driverColumnExists('delivery_users', 'approval_status')) {
        $approvalStatus = strtolower(trim((string)($user['approval_status'] ?? 'pending')));
        if ($approvalStatus !== 'approved') {
            echo json_encode([
                "status" => "error",
                "message" => "driver account is pending approval",
                "approval_status" => $approvalStatus,
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }

    $updateStmt = $con->prepare("
        UPDATE delivery_users
        SET last_login_at = NOW()
        WHERE id = ?
    ");
    $updateStmt->execute([(int)$user['id']]);

    $freshStmt = $con->prepare("
        SELECT du.*
        FROM delivery_users du
        WHERE du.id = ?
        LIMIT 1
    ");
    $freshStmt->execute([(int)$user['id']]);
    $user = $freshStmt->fetch(PDO::FETCH_ASSOC) ?: $user;

    unset($user['password']);

    echo json_encode([
        "status" => "success",
        "message" => "login success",
        "driver_id" => $user['id'] ?? null,
        "needs_profile_setup" => (int)($user['profile_completed'] ?? 0) !== 1,
        "data" => $user,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
