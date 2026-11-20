<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterSupportFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterSupportRequireSchema(): void
{
    $requiredColumns = ['id', 'user_id', 'sender_type', 'message', 'audio_url', 'timestamp'];
    if (!tableExists('chat_messages')) {
        masterSupportFail('جدول محادثات الدعم غير موجود. طبّق migration 20260818_master_chat_tables.sql أولًا.', 409);
    }
    foreach ($requiredColumns as $column) {
        if (!columnExists('chat_messages', $column)) {
            masterSupportFail('بنية محادثات الدعم غير مكتملة. طبّق migration 20260818_master_chat_tables.sql أولًا.', 409);
        }
    }
}

function masterSupportRows(string $sql, array $params = []): array
{
    global $con;
    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

function masterSupportScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $value = $stmt->fetchColumn();
    return $value === false || $value === null ? $fallback : $value;
}

function masterSupportPreview(array $row): string
{
    $message = trim((string)($row['message'] ?? ''));
    if ($message !== '') {
        return $message;
    }
    return trim((string)($row['audio_url'] ?? '')) !== '' ? 'رسالة صوتية' : 'لا توجد رسائل بعد';
}

function masterSupportTime(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '--:--' : date('H:i', $timestamp);
}

function masterSupportRelative(?string $value): string
{
    $timestamp = strtotime((string)$value);
    if ($timestamp === false) {
        return 'الآن';
    }
    $seconds = max(0, time() - $timestamp);
    if ($seconds < 60) {
        return 'منذ دقيقة';
    }
    $minutes = (int)floor($seconds / 60);
    if ($minutes < 60) {
        return 'منذ ' . $minutes . ' دقيقة';
    }
    $hours = (int)floor($minutes / 60);
    if ($hours < 24) {
        return 'منذ ' . $hours . ' ساعة';
    }
    return date('Y-m-d', $timestamp);
}

function masterSupportAssetUrl($value): string
{
    $text = trim((string)$value);
    if ($text === '') {
        return '';
    }
    if (preg_match('/^https?:\/\//i', $text)) {
        return $text;
    }
    return 'https://savir-technology.online/roaqv2/' . ltrim($text, '/');
}

function masterSupportConversation(array $row): array
{
    $name = trim((string)($row['users_name'] ?? ''));
    if ($name === '') {
        $name = 'عميل #' . (int)$row['user_id'];
    }
    $lastAdminAt = $row['last_admin_at'] ?? null;
    return [
        'user_id' => (int)$row['user_id'],
        'customer_name' => $name,
        'customer_phone' => (string)($row['users_phone'] ?? ''),
        'customer_email' => (string)($row['users_email'] ?? ''),
        'customer_image_url' => masterSupportAssetUrl($row['users_image'] ?? ''),
        'last_message' => masterSupportPreview($row),
        'last_sender_type' => (string)($row['sender_type'] ?? ''),
        'last_message_time' => $row['timestamp'] ?? null,
        'time_label' => masterSupportTime($row['timestamp'] ?? null),
        'relative_label' => masterSupportRelative($row['timestamp'] ?? null),
        'total_messages' => (int)($row['total_messages'] ?? 0),
        'unread_for_admin' => (int)($row['unread_for_admin'] ?? 0),
        'last_admin_at' => $lastAdminAt,
    ];
}

