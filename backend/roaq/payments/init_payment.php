<?php
// init_payment.php
include "../connect.php"; // الاتصال بقاعدة البيانات

// Paymob Keys (غيّرها بالـ Live Keys عند التشغيل الحقيقي)
$api_key        = trim((string) getenv('PAYMOB_API_KEY'));
$integration_id = "5022554"; // Online Card Integration ID
$iframe_id      = "870455";

// 🟢 دالة تسجيل للـ Debug
function log_paymob($step, $data) {
    if (getenv('PAYMOB_DEBUG_LOG') !== '1') {
        return;
    }

    $message = is_string($data) ? $data : print_r($data, true);
    $message = preg_replace(
        '/((?:api[_ -]?key|token|password|authorization)\s*[=:]\s*["\']?)[^\s,"\'&}]+/i',
        '$1[REDACTED]',
        $message
    );
    file_put_contents(
        __DIR__ . "/paymob_log.txt",
        "[" . date("Y-m-d H:i:s") . "] $step: " . substr($message, 0, 4000) . "\n\n",
        FILE_APPEND | LOCK_EX
    );
}

if ($api_key === '') {
    http_response_code(503);
    echo json_encode([
        'status' => 'error',
        'message' => 'Payment service is not configured',
    ]);
    exit;
}

// 🟢 استلام البيانات (JSON / POST / GET)
$input = json_decode(file_get_contents("php://input"), true);
$user_id  = $input['user_id']  ?? $_POST['user_id']  ?? $_GET['user_id']  ?? null;
$order_id = $input['order_id'] ?? $_POST['order_id'] ?? $_GET['order_id'] ?? null;
$amount   = $input['amount']   ?? $_POST['amount']   ?? $_GET['amount']   ?? null;

$currency = "SAR";

// ✅ تحقق من البيانات الأساسية
if (!$user_id || !$order_id || !$amount) {
    echo json_encode([
        "status"  => "error",
        "message" => "البيانات ناقصة: user_id, order_id, amount مطلوبين"
    ]);
    exit;
}

// 🟢 هات بيانات العميل من قاعدة البيانات
$stmt = $con->prepare("
    SELECT u.users_name, u.users_email, a.address_city, a.address_street, a.address_phone
    FROM users u
    LEFT JOIN address a ON a.address_usersid = u.users_id
    WHERE u.users_id = :uid
    LIMIT 1
");
$stmt->execute([":uid" => $user_id]);
$customer = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$customer) {
    echo json_encode([
        "status"  => "error",
        "message" => "لم يتم العثور على بيانات العميل"
    ]);
    exit;
}

// استخدم بيانات العميل أو قيم افتراضية
$first_name = explode(" ", $customer['users_name'])[0] ?? "Customer";
$last_name  = explode(" ", $customer['users_name'])[1] ?? "Test";
$email      = $customer['users_email'] ?? "customer@example.com";
$phone      = $customer['address_phone'] ?? "01111111111";
$city       = $customer['address_city'] ?? "Cairo";
$street     = $customer['address_street'] ?? "NA";

try {
    // =========================
    // 1️⃣ Get Auth Token
    // =========================
    $ch = curl_init("https://accept.paymob.com/api/auth/tokens");
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(["api_key" => $api_key]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/json"]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $auth_raw = curl_exec($ch);
    $auth_response = json_decode($auth_raw, true);
    curl_close($ch);
    log_paymob("Auth", $auth_raw);

    if (!isset($auth_response['token'])) {
        throw new Exception("فشل في الحصول على Auth Token: " . $auth_raw);
    }
    $auth_token = $auth_response['token'];

    // =========================
    // 2️⃣ Register Order
    // =========================
    $order_payload = [
        "delivery_needed"   => "false",
        "amount_cents"      => $amount * 100,
        "currency"          => $currency,
        "merchant_order_id" => $order_id,
        "items"             => []
    ];

    $ch = curl_init("https://accept.paymob.com/api/ecommerce/orders");
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($order_payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Content-Type: application/json",
        "Authorization: Bearer $auth_token"
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $order_raw = curl_exec($ch);
    $order_response = json_decode($order_raw, true);
    curl_close($ch);
    log_paymob("Order", $order_raw);

    if (!isset($order_response['id'])) {
        throw new Exception("فشل في تسجيل الأوردر عند Paymob: " . $order_raw);
    }
    $paymob_order_id = $order_response['id'];

    // =========================
    // 3️⃣ Payment Key Request
    // =========================
    $billing_data = [
        "apartment"       => "NA",
        "email"           => $email,
        "floor"           => "NA",
        "first_name"      => $first_name,
        "last_name"       => $last_name,
        "street"          => $street,
        "building"        => "NA",
        "phone_number"    => $phone,
        "shipping_method" => "NA",
        "postal_code"     => "NA",
        "city"            => $city,
        "country"         => "EG",
        "state"           => "NA"
    ];

    $payment_key_payload = [
        "auth_token"     => $auth_token,
        "amount_cents"   => $amount * 100,
        "expiration"     => 3600,
        "order_id"       => $paymob_order_id,
        "billing_data"   => $billing_data,
        "currency"       => $currency,
        "integration_id" => $integration_id
    ];

    $ch = curl_init("https://accept.paymob.com/api/acceptance/payment_keys");
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payment_key_payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/json"]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $payment_raw = curl_exec($ch);
    $payment_response = json_decode($payment_raw, true);
    curl_close($ch);
    log_paymob("PaymentKey", $payment_raw);

    if (!isset($payment_response['token'])) {
        throw new Exception("فشل في إنشاء Payment Key: " . $payment_raw);
    }
    $payment_token = $payment_response['token'];

    // =========================
    // 4️⃣ Generate Iframe Link
    // =========================
    $iframe_url = "https://accept.paymob.com/api/acceptance/iframes/$iframe_id?payment_token=$payment_token";

    echo json_encode([
        "status"          => "success",
        "iframe_url"      => $iframe_url,
        "paymob_order_id" => $paymob_order_id,
        "payment_token"   => $payment_token,
        "customer"        => $customer,
        "debug"           => [
            "auth"    => $auth_response,
            "order"   => $order_response,
            "payment" => $payment_response
        ]
    ]);

} catch (Exception $e) {
    log_paymob("Error", $e->getMessage());
    echo json_encode([
        "status"  => "error",
        "message" => $e->getMessage()
    ]);
}
