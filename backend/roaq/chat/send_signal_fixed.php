<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";
require_once __DIR__ . '/../notifications/fcm_token_utils.php';

/**
 * Send signaling message (offer/answer/candidate)
 * Params: call_id, from_user, to_user, message_type (offer|answer|candidate), payload
 */

$call_id = intval($_POST['call_id'] ?? 0);
$from_user = intval($_POST['from_user'] ?? 0);
$to_user = intval($_POST['to_user'] ?? 0);
$message_type = $_POST['message_type'] ?? '';
$payload = $_POST['payload'] ?? '';

if ($call_id <= 0 || $from_user <= 0 || $to_user <= 0 || empty($message_type) || empty($payload)) {
    echo json_encode(["status" => "fail", "message" => "بيانات غير صحيحة"]);
    exit;
}

try {
    // ✅ التحقق من أن from_user موجود في قاعدة البيانات
    $user_check = $con->prepare("SELECT users_id FROM users WHERE users_id = ?");
    $user_check->execute([$from_user]);
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
    $call_check->execute([$call_id, $from_user, $from_user]);
    if ($call_check->rowCount() == 0) {
        echo json_encode(["status" => "fail", "message" => "المكالمة غير صحيحة أو غير نشطة"]);
        exit;
    }

    // Ensure signaling table exists
    $create_sql = "CREATE TABLE IF NOT EXISTS call_signaling (
        id INT(11) NOT NULL AUTO_INCREMENT,
        call_id INT(11) NOT NULL,
        from_user INT(11) NOT NULL,
        to_user INT(11) NOT NULL,
        message_type VARCHAR(32) NOT NULL,
        payload LONGTEXT NOT NULL,
        consumed TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    $con->exec($create_sql);

    // Store signaling message in database
    $stmt = $con->prepare(
        "INSERT INTO call_signaling (call_id, from_user, to_user, message_type, payload)
         VALUES (:call_id, :from_user, :to_user, :message_type, :payload)"
    );

    $stmt->execute([
        ':call_id' => $call_id,
        ':from_user' => $from_user,
        ':to_user' => $to_user,
        ':message_type' => $message_type,
        ':payload' => $payload
    ]);

    // Get receiver's FCM token
    $receiverTokenStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
    $receiverTokenStmt->execute([$to_user]);
    $receiverRow = $receiverTokenStmt->fetch(PDO::FETCH_ASSOC);
    $receiverToken = trim((string)($receiverRow['fcm_token'] ?? ''));

    // Send notification via FCM if token exists
    $fcmSent = false;
    if ($receiverToken !== '') {
        try {
            $pushFile = __DIR__ . '/firebase/send_notification.php';
            if (file_exists($pushFile)) {
                require_once $pushFile;

                // Get caller name
                $callerNameStmt = $con->prepare("SELECT users_name FROM users WHERE users_id = ? LIMIT 1");
                $callerNameStmt->execute([$from_user]);
                $callerName = trim((string)($callerNameStmt->fetchColumn() ?? 'مستخدم'));

                $fcmResult = @sendFCM(
                    "رسالة اتصال",
                    "$callerName يرسل لك إشارة اتصال",
                    $receiverToken,
                    [
                        'type' => 'call_signal',
                        'call_id' => (string)$call_id,
                        'from_user' => (string)$from_user,
                        'to_user' => (string)$to_user,
                        'message_type' => (string)$message_type,
                        'payload' => $payload,
                        'caller_name' => $callerName,
                    ],
                    [
                        'channel_id' => 'calls',
                        'sound' => 'default',
                        'priority' => 'high'
                    ]
                );

                $fcmSent = is_array($fcmResult) && $fcmResult['ok'] === true;
            }
        } catch (Throwable $fcmError) {
            error_log("send_signal.php FCM error: " . $fcmError->getMessage());
        }
    }

    echo json_encode([
        "status" => "success", 
        "message" => "sent",
        "fcm_sent" => $fcmSent
    ]);

} catch (Exception $e) {
    error_log("send_signal.php error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}