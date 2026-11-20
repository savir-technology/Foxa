<?php
include "../../../connect.php";
header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    ensureVendorCategorySchema();
    $actor = requireDashboardActor(['vendor', 'master']);
    if (($actor['role'] ?? '') === 'master') {
        requireMasterPermission($actor['master'] ?? [], 'restaurants.view');
    }

    $sql = "
        SELECT
            categories_id,
            categories_name_en,
            categories_name_ar,
            categories_image,
            vendor_id,
            category_type,
            category_scope
        FROM categories
        WHERE categories_active = 1
    ";

    if (($actor['role'] ?? '') === 'vendor') {
        // Shared categories are available to every vendor in the same
        // activity. Keep the requested specialization first, but allow the
        // shared/general catalogue as a fallback for newly-created vendors
        // and categories created before category_scope was introduced.
        $sql .= " AND (vendor_id = :vendor_id OR (vendor_id = 0 AND category_type = :category_type AND (category_scope = :category_scope OR category_scope = 'general'))) ";
    }

    $sql .= "
        ORDER BY categories_id DESC
    ";
    $stmt = $con->prepare($sql);
    $params = [];
    if (($actor['role'] ?? '') === 'vendor') {
        $vendor = $actor['vendor'] ?? [];
        $params[':vendor_id'] = (int)($vendor['vendor_id'] ?? 0);
        $params[':category_type'] = strtolower((string)($vendor['vendor_type'] ?? 'restaurant')) === 'store'
            ? 'store'
            : 'restaurant';
        $params[':category_scope'] = strtolower((string)($vendor['vendor_type'] ?? 'restaurant')) === 'store'
            ? strtolower((string)($vendor['store_category'] ?? 'general'))
            : 'restaurant';
    }
    $stmt->execute($params);

    // A new store must never start with an empty category selector just
    // because its specialization has no scoped rows yet. The categories are
    // still restricted to store activity; the products remain vendor-owned.
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (($actor['role'] ?? '') === 'vendor' && empty($rows)) {
        $vendor = $actor['vendor'] ?? [];
        if (strtolower((string)($vendor['vendor_type'] ?? 'restaurant')) === 'store') {
            $fallback = $con->prepare("SELECT categories_id, categories_name_en, categories_name_ar, categories_image, vendor_id, category_type, category_scope FROM categories WHERE categories_active = 1 AND vendor_id = 0 AND category_type = 'store' ORDER BY categories_id DESC");
            $fallback->execute();
            $rows = $fallback->fetchAll(PDO::FETCH_ASSOC);
        }
    }

    echo json_encode([
        'status' => 'success',
        'data' => $rows,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
