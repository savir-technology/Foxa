<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Params: user_id, property_id, sender_type (user|admin), message, optional file 'attachment'
$user_id = $_POST['user_id'] ?? null;
$property_id = $_POST['property_id'] ?? null;
$sender_type = $_POST['sender_type'] ?? 'user';
$message = $_POST['message'] ?? '';

if (!$user_id || !$property_id) {
    echo json_encode(["status" => "fail", "message" => "missing user_id or property_id"]);
    exit;
}

$attachment_url = null;
if (isset($_FILES['attachment'])) {
    $folder = "../uploads/chat_attachments/";
    if (!file_exists($folder)) mkdir($folder, 0777, true);
    $ext = pathinfo($_FILES['attachment']['name'], PATHINFO_EXTENSION);
    $file_name = time() . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $file_path = $folder . $file_name;
    move_uploaded_file($_FILES['attachment']['tmp_name'], $file_path);
    $attachment_url = "uploads/chat_attachments/" . $file_name;
}

try {
    // 1) Find or create property chat thread
    $stmt = $con->prepare("SELECT chat_id FROM property_chats WHERE property_id = ? AND user_id = ? LIMIT 1");
    $stmt->execute([$property_id, $user_id]);
    $chat = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($chat) {
        $chat_id = $chat['chat_id'];
    } else {
        $ins = $con->prepare("INSERT INTO property_chats (property_id, user_id, initiated_by, created_at) VALUES (?, ?, 'user', current_timestamp())");
        $ins->execute([$property_id, $user_id]);
        $chat_id = $con->lastInsertId();
    }

    // 2) Insert message
    $stmt2 = $con->prepare("INSERT INTO property_chat_messages (chat_id, property_id, sender_id, sender_type, message_content, attachment_url, created_at) VALUES (?, ?, ?, ?, ?, ?, current_timestamp())");
    $ok = $stmt2->execute([$chat_id, $property_id, $user_id, $sender_type, $message, $attachment_url]);

    if (!$ok) throw new Exception('db_insert_failed');

    // 3) Notify recipient via FCM (use existing firebase helper if present)
    if ($sender_type == 'admin') {
        // notify user
        $s = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
        $s->execute([$user_id]);
        $u = $s->fetch(PDO::FETCH_ASSOC);
        if ($u && !empty($u['fcm_token'])) {
            if (file_exists(__DIR__ . "/firebase/send_notification.php")) {
                include __DIR__ . "/firebase/send_notification.php";
                sendFCM("رسالة جديدة بخصوص عقار", $message ?: "تم إرسال مرفق", trim($u['fcm_token']));
            }
        }
    } else {
        // notify support (prefer conect role, fallback admin/crm)
        $s = $con->prepare(
            "SELECT fcm_token
             FROM users
             WHERE user_role IN ('conect', 'admin', 'crm')
               AND users_approve = 1
               AND fcm_token IS NOT NULL
             ORDER BY FIELD(user_role, 'conect', 'admin', 'crm'), users_id ASC
             LIMIT 1"
        );
        $s->execute([]);
        $a = $s->fetch(PDO::FETCH_ASSOC);
        if ($a && !empty($a['fcm_token']) && file_exists(__DIR__ . "/firebase/send_notification.php")) {
            include __DIR__ . "/firebase/send_notification.php";
            sendFCM("مستخدم تواصل بخصوص عقار", $message ?: "تم إرسال مرفق", trim($a['fcm_token']));
        }
    }

    echo json_encode(["status" => "success", "chat_id" => (int)$chat_id]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

?>
