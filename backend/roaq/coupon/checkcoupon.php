<?php

include "../connect.php";

header('Content-Type: application/json; charset=utf-8');

$couponName = trim((string)filterRequest('couponname'));
if ($couponName === '') {
    echo json_encode(['status' => 'error', 'message' => 'Coupon code is required']);
    exit;
}

try {
    $stmt = $con->prepare('SELECT coupon_id, vendor_id, coupon_name, coupon_count,
        coupon_expiredate, coupon_discount
        FROM coupon
        WHERE coupon_name = :name
          AND coupon_count > 0
          AND coupon_expiredate > NOW()
        LIMIT 1');
    $stmt->execute([':name' => $couponName]);
    $coupon = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$coupon) {
        echo json_encode(['status' => 'error', 'message' => 'Coupon not valid'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode(['status' => 'success', 'data' => $coupon], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Unable to validate coupon'], JSON_UNESCAPED_UNICODE);
}
?>
