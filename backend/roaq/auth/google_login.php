<?php
include "../connect.php";

header('Content-Type: application/json; charset=utf-8');

$idToken = trim((string) (filterRequest("id_token") ?? ""));
$fallbackFirebaseUid = trim((string) (filterRequest("firebase_uid") ?? ""));
$fallbackEmail = trim((string) (filterRequest("email") ?? ""));
$fallbackName = trim((string) (filterRequest("name") ?? ""));
$fallbackPhotoUrl = trim((string) (filterRequest("photo_url") ?? ""));
$fallbackPhone = trim((string) (filterRequest("phone") ?? ""));

function googleFailure($message)
{
    echo json_encode(array(
        "status" => "failure",
        "message" => $message,
    ));
    exit;
}

function columnExists(PDO $con, $table, $column)
{
    $stmt = $con->prepare("
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
          AND TABLE_NAME = ? 
          AND COLUMN_NAME = ?
    ");
    $stmt->execute(array($table, $column));
    return intval($stmt->fetchColumn()) > 0;
}

function postJson($url, array $payload)
{
    $body = json_encode($payload);

    if (function_exists('curl_init')) {
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($body),
        ));
        curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);

        $response = curl_exec($ch);
        $statusCode = intval(curl_getinfo($ch, CURLINFO_HTTP_CODE));
        $error = curl_error($ch);
        curl_close($ch);

        return array(
            'status_code' => $statusCode,
            'body' => $response,
            'error' => $error,
        );
    }

    $context = stream_context_create(array(
        'http' => array(
            'method' => 'POST',
            'header' => "Content-Type: application/json\r\n",
            'content' => $body,
            'timeout' => 15,
        ),
    ));

    $response = @file_get_contents($url, false, $context);
    $statusCode = 0;
    if (isset($http_response_header[0]) && preg_match('/\s(\d{3})\s/', $http_response_header[0], $matches)) {
        $statusCode = intval($matches[1]);
    }

    return array(
        'status_code' => $statusCode,
        'body' => $response,
        'error' => $response === false ? 'stream_request_failed' : '',
    );
}

function verifyGoogleToken($idToken)
{
    $firebaseApiKey = 'AIzaSyBw3h3YBMUywHnhSEaGM0TYc6Nj_9LCWfk';
    $lookupUrl = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$firebaseApiKey";
    $response = postJson($lookupUrl, array('idToken' => $idToken));

    if (!empty($response['error']) || intval($response['status_code']) !== 200) {
        return null;
    }

    $decoded = json_decode((string) $response['body'], true);
    if (!is_array($decoded) || empty($decoded['users']) || !is_array($decoded['users'])) {
        return null;
    }

    $user = $decoded['users'][0] ?? null;
    if (!is_array($user)) {
        return null;
    }

    return array(
        'firebase_uid' => trim((string) ($user['localId'] ?? '')),
        'email' => trim((string) ($user['email'] ?? '')),
        'name' => trim((string) ($user['displayName'] ?? '')),
        'photo_url' => trim((string) ($user['photoUrl'] ?? '')),
        'phone' => trim((string) ($user['phoneNumber'] ?? '')),
    );
}

function normalizeGoogleProfile(array $verified, $fallbackFirebaseUid, $fallbackEmail, $fallbackName, $fallbackPhotoUrl, $fallbackPhone)
{
    return array(
        'firebase_uid' => $verified['firebase_uid'] !== '' ? $verified['firebase_uid'] : $fallbackFirebaseUid,
        'email' => $verified['email'] !== '' ? $verified['email'] : $fallbackEmail,
        'name' => $verified['name'] !== '' ? $verified['name'] : $fallbackName,
        'photo_url' => $verified['photo_url'] !== '' ? $verified['photo_url'] : $fallbackPhotoUrl,
        'phone' => $verified['phone'] !== '' ? $verified['phone'] : $fallbackPhone,
    );
}

function buildGoogleUsername($email, $name)
{
    $candidate = trim((string) $name);
    if ($candidate !== '') {
        return $candidate;
    }

    $email = trim((string) $email);
    if ($email !== '' && strpos($email, '@') !== false) {
        return substr($email, 0, strpos($email, '@'));
    }

    return 'google_user';
}

