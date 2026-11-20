<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * End Call
 * Parameters: call_id, user_id, duration (في الثواني)
 */

$call_id = intval($_POST['call_id'] ?? 0);
$user_id = intval($_POST['user_id'] ?? 0);
$duration = intval($_POST['duration'] ?? 0);

if ($call_id <= 0 || $user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "بيانات غير صحيحة"]);
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

    // الحصول على بيانات المكالمة
    $stmt = $con->prepare(
        "SELECT * FROM call_logs WHERE call_id = :call_id"
    );
    
    $stmt->execute([':call_id' => $call_id]);
    $call = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$call) {
        echo json_encode(["status" => "fail", "message" => "المكالمة غير موجودة"]);
        exit;
    }

    // التحقق من أن المستخدم جزء من المكالمة
    if ($call['caller_id'] != $user_id && $call['receiver_id'] != $user_id) {
        echo json_encode(["status" => "fail", "message" => "لا يمكنك إنهاء هذه المكالمة"]);
        exit;
    }

    // إنهاء المكالمة وحفظ المدة
    $update_stmt = $con->prepare(
        "UPDATE call_logs 
         SET call_status = 'ended', 
             duration = :duration,
             ended_at = CURRENT_TIMESTAMP
         WHERE call_id = :call_id"
    );
    
    $update_stmt->execute([
        ':call_id' => $call_id,
        ':duration' => $duration
    ]);

    // تحديث وقت خروج المشارك
    $stmt_participant = $con->prepare(
        "UPDATE call_participants 
         SET left_at = CURRENT_TIMESTAMP 
         WHERE call_id = :call_id AND user_id = :user_id"
    );
    
    $stmt_participant->execute([
        ':call_id' => $call_id,
        ':user_id' => $user_id
    ]);

    // إضافة إشعار للمستخدم الآخر (إذا كانت المكالمة مقبولة)
    if ($call['call_status'] === 'accepted') {
        $other_user = ($call['caller_id'] === $user_id) ? $call['receiver_id'] : $call['caller_id'];
        
        $stmt_notification = $con->prepare(
            "INSERT INTO call_notifications (call_id, user_id, notification_type) 
             VALUES (:call_id, :user_id, 'call_ended')"
        );
        
        $stmt_notification->execute([
            ':call_id' => $call_id,
            ':user_id' => $other_user
        ]);
    } else if ($call['call_status'] === 'pending') {
        // إذا كانت المكالمة لم تُقبل، أضف إشعار "مكالمة فائتة"
        $stmt_notification = $con->prepare(
            "INSERT INTO call_notifications (call_id, user_id, notification_type) 
             VALUES (:call_id, :user_id, 'call_missed')"
        );
        
        $stmt_notification->execute([
            ':call_id' => $call_id,
            ':user_id' => $call['receiver_id']
        ]);
    }

    echo json_encode([
        "status" => "success",
        "call_id" => $call_id,
        "duration" => $duration,
        "message" => "تم إنهاء المكالمة بنجاح"
    ]);

} catch (Exception $e) {
    error_log("end_call.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
