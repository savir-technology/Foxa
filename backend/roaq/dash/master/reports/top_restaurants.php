<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$reportTopQueryFailures = [];
$reportTopUsedFallback = false;

function reportTopMarkQueryFailure(string $component, Throwable $error): void
{
    global $reportTopQueryFailures;
    $reportTopQueryFailures[] = $component;
    error_log('master reports top restaurants ' . $component . ' failed: ' . $error->getMessage());
}

function reportTopRows(string $sql): array
{
    global $con;
    try {
        $stmt = $con->query($sql);
        return $stmt ? ($stmt->fetchAll(PDO::FETCH_ASSOC) ?: []) : [];
    } catch (Throwable $e) {
        reportTopMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function reportTopStatusExpr(string $alias = 'o'): string
{
    $prefix = $alias !== '' ? $alias . '.' : '';
    $columns = [];
    if (columnExists('orders', 'status')) {
        $columns[] = $prefix . 'status';
    }
    if (columnExists('orders', 'orders_status')) {
        $columns[] = $prefix . 'orders_status';
    }
    return empty($columns) ? "''" : 'COALESCE(' . implode(', ', $columns) . ", '')";
}

function reportTopVendorNameExpr(string $alias, string $fallbackIdExpr): string
{
    $candidates = [];
    if (columnExists('vendors', 'store_name')) {
        $candidates[] = "NULLIF({$alias}.store_name, '')";
    }
    if (columnExists('vendors', 'vendor_name')) {
        $candidates[] = "NULLIF({$alias}.vendor_name, '')";
    }
    $candidates[] = "CONCAT('Restaurant #', {$fallbackIdExpr})";
    return 'COALESCE(' . implode(', ', $candidates) . ')';
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'reports.view');
    $master = masterPublicData($admin);

    if (!tableExists('orders') || !tableExists('vendors')) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [],
            'data_quality' => [
                'state' => 'degraded',
                'failed_components' => ['orders_or_vendors_schema'],
            ],
        ]);
    }

    $rows = [];
    $statusExpr = reportTopStatusExpr('o');
    $successWhere = "{$statusExpr} IN ('delivered','completed','paid','4')";

    if (
        tableExists('vendor_orders') &&
        columnExists('vendor_orders', 'vendor_id') &&
        columnExists('vendor_orders', 'order_id') &&
        columnExists('vendor_orders', 'vendor_total') &&
        columnExists('orders', 'orders_id')
    ) {
        $rows = reportTopRows("
            SELECT
                vo.vendor_id,
                " . reportTopVendorNameExpr('v', 'vo.vendor_id') . " AS name,
                COUNT(DISTINCT vo.order_id) AS orders_count,
                COALESCE(SUM(vo.vendor_total), 0) AS sales
            FROM vendor_orders vo
            INNER JOIN orders o ON o.orders_id = vo.order_id
            LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id
            WHERE {$successWhere}
            GROUP BY vo.vendor_id, name
            ORDER BY sales DESC, orders_count DESC
            LIMIT 10
        ");
    } elseif (
        tableExists('order_items') &&
        columnExists('order_items', 'vendor_id') &&
        columnExists('order_items', 'order_id') &&
        columnExists('orders', 'orders_id')
    ) {
        $totalColumns = [];
        if (columnExists('order_items', 'line_total')) {
            $totalColumns[] = 'oi.line_total';
        }
        if (columnExists('order_items', 'subtotal')) {
            $totalColumns[] = 'oi.subtotal';
        }
        if (columnExists('order_items', 'item_price') && columnExists('order_items', 'quantity')) {
            $totalColumns[] = 'oi.item_price * oi.quantity';
        }
        $totalExpr = empty($totalColumns)
            ? '0'
            : 'COALESCE(' . implode(', ', $totalColumns) . ', 0)';
        $rows = reportTopRows("
            SELECT
                oi.vendor_id,
                " . reportTopVendorNameExpr('v', 'oi.vendor_id') . " AS name,
                COUNT(DISTINCT oi.order_id) AS orders_count,
                COALESCE(SUM({$totalExpr}), 0) AS sales
            FROM order_items oi
            INNER JOIN orders o ON o.orders_id = oi.order_id
            LEFT JOIN vendors v ON v.vendor_id = oi.vendor_id
            WHERE {$successWhere}
            GROUP BY oi.vendor_id, name
            ORDER BY sales DESC, orders_count DESC
            LIMIT 10
        ");
    }

    // A new platform can have vendors and pending orders before the first
    // completed order is recorded. Keep the report useful instead of showing
    // an empty screen in that case.
    if (empty($rows) && tableExists('vendor_orders') && columnExists('vendor_orders', 'vendor_id')) {
        $reportTopUsedFallback = true;
        $rows = reportTopRows("\n            SELECT\n                vo.vendor_id,\n                " . reportTopVendorNameExpr('v', 'vo.vendor_id') . " AS name,\n                COUNT(DISTINCT vo.order_id) AS orders_count,\n                COALESCE(SUM(vo.vendor_total), 0) AS sales\n            FROM vendor_orders vo\n            LEFT JOIN vendors v ON v.vendor_id = vo.vendor_id\n            GROUP BY vo.vendor_id, name\n            ORDER BY orders_count DESC, sales DESC\n            LIMIT 10\n        ");
    }

    if (empty($rows) && tableExists('vendors') && columnExists('vendors', 'vendor_id')) {
        $reportTopUsedFallback = true;
        $rows = reportTopRows("\n            SELECT\n                v.vendor_id,\n                " . reportTopVendorNameExpr('v', 'v.vendor_id') . " AS name,\n                0 AS orders_count,\n                0 AS sales\n            FROM vendors v\n            ORDER BY v.vendor_id DESC\n            LIMIT 10\n        ");
    }

    $data = [];
    $rank = 1;
    foreach ($rows as $row) {
        $data[] = [
            'rank' => $rank++,
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'name' => (string)($row['name'] ?? ''),
            'orders' => (int)($row['orders_count'] ?? 0),
            'sales' => round((float)($row['sales'] ?? 0), 2),
        ];
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => $data,
        'data_quality' => empty($reportTopQueryFailures) && !$reportTopUsedFallback
            ? ['state' => 'complete']
            : [
                'state' => $reportTopUsedFallback ? 'partial' : 'degraded',
                'reason' => $reportTopUsedFallback ? 'No completed orders yet; showing current vendor activity.' : null,
                'failed_components' => array_values(array_unique($reportTopQueryFailures)),
            ],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage(), 'data' => []], 500);
}
