<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../../connect.php";

try {
    $itemId = intval($_POST['item_id'] ?? 0);
    $address = trim((string) ($_POST['property_address'] ?? ''));
    $lat = floatval($_POST['property_lat'] ?? 0);
    $lng = floatval($_POST['property_lng'] ?? 0);

    if ($itemId <= 0) {
        throw new Exception("معرف العقار مفقود");
    }
    if ($lat == 0 && $lng == 0) {
        throw new Exception("الإحداثيات الجغرافية مفقودة");
    }

    // Keep legacy columns in items table updated.
    $stmt = $con->prepare("
        UPDATE items
        SET property_address = :address,
            property_lat = :lat,
            property_lng = :lng
        WHERE items_id = :item_id
    ");
    $stmt->execute([
        ':address' => ($address !== '' ? $address : 'موقع محدد'),
        ':lat' => $lat,
        ':lng' => $lng,
        ':item_id' => $itemId,
    ]);

    // Dedicated table for map pin / precise location.
    $con->exec("
        CREATE TABLE IF NOT EXISTS property_locations (
            item_id INT PRIMARY KEY,
            location_title VARCHAR(255) NULL,
            location_address VARCHAR(500) NULL,
            latitude DECIMAL(10,7) NOT NULL,
            longitude DECIMAL(10,7) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $upsert = $con->prepare("
        INSERT INTO property_locations (item_id, location_title, location_address, latitude, longitude)
        VALUES (:item_id, :title, :address, :lat, :lng)
        ON DUPLICATE KEY UPDATE
            location_title = VALUES(location_title),
            location_address = VALUES(location_address),
            latitude = VALUES(latitude),
            longitude = VALUES(longitude)
    ");
    $upsert->execute([
        ':item_id' => $itemId,
        ':title' => trim((string) ($_POST['location_title'] ?? '')),
        ':address' => ($address !== '' ? $address : null),
        ':lat' => $lat,
        ':lng' => $lng,
    ]);

    echo json_encode([
        "status" => "success",
        "message" => "تم حفظ الموقع بنجاح",
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(400);
    error_log("update_property_location.php error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
