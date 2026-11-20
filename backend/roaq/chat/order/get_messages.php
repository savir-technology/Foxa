<?php
header('Content-Type: application/json; charset=utf-8');
include "../../connect.php";

function ensureOrderChatSchema(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS order_chat_messages (
            chat_id BIGINT NOT NULL AUTO_INCREMENT,
            order_id INT NOT NULL,
            chat_scope VARCHAR(32) NOT NULL DEFAULT 'order',
            sender_role VARCHAR(32) NOT NULL,
            sender_ref_id INT NOT NULL,
            message TEXT NOT NULL,
            audio_url VARCHAR(255) DEFAULT NULL,
            is_read TINYINT(1) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (chat_id),
            KEY idx_order_scope_created (order_id, chat_scope, created_at),
            KEY idx_sender_ref (sender_role, sender_ref_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

ensureOrderChatSchema($con);

$orderId = (int)($_POST['order_id'] ?? $_GET['order_id'] ?? 0);
$chatScope = trim((string)($_POST['chat_scope'] ?? $_GET['chat_scope'] ?? 'order'));

if ($orderId <= 0) {
    echo json_encode(["status" => "error", "message" => "missing order_id"], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $stmt = $con->prepare("
        SELECT
            chat_id,
            order_id,
            chat_scope,
            sender_role,
            sender_ref_id,
            message,
            audio_url,
            is_read,
            created_at
        FROM order_chat_messages
        WHERE order_id = ? AND chat_scope = ?
        ORDER BY created_at ASC, chat_id ASC
    ");
    $stmt->execute([$orderId, $chatScope]);

    echo json_encode([
        "status" => "success",
        "data" => $stmt->fetchAll(PDO::FETCH_ASSOC),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
?>
