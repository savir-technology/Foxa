<?php
/**
 * Real Estate API - Property Documents Endpoint
 * 
 * Upload property documents (deed, certificate, blueprint, inspection report, contract, etc.)
 * 
 * Method: POST
 * Parameters:
 *   - property_id (required): Property ID
 *   - admin_id (required): Admin authorization
 *   - document_type (required): deed|certificate|blueprint|inspection_report|contract|other
 *   - document_name (required): Human-readable document name
 *   - file 'property_document' (required): PDF or image file
 */

header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

try {
    $property_id = isset($_POST['property_id']) ? (int)$_POST['property_id'] : null;
    $admin_id = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : null;
    $document_type = isset($_POST['document_type']) ? filterRequest('document_type') : 'other';
    $document_name = isset($_POST['document_name']) ? filterRequest('document_name') : null;

    if (!$property_id || !$admin_id || !$document_name || !isset($_FILES['property_document'])) {
        echo json_encode(["status" => "fail", "message" => "Missing required parameters or file"]);
        exit;
    }

    // Verify admin
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

    // Validate document
    $allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
    $max_size = 10 * 1024 * 1024; // 10MB

    if (!in_array($_FILES['property_document']['type'], $allowed)) {
        echo json_encode(["status" => "fail", "message" => "Invalid file type. Allowed: PDF, JPEG, PNG, WebP"]);
        exit;
    }

    if ($_FILES['property_document']['size'] > $max_size) {
        echo json_encode(["status" => "fail", "message" => "File too large. Maximum 10MB"]);
        exit;
    }

    // Create upload directory
    $upload_dir = "../uploads/property_documents/";
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }

    // Generate unique filename
    $ext = pathinfo($_FILES['property_document']['name'], PATHINFO_EXTENSION);
    $filename = time() . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
    $filepath = $upload_dir . $filename;

    // Move file
    if (!move_uploaded_file($_FILES['property_document']['tmp_name'], $filepath)) {
        echo json_encode(["status" => "fail", "message" => "Failed to upload document"]);
        exit;
    }

    // Insert document record
    $docStmt = $con->prepare("
        INSERT INTO property_documents 
        (property_id, document_type, document_name, document_url, uploaded_by_admin, created_at)
        VALUES (?, ?, ?, ?, 1, NOW())
    ");

    if ($docStmt->execute([$property_id, $document_type, $document_name, "uploads/property_documents/" . $filename])) {
        $document_id = $con->lastInsertId();
        echo json_encode([
            "status" => "success",
            "message" => "Document uploaded successfully",
            "document_id" => (int)$document_id,
            "document_url" => "uploads/property_documents/" . $filename
        ]);
    } else {
        unlink($filepath);
        echo json_encode(["status" => "fail", "message" => "Failed to save document record"]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Failed to upload document",
        "error" => $e->getMessage()
    ]);
}
?>
