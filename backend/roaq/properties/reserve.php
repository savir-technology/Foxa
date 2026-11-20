<?php
/**
 * Real Estate API - Property Reservation Endpoint
 * 
 * Create a property reservation (purchase contract initiation)
 * 
 * Method: POST
 * Parameters:
 *   - user_id (required): User ID
 *   - property_id (required): Property ID
 *   - installment_plan_id (optional): Selected installment plan
 *   - reservation_notes (optional): Special notes or requirements
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : null;
    $property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : null;
    $plan_id = isset($_POST['installment_plan_id']) ? (int)$_POST['installment_plan_id'] : null;
    $notes = isset($_POST['reservation_notes']) ? filterRequest('reservation_notes') : '';

    if (!$user_id || !$property_id) {
        echo json_encode(["status" => "fail", "message" => "user_id and property_id required"]);
        exit;
    }

    // Verify property exists
    $propStmt = $con->prepare("SELECT property_id, status FROM properties WHERE property_id = ? LIMIT 1");
    $propStmt->execute([$property_id]);
    $property = $propStmt->fetch(PDO::FETCH_ASSOC);

    if (!$property) {
        echo json_encode(["status" => "fail", "message" => "Property not found"]);
        exit;
    }

    // Check if property is available
    if ($property['status'] !== 'available') {
        echo json_encode(["status" => "fail", "message" => "Property is not available for reservation"]);
        exit;
    }

    // Check if user already has an active reservation for this property
    $existStmt = $con->prepare("SELECT reservation_id FROM property_reservations WHERE property_id = ? AND user_id = ? AND reservation_status IN ('pending', 'confirmed') LIMIT 1");
    $existStmt->execute([$property_id, $user_id]);
    if ($existStmt->fetch()) {
        echo json_encode(["status" => "fail", "message" => "User already has an active reservation for this property"]);
        exit;
    }

    // Get installment plan details if provided
    $plan_details = null;
    if ($plan_id) {
        $planStmt = $con->prepare("SELECT plan_id, total_amount, down_payment, installment_type, installment_count, installment_value FROM installment_plans WHERE plan_id = ? AND property_id = ? LIMIT 1");
        $planStmt->execute([$plan_id, $property_id]);
        $plan_details = $planStmt->fetch(PDO::FETCH_ASSOC);

        if (!$plan_details) {
            echo json_encode(["status" => "fail", "message" => "Installment plan not found for this property"]);
            exit;
        }
    }

    // Create reservation
    $resStmt = $con->prepare("
        INSERT INTO property_reservations 
        (property_id, user_id, installment_plan_id, reservation_status, reservation_notes, created_at)
        VALUES (?, ?, ?, 'pending', ?, NOW())
    ");

    if ($resStmt->execute([$property_id, $user_id, $plan_id, $notes])) {
        $reservation_id = $con->lastInsertId();

        // Notify admin via FCM if available
        $adminStmt = $con->prepare("SELECT fcm_token FROM users WHERE user_role = 'admin' AND fcm_token IS NOT NULL LIMIT 1");
        $adminStmt->execute([]);
        $admin = $adminStmt->fetch(PDO::FETCH_ASSOC);

        if ($admin && !empty($admin['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
            include __DIR__ . "/../chat/firebase/send_notification.php";
            sendFCM(
                "حجز عقار جديد",
                "تم استقبال حجز جديد للعقار #$property_id من قبل المستخدم #$user_id",
                trim($admin['fcm_token'])
            );
        }

        echo json_encode([
            "status" => "success",
            "message" => "Reservation created successfully",
            "reservation_id" => (int)$reservation_id,
            "installment_plan" => $plan_details
        ]);
    } else {
        throw new Exception("Failed to create reservation");
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to create reservation",
        "error" => $e->getMessage()
    ]);
}
?>
