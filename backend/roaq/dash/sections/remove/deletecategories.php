<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    ensureVendorCategorySchema();
    $actor = requireDashboardActor(['vendor', 'master']);

    $id = 0;
    if (isset($_GET['id'])) {
        $id = (int)$_GET['id'];
    } else {
        $data = json_decode(file_get_contents("php://input"));
        $id = isset($data->categories_id) ? (int)$data->categories_id : 0;
    }

    if ($id <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid ID',
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $stmt = $con->prepare("
        SELECT categories_image, vendor_id
        FROM categories
        WHERE categories_id = :id
        LIMIT 1
    ");
    $stmt->execute([':id' => $id]);
    $category = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$category) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Category not found',
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if (($actor['role'] ?? '') === 'vendor' &&
        (int)($category['vendor_id'] ?? 0) !== (int)($actor['vendor']['vendor_id'] ?? 0)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'You can only delete your own categories',
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $imageName = (string)($category['categories_image'] ?? '');
    $imagePath = __DIR__ . "/../../../uploud/categories/" . $imageName;

    $deleteStmt = $con->prepare("
        DELETE FROM categories
        WHERE categories_id = :id
    ");
    $deleteStmt->execute([
        ':id' => $id,
    ]);

    if (file_exists($imagePath)) {
        unlink($imagePath);
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'Category deleted successfully',
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
