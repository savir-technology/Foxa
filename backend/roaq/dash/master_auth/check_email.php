<?php
include "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$email = strtolower(trim((string)($payload['email'] ?? '')));

if ($email === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email is required',
    ], 400);
}

try {
    $stmt = $con->prepare("
        SELECT admin_id, admin_name, admin_approve
        FROM admin
        WHERE LOWER(admin_email) = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$admin) {
        respondJson([
            'status' => 'error',
            'message' => 'Account not found',
        ], 404);
    }

    $resetCode = generateOtpCode(6);
    $resetExpiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));

    $con->beginTransaction();
    $updateStmt = $con->prepare("
        UPDATE admin
        SET
            admin_reset_code = :code,
            admin_reset_expires_at = :expires_at
        WHERE admin_id = :admin_id
    ");
    $updateStmt->execute([
        ':code' => $resetCode,
        ':expires_at' => $resetExpiresAt,
        ':admin_id' => $admin['admin_id'],
    ]);

    if (!sendEmailWithFallback($email, 'FOXA Master Reset Code', "رمز إعادة التعيين: $resetCode")) {
        throw new RuntimeException('Unable to send reset email');
    }

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Reset code sent successfully',
        'email' => $email,
        'next_step' => 'verify_reset_code',
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
