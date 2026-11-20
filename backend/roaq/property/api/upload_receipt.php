<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);

require_once '../../connect.php';
require_once '../../notifications/notification_service.php';
header('Content-Type: application/json; charset=utf-8');

try {
    $items_id = intval($_POST['items_id'] ?? 0);
    $plan_id  = intval($_POST['plan_id'] ?? 0);
    $user_id  = intval($_POST['user_id'] ?? 0);

    if ($items_id <= 0 || $plan_id <= 0 || $user_id <= 0) {
        throw new Exception('بيانات غير صحيحة');
    }

    if (!isset($_FILES['receipt'])) {
        throw new Exception('لم يتم رفع أي ملف');
    }

    if ($_FILES['receipt']['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('خطأ في رفع الملف: ' . $_FILES['receipt']['error']);
    }

    $allowed_types = ['image/jpeg', 'image/png', 'application/pdf'];
    $file_type = mime_content_type($_FILES['receipt']['tmp_name']);
    if (!in_array($file_type, $allowed_types, true)) {
        throw new Exception('نوع الملف غير مسموح. مسموح فقط JPG, PNG, PDF');
    }

    $max_size = 5 * 1024 * 1024;
    if ($_FILES['receipt']['size'] > $max_size) {
        throw new Exception('حجم الملف أكبر من 5MB');
    }

    $stmt = $con->prepare(
        "SELECT installment_id
         FROM property_installments
         WHERE plan_id = :plan_id
           AND user_id = :user_id
           AND status IN ('pending', 'late', 'rejected')
         ORDER BY due_date ASC
         LIMIT 1"
    );
    $stmt->execute([
        ':plan_id' => $plan_id,
        ':user_id' => $user_id,
    ]);
    $installment = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$installment) {
        throw new Exception('لا يوجد قسط مستحق حالياً');
    }

    $installment_id = intval($installment['installment_id']);

    $target_dir = $_SERVER['DOCUMENT_ROOT'] . '/aqar/zahra/uploads/receipts/';
    if (!file_exists($target_dir)) {
        if (!mkdir($target_dir, 0755, true)) {
            throw new Exception('فشل إنشاء مجلد الحفظ');
        }
    }

    if (!is_writable($target_dir)) {
        throw new Exception('المجلد غير قابل للكتابة');
    }

    $extension = pathinfo($_FILES['receipt']['name'], PATHINFO_EXTENSION);
    $filename = 'receipt_' . $user_id . '_' . time() . '_' . rand(1000, 9999) . '.' . $extension;
    $target_file = $target_dir . $filename;

    if (!move_uploaded_file($_FILES['receipt']['tmp_name'], $target_file)) {
        throw new Exception('فشل حفظ الملف');
    }

    $sql = "UPDATE property_installments
            SET payment_receipt = :receipt,
                status = 'receipt_uploaded',
                paid_at = NULL
            WHERE installment_id = :id";

    $updateStmt = $con->prepare($sql);
    $updateStmt->execute([
        ':receipt' => $filename,
        ':id' => $installment_id,
    ]);

    notifyUser(
        $user_id,
        'تم استلام إثبات الدفع',
        'تم استلام الإيصال وحالة العملية الآن: قيد المراجعة.',
        'receipt',
        [
            'installment_id' => $installment_id,
            'plan_id' => $plan_id,
            'item_id' => $items_id,
        ],
        'receipt_uploaded_' . $installment_id
    );

    echo json_encode([
        'success' => true,
        'message' => 'تم رفع الإيصال بنجاح وحالته قيد المراجعة',
        'filename' => $filename,
        'installment_id' => $installment_id,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
