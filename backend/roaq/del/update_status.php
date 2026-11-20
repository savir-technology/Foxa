<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $driver_id = $_POST['driver_id'] ?? '';
    $status = $_POST['status'] ?? '';

    if (empty($driver_id) || empty($status) || !in_array($status, ['online', 'offline'], true)) {
        echo json_encode([
            "status" => "failed",
            "message" => "جميع الحقول مطلوبة أو الحالة غير صحيحة",
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $stmt = $con->prepare("
        UPDATE delivery_users
        SET status = ?,
            last_seen_at = NOW()
        WHERE id = ?
    ");
    $result = $stmt->execute([$status, $driver_id]);

    if ($result) {
        echo json_encode([
            "status" => "success",
            "message" => "تم تحديث الحالة بنجاح",
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            "status" => "failed",
            "message" => "فشل في تحديث الحالة",
        ], JSON_UNESCAPED_UNICODE);
    }
} else {
    echo json_encode([
        "status" => "failed",
        "message" => "يجب استخدام طلب POST",
    ], JSON_UNESCAPED_UNICODE);
}
?>
