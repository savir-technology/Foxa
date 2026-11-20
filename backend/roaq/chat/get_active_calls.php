<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Get Active Calls for a User
 * Parameters: user_id
 */

$user_id = intval($_POST['user_id'] ?? 0);

if ($user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "معرف المستخدم مفقود"]);
    exit;
}

try {
    // الحصول على المكالمات النشطة
    $stmt = $con->prepare(
        "SELECT 
            cl.call_id,
            cl.caller_id,
            cl.receiver_id,
            cl.call_type,
            cl.call_status,
            cl.started_at,
            cl.call_token,
            caller.users_name AS caller_name,
            caller.users_image AS caller_image,
            receiver.users_name AS receiver_name,
            receiver.users_image AS receiver_image,
            i.items_name_ar AS property_name,
            (SELECT COUNT(*) FROM call_participants WHERE call_id = cl.call_id) AS participants_count
         FROM call_logs cl
         LEFT JOIN users caller ON cl.caller_id = caller.users_id
         LEFT JOIN users receiver ON cl.receiver_id = receiver.users_id
         LEFT JOIN items i ON cl.item_id = i.items_id
         WHERE (cl.caller_id = :user_id OR cl.receiver_id = :user_id)
         AND cl.call_status IN ('pending', 'accepted')
         ORDER BY cl.started_at DESC"
    );

    $stmt->execute([':user_id' => $user_id]);
    $calls = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // الحصول على الإشعارات غير المقروءة
    $notif_stmt = $con->prepare(
        "SELECT COUNT(*) as unread_count FROM call_notifications 
         WHERE user_id = :user_id AND is_read = 0"
    );
    
    $notif_stmt->execute([':user_id' => $user_id]);
    $unread = $notif_stmt->fetch(PDO::FETCH_ASSOC)['unread_count'];

    echo json_encode([
        "status" => "success",
        "data" => $calls,
        "active_calls_count" => count($calls),
        "unread_notifications" => $unread
    ]);

} catch (Exception $e) {
    error_log("get_active_calls.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
