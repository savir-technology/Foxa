<?php
/**
 * Real Estate API - Property Favorites Endpoint
 * 
 * Method: POST
 * Parameters:
 *   - user_id (required): User ID
 *   - property_id (required): Property ID
 *   - action (required): add|remove|list
 *   - page (optional, for 'list' action): Pagination page
 *   - limit (optional, for 'list' action): Items per page
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : null;
    $property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : null;
    $action = isset($_POST['action']) ? filterRequest('action') : 'list';
    $page = isset($_POST['page']) ? max(1, (int)$_POST['page']) : 1;
    $limit = isset($_POST['limit']) ? max(1, (int)$_POST['limit']) : 10;

    if (!$user_id) {
        echo json_encode(["status" => "fail", "message" => "user_id is required"]);
        exit;
    }

    if ($action === 'add' || $action === 'remove') {
        if (!$property_id) {
            echo json_encode(["status" => "fail", "message" => "property_id is required for add/remove actions"]);
            exit;
        }

        // Verify property exists
        $propStmt = $con->prepare("SELECT property_id FROM properties WHERE property_id = ? LIMIT 1");
        $propStmt->execute([$property_id]);
        if (!$propStmt->fetch()) {
            echo json_encode(["status" => "fail", "message" => "Property not found"]);
            exit;
        }
    }

    if ($action === 'add') {
        // Check if already favorited
        $checkStmt = $con->prepare("SELECT favorite_id FROM property_favorites WHERE user_id = ? AND property_id = ? LIMIT 1");
        $checkStmt->execute([$user_id, $property_id]);
        if ($checkStmt->fetch()) {
            echo json_encode(["status" => "failure", "message" => "Property already in favorites"]);
            exit;
        }

        // Add to favorites
        $addStmt = $con->prepare("
            INSERT INTO property_favorites (user_id, property_id, created_at)
            VALUES (?, ?, NOW())
        ");

        if ($addStmt->execute([$user_id, $property_id])) {
            echo json_encode([
                "status" => "success",
                "message" => "Property added to favorites",
                "favorite_id" => (int)$con->lastInsertId()
            ]);
        } else {
            echo json_encode(["status" => "fail", "message" => "Failed to add to favorites"]);
        }

    } elseif ($action === 'remove') {
        $removeStmt = $con->prepare("DELETE FROM property_favorites WHERE user_id = ? AND property_id = ?");
        if ($removeStmt->execute([$user_id, $property_id])) {
            echo json_encode(["status" => "success", "message" => "Property removed from favorites"]);
        } else {
            echo json_encode(["status" => "fail", "message" => "Failed to remove from favorites"]);
        }

    } elseif ($action === 'list') {
        $offset = ($page - 1) * $limit;

        // Get count
        $countStmt = $con->prepare("SELECT COUNT(*) as total FROM property_favorites WHERE user_id = ?");
        $countStmt->execute([$user_id]);
        $countResult = $countStmt->fetch(PDO::FETCH_ASSOC);
        $total = (int)$countResult['total'];

        // Get favorites with property details
        $listStmt = $con->prepare("
            SELECT p.*, pf.created_at as favorited_at,
                   (SELECT COUNT(*) FROM property_images WHERE property_id = p.property_id) as image_count
            FROM property_favorites pf
            JOIN properties p ON pf.property_id = p.property_id
            WHERE pf.user_id = ?
            ORDER BY pf.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $listStmt->execute([$user_id, (int)$limit, (int)$offset]);
        $favorites = $listStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "status" => "success",
            "data" => $favorites,
            "pagination" => [
                "current_page" => $page,
                "per_page" => $limit,
                "total" => $total,
                "total_pages" => ceil($total / $limit)
            ]
        ]);

    } else {
        echo json_encode(["status" => "fail", "message" => "Invalid action. Use: add|remove|list"]);
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
