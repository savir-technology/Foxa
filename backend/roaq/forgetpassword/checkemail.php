<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');
$email = strtolower(trim((string)filterRequest('email')));
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'failure', 'message' => 'Invalid email']); exit;
}
$user = findUserByEmail($email);
if (!$user) {
    echo json_encode(['status' => 'failure', 'message' => 'Email not found']); exit;
}
$code = (string)random_int(100000, 999999);
$update = $con->prepare('UPDATE users SET users_verfiycode = ? WHERE users_id = ?');
$update->execute([$code, (int)$user['users_id']]);
if (!sendEmailWithFallback($email, 'Reset your FOXA password', $code)) {
    echo json_encode(['status' => 'failure', 'message' => 'Unable to send verification email']); exit;
}
echo json_encode(['status' => 'success', 'message' => 'Verification code sent']);
?>
