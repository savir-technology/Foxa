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
$phoneInput = trim((string)($payload['phone'] ?? ''));
$email = strtolower(trim((string)($payload['email'] ?? '')));
$name = trim((string)($payload['name'] ?? $payload['username'] ?? ''));
$photo = trim((string)($payload['photo'] ?? ''));
$firebaseUid = trim((string)($payload['firebase_uid'] ?? $payload['uid'] ?? ''));
$locale = trim((string)($payload['locale'] ?? ''));
$fcmToken = trim((string)($payload['fcm_token'] ?? ''));
if ($email === '') {
    respondJson([
        'status' => 'error',
        'message' => 'A Google email is required',
    ], 400);
}
$userByEmail = findUserByEmail($email);
if ($phoneInput === '') {
    $storedPhone = trim((string)($userByEmail['users_phone'] ?? ''));
    $hasStoredPhone = $storedPhone !== '' && strtolower($storedPhone) !== 'null';
    if (!$userByEmail || !$hasStoredPhone) {
        respondJson([
            'status' => 'needs_phone',
            'message' => 'WhatsApp number is required for the first Google sign-in',
        ]);
    }
    $fields = array(
        'users_approve' => 1,
        'last_login_at' => date('Y-m-d H:i:s'),
        'auth_provider' => 'google',
        'users_email' => $email,
        'profile_completed' => 1,
    );
    if ($locale !== '') {
        $fields['users_locale'] = $locale;
    }
    if ($name !== '') {
        $currentName = trim((string)($userByEmail['users_name'] ?? ''));
        if ($currentName === '' || $currentName === 'New User') {
            $fields['users_name'] = $name;
        }
    }
    if ($photo !== '') {
        $fields['users_image'] = $photo;
    }
    if ($fcmToken !== '') {
        $fields['fcm_token'] = substr($fcmToken, 0, 255);
    }
    if (empty($userByEmail['whatsapp_phone_verified_at'])) {
        $fields['whatsapp_phone_verified_at'] = date('Y-m-d H:i:s');
    }
    $setParts = array();
    $params = array(':user_id' => (int)$userByEmail['users_id']);
    foreach ($fields as $column => $value) {
        $setParts[] = $column . ' = :' . $column;
        $params[':' . $column] = $value;
    }
    $stmt = $con->prepare("
        UPDATE users
        SET " . implode(",\n        ", $setParts) . "
        WHERE users_id = :user_id
    ");
    $stmt->execute($params);
    $fresh = $con->prepare("SELECT * FROM users WHERE users_id = :user_id LIMIT 1");
    $fresh->execute(array(':user_id' => (int)$userByEmail['users_id']));
    $user = $fresh->fetch(PDO::FETCH_ASSOC) ?: $userByEmail;
    if ($fcmToken !== '') {
        purgeDuplicateUserFcmToken($con, (int)$user['users_id'], $fcmToken);
    }
    $session = createUserSession((int)$user['users_id']);
    respondJson([
        'status' => 'success',
        'message' => 'Signed in successfully',
        'user' => userPublicData($user),
        'token' => $session['token'],
        'refresh_token' => $session['refresh_token'],
        'expires_at' => $session['expires_at'],
        'refresh_expires_at' => $session['refresh_expires_at'],
    ]);
}
$phone = normalizePhoneForStorage($phoneInput);
if ($phone === '') {
    respondJson([
        'status' => 'error',
        'message' => 'A valid WhatsApp number is required',
    ], 400);
}
$userByPhone = findUserByPhoneFlexible($phone);
if ($userByPhone && (!$userByEmail || (int)$userByPhone['users_id'] !== (int)$userByEmail['users_id'])) {
    respondJson([
        'status' => 'phone_in_use',
        'message' => 'This WhatsApp number is already linked to another account. Please use a different number.',
    ], 409);
}
$user = $userByEmail;
$isNewUser = !$user;
$fields = array(
    'users_approve' => 1,
    'last_login_at' => date('Y-m-d H:i:s'),
    'auth_provider' => 'google',
    'profile_completed' => 1,
    'users_email' => $email,
    'users_phone' => $phone,
);
if ($locale !== '') {
    $fields['users_locale'] = $locale;
}
if ($name !== '') {
    $currentName = trim((string)($user['users_name'] ?? ''));
    if ($isNewUser || $currentName === '' || $currentName === 'New User') {
        $fields['users_name'] = $name;
    }
} elseif ($isNewUser || trim((string)($user['users_name'] ?? '')) === '' || trim((string)($user['users_name'] ?? '')) === 'New User') {
    $fields['users_name'] = $email;
}
if ($email !== '') {
    $currentEmail = trim((string)($user['users_email'] ?? ''));
    $isPlaceholderEmail = strpos($currentEmail, '@wa.aleppoeats.local') !== false
        || strpos($currentEmail, 'social_') === 0
        || $currentEmail === '';
    if ($isNewUser || $isPlaceholderEmail) {
        $fields['users_email'] = $email;
    }
}
if ($photo !== '') {
    $fields['users_image'] = $photo;
}
if ($fcmToken !== '') {
    $fields['fcm_token'] = substr($fcmToken, 0, 255);
}
if ($isNewUser || empty($user['whatsapp_phone_verified_at'])) {
    $fields['whatsapp_phone_verified_at'] = date('Y-m-d H:i:s');
}
if ($isNewUser) {
    $randomPassword = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT);
    $insertData = [
        'users_name' => $fields['users_name'] ?? $email,
        'users_password' => $randomPassword,
        'users_email' => $fields['users_email'] ?? $email,
        'users_phone' => $phone,
        'users_verfiycode' => 0,
        'users_approve' => 1,
        'password_hashed' => 1,
        'auth_provider' => 'google',
        'profile_completed' => 1,
        'whatsapp_phone_verified_at' => $fields['whatsapp_phone_verified_at'] ?? date('Y-m-d H:i:s'),
        'last_login_at' => $fields['last_login_at'],
    ];
    if ($locale !== '') {
        $insertData['users_locale'] = $locale;
    }
    if ($photo !== '') {
        $insertData['users_image'] = $photo;
    }
    if ($fcmToken !== '') {
        $insertData['fcm_token'] = substr($fcmToken, 0, 255);
    }
    $fieldsList = implode(', ', array_keys($insertData));
    $placeholders = implode(', ', array_map(function ($key) {
        return ':' . $key;
    }, array_keys($insertData)));
    $stmt = $con->prepare("
        INSERT INTO users ($fieldsList)
        VALUES ($placeholders)
    ");
    $params = [];
    foreach ($insertData as $column => $value) {
        $params[':' . $column] = $value;
    }
    $stmt->execute($params);
    $fresh = $con->prepare("SELECT * FROM users WHERE users_id = :user_id LIMIT 1");
    $fresh->execute(array(':user_id' => (int)$con->lastInsertId()));
    $user = $fresh->fetch(PDO::FETCH_ASSOC) ?: $insertData;
} else {
    $setParts = array();
    $params = array(':user_id' => (int)$user['users_id']);
    foreach ($fields as $column => $value) {
        $setParts[] = $column . ' = :' . $column;
        $params[':' . $column] = $value;
    }
    $stmt = $con->prepare("
        UPDATE users
        SET " . implode(",\n        ", $setParts) . "
        WHERE users_id = :user_id
    ");
    $stmt->execute($params);
    $fresh = $con->prepare("SELECT * FROM users WHERE users_id = :user_id LIMIT 1");
    $fresh->execute(array(':user_id' => (int)$user['users_id']));
    $user = $fresh->fetch(PDO::FETCH_ASSOC) ?: $user;
}
if ($fcmToken !== '') {
    purgeDuplicateUserFcmToken($con, (int)$user['users_id'], $fcmToken);
}
$session = createUserSession((int)$user['users_id']);
respondJson([
    'status' => 'success',
    'message' => 'WhatsApp number linked successfully',
    'user' => userPublicData($user),
    'token' => $session['token'],
    'refresh_token' => $session['refresh_token'],
    'expires_at' => $session['expires_at'],
    'refresh_expires_at' => $session['refresh_expires_at'],
]);