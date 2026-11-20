<?php
include __DIR__ . "/connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$payload = getRequestPayload();
$email = strtolower(trim((string)($payload['email'] ?? '')));
$code = trim((string)($payload['code'] ?? ''));

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || !preg_match('/^\d{4,10}$/', $code)) {
    respondJson([
        'status' => 'error',
        'message' => 'Email and verification code are required',
    ], 400);
}

try {
    ensureDriverOtpSchema();

    $otpStmt = $con->prepare("
        SELECT *
        FROM driver_email_otp_requests
        WHERE email = :email
          AND verified_at IS NULL
          AND used_at IS NULL
          AND expires_at > NOW()
        ORDER BY otp_request_id DESC
        LIMIT 1
    ");
    $otpStmt->execute([':email' => $email]);
    $otpRequest = $otpStmt->fetch(PDO::FETCH_ASSOC);

    if (!$otpRequest) {
        respondJson([
            'status' => 'error',
            'message' => 'No active verification request was found for this email',
        ], 404);
    }

    if ((int)($otpRequest['verify_attempts'] ?? 0) >= 5) {
        respondJson([
            'status' => 'error',
            'message' => 'Too many verification attempts. Please request a new code.',
        ], 429);
    }

    $verificationPassed = hash_equals(
        (string)($otpRequest['otp_code_hash'] ?? ''),
        hash('sha256', $code)
    );

    $updateStmt = $con->prepare("
        UPDATE driver_email_otp_requests
        SET verify_attempts = verify_attempts + 1,
            request_status = :request_status,
            verified_at = CASE WHEN :verified = 1 THEN NOW() ELSE verified_at END,
            verification_token = CASE WHEN :verified = 1 AND verification_token IS NULL
                THEN :verification_token
                ELSE verification_token
            END
        WHERE otp_request_id = :otp_request_id
    ");

    $verificationToken = null;
    if ($verificationPassed) {
        $verificationToken = bin2hex(random_bytes(32));
    }

    $updateStmt->execute([
        ':request_status' => $verificationPassed ? 'approved' : 'failed',
        ':verified' => $verificationPassed ? 1 : 0,
        ':verification_token' => $verificationToken,
        ':otp_request_id' => (int)$otpRequest['otp_request_id'],
    ]);

    if (!$verificationPassed) {
        respondJson([
            'status' => 'error',
            'message' => 'Verification code is not valid',
        ], 401);
    }

    respondJson([
        'status' => 'success',
        'message' => 'Email verification completed',
        'email' => $email,
        'verification_token' => $verificationToken,
        'expires_at' => $otpRequest['expires_at'] ?? null,
    ]);
} catch (Throwable $e) {
    error_log('driver_email_verify_code failed: ' . $e->getMessage());
    respondJson([
        'status' => 'error',
        'message' => 'تعذر التحقق من رمز البريد الإلكتروني، حاول مرة أخرى.',
    ], 500);
}