function masterSupportMessages(int $userId): array
{
    $rows = masterSupportRows("
        SELECT id, user_id, sender_type, message, audio_url, timestamp
        FROM chat_messages
        WHERE user_id = :user_id
        ORDER BY timestamp ASC, id ASC
        LIMIT 180
    ", [':user_id' => $userId]);

    $messages = [];
    foreach ($rows as $row) {
        $sender = strtolower(trim((string)($row['sender_type'] ?? '')));
        $messages[] = [
            'id' => (int)$row['id'],
            'user_id' => (int)$row['user_id'],
            'sender_type' => $sender,
            'sender_name' => $sender === 'admin' ? 'الدعم الفني' : 'العميل',
            'message' => (string)($row['message'] ?? ''),
            'audio_url' => masterSupportAssetUrl($row['audio_url'] ?? ''),
            'timestamp' => $row['timestamp'] ?? null,
            'time_label' => masterSupportTime($row['timestamp'] ?? null),
            'relative_label' => masterSupportRelative($row['timestamp'] ?? null),
        ];
    }
    return $messages;
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, $_SERVER['REQUEST_METHOD'] === 'POST' ? 'support.reply' : 'support.view');
    masterSupportRequireSchema();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $payload = json_decode(file_get_contents('php://input') ?: '{}', true);
        if (!is_array($payload) || !$payload) {
            $payload = $_POST;
        }

        $userId = (int)($payload['user_id'] ?? $_POST['user_id'] ?? 0);
        $message = trim((string)($payload['message'] ?? $_POST['message'] ?? ''));
        if ($userId <= 0) {
            masterSupportFail('user_id is required');
        }

        $audioUrl = null;
        if (isset($_FILES['audio']) && is_array($_FILES['audio'])) {
            if ((int)($_FILES['audio']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
                masterSupportFail('audio upload failed');
            }
            $size = (int)($_FILES['audio']['size'] ?? 0);
            if ($size <= 0 || $size > 8 * 1024 * 1024) {
                masterSupportFail('audio file must be less than 8MB');
            }
            $original = (string)($_FILES['audio']['name'] ?? 'voice.m4a');
            $ext = strtolower(pathinfo($original, PATHINFO_EXTENSION));
            $allowed = ['mp3', 'm4a', 'wav', 'ogg', 'aac', 'webm'];
            if (!in_array($ext, $allowed, true)) {
                masterSupportFail('unsupported audio type');
            }
            $root = dirname(__DIR__, 3);
            $relativeDir = 'uploads/chat_audio';
            $targetDir = $root . DIRECTORY_SEPARATOR . $relativeDir;
            if (!is_dir($targetDir) && !mkdir($targetDir, 0775, true) && !is_dir($targetDir)) {
                masterSupportFail('could not create audio directory', 500);
            }
            $fileName = 'support_admin_' . $userId . '_' . time() . '_' . random_int(1000, 9999) . '.' . $ext;
            $targetPath = $targetDir . DIRECTORY_SEPARATOR . $fileName;
            if (!move_uploaded_file((string)$_FILES['audio']['tmp_name'], $targetPath)) {
                masterSupportFail('could not save audio file', 500);
            }
            $audioUrl = $relativeDir . '/' . $fileName;
        }

        if ($message === '' && $audioUrl === null) {
            masterSupportFail('message or audio is required');
        }

        $stmt = $con->prepare("
            INSERT INTO chat_messages (user_id, sender_type, message, audio_url)
            VALUES (:user_id, 'admin', :message, :audio_url)
        ");
        $stmt->execute([
            ':user_id' => $userId,
            ':message' => $message,
            ':audio_url' => $audioUrl,
        ]);
        $messageId = (int)$con->lastInsertId();

        $notificationAttempted = false;
        $notificationError = null;
        $helper = __DIR__ . "/../../../notifications/notification_helper.php";
        if (file_exists($helper)) {
            require_once $helper;
        }
        if (function_exists('notifyUser')) {
            try {
                $notificationAttempted = true;
                notifyUser(
                    $con,
                    $userId,
                    'admin_chat',
                    'رسالة جديدة من الدعم الفني',
                    $message !== '' ? $message : 'تم إرسال رسالة صوتية جديدة',
                    'chat',
                    null,
                    [
                        'sender_type' => 'admin',
                        'message_id' => (string)$messageId,
                        'screen' => 'chat',
                    ],
                    true
                );
            } catch (Throwable $notifyError) {
                $notificationError = $notifyError->getMessage();
            }
        }

        respondJson([
            'status' => 'success',
            'message' => 'sent',
            'data' => [
                'message_id' => $messageId,
                'user_id' => $userId,
                'messages' => masterSupportMessages($userId),
            ],
            'notification' => [
                'attempted' => $notificationAttempted,
                'error' => $notificationError,
            ],
        ]);
    }

    $query = trim((string)($_GET['q'] ?? ''));
    $selectedUserId = (int)($_GET['user_id'] ?? 0);

    $params = [];
    $where = '1 = 1';
    if ($query !== '') {
        $where = "(CAST(latest.user_id AS CHAR) LIKE :q OR u.users_name LIKE :q OR u.users_phone LIKE :q OR u.users_email LIKE :q OR latest.message LIKE :q)";
        $params[':q'] = '%' . $query . '%';
    }

    $conversations = masterSupportRows("
        SELECT
            latest.id,
            latest.user_id,
            latest.sender_type,
            latest.message,
            latest.audio_url,
            latest.timestamp,
            u.users_name,
            u.users_phone,
            u.users_email,
            u.users_image,
            counts.total_messages,
            counts.last_admin_at,
            counts.unread_for_admin
        FROM chat_messages latest
        INNER JOIN (
            SELECT user_id, MAX(id) AS latest_id
            FROM chat_messages
            GROUP BY user_id
        ) ids ON ids.latest_id = latest.id
        LEFT JOIN users u ON u.users_id = latest.user_id
        LEFT JOIN (
            SELECT
                cm.user_id,
                COUNT(*) AS total_messages,
                MAX(CASE WHEN cm.sender_type = 'admin' THEN cm.timestamp ELSE NULL END) AS last_admin_at,
                SUM(CASE
                    WHEN cm.sender_type = 'user'
                     AND cm.timestamp > COALESCE((
                        SELECT MAX(admin_msg.timestamp)
                        FROM chat_messages admin_msg
                        WHERE admin_msg.user_id = cm.user_id
                          AND admin_msg.sender_type = 'admin'
                     ), '1970-01-01 00:00:00')
                    THEN 1 ELSE 0 END
                ) AS unread_for_admin
            FROM chat_messages cm
            GROUP BY cm.user_id
        ) counts ON counts.user_id = latest.user_id
        WHERE $where
        ORDER BY latest.timestamp DESC, latest.id DESC
        LIMIT 120
    ", $params);

    $conversationData = array_map('masterSupportConversation', $conversations);
    if ($selectedUserId <= 0 && count($conversationData) > 0) {
        $selectedUserId = (int)$conversationData[0]['user_id'];
    }

    $messages = $selectedUserId > 0 ? masterSupportMessages($selectedUserId) : [];
    $total = (int)masterSupportScalar("SELECT COUNT(DISTINCT user_id) FROM chat_messages", [], 0);
    $today = (int)masterSupportScalar("SELECT COUNT(*) FROM chat_messages WHERE DATE(timestamp) = CURDATE()", [], 0);
    $unread = 0;
    foreach ($conversationData as $conversation) {
        $unread += (int)$conversation['unread_for_admin'];
    }

    respondJson([
        'status' => 'success',
        'data' => [
            'server_now' => date('c'),
            'selected_user_id' => $selectedUserId,
            'stats' => [
                'total_conversations' => $total,
                'visible_conversations' => count($conversationData),
                'unread_messages' => $unread,
                'today_messages' => $today,
            ],
            'conversations' => $conversationData,
            'messages' => $messages,
        ],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
