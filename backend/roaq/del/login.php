<?php
include "connect.php";

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $phone = $_POST['phone'] ?? '';
    $password = $_POST['password'] ?? '';

    if (empty($phone) || empty($password)) {
        echo json_encode(["status" => "failed", "message" => "جميع الحقول مطلوبة"]);
        exit();
    }

    // جلب بيانات المستخدم من قاعدة البيانات
    $stmt = $con->prepare("SELECT * FROM delivery_users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user && password_verify($password, $user['password'])) {
        echo json_encode(["status" => "success", "message" => "تم تسجيل الدخول بنجاح", "user_id" => $user['id']]);
    } else {
        echo json_encode(["status" => "failed", "message" => "رقم الهاتف أو كلمة المرور غير صحيحة"]);
    }
} else {
    echo json_encode(["status" => "failed", "message" => "يجب استخدام طلب POST"]);
}
?>
