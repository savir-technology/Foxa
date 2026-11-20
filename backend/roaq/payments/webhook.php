<?php
// webhook.php
include "../connect.php"; // ملف الاتصال بقاعدة البيانات
require_once __DIR__ . "/../notifications/notification_helper.php";

// Paymob HMAC Secret
$hmac_secret = "6E0AB4F9CC408AFAB5D39DB46ABCCAFC";

// استقبل البيانات الخام من Paymob
$raw_data = file_get_contents("php://input");
$payload = json_decode($raw_data, true);

// سجل الـ raw في لوج عشان المتابعة
file_put_contents("paymob_webhook.log", date("Y-m-d H:i:s") . " - RAW: " . $raw_data . PHP_EOL, FILE_APPEND);

// تحقق إن البيانات جت فعلاً
if (!$payload) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "No payload received"]);
    exit;
}

// تحقق من وجود HMAC في الهيدر
$headers = array_change_key_case(getallheaders(), CASE_LOWER);
if (!isset($headers['hmac'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "HMAC missing"]);
    exit;
}
$hmac_received = $headers['hmac'];

// الحقول اللي لازم تتجمع عشان حساب الـ HMAC
$hmac_fields = [
    "amount_cents",
    "created_at",
    "currency",
    "error_occured",
    "has_parent_transaction",
    "id",
    "integration_id",
    "is_3d_secure",
    "is_auth",
    "is_capture",
    "is_refunded",
    "is_standalone_payment",
    "is_voided",
    "order.id",
    "owner",
    "pending",
    "source_data.pan",
    "source_data.sub_type",
    "source_data.type",
    "success"
];

// ابنِ الـ string اللي هيتعمله HMAC
$hmac_string = "";
foreach ($hmac_fields as $field) {
    $parts = explode('.', $field);
    $value = $payload;
    foreach ($parts as $p) {
        $value = $value[$p] ?? '';
    }
    $hmac_string .= $value;
}

// حساب HMAC
$calculated_hmac = hash_hmac("sha512", $hmac_string, $hmac_secret);

// تحقق من التطابق
if ($calculated_hmac !== $hmac_received) {
    file_put_contents("paymob_webhook.log", date("Y-m-d H:i:s") . " - Invalid HMAC" . PHP_EOL, FILE_APPEND);
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Invalid HMAC"]);
    exit;
}

// ✅ البيانات صحيحة، نحدث حالة الطلب
$success         = $payload['success'] ?? false;
$order_id        = $payload['order']['merchant_order_id'] ?? null;
$transaction_id  = $payload['id'] ?? null;
$payment_method  = $payload['source_data']['sub_type'] ?? $payload['source_data']['type'] ?? 'unknown';
$amount_cents    = $payload['amount_cents'] ?? 0;

if ($order_id) {
    $status = $success ? "paid" : "failed";

    $userStmt = $con->prepare("SELECT orders_usersid, orders_status FROM orders WHERE orders_id = :oid LIMIT 1");
    $userStmt->execute([":oid" => $order_id]);
    $orderRow = $userStmt->fetch(PDO::FETCH_ASSOC);
    $orderUserId = (int)($orderRow['orders_usersid'] ?? 0);
    $oldStatus = (string)($orderRow['orders_status'] ?? '');

    $stmt = $con->prepare("
        UPDATE orders 
        SET orders_status = :status,
            orders_paymentmethod = 1,
            transaction_id = :txid,
            payment_method = :pmethod,
            paid_amount    = :amount
        WHERE orders_id = :oid
    ");
    $stmt->execute([
        ":status"  => $status,
        ":txid"    => $transaction_id,
        ":pmethod" => $payment_method,
        ":amount"  => $amount_cents / 100, // من أصغر وحدة نقدية للريال
        ":oid"     => $order_id
    ]);

    if ($orderUserId > 0 && $oldStatus !== $status) {
        notifyUser(
            $con,
            $orderUserId,
            'payment_status',
            $success ? 'تم تأكيد الدفع' : 'تحديث في حالة الدفع',
            $success
                ? 'تم دفع الطلب #' . $order_id . ' بنجاح.'
                : 'تعذر إتمام دفع الطلب #' . $order_id . '.',
            'order',
            (int)$order_id,
            [
                'order_id' => (string)$order_id,
                'status' => $status,
                'transaction_id' => (string)$transaction_id,
            ],
            true
        );
    }

    file_put_contents("paymob_webhook.log", date("Y-m-d H:i:s") . " - Order $order_id updated to $status, TxID: $transaction_id, Method: $payment_method" . PHP_EOL, FILE_APPEND);
}

// رد نجاح لـ Paymob
http_response_code(200);
echo json_encode(["status" => "success", "message" => "Webhook processed"]);
