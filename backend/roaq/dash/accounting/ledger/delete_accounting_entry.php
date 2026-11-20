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
    $entryId = (int)($_POST['id'] ?? 0);

    if ($entryId <= 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'ID is required',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $entryStmt = $con->prepare("
        SELECT
            ae.entry_id,
            ae.reference_table,
            ae.reference_id
        FROM accounting_entries ae
        LEFT JOIN vendor_orders vo
            ON ae.reference_table = 'orders'
           AND vo.order_id = ae.reference_id
        LEFT JOIN expenses e
            ON ae.reference_table = 'expenses'
           AND e.expense_id = ae.reference_id
        WHERE ae.entry_id = :entry_id
          AND (
                (ae.reference_table = 'orders' AND vo.vendor_id = :vendor_id)
             OR (ae.reference_table = 'expenses' AND e.vendor_id = :vendor_id)
          )
        LIMIT 1
    ");
    $entryStmt->execute([
        ':entry_id' => $entryId,
        ':vendor_id' => $vendorId,
    ]);
    $entry = $entryStmt->fetch(PDO::FETCH_ASSOC);

    if (!$entry) {
        echo json_encode([
            'status' => 'failure',
            'message' => 'Entry not found',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $con->beginTransaction();

    if (($entry['reference_table'] ?? '') === 'expenses') {
        $con->prepare("
            DELETE FROM expenses
            WHERE expense_id = :reference_id
              AND vendor_id = :vendor_id
        ")->execute([
            ':reference_id' => (int)$entry['reference_id'],
            ':vendor_id' => $vendorId,
        ]);
    }

    $con->prepare("
        DELETE FROM accounting_entries
        WHERE entry_id = :entry_id
    ")->execute([':entry_id' => $entryId]);

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
