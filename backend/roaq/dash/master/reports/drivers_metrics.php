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

$reportDriversQueryFailures = [];

function reportDriversMarkQueryFailure(string $component, Throwable $error): void
{
    global $reportDriversQueryFailures;
    $reportDriversQueryFailures[] = $component;
    error_log('master reports drivers ' . $component . ' failed: ' . $error->getMessage());
}

function reportDriversScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        reportDriversMarkQueryFailure('scalar_query', $e);
        return $fallback;
    }
}

function reportDriversStatusExpr(): string
{
    $columns = [];
    if (columnExists('orders', 'status')) {
        $columns[] = 'status';
    }
    if (columnExists('orders', 'orders_status')) {
        $columns[] = 'orders_status';
    }
    return empty($columns) ? "''" : 'COALESCE(' . implode(', ', $columns) . ", '')";
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'reports.view');
    $master = masterPublicData($admin);

    if (!tableExists('delivery_users')) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [],
            'data_quality' => [
                'state' => 'degraded',
                'failed_components' => ['delivery_users_schema'],
            ],
        ]);
    }

    $totalDrivers = (int)reportDriversScalar('SELECT COUNT(*) FROM delivery_users');
    $onlineExpr = columnExists('delivery_users', 'last_seen_at')
        ? "(status = 'online' OR (last_seen_at IS NOT NULL AND last_seen_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)))"
        : "status = 'online'";
    $activeDrivers = columnExists('delivery_users', 'status')
        ? (int)reportDriversScalar("SELECT COUNT(*) FROM delivery_users WHERE {$onlineExpr}")
        : $totalDrivers;

    $todayOrders = 0;
    $completedToday = 0;
    $activeOrders = 0;
    $avgAcceptanceSeconds = 0;
    if (tableExists('orders') && columnExists('orders', 'delivery_id')) {
        $statusExpr = reportDriversStatusExpr();
        $todayOrders = columnExists('orders', 'orders_datetime')
            ? (int)reportDriversScalar("SELECT COUNT(*) FROM orders WHERE delivery_id IS NOT NULL AND DATE(orders_datetime) = CURDATE()")
            : 0;
        $completedToday = columnExists('orders', 'orders_datetime')
            ? (int)reportDriversScalar("SELECT COUNT(*) FROM orders WHERE delivery_id IS NOT NULL AND DATE(orders_datetime) = CURDATE() AND {$statusExpr} IN ('delivered','completed','paid','4')")
            : 0;
        $activeOrders = (int)reportDriversScalar("SELECT COUNT(*) FROM orders WHERE delivery_id IS NOT NULL AND {$statusExpr} NOT IN ('delivered','completed','paid','4','canceled','cancelled','failed','rejected')");

        if (columnExists('orders', 'assigned_at') && columnExists('orders', 'accepted_at')) {
            $avgAcceptanceSeconds = (float)reportDriversScalar("
                SELECT COALESCE(AVG(TIMESTAMPDIFF(SECOND, assigned_at, accepted_at)), 0)
                FROM orders
                WHERE delivery_id IS NOT NULL
                  AND assigned_at IS NOT NULL
                  AND accepted_at IS NOT NULL
                  AND accepted_at >= assigned_at
            ");
        }
    }

    $onDutyPercentage = $totalDrivers > 0 ? round(($activeDrivers / $totalDrivers) * 100, 1) : 0;
    $incidents = tableExists('delivery_driver_emergency_reports') && columnExists('delivery_driver_emergency_reports', 'created_at')
        ? (int)reportDriversScalar("SELECT COUNT(*) FROM delivery_driver_emergency_reports WHERE DATE(created_at) = CURDATE()")
        : 0;
    $averageRating = tableExists('driver_ratings') && columnExists('driver_ratings', 'rating')
        ? (float)reportDriversScalar('SELECT COALESCE(AVG(rating), 0) FROM driver_ratings')
        : 0;

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'إجمالي السائقين' => $totalDrivers,
            'سائقون متصلون الآن' => $activeDrivers,
            'طلبات السائقين اليوم' => $todayOrders,
            'طلبات مكتملة اليوم' => $completedToday,
            'طلبات نشطة مع السائقين' => $activeOrders,
            'متوسط قبول الطلب بالثواني' => round($avgAcceptanceSeconds),
            'نسبة السائقين المتصلين' => $onDutyPercentage . '%',
            'بلاغات الطوارئ اليوم' => $incidents,
            'متوسط تقييم السائقين' => round($averageRating, 1),
        ],
        'data_quality' => empty($reportDriversQueryFailures)
            ? ['state' => 'complete']
            : [
                'state' => 'degraded',
                'failed_components' => array_values(array_unique($reportDriversQueryFailures)),
            ],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage(), 'data' => []], 500);
}
