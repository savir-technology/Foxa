<?php
/**
 * Real Estate API - Admin Bank Transfer Approval Endpoint
 * 
 * Admin approves, rejects, or views bank transfer submissions
 * 
 * Method: POST
 * Parameters:
 *   - admin_id (required): Admin ID for authorization
 *   - action (required): approve|reject|list
 *   - transfer_id (required for approve/reject): Transfer ID
 *   - approval_notes (optional): Reason for rejection or approval notes
 *   - page (optional, for 'list'): Pagination
 *   - limit (optional, for 'list'): Items per page
 *   - status_filter (optional, for 'list'): pending|approved|rejected
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $admin_id = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : null;
    $action = isset($_POST['action']) ? filterRequest('action') : 'list';
    $transfer_id = isset($_POST['transfer_id']) ? (int)$_POST['transfer_id'] : null;
    $approval_notes = isset($_POST['approval_notes']) ? filterRequest('approval_notes') : '';
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

    if ($action === 'approve' || $action === 'reject') {
        if (!$transfer_id) {
            echo json_encode(["status" => "fail", "message" => "transfer_id is required"]);
            exit;
        }

        // Verify transfer exists and is pending
        $transStmt = $con->prepare("SELECT transfer_id, user_id, property_id, amount, status FROM bank_transfers WHERE transfer_id = ? LIMIT 1");
        $transStmt->execute([$transfer_id]);
        $transfer = $transStmt->fetch(PDO::FETCH_ASSOC);

        if (!$transfer) {
            echo json_encode(["status" => "fail", "message" => "Transfer not found"]);
            exit;
        }

        if ($transfer['status'] !== 'pending') {
            echo json_encode(["status" => "fail", "message" => "Transfer is already " . $transfer['status']]);
            exit;
        }

        $new_status = ($action === 'approve') ? 'approved' : 'rejected';

        // Update transfer status
        $updateStmt = $con->prepare("UPDATE bank_transfers SET status = ?, updated_at = NOW() WHERE transfer_id = ?");
        if ($updateStmt->execute([$new_status, $transfer_id])) {
            // If approved, notify user
            if ($action === 'approve') {
                $userStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
                $userStmt->execute([$transfer['user_id']]);
                $user = $userStmt->fetch(PDO::FETCH_ASSOC);

                if ($user && !empty($user['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
                    include __DIR__ . "/../chat/firebase/send_notification.php";
                    sendFCM(
                        "تم قبول التحويل البنكي",
                        "تم قبول التحويل البنكي بمبلغ " . $transfer['amount'] . " للعقار رقم " . $transfer['property_id'],
                        trim($user['fcm_token'])
                    );
                }
            } else {
                // Notify user of rejection
                $userStmt = $con->prepare("SELECT fcm_token FROM users WHERE users_id = ? LIMIT 1");
                $userStmt->execute([$transfer['user_id']]);
                $user = $userStmt->fetch(PDO::FETCH_ASSOC);

                if ($user && !empty($user['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
                    include __DIR__ . "/../chat/firebase/send_notification.php";
                    $notif_msg = $approval_notes ? "تم رفض التحويل: $approval_notes" : "تم رفض التحويل البنكي";
                    sendFCM(
                        "تم رفض التحويل البنكي",
                        $notif_msg,
                        trim($user['fcm_token'])
                    );
                }
            }

            echo json_encode([
                "status" => "success",
                "message" => "Transfer " . $new_status . " successfully",
                "transfer_id" => (int)$transfer_id
            ]);
        } else {
            echo json_encode(["status" => "fail", "message" => "Failed to update transfer"]);
        }

    } elseif ($action === 'list') {
        $offset = ($page - 1) * $limit;
        
        $where = "WHERE 1=1";
        $params = [];
        
        if ($status_filter) {
            $where .= " AND status = ?";
            $params[] = $status_filter;
        }

        // Get count
        $countStmt = $con->prepare("SELECT COUNT(*) as total FROM bank_transfers $where");
        $countStmt->execute($params);
        $countResult = $countStmt->fetch(PDO::FETCH_ASSOC);
        $total = (int)$countResult['total'];

        // Get transfers
        $listStmt = $con->prepare("
            SELECT bt.*, 
                   u.users_name, u.users_email, u.users_phone,
                   p.title as property_title, p.property_type
            FROM bank_transfers bt
            LEFT JOIN users u ON bt.user_id = u.users_id
            LEFT JOIN properties p ON bt.property_id = p.property_id
            $where
            ORDER BY bt.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        $listStmt->execute($params);
        $transfers = $listStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "status" => "success",
            "data" => $transfers,
            "pagination" => [
                "current_page" => $page,
                "per_page" => $limit,
                "total" => $total,
                "total_pages" => ceil($total / $limit)
            ]
        ]);

    } else {
        echo json_encode(["status" => "fail", "message" => "Invalid action. Use: approve|reject|list"]);
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
