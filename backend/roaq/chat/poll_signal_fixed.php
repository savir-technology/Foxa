<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";
require_once __DIR__ . '/../notifications/fcm_token_utils.php';

/**
 * Poll for signaling messages for a given call and receiver
 * Params: call_id, to_user
 * Returns: array of messages (id, from_user, message_type, payload)
 */

$call_id = intval($_POST['call_id'] ?? 0);
$to_user = intval($_POST['to_user'] ?? 0);

if ($call_id <= 0 || $to_user <= 0) {
    echo json_encode(["status" => "fail", "message" => "بيانات غير صحيحة"]);
    exit;
}

try {
    // ✅ التحقق من أن to_user موجود في قاعدة البيانات
    $user_check = $con->prepare("SELECT users_id FROM users WHERE users_id = ?");
    $user_check->execute([$to_user]);
    if ($user_check->rowCount() == 0) {
        echo json_encode(["status" => "fail", "message" => "المستخدم غير موجود"]);
        exit;
    }

    // ✅ التحقق من أن المكالمة موجودة والمستخدم جزء منها
    $call_check = $con->prepare(
        "SELECT call_id FROM call_logs
         WHERE call_id = ? AND (caller_id = ? OR receiver_id = ?)
         AND call_status IN ('accepted', 'pending')"
    );
    $call_check->execute([$call_id, $to_user, $to_user]);
    if ($call_check->rowCount() == 0) {
        echo json_encode(["status" => "fail", "message" => "المكالمة غير صحيحة أو غير نشطة"]);
        exit;
    }

    $query = $con->prepare(
        "SELECT id, from_user, message_type, payload, created_at
         FROM call_signaling
         WHERE call_id = :call_id AND to_user = :to_user AND consumed = 0
         ORDER BY id ASC"
    );

    $query->execute([
        ':call_id' => $call_id,
        ':to_user' => $to_user
    ]);

    $messages = $query->fetchAll(PDO::FETCH_ASSOC);

    if (!empty($messages)) {
        // mark as consumed
        $ids = array_column($messages, 'id');
        $in  = str_repeat('?,', count($ids) - 1) . '?';
        $update = $con->prepare("UPDATE call_signaling SET consumed = 1 WHERE id IN ($in)");
        $update->execute($ids);

        // Also send FCM notification for new signals if needed
        try {
            $pushFile = __DIR__ . '/firebase/send_notification.php';
            if (file_exists($pushFile)) {
                require_once $pushFile;

                // Get caller info
                $from_users = array_unique(array_column($messages, 'from_user'));
                foreach ($from_users as $from_user) {
                    $callerNameStmt = $con->prepare("SELECT users_name FROM users WHERE users_id = ? LIMIT 1");
                    $callerNameStmt->execute([$from_user]);
                    $callerName = trim((string)($callerNameStmt->fetchColumn() ?? 'مستخدم'));

                    // Get user's FCM token
                    $userTokenStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
                    $userTokenStmt->execute([$to_user]);
                    $userRow = $userTokenStmt->fetch(PDO::FETCH_ASSOC);
                    $userToken = trim((string)($userRow['fcm_token'] ?? ''));

                    if ($userToken !== '') {
                        @sendFCM(
                            "إشارات اتصال جديدة",
                            "$callerName أرسل إشارات اتصال جديدة",
                            $userToken,
                            [
                                'type' => 'new_call_signals',
                                'call_id' => (string)$call_id,
                                'from_user' => (string)$from_user,
                                'to_user' => (string)$to_user,
                                'signals_count' => count($messages),
                                'caller_name' => $callerName,
                            ],
                            [
                                'channel_id' => 'calls',
                                'sound' => 'default',
                                'priority' => 'high'
                            ]
                        );
                    }
                }
            }
        } catch (Throwable $fcmError) {
            error_log("poll_signal.php FCM error: " . $fcmError->getMessage());
        }
    }

    echo json_encode(["status" => "success", "messages" => $messages]);

} catch (Exception $e) {
    error_log("poll_signal.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
