<?php
/**
 * Real Estate API - Property Booking (Visit) Endpoint
 * 
 * Schedule a property visit/viewing appointment
 * 
 * Method: POST
 * Parameters:
 *   - user_id (required): User ID
 *   - property_id (required): Property ID
 *   - booking_date (required): Date in YYYY-MM-DD format
 *   - booking_time (required): Time in HH:MM format
 *   - notes (optional): Special requirements
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : null;
    $property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : null;
    $booking_date = isset($_POST['booking_date']) ? filterRequest('booking_date') : null;
    $booking_time = isset($_POST['booking_time']) ? filterRequest('booking_time') : null;
    $notes = isset($_POST['notes']) ? filterRequest('notes') : '';

    if (!$user_id || !$property_id || !$booking_date || !$booking_time) {
        echo json_encode(["status" => "fail", "message" => "Missing required parameters"]);
        exit;
    }

    // Validate date format
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $booking_date)) {
        echo json_encode(["status" => "fail", "message" => "Invalid booking_date format. Use YYYY-MM-DD"]);
        exit;
    }

    // Validate time format
    if (!preg_match('/^\d{2}:\d{2}$/', $booking_time)) {
        echo json_encode(["status" => "fail", "message" => "Invalid booking_time format. Use HH:MM"]);
        exit;
    }

    // Ensure date is in the future
    $bookingDateTime = strtotime("$booking_date $booking_time");
    if ($bookingDateTime < time()) {
        echo json_encode(["status" => "fail", "message" => "Booking date/time must be in the future"]);
        exit;
    }

    // Verify property exists
    $propStmt = $con->prepare("SELECT property_id FROM properties WHERE property_id = ? LIMIT 1");
    $propStmt->execute([$property_id]);
    if (!$propStmt->fetch()) {
        echo json_encode(["status" => "fail", "message" => "Property not found"]);
        exit;
    }

    // Check for duplicate booking at same time slot
    $dupStmt = $con->prepare("
        SELECT booking_id FROM property_bookings 
        WHERE property_id = ? AND booking_date = ? AND booking_time_slot = ? 
        AND booking_status IN ('pending', 'confirmed')
        LIMIT 1
    ");
    $dupStmt->execute([$property_id, $booking_date, $booking_time]);
    if ($dupStmt->fetch()) {
        echo json_encode(["status" => "fail", "message" => "This time slot is already booked"]);
        exit;
    }

    // Create booking
    $bookStmt = $con->prepare("
        INSERT INTO property_bookings 
        (property_id, user_id, booking_status, booking_date, booking_time_slot, notes, created_at)
        VALUES (?, ?, 'pending', ?, ?, ?, NOW())
    ");

    if ($bookStmt->execute([$property_id, $user_id, $booking_date, $booking_time, $notes])) {
        $booking_id = $con->lastInsertId();

        // Add to calendar for tracking
        $calStmt = $con->prepare("
            INSERT INTO property_calendar 
            (property_id, user_id, event_type, event_date, note, created_at)
            VALUES (?, ?, 'visit', ?, ?, NOW())
        ");
        $calStmt->execute([$property_id, $user_id, $booking_date, "Scheduled visit from user #$user_id"]);

        // Notify admin
        $adminStmt = $con->prepare("SELECT fcm_token FROM users WHERE user_role = 'admin' AND fcm_token IS NOT NULL LIMIT 1");
        $adminStmt->execute([]);
        $admin = $adminStmt->fetch(PDO::FETCH_ASSOC);

        if ($admin && !empty($admin['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
            include __DIR__ . "/../chat/firebase/send_notification.php";
            sendFCM(
                "حجز زيارة عقار",
                "تم حجز زيارة للعقار #$property_id في $booking_date الساعة $booking_time",
                trim($admin['fcm_token'])
            );
        }

        echo json_encode([
            "status" => "success",
            "message" => "Booking created successfully",
            "booking_id" => (int)$booking_id,
            "booking_date" => $booking_date,
            "booking_time" => $booking_time
        ]);
    } else {
        throw new Exception("Failed to create booking");
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to create booking",
        "error" => $e->getMessage()
    ]);
}
?>
