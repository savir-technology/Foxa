<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function financeWalletError(string $message, int $statusCode = 400): void
{
    respondJson([
        'status' => 'error',
        'message' => $message,
    ], $statusCode);
}

function financeWalletNormalizeStatus($value): string
{
    return strtolower(trim((string)$value));
}

function financeWalletIsCanceled(string $status): bool
{
    return in_array($status, [
        'canceled',
        'cancelled',
        'cancelled_by_user',
        'canceled_by_user',
        'failed',
        'rejected',
        'refunded',
        'refund',
        'returned',
        'return',
        '-1',
        '5',
    ], true);
}

function financeWalletIsOnlinePayment(string $method, string $transactionId, string $gatewayRef): bool
{
    if (trim($transactionId) !== '' || trim($gatewayRef) !== '') {
        return true;
    }

    $method = strtolower(trim($method));
    if ($method === '') {
        return false;
    }

    foreach (['visa', 'card', 'credit', 'debit', 'online', 'paypal', 'paymob', 'mastercard', 'meeza'] as $needle) {
        if (strpos($method, $needle) !== false) {
            return true;
        }
    }

    return false;
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'finance.refund');
    $payload = getRequestPayload();
    $orderId = (int)($payload['order_id'] ?? 0);
    $note = trim((string)($payload['note'] ?? ''));

    if ($orderId <= 0) {
        financeWalletError('رقم الطلب مطلوب لرد نقاط المحفظة');
    }

    if (!tableExists('orders')) {
        financeWalletError('جدول الطلبات غير متاح');
    }

    $walletRequiredColumns = ['id', 'user_id', 'points', 'balance'];
    $refundLogRequiredColumns = ['id', 'order_id', 'user_id', 'points', 'amount', 'note', 'created_by', 'created_at'];
    if (!tableExists('wallet') || !tableExists('wallet_refund_logs')) {
        financeWalletError('جداول المحفظة غير متاحة. طبّق migration 20260818_master_wallet_tables.sql أولًا.', 409);
    }
    foreach ($walletRequiredColumns as $column) {
        if (!columnExists('wallet', $column)) {
            financeWalletError('بنية المحفظة غير مكتملة. طبّق migration 20260818_master_wallet_tables.sql أولًا.', 409);
        }
    }
    foreach ($refundLogRequiredColumns as $column) {
        if (!columnExists('wallet_refund_logs', $column)) {
            financeWalletError('بنية سجل استرداد المحفظة غير مكتملة. طبّق migration 20260818_master_wallet_tables.sql أولًا.', 409);
        }
    }

    $statusSelect = columnExists('orders', 'status') ? "status" : "'' AS status";
    $paymentMethodSelect = columnExists('orders', 'payment_method') ? "payment_method" : "'' AS payment_method";
    $ordersPaymentSelect = columnExists('orders', 'orders_paymentmethod') ? "orders_paymentmethod" : "0 AS orders_paymentmethod";
    $paidAmountSelect = columnExists('orders', 'paid_amount') ? "paid_amount" : "0 AS paid_amount";
    $transactionSelect = columnExists('orders', 'transaction_id') ? "transaction_id" : "'' AS transaction_id";
    $gatewayRefSelect = columnExists('orders', 'orders_gateway_ref') ? "orders_gateway_ref" : "'' AS orders_gateway_ref";

    $orderStmt = $con->prepare("
        SELECT
            orders_id,
            orders_usersid,
            orders_totalprice,
            orders_status,
            {$statusSelect},
            {$paymentMethodSelect},
            {$ordersPaymentSelect},
            {$paidAmountSelect},
            {$transactionSelect},
            {$gatewayRefSelect}
        FROM orders
        WHERE orders_id = :order_id
        LIMIT 1
    ");
    $orderStmt->execute([':order_id' => $orderId]);
    $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
    if (!$order) {
        financeWalletError('الطلب غير موجود', 404);
    }

    $orderStatus = financeWalletNormalizeStatus($order['status'] ?? '');
    if ($orderStatus === '') {
        $orderStatus = financeWalletNormalizeStatus($order['orders_status'] ?? '');
    }

    if (!financeWalletIsCanceled($orderStatus)) {
        financeWalletError('لا يمكن رد النقاط إلا لطلب ملغي أو مرفوض أو مسترد');
    }

    $paymentMethod = (string)($order['payment_method'] ?? '');
    $ordersPaymentMethod = (string)($order['orders_paymentmethod'] ?? '');
    $transactionId = (string)($order['transaction_id'] ?? '');
    $gatewayRef = (string)($order['orders_gateway_ref'] ?? '');
    $isNumericOnlinePayment = trim($ordersPaymentMethod) === '1';
    if (!$isNumericOnlinePayment && !financeWalletIsOnlinePayment($paymentMethod, $transactionId, $gatewayRef)) {
        financeWalletError('رد نقاط المحفظة متاح للطلبات المدفوعة إلكترونيا فقط');
    }

    $userId = (int)($order['orders_usersid'] ?? 0);
    $paidAmount = (float)($order['paid_amount'] ?? 0);
    $orderTotal = (float)($order['orders_totalprice'] ?? 0);
    $refundAmount = $paidAmount > 0 ? $paidAmount : $orderTotal;
    $refundPoints = (int)round($refundAmount);

    if ($userId <= 0 || $refundAmount <= 0 || $refundPoints <= 0) {
        financeWalletError('قيمة الطلب غير صالحة لرد النقاط');
    }

    $duplicateStmt = $con->prepare("
        SELECT id
        FROM wallet_refund_logs
        WHERE order_id = :order_id
        LIMIT 1
    ");
    $duplicateStmt->execute([':order_id' => $orderId]);
    if ($duplicateStmt->fetchColumn()) {
        financeWalletError('تم رد نقاط هذا الطلب من قبل');
    }

    $adminId = (int)($admin['admin_id'] ?? $admin['id'] ?? 0);
    $logNote = $note !== '' ? $note : 'Refund canceled online-paid order to wallet points';

    $con->beginTransaction();

    $walletIdColumn = columnExists('wallet', 'id') ? 'id' : null;
    $walletStmt = $con->prepare("
        SELECT " . ($walletIdColumn ?: 'user_id') . " AS wallet_key
        FROM wallet
        WHERE user_id = :user_id
        LIMIT 1
        FOR UPDATE
    ");
    $walletStmt->execute([':user_id' => $userId]);
    $walletKey = $walletStmt->fetchColumn();

    if ($walletKey) {
        $whereColumn = $walletIdColumn ?: 'user_id';
        $updateWallet = $con->prepare("
            UPDATE wallet
            SET
                balance = balance + :amount,
                points = points + :points
            WHERE {$whereColumn} = :wallet_key
        ");
        $updateWallet->execute([
            ':amount' => $refundAmount,
            ':points' => $refundPoints,
            ':wallet_key' => $walletKey,
        ]);
    } else {
        $insertWallet = $con->prepare("
            INSERT INTO wallet (user_id, points, balance)
            VALUES (:user_id, :points, :amount)
        ");
        $insertWallet->execute([
            ':user_id' => $userId,
            ':points' => $refundPoints,
            ':amount' => $refundAmount,
        ]);
    }

    $insertLog = $con->prepare("
        INSERT INTO wallet_refund_logs (
            order_id,
            user_id,
            points,
            amount,
            note,
            created_by
        ) VALUES (
            :order_id,
            :user_id,
            :points,
            :amount,
            :note,
            :created_by
        )
    ");
    $insertLog->execute([
        ':order_id' => $orderId,
        ':user_id' => $userId,
        ':points' => $refundPoints,
        ':amount' => $refundAmount,
        ':note' => $logNote,
        ':created_by' => $adminId > 0 ? $adminId : null,
    ]);

    if (tableExists('payments')) {
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
                'wallet_points_refund',
                'refunded_to_wallet',
                :amount,
                NOW()
            )
        ");
        $paymentStmt->execute([
            ':order_id' => $orderId,
            ':user_id' => $userId,
            ':amount' => $refundAmount,
        ]);
    }

    if (tableExists('accounting_entries')) {
        $accountingStmt = $con->prepare("
            INSERT INTO accounting_entries (
                entry_type,
                reference_table,
                reference_id,
                debit,
                credit,
                description,
                user_id
            ) VALUES (
                'refund',
                'orders',
                :order_id,
                :amount,
                0,
                :description,
                :user_id
            )
        ");
        $accountingStmt->execute([
            ':order_id' => $orderId,
            ':amount' => $refundAmount,
            ':description' => 'Refunded cancelled online-paid order #' . $orderId . ' to wallet points',
            ':user_id' => $userId,
        ]);
    }

    $balanceStmt = $con->prepare("
        SELECT points, balance
        FROM wallet
        WHERE user_id = :user_id
        LIMIT 1
    ");
    $balanceStmt->execute([':user_id' => $userId]);
    $wallet = $balanceStmt->fetch(PDO::FETCH_ASSOC) ?: ['points' => 0, 'balance' => 0];

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'تم رد قيمة الطلب كنقاط في محفظة العميل',
        'data' => [
            'order_id' => $orderId,
            'user_id' => $userId,
            'added_points' => $refundPoints,
            'added_balance' => $refundAmount,
            'wallet_points' => (int)($wallet['points'] ?? 0),
            'wallet_balance' => (float)($wallet['balance'] ?? 0),
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    financeWalletError($e->getMessage(), 500);
}
