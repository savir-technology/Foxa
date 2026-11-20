<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function ensureWasteTable(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS inventory_waste (
            waste_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            vendor_id INT NOT NULL DEFAULT 0,
            item_id INT NOT NULL,
            variant_id INT NULL,
            quantity INT NOT NULL DEFAULT 0,
            cost_per_unit DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            total_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
            reason VARCHAR(255) NULL,
            notes TEXT NULL,
            waste_date DATE NOT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);

    ensureWasteTable($con);

    $revenueStmt = $con->prepare("
        SELECT COALESCE(SUM(a.credit), 0) AS total_revenue
        FROM accounting_entries a
        INNER JOIN vendor_orders vo
            ON vo.order_id = a.reference_id
           AND vo.vendor_id = :vendor_id
        WHERE a.entry_type = 'sale'
          AND a.reference_table = 'orders'
    ");
    $revenueStmt->execute([':vendor_id' => $vendorId]);
    $revenueData = $revenueStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $expenseStmt = $con->prepare("
        SELECT COALESCE(SUM(amount), 0) AS total_expenses
        FROM expenses
        WHERE vendor_id = :vendor_id
    ");
    $expenseStmt->execute([':vendor_id' => $vendorId]);
    $expenseData = $expenseStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $wasteStmt = $con->prepare("
        SELECT COALESCE(SUM(total_cost), 0) AS total_waste_cost
        FROM inventory_waste
        WHERE vendor_id = :vendor_id
    ");
    $wasteStmt->execute([':vendor_id' => $vendorId]);
    $wasteData = $wasteStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $inventoryStmt = $con->prepare("
        SELECT
            COALESCE(SUM(iv.stock), 0) AS inventory_units,
            COALESCE(SUM(iv.stock * COALESCE(NULLIF(iv.price, 0), i.items_price)), 0) AS inventory_value
        FROM item_variants iv
        INNER JOIN items i ON i.items_id = iv.item_id
        WHERE i.vendor_id = :vendor_id
    ");
    $inventoryStmt->execute([':vendor_id' => $vendorId]);
    $inventoryData = $inventoryStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $totalRevenue = (float)($revenueData['total_revenue'] ?? 0);
    $totalExpenses = (float)($expenseData['total_expenses'] ?? 0);
    $totalWaste = (float)($wasteData['total_waste_cost'] ?? 0);
    $netProfit = $totalRevenue - $totalExpenses - $totalWaste;

    echo json_encode([
        'status' => 'success',
        'data' => [
            'total_revenue' => number_format($totalRevenue, 2, '.', ''),
            'total_expenses' => number_format($totalExpenses, 2, '.', ''),
            'total_waste_cost' => number_format($totalWaste, 2, '.', ''),
            'net_profit' => number_format($netProfit, 2, '.', ''),
            'inventory_units' => (int)($inventoryData['inventory_units'] ?? 0),
            'inventory_value' => number_format((float)($inventoryData['inventory_value'] ?? 0), 2, '.', ''),
        ],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
