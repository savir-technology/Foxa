<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';
require_once '../../../notifications/notification_service.php';

$installment_id = intval($_POST['installment_id'] ?? 0);
$status = trim((string) ($_POST['status'] ?? ''));
$allowed = ['pending', 'paid', 'late', 'receipt_uploaded', 'rejected'];

if ($installment_id <= 0 || !in_array($status, $allowed, true)) {
    echo json_encode(['status' => 'fail', 'message' => 'Invalid installment_id or status']);
    exit;
}

try {
    $select = $con->prepare(
        "SELECT pi.installment_id, pi.user_id, pi.plan_id, pi.status AS old_status, pp.item_id
         FROM property_installments pi
         INNER JOIN property_plans pp ON pp.plan_id = pi.plan_id
         WHERE pi.installment_id = :id
         LIMIT 1"
    );
    $select->execute([':id' => $installment_id]);
    $row = $select->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        echo json_encode(['status' => 'fail', 'message' => 'Installment not found']);
        exit;
    }

    $update = $con->prepare(
        "UPDATE property_installments
         SET status = :status,
             paid_at = CASE WHEN :status_paid = 'paid' THEN NOW() ELSE paid_at END
         WHERE installment_id = :id"
    );
    $update->execute([
        ':status' => $status,
        ':status_paid' => $status,
        ':id' => $installment_id,
    ]);

    $userId = intval($row['user_id']);
    $planId = intval($row['plan_id']);
    $itemId = intval($row['item_id']);

    if ($status === 'paid') {
        notifyUser(
            $userId,
            'تم سداد القسط بنجاح',
            'تمت مراجعة العملية وتأكيد سداد القسط.',
            'receipt',
            [
                'installment_id' => $installment_id,
                'plan_id' => $planId,
                'item_id' => $itemId,
            ],
            'receipt_paid_' . $installment_id
        );
    } elseif ($status === 'rejected') {
        notifyUser(
            $userId,
            'فشلت عملية السداد',
            'تم رفض عملية السداد. يرجى إعادة رفع إيصال صحيح أو التواصل مع الدعم.',
            'receipt',
            [
                'installment_id' => $installment_id,
                'plan_id' => $planId,
                'item_id' => $itemId,
            ],
            'receipt_rejected_' . $installment_id
        );
    }

    echo json_encode([
        'status' => 'success',
        'installment_id' => $installment_id,
        'new_status' => $status,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('update_installment_status.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
