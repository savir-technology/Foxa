<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";
require_once __DIR__ . "/firebase/send_notification.php";
require_once __DIR__ . "/../notifications/notification_helper.php";

$user_id = $_POST['user_id'] ?? null;
$sender_type = $_POST['sender_type'] ?? 'user';
$message = $_POST['message'] ?? '';

if ($user_id == null) {
    echo json_encode(["status" => "fail", "message" => "missing user_id"]);
    exit;
}

$audio_url = null;

if (isset($_FILES['audio'])) {
    $folder = dirname(__DIR__) . "/uploads/chat_audio/";
    if (!is_dir($folder)) {
        mkdir($folder, 0777, true);
    }

    $extension = pathinfo($_FILES['audio']['name'] ?? '', PATHINFO_EXTENSION);
    $file_name = time() . ($extension ? '.' . $extension : '.m4a');
    $file_path = $folder . $file_name;
    if (!move_uploaded_file($_FILES['audio']['tmp_name'], $file_path)) {
        echo json_encode(["status" => "fail", "message" => "failed to save audio"]);
        exit;
    }
    $audio_url = "uploads/chat_audio/" . $file_name;
}

$stmt = $con->prepare("INSERT INTO chat_messages (user_id, sender_type, message, audio_url) VALUES (?, ?, ?, ?)");
$success = $stmt->execute([$user_id, $sender_type, $message, $audio_url]);

if ($success) {
    if ($sender_type == 'user') {
        $preview = trim((string)$message);
        if ($preview === '') {
            $preview = 'تم إرسال رسالة صوتية جديدة';
        }

        sendFCMToTopic(
            'رسالة جديدة من مستخدم',
            $preview,
            'admin_chat',
            [
                'type' => 'admin_chat_message',
                'user_id' => (string)$user_id,
                'sender_type' => 'user',
                'screen' => 'chat',
            ]
        );
        notifyMasterWebPush(
            $con,
            'admin_chat_message',
            'رسالة جديدة من مستخدم',
            $preview,
            [
                'user_id' => (string)$user_id,
                'sender_type' => 'user',
                'screen' => 'chat',
            ]
        );
    }

    if ($sender_type == 'admin') {
        notifyUser(
            $con,
            (int)$user_id,
            'admin_chat',
            'رسالة جديدة من الدعم الفني',
            $message ?: 'تم إرسال رسالة صوتية جديدة',
            'chat',
            null,
            [
                'sender_type' => 'admin',
            ],
            true
        );
    }

    echo json_encode(["status" => "success", "message" => "Check debug_fcm_log.txt for details"]);
} else {
    echo json_encode(["status" => "fail"]);
}
?>
