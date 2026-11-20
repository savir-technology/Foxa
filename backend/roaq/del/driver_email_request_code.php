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
$locale = trim((string)($payload['locale'] ?? ''));

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respondJson([
        'status' => 'error',
        'message' => 'A valid email address is required',
    ], 400);
}

try {
    ensureDriverOtpSchema();

    $cooldownStmt = $con->prepare("
        SELECT created_at
        FROM driver_email_otp_requests
        WHERE email = :email
          AND created_at >= (NOW() - INTERVAL 60 SECOND)
        ORDER BY otp_request_id DESC
        LIMIT 1
    ");
    $cooldownStmt->execute([':email' => $email]);
    if ($cooldownStmt->fetch(PDO::FETCH_ASSOC)) {
        respondJson([
            'status' => 'error',
            'message' => 'Please wait before requesting another code',
            'retry_after_seconds' => 60,
        ], 429);
    }

    $hourlyStmt = $con->prepare("
        SELECT COUNT(*)
        FROM driver_email_otp_requests
        WHERE email = :email
          AND created_at >= (NOW() - INTERVAL 1 HOUR)
    ");
    $hourlyStmt->execute([':email' => $email]);
    $requestsLastHour = (int)$hourlyStmt->fetchColumn();
    if ($requestsLastHour >= 5) {
        respondJson([
            'status' => 'error',
            'message' => 'Too many OTP requests for this email. Please try again later.',
        ], 429);
    }

    $code = generateOtpCode(6);
    $subject = 'FOXA Driver verification code';
    $message = "Verification code: {$code}";
    $mailSent = sendEmailWithFallback($email, $subject, $message);

    if (!$mailSent) {
        respondJson([
            'status' => 'error',
            'message' => 'Unable to send the verification email',
        ], 502);
    }

    $expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));
    $metadata = [
        'locale' => $locale !== '' ? $locale : null,
    ];

    $insertStmt = $con->prepare("
        INSERT INTO driver_email_otp_requests (
            email,
            otp_code_hash,
            request_status,
            send_attempts,
            verify_attempts,
            metadata,
            expires_at
        ) VALUES (
            :email,
            :otp_code_hash,
            'pending',
            1,
            0,
            :metadata,
            :expires_at
        )
    ");
    $insertStmt->execute([
        ':email' => $email,
        ':otp_code_hash' => hash('sha256', $code),
        ':metadata' => json_encode($metadata, JSON_UNESCAPED_UNICODE),
        ':expires_at' => $expiresAt,
    ]);

    $response = [
        'status' => 'success',
        'message' => 'Verification code sent successfully',
        'email' => $email,
        'expires_at' => $expiresAt,
    ];

    if (!isProductionEnvironment()) {
        $response['debug_code'] = $code;
    }

    respondJson($response);
} catch (Throwable $e) {
    error_log('driver_email_request_code failed: ' . $e->getMessage());
    respondJson([
        'status' => 'error',
        'message' => 'تعذر إرسال رمز التحقق، حاول مرة أخرى.',
    ], 500);
}
