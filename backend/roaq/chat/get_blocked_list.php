<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Get Blocked Users List
 * Parameters: user_id
 */

$user_id = intval($_POST['user_id'] ?? 0);

if ($user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "معرف المستخدم مفقود"]);
    exit;
}

try {
    $stmt = $con->prepare(
        "SELECT 
            bu.block_id,
            bu.blocked_id,
            bu.reason,
            bu.blocked_at,
            u.users_name,
            u.users_image,
            u.users_phone
         FROM blocked_users bu
         LEFT JOIN users u ON bu.blocked_id = u.users_id
         WHERE bu.blocker_id = :user_id
         ORDER BY bu.blocked_at DESC"
    );

    $stmt->execute([':user_id' => $user_id]);
    $blocked = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $blocked,
        "count" => count($blocked)
    ]);

} catch (Exception $e) {
    error_log("get_blocked_list.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
