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

$reportsQueryFailures = [];

function reportsMarkQueryFailure(string $component, Throwable $error): void
{
    global $reportsQueryFailures;
    $reportsQueryFailures[] = $component;
    error_log('master reports ' . $component . ' failed: ' . $error->getMessage());
}

function reportsScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        reportsMarkQueryFailure('scalar_query', $e);
        return $fallback;
    }
}

function reportsRows(string $sql, array $params = []): array
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        reportsMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function reportsOrderStatusExpr(string $alias = ''): string
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

function reportsDateExpr(string $table, array $columns, string $fallback = 'NOW()'): string
{
    $available = [];
    foreach ($columns as $column) {
        if (columnExists($table, $column)) {
            $available[] = $column;
        }
    }
    return empty($available) ? $fallback : 'COALESCE(' . implode(', ', $available) . ')';
}

function reportsSuccessfulWhere(string $expr): string
{
    return "{$expr} IN ('delivered','completed','paid','4')";
}

function reportsCanceledWhere(string $expr): string
{
    return "{$expr} IN ('canceled','cancelled','failed','rejected')";
}

function reportsEmptySeries(): array
{
    $series = [];
    for ($i = 29; $i >= 0; $i--) {
        $series[] = [
            'date' => date('Y-m-d', strtotime("-{$i} days")),
            'value' => 0,
        ];
    }
    return $series;
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'reports.view');
    $master = masterPublicData($admin);

    if (!tableExists('orders')) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [
                'server_now' => date('c'),
                'total_orders' => 0,
                'revenue' => 0,
                'avg_delivery_minutes' => 0,
                'new_users' => 0,
                'acceptance_rate' => 0,
                'cancellations_rate' => 0,
                'series' => reportsEmptySeries(),
                'ratings' => [],
                'data_quality' => [
                    'state' => 'degraded',
                    'failed_components' => ['orders_schema'],
                ],
            ],
        ]);
    }

    $statusExpr = reportsOrderStatusExpr();
    $successfulWhere = reportsSuccessfulWhere($statusExpr);
    $canceledWhere = reportsCanceledWhere($statusExpr);
    $totalOrders = (int)reportsScalar('SELECT COUNT(*) FROM orders');
    $completedOrders = (int)reportsScalar("SELECT COUNT(*) FROM orders WHERE {$successfulWhere}");
    $canceledOrders = (int)reportsScalar("SELECT COUNT(*) FROM orders WHERE {$canceledWhere}");
    $revenue = (float)reportsScalar("SELECT COALESCE(SUM(orders_totalprice), 0) FROM orders WHERE {$successfulWhere}");

    $dateExpr = reportsDateExpr('orders', ['orders_datetime', 'created_at']);
    $startExpr = reportsDateExpr('orders', ['accepted_at', 'assigned_at', 'orders_datetime']);
    $endExpr = reportsDateExpr('orders', ['delivered_at', 'updated_at']);
    $avgDeliveryMinutes = (float)reportsScalar("
        SELECT COALESCE(AVG(TIMESTAMPDIFF(MINUTE, {$startExpr}, {$endExpr})), 0)
        FROM orders
        WHERE {$successfulWhere}
          AND {$startExpr} IS NOT NULL
          AND {$endExpr} IS NOT NULL
          AND {$endExpr} >= {$startExpr}
    ");

    $newUsers = 0;
    if (tableExists('users')) {
        $userDateColumn = columnExists('users', 'users_creat') ? 'users_creat' : (columnExists('users', 'created_at') ? 'created_at' : '');
        $newUsers = $userDateColumn === ''
            ? (int)reportsScalar('SELECT COUNT(*) FROM users')
            : (int)reportsScalar("SELECT COUNT(*) FROM users WHERE {$userDateColumn} >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)");
    }

    $seriesRows = reportsRows("
        SELECT DATE({$dateExpr}) AS day_label, COUNT(*) AS total
        FROM orders
        WHERE {$dateExpr} >= DATE_SUB(CURDATE(), INTERVAL 29 DAY)
        GROUP BY DATE({$dateExpr})
        ORDER BY day_label ASC
    ");
    $seriesByDay = [];
    foreach ($seriesRows as $row) {
        $seriesByDay[(string)($row['day_label'] ?? '')] = (int)($row['total'] ?? 0);
    }
    $series = [];
    for ($i = 29; $i >= 0; $i--) {
        $day = date('Y-m-d', strtotime("-{$i} days"));
        $series[] = ['date' => $day, 'value' => $seriesByDay[$day] ?? 0];
    }

    $ratings = [];
    if (tableExists('ratings') && columnExists('ratings', 'rating')) {
        $ratingRows = reportsRows("
            SELECT ROUND(rating) AS rating_value, COUNT(*) AS total
            FROM ratings
            GROUP BY ROUND(rating)
            ORDER BY rating_value DESC
        ");
        foreach ($ratingRows as $row) {
            $ratings[(string)(int)($row['rating_value'] ?? 0)] = (int)($row['total'] ?? 0);
        }
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => date('c'),
            'total_orders' => $totalOrders,
            'revenue' => round($revenue, 2),
            'avg_delivery_minutes' => round($avgDeliveryMinutes, 1),
            'new_users' => $newUsers,
            'acceptance_rate' => $totalOrders > 0 ? round(($completedOrders / $totalOrders) * 100, 1) : 0,
            'cancellations_rate' => $totalOrders > 0 ? round(($canceledOrders / $totalOrders) * 100, 1) : 0,
            'series' => $series,
            'ratings' => $ratings,
            'data_quality' => empty($reportsQueryFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($reportsQueryFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [
            'total_orders' => 0,
            'revenue' => 0,
            'avg_delivery_minutes' => 0,
            'new_users' => 0,
            'acceptance_rate' => 0,
            'cancellations_rate' => 0,
            'series' => reportsEmptySeries(),
            'ratings' => [],
        ],
    ], 500);
}
