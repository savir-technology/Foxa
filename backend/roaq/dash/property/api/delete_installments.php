<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode([
            'status' => 'error',
            'message' => 'Method not allowed',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $status = trim((string)($_POST['status'] ?? 'all'));
    $allowed = ['all', 'pending', 'paid', 'late', 'receipt_uploaded', 'rejected'];
    if (!in_array($status, $allowed, true)) {
        $status = 'all';
    }

    if ($status === 'all') {
        $stmt = $con->prepare("DELETE FROM property_installments");
        $stmt->execute();
        $deleted = $stmt->rowCount();
    } else {
        $stmt = $con->prepare("DELETE FROM property_installments WHERE status = :status");
        $stmt->execute([':status' => $status]);
        $deleted = $stmt->rowCount();
    }

    echo json_encode([
        'status' => 'success',
        'deleted_count' => $deleted,
        'filter' => $status,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
