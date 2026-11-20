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

    $stmt = $con->prepare("
        SELECT
            w.waste_id,
            w.item_id,
            w.variant_id,
            w.quantity,
            w.cost_per_unit,
            w.total_cost,
            w.reason,
            w.notes,
            w.waste_date,
            i.items_name_ar,
            i.items_name_en,
            c.color_name,
            c.color_hex,
            s.size_name
        FROM inventory_waste w
        INNER JOIN items i ON i.items_id = w.item_id
        LEFT JOIN item_variants iv ON iv.variant_id = w.variant_id
        LEFT JOIN colors c ON c.color_id = iv.color_id
        LEFT JOIN sizes s ON s.size_id = iv.size_id
        WHERE w.vendor_id = :vendor_id
        ORDER BY w.waste_date DESC, w.waste_id DESC
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $totalQty = 0;
    $totalCost = 0.0;
    foreach ($rows as $row) {
        $totalQty += (int)($row['quantity'] ?? 0);
        $totalCost += (float)($row['total_cost'] ?? 0);
    }

    echo json_encode([
        'status' => 'success',
        'summary' => [
            'rows_count' => count($rows),
            'total_quantity' => $totalQty,
            'total_cost' => number_format($totalCost, 2, '.', ''),
        ],
        'data' => $rows,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
