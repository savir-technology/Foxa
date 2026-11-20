<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

/**
 * Handle Call (Accept/Reject)
 * Params: call_id, user_id, action(accept|reject)
 *
 * Rules:
 * - Original receiver can accept/reject normally.
 * - Any admin who received incoming_call notification can accept call.
 *   On accept, receiver_id is reassigned to that admin (first accepter wins).
 * - Non-primary admin reject only dismisses their own notification.
 */

$call_id = intval($_POST['call_id'] ?? 0);
$user_id = intval($_POST['user_id'] ?? 0);
$action = trim((string)($_POST['action'] ?? ''));

if ($call_id <= 0 || $user_id <= 0 || !in_array($action, ['accept', 'reject'], true)) {
    echo json_encode(["status" => "fail", "message" => "Invalid parameters"]);
    exit;
}

try {
    $userCheck = $con->prepare("SELECT users_id, user_role FROM users WHERE users_id = ? LIMIT 1");
    $userCheck->execute([$user_id]);
    $user = $userCheck->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        echo json_encode(["status" => "fail", "message" => "User not found"]);
        exit;
    }
    $isAdmin = strtolower(trim((string)($user['user_role'] ?? ''))) === 'admin';

    $stmt = $con->prepare("SELECT * FROM call_logs WHERE call_id = :call_id LIMIT 1");
    $stmt->execute([':call_id' => $call_id]);
    $call = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$call) {
        echo json_encode(["status" => "fail", "message" => "Call not found"]);
        exit;
    }

    $isOriginalReceiver = intval($call['receiver_id'] ?? 0) === $user_id;

    $notifStmt = $con->prepare(
        "SELECT notification_id
         FROM call_notifications
         WHERE call_id = :call_id
           AND user_id = :user_id
           AND notification_type = 'incoming_call'
         LIMIT 1"
    );
    $notifStmt->execute([
        ':call_id' => $call_id,
        ':user_id' => $user_id,
    ]);
    $hasIncomingNotification = (bool)$notifStmt->fetch(PDO::FETCH_ASSOC);

    if (!$isOriginalReceiver && !($isAdmin && $hasIncomingNotification)) {
        echo json_encode(["status" => "fail", "message" => "You cannot control this call"]);
        exit;
    }

    if (($call['call_status'] ?? '') !== 'pending') {
        echo json_encode(["status" => "fail", "message" => "Call is no longer pending"]);
        exit;
    }

    if ($action === 'accept') {
        // First accepter wins (atomic update on pending state).
        $acceptStmt = $con->prepare(
            "UPDATE call_logs
             SET call_status = 'accepted', receiver_id = :receiver_id
             WHERE call_id = :call_id
               AND call_status = 'pending'"
        );
        $acceptStmt->execute([
            ':receiver_id' => $user_id,
            ':call_id' => $call_id,
        ]);

        if ($acceptStmt->rowCount() === 0) {
            echo json_encode(["status" => "fail", "message" => "Call already handled"]);
            exit;
        }

        $participantStmt = $con->prepare(
            "INSERT INTO call_participants (call_id, user_id) VALUES (:call_id, :user_id)"
        );
        try {
            $participantStmt->execute([
                ':call_id' => $call_id,
                ':user_id' => $user_id,
            ]);
        } catch (Throwable $dup) {
            // ignore duplicate participant insert
        }

        // Mark all incoming notifications for this call as read.
        $markAll = $con->prepare(
            "UPDATE call_notifications
             SET is_read = 1
             WHERE call_id = :call_id
               AND notification_type = 'incoming_call'"
        );
        $markAll->execute([':call_id' => $call_id]);

        echo json_encode([
            "status" => "success",
            "call_id" => $call_id,
            "call_token" => (string)($call['call_token'] ?? ''),
            "message" => "Call accepted",
            "receiver_id" => $user_id,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    // reject
    if ($isOriginalReceiver) {
        $rejectStmt = $con->prepare(
            "UPDATE call_logs
             SET call_status = 'rejected'
             WHERE call_id = :call_id
               AND call_status = 'pending'"
        );
        $rejectStmt->execute([':call_id' => $call_id]);

        $markAll = $con->prepare(
            "UPDATE call_notifications
             SET is_read = 1
             WHERE call_id = :call_id
               AND notification_type = 'incoming_call'"
        );
        $markAll->execute([':call_id' => $call_id]);

        echo json_encode([
            "status" => "success",
            "call_id" => $call_id,
            "message" => "Call rejected",
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    // Non-primary admin: dismiss own incoming notification only.
    $dismiss = $con->prepare(
        "UPDATE call_notifications
         SET is_read = 1
         WHERE call_id = :call_id
           AND user_id = :user_id
           AND notification_type = 'incoming_call'"
    );
    $dismiss->execute([
        ':call_id' => $call_id,
        ':user_id' => $user_id,
    ]);

    echo json_encode([
        "status" => "success",
        "call_id" => $call_id,
        "message" => "Notification dismissed",
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log("handle_call.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "Server error"]);
}

