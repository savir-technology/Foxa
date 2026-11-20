<?php
include __DIR__ . "/connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $stmt = $con->prepare("
        SELECT
            v.vendor_id,
            v.vendor_name,
            v.store_name,
            v.store_slug,
            v.vendor_phone,
            v.vendor_logo,
            v.vendor_description,
            s.is_open,
            s.accepts_preorders,
            s.temporary_closed_reason
        FROM vendors v
        LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
        WHERE v.vendor_status = 'active'
          AND v.vendor_is_verified = 1
        ORDER BY COALESCE(NULLIF(v.store_name, ''), v.vendor_name) ASC, v.vendor_id DESC
    ");
    $stmt->execute();

    echo json_encode([
        "status" => "success",
        "data" => $stmt->fetchAll(PDO::FETCH_ASSOC),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
