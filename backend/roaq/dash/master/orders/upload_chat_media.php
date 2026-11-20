<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterOrderMediaFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterOrderMediaRequireSchema(): void
{
    $requiredColumns = [
        'chat_id',
        'order_id',
        'chat_scope',
        'sender_role',
        'sender_ref_id',
        'message',
        'audio_url',
        'is_read',
        'created_at',
    ];
    if (!tableExists('order_chat_messages')) {
        masterOrderMediaFail('جدول محادثات الطلبات غير موجود. طبّق migration 20260818_master_chat_tables.sql أولًا.', 409);
    }
    foreach ($requiredColumns as $column) {
        if (!columnExists('order_chat_messages', $column)) {
            masterOrderMediaFail('بنية محادثات الطلبات غير مكتملة. طبّق migration 20260818_master_chat_tables.sql أولًا.', 409);
        }
    }
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'orders.edit');
    masterOrderMediaRequireSchema();

    $orderId = (int)($_POST['order_id'] ?? 0);
    $caption = trim((string)($_POST['message'] ?? 'مرفق من لوحة الماستر'));
    if ($orderId <= 0) {
        masterOrderMediaFail('order_id is required');
    }
    if (!isset($_FILES['media']) || !is_array($_FILES['media'])) {
        masterOrderMediaFail('media file is required');
    }
    if ((int)($_FILES['media']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        masterOrderMediaFail('upload failed');
    }
    $exists = $con->prepare("SELECT orders_id FROM orders WHERE orders_id = :order_id LIMIT 1");
    $exists->execute([':order_id' => $orderId]);
    if (!$exists->fetchColumn()) {
        masterOrderMediaFail('order not found', 404);
    }

    $size = (int)($_FILES['media']['size'] ?? 0);
    if ($size <= 0 || $size > 8 * 1024 * 1024) {
        masterOrderMediaFail('media file must be less than 8MB');
    }
    $original = (string)($_FILES['media']['name'] ?? 'media');
    $ext = strtolower(pathinfo($original, PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'mp3', 'm4a', 'wav', 'ogg'];
    if (!in_array($ext, $allowed, true)) {
        masterOrderMediaFail('unsupported media type');
    }

    $root = dirname(__DIR__, 3);
    $relativeDir = 'uploads/master/order_chat';
    $targetDir = $root . DIRECTORY_SEPARATOR . $relativeDir;
    if (!is_dir($targetDir) && !mkdir($targetDir, 0775, true) && !is_dir($targetDir)) {
        masterOrderMediaFail('could not create media directory', 500);
    }
    $fileName = 'order_' . $orderId . '_' . time() . '_' . random_int(1000, 9999) . '.' . $ext;
    $targetPath = $targetDir . DIRECTORY_SEPARATOR . $fileName;
    if (!move_uploaded_file((string)$_FILES['media']['tmp_name'], $targetPath)) {
        masterOrderMediaFail('could not save media file', 500);
    }

    $mediaUrl = 'https://savir-technology.online/roaqv2/' . $relativeDir . '/' . $fileName;
    $stmt = $con->prepare("
        INSERT INTO order_chat_messages (
            order_id, chat_scope, sender_role, sender_ref_id, message, audio_url, is_read
        ) VALUES (
            :order_id, 'order', 'admin', :admin_id, :message, :media_url, 0
        )
    ");
    $stmt->execute([
        ':order_id' => $orderId,
        ':admin_id' => (int)($admin['admin_id'] ?? 0),
        ':message' => $caption !== '' ? $caption : 'مرفق من لوحة الماستر',
        ':media_url' => $mediaUrl,
    ]);

    respondJson([
        'status' => 'success',
        'message' => 'media uploaded',
        'data' => [
            'message_id' => (int)$con->lastInsertId(),
            'order_id' => $orderId,
            'media_url' => $mediaUrl,
        ],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
