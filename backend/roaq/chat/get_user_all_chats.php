<?php
/**
 * get_user_all_chats.php
 * 
 * الهدف: جلب كل دردشات المستخدم
 * مثل واتساب - قائمة الدردشات
 * 
 * المدخلات:
 * - user_id: معرف المستخدم
 * 
 * المخرجات:
 * - قائمة بكل الدردشات مع:
 *   - property_name: اسم العقار
 *   - property_image: صورة العقار
 *   - last_message: آخر رسالة
 *   - last_message_time: وقت آخر رسالة
 *   - unread_count: عدد الرسائل غير المقروءة
 */

header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

try {
    $user_id = intval($_POST['user_id'] ?? 0);

    if ($user_id <= 0) {
        throw new Exception("معرف المستخدم مفقود");
    }

    $stmt = $con->prepare(
        "SELECT 
            c.id AS chat_id,
            c.item_id,
            c.other_user_id,
            c.last_message,
            c.last_message_time,
            UNIX_TIMESTAMP(c.last_message_time) AS last_message_ts,
            c.unread_count,
            c.created_at,
            UNIX_TIMESTAMP(c.created_at) AS created_at_ts,
            c.updated_at,
            UNIX_TIMESTAMP(c.updated_at) AS updated_at_ts,
            i.items_name_ar AS property_name,
            i.items_name_en AS property_name_en,
            i.items_image AS property_image,
            i.items_price,
            u.users_name AS other_user_name,
            u.users_image AS other_user_image
         FROM chats c
         LEFT JOIN items i ON c.item_id = i.items_id
         LEFT JOIN users u ON c.other_user_id = u.users_id
         WHERE c.user_id = :user_id AND c.is_active = 1
         ORDER BY c.updated_at DESC"
    );

    $stmt->execute([':user_id' => $user_id]);
    $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($chats as &$chat) {
        $chat['unread_count'] = intval($chat['unread_count'] ?? 0);
    }
    unset($chat);

    echo json_encode([
        "status" => "success",
        "data" => $chats,
        "count" => count($chats)
    ]);

} catch (Exception $e) {
    error_log("get_user_all_chats.php error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
