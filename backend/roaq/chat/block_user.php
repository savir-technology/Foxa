<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Block User
 * Parameters: blocker_id, blocked_id, reason (optional)
 */

$blocker_id = intval($_POST['blocker_id'] ?? 0);
$blocked_id = intval($_POST['blocked_id'] ?? 0);
$reason = trim($_POST['reason'] ?? '');

if ($blocker_id <= 0 || $blocked_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "بيانات غير صحيحة"]);
    exit;
}

if ($blocker_id === $blocked_id) {
    echo json_encode(["status" => "fail", "message" => "لا يمكنك حظر نفسك"]);
    exit;
}

try {
    // التحقق من عدم وجود حظر سابق
    $check_stmt = $con->prepare(
        "SELECT block_id FROM blocked_users 
         WHERE blocker_id = :blocker_id AND blocked_id = :blocked_id"
    );
    
    $check_stmt->execute([
        ':blocker_id' => $blocker_id,
        ':blocked_id' => $blocked_id
    ]);

    if ($check_stmt->rowCount() > 0) {
        echo json_encode(["status" => "fail", "message" => "هذا المستخدم محظور بالفعل"]);
        exit;
    }

    // إلغاء أي مكالمات نشطة
    $cancel_calls = $con->prepare(
        "UPDATE call_logs 
         SET call_status = 'rejected'
         WHERE call_status IN ('pending', 'accepted')
         AND ((caller_id = :blocker_id AND receiver_id = :blocked_id)
              OR (caller_id = :blocked_id AND receiver_id = :blocker_id))"
    );
    
    $cancel_calls->execute([
        ':blocker_id' => $blocker_id,
        ':blocked_id' => $blocked_id
    ]);

    // إضافة الحظر
    $stmt = $con->prepare(
        "INSERT INTO blocked_users (blocker_id, blocked_id, reason) 
         VALUES (:blocker_id, :blocked_id, :reason)"
    );

    $stmt->execute([
        ':blocker_id' => $blocker_id,
        ':blocked_id' => $blocked_id,
        ':reason' => !empty($reason) ? $reason : null
    ]);

    echo json_encode([
        "status" => "success",
        "message" => "تم حظر المستخدم بنجاح"
    ]);

} catch (Exception $e) {
    error_log("block_user.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
