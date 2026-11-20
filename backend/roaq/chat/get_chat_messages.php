<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Get Chat Messages with Media (Files, Images, Audio)
 * 
 * المعاملات:
 * - chat_id: معرف الدردشة
 * - limit (اختياري): عدد الرسائل المطلوبة (افتراضي: 50)
 * - offset (اختياري): الإزاحة (افتراضي: 0)
 * 
 * للتوافقية مع الكود القديم، يمكن استخدام:
 * - user_id و item_id بدل chat_id
 */

$chat_id = intval($_POST['chat_id'] ?? 0);
$user_id = intval($_POST['user_id'] ?? 0);
$item_id = intval($_POST['item_id'] ?? 0);
$limit = intval($_POST['limit'] ?? 50);
$offset = intval($_POST['offset'] ?? 0);

// 🔄 إذا لم يأتِ chat_id، ابحث عن شات من user_id و item_id (قديم)
if ($chat_id <= 0 && $user_id > 0 && $item_id > 0) {
    $chat_search = $con->prepare(
        "SELECT id FROM chats 
         WHERE item_id = :item_id AND user_id = :user_id 
         LIMIT 1"
    );
    $chat_search->execute([':item_id' => $item_id, ':user_id' => $user_id]);
    $chat_row = $chat_search->fetch(PDO::FETCH_ASSOC);
    $chat_id = $chat_row['id'] ?? 0;
}

if ($chat_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "معرف الدردشة مفقود"]);
    exit;
}

$limit = min($limit, 100);
$offset = max($offset, 0);

try {
    $stmt = $con->prepare(
        "SELECT 
            cm.id,
            cm.chat_id,
            cm.user_id,
            cm.sender_type,
            cm.message,
            cm.audio_url,
            cm.image_url,
            cm.file_url,
            cm.file_type,
            cm.media_type,
            cm.timestamp,
            UNIX_TIMESTAMP(cm.timestamp) AS timestamp_ts,
            u.users_name,
            u.users_image,
            i.items_name_ar AS property_name,
            (SELECT COUNT(*) FROM chat_media WHERE message_id = cm.id) AS media_count
         FROM chat_messages cm
         LEFT JOIN users u ON cm.user_id = u.users_id
         LEFT JOIN items i ON cm.item_id = i.items_id
         WHERE cm.chat_id = :chat_id
         ORDER BY cm.timestamp ASC
         LIMIT :limit OFFSET :offset"
    );

    $stmt->bindValue(':chat_id', $chat_id, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // جلب تفاصيل الوسائط
    foreach ($messages as &$msg) {
        if ($msg['media_count'] > 0) {
            $media_stmt = $con->prepare(
                "SELECT * FROM chat_media WHERE message_id = :message_id"
            );
            $media_stmt->execute([':message_id' => $msg['id']]);
            $msg['media'] = $media_stmt->fetchAll(PDO::FETCH_ASSOC);
        } else {
            $msg['media'] = [];
        }
    }
    echo json_encode([
        "status" => "success",
        "data" => $messages
    ]);

} catch (Exception $e) {
    error_log("get_chat_messages.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
