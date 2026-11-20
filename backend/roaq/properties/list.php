<?php
/**
 * Real Estate API - Property Listing Endpoint
 * 
 * Features:
 * - List all available properties with pagination
 * - Filter by property_type, city, price range, status
 * - Order by price, date, popularity
 * - Include user favorites status
 * - Include image count
 * 
 * Method: POST/GET
 * Parameters:
 *   - user_id (optional): For favorite status
 *   - type (optional): apartment|villa|land|commercial
 *   - city (optional): Filter by city
 *   - min_price (optional): Minimum price filter
 *   - max_price (optional): Maximum price filter
 *   - rooms (optional): Number of rooms
 *   - page (optional, default: 1): Pagination
 *   - limit (optional, default: 10): Items per page
 *   - sort (optional): price_asc|price_desc|newest|oldest
 *   - status (optional): available|reserved|sold
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    // Retrieve and sanitize parameters
    $user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : (isset($_GET['user_id']) ? (int)$_GET['user_id'] : null);
    $type = isset($_POST['type']) ? filterRequest('type') : (isset($_GET['type']) ? $_GET['type'] : null);
    $city = isset($_POST['city']) ? filterRequest('city') : (isset($_GET['city']) ? $_GET['city'] : null);
    $min_price = isset($_POST['min_price']) ? (float)$_POST['min_price'] : (isset($_GET['min_price']) ? (float)$_GET['min_price'] : null);
    $max_price = isset($_POST['max_price']) ? (float)$_POST['max_price'] : (isset($_GET['max_price']) ? (float)$_GET['max_price'] : null);
    $rooms = isset($_POST['rooms']) ? (int)$_POST['rooms'] : (isset($_GET['rooms']) ? (int)$_GET['rooms'] : null);
    $page = isset($_POST['page']) ? max(1, (int)$_POST['page']) : (isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1);
    $limit = isset($_POST['limit']) ? max(1, (int)$_POST['limit']) : (isset($_GET['limit']) ? max(1, (int)$_GET['limit']) : 10);
    $sort = isset($_POST['sort']) ? filterRequest('sort') : (isset($_GET['sort']) ? $_GET['sort'] : 'newest');
    $status = isset($_POST['status']) ? filterRequest('status') : (isset($_GET['status']) ? $_GET['status'] : 'available');

    // Build WHERE clause
    $where = "WHERE 1=1";
    $params = [];
    
    if ($status) {
        $where .= " AND status = ?";
        $params[] = $status;
    }
    
    if ($type) {
        $where .= " AND property_type = ?";
        $params[] = $type;
    }
    
    if ($city) {
        $where .= " AND city LIKE ?";
        $params[] = "%$city%";
    }
    
    if ($min_price !== null) {
        $where .= " AND price >= ?";
        $params[] = $min_price;
    }
    
    if ($max_price !== null) {
        $where .= " AND price <= ?";
        $params[] = $max_price;
    }
    
    if ($rooms !== null) {
        $where .= " AND rooms >= ?";
        $params[] = $rooms;
    }

    // Build ORDER clause
    $order = "ORDER BY created_at DESC";
    if ($sort === 'price_asc') {
        $order = "ORDER BY price ASC";
    } elseif ($sort === 'price_desc') {
        $order = "ORDER BY price DESC";
    } elseif ($sort === 'newest') {
        $order = "ORDER BY created_at DESC";
    } elseif ($sort === 'oldest') {
        $order = "ORDER BY created_at ASC";
    }

    // Calculate offset
    $offset = ($page - 1) * $limit;

    // Count total properties
    $countStmt = $con->prepare("SELECT COUNT(*) as total FROM properties $where");
    $countStmt->execute($params);
    $countResult = $countStmt->fetch(PDO::FETCH_ASSOC);
    $total = (int)$countResult['total'];

    // Fetch properties
    $stmt = $con->prepare("
        SELECT p.*, 
               (SELECT COUNT(*) FROM property_images WHERE property_id = p.property_id) as image_count,
               (SELECT COUNT(*) FROM property_favorites WHERE property_id = p.property_id AND user_id = ?) as is_favorite
        FROM properties p
        $where
        $order
        LIMIT ? OFFSET ?
    ");
    
    // Add user_id to params for favorite check
    array_unshift($params, $user_id ?? 0);
    $params[] = (int)$limit;
    $params[] = (int)$offset;
    
    $stmt->execute($params);
    $properties = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format response
    $response = [
        "status" => "success",
        "data" => $properties,
        "pagination" => [
            "current_page" => $page,
            "per_page" => $limit,
            "total" => $total,
            "total_pages" => ceil($total / $limit)
        ]
    ];

    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to fetch properties",
        "error" => $e->getMessage()
    ]);
}
?>
