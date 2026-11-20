<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../../connect.php";

function hasTable(PDO $con, string $table): bool
{
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table
    ");
    $stmt->execute([':table' => $table]);
    return ((int) $stmt->fetchColumn()) > 0;
}

try {
    $itemId = intval($_POST['item_id'] ?? $_GET['item_id'] ?? 0);
    if ($itemId <= 0) {
        throw new Exception("معرف العقار مفقود");
    }

    $hasLocations = hasTable($con, 'property_locations');
    $sql = "
        SELECT
            i.items_id,
            i.items_name_ar,
            i.items_name_en,
            i.items_price,
            i.items_image,
            " . ($hasLocations ? "COALESCE(pl.location_address, i.property_address)" : "i.property_address") . " AS property_address,
            " . ($hasLocations ? "COALESCE(pl.latitude, i.property_lat)" : "i.property_lat") . " AS property_lat,
            " . ($hasLocations ? "COALESCE(pl.longitude, i.property_lng)" : "i.property_lng") . " AS property_lng,
            i.property_rooms,
            i.property_bathrooms,
            i.property_floor,
            i.property_area
        FROM items i
        " . ($hasLocations ? "LEFT JOIN property_locations pl ON pl.item_id = i.items_id" : "") . "
        WHERE i.items_id = :item_id
        LIMIT 1
    ";

    $stmt = $con->prepare($sql);
    $stmt->execute([':item_id' => $itemId]);
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$item) {
        throw new Exception("العقار غير موجود");
    }

    echo json_encode([
        "status" => "success",
        "data" => $item,
        "has_location" => !empty($item['property_lat']) && !empty($item['property_lng']),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(400);
    error_log("get_property_location.php error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
