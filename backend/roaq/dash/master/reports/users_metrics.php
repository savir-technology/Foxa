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

$reportUsersQueryFailures = [];

function reportUsersMarkQueryFailure(string $component, Throwable $error): void
{
    global $reportUsersQueryFailures;
    $reportUsersQueryFailures[] = $component;
    error_log('master reports users ' . $component . ' failed: ' . $error->getMessage());
}

function reportUsersScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        reportUsersMarkQueryFailure('scalar_query', $e);
        return $fallback;
    }
}

function reportUsersRows(string $sql, array $params = []): array
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        reportUsersMarkQueryFailure('rows_query', $e);
        return [];
    }
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'reports.view');
    $master = masterPublicData($admin);

    if (!tableExists('users')) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [],
            'data_quality' => [
                'state' => 'degraded',
                'failed_components' => ['users_schema'],
            ],
        ]);
    }

    $createdColumn = columnExists('users', 'users_creat') ? 'users_creat' : (columnExists('users', 'created_at') ? 'created_at' : '');
    $newWeek = $createdColumn === ''
        ? 0
        : (int)reportUsersScalar("SELECT COUNT(*) FROM users WHERE {$createdColumn} >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)");
    $newMonth = $createdColumn === ''
        ? 0
        : (int)reportUsersScalar("SELECT COUNT(*) FROM users WHERE {$createdColumn} >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)");

    $activeWeek = 0;
    $repeatCustomers = 0;
    if (tableExists('orders') && columnExists('orders', 'orders_usersid') && columnExists('orders', 'orders_datetime')) {
        $activeWeek = (int)reportUsersScalar("
            SELECT COUNT(DISTINCT orders_usersid)
            FROM orders
            WHERE orders_usersid IS NOT NULL
              AND orders_datetime >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        ");
        $repeatCustomers = (int)reportUsersScalar("
            SELECT COUNT(*)
            FROM (
                SELECT orders_usersid
                FROM orders
                WHERE orders_usersid IS NOT NULL
                GROUP BY orders_usersid
                HAVING COUNT(*) >= 2
            ) repeat_users
        ");
    }

    $totalUsers = (int)reportUsersScalar('SELECT COUNT(*) FROM users');
    $activeUsers = columnExists('users', 'users_approve')
        ? (int)reportUsersScalar('SELECT COUNT(*) FROM users WHERE users_approve = 1')
        : $totalUsers;
    $retention7d = $totalUsers > 0 ? round(($activeWeek / $totalUsers) * 100, 1) : 0;

    $ratings = [];
    if (tableExists('ratings') && columnExists('ratings', 'rating')) {
        $ratingRows = reportUsersRows("
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
            'إجمالي المستخدمين' => $totalUsers,
            'مستخدمون مفعلون' => $activeUsers,
            'مستخدمون جدد خلال 7 أيام' => $newWeek,
            'مستخدمون جدد خلال 30 يوم' => $newMonth,
            'مستخدمون نشطون خلال 7 أيام' => $activeWeek,
            'عملاء متكررون' => $repeatCustomers,
            'معدل النشاط الأسبوعي' => $retention7d . '%',
            'ratings' => $ratings,
        ],
        'data_quality' => empty($reportUsersQueryFailures)
            ? ['state' => 'complete']
            : [
                'state' => 'degraded',
                'failed_components' => array_values(array_unique($reportUsersQueryFailures)),
            ],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage(), 'data' => []], 500);
}
