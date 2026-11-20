<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');

$email = strtolower(trim((string)filterRequest('email')));
$code = trim((string)filterRequest('verifycode'));
$stmt = $con->prepare('SELECT * FROM users WHERE LOWER(users_email) = ? AND users_verfiycode = ? LIMIT 1');
$stmt->execute([$email, $code]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
    echo json_encode(['status' => 'failure', 'message' => 'Verification code is incorrect']);
    exit;
}

$update = $con->prepare('UPDATE users SET users_approve = 1, users_verfiycode = 0 WHERE users_id = ?');
$update->execute([(int)$user['users_id']]);
echo json_encode(['status' => 'success', 'message' => 'Email verified successfully']);
?>