function fetchUserByFirebaseUid(PDO $con, $firebaseUid)
{
    $stmt = $con->prepare("SELECT * FROM users WHERE firebase_uid = ? ORDER BY users_id DESC LIMIT 1");
    $stmt->execute(array($firebaseUid));
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

function fetchUserByEmail(PDO $con, $email)
{
    $stmt = $con->prepare("SELECT * FROM users WHERE users_email = ? ORDER BY users_id DESC LIMIT 1");
    $stmt->execute(array($email));
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

function createGoogleUser(PDO $con, array $profile, $supportsFirebaseUid, $supportsAuthProvider)
{
    $data = array(
        'users_name' => buildGoogleUsername($profile['email'], $profile['name']),
        'users_password' => password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT),
        'password_hashed' => 1,
        'users_email' => $profile['email'],
        'users_phone' => $profile['phone'] !== '' ? $profile['phone'] : null,
        'users_verfiycode' => random_int(10000, 99999),
        'users_approve' => 1,
        'user_role' => 'user',
        'users_image' => $profile['photo_url'] !== '' ? $profile['photo_url'] : null,
    );

    if ($supportsFirebaseUid) {
        $data['firebase_uid'] = $profile['firebase_uid'];
    }
    if ($supportsAuthProvider) {
        $data['auth_provider'] = 'google';
    }

    $count = insertData('users', $data, false);
    if ($count <= 0) {
        return null;
    }

    $userId = intval($con->lastInsertId());
    $stmt = $con->prepare("SELECT * FROM users WHERE users_id = ? LIMIT 1");
    $stmt->execute(array($userId));
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

function updateGoogleUser(PDO $con, array $user, array $profile, $supportsFirebaseUid, $supportsAuthProvider)
{
    $fields = array();
    $params = array();

    if ($profile['name'] !== '' && trim((string) ($user['users_name'] ?? '')) !== $profile['name']) {
        $fields[] = "users_name = ?";
        $params[] = $profile['name'];
    }

    if ($profile['email'] !== '' && trim((string) ($user['users_email'] ?? '')) !== $profile['email']) {
        $fields[] = "users_email = ?";
        $params[] = $profile['email'];
    }

    if ($profile['phone'] !== '' && trim((string) ($user['users_phone'] ?? '')) !== $profile['phone']) {
        $fields[] = "users_phone = ?";
        $params[] = $profile['phone'];
    }

    $currentImage = trim((string) ($user['users_image'] ?? ''));
    $currentImageIsRemote = $currentImage !== '' &&
        (stripos($currentImage, 'http://') === 0 || stripos($currentImage, 'https://') === 0);
    if ($profile['photo_url'] !== '' && ($currentImage === '' || $currentImageIsRemote) && $currentImage !== $profile['photo_url']) {
        $fields[] = "users_image = ?";
        $params[] = $profile['photo_url'];
    }

    if ($supportsFirebaseUid && $profile['firebase_uid'] !== '' && trim((string) ($user['firebase_uid'] ?? '')) !== $profile['firebase_uid']) {
        $fields[] = "firebase_uid = ?";
        $params[] = $profile['firebase_uid'];
    }

    if ($supportsAuthProvider && trim((string) ($user['auth_provider'] ?? '')) !== 'google') {
        $fields[] = "auth_provider = ?";
        $params[] = 'google';
    }

    if ((string) ($user['users_approve'] ?? '0') !== '1') {
        $fields[] = "users_approve = ?";
        $params[] = 1;
    }

    if (empty($fields)) {
        return true;
    }

    $params[] = intval($user['users_id']);
    $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE users_id = ?";
    $stmt = $con->prepare($sql);
    return $stmt->execute($params);
}

if ($idToken === '') {
    googleFailure('GOOGLE_TOKEN_REQUIRED');
}

$verifiedProfile = verifyGoogleToken($idToken);
if ($verifiedProfile === null) {
    googleFailure('INVALID_GOOGLE_TOKEN');
}

$profile = normalizeGoogleProfile(
    $verifiedProfile,
    $fallbackFirebaseUid,
    $fallbackEmail,
    $fallbackName,
    $fallbackPhotoUrl,
    $fallbackPhone
);

if ($profile['email'] === '') {
    googleFailure('GOOGLE_EMAIL_REQUIRED');
}

$supportsFirebaseUid = columnExists($con, 'users', 'firebase_uid');
$supportsAuthProvider = columnExists($con, 'users', 'auth_provider');

$user = null;
if ($supportsFirebaseUid && $profile['firebase_uid'] !== '') {
    $user = fetchUserByFirebaseUid($con, $profile['firebase_uid']);
}

if (!$user) {
    $user = fetchUserByEmail($con, $profile['email']);
}

if ($user) {
    $updated = updateGoogleUser($con, $user, $profile, $supportsFirebaseUid, $supportsAuthProvider);
    if (!$updated) {
        googleFailure('GOOGLE_USER_UPDATE_FAILED');
    }

    $stmt = $con->prepare("SELECT * FROM users WHERE users_id = ? LIMIT 1");
    $stmt->execute(array(intval($user['users_id'])));
    $freshUser = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$freshUser) {
        googleFailure('GOOGLE_USER_NOT_FOUND');
    }

    echo json_encode(array(
        'status' => 'success',
        'message' => 'GOOGLE_LOGIN_SUCCESS',
        'data' => $freshUser,
    ));
    exit;
}

$createdUser = createGoogleUser($con, $profile, $supportsFirebaseUid, $supportsAuthProvider);
if (!$createdUser) {
    googleFailure('GOOGLE_USER_CREATE_FAILED');
}

echo json_encode(array(
    'status' => 'success',
    'message' => 'GOOGLE_ACCOUNT_CREATED',
    'data' => $createdUser,
));
exit;
?>
