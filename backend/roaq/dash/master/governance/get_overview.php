<?php
include "../../../connect.php";
require_once __DIR__ . "/../../../notifications/notification_helper.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$actor = requireDashboardActor(['master']);
requireMasterPermission($actor['master'] ?? [], 'reports.view');
ensureNotificationsTable($con);

function formatDateLabel($value)
{
    if (!$value) {
        return 'No activity yet';
    }

    $timestamp = strtotime((string)$value);
    if ($timestamp === false) {
        return (string)$value;
    }

    return date('Y-m-d H:i', $timestamp);
}

try {
    $paidOrdersCount = (int)$con->query("
        SELECT COUNT(*)
        FROM orders
        WHERE orders_status = 'paid'
    ")->fetchColumn();

    $gmv = (float)$con->query("
        SELECT COALESCE(SUM(orders_totalprice), 0)
        FROM orders
        WHERE orders_status = 'paid'
    ")->fetchColumn();

    $activeVendors = (int)$con->query("
        SELECT COUNT(*)
        FROM vendors
        WHERE vendor_status = 'active'
          AND vendor_is_verified = 1
    ")->fetchColumn();

    $aov = $paidOrdersCount > 0 ? $gmv / $paidOrdersCount : 0.0;

    $roles = [];
    $employees = [];
    $roleStmt = $con->query("
        SELECT
            a.admin_id,
            a.admin_name,
            a.admin_email,
            a.admin_phone,
            a.admin_approve,
            a.admin_role_id,
            rp.role_name,
            rp.role_scope,
            rp.tint_hex,
            a.admin_create,
            latest.last_used_at
        FROM admin a
        LEFT JOIN master_role_profiles rp ON rp.role_id = a.admin_role_id
        LEFT JOIN (
            SELECT admin_id, MAX(last_used_at) AS last_used_at
            FROM master_sessions
            GROUP BY admin_id
        ) latest ON latest.admin_id = a.admin_id
        ORDER BY COALESCE(latest.last_used_at, a.admin_create) DESC, a.admin_id DESC
    ");

    while ($row = $roleStmt->fetch(PDO::FETCH_ASSOC)) {
        $permissions = [];
        $permissions[] = ((int)$row['admin_approve'] === 1) ? 'Approved account' : 'Pending approval';
        if (!empty($row['admin_phone'])) {
            $permissions[] = 'Phone ' . $row['admin_phone'];
        }
        $permissions[] = 'Created ' . formatDateLabel($row['admin_create']);
        $permissions[] = 'Last active ' . formatDateLabel($row['last_used_at']);

        $roles[] = [
            'role_name' => $row['admin_name'],
            'role_scope' => $row['admin_email'] . ' - Master account',
            'permissions_json' => json_encode($permissions, JSON_UNESCAPED_UNICODE),
            'tint_hex' => ((int)$row['admin_approve'] === 1) ? '#3B82F6' : '#F59E0B',
        ];

        $employees[] = [
            'admin_id' => (int)($row['admin_id'] ?? 0),
            'name' => (string)($row['admin_name'] ?? ''),
            'email' => (string)($row['admin_email'] ?? ''),
            'phone' => (string)($row['admin_phone'] ?? ''),
            'department' => (string)($row['role_scope'] ?? 'Master Control'),
            'role_label' => (string)($row['role_name'] ?? ('Role #' . (int)($row['admin_role_id'] ?? 0))),
            'job_title' => (string)($row['role_name'] ?? 'Platform employee'),
            'status' => ((int)$row['admin_approve'] === 1) ? 'نشط' : 'معلق',
            'status_hex' => ((int)$row['admin_approve'] === 1) ? '#1A8B4A' : '#F59E0B',
            'last_login' => formatDateLabel($row['last_used_at']),
            'avatar_hex' => (string)($row['tint_hex'] ?? '#1A8B4A'),
        ];
    }

    $audit = [];
    $sessions = [];
    $auditStmt = $con->query("
        SELECT
            a.admin_name,
            ms.ip_address,
            ms.user_agent,
            ms.last_used_at,
            ms.created_at
        FROM master_sessions ms
        INNER JOIN admin a ON a.admin_id = ms.admin_id
        ORDER BY ms.last_used_at DESC, ms.session_id DESC
        LIMIT 20
    ");

    while ($row = $auditStmt->fetch(PDO::FETCH_ASSOC)) {
        $entity = trim((string)$row['ip_address']) !== ''
            ? 'IP ' . $row['ip_address']
            : 'Unknown IP';

        $action = 'Master session authenticated';
        if (!empty($row['user_agent'])) {
            $action .= ' - ' . substr((string)$row['user_agent'], 0, 48);
        }

        $audit[] = [
            'actor_name' => $row['admin_name'],
            'action_text' => $action,
            'entity_label' => $entity,
            'action_time_label' => formatDateLabel($row['last_used_at'] ?: $row['created_at']),
            'tint_hex' => '#3B82F6',
        ];

        $sessions[] = [
            'name' => (string)($row['admin_name'] ?? ''),
            'platform' => trim((string)($row['user_agent'] ?? '')) !== ''
                ? substr((string)$row['user_agent'], 0, 64)
                : $entity,
            'status' => 'نشطة',
            'status_hex' => '#1A8B4A',
            'avatar_hex' => '#3B82F6',
        ];
    }

    $onboarding = [];
    $onboardingStmt = $con->query("
        SELECT
            vendor_id,
            vendor_name,
            store_name,
            vendor_status,
            vendor_is_verified,
            vendor_created_at
        FROM vendors
        ORDER BY vendor_created_at DESC, vendor_id DESC
        LIMIT 20
    ");

    while ($row = $onboardingStmt->fetch(PDO::FETCH_ASSOC)) {
        $stepName = 'Awaiting activation review';
        $statusLabel = 'Pending';
        $tint = '#F59E0B';

        if ($row['vendor_status'] === 'active' && (int)$row['vendor_is_verified'] === 1) {
            $stepName = 'Store is live and verified';
            $statusLabel = 'Completed';
            $tint = '#10B981';
        } elseif ($row['vendor_status'] === 'suspended') {
            $stepName = 'Store suspended and needs compliance review';
            $statusLabel = 'Suspended';
            $tint = '#EF4444';
        } elseif ((int)$row['vendor_is_verified'] === 1) {
            $stepName = 'Verified identity waiting for operational activation';
            $statusLabel = 'Verified';
            $tint = '#3B82F6';
        }

        $onboarding[] = [
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'vendor_name' => $row['store_name'],
            'step_name' => $stepName . ' - ' . formatDateLabel($row['vendor_created_at']),
            'status_label' => $statusLabel,
            'tint_hex' => $tint,
        ];
    }

    $settlements = [];
    $settlementStmt = $con->query("
        SELECT
            v.vendor_id,
            v.store_name,
            COALESCE(SUM(vo.vendor_total), 0) AS gross_amount,
            COALESCE(SUM(CASE WHEN vo.vendor_status = 'pending' THEN vo.vendor_total ELSE 0 END), 0) AS pending_amount,
            COALESCE(SUM(CASE WHEN vo.vendor_status = 'paid' THEN vo.vendor_total ELSE 0 END), 0) AS paid_amount,
            MAX(vo.updated_at) AS last_activity
        FROM vendors v
        LEFT JOIN vendor_orders vo ON vo.vendor_id = v.vendor_id
        GROUP BY v.vendor_id, v.store_name
        ORDER BY gross_amount DESC, v.vendor_id ASC
        LIMIT 20
    ");

    while ($row = $settlementStmt->fetch(PDO::FETCH_ASSOC)) {
        $settlements[] = [
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'vendor_name' => $row['store_name'],
            'gross_amount' => $row['gross_amount'],
            'commission_amount' => $row['pending_amount'],
            'net_amount' => $row['paid_amount'],
            'period_label' => formatDateLabel($row['last_activity']),
        ];
    }

    $fraud = [];

    $riskAlertsCount = 0;

    $pendingBurstStmt = $con->query("
        SELECT
            orders_usersid,
            COUNT(*) AS pending_count,
            COALESCE(SUM(orders_totalprice), 0) AS pending_total
        FROM orders
        WHERE orders_status = 'pending'
        GROUP BY orders_usersid
        HAVING COUNT(*) >= 3
        ORDER BY pending_count DESC, pending_total DESC
        LIMIT 5
    ");

    while ($row = $pendingBurstStmt->fetch(PDO::FETCH_ASSOC)) {
        $riskAlertsCount++;
        $fraud[] = [
            'alert_title' => 'Customer #' . $row['orders_usersid'] . ' has repeated pending orders',
            'alert_detail' => $row['pending_count'] . ' pending orders totaling SAR ' . number_format((float)$row['pending_total'], 0),
            'severity_label' => 'Medium',
            'tint_hex' => '#F59E0B',
        ];
    }

    $failedPaymentsStmt = $con->query("
        SELECT
            orders_usersid,
            COUNT(*) AS failed_count
        FROM orders
        WHERE orders_status = 'failed'
        GROUP BY orders_usersid
        HAVING COUNT(*) >= 1
        ORDER BY failed_count DESC
        LIMIT 5
    ");

    while ($row = $failedPaymentsStmt->fetch(PDO::FETCH_ASSOC)) {
        $riskAlertsCount++;
        $fraud[] = [
            'alert_title' => 'Customer #' . $row['orders_usersid'] . ' has failed payment attempts',
            'alert_detail' => $row['failed_count'] . ' failed orders require payment review',
            'severity_label' => 'High',
            'tint_hex' => '#EF4444',
        ];
    }

    $suspendedVendorStmt = $con->query("
        SELECT
            v.store_name,
            COUNT(i.items_id) AS active_items_count
        FROM vendors v
        INNER JOIN items i ON i.vendor_id = v.vendor_id
        WHERE v.vendor_status = 'suspended'
          AND i.items_active = 1
        GROUP BY v.vendor_id, v.store_name
        HAVING COUNT(i.items_id) > 0
        ORDER BY active_items_count DESC
        LIMIT 5
    ");

    while ($row = $suspendedVendorStmt->fetch(PDO::FETCH_ASSOC)) {
        $riskAlertsCount++;
        $fraud[] = [
            'alert_title' => $row['store_name'] . ' is suspended with active catalog items',
            'alert_detail' => $row['active_items_count'] . ' items are still active and need review',
            'severity_label' => 'High',
            'tint_hex' => '#B91C1C',
        ];
    }

    if (empty($fraud)) {
        $fraud[] = [
            'alert_title' => 'No high-risk patterns detected',
            'alert_detail' => 'Live scan of orders, payments, and vendor catalog returned no escalations.',
            'severity_label' => 'Info',
            'tint_hex' => '#10B981',
        ];
    }

    $disputes = [];

    $staleVendorOrdersStmt = $con->query("
        SELECT
            vo.order_id,
            v.store_name,
            vo.vendor_total,
            vo.updated_at
        FROM vendor_orders vo
        INNER JOIN vendors v ON v.vendor_id = vo.vendor_id
        WHERE vo.vendor_status = 'pending'
          AND vo.updated_at <= DATE_SUB(NOW(), INTERVAL 48 HOUR)
        ORDER BY vo.updated_at ASC
        LIMIT 10
    ");

    while ($row = $staleVendorOrdersStmt->fetch(PDO::FETCH_ASSOC)) {
        $disputes[] = [
            'order_label' => 'Order #' . $row['order_id'],
            'issue_text' => 'Pending vendor settlement for SAR ' . number_format((float)$row['vendor_total'], 0),
            'owner_label' => $row['store_name'] . ' - Last update ' . formatDateLabel($row['updated_at']),
            'state_label' => 'Escalated',
            'tint_hex' => '#F59E0B',
        ];
    }

    $failedOrdersStmt = $con->query("
        SELECT
            orders_id,
            orders_usersid,
            orders_totalprice,
            COALESCE(updated_at, orders_datetime) AS latest_time
        FROM orders
        WHERE orders_status = 'failed'
        ORDER BY latest_time DESC, orders_id DESC
        LIMIT 10
    ");

    while ($row = $failedOrdersStmt->fetch(PDO::FETCH_ASSOC)) {
        $disputes[] = [
            'order_label' => 'Order #' . $row['orders_id'],
            'issue_text' => 'Failed payment for SAR ' . number_format((float)$row['orders_totalprice'], 0),
            'owner_label' => 'Customer #' . $row['orders_usersid'] . ' - ' . formatDateLabel($row['latest_time']),
            'state_label' => 'Finance review',
            'tint_hex' => '#EF4444',
        ];
    }

    if (empty($disputes)) {
        $disputes[] = [
            'order_label' => 'No active disputes',
            'issue_text' => 'No delayed vendor orders or failed payments require escalation right now.',
            'owner_label' => 'Live operations check',
            'state_label' => 'Clear',
            'tint_hex' => '#10B981',
        ];
    }

    $broadcasts = $con->query("
        SELECT
            COALESCE(NULLIF(notification_title, ''), notification_type) AS campaign_title,
            CONCAT(COUNT(DISTINCT notification_userid), ' recipients') AS audience_label,
            'In-app notification' AS channel_label,
            CONCAT('Last send ', DATE_FORMAT(MAX(notification_created_at), '%Y-%m-%d %H:%i')) AS status_label
        FROM notifications
        GROUP BY COALESCE(NULLIF(notification_title, ''), notification_type)
        ORDER BY MAX(notification_created_at) DESC
        LIMIT 10
    ")->fetchAll(PDO::FETCH_ASSOC);

    if (empty($broadcasts)) {
        $broadcasts[] = [
            'campaign_title' => 'No notification activity yet',
            'audience_label' => '0 recipients',
            'channel_label' => 'In-app notification',
            'status_label' => 'No sends recorded',
        ];
    }

    $videoTargetBaseSql = "
        SELECT
            base_v.video_id,
            base_v.video_title,
            base_v.video_date,
            CASE
                WHEN LOWER(COALESCE(base_v.video_target_type, '')) IN ('restaurant', 'product') THEN LOWER(COALESCE(base_v.video_target_type, ''))
                WHEN base_v.video_product_id IS NOT NULL AND base_v.video_product_id > 0 THEN 'product'
                ELSE NULL
            END AS effective_target_type,
            CASE
                WHEN LOWER(COALESCE(base_v.video_target_type, '')) IN ('restaurant', 'product')
                     AND COALESCE(base_v.video_target_id, 0) > 0 THEN COALESCE(base_v.video_target_id, 0)
                WHEN base_v.video_product_id IS NOT NULL AND base_v.video_product_id > 0 THEN base_v.video_product_id
                ELSE 0
            END AS effective_target_id
        FROM videos base_v
    ";

    $moderation = $con->query("
        SELECT item_label, reason_text, state_label, tint_hex
        FROM (
            SELECT
                CONCAT('Video #', v.video_id, ' - ', v.video_title) AS item_label,
                'Video is not linked to any destination' AS reason_text,
                'Needs review' AS state_label,
                '#F59E0B' AS tint_hex,
                v.video_date AS sort_time
            FROM ($videoTargetBaseSql) v
            WHERE v.effective_target_type IS NULL

            UNION ALL

            SELECT
                CONCAT('Video #', v.video_id, ' - ', v.video_title) AS item_label,
                'Linked item is missing or inactive' AS reason_text,
                'Blocked link' AS state_label,
                '#EF4444' AS tint_hex,
                v.video_date AS sort_time
            FROM ($videoTargetBaseSql) v
            LEFT JOIN items i ON i.items_id = v.effective_target_id
            WHERE v.effective_target_type = 'product'
              AND (i.items_id IS NULL OR i.items_active = 0)

            UNION ALL

            SELECT
                CONCAT('Video #', v.video_id, ' - ', v.video_title) AS item_label,
                'Linked restaurant is missing or inactive' AS reason_text,
                'Blocked link' AS state_label,
                '#EF4444' AS tint_hex,
                v.video_date AS sort_time
            FROM ($videoTargetBaseSql) v
            LEFT JOIN vendors vd ON vd.vendor_id = v.effective_target_id
            WHERE v.effective_target_type = 'restaurant'
              AND (vd.vendor_id IS NULL OR COALESCE(vd.vendor_status, '') <> 'active')

            UNION ALL

            SELECT
                CONCAT('Ad #', a.id) AS item_label,
                'Ad entry is missing destination target' AS reason_text,
                'Needs completion' AS state_label,
                '#3B82F6' AS tint_hex,
                a.created_at AS sort_time
            FROM ads2 a
            WHERE (
                (a.target_type IS NULL OR TRIM(a.target_type) = '' OR a.target_type = 'url')
                AND (a.link_url IS NULL OR TRIM(a.link_url) = '')
            )
        ) moderation_feed
        ORDER BY sort_time DESC
        LIMIT 12
    ")->fetchAll(PDO::FETCH_ASSOC);

    if (empty($moderation)) {
        $moderation[] = [
            'item_label' => 'No moderation blockers',
            'reason_text' => 'Videos and ads currently pass the basic live integrity checks.',
            'state_label' => 'Healthy',
            'tint_hex' => '#10B981',
        ];
    }

    $returns = [];
    if (tableExists('vendor_return_requests')) {
        $returnRows = $con->query("
            SELECT
                return_id,
                order_label,
                customer_name,
                reason_text,
                status_label,
                tint_hex,
                created_at
            FROM vendor_return_requests
            ORDER BY created_at DESC, return_id DESC
            LIMIT 20
        ")->fetchAll(PDO::FETCH_ASSOC);
        foreach ($returnRows as $row) {
            $returns[] = [
                'return_id' => (int)($row['return_id'] ?? 0),
                'title' => (string)($row['order_label'] ?? ('Return #' . (int)($row['return_id'] ?? 0))),
                'subtitle' => trim((string)($row['customer_name'] ?? '') . ' - ' . (string)($row['reason_text'] ?? '')),
                'status' => (string)($row['status_label'] ?? 'Pending review'),
                'tint_hex' => (string)($row['tint_hex'] ?? '#F59E0B'),
                'created_at' => formatDateLabel($row['created_at'] ?? null),
            ];
        }
    }

    $stockRules = [];
    if (tableExists('vendor_item_stock_rules') && tableExists('items')) {
        $stockRows = $con->query("
            SELECT
                r.rule_id,
                r.item_id,
                r.minimum_stock,
                r.supplier_eta,
                r.action_label,
                r.is_active,
                i.items_name_ar,
                i.items_name_en
            FROM vendor_item_stock_rules r
            LEFT JOIN items i ON i.items_id = r.item_id
            ORDER BY r.is_active DESC, r.updated_at DESC, r.rule_id DESC
            LIMIT 20
        ")->fetchAll(PDO::FETCH_ASSOC);
        foreach ($stockRows as $row) {
            $itemName = trim((string)($row['items_name_ar'] ?? '')) !== ''
                ? (string)$row['items_name_ar']
                : (string)($row['items_name_en'] ?? ('Item #' . (int)($row['item_id'] ?? 0)));
            $stockRules[] = [
                'rule_id' => (int)($row['rule_id'] ?? 0),
                'title' => $itemName,
                'subtitle' => 'Minimum stock: ' . (int)($row['minimum_stock'] ?? 0)
                    . ' - ETA: ' . (string)($row['supplier_eta'] ?? '-'),
                'status' => ((int)($row['is_active'] ?? 0) === 1) ? 'Active rule' : 'Inactive rule',
                'tint_hex' => ((int)($row['is_active'] ?? 0) === 1) ? '#10B981' : '#64748B',
                'created_at' => (string)($row['action_label'] ?? 'Review stock'),
            ];
        }
    }

    $ordersCount = (int)$con->query("SELECT COUNT(*) FROM orders")->fetchColumn();
    $vendorsCount = (int)$con->query("SELECT COUNT(*) FROM vendors")->fetchColumn();
    $videosCount = (int)$con->query("SELECT COUNT(*) FROM videos")->fetchColumn();
    $notificationsCount = (int)$con->query("SELECT COUNT(*) FROM notifications")->fetchColumn();

    $scheduledExports = [];
    if (tableExists('vendor_scheduled_reports')) {
        $scheduledRows = $con->query("
            SELECT report_id, report_name, cadence_label, target_label, is_active, created_at
            FROM vendor_scheduled_reports
            ORDER BY is_active DESC, created_at DESC, report_id DESC
            LIMIT 20
        ")->fetchAll(PDO::FETCH_ASSOC);
        foreach ($scheduledRows as $row) {
            $scheduledExports[] = [
                'report_id' => (int)($row['report_id'] ?? 0),
                'title' => (string)($row['report_name'] ?? 'Scheduled report'),
                'subtitle' => trim((string)($row['cadence_label'] ?? '') . ' - ' . (string)($row['target_label'] ?? '')),
                'status' => ((int)($row['is_active'] ?? 0) === 1) ? 'Active' : 'Inactive',
                'tint_hex' => ((int)($row['is_active'] ?? 0) === 1) ? '#10B981' : '#64748B',
                'created_at' => formatDateLabel($row['created_at'] ?? null),
            ];
        }
    }
    if (empty($scheduledExports)) {
        $scheduledExports = [
        [
            'title' => 'Orders dataset',
            'subtitle' => $ordersCount . ' records available now - CSV / Excel',
            'status' => 'Active',
            'tint_hex' => '#10B981',
        ],
        [
            'title' => 'Vendors registry',
            'subtitle' => $vendorsCount . ' vendor records available now - CSV / Excel',
            'status' => 'Active',
            'tint_hex' => '#10B981',
        ],
        [
            'title' => 'Videos catalog',
            'subtitle' => $videosCount . ' content records available now - CSV / Excel',
            'status' => 'Active',
            'tint_hex' => '#10B981',
        ],
        [
            'title' => 'Notifications activity',
            'subtitle' => $notificationsCount . ' notification records available now - CSV / Excel',
            'status' => 'Active',
            'tint_hex' => '#10B981',
        ],
        ];
    }

    respondJson([
        'status' => 'success',
        'summary' => [
            'gmv' => $gmv,
            'aov' => $aov,
            'active_vendors_count' => $activeVendors,
            'risk_alerts_count' => $riskAlertsCount,
        ],
        'data' => [
            'roles' => $roles,
            'employees' => $employees,
            'audit_logs' => $audit,
            'sessions' => $sessions,
            'onboarding_queue' => $onboarding,
            'settlements' => $settlements,
            'fraud_alerts' => $fraud,
            'dispute_cases' => $disputes,
            'broadcasts' => $broadcasts,
            'moderation_queue' => $moderation,
            'returns' => $returns,
            'stock_rules' => $stockRules,
            'scheduled_exports' => $scheduledExports,
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
