<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";
require_once "../notifications/notification_service.php";

function resolveSupportUserId(PDO $con): int
{
    // Force a single support owner for all chats.
    $fixedSupportUserId = 89;
    $stmt = $con->prepare(
        "SELECT users_id
         FROM users
         WHERE users_id = :id
           AND users_approve = 1
         LIMIT 1"
    );
    $stmt->execute([':id' => $fixedSupportUserId]);
    return intval($stmt->fetchColumn() ?: 0);
}

$chat_id = intval($_POST['chat_id'] ?? 0);
$user_id = intval($_POST['user_id'] ?? 0);
$item_id = intval($_POST['item_id'] ?? 0);
$sender_type = strtolower(trim((string) ($_POST['sender_type'] ?? 'user')));
$message = trim((string) ($_POST['message'] ?? ''));

if (!in_array($sender_type, ['user', 'admin'], true)) {
    $sender_type = 'user';
}

if ($user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "Missing user_id"]);
    exit;
}

try {
    if ($chat_id > 0) {
        $chatMetaStmt = $con->prepare("SELECT item_id FROM chats WHERE id = :id LIMIT 1");
        $chatMetaStmt->execute([':id' => $chat_id]);
        $chatMeta = $chatMetaStmt->fetch(PDO::FETCH_ASSOC);
        if (!$chatMeta) {
            echo json_encode(["status" => "fail", "message" => "Invalid chat_id"]);
            exit;
        }
        $chatItemId = intval($chatMeta['item_id'] ?? 0);
        if ($chatItemId <= 0) {
            echo json_encode(["status" => "fail", "message" => "Chat is not linked to item"]);
            exit;
        }
        $item_id = $chatItemId;
    }

    if ($chat_id <= 0) {
        if ($item_id <= 0) {
            echo json_encode(["status" => "fail", "message" => "Missing item_id"]);
            exit;
        }
        if ($sender_type === 'admin') {
            echo json_encode(["status" => "fail", "message" => "Admin media requires chat_id"]);
            exit;
        }
        $adminUserId = resolveSupportUserId($con);
        if ($adminUserId <= 0) {
            echo json_encode(["status" => "fail", "message" => "No active admin user found"]);
            exit;
        }

        $find_stmt = $con->prepare(
            "SELECT id
             FROM chats
             WHERE item_id = :item_id AND user_id = :user_id
             ORDER BY (other_user_id = :other_user_id) DESC, id DESC
             LIMIT 1"
        );
        $find_stmt->execute([
            ':item_id' => $item_id,
            ':user_id' => $user_id,
            ':other_user_id' => $adminUserId,
        ]);
        $row = $find_stmt->fetch(PDO::FETCH_ASSOC);
        if ($row) {
            $chat_id = intval($row['id']);
            $reassignStmt = $con->prepare(
                "UPDATE chats
                 SET other_user_id = :other_user_id,
                     updated_at = NOW()
                 WHERE id = :chat_id"
            );
            $reassignStmt->execute([
                ':other_user_id' => $adminUserId,
                ':chat_id' => $chat_id,
            ]);
        } else {
            $create_stmt = $con->prepare(
                "INSERT INTO chats (item_id, user_id, other_user_id, lead_status, created_at, updated_at)
                 VALUES (:item_id, :user_id, :other_user_id, 'interested', NOW(), NOW())"
            );
            $create_stmt->execute([
                ':item_id' => $item_id,
                ':user_id' => $user_id,
                ':other_user_id' => $adminUserId,
            ]);
            $chat_id = intval($con->lastInsertId());
        }
    }

    if ($chat_id <= 0) {
        echo json_encode(["status" => "fail", "message" => "Missing chat_id"]);
        exit;
    }

    $media_url = null;
    $media_type = 'text';
    $file_type = null;
    $file_size = null;
    $mime_type = null;
    $audio_url = null;
    $image_url = null;
    $file_url = null;
    $original_file_name = null;

    if (!empty($_FILES['image']['tmp_name'])) {
        $image = $_FILES['image'];
        $ext = strtolower(pathinfo($image['name'], PATHINFO_EXTENSION));
        $allowed = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        if (!in_array($ext, $allowed, true)) {
            echo json_encode(["status" => "fail", "message" => "Unsupported image type"]);
            exit;
        }
        if ($image['size'] > 10 * 1024 * 1024) {
            echo json_encode(["status" => "fail", "message" => "Image too large (max 10MB)"]);
            exit;
        }
        $folder = "../uploads/chat_images/";
        if (!file_exists($folder)) {
            mkdir($folder, 0777, true);
        }
        $file_name = uniqid('img_') . '.' . $ext;
        if (!move_uploaded_file($image['tmp_name'], $folder . $file_name)) {
            echo json_encode(["status" => "error", "message" => "Failed to upload image"]);
            exit;
        }
        $image_url = "uploads/chat_images/" . $file_name;
        $media_url = $image_url;
        $media_type = 'image';
        $mime_type = $image['type'];
        $file_size = intval($image['size']);
        $original_file_name = $image['name'];
    } elseif (!empty($_FILES['file']['tmp_name'])) {
        $file = $_FILES['file'];
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $allowed = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'rar'];
        if (!in_array($ext, $allowed, true)) {
            echo json_encode(["status" => "fail", "message" => "Unsupported file type"]);
            exit;
        }
        if ($file['size'] > 50 * 1024 * 1024) {
            echo json_encode(["status" => "fail", "message" => "File too large (max 50MB)"]);
            exit;
        }
        $folder = "../uploads/chat_files/";
        if (!file_exists($folder)) {
            mkdir($folder, 0777, true);
        }
        $file_name = uniqid('file_') . '.' . $ext;
        if (!move_uploaded_file($file['tmp_name'], $folder . $file_name)) {
            echo json_encode(["status" => "error", "message" => "Failed to upload file"]);
            exit;
        }
        $file_url = "uploads/chat_files/" . $file_name;
        $media_url = $file_url;
        $media_type = 'file';
        $file_type = $ext;
        $mime_type = $file['type'];
        $file_size = intval($file['size']);
        $original_file_name = $file['name'];
    } elseif (!empty($_FILES['audio']['tmp_name'])) {
        $audio = $_FILES['audio'];
        $ext = strtolower(pathinfo($audio['name'], PATHINFO_EXTENSION));
        $allowed = ['mp3', 'm4a', 'wav', 'aac', 'ogg'];
        if (!in_array($ext, $allowed, true)) {
            echo json_encode(["status" => "fail", "message" => "Unsupported audio type"]);
            exit;
        }
        if ($audio['size'] > 25 * 1024 * 1024) {
            echo json_encode(["status" => "fail", "message" => "Audio too large (max 25MB)"]);
            exit;
        }
        $folder = "../uploads/chat_audio/";
        if (!file_exists($folder)) {
            mkdir($folder, 0777, true);
        }
        $file_name = uniqid('audio_') . '.' . $ext;
        if (!move_uploaded_file($audio['tmp_name'], $folder . $file_name)) {
            echo json_encode(["status" => "error", "message" => "Failed to upload audio"]);
            exit;
        }
        $audio_url = "uploads/chat_audio/" . $file_name;
        $media_url = $audio_url;
        $media_type = 'audio';
        $mime_type = $audio['type'];
        $file_size = intval($audio['size']);
        $original_file_name = $audio['name'];
    } else {
        if ($message === '') {
            echo json_encode(["status" => "fail", "message" => "Message or media is required"]);
            exit;
        }
    }

    $stmt = $con->prepare(
        "INSERT INTO chat_messages (
            chat_id, user_id, item_id, sender_type, message,
            audio_url, image_url, file_url, file_type, media_type
        ) VALUES (
            :chat_id, :user_id, :item_id, :sender_type, :message,
            :audio_url, :image_url, :file_url, :file_type, :media_type
        )"
    );
    $stmt->execute([
        ':chat_id' => $chat_id,
        ':user_id' => $user_id,
        ':item_id' => $item_id > 0 ? $item_id : null,
        ':sender_type' => $sender_type,
        ':message' => $message,
        ':audio_url' => $audio_url,
        ':image_url' => $image_url,
        ':file_url' => $file_url,
        ':file_type' => $file_type,
        ':media_type' => $media_type,
    ]);

    $message_id = intval($con->lastInsertId());

    if ($media_url && $message_id > 0) {
        $mediaStmt = $con->prepare(
            "INSERT INTO chat_media (
                message_id, user_id, item_id, media_url, media_type, file_name, file_size, mime_type
            ) VALUES (
                :message_id, :user_id, :item_id, :media_url, :media_type, :file_name, :file_size, :mime_type
            )"
        );
        $mediaStmt->execute([
            ':message_id' => $message_id,
            ':user_id' => $user_id,
            ':item_id' => $item_id > 0 ? $item_id : null,
            ':media_url' => $media_url,
            ':media_type' => $media_type,
            ':file_name' => $original_file_name,
            ':file_size' => $file_size,
            ':mime_type' => $mime_type,
        ]);
    }

    $preview = $message !== '' ? $message : ($media_type === 'image' ? 'صورة' : ($media_type === 'file' ? 'ملف' : 'رسالة صوتية'));
    $preview = mb_substr($preview, 0, 100, 'UTF-8');

    $updateSql = $sender_type === 'admin'
        ? "UPDATE chats
           SET last_message = :last_message,
               last_message_time = NOW(),
               updated_at = NOW(),
               unread_count = 0
           WHERE id = :chat_id"
        : "UPDATE chats
           SET last_message = :last_message,
               last_message_time = NOW(),
               updated_at = NOW(),
               unread_count = unread_count + 1
           WHERE id = :chat_id";
    $updateStmt = $con->prepare($updateSql);
    $updateStmt->execute([
        ':last_message' => $preview,
        ':chat_id' => $chat_id,
    ]);

    if ($sender_type === 'admin') {
        $chatStmt = $con->prepare("SELECT user_id, item_id FROM chats WHERE id = :id LIMIT 1");
        $chatStmt->execute([':id' => $chat_id]);
        $chatRow = $chatStmt->fetch(PDO::FETCH_ASSOC);
        if ($chatRow) {
            $targetUser = intval($chatRow['user_id'] ?? 0);
            $targetItem = intval($chatRow['item_id'] ?? 0);
            if ($targetUser > 0) {
                notifyUser(
                    $targetUser,
                    'رسالة جديدة من المطور',
                    $preview,
                    'chat',
                    [
                        'chat_id' => $chat_id,
                        'item_id' => $targetItem,
                        'message_id' => $message_id,
                        'media_type' => $media_type,
                    ],
                    'admin_media_msg_' . $message_id
                );
            }
        }
    }

    echo json_encode([
        "status" => "success",
        "chat_id" => $chat_id,
        "message_id" => $message_id,
        "media_type" => $media_type,
        "media_url" => $media_url,
        "message" => "Message sent successfully",
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log("upload_media.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
