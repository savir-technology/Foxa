<?php
/**
 * Real Estate API - Property Images Endpoint
 * 
 * Upload and manage property images
 * 
 * Method: POST
 * Parameters:
 *   - property_id (required): Property ID
 *   - admin_id (required): Admin authorization
 *   - image_type (required): gallery|main|floor_plan
 *   - file 'property_image' (required): Image file (JPG, PNG, WebP)
 *   - image_order (optional, default: last+1): Display order
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : null;
    $admin_id = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : null;
    $image_type = isset($_POST['image_type']) ? filterRequest('image_type') : 'gallery';
    $image_order = isset($_POST['image_order']) ? (int)$_POST['image_order'] : null;

    if (!$property_id || !$admin_id || !isset($_FILES['property_image'])) {
        echo json_encode(["status" => "fail", "message" => "Missing required parameters or file"]);
        exit;
    }

    // Verify admin exists
    $adminStmt = $con->prepare("SELECT admin_id FROM admin WHERE admin_id = ? LIMIT 1");
    $adminStmt->execute([$admin_id]);
    if (!$adminStmt->fetch()) {
        echo json_encode(["status" => "fail", "message" => "Admin not found"]);
        exit;
    }

    // Verify property exists
    $propStmt = $con->prepare("SELECT property_id FROM properties WHERE property_id = ? LIMIT 1");
    $propStmt->execute([$property_id]);
    if (!$propStmt->fetch()) {
        echo json_encode(["status" => "fail", "message" => "Property not found"]);
        exit;
    }

    // Validate image
    $allowed = ['image/jpeg', 'image/png', 'image/webp'];
    $max_size = 5 * 1024 * 1024; // 5MB

    if (!in_array($_FILES['property_image']['type'], $allowed)) {
        echo json_encode(["status" => "fail", "message" => "Invalid image type. Allowed: JPEG, PNG, WebP"]);
        exit;
    }

    if ($_FILES['property_image']['size'] > $max_size) {
        echo json_encode(["status" => "fail", "message" => "File too large. Maximum 5MB"]);
        exit;
    }

    // Create upload directory
    $upload_dir = "../uploads/property_images/";
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }

    // Generate unique filename
    $ext = pathinfo($_FILES['property_image']['name'], PATHINFO_EXTENSION);
    $filename = time() . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
    $filepath = $upload_dir . $filename;

    // Move file
    if (!move_uploaded_file($_FILES['property_image']['tmp_name'], $filepath)) {
        echo json_encode(["status" => "fail", "message" => "Failed to upload image"]);
        exit;
    }

    // Get next order number if not specified
    if ($image_order === null) {
        $orderStmt = $con->prepare("SELECT MAX(image_order) as max_order FROM property_images WHERE property_id = ?");
        $orderStmt->execute([$property_id]);
        $orderResult = $orderStmt->fetch(PDO::FETCH_ASSOC);
        $image_order = ($orderResult['max_order'] ?? 0) + 1;
    }

    // Insert image record
    $imgStmt = $con->prepare("
        INSERT INTO property_images 
        (property_id, image_url, image_order, image_type, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ");

    if ($imgStmt->execute([$property_id, "uploads/property_images/" . $filename, $image_order, $image_type])) {
        $image_id = $con->lastInsertId();
        echo json_encode([
            "status" => "success",
            "message" => "Image uploaded successfully",
            "image_id" => (int)$image_id,
            "image_url" => "uploads/property_images/" . $filename
        ]);
    } else {
        unlink($filepath);
        echo json_encode(["status" => "fail", "message" => "Failed to save image record"]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to upload image",
        "error" => $e->getMessage()
    ]);
}
?>
