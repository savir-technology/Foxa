<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

$user_id = $_POST['user_id'] ?? null;

if ($user_id == null) {
    echo json_encode(["status" => "fail", "message" => "missing user_id"]);
    exit;
}

try {
    $stmt = $con->prepare("SELECT * FROM chat_messages WHERE user_id = ? ORDER BY timestamp ASC");
    $stmt->execute([$user_id]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 🔹 احصل على آخر رسالة أرسلها الأدمن (اختياري لو هتحتاجها)
    $stmt2 = $con->prepare("SELECT * FROM chat_messages WHERE user_id = ? AND sender_type = 'admin' ORDER BY timestamp DESC LIMIT 1");
    $stmt2->execute([$user_id]);
    $last_admin_msg = $stmt2->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $data,
        "last_admin_message" => $last_admin_msg
    ]);

} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
