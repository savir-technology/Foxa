<?php
require_once "../../../connect.php";
require_once "../../../asset_urls.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function financeGuessCity(string $address): string
{
    $value = trim($address);
    if ($value === '') {
        return 'غير محدد';
    }

    $parts = preg_split('/[-،,\/]+/u', $value) ?: [];
    foreach ($parts as $part) {
        $clean = trim($part);
        if ($clean !== '') {
            return $clean;
        }
    }

    return $value;
}

function financeStatusLabel($approved): string
{
    return (int)$approved === 1 ? 'نشطة' : 'مقفلة';
}

function financeEntryTypeLabel(string $type): string
{
    $key = strtolower(trim($type));
    if ($key === 'sale') {
        return 'إيراد';
    }
    if ($key === 'refund') {
        return 'استرداد';
    }
    if ($key === 'payment') {
        return 'دفعة';
    }
    if ($key === 'expense') {
        return 'مصروف';
    }
    if ($key === 'wallet_add') {
        return 'إضافة محفظة';
    }
    if ($key === 'wallet_use') {
        return 'استخدام محفظة';
    }

    return $type === '' ? 'حركة' : $type;
}

function financeEntryAccountLabel(string $typeLabel): string
{
    if ($typeLabel === 'إيراد') {
        return 'إيرادات الطلبات';
    }
    if ($typeLabel === 'استرداد') {
        return 'الاستردادات';
    }
    if ($typeLabel === 'إضافة محفظة' || $typeLabel === 'استخدام محفظة') {
        return 'محفظة العميل';
    }
    if ($typeLabel === 'دفعة') {
        return 'عمليات الدفع';
    }

    return 'المصروفات';
}

function financeNullableNumber($value): ?float
{
    if ($value === null || (is_string($value) && trim($value) === '')) {
        return null;
    }

    return is_numeric($value) ? (float)$value : null;
}

function financeRefundableStatusExpression(): string
{
    if (columnExists('orders', 'status')) {
        return "LOWER(COALESCE(o.status, o.orders_status, ''))";
    }

    return "LOWER(COALESCE(o.orders_status, ''))";
}

