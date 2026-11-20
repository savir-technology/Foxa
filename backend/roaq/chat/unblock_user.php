<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Unblock User
 * Parameters: blocker_id, blocked_id
 */

$blocker_id = intval($_POST['blocker_id'] ?? 0);
$blocked_id = intval($_POST['blocked_id'] ?? 0);

if ($blocker_id <= 0 || $blocked_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "بيانات غير صحيحة"]);
    exit;
}

try {
    // حذف الحظر
    $stmt = $con->prepare(
        "DELETE FROM blocked_users 
         WHERE blocker_id = :blocker_id AND blocked_id = :blocked_id"
    );

    $stmt->execute([
        ':blocker_id' => $blocker_id,
        ':blocked_id' => $blocked_id
    ]);

    if ($stmt->rowCount() === 0) {
        echo json_encode(["status" => "fail", "message" => "لا يوجد حظر لهذا المستخدم"]);
        exit;
    }

    echo json_encode([
        "status" => "success",
        "message" => "تم إلغاء حظر المستخدم بنجاح"
    ]);

} catch (Exception $e) {
    error_log("unblock_user.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
