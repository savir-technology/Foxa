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
    $totalInvestors = intval($con->query("SELECT COUNT(DISTINCT user_id) FROM property_contracts")->fetchColumn() ?: 0);
    $activeProperties = intval($con->query("SELECT COUNT(*) FROM items WHERE items_active = 1")->fetchColumn() ?: 0);
    $totalContracts = intval($con->query("SELECT COUNT(*) FROM property_contracts")->fetchColumn() ?: 0);

    $installmentsRevenue = floatval($con->query("SELECT COALESCE(SUM(amount),0) FROM property_installments WHERE status = 'paid'")->fetchColumn() ?: 0);
    $ordersRevenue = floatval($con->query("SELECT COALESCE(SUM(orders_totalprice),0) FROM orders WHERE orders_status = 'paid'")->fetchColumn() ?: 0);
    $totalRevenue = $installmentsRevenue + $ordersRevenue;

    $investorsCurrent = intval($con->query("\n        SELECT COUNT(DISTINCT user_id)\n        FROM property_contracts\n        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')\n    ")->fetchColumn() ?: 0);
    $investorsPrev = intval($con->query("\n        SELECT COUNT(DISTINCT user_id)\n        FROM property_contracts\n        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')\n    ")->fetchColumn() ?: 0);

    $propertiesCurrent = intval($con->query("\n        SELECT COUNT(*)\n        FROM items\n        WHERE DATE_FORMAT(items_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')\n    ")->fetchColumn() ?: 0);
    $propertiesPrev = intval($con->query("\n        SELECT COUNT(*)\n        FROM items\n        WHERE DATE_FORMAT(items_date, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')\n    ")->fetchColumn() ?: 0);

    $contractsCurrent = intval($con->query("\n        SELECT COUNT(*)\n        FROM property_contracts\n        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')\n    ")->fetchColumn() ?: 0);
    $contractsPrev = intval($con->query("\n        SELECT COUNT(*)\n        FROM property_contracts\n        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')\n    ")->fetchColumn() ?: 0);

    $revenueCurrentInstallments = floatval($con->query("\n        SELECT COALESCE(SUM(amount),0)\n        FROM property_installments\n        WHERE status = 'paid'\n          AND DATE_FORMAT(COALESCE(paid_at, created_at), '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')\n    ")->fetchColumn() ?: 0);
    $revenuePrevInstallments = floatval($con->query("\n        SELECT COALESCE(SUM(amount),0)\n        FROM property_installments\n        WHERE status = 'paid'\n          AND DATE_FORMAT(COALESCE(paid_at, created_at), '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')\n    ")->fetchColumn() ?: 0);

    $revenueCurrentOrders = floatval($con->query("\n        SELECT COALESCE(SUM(orders_totalprice),0)\n        FROM orders\n        WHERE orders_status = 'paid'\n          AND DATE_FORMAT(COALESCE(updated_at, orders_datetime), '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')\n    ")->fetchColumn() ?: 0);
    $revenuePrevOrders = floatval($con->query("\n        SELECT COALESCE(SUM(orders_totalprice),0)\n        FROM orders\n        WHERE orders_status = 'paid'\n          AND DATE_FORMAT(COALESCE(updated_at, orders_datetime), '%Y-%m') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')\n    ")->fetchColumn() ?: 0);

    $revenueCurrent = $revenueCurrentInstallments + $revenueCurrentOrders;
    $revenuePrev = $revenuePrevInstallments + $revenuePrevOrders;

    $usersStmt = $con->prepare("\n        SELECT users_id, users_name, users_email, user_role, users_approve, users_creat\n        FROM users\n        ORDER BY users_creat DESC\n        LIMIT 5\n    ");
    $usersStmt->execute();
    $recentUsers = $usersStmt->fetchAll(PDO::FETCH_ASSOC);

    $propsStmt = $con->prepare("\n        SELECT\n            i.items_id,\n            i.items_name_ar,\n            i.items_name_en,\n            i.items_price,\n            i.property_status,\n            i.items_date,\n            (SELECT COUNT(*) FROM favorite f WHERE f.favorite_itemsid = i.items_id) AS views\n        FROM items i\n        ORDER BY i.items_date DESC\n        LIMIT 5\n    ");
    $propsStmt->execute();
    $recentProperties = $propsStmt->fetchAll(PDO::FETCH_ASSOC);

    $trendMap = [];
    for ($m = 11; $m >= 0; $m--) {
        $monthKey = date('Y-m', strtotime("-$m months"));
        $trendMap[$monthKey] = 0.0;
    }

    $trendInstallmentsStmt = $con->prepare("\n        SELECT DATE_FORMAT(COALESCE(paid_at, created_at), '%Y-%m') AS ym, COALESCE(SUM(amount),0) AS total\n        FROM property_installments\n        WHERE status = 'paid'\n          AND COALESCE(paid_at, created_at) >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 11 MONTH)\n        GROUP BY ym\n        ORDER BY ym ASC\n    ");
    $trendInstallmentsStmt->execute();
    foreach ($trendInstallmentsStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $k = (string)($row['ym'] ?? '');
        if ($k !== '' && array_key_exists($k, $trendMap)) {
            $trendMap[$k] += floatval($row['total'] ?? 0);
        }
    }

    $trendOrdersStmt = $con->prepare("\n        SELECT DATE_FORMAT(COALESCE(updated_at, orders_datetime), '%Y-%m') AS ym, COALESCE(SUM(orders_totalprice),0) AS total\n        FROM orders\n        WHERE orders_status = 'paid'\n          AND COALESCE(updated_at, orders_datetime) >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 11 MONTH)\n        GROUP BY ym\n        ORDER BY ym ASC\n    ");
    $trendOrdersStmt->execute();
    foreach ($trendOrdersStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $k = (string)($row['ym'] ?? '');
        if ($k !== '' && array_key_exists($k, $trendMap)) {
            $trendMap[$k] += floatval($row['total'] ?? 0);
        }
    }

    $trend = [];
    foreach ($trendMap as $month => $value) {
        $trend[] = [
            'month' => $month,
            'value' => round(floatval($value), 2),
        ];
    }

    $pendingInstallments = intval($con->query("SELECT COUNT(*) FROM property_installments WHERE status = 'pending'")->fetchColumn() ?: 0);
    $paidInstallmentsCount = intval($con->query("SELECT COUNT(*) FROM property_installments WHERE status = 'paid'")->fetchColumn() ?: 0);
    $totalInstallmentsCount = intval($con->query("SELECT COUNT(*) FROM property_installments")->fetchColumn() ?: 0);

    $openChats = intval($con->query("SELECT COUNT(*) FROM chats WHERE is_active = 1")->fetchColumn() ?: 0);
    $totalChats = intval($con->query("SELECT COUNT(*) FROM chats")->fetchColumn() ?: 0);

    $totalUsers = intval($con->query("SELECT COUNT(*) FROM users WHERE users_approve = 1")->fetchColumn() ?: 0);
    $totalCategories = intval($con->query("SELECT COUNT(*) FROM categories")->fetchColumn() ?: 0);
    $totalVideos = intval($con->query("SELECT COUNT(*) FROM videos")->fetchColumn() ?: 0);
    $totalAds2 = intval($con->query("SELECT COUNT(*) FROM ads2")->fetchColumn() ?: 0);

    $pendingOrders = intval($con->query("SELECT COUNT(*) FROM orders WHERE orders_status = 'pending'")->fetchColumn() ?: 0);
    $paidOrdersCount = intval($con->query("SELECT COUNT(*) FROM orders WHERE orders_status = 'paid'")->fetchColumn() ?: 0);
    $totalOrdersCount = intval($con->query("SELECT COUNT(*) FROM orders")->fetchColumn() ?: 0);

    $recentActivityUsers = intval($con->query("\n        SELECT COUNT(*) FROM users WHERE users_creat >= DATE_SUB(NOW(), INTERVAL 7 DAY)\n    ")->fetchColumn() ?: 0);
    $recentActivityOrders = intval($con->query("\n        SELECT COUNT(*) FROM orders WHERE orders_datetime >= DATE_SUB(NOW(), INTERVAL 7 DAY)\n    ")->fetchColumn() ?: 0);
    $recentActivityContracts = intval($con->query("\n        SELECT COUNT(*) FROM property_contracts WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)\n    ")->fetchColumn() ?: 0);

    $recentActivity = $recentActivityUsers + $recentActivityOrders + $recentActivityContracts;
    $activityHealth = min(1.0, 0.35 + ($recentActivity / 30.0));

    $chatHealth = $totalChats > 0
        ? min(1.0, 0.70 + (($openChats / max(1, $totalChats)) * 0.30))
        : 0.80;

    $collectionNumerator = $paidInstallmentsCount + $paidOrdersCount;
    $collectionDenominator = $totalInstallmentsCount + $totalOrdersCount;
    $collectionHealth = $collectionDenominator > 0
        ? max(0.0, min(1.0, $collectionNumerator / $collectionDenominator))
        : 0.85;

    $health = [
        ['label' => 'حيوية النظام', 'value' => round($activityHealth, 4)],
        ['label' => 'قاعدة البيانات', 'value' => 1.0],
        ['label' => 'نشاط المحادثات', 'value' => round($chatHealth, 4)],
        ['label' => 'تحصيل المدفوعات', 'value' => round($collectionHealth, 4)],
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
?>
