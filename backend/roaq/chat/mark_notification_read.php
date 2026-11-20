<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Mark Notification as Read
 * Parameters: notification_id (or call_id for marking all notifications for a call), user_id
 */

$notification_id = intval($_POST['notification_id'] ?? 0);
$call_id = intval($_POST['call_id'] ?? 0);
$user_id = intval($_POST['user_id'] ?? 0);

if ($user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "معرف المستخدم مفقود"]);
    exit;
}

if ($notification_id <= 0 && $call_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "معرف الإشعار أو المكالمة مفقود"]);
    exit;
}

try {
    // ✅ التحقق من أن user_id موجود في قاعدة البيانات
    $user_check = $con->prepare("SELECT users_id FROM users WHERE users_id = ?");
    $user_check->execute([$user_id]);
    if ($user_check->rowCount() == 0) {
        echo json_encode(["status" => "fail", "message" => "المستخدم غير موجود"]);
        exit;
    }

    if ($notification_id > 0) {
        // التحقق من أن الإشعار للمستخدم الحالي
        $check = $con->prepare(
            "SELECT notification_id FROM call_notifications 
             WHERE notification_id = ? AND user_id = ?"
        );
        $check->execute([$notification_id, $user_id]);
        if ($check->rowCount() == 0) {
            echo json_encode(["status" => "fail", "message" => "الإشعار غير موجود أو لا يخصك"]);
            exit;
        }

        // تحديد إشعار واحد
        $stmt = $con->prepare(
            "UPDATE call_notifications 
             SET is_read = 1, read_at = CURRENT_TIMESTAMP 
             WHERE notification_id = :notification_id"
        );

        $stmt->execute([':notification_id' => $notification_id]);

        echo json_encode([
            "status" => "success",
            "message" => "تم توقيع الإشعار كمقروء"
        ]);
    } else if ($call_id > 0) {
        // التحقق من أن المستخدم جزء من المكالمة
        $check = $con->prepare(
            "SELECT call_id FROM call_logs 
             WHERE call_id = ? AND (caller_id = ? OR receiver_id = ?)"
        );
        $check->execute([$call_id, $user_id, $user_id]);
        if ($check->rowCount() == 0) {
            echo json_encode(["status" => "fail", "message" => "المكالمة غير موجودة أو لا تخصك"]);
            exit;
        }

        // تحديد جميع الإشعارات للمكالمة
        $stmt = $con->prepare(
            "UPDATE call_notifications 
             SET is_read = 1, read_at = CURRENT_TIMESTAMP 
             WHERE call_id = :call_id AND user_id = :user_id"
        );

        $stmt->execute([
            ':call_id' => $call_id,
            ':user_id' => $user_id
        ]);

        echo json_encode([
            "status" => "success",
            "message" => "تم توقيع جميع الإشعارات كمقروءة"
        ]);
    }

} catch (Exception $e) {
    error_log("mark_notification_read.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
