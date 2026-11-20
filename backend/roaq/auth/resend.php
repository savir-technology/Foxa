<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');

$email = strtolower(trim((string)filterRequest('email')));
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'failure', 'message' => 'Invalid email']);
    exit;
}

$code = (string)random_int(100000, 999999);
$user = findUserByEmail($email);
if (!$user || (int)($user['users_approve'] ?? 0) === 1) {
    echo json_encode(['status' => 'failure', 'message' => 'Verification is not required']);
    exit;
}

$update = $con->prepare('UPDATE users SET users_verfiycode = ? WHERE users_id = ?');
$update->execute([$code, (int)$user['users_id']]);
if (!sendEmailWithFallback($email, 'Verify your FOXA account', $code)) {
    echo json_encode(['status' => 'failure', 'message' => 'Unable to send verification email']);
    exit;
}
echo json_encode(['status' => 'success', 'message' => 'Verification code sent']);
?>
