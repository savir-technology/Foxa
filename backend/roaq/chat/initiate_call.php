<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

function isSupportRole(string $role): bool
{
    return in_array($role, ['admin', 'conect', 'crm'], true);
}

function resolveSupportUserId(PDO $con): int
{
    // Force a single support owner for all calls.
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

function resolveChatAssignedSupport(PDO $con, int $clientUserId, int $itemId): int
{
    return resolveSupportUserId($con);
}

/**
 * Initiate Call
 * Params:
 * - caller_id (required)
 * - call_type (voice|video|audio)
 * - item_id (optional)
 * - receiver_id (optional; allowed only when caller is admin)
 *
 * Behavior:
 * - User app (no receiver_id): call is routed to first admin user.
 * - Support dashboard (with receiver_id): support can call selected client.
 */

$caller_id = intval($_POST['caller_id'] ?? 0);
$receiver_id_input = intval($_POST['receiver_id'] ?? 0);
$item_id = intval($_POST['item_id'] ?? 0);
$call_type = trim((string)($_POST['call_type'] ?? 'voice'));

if ($caller_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "Missing caller_id"]);
    exit;
}

if (!in_array($call_type, ['voice', 'video', 'audio'], true)) {
    echo json_encode(["status" => "fail", "message" => "Invalid call_type"]);
    exit;
}

