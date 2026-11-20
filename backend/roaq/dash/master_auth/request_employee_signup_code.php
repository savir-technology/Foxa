<?php
include "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $stmt = $con->query("SELECT admin_id, admin_email FROM admin WHERE admin_role_id = 1 LIMIT 1");
    $owner = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$owner) {
        respondJson(['status' => 'error', 'message' => 'لا يوجد بريد للماستر الأساسي'], 404);
    }

    $code = generateOtpCode(6);
    $expiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));
    $update = $con->prepare("UPDATE admin SET admin_reset_code = :code, admin_reset_expires_at = :expires_at WHERE admin_id = :admin_id");
    $update->execute([
        ':code' => $code,
        ':expires_at' => $expiresAt,
        ':admin_id' => $owner['admin_id'],
    ]);

    if (!sendEmailWithFallback($owner['admin_email'], 'Jeeb Master Employee Signup Code', "رمز السماح بإنشاء حساب موظف: $code")) {
        throw new RuntimeException('تعذر إرسال كود التحقق إلى بريد الماستر');
    }

    respondJson([
        'status' => 'success',
        'message' => 'تم إرسال كود التحقق إلى بريد الماستر الأساسي',
        'email' => $owner['admin_email'],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
