<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);

    $id = (int)($_POST['id'] ?? 0);
    $title = trim((string)($_POST['title'] ?? ''));
    $amount = (float)($_POST['amount'] ?? 0);

    if ($id <= 0 || $title === '' || $amount <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid expense data',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $checkStmt = $con->prepare("
        SELECT expense_id
        FROM expenses
        WHERE expense_id = :id
          AND vendor_id = :vendor_id
        LIMIT 1
    ");
    $checkStmt->execute([
        ':id' => $id,
        ':vendor_id' => $vendorId,
    ]);
    if (!$checkStmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode([
            'status' => 'failure',
            'message' => 'Expense not found',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $con->beginTransaction();

    $stmt = $con->prepare("
        UPDATE expenses
        SET expense_title = :title,
            amount = :amount
        WHERE expense_id = :id
          AND vendor_id = :vendor_id
    ");
    $stmt->execute([
        ':title' => $title,
        ':amount' => $amount,
        ':id' => $id,
        ':vendor_id' => $vendorId,
    ]);

    $entryStmt = $con->prepare("
        UPDATE accounting_entries
        SET debit = :amount,
            description = :description
        WHERE entry_type = 'expense'
          AND reference_table = 'expenses'
          AND reference_id = :id
    ");
    $entryStmt->execute([
        ':amount' => $amount,
        ':description' => 'Expense: ' . $title,
        ':id' => $id,
    ]);

    $con->commit();

    echo json_encode([
        'status' => 'success',
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
