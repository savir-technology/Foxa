<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');

$name = trim((string)filterRequest('username'));
$email = strtolower(trim((string)filterRequest('email')));
$phone = trim((string)filterRequest('phone'));
$password = (string)filterRequest('password');

if ($name === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || $phone === '' || strlen($password) < 6) {
    echo json_encode(['status' => 'failure', 'message' => 'Please provide valid account details']);
    exit;
}

$exists = $con->prepare('SELECT users_id FROM users WHERE LOWER(users_email) = ? OR users_phone = ? LIMIT 1');
$exists->execute([$email, $phone]);
if ($exists->fetch()) {
    echo json_encode(['status' => 'failure', 'message' => 'PHONE OR EMAIL']);
    exit;
}

$code = (string)random_int(100000, 999999);
$stmt = $con->prepare("INSERT INTO users (users_name, users_password, users_email, users_phone, users_verfiycode, users_approve, password_hashed, auth_provider, profile_completed) VALUES (?, ?, ?, ?, ?, 0, 1, 'email', 0)");
$stmt->execute([$name, password_hash($password, PASSWORD_DEFAULT), $email, $phone, $code]);
$mailSent = sendEmailWithFallback($email, 'Verify your FOXA account', $code);
if (!$mailSent) {
    $clearCode = $con->prepare('UPDATE users SET users_verfiycode = 0 WHERE users_email = ? AND users_approve = 0');
    $clearCode->execute([$email]);
    echo json_encode(['status' => 'failure', 'message' => 'Unable to send verification email']);
    exit;
}
echo json_encode(['status' => 'success', 'message' => 'Verification code sent']);
?>