try {
    $lockKey = null;
    $hasTx = false;

    // Validate caller and read role.
    $callerStmt = $con->prepare("SELECT users_id, user_role FROM users WHERE users_id = ? LIMIT 1");
    $callerStmt->execute([$caller_id]);
    $caller = $callerStmt->fetch(PDO::FETCH_ASSOC);
    if (!$caller) {
        echo json_encode(["status" => "fail", "message" => "Caller not found"]);
        exit;
    }
    $caller_role = strtolower(trim((string)($caller['user_role'] ?? 'user')));

    // Resolve receiver.
    if ($receiver_id_input > 0) {
        if (!isSupportRole($caller_role)) {
            echo json_encode(["status" => "fail", "message" => "Only support can set receiver_id"]);
            exit;
        }
        $receiver_id = $receiver_id_input;
    } else if (isSupportRole($caller_role)) {
        // Admin caller without explicit receiver_id:
        // prefer resolving the latest client from chats by (admin + item_id),
        // and avoid routing the call to another admin by default.
        $receiver_id = 0;
        if ($item_id > 0) {
            $chatStmt = $con->prepare(
                "SELECT user_id
                 FROM chats
                 WHERE other_user_id = :admin_id
                   AND item_id = :item_id
                   AND user_id <> :admin_id
                 ORDER BY updated_at DESC, id DESC
                 LIMIT 1"
            );
            $chatStmt->execute([
                ':admin_id' => $caller_id,
                ':item_id' => $item_id,
            ]);
            $receiver_id = intval($chatStmt->fetchColumn() ?: 0);
        }

        if ($receiver_id <= 0) {
            echo json_encode([
                "status" => "fail",
                "message" => "Missing receiver_id for admin call",
                "debug" => [
                    "caller_id" => $caller_id,
                    "caller_role" => $caller_role,
                    "item_id" => $item_id,
                ],
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            exit;
        }
    } else {
        $receiver_id = resolveChatAssignedSupport($con, $caller_id, $item_id);
        if ($receiver_id <= 0) {
            $receiver_id = resolveSupportUserId($con);
        }
        if ($receiver_id <= 0) {
            echo json_encode(["status" => "fail", "message" => "No support account found"]);
            exit;
        }
    }

    // Admin safety fallback:
    // If dashboard sent self as receiver by mistake, resolve client from chats.
    if (isSupportRole($caller_role) && $receiver_id === $caller_id) {
        if ($item_id > 0) {
            $chatStmt = $con->prepare(
                "SELECT user_id
                 FROM chats
                 WHERE other_user_id = :admin_id
                   AND item_id = :item_id
                   AND user_id <> :admin_id
                 ORDER BY updated_at DESC, id DESC
                 LIMIT 1"
            );
            $chatStmt->execute([
                ':admin_id' => $caller_id,
                ':item_id' => $item_id,
            ]);
            $resolved = intval($chatStmt->fetchColumn() ?: 0);
            if ($resolved > 0) {
                $receiver_id = $resolved;
            }
        }
    }

    // Validate receiver.
    $receiverStmt = $con->prepare("SELECT users_id FROM users WHERE users_id = ? LIMIT 1");
    $receiverStmt->execute([$receiver_id]);
    if ($receiverStmt->rowCount() === 0) {
        echo json_encode(["status" => "fail", "message" => "Receiver not found"]);
        exit;
    }

    if ($caller_id === $receiver_id) {
        echo json_encode([
            "status" => "fail",
            "message" => "Caller and receiver cannot be same",
            "debug" => [
                "caller_id" => $caller_id,
                "receiver_id" => $receiver_id,
                "caller_role" => $caller_role,
                "item_id" => $item_id,
            ],
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    // Acquire per-pair lock to prevent duplicate call creation race.
    $pairA = min($caller_id, $receiver_id);
    $pairB = max($caller_id, $receiver_id);
    $lockKey = "call_pair_" . $pairA . "_" . $pairB;
    $lockStmt = $con->prepare("SELECT GET_LOCK(:lock_key, 3)");
    $lockStmt->execute([':lock_key' => $lockKey]);
    $gotLock = intval($lockStmt->fetchColumn() ?: 0);
    if ($gotLock !== 1) {
        echo json_encode(["status" => "fail", "message" => "Please retry call"]);
        exit;
    }

    $con->beginTransaction();
    $hasTx = true;

    // Expire stale pending calls.
    $expire = $con->prepare(
        "UPDATE call_logs
         SET call_status = 'rejected'
         WHERE call_status = 'pending'
           AND TIMESTAMPDIFF(SECOND, created_at, NOW()) >= 30"
    );
    $expire->execute();

    // Prevent duplicate active call between same pair.
    $activeStmt = $con->prepare(
        "SELECT call_id
         FROM call_logs
         WHERE ((caller_id = :caller_id AND receiver_id = :receiver_id)
             OR (caller_id = :receiver_id AND receiver_id = :caller_id))
           AND call_status IN ('pending', 'accepted')
         LIMIT 1
         FOR UPDATE"
    );
    $activeStmt->execute([
        ':caller_id' => $caller_id,
        ':receiver_id' => $receiver_id,
    ]);
    if ($activeStmt->rowCount() > 0) {
        $con->rollBack();
        $hasTx = false;
        echo json_encode(["status" => "fail", "message" => "There is already an active call"]);
        exit;
    }

    // Respect block list: receiver may block caller.
    $blockStmt = $con->prepare(
        "SELECT block_id
         FROM blocked_users
         WHERE blocker_id = :receiver_id AND blocked_id = :caller_id
         LIMIT 1
         FOR UPDATE"
    );
    $blockStmt->execute([
        ':receiver_id' => $receiver_id,
        ':caller_id' => $caller_id,
    ]);
    if ($blockStmt->rowCount() > 0) {
        $con->rollBack();
        $hasTx = false;
        echo json_encode(["status" => "fail", "message" => "You are blocked by this user"]);
        exit;
    }

    $call_token = bin2hex(random_bytes(16));

    $insertCall = $con->prepare(
        "INSERT INTO call_logs (caller_id, receiver_id, item_id, call_type, call_status, call_token)
         VALUES (:caller_id, :receiver_id, :item_id, :call_type, 'pending', :call_token)"
    );
    $insertCall->execute([
        ':caller_id' => $caller_id,
        ':receiver_id' => $receiver_id,
        ':item_id' => $item_id > 0 ? $item_id : null,
        ':call_type' => $call_type,
        ':call_token' => $call_token,
    ]);

    $call_id = intval($con->lastInsertId());

    $participantStmt = $con->prepare(
        "INSERT INTO call_participants (call_id, user_id) VALUES (:call_id, :user_id)"
    );
    $participantStmt->execute([
        ':call_id' => $call_id,
        ':user_id' => $caller_id,
    ]);

    // Notify receiver (and all approved admins for incoming user calls).
    $notifyStmt = $con->prepare(
        "INSERT INTO call_notifications (call_id, user_id, notification_type)
         VALUES (:call_id, :user_id, 'incoming_call')"
    );
    $notifyStmt->execute([
        ':call_id' => $call_id,
        ':user_id' => $receiver_id,
    ]);

    $con->commit();
    $hasTx = false;

    $push_sent = false;
    $push_reason = '';

    // Push incoming-call notification via FCM (best-effort).
    try {
        $tokenStmt = $con->prepare("SELECT fcm_token, users_name FROM users WHERE users_id = ? LIMIT 1");
        $tokenStmt->execute([$receiver_id]);
        $receiverRow = $tokenStmt->fetch(PDO::FETCH_ASSOC);

        $callerStmt2 = $con->prepare("SELECT users_name FROM users WHERE users_id = ? LIMIT 1");
        $callerStmt2->execute([$caller_id]);
        $callerName = trim((string)($callerStmt2->fetchColumn() ?: 'عميل'));

        $receiverToken = trim((string)($receiverRow['fcm_token'] ?? ''));
        if ($receiverToken !== '') {
            $pushFile = __DIR__ . '/firebase/send_notification.php';
            if (file_exists($pushFile)) {
                require_once $pushFile;
                @sendFCM(
                    "مكالمة واردة",
                    $callerName . " يتصل بك",
                    $receiverToken,
                    [
                        'type' => 'incoming_call',
                        'call_id' => (string)$call_id,
                        'caller_id' => (string)$caller_id,
                        'caller_name' => (string)$callerName,
                        'receiver_id' => (string)$receiver_id,
                        'call_type' => (string)$call_type,
                        'item_id' => (string)$item_id,
                    ],
                    [
                        'channel_id' => 'calls',
                        'sound' => 'default',
                    ]
                );
                $push_sent = true;
            } else {
                $push_reason = 'send_notification.php missing';
            }
        } else {
            $push_reason = 'receiver token empty';
        }
    } catch (Throwable $pushErr) {
        $push_reason = 'push exception: ' . $pushErr->getMessage();
        error_log("initiate_call.php FCM push error: " . $pushErr->getMessage());
    }

    echo json_encode([
        "status" => "success",
        "call_id" => $call_id,
        "call_token" => $call_token,
        "call_type" => $call_type,
        "caller_id" => $caller_id,
        "receiver_id" => $receiver_id,
        "push_sent" => $push_sent,
        "push_reason" => $push_reason,
        "message" => "Call initiated successfully"
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    if (isset($hasTx) && $hasTx && $con->inTransaction()) {
        $con->rollBack();
    }
    error_log("initiate_call.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "Server error"]);
} finally {
    if (isset($lockKey) && $lockKey) {
        try {
            $unlockStmt = $con->prepare("DO RELEASE_LOCK(:lock_key)");
            $unlockStmt->execute([':lock_key' => $lockKey]);
        } catch (Throwable $unlockErr) {
            // Ignore unlock failures.
        }
    }
}

?>
