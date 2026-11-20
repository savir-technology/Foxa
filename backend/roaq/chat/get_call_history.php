<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Get Call History for a User
 * Parameters: user_id, limit (optional), offset (optional)
 */

$user_id = intval($_POST['user_id'] ?? 0);
$limit = intval($_POST['limit'] ?? 20);
$offset = intval($_POST['offset'] ?? 0);

if ($user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "معرف المستخدم مفقود"]);
    exit;
}

// التحقق من الحدود المعقولة
$limit = min($limit, 100);
$offset = max($offset, 0);

try {
    $stmt = $con->prepare(
        "SELECT 
            cl.call_id,
            cl.caller_id,
            cl.receiver_id,
            cl.call_type,
            cl.call_status,
            cl.duration,
            cl.started_at,
            cl.ended_at,
            caller.users_name AS caller_name,
            caller.users_image AS caller_image,
            receiver.users_name AS receiver_name,
            receiver.users_image AS receiver_image,
            i.items_name_ar AS property_name
         FROM call_logs cl
         LEFT JOIN users caller ON cl.caller_id = caller.users_id
         LEFT JOIN users receiver ON cl.receiver_id = receiver.users_id
         LEFT JOIN items i ON cl.item_id = i.items_id
         WHERE cl.caller_id = :user_id OR cl.receiver_id = :user_id
         ORDER BY cl.started_at DESC
         LIMIT :limit OFFSET :offset"
    );

    $stmt->bindValue(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $calls = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // الحصول على عدد المكالمات الكلي
    $count_stmt = $con->prepare(
        "SELECT COUNT(*) as total FROM call_logs 
         WHERE caller_id = :user_id OR receiver_id = :user_id"
    );
    
    $count_stmt->execute([':user_id' => $user_id]);
    $total = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];

    echo json_encode([
        "status" => "success",
        "data" => $calls,
        "total" => $total,
        "count" => count($calls)
    ]);

} catch (Exception $e) {
    error_log("get_call_history.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
