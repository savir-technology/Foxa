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

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);

    $stmt = $con->prepare("
        SELECT
            DATE(a.entry_date) AS sale_date,
            COALESCE(SUM(a.credit), 0) AS total_sales
        FROM accounting_entries a
        INNER JOIN vendor_orders vo
            ON vo.order_id = a.reference_id
           AND vo.vendor_id = :vendor_id
        WHERE a.entry_type = 'sale'
          AND a.reference_table = 'orders'
        GROUP BY DATE(a.entry_date)
        ORDER BY sale_date ASC
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $totalSales = 0.0;
    foreach ($data as $row) {
        $totalSales += (float)($row['total_sales'] ?? 0);
    }

    $daysCount = count($data);
    $avgDaily = $daysCount > 0 ? ($totalSales / $daysCount) : 0.0;

    echo json_encode([
        'status' => 'success',
        'summary' => [
            'total_sales' => number_format($totalSales, 2, '.', ''),
            'days_count' => $daysCount,
            'average_daily_sales' => number_format($avgDaily, 2, '.', ''),
        ],
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [],
    ], JSON_UNESCAPED_UNICODE);
}
