<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Update Call Participant Status (Mute/Camera)
 * Parameters: call_id, user_id, is_muted (optional), is_camera_off (optional)
 */

$call_id = intval($_POST['call_id'] ?? 0);
$user_id = intval($_POST['user_id'] ?? 0);
$is_muted = isset($_POST['is_muted']) ? (int)$_POST['is_muted'] : null;
$is_camera_off = isset($_POST['is_camera_off']) ? (int)$_POST['is_camera_off'] : null;

if ($call_id <= 0 || $user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "بيانات غير صحيحة"]);
    exit;
}

try {
    // التحقق من أن المستخدم مشارك في المكالمة
    $check_stmt = $con->prepare(
        "SELECT participant_id FROM call_participants 
         WHERE call_id = :call_id AND user_id = :user_id"
    );
    
    $check_stmt->execute([
        ':call_id' => $call_id,
        ':user_id' => $user_id
    ]);

    if ($check_stmt->rowCount() === 0) {
        echo json_encode(["status" => "fail", "message" => "أنت لست مشاركاً في هذه المكالمة"]);
        exit;
    }

    // تحديث حالة المشارك
    $update_fields = [];
    $bind_params = [':call_id' => $call_id, ':user_id' => $user_id];

    if ($is_muted !== null) {
        $update_fields[] = "is_muted = :is_muted";
        $bind_params[':is_muted'] = $is_muted;
    }

    if ($is_camera_off !== null) {
        $update_fields[] = "is_camera_off = :is_camera_off";
        $bind_params[':is_camera_off'] = $is_camera_off;
    }

    if (empty($update_fields)) {
        echo json_encode(["status" => "fail", "message" => "لا توجد حقول لتحديثها"]);
        exit;
    }

    $update_query = "UPDATE call_participants SET " . implode(", ", $update_fields) . 
                   " WHERE call_id = :call_id AND user_id = :user_id";
    
    $stmt = $con->prepare($update_query);
    $stmt->execute($bind_params);

    // الحصول على حالة المشاركين الحالية
    $participants_stmt = $con->prepare(
        "SELECT 
            cp.user_id,
            cp.is_muted,
            cp.is_camera_off,
            u.users_name,
            u.users_image
         FROM call_participants cp
         LEFT JOIN users u ON cp.user_id = u.users_id
         WHERE cp.call_id = :call_id"
    );
    
    $participants_stmt->execute([':call_id' => $call_id]);
    $participants = $participants_stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "message" => "تم تحديث الحالة بنجاح",
        "participants" => $participants
    ]);

} catch (Exception $e) {
    error_log("update_call_participant.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
