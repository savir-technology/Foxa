<?php
include "../connect.php";

$user_id = $_POST['user_id'] ?? null;

if ($user_id == null) {
    echo json_encode(["status" => "fail", "message" => "missing user_id"]);
    exit;
}

// نجيب آخر رسالة بين الأدمن والمستخدم دا فقط
$stmt = $con->prepare("
    SELECT 
        id,
        user_id,
        sender_type,
        message,
        audio_url,
        timestamp
    FROM chat_messages
    WHERE user_id = ?
    ORDER BY timestamp DESC
    LIMIT 1
");
$stmt->execute([$user_id]);
$data = $stmt->fetch(PDO::FETCH_ASSOC);

if ($data) {
    echo json_encode([
        "status" => "success",
        "data" => [$data]
    ]);
} else {
    echo json_encode([
        "status" => "empty",
        "message" => "No chat found"
    ]);
}
?>
