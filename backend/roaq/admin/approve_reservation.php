<?php
/**
 * Real Estate API - Admin Reservation Approval Endpoint
 * 
 * Admin approves, rejects, or manages property reservations
 * 
 * Method: POST
 * Parameters:
 *   - admin_id (required): Admin ID for authorization
 *   - action (required): approve|reject|cancel|list
 *   - reservation_id (required for approve/reject/cancel): Reservation ID
 *   - rejection_reason (optional): Reason for rejection/cancellation
 *   - page (optional, for 'list'): Pagination
 *   - limit (optional, for 'list'): Items per page
 *   - status_filter (optional, for 'list'): pending|confirmed|cancelled|completed
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $admin_id = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : null;
    $action = isset($_POST['action']) ? filterRequest('action') : 'list';
    $reservation_id = isset($_POST['reservation_id']) ? (int)$_POST['reservation_id'] : null;
    $rejection_reason = isset($_POST['rejection_reason']) ? filterRequest('rejection_reason') : '';
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

    if ($action === 'approve' || $action === 'reject' || $action === 'cancel') {
        if (!$reservation_id) {
            echo json_encode(["status" => "fail", "message" => "reservation_id is required"]);
            exit;
        }

        // Get reservation details
        $resStmt = $con->prepare("
            SELECT pr.*, p.status as property_status 
            FROM property_reservations pr
            LEFT JOIN properties p ON pr.property_id = p.property_id
            WHERE pr.reservation_id = ? LIMIT 1
        ");
        $resStmt->execute([$reservation_id]);
        $reservation = $resStmt->fetch(PDO::FETCH_ASSOC);

        if (!$reservation) {
            echo json_encode(["status" => "fail", "message" => "Reservation not found"]);
            exit;
        }

        // Determine new status
        if ($action === 'approve') {
            $new_status = 'confirmed';
            
            // Update property status to reserved
            if ($reservation['property_status'] === 'available') {
                $updatePropStmt = $con->prepare("UPDATE properties SET status = 'reserved' WHERE property_id = ?");
                $updatePropStmt->execute([$reservation['property_id']]);
            }
        } elseif ($action === 'reject') {
            $new_status = 'cancelled';
        } else { // cancel
            $new_status = 'cancelled';
        }

        // Update reservation
        $updateStmt = $con->prepare("
            UPDATE property_reservations 
            SET reservation_status = ?, rejection_reason = ?, updated_at = NOW()
            WHERE reservation_id = ?
        ");

        if ($updateStmt->execute([$new_status, $rejection_reason, $reservation_id])) {
            // Notify user
            $userStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
            $userStmt->execute([$reservation['user_id']]);
            $user = $userStmt->fetch(PDO::FETCH_ASSOC);

            if ($user && !empty($user['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
                include __DIR__ . "/../chat/firebase/send_notification.php";
                
                if ($new_status === 'confirmed') {
                    sendFCM(
                        "تم قبول حجزك",
                        "تم قبول حجزك للعقار رقم " . $reservation['property_id'],
                        trim($user['fcm_token'])
                    );
                } else {
                    $msg = $rejection_reason ? "تم إلغاء الحجز: $rejection_reason" : "تم إلغاء حجزك للعقار";
                    sendFCM("تم إلغاء الحجز", $msg, trim($user['fcm_token']));
                }
            }

            echo json_encode([
                "status" => "success",
                "message" => "Reservation " . $new_status . " successfully",
                "reservation_id" => (int)$reservation_id
            ]);
        } else {
            echo json_encode(["status" => "fail", "message" => "Failed to update reservation"]);
        }

    } elseif ($action === 'list') {
        $offset = ($page - 1) * $limit;
        
        $where = "WHERE 1=1";
        $params = [];
        
        if ($status_filter) {
            $where .= " AND reservation_status = ?";
            $params[] = $status_filter;
        }

        // Get count
        $countStmt = $con->prepare("SELECT COUNT(*) as total FROM property_reservations $where");
        $countStmt->execute($params);
        $countResult = $countStmt->fetch(PDO::FETCH_ASSOC);
        $total = (int)$countResult['total'];

        // Get reservations
        $listStmt = $con->prepare("
            SELECT pr.*,
                   u.users_name, u.users_email, u.users_phone,
                   p.title as property_title, p.property_type, p.price
            FROM property_reservations pr
            LEFT JOIN users u ON pr.user_id = u.users_id
            LEFT JOIN properties p ON pr.property_id = p.property_id
            $where
            ORDER BY pr.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        $listStmt->execute($params);
        $reservations = $listStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "status" => "success",
            "data" => $reservations,
            "pagination" => [
                "current_page" => $page,
                "per_page" => $limit,
                "total" => $total,
                "total_pages" => ceil($total / $limit)
            ]
        ]);

    } else {
        echo json_encode(["status" => "fail", "message" => "Invalid action. Use: approve|reject|cancel|list"]);
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
