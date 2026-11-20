<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Params: user_id, property_id, optional chat_id
$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : (isset($_GET['user_id']) ? (int)$_GET['user_id'] : null);
$property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : (isset($_GET['property_id']) ? (int)$_GET['property_id'] : null);
$chat_id = isset($_POST['chat_id']) ? (int)$_POST['chat_id'] : (isset($_GET['chat_id']) ? (int)$_GET['chat_id'] : null);

if (!$user_id || !$property_id) {
    echo json_encode(["status" => "fail", "message" => "missing user_id or property_id"]);
    exit;
}

try {
    // If chat_id provided, use it; otherwise try to find chat thread
    if ($chat_id) {
        $stmt = $con->prepare("SELECT * FROM property_chat_messages WHERE chat_id = ? ORDER BY created_at ASC");
        $stmt->execute([$chat_id]);
    } else {
        // find chat for this user and property
        $c = $con->prepare("SELECT chat_id FROM property_chats WHERE property_id = ? AND user_id = ? LIMIT 1");
        $c->execute([$property_id, $user_id]);
        $row = $c->fetch(PDO::FETCH_ASSOC);
        if ($row) {
            $stmt = $con->prepare("SELECT * FROM property_chat_messages WHERE chat_id = ? ORDER BY created_at ASC");
            $stmt->execute([$row['chat_id']]);
        } else {
            // no chat yet -> empty list
            echo json_encode(["status"=>"success","data"=>[]]);
            exit;
        }
    }

    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $messages]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

?>
