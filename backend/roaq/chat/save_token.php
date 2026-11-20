<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";
require_once __DIR__ . '/../notifications/fcm_token_utils.php';

// ✅ استقبال البيانات
$user_id = $_POST['user_id'] ?? null;
$fcm_token = trim((string)($_POST['fcm_token'] ?? ''));

if (!$user_id || !$fcm_token) {
    echo json_encode([
        "status" => "fail",
        "message" => "missing parameters"
    ]);
    exit;
}

// ✅ تحقق من وجود المستخدم
$stmt = $con->prepare("SELECT * FROM users WHERE users_id = ?");
$stmt->execute([$user_id]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    echo json_encode([
        "status" => "fail",
        "message" => "user not found"
    ]);
    exit;
}

// ✅ تحديث أو حفظ التوكن في جدول المستخدمين
$update = $con->prepare("UPDATE users SET fcm_token = ? WHERE users_id = ?");
$success = $update->execute([substr($fcm_token, 0, 255), $user_id]);

if ($success) {
    purgeDuplicateUserFcmToken($con, (int)$user_id, $fcm_token);
    echo json_encode([
        "status" => "success",
        "message" => "token updated successfully",
        "user_id" => $user_id,
        "token" => $fcm_token
    ]);
} else {
    echo json_encode([
        "status" => "fail",
        "message" => "database error"
    ]);
}
?>
