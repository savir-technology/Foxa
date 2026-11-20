<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');

$email = strtolower(trim((string)filterRequest('email')));
$password = (string)filterRequest('password');
if ($email === '' || $password === '') {
    echo json_encode(['status' => 'failure', 'message' => 'Email and password are required']);
    exit;
}

$user = findUserByEmail($email);
if (!$user) {
    echo json_encode(['status' => 'failure', 'message' => 'Invalid email or password']);
    exit;
}

$stored = (string)($user['users_password'] ?? '');
$hashed = (int)($user['password_hashed'] ?? 0) === 1 || password_get_info($stored)['algo'] !== 0;
$valid = $hashed ? password_verify($password, $stored) : hash_equals($stored, $password);
if (!$valid) {
    echo json_encode(['status' => 'failure', 'message' => 'Invalid email or password']);
    exit;
}

if ((int)($user['users_approve'] ?? 0) !== 1) {
    echo json_encode(['status' => 'unverified', 'message' => 'Please verify your email first']);
    exit;
}

// Upgrade old plaintext records after the first successful login.
if (!$hashed) {
    $upgrade = $con->prepare('UPDATE users SET users_password = ?, password_hashed = 1 WHERE users_id = ?');
    $upgrade->execute([password_hash($password, PASSWORD_DEFAULT), (int)$user['users_id']]);
}

$session = createUserSession((int)$user['users_id']);
echo json_encode([
    'status' => 'success',
    'user' => userPublicData($user),
    'token' => $session['token'],
    'refresh_token' => $session['refresh_token'],
    'expires_at' => $session['expires_at'],
    'refresh_expires_at' => $session['refresh_expires_at'],
]);
?>
