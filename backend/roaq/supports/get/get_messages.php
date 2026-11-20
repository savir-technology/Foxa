<?php
include '../../connect.php'; // الاتصال بقاعدة البيانات

$sender_id = $_GET['sender_id'];
$receiver_id = $_GET['receiver_id'];

if (empty($sender_id) || empty($receiver_id)) {
    echo json_encode(["status" => "error", "message" => "بيانات غير كافية"]);
    exit();
}

try {
    $stmt = $con->prepare("SELECT * FROM messages WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?) ORDER BY created_at ASC");
    $stmt->execute([$sender_id, $receiver_id, $receiver_id, $sender_id]);

    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "messages" => $messages]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => "خطأ في جلب الرسائل: " . $e->getMessage()]);
}
?>
