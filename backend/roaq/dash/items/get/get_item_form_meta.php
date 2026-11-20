<?php
include "../../../connect.php";
ensureAleppoFoodOrderingSchema();

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $colorsStmt = $con->prepare("
        SELECT color_id, color_name, color_hex
        FROM colors
        WHERE color_active = 1
        ORDER BY color_name ASC
    ");
    $colorsStmt->execute();
    $colors = $colorsStmt->fetchAll(PDO::FETCH_ASSOC);

    $sizesStmt = $con->prepare("
        SELECT size_id, size_name, size_order, product_type
        FROM sizes
        ORDER BY size_order ASC, size_name ASC
    ");
    $sizesStmt->execute();
    $sizes = $sizesStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "colors" => $colors,
        "sizes" => $sizes,
        "modifier_group_types" => [
            [
                "value" => "ingredient",
                "label_ar" => "مكونات أساسية",
                "label_en" => "Ingredients",
            ],
            [
                "value" => "modifier",
                "label_ar" => "إضافات",
                "label_en" => "Modifiers",
            ],
        ],
        "modifier_group_defaults" => [
            "min_select" => 0,
            "max_select" => 1,
            "is_required" => false,
        ],
        "modifier_option_defaults" => [
            "price_delta" => 0,
            "image_url" => "",
            "is_default_selected" => false,
            "is_removable" => true,
        ],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
?>
