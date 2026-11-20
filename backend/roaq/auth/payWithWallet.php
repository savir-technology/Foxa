<?php
include "../connect.php";

$userId = (int) filterRequest("user_id");
$orderId = (int) filterRequest("order_id");
$total = (float) filterRequest("total");

if ($userId <= 0 || $orderId <= 0 || $total <= 0) {
    printFailure("MISSING_DATA");
    exit;
}

try {
    $con->beginTransaction();

    $ensureWallet = $con->prepare("
        INSERT INTO wallet (user_id, points, balance)
        VALUES (:uid, 0, 0)
        ON DUPLICATE KEY UPDATE user_id = user_id
    ");
    $ensureWallet->execute([':uid' => $userId]);

    $walletStmt = $con->prepare("
        SELECT balance
        FROM wallet
        WHERE user_id = :uid
        FOR UPDATE
    ");
    $walletStmt->execute([':uid' => $userId]);
    $walletBalance = (float)($walletStmt->fetchColumn() ?: 0);

    $orderStmt = $con->prepare("
        SELECT orders_id
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
    if (!$orderStmt->fetchColumn()) {
        $con->rollBack();
        printFailure("ORDER_NOT_FOUND");
        exit;
    }

    if ($walletBalance < $total) {
        $con->rollBack();
        printFailure("NO_ENOUGH_BALANCE");
        exit;
    }

    $deductStmt = $con->prepare("
        UPDATE wallet
        SET balance = balance - :amount
        WHERE user_id = :uid
    ");
    $deductStmt->execute([
        ':amount' => $total,
        ':uid' => $userId,
    ]);

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
            'wallet',
            'paid',
            :payment_amount,
            NOW()
        )
    ");
    $paymentStmt->execute([
        ':order_id' => $orderId,
        ':user_id' => $userId,
        ':payment_amount' => $total,
    ]);

    $updateOrder = $con->prepare("
        UPDATE orders
        SET
            orders_status = 'paid',
            payment_method = 'wallet',
            orders_paymentmethod = 2,
            paid_amount = :amount
        WHERE orders_id = :oid
          AND orders_usersid = :uid
    ");
    $updateOrder->execute([
        ':amount' => $total,
        ':oid' => $orderId,
        ':uid' => $userId,
    ]);

    $con->commit();
    printSuccess("WALLET_PAYMENT_DONE");
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    printFailure($e->getMessage());
}
