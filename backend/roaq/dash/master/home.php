<?php
require_once "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function dashboardGrowthPercent($current, $previous)
{
    $current = (float)$current;
    $previous = (float)$previous;
    if ($previous <= 0.0) {
        return $current > 0.0 ? 100.0 : 0.0;
    }

    return (($current - $previous) / $previous) * 100.0;
}

function dashboardTrendDirection($current, $previous)
{
    $current = (float)$current;
    $previous = (float)$previous;

    if (abs($current - $previous) < 0.0001) {
        return 'flat';
    }

    return $current >= $previous ? 'up' : 'down';
}

function dashboardFormatNumber($value, $decimals = 0)
{
    return number_format((float)$value, $decimals, '.', ',');
}

function dashboardRelativeLabel(?string $value): string
{
    $raw = trim((string)$value);
    if ($raw === '' || strtolower($raw) === 'null') {
        return 'اليوم';
    }

    $timestamp = strtotime($raw);
    if ($timestamp === false) {
        return $raw;
    }

    $diffDays = (int)floor((time() - $timestamp) / 86400);
    if ($diffDays <= 0) {
        return 'اليوم';
    }
    if ($diffDays === 1) {
        return 'منذ يوم';
    }
    if ($diffDays === 2) {
        return 'منذ يومين';
    }

    return 'منذ ' . $diffDays . ' أيام';
}

function dashboardRoleLabel($adminRoleId, $fallbackRoleName = '')
{
    switch ((int)$adminRoleId) {
        case 1:
            return 'الأدمن الأساسي';
        case 2:
            return 'مدير الحسابات';
        case 3:
            return 'مدير المطاعم';
        case 4:
            return 'مدير قسم السائقين';
        case 5:
            return 'مدير الدعم الفني';
        default:
            $fallbackRoleName = trim((string)$fallbackRoleName);
            return $fallbackRoleName !== '' ? $fallbackRoleName : 'مدير المنصة';
    }
}

function dashboardMetricLabel($value, $singular, $plural = null)
{
    $count = (int)$value;
    if ($count === 0) {
        return '0 ' . $singular;
    }

    if ($count === 1) {
        return '1 ' . $singular;
    }

    if ($plural === null || $plural === '') {
        $plural = $singular;
    }

    return dashboardFormatNumber($count) . ' ' . $plural;
}

