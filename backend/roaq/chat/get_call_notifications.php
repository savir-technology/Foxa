<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Get call notifications for a user.
 * Params:
 * - user_id (required)
 * - unread_only (optional: true|1 to return unread only)
 * - limit (optional, default 30, max 100)
 */

$user_id = intval($_POST['user_id'] ?? 0);
$unread_raw = strtolower(trim((string)($_POST['unread_only'] ?? 'false')));
$unread_only = in_array($unread_raw, ['1', 'true', 'yes'], true);
$limit = intval($_POST['limit'] ?? 30);

if ($user_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "Missing user_id"]);
    exit;
}

$limit = max(1, min($limit, 100));

try {
    $userStmt = $con->prepare("SELECT users_id FROM users WHERE users_id = ? LIMIT 1");
    $userStmt->execute([$user_id]);
    if ($userStmt->rowCount() === 0) {
        echo json_encode(["status" => "fail", "message" => "User not found"]);
        exit;
    }

    $sql =
        "SELECT
            cn.notification_id,
            cn.call_id,
            cn.user_id,
            cn.notification_type,
            cn.is_read,
            cn.created_at,
            cn.read_at,
            cl.caller_id,
            cl.receiver_id,
            cl.call_type,
            cl.call_status,
            cl.item_id,
            caller.users_name AS caller_name,
            receiver.users_name AS receiver_name
         FROM call_notifications cn
         LEFT JOIN call_logs cl ON cl.call_id = cn.call_id
         LEFT JOIN users caller ON caller.users_id = cl.caller_id
         LEFT JOIN users receiver ON receiver.users_id = cl.receiver_id
         WHERE cn.user_id = :user_id";

    if ($unread_only) {
        $sql .= " AND cn.is_read = 0";
    }

    $sql .= " ORDER BY cn.created_at DESC, cn.notification_id DESC LIMIT :limit";

    $stmt = $con->prepare($sql);
    $stmt->bindValue(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->execute();

    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    $data = [];

    foreach ($rows as $r) {
        $data[] = [
            'notification_id' => intval($r['notification_id'] ?? 0),
            'call_id' => intval($r['call_id'] ?? 0),
            'user_id' => intval($r['user_id'] ?? 0),
            'notification_type' => (string)($r['notification_type'] ?? ''),
            'is_read' => intval($r['is_read'] ?? 0),
            'created_at' => (string)($r['created_at'] ?? ''),
            'read_at' => $r['read_at'],
            'caller_id' => intval($r['caller_id'] ?? 0),
            'receiver_id' => intval($r['receiver_id'] ?? 0),
            'call_type' => (string)($r['call_type'] ?? 'voice'),
            'call_status' => (string)($r['call_status'] ?? ''),
            'item_id' => intval($r['item_id'] ?? 0),
            'caller_name' => (string)($r['caller_name'] ?? ''),
            'receiver_name' => (string)($r['receiver_name'] ?? ''),
        ];
    }

    echo json_encode([
        "status" => "success",
        "count" => count($data),
        "data" => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log("get_call_notifications.php error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => "Server error",
    ]);
}

?>
