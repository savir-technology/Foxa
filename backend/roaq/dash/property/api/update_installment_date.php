<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

$installment_id = intval($_POST['installment_id'] ?? 0);
$due_date = trim((string) ($_POST['due_date'] ?? ''));

if ($installment_id <= 0 || $due_date === '') {
    echo json_encode(['status' => 'fail', 'message' => 'Invalid installment_id or due_date']);
    exit;
}

try {
    $date = DateTime::createFromFormat('Y-m-d', $due_date);
    if (!$date || $date->format('Y-m-d') !== $due_date) {
        echo json_encode(['status' => 'fail', 'message' => 'Invalid date format']);
        exit;
    }

    $update = $con->prepare(
        "UPDATE property_installments
         SET due_date = :due_date
         WHERE installment_id = :id"
    );
    $update->execute([
        ':due_date' => $due_date,
        ':id' => $installment_id,
    ]);

    echo json_encode([
        'status' => 'success',
        'installment_id' => $installment_id,
        'due_date' => $due_date,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('update_installment_date.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
