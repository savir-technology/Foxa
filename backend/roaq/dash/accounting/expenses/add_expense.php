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

    $title = trim((string)($_POST['title'] ?? ''));
    $amount = (float)($_POST['amount'] ?? 0);

    if ($title === '' || $amount <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Title and amount are required',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $con->beginTransaction();

    $stmt = $con->prepare("
        INSERT INTO expenses (vendor_id, expense_title, amount, expense_date)
        VALUES (:vendor_id, :title, :amount, CURDATE())
    ");
    $stmt->execute([
        ':vendor_id' => $vendorId,
        ':title' => $title,
        ':amount' => $amount,
    ]);

    $expenseId = (int)$con->lastInsertId();

    $entryStmt = $con->prepare("
        INSERT INTO accounting_entries (
            entry_type,
            reference_table,
            reference_id,
            debit,
            description,
            user_id
        ) VALUES (
            'expense',
            'expenses',
            :expense_id,
            :amount,
            :description,
            NULL
        )
    ");
    $entryStmt->execute([
        ':expense_id' => $expenseId,
        ':amount' => $amount,
        ':description' => 'Expense: ' . $title,
    ]);

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'expense_id' => $expenseId,
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
