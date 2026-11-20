<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');
$email = strtolower(trim((string)filterRequest('email')));
$code = trim((string)filterRequest('verifycode'));
$stmt = $con->prepare('SELECT users_id FROM users WHERE LOWER(users_email) = ? AND users_verfiycode = ? LIMIT 1');
$stmt->execute([$email, $code]);
echo json_encode($stmt->fetch() ? ['status' => 'success'] : ['status' => 'failure', 'message' => 'Verification code is incorrect']);
?>
