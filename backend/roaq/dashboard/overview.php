<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../connect.php';

function growthPercent($current, $previous)
{
    $current = floatval($current);
    $previous = floatval($previous);
    if ($previous <= 0) {
        return $current > 0 ? 100.0 : 0.0;
    }
    return (($current - $previous) / $previous) * 100.0;
}

try {
    // Stats
    $totalInvestors = intval($con->query("SELECT COUNT(DISTINCT user_id) FROM property_contracts")->fetchColumn() ?: 0);
    $activeProperties = intval($con->query("SELECT COUNT(*) FROM items WHERE items_active = 1")->fetchColumn() ?: 0);
    $totalContracts = intval($con->query("SELECT COUNT(*) FROM property_contracts")->fetchColumn() ?: 0);
    $totalRevenue = floatval($con->query("SELECT COALESCE(SUM(amount),0) FROM property_installments WHERE status = 'paid'")->fetchColumn() ?: 0);

    // Growth (this month vs previous month)
    $investorsCurrent = intval($con->query("
        SELECT COUNT(DISTINCT user_id)
        FROM property_contracts
        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    ")->fetchColumn() ?: 0);
    $investorsPrev = intval($con->query("
        SELECT COUNT(DISTINCT user_id)
        FROM property_contracts
        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')
    ")->fetchColumn() ?: 0);

    $propertiesCurrent = intval($con->query("
        SELECT COUNT(*)
        FROM items
        WHERE DATE_FORMAT(items_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    ")->fetchColumn() ?: 0);
    $propertiesPrev = intval($con->query("
        SELECT COUNT(*)
        FROM items
        WHERE DATE_FORMAT(items_date, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')
    ")->fetchColumn() ?: 0);

    $contractsCurrent = intval($con->query("
        SELECT COUNT(*)
        FROM property_contracts
        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    ")->fetchColumn() ?: 0);
    $contractsPrev = intval($con->query("
        SELECT COUNT(*)
        FROM property_contracts
        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')
    ")->fetchColumn() ?: 0);

    $revenueCurrent = floatval($con->query("
        SELECT COALESCE(SUM(amount),0)
        FROM property_installments
        WHERE status = 'paid'
          AND DATE_FORMAT(COALESCE(paid_at, created_at), '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
    ")->fetchColumn() ?: 0);
    $revenuePrev = floatval($con->query("
        SELECT COALESCE(SUM(amount),0)
        FROM property_installments
        WHERE status = 'paid'
          AND DATE_FORMAT(COALESCE(paid_at, created_at), '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')
    ")->fetchColumn() ?: 0);

    // Recent users
    $usersStmt = $con->prepare("
        SELECT users_id, users_name, users_email, user_role, users_approve, users_creat
        FROM users
        ORDER BY users_creat DESC
        LIMIT 5
    ");
    $usersStmt->execute();
    $recentUsers = $usersStmt->fetchAll(PDO::FETCH_ASSOC);

    // Recent properties
    $propsStmt = $con->prepare("
        SELECT
            i.items_id,
            i.items_name_ar,
            i.items_name_en,
            i.items_price,
            i.property_status,
            i.items_date,
            (SELECT COUNT(*) FROM favorite f WHERE f.favorite_itemsid = i.items_id) AS views
        FROM items i
        ORDER BY i.items_date DESC
        LIMIT 5
    ");
    $propsStmt->execute();
    $recentProperties = $propsStmt->fetchAll(PDO::FETCH_ASSOC);

    // Sales trend (last 12 months)
    $trendMap = [];
    for ($m = 11; $m >= 0; $m--) {
        $monthKey = date('Y-m', strtotime("-$m months"));
        $trendMap[$monthKey] = 0.0;
    }

    $trendStmt = $con->prepare("
        SELECT DATE_FORMAT(COALESCE(paid_at, created_at), '%Y-%m') AS ym, COALESCE(SUM(amount),0) AS total
        FROM property_installments
        WHERE status = 'paid'
          AND COALESCE(paid_at, created_at) >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 11 MONTH)
        GROUP BY ym
        ORDER BY ym ASC
    ");
    $trendStmt->execute();
    foreach ($trendStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $k = (string)$row['ym'];
        if (array_key_exists($k, $trendMap)) {
            $trendMap[$k] = floatval($row['total']);
        }
    }

    $trend = [];
    foreach ($trendMap as $month => $value) {
        $trend[] = [
            'month' => $month,
            'value' => $value,
        ];
    }

    // Health
    $pendingInstallments = intval($con->query("SELECT COUNT(*) FROM property_installments WHERE status = 'pending'")->fetchColumn() ?: 0);
    $openChats = intval($con->query("SELECT COUNT(*) FROM chats WHERE is_active = 1")->fetchColumn() ?: 0);
    $totalUsers = intval($con->query("SELECT COUNT(*) FROM users WHERE users_approve = 1")->fetchColumn() ?: 0);
    $totalCategories = intval($con->query("SELECT COUNT(*) FROM categories")->fetchColumn() ?: 0);
    $totalVideos = intval($con->query("SELECT COUNT(*) FROM videos")->fetchColumn() ?: 0);
    $totalAds2 = intval($con->query("SELECT COUNT(*) FROM ads2")->fetchColumn() ?: 0);
    $pendingOrders = intval($con->query("SELECT COUNT(*) FROM orders WHERE orders_status = 'pending'")->fetchColumn() ?: 0);
    $health = [
        ['label' => 'الخوادم', 'value' => 0.99],
        ['label' => 'قاعدة البيانات', 'value' => 0.98],
        ['label' => 'نشاط المحادثات', 'value' => $openChats > 0 ? 0.96 : 0.90],
        ['label' => 'تحصيل الدفعات', 'value' => $pendingInstallments > 0 ? 0.91 : 0.97],
    ];

    echo json_encode([
        'status' => 'success',
        'data' => [
            'stats' => [
                [
                    'key' => 'investors',
                    'title' => 'إجمالي المستثمرين',
                    'value' => $totalInvestors,
                    'growth' => round(growthPercent($investorsCurrent, $investorsPrev), 1),
                ],
                [
                    'key' => 'properties',
                    'title' => 'العقارات النشطة',
                    'value' => $activeProperties,
                    'growth' => round(growthPercent($propertiesCurrent, $propertiesPrev), 1),
                ],
                [
                    'key' => 'revenue',
                    'title' => 'إجمالي العائدات',
                    'value' => $totalRevenue,
                    'growth' => round(growthPercent($revenueCurrent, $revenuePrev), 1),
                ],
                [
                    'key' => 'contracts',
                    'title' => 'العقود',
                    'value' => $totalContracts,
                    'growth' => round(growthPercent($contractsCurrent, $contractsPrev), 1),
                ],
            ],
            'recent_users' => $recentUsers,
            'recent_properties' => $recentProperties,
            'health' => $health,
            'sales_trend' => $trend,
            'module_metrics' => [
                'approved_users' => $totalUsers,
                'active_chats' => $openChats,
                'pending_installments' => $pendingInstallments,
                'categories' => $totalCategories,
                'reels_videos' => $totalVideos,
                'ads2' => $totalAds2,
                'pending_orders' => $pendingOrders,
            ],
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('overview.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
