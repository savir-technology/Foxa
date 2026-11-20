<?php
/**
 * Notification Helper Functions
 * These functions help in sending various types of notifications
 */

require_once __DIR__ . '/../notifications/fcm_token_utils.php';

/**
 * Send call notification to user
 * @param PDO $con Database connection
 * @param int $call_id Call ID
 * @param int $from_user User ID who initiated the call
 * @param int $to_user User ID to receive the notification
 * @param string $notification_type Type of notification (incoming_call, call_ended, etc.)
 * @param array $extra_data Additional data to include in notification
 * @return bool True if notification was sent successfully
 */
function sendCallNotification(PDO $con, int $call_id, int $from_user, int $to_user, string $notification_type = 'incoming_call', array $extra_data = []): bool
{
    try {
        // Get receiver's FCM token
        $receiverTokenStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
        $receiverTokenStmt->execute([$to_user]);
        $receiverRow = $receiverTokenStmt->fetch(PDO::FETCH_ASSOC);
        $receiverToken = trim((string)($receiverRow['fcm_token'] ?? ''));

        if ($receiverToken === '') {
            error_log("sendCallNotification: No FCM token for user $to_user");
            return false;
        }

        // Get caller name
        $callerNameStmt = $con->prepare("SELECT users_name FROM users WHERE users_id = ? LIMIT 1");
        $callerNameStmt->execute([$from_user]);
        $callerName = trim((string)($callerNameStmt->fetchColumn() ?? 'مستخدم'));

        // Get call details
        $callStmt = $con->prepare("SELECT call_type, call_status FROM call_logs WHERE call_id = ? LIMIT 1");
        $callStmt->execute([$call_id]);
        $callRow = $callStmt->fetch(PDO::FETCH_ASSOC);
        $callType = $callRow['call_type'] ?? 'voice';
        $callStatus = $callRow['call_status'] ?? 'pending';

        // Prepare notification title and body based on type
        $title = '';
        $body = '';
        $data = [
            'type' => $notification_type,
            'call_id' => (string)$call_id,
            'from_user' => (string)$from_user,
            'to_user' => (string)$to_user,
            'caller_name' => $callerName,
            'call_type' => $callType,
            'call_status' => $callStatus
        ];

        // Add extra data
        foreach ($extra_data as $key => $value) {
            $data[$key] = (string)$value;
        }

        switch ($notification_type) {
            case 'incoming_call':
                $title = "مكالمة واردة";
                $body = "$callerName يتصل بك";
                $data['render_call_ui'] = '1';
                break;

            case 'call_accepted':
                $title = "مكالمة مقبولة";
                $body = "$callerName قبل مكالمتك";
                break;

            case 'call_rejected':
                $title = "مكالمة مرفوضة";
                $body = "$callerName رفض مكالمتك";
                break;

            case 'call_ended':
                $title = "انتهت المكالمة";
                $body = "انتهت مكالمتك مع $callerName";
                break;

            case 'call_missed':
                $title = "مكالمة فائتة";
                $body = "فوتت مكالمة من $callerName";
                break;

            default:
                $title = "إشعار اتصال";
                $body = "لديك إشعار جديد";
        }

        // Send FCM notification
        $pushFile = __DIR__ . '/firebase/send_notification.php';
        if (file_exists($pushFile)) {
            require_once $pushFile;

            $fcmResult = @sendFCM(
                $title,
                $body,
                $receiverToken,
                $data,
                [
                    'channel_id' => 'calls',
                    'sound' => 'default',
                    'priority' => 'high',
                    'content_available' => true
                ]
            );

            return is_array($fcmResult) && $fcmResult['ok'] === true;
        }

        return false;

    } catch (Throwable $e) {
        error_log("sendCallNotification error: " . $e->getMessage());
        return false;
    }
}

/**
 * Send multiple call notifications to different users
 * @param PDO $con Database connection
 * @param int $call_id Call ID
 * @param int $from_user User ID who initiated the call
 * @param array $to_users Array of user IDs to receive notifications
 * @param string $notification_type Type of notification
 * @param array $extra_data Additional data to include in notification
 * @return int Number of successful notifications sent
 */
function sendMultipleCallNotifications(PDO $con, int $call_id, int $from_user, array $to_users, string $notification_type = 'incoming_call', array $extra_data = []): int
{
    $sentCount = 0;

    foreach ($to_users as $to_user) {
        if (is_int($to_user) && sendCallNotification($con, $call_id, $from_user, $to_user, $notification_type, $extra_data)) {
            $sentCount++;
        }
    }

    return $sentCount;
}

/**
 * Update call notification status
 * @param PDO $con Database connection
 * @param int $call_id Call ID
 * @param int $user_id User ID
 * @param string $status New status (read, dismissed)
 * @return bool True if update was successful
 */
function updateCallNotificationStatus(PDO $con, int $call_id, int $user_id, string $status = 'read'): bool
{
    try {
        $stmt = $con->prepare("
            UPDATE call_notifications 
            SET is_read = 1, read_at = NOW() 
            WHERE call_id = :call_id AND user_id = :user_id
        ");

        $stmt->execute([
            ':call_id' => $call_id,
            ':user_id' => $user_id
        ]);

        return $stmt->rowCount() > 0;

    } catch (Exception $e) {
        error_log("updateCallNotificationStatus error: " . $e->getMessage());
        return false;
    }
}
