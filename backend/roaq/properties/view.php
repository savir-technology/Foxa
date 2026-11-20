<?php
/**
 * Real Estate API - Property Details Endpoint
 * 
 * Get detailed information about a specific property
 * Includes: images, documents, reservations, reviews, installment plans
 * 
 * Method: POST/GET
 * Parameters:
 *   - property_id (required): Property ID
 *   - user_id (optional): For favorite status and permissions
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : (isset($_GET['property_id']) ? (int)$_GET['property_id'] : null);
    $user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : (isset($_GET['user_id']) ? (int)$_GET['user_id'] : null);

    if (!$property_id) {
        echo json_encode(["status" => "fail", "message" => "property_id is required"]);
        exit;
    }

    // Fetch property details
    $stmt = $con->prepare("SELECT * FROM properties WHERE property_id = ? LIMIT 1");
    $stmt->execute([$property_id]);
    $property = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$property) {
        echo json_encode(["status" => "failure", "message" => "Property not found"]);
        exit;
    }

    // Fetch property images
    $imgStmt = $con->prepare("SELECT image_id, image_url, image_order, image_type FROM property_images WHERE property_id = ? ORDER BY image_order ASC");
    $imgStmt->execute([$property_id]);
    $images = $imgStmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch property documents
    $docStmt = $con->prepare("SELECT document_id, document_type, document_name, document_url FROM property_documents WHERE property_id = ? ORDER BY created_at DESC");
    $docStmt->execute([$property_id]);
    $documents = $docStmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch installment plans
    $planStmt = $con->prepare("SELECT plan_id, total_amount, down_payment, installment_type, installment_count, installment_value FROM installment_plans WHERE property_id = ? ORDER BY created_at DESC");
    $planStmt->execute([$property_id]);
    $plans = $planStmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch active reservations count
    $resStmt = $con->prepare("SELECT COUNT(*) as active_reservations FROM property_reservations WHERE property_id = ? AND reservation_status = 'confirmed'");
    $resStmt->execute([$property_id]);
    $reservations = $resStmt->fetch(PDO::FETCH_ASSOC);

    // Fetch property reviews/ratings
    $reviewStmt = $con->prepare("SELECT COUNT(*) as review_count, AVG(rating) as average_rating FROM property_reviews WHERE property_id = ?");
    $reviewStmt->execute([$property_id]);
    $reviews = $reviewStmt->fetch(PDO::FETCH_ASSOC);

    // Check if user favorited this property
    $favStmt = $con->prepare("SELECT favorite_id FROM property_favorites WHERE property_id = ? AND user_id = ? LIMIT 1");
    $favStmt->execute([$property_id, $user_id ?? 0]);
    $favorite = $favStmt->fetch(PDO::FETCH_ASSOC);

    $response = [
        "status" => "success",
        "property" => $property,
        "images" => $images,
        "documents" => $documents,
        "installment_plans" => $plans,
        "active_reservations" => (int)($reservations['active_reservations'] ?? 0),
        "reviews" => [
            "count" => (int)($reviews['review_count'] ?? 0),
            "average_rating" => (float)($reviews['average_rating'] ?? 0)
        ],
        "is_favorite" => !empty($favorite)
    ];

    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to fetch property details",
        "error" => $e->getMessage()
    ]);
}
?>
