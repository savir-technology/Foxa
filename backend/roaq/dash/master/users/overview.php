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

$masterUsersQueryFailures = [];

function masterUsersMarkQueryFailure(string $component, Throwable $error): void
{
    global $masterUsersQueryFailures;
    $masterUsersQueryFailures[] = $component;
    error_log('master users ' . $component . ' failed: ' . $error->getMessage());
}

function masterUsersRows(string $sql, array $params = []): array
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {
        masterUsersMarkQueryFailure('rows_query', $e);
        return [];
    }
}

function masterUsersScalar(string $sql, array $params = [], $fallback = 0)
{
    global $con;
    try {
        $stmt = $con->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();
        return $value === false || $value === null ? $fallback : $value;
    } catch (Throwable $e) {
        masterUsersMarkQueryFailure('scalar_query', $e);
        return $fallback;
    }
}

function masterUsersNumber($value): string
{
    return number_format((float)$value, 0, '.', ',');
}

function masterUsersDate(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '-' : date('Y-m-d', $timestamp);
}

function masterUsersTime(?string $value): string
{
    $timestamp = strtotime((string)$value);
    return $timestamp === false ? '-' : date('H:i', $timestamp);
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'customers.view');
    $master = masterPublicData($admin);

    if (!tableExists('users')) {
        respondJson([
            'status' => 'success',
            'master' => $master,
            'data' => [
                'users' => [],
                'addresses' => [],
                'recipients' => [],
                'favorites' => [],
                'orders' => [],
                'notes' => [],
                'data_quality' => [
                    'state' => 'degraded',
                    'failed_components' => ['users_schema'],
                ],
            ],
        ]);
    }

    $ordersAvailable = tableExists('orders');
    $addressAvailable = tableExists('address');
    $favoriteAvailable = tableExists('favorite');
    $walletAvailable = tableExists('wallet')
        && columnExists('wallet', 'user_id')
        && columnExists('wallet', 'balance');
    $walletRefundsAvailable = tableExists('wallet_refund_logs');
    $cartAvailable = tableExists('cart')
        && columnExists('cart', 'cart_usersid')
        && columnExists('cart', 'cart_orders');
    $userCouponsAvailable = tableExists('user_coupons')
        && columnExists('user_coupons', 'user_id');
    $spinsAvailable = tableExists('user_spins')
        && columnExists('user_spins', 'user_id');
    $referralsAvailable = tableExists('referrals')
        && columnExists('referrals', 'referred_by');
    $orderUserSelect = $ordersAvailable
        ? "COALESCE(o.orders_count, 0) AS orders_count, COALESCE(o.total_spend, 0) AS total_spend, o.last_order_at"
        : "0 AS orders_count, 0 AS total_spend, NULL AS last_order_at";
    $addressUserSelect = $addressAvailable
        ? "COALESCE(a.saved_addresses_count, 0) AS saved_addresses_count"
        : "0 AS saved_addresses_count";
    $favoriteUserSelect = $favoriteAvailable
        ? "COALESCE(f.favorites_count, 0) AS favorites_count"
        : "0 AS favorites_count";
    $walletUserSelect = $walletAvailable
        ? "COALESCE(w.wallet_balance, 0) AS wallet_balance,
            COALESCE(w.wallet_points, 0) AS wallet_points,
            COALESCE(w.wallet_count, 0) AS wallet_count"
        : "0 AS wallet_balance,
            0 AS wallet_points,
            0 AS wallet_count";
    $refundUserSelect = $walletRefundsAvailable
        ? "COALESCE(wr.refund_points, 0) AS refund_points,
            COALESCE(wr.refund_amount, 0) AS refund_amount,
            wr.last_refund_at"
        : "0 AS refund_points,
            0 AS refund_amount,
            NULL AS last_refund_at";
    $cartUserSelect = $cartAvailable
        ? "COALESCE(c.cart_items_count, 0) AS cart_items_count"
        : "0 AS cart_items_count";
    $couponUserSelect = $userCouponsAvailable
        ? "COALESCE(uc.user_coupons_count, 0) AS user_coupons_count"
        : "0 AS user_coupons_count";
    $spinUserSelect = $spinsAvailable
        ? "COALESCE(us.spins_count, 0) AS spins_count"
        : "0 AS spins_count";
    $referralUserSelect = $referralsAvailable
        ? "COALESCE(r.referrals_count, 0) AS referrals_count"
        : "0 AS referrals_count";
    $userOrderBy = $ordersAvailable
        ? "COALESCE(o.last_order_at, u.users_id) DESC"
        : "u.users_id DESC";

    $userRows = masterUsersRows("
        SELECT
            u.users_id,
            u.users_name,
            u.users_phone,
            u.users_email,
            u.users_approve,
            u.users_image,
            {$orderUserSelect},
            {$addressUserSelect},
            {$favoriteUserSelect},
            {$walletUserSelect},
            {$refundUserSelect},
            {$cartUserSelect},
            {$couponUserSelect},
            {$spinUserSelect},
            {$referralUserSelect}
        FROM users u
        " . ($ordersAvailable ? "
            LEFT JOIN (
                SELECT
                    orders_usersid AS user_id,
                    COUNT(*) AS orders_count,
                    COALESCE(SUM(orders_totalprice), 0) AS total_spend,
                    MAX(orders_datetime) AS last_order_at
                FROM orders
                GROUP BY orders_usersid
            ) o ON o.user_id = u.users_id
        " : "") . "
        " . ($addressAvailable ? "
            LEFT JOIN (
                SELECT address_usersid AS user_id, COUNT(*) AS saved_addresses_count
                FROM address
                GROUP BY address_usersid
            ) a ON a.user_id = u.users_id
        " : "") . "
        " . ($favoriteAvailable ? "
            LEFT JOIN (
                SELECT favorite_usersid AS user_id, COUNT(*) AS favorites_count
                FROM favorite
                GROUP BY favorite_usersid
            ) f ON f.user_id = u.users_id
        " : "") . "
        " . ($walletAvailable ? "
            LEFT JOIN (
                SELECT
                    user_id,
                    COALESCE(SUM(balance), 0) AS wallet_balance,
                    COALESCE(SUM(points), 0) AS wallet_points,
                    COUNT(*) AS wallet_count
                FROM wallet
                GROUP BY user_id
            ) w ON w.user_id = u.users_id
        " : "") . "
        " . ($walletRefundsAvailable ? "
            LEFT JOIN (
                SELECT
                    user_id,
                    COALESCE(SUM(points), 0) AS refund_points,
                    COALESCE(SUM(amount), 0) AS refund_amount,
                    MAX(created_at) AS last_refund_at
                FROM wallet_refund_logs
                GROUP BY user_id
            ) wr ON wr.user_id = u.users_id
        " : "") . "
        " . ($cartAvailable ? "
            LEFT JOIN (
                SELECT cart_usersid AS user_id, COUNT(*) AS cart_items_count
                FROM cart
                WHERE cart_orders = 0
                GROUP BY cart_usersid
            ) c ON c.user_id = u.users_id
        " : "") . "
        " . ($userCouponsAvailable ? "
            LEFT JOIN (
                SELECT user_id, COUNT(*) AS user_coupons_count
                FROM user_coupons
                GROUP BY user_id
            ) uc ON uc.user_id = u.users_id
        " : "") . "
        " . ($spinsAvailable ? "
            LEFT JOIN (
                SELECT user_id, COUNT(*) AS spins_count
                FROM user_spins
                GROUP BY user_id
            ) us ON us.user_id = u.users_id
        " : "") . "
        " . ($referralsAvailable ? "
            LEFT JOIN (
                SELECT referred_by AS user_id, COUNT(*) AS referrals_count
                FROM referrals
                GROUP BY referred_by
            ) r ON r.user_id = u.users_id
        " : "") . "
        ORDER BY {$userOrderBy}
        LIMIT 260
    ");

    $users = [];
    foreach ($userRows as $row) {
        $spend = (float)($row['total_spend'] ?? 0);
        $users[] = [
            'users_id' => (int)($row['users_id'] ?? 0),
            'users_name' => (string)($row['users_name'] ?? ''),
            'users_phone' => (string)($row['users_phone'] ?? ''),
            'users_email' => (string)($row['users_email'] ?? ''),
            'users_approve' => (int)($row['users_approve'] ?? 0),
            'users_image' => (string)($row['users_image'] ?? ''),
            'country' => '',
            'city' => '',
            'orders_count' => (int)($row['orders_count'] ?? 0),
            'total_spend' => masterUsersNumber($spend),
            'wallet_balance' => masterUsersNumber($row['wallet_balance'] ?? 0),
            'wallet_exists' => ((int)($row['wallet_count'] ?? 0)) > 0,
            'wallet_points' => (int)($row['wallet_points'] ?? 0),
            'refund_points' => (int)($row['refund_points'] ?? 0),
            'refund_amount' => masterUsersNumber($row['refund_amount'] ?? 0),
            'last_refund_date' => masterUsersDate($row['last_refund_at'] ?? null),
            'last_refund_time' => masterUsersTime($row['last_refund_at'] ?? null),
            'last_order_date' => masterUsersDate($row['last_order_at'] ?? null),
            'last_order_time' => masterUsersTime($row['last_order_at'] ?? null),
            'favorites_count' => (int)($row['favorites_count'] ?? 0),
            'saved_addresses_count' => (int)($row['saved_addresses_count'] ?? 0),
            'cart_items_count' => (int)($row['cart_items_count'] ?? 0),
            'user_coupons_count' => (int)($row['user_coupons_count'] ?? 0),
            'spins_count' => (int)($row['spins_count'] ?? 0),
            'referrals_count' => (int)($row['referrals_count'] ?? 0),
            'rating_average' => 0,
        ];
    }

    $addresses = [];
    if ($addressAvailable) {
        $addressOrderSelect = $ordersAvailable
            ? "COALESCE(o.linked_orders, 0) AS linked_orders, o.last_order_at"
            : "0 AS linked_orders, NULL AS last_order_at";
        $addressRows = masterUsersRows("
            SELECT
                a.address_id,
                a.address_usersid,
                a.address_name,
                a.address_city,
                a.address_street,
                a.address_phone,
                a.address_lat,
                a.address_long,
                u.users_name,
                u.users_phone,
                u.users_image,
                {$addressOrderSelect}
            FROM address a
            LEFT JOIN users u ON u.users_id = a.address_usersid
            " . ($ordersAvailable ? "
                LEFT JOIN (
                    SELECT
                        orders_address AS address_id,
                        COUNT(*) AS linked_orders,
                        MAX(orders_datetime) AS last_order_at
                    FROM orders
                    WHERE orders_address IS NOT NULL
                    GROUP BY orders_address
                ) o ON o.address_id = a.address_id
            " : "") . "
            ORDER BY a.address_id DESC
            LIMIT 260
        ");
        foreach ($addressRows as $row) {
            $addresses[] = [
                'address_id' => (int)($row['address_id'] ?? 0),
                'user_id' => (int)($row['address_usersid'] ?? 0),
                'user_name' => (string)($row['users_name'] ?? ''),
                'user_phone' => (string)($row['users_phone'] ?? $row['address_phone'] ?? ''),
                'user_avatar' => (string)($row['users_image'] ?? ''),
                'type_label' => (string)($row['address_name'] ?? 'عنوان'),
                'title' => trim((string)($row['address_name'] ?? '')) !== ''
                    ? (string)$row['address_name']
                    : (string)($row['address_street'] ?? ''),
                'city' => (string)($row['address_city'] ?? ''),
                'district' => (string)($row['address_street'] ?? ''),
                'landmark' => (string)($row['address_street'] ?? ''),
                'status' => 'نشط',
                'saved_date' => '-',
                'last_order' => masterUsersDate($row['last_order_at'] ?? null),
                'postal_code' => '-',
                'linked_orders' => (int)($row['linked_orders'] ?? 0),
                'lat' => $row['address_lat'] ?? null,
                'lng' => $row['address_long'] ?? null,
            ];
        }
    }

    $recipients = [];
    if ($ordersAvailable) {
        $recipientRows = masterUsersRows("
            SELECT
                o.orders_usersid,
                COALESCE(NULLIF(o.orders_recipient_name, ''), u.users_name, 'Recipient') AS recipient_name,
                COALESCE(NULLIF(o.orders_recipient_phone, ''), u.users_phone, '') AS recipient_phone,
                COALESCE(NULLIF(o.orders_recipient_address_name, ''), NULLIF(o.orders_recipient_address_line, ''), '') AS address_title,
                COALESCE(o.orders_recipient_lat, o.delivery_latitude) AS lat,
                COALESCE(o.orders_recipient_lng, o.delivery_longitude) AS lng,
                u.users_name,
                u.users_email,
                u.users_image,
                COUNT(*) AS total_orders,
                MAX(o.orders_datetime) AS last_used
            FROM orders o
            LEFT JOIN users u ON u.users_id = o.orders_usersid
            WHERE COALESCE(o.orders_recipient_name, o.orders_recipient_phone, '') <> ''
            GROUP BY o.orders_usersid, recipient_name, recipient_phone, address_title, lat, lng, u.users_name, u.users_email, u.users_image
            ORDER BY last_used DESC
            LIMIT 260
        ");
        foreach ($recipientRows as $row) {
            $recipients[] = [
                'user_name' => (string)($row['users_name'] ?? ''),
                'user_avatar' => (string)($row['users_image'] ?? ''),
                'recipient_name' => (string)($row['recipient_name'] ?? ''),
                'phone' => (string)($row['recipient_phone'] ?? ''),
                'email' => (string)($row['users_email'] ?? ''),
                'type_label' => 'مستلم',
                'default_label' => ((int)($row['total_orders'] ?? 0) > 1) ? 'مكرر' : '-',
                'address_title' => (string)($row['address_title'] ?? ''),
                'city' => '',
                'saved_date' => masterUsersDate($row['last_used'] ?? null),
                'last_used' => masterUsersDate($row['last_used'] ?? null),
                'status' => 'نشط',
                'total_orders' => (int)($row['total_orders'] ?? 0),
                'lat' => $row['lat'] ?? null,
                'lng' => $row['lng'] ?? null,
            ];
        }
    }

    $favorites = [];
    if (tableExists('favorite') && tableExists('items')) {
        $favoriteRows = masterUsersRows("
            SELECT
                f.favorite_id,
                f.favorite_usersid,
                f.favorite_itemsid,
                i.items_name_ar,
                i.items_name_en,
                i.items_image,
                i.items_price,
                i.items_active,
                u.users_name,
                u.users_phone
            FROM favorite f
            INNER JOIN items i ON i.items_id = f.favorite_itemsid
            LEFT JOIN users u ON u.users_id = f.favorite_usersid
            ORDER BY f.favorite_id DESC
            LIMIT 260
        ");
        foreach ($favoriteRows as $row) {
            $favorites[] = [
                'favorite_id' => (int)($row['favorite_id'] ?? 0),
                'user_id' => (int)($row['favorite_usersid'] ?? 0),
                'user_name' => (string)($row['users_name'] ?? ''),
                'user_phone' => (string)($row['users_phone'] ?? ''),
                'item_id' => (int)($row['favorite_itemsid'] ?? 0),
                'item_name' => trim((string)($row['items_name_ar'] ?? '')) !== ''
                    ? (string)$row['items_name_ar']
                    : (string)($row['items_name_en'] ?? ''),
                'item_image' => (string)($row['items_image'] ?? ''),
                'price' => (string)($row['items_price'] ?? '0'),
                'active' => (int)($row['items_active'] ?? 0) === 1,
            ];
        }
    }

    $userOrders = [];
    if ($ordersAvailable) {
        $orderRows = masterUsersRows("
            SELECT
                o.orders_id,
                o.orders_usersid,
                o.orders_status,
                o.status,
                o.orders_totalprice,
                o.orders_datetime,
                u.users_name,
                u.users_phone
            FROM orders o
            LEFT JOIN users u ON u.users_id = o.orders_usersid
            ORDER BY o.orders_datetime DESC, o.orders_id DESC
            LIMIT 260
        ");
        foreach ($orderRows as $row) {
            $userOrders[] = [
                'order_id' => (int)($row['orders_id'] ?? 0),
                'user_id' => (int)($row['orders_usersid'] ?? 0),
                'user_name' => (string)($row['users_name'] ?? ''),
                'user_phone' => (string)($row['users_phone'] ?? ''),
                'status' => (string)($row['orders_status'] ?? $row['status'] ?? ''),
                'total' => (string)($row['orders_totalprice'] ?? '0'),
                'created_at' => masterUsersDate($row['orders_datetime'] ?? null),
            ];
        }
    }

    $notes = [];
    if (tableExists('master_audit_logs')) {
        $noteRows = masterUsersRows("
            SELECT audit_id, actor_name, action_text, entity_label,
                   action_time_label, created_at
            FROM master_audit_logs
            WHERE action_text LIKE 'user note:%'
            ORDER BY created_at DESC, audit_id DESC
            LIMIT 260
        ");
        foreach ($noteRows as $row) {
            $notes[] = [
                'note_id' => (int)($row['audit_id'] ?? 0),
                'actor' => (string)($row['actor_name'] ?? ''),
                'text' => trim(str_replace('user note:', '', (string)($row['action_text'] ?? ''))),
                'entity' => (string)($row['entity_label'] ?? ''),
                'created_at' => (string)($row['created_at'] ?? $row['action_time_label'] ?? ''),
            ];
        }
    }

    respondJson([
        'status' => 'success',
        'master' => $master,
        'data' => [
            'users' => $users,
            'addresses' => $addresses,
            'recipients' => $recipients,
            'favorites' => $favorites,
            'orders' => $userOrders,
            'notes' => $notes,
            'summary' => [
                'total_users' => count($users),
                'active_users' => (int)masterUsersScalar("SELECT COUNT(*) FROM users WHERE users_approve = 1"),
                'total_addresses' => count($addresses),
                'total_recipients' => count($recipients),
            ],
            'data_quality' => empty($masterUsersQueryFailures)
                ? ['state' => 'complete']
                : [
                    'state' => 'degraded',
                    'failed_components' => array_values(array_unique($masterUsersQueryFailures)),
                ],
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
        'data' => [
            'users' => [],
            'addresses' => [],
            'recipients' => [],
            'favorites' => [],
            'orders' => [],
            'notes' => [],
        ],
    ], 500);
}
