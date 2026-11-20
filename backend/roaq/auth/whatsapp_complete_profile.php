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
$user = requireUserAuth();
$payload = getRequestPayload();
$fullName = trim((string)($payload['full_name'] ?? $payload['username'] ?? ''));
$locale = trim((string)($payload['locale'] ?? ''));
$marketingOptIn = !empty($payload['marketing_opt_in']) ? 1 : 0;
$fcmToken = trim((string)($payload['fcm_token'] ?? ''));
if (mb_strlen($fullName) < 3) {
    respondJson([
        'status' => 'error',
        'message' => 'Full name must be at least 3 characters',
    ], 400);
}
$imageName = null;
if (isset($_FILES['image']) && !empty($_FILES['image']['name'])) {
    $uploadDir = __DIR__ . '/../uploads/users/img';
    if (!is_dir($uploadDir)) {
        @mkdir($uploadDir, 0775, true);
    }
    $uploaded = imageUpload($uploadDir, 'image');
    if ($uploaded !== 'fail' && $uploaded !== 'empty') {
        $imageName = $uploaded;
    }
}
$fields = [
    'users_name' => $fullName,
    'profile_completed' => 1,
    'users_terms_accepted_at' => date('Y-m-d H:i:s'),
    'users_marketing_opt_in' => $marketingOptIn,
];
if ($locale !== '') {
    $fields['users_locale'] = $locale;
}
if ($imageName !== null) {
    $fields['users_image'] = $imageName;
}
if ($fcmToken !== '') {
    $fields['fcm_token'] = substr($fcmToken, 0, 255);
}
$setParts = [];
$params = [':user_id' => (int)$user['users_id']];
foreach ($fields as $column => $value) {
    $setParts[] = "{$column} = :{$column}";
    $params[":{$column}"] = $value;
}
$stmt = $con->prepare("
    UPDATE users
    SET " . implode(",\n        ", $setParts) . "
    WHERE users_id = :user_id
");
$stmt->execute($params);
$freshStmt = $con->prepare("SELECT * FROM users WHERE users_id = :user_id LIMIT 1");
$freshStmt->execute([':user_id' => (int)$user['users_id']]);
$freshUser = $freshStmt->fetch(PDO::FETCH_ASSOC);
if ($fcmToken !== '') {
    purgeDuplicateUserFcmToken($con, (int)$user['users_id'], $fcmToken);
}
respondJson([
    'status' => 'success',
    'message' => 'Profile completed successfully',
    'user' => userPublicData($freshUser ?: $user),
]);