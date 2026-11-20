<?php
include "../connect.php";

$user_id = filterRequest("user_id");

if (!$user_id) {
    echo json_encode(["status" => "error", "message" => "Missing user_id"]);
    exit;
}

try {
    // حذف جميع الرسائل الخاصة بالمستخدم
    $stmt = $con->prepare("DELETE FROM chat_messages WHERE user_id = ?");
    $stmt->execute([$user_id]);

    if ($stmt->rowCount() > 0) {
        echo json_encode(["status" => "success", "message" => "Chat deleted successfully"]);
    } else {
        echo json_encode(["status" => "empty", "message" => "No chat found for this user"]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
