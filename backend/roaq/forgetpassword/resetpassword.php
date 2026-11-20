<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');
$email = strtolower(trim((string)filterRequest('email')));
$code = trim((string)filterRequest('verifycode'));
$password = (string)filterRequest('password');
if (strlen($password) < 6) {
    echo json_encode(['status' => 'failure', 'message' => 'Password must be at least 6 characters']); exit;
}
$stmt = $con->prepare('SELECT users_id FROM users WHERE LOWER(users_email) = ? AND users_verfiycode = ? LIMIT 1');
$stmt->execute([$email, $code]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
    echo json_encode(['status' => 'failure', 'message' => 'Verification code is incorrect']); exit;
}
$update = $con->prepare('UPDATE users SET users_password = ?, password_hashed = 1, users_verfiycode = 0 WHERE users_id = ?');
$update->execute([password_hash($password, PASSWORD_DEFAULT), (int)$user['users_id']]);
echo json_encode(['status' => 'success', 'message' => 'Password reset successfully']);
?>