function dashboardStatusItem($label, $healthy, $dotHex = '#1A8B4A')
{
    return [
        'label' => $label,
        'is_healthy' => (bool)$healthy,
        'dot_hex' => $healthy ? $dotHex : '#D92C2C',
    ];
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'dashboard.view');
    ensureMasterDashboardSchema();
    $master = masterPublicData($admin);

    $homeQualityFailures = [];
    $homeTableChecks = [
        'orders' => 'orders',
        'delivery_users' => 'delivery_users',
        'vendors' => 'vendors',
        'vendor_store_settings' => 'vendor_store_settings',
        'users' => 'users',
        'accounting_entries' => 'accounting_entries',
        'ads2' => 'ads2',
        'notifications' => 'notifications',
        'support' => 'support',
        'master_dispute_cases' => 'master_dispute_cases',
        'master_fraud_alerts' => 'master_fraud_alerts',
        'master_content_moderation_queue' => 'master_content_moderation_queue',
        'master_scheduled_exports' => 'master_scheduled_exports',
        'app_legal_documents' => 'app_legal_documents',
        'app_cookie_consent_options' => 'app_cookie_consent_options',
        'master_vendor_settlements' => 'master_vendor_settlements',
        'admin' => 'admin',
        'master_role_profiles' => 'master_role_profiles',
    ];

    foreach ($homeTableChecks as $key => $tableName) {
        if (!tableExists($tableName)) {
            $homeQualityFailures[] = $key . '_schema';
        }
    }

    $roleId = (int)($master['admin_role_id'] ?? $admin['admin_role_id'] ?? 1);
    $roleName = $master['role']['role_name'] ?? '';
    $displayName = trim((string)($master['admin_name'] ?? $admin['admin_name'] ?? ''));
    if ($displayName === '') {
        $displayName = trim((string)($master['admin_email'] ?? $admin['admin_email'] ?? ''));
    }
    if ($displayName === '') {
        $displayName = 'Admin #' . (int)($master['admin_id'] ?? $admin['admin_id'] ?? 0);
    }

    $roleLabel = dashboardRoleLabel($roleId, $roleName);

    $requestedZone = trim((string)($_GET['zone'] ?? ''));
    $selectedZoneId = ctype_digit($requestedZone) ? (int)$requestedZone : 0;
    $ordersZoneWhere = $selectedZoneId > 0 && columnExists('orders', 'delivery_zone_id')
        ? ' WHERE delivery_zone_id = ' . $selectedZoneId
        : '';
    $driversZoneWhere = $selectedZoneId > 0 && columnExists('delivery_users', 'zone_id')
        ? ' WHERE zone_id = ' . $selectedZoneId
        : '';
    $vendorsZoneWhere = $selectedZoneId > 0 && columnExists('vendors', 'zone_id')
        ? ' WHERE v.zone_id = ' . $selectedZoneId
        : '';

    $availableZones = [];
    if (tableExists('delivery_zones')) {
        $vendorZoneCount = columnExists('vendors', 'zone_id')
            ? "(SELECT COUNT(*) FROM vendors vz WHERE vz.zone_id = z.zone_id AND vz.vendor_status = 'active' AND vz.vendor_is_verified = 1)"
            : '0';
        $driverZoneCount = columnExists('delivery_users', 'zone_id')
            ? "(SELECT COUNT(*) FROM delivery_users dz WHERE dz.zone_id = z.zone_id)"
            : '0';
        $zoneRows = $con->query("\n            SELECT z.zone_id, z.zone_name, z.city,\n                   {$vendorZoneCount} AS vendor_count,\n                   {$driverZoneCount} AS driver_count\n            FROM delivery_zones z\n            WHERE z.is_active = 1\n            ORDER BY z.zone_name ASC, z.zone_id ASC\n        ")->fetchAll(PDO::FETCH_ASSOC) ?: [];
        foreach ($zoneRows as $zoneRow) {
            $vendorCount = (int)($zoneRow['vendor_count'] ?? 0);
            $driverCount = (int)($zoneRow['driver_count'] ?? 0);
            if (($vendorCount + $driverCount) <= 0) {
                continue;
            }
            $availableZones[] = [
                'id' => (string)(int)$zoneRow['zone_id'],
                'label' => trim((string)($zoneRow['zone_name'] ?? '')),
                'city' => trim((string)($zoneRow['city'] ?? '')),
                'vendor_count' => $vendorCount,
                'driver_count' => $driverCount,
            ];
        }
    }

    $orderStats = $con->query("
        SELECT
            COUNT(*) AS total_orders,
            SUM(CASE WHEN DATE(orders_datetime) = CURDATE() THEN 1 ELSE 0 END) AS today_orders,
            SUM(CASE WHEN DATE(orders_datetime) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 ELSE 0 END) AS yesterday_orders,
            SUM(CASE WHEN orders_status = 'pending' THEN 1 ELSE 0 END) AS pending_orders,
            SUM(CASE WHEN orders_status = 'pending' AND orders_datetime <= DATE_SUB(NOW(), INTERVAL 2 HOUR) THEN 1 ELSE 0 END) AS late_orders,
            SUM(CASE WHEN orders_status = 'paid' AND DATE(COALESCE(updated_at, orders_datetime)) = CURDATE() THEN 1 ELSE 0 END) AS paid_today,
            SUM(CASE WHEN orders_status = 'paid' AND DATE(COALESCE(updated_at, orders_datetime)) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 ELSE 0 END) AS paid_yesterday,
            COALESCE(SUM(CASE WHEN orders_status = 'paid' AND DATE(COALESCE(updated_at, orders_datetime)) = CURDATE() THEN orders_totalprice ELSE 0 END), 0) AS revenue_today,
            COALESCE(SUM(CASE WHEN orders_status = 'paid' AND DATE(COALESCE(updated_at, orders_datetime)) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN orders_totalprice ELSE 0 END), 0) AS revenue_yesterday,
            SUM(CASE WHEN DATE(orders_datetime) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS week_orders
        FROM orders{$ordersZoneWhere}
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $driverStats = $con->query("
        SELECT
            COUNT(*) AS total_drivers,
            SUM(CASE WHEN status = 'online' OR (last_seen_at IS NOT NULL AND last_seen_at >= (NOW() - INTERVAL 5 MINUTE)) THEN 1 ELSE 0 END) AS online_drivers,
            SUM(CASE WHEN status = 'online' OR (last_seen_at IS NOT NULL AND DATE(last_seen_at) = CURDATE()) THEN 1 ELSE 0 END) AS active_today,
            SUM(CASE WHEN status = 'online' OR (last_seen_at IS NOT NULL AND DATE(last_seen_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)) THEN 1 ELSE 0 END) AS active_yesterday,
            SUM(CASE WHEN status = 'offline' OR (last_seen_at IS NOT NULL AND last_seen_at <= (NOW() - INTERVAL 6 HOUR)) THEN 1 ELSE 0 END) AS follow_up_drivers
        FROM delivery_users{$driversZoneWhere}
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $vendorStats = $con->query("
        SELECT
            COUNT(*) AS total_vendors,
            SUM(CASE WHEN v.vendor_status = 'active' AND v.vendor_is_verified = 1 THEN 1 ELSE 0 END) AS active_vendors,
            SUM(CASE WHEN v.vendor_status = 'active' AND v.vendor_is_verified = 1 AND LOWER(COALESCE(v.vendor_type, 'restaurant')) = 'restaurant' AND COALESCE(s.is_open, 1) = 1 THEN 1 ELSE 0 END) AS open_restaurants,
            SUM(CASE WHEN v.vendor_status = 'active' AND v.vendor_is_verified = 1 AND LOWER(COALESCE(v.vendor_type, 'restaurant')) = 'store' AND COALESCE(s.is_open, 1) = 1 THEN 1 ELSE 0 END) AS open_stores,
            SUM(CASE WHEN v.vendor_status = 'pending' OR v.vendor_is_verified = 0 THEN 1 ELSE 0 END) AS pending_vendors,
            SUM(CASE WHEN v.vendor_status = 'suspended' THEN 1 ELSE 0 END) AS suspended_vendors,
            SUM(CASE WHEN DATE(COALESCE(v.vendor_updated_at, v.vendor_created_at)) = CURDATE() THEN 1 ELSE 0 END) AS active_today,
            SUM(CASE WHEN DATE(COALESCE(v.vendor_updated_at, v.vendor_created_at)) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 ELSE 0 END) AS active_yesterday
        FROM vendors v
        LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
        {$vendorsZoneWhere}
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $userStats = $con->query("
        SELECT
            COUNT(*) AS total_users,
            SUM(CASE WHEN users_approve = 1 THEN 1 ELSE 0 END) AS active_users,
            SUM(CASE WHEN DATE(users_creat) = CURDATE() THEN 1 ELSE 0 END) AS users_today,
            SUM(CASE WHEN DATE(users_creat) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 ELSE 0 END) AS users_yesterday,
            SUM(CASE WHEN DATE(users_creat) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS users_week
        FROM users
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $financeStats = $con->query("
        SELECT
            COUNT(*) AS entries_count,
            SUM(CASE WHEN entry_type = 'sale' THEN 1 ELSE 0 END) AS sales_count,
            SUM(CASE WHEN entry_type = 'refund' THEN 1 ELSE 0 END) AS refunds_count,
            COALESCE(SUM(CASE WHEN entry_type = 'sale' AND DATE(entry_date) = CURDATE() THEN credit ELSE 0 END), 0) AS revenue_today,
            COALESCE(SUM(CASE WHEN entry_type = 'sale' AND DATE(entry_date) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN credit ELSE 0 END), 0) AS revenue_yesterday,
            COALESCE(SUM(CASE WHEN entry_type = 'expense' AND DATE(entry_date) = CURDATE() THEN debit ELSE 0 END), 0) AS expenses_today,
            COALESCE(SUM(CASE WHEN entry_type = 'refund' AND DATE(entry_date) = CURDATE() THEN debit ELSE 0 END), 0) AS refunds_today
        FROM accounting_entries
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $marketingStats = $con->query("
        SELECT
            COUNT(*) AS active_ads,
            SUM(CASE WHEN DATE(COALESCE(updated_at, created_at)) = CURDATE() THEN 1 ELSE 0 END) AS active_today,
            SUM(CASE WHEN DATE(COALESCE(updated_at, created_at)) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 ELSE 0 END) AS active_yesterday
        FROM ads2
        WHERE is_active = 1
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $notificationStats = $con->query("
        SELECT
            COUNT(*) AS total_notifications,
            SUM(CASE WHEN notification_is_read = 0 THEN 1 ELSE 0 END) AS unread_notifications,
            SUM(CASE WHEN DATE(notification_created_at) = CURDATE() THEN 1 ELSE 0 END) AS notifications_today
        FROM notifications
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $supportStats = $con->query("
        SELECT
            COUNT(*) AS support_count,
            SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) AS support_today,
            SUM(CASE WHEN DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS support_week
        FROM support
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $disputeStats = $con->query("
        SELECT
            COUNT(*) AS dispute_count,
            SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) AS dispute_today
        FROM master_dispute_cases
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $fraudStats = $con->query("
        SELECT
            COUNT(*) AS fraud_count,
            SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) AS fraud_today
        FROM master_fraud_alerts
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $moderationStats = $con->query("
        SELECT
            COUNT(*) AS moderation_count,
            SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) AS moderation_today
        FROM master_content_moderation_queue
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $exportsStats = $con->query("
        SELECT
            COUNT(*) AS active_exports,
            MAX(created_at) AS last_export_at
        FROM master_scheduled_exports
        WHERE is_active = 1
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $legalDocsStats = $con->query("
        SELECT
            COUNT(*) AS active_documents,
            MAX(updated_at) AS last_document_at
        FROM app_legal_documents
        WHERE is_active = 1
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $cookieStats = $con->query("
        SELECT
            COUNT(*) AS active_options,
            MAX(updated_at) AS last_option_at
        FROM app_cookie_consent_options
        WHERE is_active = 1
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $settlementStats = $con->query("
        SELECT
            COUNT(*) AS settlements_count,
            COALESCE(SUM(gross_amount), 0) AS gross_amount,
            COALESCE(SUM(commission_amount), 0) AS commission_amount,
            COALESCE(SUM(net_amount), 0) AS net_amount
        FROM master_vendor_settlements
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $adminStats = $con->query("
        SELECT
            COUNT(*) AS total_admins,
            SUM(CASE WHEN admin_approve = 1 THEN 1 ELSE 0 END) AS active_admins,
            COUNT(DISTINCT admin_role_id) AS role_count
        FROM admin
    ")->fetch(PDO::FETCH_ASSOC) ?: [];

    $roleCount = (int)($con->query("SELECT COUNT(*) FROM master_role_profiles")->fetchColumn() ?: 0);

    $latestSettingsCandidates = [
        $legalDocsStats['last_document_at'] ?? null,
        $cookieStats['last_option_at'] ?? null,
        $exportsStats['last_export_at'] ?? null,
        $con->query("SELECT MAX(updated_at) FROM vendor_store_settings")->fetchColumn() ?: null,
    ];

    $latestSettingsAt = null;
    foreach ($latestSettingsCandidates as $candidate) {
        if (!$candidate) {
            continue;
        }
        $candidateTs = strtotime((string)$candidate);
        if ($candidateTs === false) {
            continue;
        }
        if ($latestSettingsAt === null || $candidateTs > $latestSettingsAt) {
            $latestSettingsAt = $candidateTs;
        }
    }

    $sectionActionMap = [
        'operations' => [
            'label' => ((int)($orderStats['late_orders'] ?? 0) > 0)
                ? dashboardMetricLabel($orderStats['late_orders'], 'طلب متأخر', 'طلبات متأخرة')
                : 'لا توجد طلبات متأخرة',
        ],
        'orders' => [
            'label' => dashboardMetricLabel($orderStats['today_orders'] ?? 0, 'طلب جديد', 'طلبات جديدة'),
        ],
        'delivery' => [
            'label' => dashboardMetricLabel($driverStats['follow_up_drivers'] ?? 0, 'سائق بحاجة متابعة', 'سائقين بحاجة متابعة'),
        ],
        'restaurants' => [
            'label' => dashboardMetricLabel($vendorStats['pending_vendors'] ?? 0, 'مطعم بحاجة متابعة', 'مطاعم بحاجة متابعة'),
        ],
        'customers' => [
            'label' => dashboardMetricLabel($userStats['users_week'] ?? 0, 'مستخدم جديد', 'مستخدمين جدد'),
        ],
        'finance' => [
            'label' => dashboardMetricLabel($financeStats['refunds_today'] ?? 0, 'استرداد جديد', 'استردادات جديدة'),
        ],
        'marketing' => [
            'label' => dashboardMetricLabel($marketingStats['active_ads'] ?? 0, 'عرض جديد فعال', 'عروض جديدة فعالة'),
        ],
        'communication' => [
            'label' => dashboardMetricLabel($notificationStats['unread_notifications'] ?? 0, 'رسالة دعم', 'رسائل دعم'),
        ],
        'quality' => [
            'label' => dashboardMetricLabel($disputeStats['dispute_count'] ?? 0, 'شكوى جديدة', 'شكاوى جديدة'),
        ],
        'reports' => [
            'label' => dashboardMetricLabel($exportsStats['active_exports'] ?? 0, 'تقرير مجدول', 'تقارير مجدولة'),
        ],
        'settings' => [
            'label' => $latestSettingsAt
                ? 'آخر تعديل ' . dashboardRelativeLabel(date('Y-m-d H:i:s', $latestSettingsAt))
                : 'لا توجد تحديثات حديثة',
        ],
        'administration' => [
            'label' => dashboardMetricLabel($adminStats['active_admins'] ?? 0, 'موظف مفعل', 'موظفين مفعلين'),
        ],
    ];

    $sectionPermissionMap = [
        'operations' => 'Support',
        'orders' => 'orders.view',
        'delivery' => 'drivers.view',
        'restaurants' => 'restaurants.view',
        'customers' => 'customers.view',
        'finance' => 'finance.view',
        'marketing' => 'Content',
        'communication' => 'Support',
        'quality' => 'Support',
        'reports' => 'reports.view',
        'settings' => 'settings.view',
        'administration' => 'administration.view',
    ];

    $sectionRows = [];
    $sectionStmt = $con->query("
        SELECT
            section_key,
            section_index,
            permission_key,
            title_ar,
            subtitle_en,
            pages_count_label,
            icon_key,
            accent_hex,
            icon_background_hex,
            action_color_hex,
            sort_order,
            is_active
        FROM master_dashboard_sections
        WHERE is_active = 1
        ORDER BY sort_order ASC, section_index ASC
    ");

    while ($row = $sectionStmt->fetch(PDO::FETCH_ASSOC)) {
        $sectionKey = (string)($row['section_key'] ?? '');
        $permissionKey = trim((string)($row['permission_key'] ?? ''));
        if ($permissionKey === '') {
            $permissionKey = $sectionPermissionMap[$sectionKey] ?? '';
        }
        if ($permissionKey !== '' && !masterHasPermission($admin, $permissionKey)) {
            continue;
        }
        $actionLabel = $sectionActionMap[$sectionKey]['label'] ?? 'قريباً';

        $sectionRows[] = [
            'section_key' => $sectionKey,
            'index' => (int)($row['section_index'] ?? 0),
            'permission_key' => $permissionKey,
            'title' => (string)($row['title_ar'] ?? ''),
            'subtitle' => (string)($row['subtitle_en'] ?? ''),
            'pages_count' => (string)($row['pages_count_label'] ?? ''),
            'action_label' => $actionLabel,
            'icon_key' => (string)($row['icon_key'] ?? ''),
            'accent_hex' => (string)($row['accent_hex'] ?? '#3B82F6'),
            'icon_background_hex' => (string)($row['icon_background_hex'] ?? '#EEF2FF'),
            'action_color_hex' => (string)($row['action_color_hex'] ?? '#3B82F6'),
            'enabled' => true,
        ];
    }

    $sidebarItems = [
        ['icon_key' => 'home', 'label' => 'الرئيسية', 'selected' => true],
        ['icon_key' => 'operations', 'label' => 'لوحة العمليات', 'selected' => false],
        ['icon_key' => 'orders', 'label' => 'إدارة الطلبات', 'selected' => false],
        ['icon_key' => 'delivery', 'label' => 'التوصيل والوجستيات', 'selected' => false],
        ['icon_key' => 'store', 'label' => 'إدارة المطاعم', 'selected' => false],
        ['icon_key' => 'users', 'label' => 'العملاء', 'selected' => false],
        ['icon_key' => 'finance', 'label' => 'الإدارة المالية', 'selected' => false],
        ['icon_key' => 'marketing', 'label' => 'التسويق والنمو', 'selected' => false],
        ['icon_key' => 'communication', 'label' => 'مركز التواصل', 'selected' => false],
        ['icon_key' => 'quality', 'label' => 'الجودة وخدمة العملاء', 'selected' => false],
        ['icon_key' => 'reports', 'label' => 'التقارير والتحليلات', 'selected' => false],
        ['icon_key' => 'settings', 'label' => 'إعدادات المنصة', 'selected' => false],
        ['icon_key' => 'administration', 'label' => 'الإدارة والصلاحيات', 'selected' => false],
    ];

    $sidebarPermissionMap = [
        'home' => '',
        'operations' => 'Support',
        'orders' => 'orders.view',
        'delivery' => 'drivers.view',
        'store' => 'restaurants.view',
        'users' => 'customers.view',
        'finance' => 'finance.view',
        'marketing' => 'Content',
        'communication' => 'Support',
        'quality' => 'Support',
        'reports' => 'reports.view',
        'settings' => 'settings.view',
        'administration' => 'administration.view',
    ];
    $sidebarItems = array_values(array_filter($sidebarItems, static function ($item) use ($admin, $sidebarPermissionMap) {
        $key = (string)($item['icon_key'] ?? '');
        $permissionKey = $sidebarPermissionMap[$key] ?? '';
        return $permissionKey === '' || masterHasPermission($admin, $permissionKey);
    }));

    $alerts = [];

    $alertCandidates = [
        [
            'key' => 'late_orders',
            'count' => (int)($orderStats['late_orders'] ?? 0),
            'label' => 'طلبات متأخرة',
            'severity' => 'High',
            'tint_hex' => '#EF4444',
        ],
        [
            'key' => 'pending_vendors',
            'count' => (int)($vendorStats['pending_vendors'] ?? 0),
            'label' => 'مطاعم تحتاج مراجعة',
            'severity' => 'Medium',
            'tint_hex' => '#F59E0B',
        ],
        [
            'key' => 'support',
            'count' => (int)($supportStats['support_count'] ?? 0),
            'label' => 'شكاوى دعم جديدة',
            'severity' => 'Medium',
            'tint_hex' => '#3B82F6',
        ],
        [
            'key' => 'notifications',
            'count' => (int)($notificationStats['unread_notifications'] ?? 0),
            'label' => 'رسائل غير مقروءة',
            'severity' => 'Low',
            'tint_hex' => '#14B8A6',
        ],
        [
            'key' => 'fraud',
            'count' => (int)($fraudStats['fraud_count'] ?? 0),
            'label' => 'تنبيهات احتيال',
            'severity' => 'High',
            'tint_hex' => '#EF4444',
        ],
        [
            'key' => 'disputes',
            'count' => (int)($disputeStats['dispute_count'] ?? 0),
            'label' => 'حالات نزاع',
            'severity' => 'High',
            'tint_hex' => '#F97316',
        ],
        [
            'key' => 'moderation',
            'count' => (int)($moderationStats['moderation_count'] ?? 0),
            'label' => 'مراجعات محتوى',
            'severity' => 'Medium',
            'tint_hex' => '#8B5CF6',
        ],
    ];

    foreach ($alertCandidates as $candidate) {
        if ($candidate['count'] <= 0) {
            continue;
        }

        $alerts[] = [
            'key' => $candidate['key'],
            'label' => $candidate['label'],
            'count' => $candidate['count'],
            'severity_label' => $candidate['severity'],
            'tint_hex' => $candidate['tint_hex'],
        ];
    }

    if (empty($alerts)) {
        $alerts[] = [
            'key' => 'healthy',
            'label' => 'لا توجد تنبيهات حالياً',
            'count' => 0,
            'severity_label' => 'Info',
            'tint_hex' => '#10B981',
        ];
    }

    $alertCount = count($alerts);
    $serviceStatusLabel = $alertCount > 0 ? 'جميع الخدمات تعمل مع وجود تنبيهات' : 'جميع الخدمات تعمل';

    $statusItems = [
        dashboardStatusItem('API Server', true),
        dashboardStatusItem('Database', true),
        dashboardStatusItem('Firebase', true),
        dashboardStatusItem('Maps', ((int)($vendorStats['open_restaurants'] ?? 0) > 0)),
        dashboardStatusItem('Notifications', ((int)($notificationStats['total_notifications'] ?? 0) >= 0)),
    ];

    $ordersToday = (int)($orderStats['today_orders'] ?? 0);
    $ordersYesterday = (int)($orderStats['yesterday_orders'] ?? 0);
    $revenueToday = (float)($financeStats['revenue_today'] ?? $orderStats['revenue_today'] ?? 0);
    $revenueYesterday = (float)($financeStats['revenue_yesterday'] ?? $orderStats['revenue_yesterday'] ?? 0);
    $driversOnline = (int)($driverStats['online_drivers'] ?? 0);
    $driversYesterday = (int)($driverStats['active_yesterday'] ?? 0);
    $restaurantsOpen = (int)($vendorStats['open_restaurants'] ?? 0);
    $storesOpen = (int)($vendorStats['open_stores'] ?? 0);
    $restaurantsYesterday = (int)($vendorStats['active_yesterday'] ?? 0);

    $stats = [
        [
            'key' => 'orders_today',
            'title' => 'إجمالي الطلبات اليوم',
            'value' => dashboardFormatNumber($ordersToday),
            'subtitle' => 'مقارنة باليوم السابق',
            'trend_value' => dashboardFormatNumber(abs(dashboardGrowthPercent($ordersToday, $ordersYesterday)), 0) . '%',
            'trend_direction' => dashboardTrendDirection($ordersToday, $ordersYesterday),
            'icon_key' => 'orders',
            'accent_hex' => '#1E7D3F',
            'icon_background_hex' => '#EAF5ED',
        ],
        [
            'key' => 'revenue_today',
            'title' => 'الإيرادات اليوم',
            'value' => dashboardFormatNumber($revenueToday, 0),
            'subtitle' => 'مقارنة باليوم السابق',
            'trend_value' => dashboardFormatNumber(abs(dashboardGrowthPercent($revenueToday, $revenueYesterday)), 0) . '%',
            'trend_direction' => dashboardTrendDirection($revenueToday, $revenueYesterday),
            'icon_key' => 'finance',
            'accent_hex' => '#177A48',
            'icon_background_hex' => '#EAF5ED',
            'value_suffix' => 'ر.س',
        ],
        [
            'key' => 'drivers_online',
            'title' => 'السائقون المتاحون',
            'value' => dashboardFormatNumber($driversOnline),
            'subtitle' => 'مقارنة باليوم السابق',
            'trend_value' => dashboardFormatNumber(abs(dashboardGrowthPercent($driversOnline, $driversYesterday)), 0) . '%',
            'trend_direction' => dashboardTrendDirection($driversOnline, $driversYesterday),
            'icon_key' => 'delivery',
            'accent_hex' => '#5B4ADE',
            'icon_background_hex' => '#F0EEFF',
        ],
        [
            'key' => 'restaurants_open',
            'title' => 'المطاعم المفتوحة',
            'value' => dashboardFormatNumber($restaurantsOpen),
            'subtitle' => 'مقارنة باليوم السابق',
            'trend_value' => dashboardFormatNumber(abs(dashboardGrowthPercent($restaurantsOpen, $restaurantsYesterday)), 0) . '%',
            'trend_direction' => dashboardTrendDirection($restaurantsOpen, $restaurantsYesterday),
            'icon_key' => 'store',
            'accent_hex' => '#EF8A18',
            'icon_background_hex' => '#FFF4E4',
        ],
        [
            'key' => 'stores_open',
            'title' => 'Ø§Ù„Ù…ØªØ§Ø¬Ø± Ø§Ù„Ù…ÙØªÙˆØ­Ø©',
            'value' => dashboardFormatNumber($storesOpen),
            'subtitle' => 'Ø§Ù„Ù…ØªØ§Ø¬Ø± Ø§Ù„Ù†Ø´Ø·Ø© Ø­Ø§Ù„ÙŠØ§Ù‹',
            'trend_value' => '',
            'trend_direction' => 'up',
            'icon_key' => 'stores',
            'accent_hex' => '#2563EB',
            'icon_background_hex' => '#EAF2FF',
        ],
    ];

    $footerVersion = 'FOXA Platform v1.0.0';

    $serverNow = (new DateTimeImmutable('now'))->format(DateTimeInterface::ATOM);

    respondJson([
        'status' => 'success',
        'role' => 'master',
        'master' => $master,
        'data' => [
            'server_now' => $serverNow,
            'platform_title' => 'لوحة تحكم صاحب المنصة',
            'platform_subtitle' => 'Platform Control Center',
            'profile' => [
                'display_name' => $displayName,
                'role_label' => $roleLabel,
                'notification_badge' => (int)($notificationStats['unread_notifications'] ?? 0),
            ],
            'status_label' => $serviceStatusLabel,
            'alert' => [
                'count' => $alertCount,
                'message' => $alertCount > 0
                    ? 'لديك ' . $alertCount . ' تنبيهات تحتاج متابعة'
                    : 'لا توجد تنبيهات حالياً',
                'items' => $alerts,
            ],
            'stats' => $stats,
             'available_zones' => $availableZones,
            'sections' => $sectionRows,
            'sidebar_items' => $sidebarItems,
            'status_items' => $statusItems,
            'footer_version' => $footerVersion,
            'data_quality' => empty($homeQualityFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($homeQualityFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
