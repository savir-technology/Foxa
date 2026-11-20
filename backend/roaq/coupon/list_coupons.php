<?php
include "../connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $stmt = $con->prepare("
        SELECT coupon_id, vendor_id, coupon_name, coupon_count, coupon_expiredate, coupon_discount
        FROM coupon
        WHERE vendor_id IS NOT NULL
          AND (coupon_expiredate IS NULL OR DATE(coupon_expiredate) >= CURDATE())
          AND (coupon_count IS NULL OR coupon_count > 0)
        ORDER BY coupon_expiredate DESC, coupon_id DESC
    ");
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'success',
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
