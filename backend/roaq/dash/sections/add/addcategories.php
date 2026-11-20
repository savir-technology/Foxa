<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    ensureVendorCategorySchema();
    $actor = requireDashboardActor(['vendor', 'master']);

    $data = json_decode(file_get_contents("php://input"));
    if (
        !isset($data->categories_name_en) ||
        !isset($data->categories_name_ar) ||
        !isset($data->categories_image)
    ) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Missing required fields',
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $catNameEn = trim((string)$data->categories_name_en);
    $catNameAr = trim((string)$data->categories_name_ar);
    $catImage = (string)$data->categories_image;
    $requestedType = strtolower(trim((string)($data->category_type ?? '')));
    $vendorId = 0;
    $categoryScope = 'restaurant';
    if (($actor['role'] ?? '') === 'vendor') {
        $vendor = $actor['vendor'] ?? [];
        $vendorId = (int)($vendor['vendor_id'] ?? 0);
        $requestedType = strtolower((string)($vendor['vendor_type'] ?? 'restaurant')) === 'store'
            ? 'store'
            : 'restaurant';
        $categoryScope = $requestedType === 'store'
            ? (strtolower(trim((string)($vendor['store_category'] ?? 'general'))) ?: 'general')
            : 'restaurant';
    } elseif (!in_array($requestedType, ['restaurant', 'store'], true)) {
        $requestedType = 'restaurant';
    }

    if ($catNameEn === '' || $catNameAr === '' || $catImage === '') {
        echo json_encode([
            'status' => 'error',
            'message' => 'Missing required fields',
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $uploadDir = __DIR__ . "/../../../uploud/categories/";
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $imageName = uniqid('category_', true) . '.png';
    $imageData = base64_decode($catImage);
    file_put_contents($uploadDir . $imageName, $imageData);

    $stmt = $con->prepare("
        INSERT INTO categories (
            categories_name_en,
            categories_name_ar,
            categories_image,
            vendor_id,
            category_type
            , category_scope
        ) VALUES (
            :categories_name_en,
            :categories_name_ar,
            :categories_image,
            :vendor_id,
            :category_type, :category_scope
        )
    ");
    $stmt->execute([
        ':categories_name_en' => $catNameEn,
        ':categories_name_ar' => $catNameAr,
        ':categories_image' => $imageName,
        ':vendor_id' => $vendorId,
        ':category_type' => $requestedType,
        ':category_scope' => $categoryScope,
    ]);

    echo json_encode([
        'status' => 'success',
        'message' => 'Category added successfully',
        'image' => 'https://savir-technology.online/roaqv2/uploud/categories/' . $imageName,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
