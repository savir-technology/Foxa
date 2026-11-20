<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);
$paymentStatus = strtolower(trim((string)($input['payment_status'] ?? $_POST['payment_status'] ?? $_GET['payment_status'] ?? '')));
$paymentAmount = (float)($input['payment_amount'] ?? $_POST['payment_amount'] ?? $_GET['payment_amount'] ?? 0);
$userId = (int)($input['user_id'] ?? $_POST['user_id'] ?? $_GET['user_id'] ?? 0);
$orderId = (int)($input['order_id'] ?? $_POST['order_id'] ?? $_GET['order_id'] ?? 0);
$paymentMethod = trim((string)($input['payment_method'] ?? $_POST['payment_method'] ?? $_GET['payment_method'] ?? 'paypal'));

$ordersPaymentMethod = 0;
if ($paymentMethod !== '') {
    $normalizedPaymentMethod = strtolower($paymentMethod);
    if (in_array($normalizedPaymentMethod, ['paypal', 'online', 'card'], true)) {
        $ordersPaymentMethod = 1;
    } elseif ($normalizedPaymentMethod === 'wallet') {
        $ordersPaymentMethod = 2;
    }
}

if ($userId <= 0 || $orderId <= 0 || $paymentAmount <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing payment data',
    ]);
    exit;
}

try {
    $con->beginTransaction();

    $orderStmt = $con->prepare("
        SELECT orders_usersid
        FROM orders
        WHERE orders_id = :oid
          AND orders_usersid = :uid
        LIMIT 1
        FOR UPDATE
    ");
    $orderStmt->execute([
        ':oid' => $orderId,
        ':uid' => $userId,
    ]);
    $orderOwner = $orderStmt->fetchColumn();

    if (!$orderOwner) {
        $con->rollBack();
        echo json_encode([
            'status' => 'error',
            'message' => 'Order not found',
        ]);
        exit;
    }

    $isSuccess = in_array($paymentStatus, ['success', 'paid', 'completed', 'confirmed', 'true'], true);
    $normalizedStatus = $isSuccess ? 'paid' : 'failed';

    $paymentStmt = $con->prepare("
        INSERT INTO payments (
            order_id,
            user_id,
            payment_method,
            payment_status,
            payment_amount,
            payment_date
        ) VALUES (
            :order_id,
            :user_id,
            :payment_method,
            :payment_status,
            :payment_amount,
            NOW()
        )
    ");
    $paymentStmt->execute([
        ':order_id' => $orderId,
        ':user_id' => $userId,
        ':payment_method' => $paymentMethod ?: 'paypal',
        ':payment_status' => $normalizedStatus,
        ':payment_amount' => $paymentAmount,
    ]);

    $updateOrder = $con->prepare("
        UPDATE orders
        SET
            orders_status = :orders_status,
            payment_method = :payment_method,
            orders_paymentmethod = :orders_paymentmethod,
            paid_amount = :paid_amount,
            transaction_id = COALESCE(transaction_id, :txid)
        WHERE orders_id = :oid
          AND orders_usersid = :uid
    ");
    $updateOrder->execute([
        ':orders_status' => $normalizedStatus,
        ':payment_method' => $paymentMethod ?: 'paypal',
        ':orders_paymentmethod' => $ordersPaymentMethod,
        ':paid_amount' => $paymentAmount,
        ':txid' => 'manual_' . $orderId . '_' . time(),
        ':oid' => $orderId,
        ':uid' => $userId,
    ]);

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'message' => 'Payment saved successfully',
        'payment_status' => $normalizedStatus,
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ]);
}
