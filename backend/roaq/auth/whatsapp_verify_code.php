<?php
include "../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
require_once __DIR__ . '/../notifications/fcm_token_utils.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
$payload = getRequestPayload();
$phone = normalizeWhatsappPhone($payload['phone'] ?? '');
$code = trim((string)($payload['code'] ?? ''));
$locale = trim((string)($payload['locale'] ?? ''));
$fcmToken = trim((string)($payload['fcm_token'] ?? ''));
if ($phone === '' || !preg_match('/^\d{4,10}$/', $code)) {
    respondJson([
        'status' => 'error',
        'message' => 'Phone number and verification code are required',
    ], 400);
}
$otpStmt = $con->prepare("
    SELECT *
    FROM user_otp_requests
    WHERE phone_e164 = :phone
      AND verified_at IS NULL
      AND expires_at > NOW()
    ORDER BY otp_request_id DESC
    LIMIT 1
");
$otpStmt->execute([':phone' => $phone]);
$otpRequest = $otpStmt->fetch(PDO::FETCH_ASSOC);
if (!$otpRequest) {
    respondJson([
        'status' => 'error',
        'message' => 'No active OTP request was found for this number',
    ], 404);
}
if ((int)($otpRequest['verify_attempts'] ?? 0) >= 5) {
    respondJson([
        'status' => 'error',
        'message' => 'Too many verification attempts. Please request a new code.',
    ], 429);
}
$verificationPassed = false;
$providerStatus = 'pending';
$providerMessage = 'Verification code is not valid';
if (($otpRequest['provider'] ?? '') === 'twilio_verify') {
    $twilioCheck = checkWhatsAppVerificationCode($phone, $code);
    $verificationPassed = (bool)($twilioCheck['success'] ?? false);
    $providerStatus = $twilioCheck['status'] ?? 'pending';
    $providerMessage = $twilioCheck['message'] ?? $providerMessage;
} else {
    $verificationPassed = hash_equals(
        (string)($otpRequest['otp_code_hash'] ?? ''),
        hash('sha256', $code)
    );
    $providerStatus = $verificationPassed ? 'approved' : 'failed';
    $providerMessage = $verificationPassed ? 'approved' : $providerMessage;
}
$updateAttemptStmt = $con->prepare("
    UPDATE user_otp_requests
    SET verify_attempts = verify_attempts + 1,
        request_status = :request_status,
        verified_at = CASE WHEN :verified = 1 THEN NOW() ELSE verified_at END
    WHERE otp_request_id = :otp_request_id
");
$updateAttemptStmt->execute([
    ':request_status' => $providerStatus,
    ':verified' => $verificationPassed ? 1 : 0,
    ':otp_request_id' => (int)$otpRequest['otp_request_id'],
]);
if (!$verificationPassed) {
    respondJson([
        'status' => 'error',
        'message' => $providerMessage,
    ], 401);
}
$user = ensureWhatsappUser($phone, $locale !== '' ? $locale : null);
$profileCompleted = (int)($user['profile_completed'] ?? 0) === 1;
if ($fcmToken !== '') {
    $tokenStmt = $con->prepare("UPDATE users SET fcm_token = :fcm_token WHERE users_id = :user_id");
    $tokenStmt->execute([
        ':fcm_token' => substr($fcmToken, 0, 255),
        ':user_id' => (int)$user['users_id'],
    ]);
    $user['fcm_token'] = $fcmToken;
    purgeDuplicateUserFcmToken($con, (int)$user['users_id'], $fcmToken);
}
$session = createUserSession((int)$user['users_id']);
respondJson([
    'status' => 'success',
    'message' => 'WhatsApp verification completed',
    'token' => $session['token'],
    'refresh_token' => $session['refresh_token'],
    'expires_at' => $session['expires_at'],
    'refresh_expires_at' => $session['refresh_expires_at'],
    'needs_profile_setup' => !$profileCompleted,
    'user' => userPublicData($user),
]);