function financeRefundPaymentExpression(string $column): string
{
    return columnExists('orders', $column) ? "COALESCE(o.{$column}, '')" : "''";
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'finance.view');
    $master = masterPublicData($admin);

    $financeQualityFailures = [];

    if (!tableExists('users')) {
        $financeQualityFailures[] = 'users_schema';
    }
    if (!tableExists('vendors') || !tableExists('vendor_orders')) {
        $financeQualityFailures[] = 'vendor_commissions_schema';
    }
    if (!tableExists('delivery_zones') && !(tableExists('vendors') && tableExists('vendor_store_settings'))) {
        $financeQualityFailures[] = 'delivery_fees_schema';
    }
    if (!tableExists('coupon')) {
        $financeQualityFailures[] = 'coupon_schema';
    }
    if (!tableExists('accounting_entries')) {
        $financeQualityFailures[] = 'accounting_schema';
    }
    if (!tableExists('wallet_refund_logs')) {
        $financeQualityFailures[] = 'refund_logs_schema';
    }

    $wallets = [];
    if (tableExists('users')) {
        $walletAvailable = tableExists('wallet');
        $ordersAvailable = tableExists('orders');
        $refundsAvailable = tableExists('wallet_refund_logs');
        $walletSelect = $walletAvailable
            ? "COALESCE(w.balance, 0) AS wallet_balance,
                COALESCE(w.points, 0) AS wallet_points"
            : "0 AS wallet_balance,
                0 AS wallet_points";
        $refundsSelect = $refundsAvailable
            ? "COALESCE(r.refund_points, 0) AS refund_points,
                COALESCE(r.refund_amount, 0) AS refund_amount,
                r.last_refund_at"
            : "0 AS refund_points,
                0 AS refund_amount,
                NULL AS last_refund_at";
        $ordersSelect = $ordersAvailable
            ? "COALESCE(MAX(o.orders_datetime), u.users_creat) AS last_activity,
                COUNT(o.orders_id) AS orders_count,
                COALESCE(SUM(
                    CASE
                        WHEN COALESCE(o.orders_status, o.status, '') IN ('paid', 'completed', 'delivered', '4')
                        THEN COALESCE(o.orders_totalprice, 0)
                        ELSE 0
                    END
                ), 0) AS total_spend"
            : "u.users_creat AS last_activity,
                0 AS orders_count,
                0 AS total_spend";
        $walletJoin = $walletAvailable ? "LEFT JOIN wallet w ON w.user_id = u.users_id" : "";
        $ordersJoin = $ordersAvailable ? "LEFT JOIN orders o ON o.orders_usersid = u.users_id" : "";
        $refundsJoin = $refundsAvailable
            ? "LEFT JOIN (
                SELECT
                    user_id,
                    COALESCE(SUM(points), 0) AS refund_points,
                    COALESCE(SUM(amount), 0) AS refund_amount,
                    MAX(created_at) AS last_refund_at
                FROM wallet_refund_logs
                GROUP BY user_id
            ) r ON r.user_id = u.users_id"
            : "";
        $walletGroup = $walletAvailable ? ", w.balance, w.points" : "";
        $refundsGroup = $refundsAvailable ? ", r.refund_points, r.refund_amount, r.last_refund_at" : "";
        $walletSql = "
            SELECT
                u.users_id,
                u.users_name,
                u.users_phone,
                u.users_email,
                u.users_approve,
                u.users_image,
                u.users_creat,
                {$walletSelect},
                {$refundsSelect},
                {$ordersSelect}
            FROM users u
            {$walletJoin}
            {$ordersJoin}
            {$refundsJoin}
            GROUP BY
                u.users_id,
                u.users_name,
                u.users_phone,
                u.users_email,
                u.users_approve,
                u.users_image,
                u.users_creat
                {$walletGroup}
                {$refundsGroup}
            ORDER BY wallet_balance DESC, u.users_id DESC
            LIMIT 250
        ";
        $walletStmt = $con->query($walletSql);
        while ($row = $walletStmt->fetch(PDO::FETCH_ASSOC)) {
            $wallets[] = [
                'wallet_id' => 'WAL-' . (int)($row['users_id'] ?? 0),
                'user_id' => (int)($row['users_id'] ?? 0),
                'user_name' => (string)($row['users_name'] ?? ''),
                'phone' => (string)($row['users_phone'] ?? ''),
                'email' => (string)($row['users_email'] ?? ''),
                'status' => financeStatusLabel($row['users_approve'] ?? 0),
                'avatar_url' => zahra_user_image_url($row['users_image'] ?? ''),
                'wallet_balance' => (float)($row['wallet_balance'] ?? 0),
                'wallet_points' => (int)($row['wallet_points'] ?? 0),
                'refund_points' => (int)($row['refund_points'] ?? 0),
                'refund_amount' => (float)($row['refund_amount'] ?? 0),
                'orders_count' => (int)($row['orders_count'] ?? 0),
                'total_spend' => (float)($row['total_spend'] ?? 0),
                'last_activity' => $row['last_refund_at'] ?? $row['last_activity'] ?? $row['users_creat'] ?? null,
                'created_at' => $row['users_creat'] ?? null,
            ];
        }
    }

    $commissions = [];
    if (tableExists('vendors') && tableExists('vendor_orders')) {
        $commissionStmt = $con->query("
            SELECT
                v.vendor_id,
                COALESCE(NULLIF(v.store_name, ''), v.vendor_name, CONCAT('Restaurant #', v.vendor_id)) AS vendor_name,
                COUNT(vo.order_id) AS orders_count,
                COALESCE(SUM(vo.vendor_total), 0) AS gross_amount,
                COALESCE(SUM(CASE WHEN vo.vendor_status = 'pending' THEN vo.vendor_total ELSE 0 END), 0) AS pending_amount,
                COALESCE(SUM(CASE WHEN vo.vendor_status = 'paid' THEN vo.vendor_total ELSE 0 END), 0) AS paid_amount,
                MAX(vo.updated_at) AS last_activity
            FROM vendors v
            LEFT JOIN vendor_orders vo ON vo.vendor_id = v.vendor_id
            GROUP BY v.vendor_id, vendor_name
            ORDER BY gross_amount DESC, v.vendor_id DESC
            LIMIT 80
        ");
        while ($row = $commissionStmt->fetch(PDO::FETCH_ASSOC)) {
            $grossAmount = (float)($row['gross_amount'] ?? 0);
            $pendingAmount = (float)($row['pending_amount'] ?? 0);
            $paidAmount = (float)($row['paid_amount'] ?? 0);
            $ratio = $grossAmount > 0 ? round(($pendingAmount / $grossAmount) * 100, 2) : 0;
            $commissions[] = [
                'vendor_id' => (int)($row['vendor_id'] ?? 0),
                'rule_name' => 'عمولة ' . (string)$row['vendor_name'],
                'description' => 'مستخرجة من إجمالي مبيعات المطعم',
                'type_label' => 'نسبة مئوية',
                'value_label' => rtrim(rtrim(number_format($ratio, 2, '.', ''), '0'), '.') . '%',
                'applies_to' => (string)$row['vendor_name'],
                'source' => 'مطعم',
                'status' => $paidAmount > 0 || $pendingAmount > 0 ? 'نشطة' : 'غير نشطة',
                'priority' => 1,
                'created_at' => $row['last_activity'] ?? null,
                'updated_at' => $row['last_activity'] ?? null,
                'gross_amount' => $grossAmount,
                'pending_amount' => $pendingAmount,
                'paid_amount' => $paidAmount,
                'orders_count' => (int)($row['orders_count'] ?? 0),
            ];
        }
    }

    $fees = [];
    if (tableExists('delivery_zones')) {
        $feesStmt = $con->query("
            SELECT
                zone_id,
                zone_name,
                city,
                coverage_km,
                delivery_fee,
                minimum_order,
                estimated_min_minutes,
                estimated_max_minutes,
                is_active
            FROM delivery_zones
            ORDER BY is_active DESC, zone_name ASC, zone_id DESC
            LIMIT 120
        ");
        while ($row = $feesStmt->fetch(PDO::FETCH_ASSOC)) {
            $deliveryFee = financeNullableNumber($row['delivery_fee'] ?? null);
            $minimumOrder = financeNullableNumber($row['minimum_order'] ?? null);
            $fees[] = [
                'zone_id' => (int)($row['zone_id'] ?? 0),
                'zone_name' => (string)($row['zone_name'] ?? ''),
                'city' => trim((string)($row['city'] ?? '')) ?: 'غير محدد',
                'fixed_fee' => $deliveryFee,
                'extra_km_fee' => null,
                'service_fee' => null,
                'minimum_order' => $minimumOrder,
                'delivery_methods' => null,
                'status' => (int)($row['is_active'] ?? 0) === 1 ? 'نشطة' : 'غير نشطة',
                'revenue_label' => '',
                'eta_min' => financeNullableNumber($row['estimated_min_minutes'] ?? null),
                'eta_max' => financeNullableNumber($row['estimated_max_minutes'] ?? null),
                'branches_count' => 0,
            ];
        }
    } elseif (tableExists('vendors') && tableExists('vendor_store_settings')) {
        $branchesAvailable = tableExists('restaurant_branches')
            && columnExists('restaurant_branches', 'branch_id')
            && columnExists('restaurant_branches', 'vendor_id')
            && columnExists('restaurant_branches', 'delivery_fee')
            && columnExists('restaurant_branches', 'estimated_min_minutes')
            && columnExists('restaurant_branches', 'estimated_max_minutes')
            && columnExists('restaurant_branches', 'is_active');
        $settingsDeliveryFeeSelect = columnExists('vendor_store_settings', 'delivery_fee')
            ? "MAX(vs.delivery_fee)"
            : "NULL";
        $settingsEtaMinSelect = columnExists('vendor_store_settings', 'estimated_min_minutes')
            ? "MAX(vs.estimated_min_minutes)"
            : "NULL";
        $settingsEtaMaxSelect = columnExists('vendor_store_settings', 'estimated_max_minutes')
            ? "MAX(vs.estimated_max_minutes)"
            : "NULL";
        $settingsMinimumOrderSelect = columnExists('vendor_store_settings', 'minimum_order')
            ? "MAX(vs.minimum_order)"
            : "NULL";
        $settingsServiceFeeSelect = columnExists('vendor_store_settings', 'service_fee')
            ? "MAX(vs.service_fee)"
            : "NULL";
        $settingsIsOpenSelect = columnExists('vendor_store_settings', 'is_open')
            ? "MAX(vs.is_open)"
            : "NULL";
        $branchSelect = $branchesAvailable
            ? "CASE WHEN COUNT(rb.branch_id) > 0 THEN MIN(rb.delivery_fee) ELSE {$settingsDeliveryFeeSelect} END AS delivery_fee,
                CASE WHEN COUNT(rb.branch_id) > 0 THEN MIN(rb.estimated_min_minutes) ELSE {$settingsEtaMinSelect} END AS eta_min,
                CASE WHEN COUNT(rb.branch_id) > 0 THEN MAX(rb.estimated_max_minutes) ELSE {$settingsEtaMaxSelect} END AS eta_max,
                COUNT(rb.vendor_id) AS branches_count"
            : "{$settingsDeliveryFeeSelect} AS delivery_fee,
                {$settingsEtaMinSelect} AS eta_min,
                {$settingsEtaMaxSelect} AS eta_max,
                0 AS branches_count";
        $branchJoin = $branchesAvailable
            ? "LEFT JOIN restaurant_branches rb ON rb.vendor_id = v.vendor_id AND rb.is_active = 1"
            : "";
        $feesSql = "
            SELECT
                v.vendor_id,
                COALESCE(NULLIF(vs.coverage_area, ''), NULLIF(v.store_name, ''), NULLIF(v.vendor_name, '')) AS zone_name,
                COALESCE(vs.store_address, '') AS store_address,
                vs.coverage_km AS coverage_km,
                {$branchSelect},
                {$settingsMinimumOrderSelect} AS minimum_order,
                {$settingsServiceFeeSelect} AS service_fee,
                NULL AS delivery_methods,
                {$settingsIsOpenSelect} AS is_open
            FROM vendors v
            LEFT JOIN vendor_store_settings vs ON vs.vendor_id = v.vendor_id
            {$branchJoin}
            GROUP BY
                v.vendor_id,
                vs.coverage_area,
                v.store_name,
                v.vendor_name,
                vs.store_address,
                vs.coverage_km
            ORDER BY delivery_fee DESC, v.vendor_id DESC
            LIMIT 120
        ";
        $feesStmt = $con->query($feesSql);
        while ($row = $feesStmt->fetch(PDO::FETCH_ASSOC)) {
            $deliveryFee = financeNullableNumber($row['delivery_fee'] ?? null);
            $minimumOrder = financeNullableNumber($row['minimum_order'] ?? null);
            $serviceFee = financeNullableNumber($row['service_fee'] ?? null);
            $fees[] = [
                'vendor_id' => (int)($row['vendor_id'] ?? 0),
                'zone_name' => (string)($row['zone_name'] ?? ''),
                'city' => financeGuessCity((string)($row['store_address'] ?? '')),
                'fixed_fee' => $deliveryFee,
                'extra_km_fee' => null,
                'service_fee' => $serviceFee,
                'minimum_order' => $minimumOrder,
                'delivery_methods' => null,
                'status' => $row['is_open'] === null
                    ? 'غير محدد'
                    : ((int)$row['is_open'] === 1 ? 'نشطة' : 'غير نشطة'),
                'revenue_label' => (string)$row['store_address'],
                'eta_min' => financeNullableNumber($row['eta_min'] ?? null),
                'eta_max' => financeNullableNumber($row['eta_max'] ?? null),
                'branches_count' => (int)($row['branches_count'] ?? 0),
            ];
        }
    }

    $coupons = [];
    if (tableExists('coupon')) {
        $couponStmt = $con->query("
            SELECT
                coupon_id,
                coupon_name,
                coupon_count,
                coupon_expiredate,
                coupon_discount
            FROM coupon
            ORDER BY coupon_expiredate DESC, coupon_id DESC
            LIMIT 200
        ");
        while ($row = $couponStmt->fetch(PDO::FETCH_ASSOC)) {
            $couponCount = (int)($row['coupon_count'] ?? 0);
            $expireDate = (string)($row['coupon_expiredate'] ?? '');
            $isExpired = $expireDate !== '' && strtotime($expireDate) !== false && strtotime($expireDate) < time();
            $coupons[] = [
                'coupon_id' => (int)($row['coupon_id'] ?? 0),
                'code' => (string)($row['coupon_name'] ?? ''),
                'restaurant' => 'المنصة',
                'type_label' => 'نسبة مئوية',
                'value_label' => (int)($row['coupon_discount'] ?? 0) . '%',
                'min_order' => '0 ر.س',
                'usage_label' => $couponCount . ' متاح',
                'status' => $isExpired ? 'منتهي' : ($couponCount > 0 ? 'نشط' : 'مستهلك'),
                'end_date' => $expireDate,
                'image_url' => '',
                'discount_value' => (int)($row['coupon_discount'] ?? 0),
                'remaining_count' => $couponCount,
            ];
        }
    }

    $discounts = [];
    foreach ($coupons as $coupon) {
        $discounts[] = [
            'coupon_id' => (int)($coupon['coupon_id'] ?? 0),
            'name' => 'خصم ' . ($coupon['code'] ?: ('#' . $coupon['coupon_id'])),
            'code' => $coupon['code'],
            'source' => 'ترويجي',
            'type_label' => $coupon['type_label'],
            'value_label' => $coupon['value_label'],
            'max_value_label' => 'غير محدد',
            'usage_label' => $coupon['usage_label'],
            'status' => $coupon['status'],
            'end_date' => $coupon['end_date'],
        ];
    }

    $records = [];
    if (tableExists('accounting_entries')) {
        $ordersAvailable = tableExists('orders');
        $usersAvailable = tableExists('users');
        $orderItemsAvailable = $ordersAvailable && tableExists('order_items');
        $vendorsAvailable = $orderItemsAvailable && tableExists('vendors');
        $orderFields = $ordersAvailable
            ? "o.orders_id,
                o.orders_usersid,
                o.orders_totalprice,
                o.orders_pricedelivery,
                o.orders_coupon"
            : "0 AS orders_id,
                0 AS orders_usersid,
                0 AS orders_totalprice,
                0 AS orders_pricedelivery,
                0 AS orders_coupon";
        $ordersJoin = $ordersAvailable
            ? "LEFT JOIN orders o
                ON ae.reference_table = 'orders'
               AND o.orders_id = ae.reference_id"
            : "";
        $usersJoin = ($ordersAvailable && $usersAvailable)
            ? "LEFT JOIN users u ON u.users_id = o.orders_usersid"
            : "";
        $orderItemsJoin = $orderItemsAvailable
            ? "
            LEFT JOIN (
                SELECT order_id, MIN(vendor_id) AS vendor_id
                FROM order_items
                GROUP BY order_id
            ) oi_map ON oi_map.order_id = o.orders_id
            "
            : "";
        $vendorJoin = $vendorsAvailable
            ? "LEFT JOIN vendors v ON v.vendor_id = oi_map.vendor_id"
            : "";
        $recordsSql = "
            SELECT
                ae.entry_id,
                ae.entry_date,
                ae.entry_type,
                ae.debit,
                ae.credit,
                ae.description,
                ae.reference_table,
                ae.reference_id,
                {$orderFields},
                " . ($ordersAvailable && $usersAvailable ? "u.users_name" : "''") . " AS users_name,
                " . ($vendorsAvailable
                    ? "COALESCE(NULLIF(v.store_name, ''), v.vendor_name, '')"
                    : "''") . " AS vendor_name
            FROM accounting_entries ae
            {$ordersJoin}
            {$usersJoin}
            {$orderItemsJoin}
            {$vendorJoin}
            ORDER BY ae.entry_date DESC, ae.entry_id DESC
            LIMIT 250
        ";
        $recordsStmt = $con->query($recordsSql);
        $runningBalance = 0.0;
        while ($row = $recordsStmt->fetch(PDO::FETCH_ASSOC)) {
            $credit = (float)($row['credit'] ?? 0);
            $debit = (float)($row['debit'] ?? 0);
            $amount = $credit > 0 ? $credit : $debit;
            $entryType = (string)($row['entry_type'] ?? '');
            $typeLabel = financeEntryTypeLabel($entryType);
            $runningBalance += $credit - $debit;
            $records[] = [
                'reference' => 'TRX-' . date('Y', strtotime((string)($row['entry_date'] ?? 'now'))) . '-' . str_pad((string)($row['entry_id'] ?? 0), 7, '0', STR_PAD_LEFT),
                'datetime' => $row['entry_date'] ?? null,
                'description' => (string)($row['description'] ?? ''),
                'account' => financeEntryAccountLabel($typeLabel),
                'type_label' => $typeLabel,
                'amount' => $credit > 0 ? $credit : -$amount,
                'status' => 'مكتملة',
                'balance_after' => $runningBalance,
                'payment_method' => $typeLabel === 'إيراد' ? 'بطاقة / تحويل' : ($typeLabel === 'استرداد' ? 'نقاط المحفظة' : 'حساب داخلي'),
                'order_id' => (int)($row['orders_id'] ?? 0),
                'customer_name' => (string)($row['users_name'] ?? ''),
                'vendor_name' => (string)($row['vendor_name'] ?? ''),
            ];
        }
    }

    if (tableExists('wallet_refund_logs')) {
        $usersJoin = tableExists('users') ? "LEFT JOIN users u ON u.users_id = wr.user_id" : "";
        $customerSelect = tableExists('users') ? "COALESCE(u.users_name, '')" : "''";
        $accountingExclusion = tableExists('accounting_entries')
            ? "AND NOT EXISTS (
                SELECT 1
                FROM accounting_entries ae
                WHERE ae.entry_type = 'refund'
                  AND ae.reference_table = 'orders'
                  AND ae.reference_id = wr.order_id
                LIMIT 1
            )"
            : "";
        $refundLogsStmt = $con->query("
            SELECT
                wr.id,
                wr.order_id,
                wr.user_id,
                wr.points,
                wr.amount,
                wr.note,
                wr.created_at,
                {$customerSelect} AS users_name
            FROM wallet_refund_logs wr
            {$usersJoin}
            WHERE 1 = 1
            {$accountingExclusion}
            ORDER BY wr.created_at DESC, wr.id DESC
            LIMIT 250
        ");
        while ($row = $refundLogsStmt->fetch(PDO::FETCH_ASSOC)) {
            $amount = (float)($row['amount'] ?? 0);
            $points = (int)($row['points'] ?? 0);
            $createdAt = (string)($row['created_at'] ?? 'now');
            $orderId = (int)($row['order_id'] ?? 0);
            $records[] = [
                'reference' => 'RFD-' . date('Y', strtotime($createdAt ?: 'now')) . '-' . str_pad((string)($row['id'] ?? 0), 7, '0', STR_PAD_LEFT),
                'datetime' => $row['created_at'] ?? null,
                'description' => 'Refunded order #' . $orderId . ' to wallet as ' . $points . ' points',
                'account' => 'الاستردادات',
                'type_label' => 'استرداد',
                'amount' => -$amount,
                'status' => 'مكتملة',
                'balance_after' => $amount,
                'payment_method' => 'نقاط المحفظة',
                'order_id' => $orderId,
                'customer_name' => (string)($row['users_name'] ?? ''),
                'vendor_name' => '',
            ];
        }
    }

    usort($records, static function ($a, $b) {
        return strtotime((string)($b['datetime'] ?? '')) <=> strtotime((string)($a['datetime'] ?? ''));
    });
    $records = array_slice($records, 0, 250);

    $refundCandidates = [];
    if (tableExists('orders')) {
        $usersAvailable = tableExists('users');
        $refundLogsAvailable = tableExists('wallet_refund_logs');
        $statusExpr = financeRefundableStatusExpression();
        $paymentExpr = financeRefundPaymentExpression('payment_method');
        $transactionExpr = financeRefundPaymentExpression('transaction_id');
        $gatewayExpr = financeRefundPaymentExpression('orders_gateway_ref');
        $paidAmountExpr = columnExists('orders', 'paid_amount') ? "COALESCE(o.paid_amount, 0)" : "0";
        $paymentNumberExpr = columnExists('orders', 'orders_paymentmethod') ? "COALESCE(o.orders_paymentmethod, 0)" : "0";
        $usersJoin = $usersAvailable ? "LEFT JOIN users u ON u.users_id = o.orders_usersid" : "";
        $customerNameSelect = $usersAvailable
            ? "COALESCE(u.users_name, o.orders_recipient_name, 'عميل')"
            : "COALESCE(o.orders_recipient_name, 'عميل')";
        $customerPhoneSelect = $usersAvailable
            ? "COALESCE(u.users_phone, o.orders_recipient_phone, '')"
            : "COALESCE(o.orders_recipient_phone, '')";
        $refundJoin = $refundLogsAvailable ? "LEFT JOIN wallet_refund_logs wr ON wr.order_id = o.orders_id" : "";
        $refundSelect = $refundLogsAvailable
            ? "wr.id AS refund_log_id,
                wr.points AS refunded_points,
                wr.amount AS refunded_amount,
                wr.note AS refund_note,
                wr.created_at AS refunded_at"
            : "NULL AS refund_log_id,
                0 AS refunded_points,
                0 AS refunded_amount,
                NULL AS refund_note,
                NULL AS refunded_at";
        $onlineWhere = "(
            LOWER({$paymentExpr}) LIKE '%visa%'
            OR LOWER({$paymentExpr}) LIKE '%card%'
            OR LOWER({$paymentExpr}) LIKE '%credit%'
            OR LOWER({$paymentExpr}) LIKE '%debit%'
            OR LOWER({$paymentExpr}) LIKE '%online%'
            OR LOWER({$paymentExpr}) LIKE '%paypal%'
            OR LOWER({$paymentExpr}) LIKE '%paymob%'
            OR LOWER({$paymentExpr}) LIKE '%master%'
            OR LOWER({$paymentExpr}) LIKE '%meeza%'
            OR {$transactionExpr} <> ''
            OR {$gatewayExpr} <> ''
            OR {$paymentNumberExpr} = 1
        )";
        $refundRows = $con->query("
            SELECT
                o.orders_id,
                o.orders_usersid,
                o.orders_datetime,
                o.orders_totalprice,
                {$paidAmountExpr} AS paid_amount,
                {$paymentExpr} AS payment_method,
                {$paymentNumberExpr} AS orders_paymentmethod,
                {$transactionExpr} AS transaction_id,
                {$gatewayExpr} AS orders_gateway_ref,
                {$statusExpr} AS status_key,
                {$customerNameSelect} AS customer_name,
                {$customerPhoneSelect} AS customer_phone,
                {$refundSelect}
            FROM orders o
            {$usersJoin}
            {$refundJoin}
            WHERE {$statusExpr} IN ('canceled','cancelled','failed','rejected','returned','refunded','return','refund','-1','5')
              AND {$onlineWhere}
            ORDER BY
                CASE WHEN " . ($refundLogsAvailable ? "wr.id IS NULL" : "1") . " THEN 0 ELSE 1 END,
                o.orders_datetime DESC,
                o.orders_id DESC
            LIMIT 250
        ");
        while ($row = $refundRows->fetch(PDO::FETCH_ASSOC)) {
            $paidAmount = (float)($row['paid_amount'] ?? 0);
            $orderTotal = (float)($row['orders_totalprice'] ?? 0);
            $refundAmount = $paidAmount > 0 ? $paidAmount : $orderTotal;
            $alreadyRefunded = !empty($row['refund_log_id']);
            $refundCandidates[] = [
                'order_id' => (int)($row['orders_id'] ?? 0),
                'user_id' => (int)($row['orders_usersid'] ?? 0),
                'customer_name' => (string)($row['customer_name'] ?? ''),
                'customer_phone' => (string)($row['customer_phone'] ?? ''),
                'order_datetime' => $row['orders_datetime'] ?? null,
                'status' => (string)($row['status_key'] ?? ''),
                'payment_method' => (string)($row['payment_method'] ?? ''),
                'payment_reference' => (string)($row['transaction_id'] ?? $row['orders_gateway_ref'] ?? ''),
                'order_total' => $orderTotal,
                'paid_amount' => $paidAmount,
                'refund_amount' => $alreadyRefunded ? (float)($row['refunded_amount'] ?? $refundAmount) : $refundAmount,
                'refund_points' => $alreadyRefunded ? (int)($row['refunded_points'] ?? round($refundAmount)) : (int)round($refundAmount),
                'refund_status' => $alreadyRefunded ? 'refunded' : 'pending',
                'refunded_at' => $row['refunded_at'] ?? null,
                'refund_note' => (string)($row['refund_note'] ?? ''),
            ];
        }
    }

    $accountingAccounts = [];
    if (tableExists('accounting_accounts')) {
        $accountingStmt = $con->query("SELECT account_id, account_name, account_type, created_at FROM accounting_accounts ORDER BY account_type, account_name");
        $accountingAccounts = $accountingStmt ? ($accountingStmt->fetchAll(PDO::FETCH_ASSOC) ?: []) : [];
    }
    $wasteRecords = [];
    if (tableExists('inventory_waste')) {
        $wasteStmt = $con->query("SELECT waste_id, item_id, vendor_id, variant_id, quantity, cost_per_unit, total_cost, reason, notes, waste_date, created_at FROM inventory_waste ORDER BY waste_date DESC, waste_id DESC LIMIT 250");
        $wasteRecords = $wasteStmt ? ($wasteStmt->fetchAll(PDO::FETCH_ASSOC) ?: []) : [];
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'server_now' => date('c'),
            'wallets' => $wallets,
            'commissions' => $commissions,
            'fees' => $fees,
            'coupons' => $coupons,
            'discounts' => $discounts,
            'records' => $records,
            'refund_candidates' => $refundCandidates,
            'accounting_accounts' => $accountingAccounts,
            'waste_records' => $wasteRecords,
            'data_quality' => empty($financeQualityFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($financeQualityFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
