<?php
/**
 * Real Estate API - Admin Booking (Visit) Approval Endpoint
 * 
 * Admin confirms, reschedules, or cancels property visit bookings
 * 
 * Method: POST
 * Parameters:
 *   - admin_id (required): Admin ID for authorization
 *   - action (required): confirm|reschedule|cancel|list
 *   - booking_id (required for confirm/reschedule/cancel): Booking ID
 *   - new_date (required for reschedule): New date in YYYY-MM-DD format
 *   - new_time (required for reschedule): New time in HH:MM format
 *   - cancellation_reason (optional): Reason for cancellation
 *   - page (optional, for 'list'): Pagination
 *   - limit (optional, for 'list'): Items per page
 *   - status_filter (optional, for 'list'): pending|confirmed|cancelled|completed
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $admin_id = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : null;
    $action = isset($_POST['action']) ? filterRequest('action') : 'list';
    $booking_id = isset($_POST['booking_id']) ? (int)$_POST['booking_id'] : null;
    $new_date = isset($_POST['new_date']) ? filterRequest('new_date') : null;
    $new_time = isset($_POST['new_time']) ? filterRequest('new_time') : null;
    $cancellation_reason = isset($_POST['cancellation_reason']) ? filterRequest('cancellation_reason') : '';
    $page = isset($_POST['page']) ? max(1, (int)$_POST['page']) : 1;
    $limit = isset($_POST['limit']) ? max(1, (int)$_POST['limit']) : 20;
    $status_filter = isset($_POST['status_filter']) ? filterRequest('status_filter') : null;

    if (!$admin_id) {
        echo json_encode(["status" => "fail", "message" => "admin_id is required"]);
        exit;
    }

    // Verify admin exists
    $adminStmt = $con->prepare("SELECT admin_id FROM admin WHERE admin_id = ? LIMIT 1");
    $adminStmt->execute([$admin_id]);
    if (!$adminStmt->fetch()) {
        echo json_encode(["status" => "fail", "message" => "Admin not found"]);
        exit;
    }

    if ($action === 'confirm' || $action === 'reschedule' || $action === 'cancel') {
        if (!$booking_id) {
            echo json_encode(["status" => "fail", "message" => "booking_id is required"]);
            exit;
        }

        // Get booking details
        $bookStmt = $con->prepare("SELECT * FROM property_bookings WHERE booking_id = ? LIMIT 1");
        $bookStmt->execute([$booking_id]);
        $booking = $bookStmt->fetch(PDO::FETCH_ASSOC);

        if (!$booking) {
            echo json_encode(["status" => "fail", "message" => "Booking not found"]);
            exit;
        }

        if ($action === 'confirm') {
            $new_status = 'confirmed';
            
            $updateStmt = $con->prepare("UPDATE property_bookings SET booking_status = ?, updated_at = NOW() WHERE booking_id = ?");
            $updateStmt->execute([$new_status, $booking_id]);

        } elseif ($action === 'reschedule') {
            if (!$new_date || !$new_time) {
                echo json_encode(["status" => "fail", "message" => "new_date and new_time required for reschedule"]);
                exit;
            }

            // Validate date format
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $new_date)) {
                echo json_encode(["status" => "fail", "message" => "Invalid date format. Use YYYY-MM-DD"]);
                exit;
            }

            // Validate time format
            if (!preg_match('/^\d{2}:\d{2}$/', $new_time)) {
                echo json_encode(["status" => "fail", "message" => "Invalid time format. Use HH:MM"]);
                exit;
            }

            // Check for conflict at new time slot
            $dupStmt = $con->prepare("
                SELECT booking_id FROM property_bookings 
                WHERE property_id = ? AND booking_date = ? AND booking_time_slot = ? 
                AND booking_status IN ('pending', 'confirmed')
                AND booking_id != ?
                LIMIT 1
            ");
            $dupStmt->execute([$booking['property_id'], $new_date, $new_time, $booking_id]);
            if ($dupStmt->fetch()) {
                echo json_encode(["status" => "fail", "message" => "New time slot is already booked"]);
                exit;
            }

            $updateStmt = $con->prepare("
                UPDATE property_bookings 
                SET booking_date = ?, booking_time_slot = ?, booking_status = 'confirmed', updated_at = NOW()
                WHERE booking_id = ?
            ");
            $updateStmt->execute([$new_date, $new_time, $booking_id]);

        } else { // cancel
            $new_status = 'cancelled';
            $updateStmt = $con->prepare("UPDATE property_bookings SET booking_status = ?, updated_at = NOW() WHERE booking_id = ?");
            $updateStmt->execute([$new_status, $booking_id]);
        }

        // Notify user
        $userStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
        $userStmt->execute([$booking['user_id']]);
        $user = $userStmt->fetch(PDO::FETCH_ASSOC);

        if ($user && !empty($user['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
            include __DIR__ . "/../chat/firebase/send_notification.php";
            
            if ($action === 'confirm') {
                sendFCM(
                    "تم تأكيد حجز الزيارة",
                    "تم تأكيد حجزك لزيارة العقار في " . $booking['booking_date'] . " الساعة " . $booking['booking_time_slot'],
                    trim($user['fcm_token'])
                );
            } elseif ($action === 'reschedule') {
                sendFCM(
                    "تم إعادة جدولة الزيارة",
                    "تم تغيير موعد الزيارة إلى $new_date الساعة $new_time",
                    trim($user['fcm_token'])
                );
            } else {
                $msg = $cancellation_reason ? "السبب: $cancellation_reason" : "تم إلغاء حجز الزيارة";
                sendFCM("تم إلغاء الزيارة", $msg, trim($user['fcm_token']));
            }
        }

        echo json_encode([
            "status" => "success",
            "message" => "Booking $action" . "ed successfully",
            "booking_id" => (int)$booking_id
        ]);

    } elseif ($action === 'list') {
        $offset = ($page - 1) * $limit;
        
        $where = "WHERE 1=1";
        $params = [];
        
        if ($status_filter) {
            $where .= " AND booking_status = ?";
            $params[] = $status_filter;
        }

        // Get count
        $countStmt = $con->prepare("SELECT COUNT(*) as total FROM property_bookings $where");
        $countStmt->execute($params);
        $countResult = $countStmt->fetch(PDO::FETCH_ASSOC);
        $total = (int)$countResult['total'];

        // Get bookings
        $listStmt = $con->prepare("
            SELECT pb.*,
                   u.users_name, u.users_email, u.users_phone,
                   p.title as property_title, p.property_type
            FROM property_bookings pb
            LEFT JOIN users u ON pb.user_id = u.users_id
            LEFT JOIN properties p ON pb.property_id = p.property_id
            $where
            ORDER BY pb.booking_date ASC
            LIMIT ? OFFSET ?
        ");
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        $listStmt->execute($params);
        $bookings = $listStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "status" => "success",
            "data" => $bookings,
            "pagination" => [
                "current_page" => $page,
                "per_page" => $limit,
                "total" => $total,
                "total_pages" => ceil($total / $limit)
            ]
        ]);

    } else {
        echo json_encode(["status" => "fail", "message" => "Invalid action. Use: confirm|reschedule|cancel|list"]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to process request",
        "error" => $e->getMessage()
    ]);
}
?>
