<?php
include "../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
$payload = getRequestPayload();
$phone = normalizeWhatsappPhone($payload['phone'] ?? '');
$locale = trim((string)($payload['locale'] ?? ''));
if ($phone === '') {
    respondJson([
        'status' => 'error',
        'message' => 'A valid WhatsApp phone number is required',
    ], 400);
}
$cooldownStmt = $con->prepare("
    SELECT created_at
    FROM user_otp_requests
    WHERE phone_e164 = :phone
      AND created_at >= (NOW() - INTERVAL 60 SECOND)
    ORDER BY otp_request_id DESC
    LIMIT 1
");
$cooldownStmt->execute([':phone' => $phone]);
$cooldownRow = $cooldownStmt->fetch(PDO::FETCH_ASSOC);
if ($cooldownRow) {
    respondJson([
        'status' => 'error',
        'message' => 'Please wait before requesting another code',
        'retry_after_seconds' => 60,
    ], 429);
}
$hourlyStmt = $con->prepare("
    SELECT COUNT(*)
    FROM user_otp_requests
    WHERE phone_e164 = :phone
      AND created_at >= (NOW() - INTERVAL 1 HOUR)
");
$hourlyStmt->execute([':phone' => $phone]);
$requestsLastHour = (int)$hourlyStmt->fetchColumn();
if ($requestsLastHour >= 5) {
    respondJson([
        'status' => 'error',
        'message' => 'Too many OTP requests for this number. Please try again later.',
    ], 429);
}
$provider = 'local_debug';
$providerSid = null;
$requestStatus = 'pending';
$debugCode = null;
$metadata = [
    'locale' => $locale !== '' ? $locale : null,
];
if (isTwilioVerifyConfigured()) {
    $twilioResponse = sendWhatsAppVerificationCode($phone);
    if (!$twilioResponse['success']) {
        respondJson([
            'status' => 'error',
            'message' => $twilioResponse['message'] ?? 'Unable to send WhatsApp verification code',
        ], 502);
    }
    $provider = 'twilio_verify';
    $providerSid = $twilioResponse['provider_sid'] ?? null;
    $requestStatus = $twilioResponse['status'] ?? 'pending';
    $metadata['provider_payload'] = $twilioResponse['data'] ?? null;
} elseif (allowLocalOtpFallback()) {
    $debugCode = generateOtpCode(5);
    $metadata['debug_mode'] = true;
} else {
    respondJson([
        'status' => 'error',
        'message' => 'Twilio Verify is not configured for WhatsApp OTP',
    ], 500);
}
$expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));
$insertStmt = $con->prepare("
    INSERT INTO user_otp_requests (
        phone_e164,
        provider,
        provider_sid,
        channel,
        otp_code_hash,
        request_status,
        send_attempts,
        verify_attempts,
        metadata,
        expires_at
    ) VALUES (
        :phone_e164,
        :provider,
        :provider_sid,
        'whatsapp',
        :otp_code_hash,
        :request_status,
        1,
        0,
        :metadata,
        :expires_at
    )
");
$insertStmt->execute([
    ':phone_e164' => $phone,
    ':provider' => $provider,
    ':provider_sid' => $providerSid,
    ':otp_code_hash' => $debugCode !== null ? hash('sha256', $debugCode) : null,
    ':request_status' => $requestStatus,
    ':metadata' => json_encode($metadata, JSON_UNESCAPED_UNICODE),
    ':expires_at' => $expiresAt,
]);
$response = [
    'status' => 'success',
    'message' => 'Verification code sent successfully',
    'phone' => $phone,
    'provider' => $provider,
    'expires_at' => $expiresAt,
];
if ($debugCode !== null && !isProductionEnvironment()) {
    $response['debug_code'] = $debugCode;
}
respondJson($response);