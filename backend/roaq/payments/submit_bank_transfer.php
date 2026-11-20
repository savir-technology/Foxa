<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";

// Params: user_id, property_id (optional), installment_id (optional), bank_name, account_name, reference_number, amount, optional 'receipt' file
$user_id = $_POST['user_id'] ?? null;
$property_id = $_POST['property_id'] ?? null;
$installment_id = $_POST['installment_id'] ?? null;
$bank_name = $_POST['bank_name'] ?? null;
$account_name = $_POST['account_name'] ?? null;
$reference_number = $_POST['reference_number'] ?? null;
$amount = $_POST['amount'] ?? null;

if (!$user_id || !$bank_name || !$amount) {
    echo json_encode(["status" => "fail", "message" => "missing required params"]);
    exit;
}

$receipt_url = null;
if (isset($_FILES['receipt'])) {
    $folder = "../uploads/receipts/";
    if (!file_exists($folder)) mkdir($folder, 0777, true);
    $ext = pathinfo($_FILES['receipt']['name'], PATHINFO_EXTENSION);
    $file_name = time() . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $file_path = $folder . $file_name;
    move_uploaded_file($_FILES['receipt']['tmp_name'], $file_path);
    $receipt_url = "uploads/receipts/" . $file_name;
}

try {
    $stmt = $con->prepare("INSERT INTO bank_transfers (user_id, property_id, installment_id, bank_name, account_name, reference_number, amount, receipt_image, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', current_timestamp())");
    $stmt->execute([$user_id, $property_id, $installment_id, $bank_name, $account_name, $reference_number, $amount, $receipt_url]);

    $transfer_id = $con->lastInsertId();

    // notify admin(s)
    $s = $con->prepare("SELECT fcm_token FROM users WHERE user_role = 'admin' AND fcm_token IS NOT NULL LIMIT 1");
    $s->execute([]);
    $a = $s->fetch(PDO::FETCH_ASSOC);
    if ($a && !empty($a['fcm_token']) && file_exists(__DIR__ . "/../chat/firebase/send_notification.php")) {
        include __DIR__ . "/../chat/firebase/send_notification.php";
        sendFCM("إشعار دفع بنكي جديد", "تم استلام طلب تحويل بمبلغ: $amount", trim($a['fcm_token']));
    }

    echo json_encode(["status" => "success", "transfer_id" => (int)$transfer_id]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

?>
