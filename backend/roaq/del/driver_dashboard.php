<?php
include "connect.php";
header("Content-Type: application/json; charset=utf-8");
function normalizeCoordinate($value): ?float
{
    if ($value === null) {
        return null;
    }
    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }
    $number = (float)$text;
    if (!is_finite($number)) {
        return null;
    }
    return $number;
}
function hasCoordinate(?float $lat, ?float $lng): bool
{
    return $lat !== null && $lng !== null && ($lat != 0.0 || $lng != 0.0);
}
function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
{
    $earthRadius = 6371.0;
    $lat1Rad = deg2rad($lat1);
    $lat2Rad = deg2rad($lat2);
    $deltaLat = deg2rad($lat2 - $lat1);
    $deltaLng = deg2rad($lng2 - $lng1);
    $a = sin($deltaLat / 2) * sin($deltaLat / 2)
        + cos($lat1Rad) * cos($lat2Rad)
        * sin($deltaLng / 2) * sin($deltaLng / 2);
    $c = 2 * atan2(sqrt($a), sqrt(max(0.0, 1 - $a)));
    return $earthRadius * $c;
}
function resolveDistanceKm(array $row): float
{
    $status = strtolower(trim((string)($row['status'] ?? '')));
    $driverLat =
        deliveryNormalizeCoordinate($row['driver_current_latitude'] ?? null) ??
        deliveryNormalizeCoordinate($row['driver_latitude'] ?? null);
    $driverLng =
        deliveryNormalizeCoordinate($row['driver_current_longitude'] ?? null) ??
        deliveryNormalizeCoordinate($row['driver_longitude'] ?? null);
    $restaurantCoords = deliveryResolveCoordinatePair(
        $row['restaurant_lat'] ?? null,
        $row['restaurant_lng'] ?? null,
        trim(
            (string)($row['restaurant_address'] ?? '') .
            ' ' .
            (string)($row['branch_label'] ?? '')
        )
    );
    $customerCoords = deliveryResolveCoordinatePair(
        $row['customer_lat'] ?? null,
        $row['customer_lng'] ?? null,
        trim(
            (string)($row['customer_address_name'] ?? '') .
            ' ' .
            (string)($row['customer_address_line'] ?? '')
        )
    );
    $restaurantLat = $restaurantCoords['lat'];
    $restaurantLng = $restaurantCoords['lng'];
    $customerLat = $customerCoords['lat'];
    $customerLng = $customerCoords['lng'];
    $routeToRestaurant = in_array(
        $status,
        ['incoming', 'assigned', 'heading_to_restaurant', 'arrived_at_restaurant'],
        true
    );
    $targetLat = $routeToRestaurant ? $restaurantLat : $customerLat;
    $targetLng = $routeToRestaurant ? $restaurantLng : $customerLng;
    if (!hasCoordinate($targetLat, $targetLng)) {
        if (hasCoordinate($restaurantLat, $restaurantLng)) {
            $targetLat = $restaurantLat;
            $targetLng = $restaurantLng;
        } elseif (hasCoordinate($customerLat, $customerLng)) {
            $targetLat = $customerLat;
            $targetLng = $customerLng;
        }
    }
    if (hasCoordinate($driverLat, $driverLng) && hasCoordinate($targetLat, $targetLng)) {
        return haversineKm($driverLat, $driverLng, $targetLat, $targetLng);
    }
    if (hasCoordinate($restaurantLat, $restaurantLng) && hasCoordinate($customerLat, $customerLng)) {
        return haversineKm($restaurantLat, $restaurantLng, $customerLat, $customerLng);
    }
    if (hasCoordinate($driverLat, $driverLng) && hasCoordinate($customerLat, $customerLng)) {
        return haversineKm($driverLat, $driverLng, $customerLat, $customerLng);
    }
    return 0.0;
}
function resolveRouteDistanceKm(array $row): float
{
    $restaurantLat = normalizeCoordinate($row['restaurant_lat'] ?? null);
    $restaurantLng = normalizeCoordinate($row['restaurant_lng'] ?? null);
    $customerLat = normalizeCoordinate($row['customer_lat'] ?? null);
    $customerLng = normalizeCoordinate($row['customer_lng'] ?? null);
    if (hasCoordinate($restaurantLat, $restaurantLng) && hasCoordinate($customerLat, $customerLng)) {
        return haversineKm($restaurantLat, $restaurantLng, $customerLat, $customerLng);
    }
    return resolveDistanceKm($row);
}
function fetchOrderDetails(PDO $con, string $whereClause, array $params): array
{
    // A customer order can contain items from many vendors. The driver must
    // receive only the vendor sub-orders assigned to this driver.
    $driverParam = (int)($params[0] ?? 0);
    // The second value preserves compatibility with orders that were
    // assigned before vendor-scoped delivery columns existed.
    $params = array_merge([$driverParam, $driverParam], $params);
    $sql = "
        SELECT
            o.orders_id AS id,
            o.orders_id AS order_id,
            ov.vendor_id AS vendor_id,
            o.delivery_id AS driver_id,
            COALESCE(o.status, 'new') AS status,
            o.orders_status,
            o.orders_datetime,
            o.order_mode,
            o.scheduled_for,
            o.assigned_at,
            o.accepted_at,
            o.arrived_at_restaurant_at,
            o.picked_up_at,
            o.arrived_at_customer_at,
            o.delivered_at,
            o.proof_type,
            o.proof_image,
            o.driver_emergency_reason,
            o.driver_emergency_at,
            o.driver_latitude,
            o.driver_longitude,
            o.orders_estimated_minutes AS eta_minutes,
            o.orders_totalprice AS total_price,
            o.orders_pricedelivery AS delivery_fee,
            o.orders_gift_message AS gift_message,
            o.orders_delivery_note AS customer_note,
            o.orders_share_token AS share_token,
            o.orders_usersid AS customer_user_id,
            COALESCE(u.users_name, o.orders_recipient_name, 'Customer') AS customer_name,
            o.orders_recipient_phone AS customer_phone,
            COALESCE(o.orders_recipient_lat, a.address_lat) AS customer_lat,
            COALESCE(o.orders_recipient_lng, a.address_long) AS customer_lng,
            COALESCE(o.orders_recipient_address_name, a.address_name, '') AS customer_address_name,
            COALESCE(o.orders_recipient_address_line, a.address_street, '') AS customer_address_line,
            o.orders_recipient_location_note AS customer_location_note,
            COALESCE(v.store_name, v.vendor_name, 'Restaurant') AS restaurant_name,
            COALESCE(v.vendor_type, 'restaurant') AS vendor_type,
            COALESCE(v.store_category, '') AS store_category,
            COALESCE(v.vendor_phone, '') AS restaurant_phone,
            COALESCE(v.vendor_logo, '') AS restaurant_logo,
            COALESCE(vss.store_address, v.vendor_description, (
                SELECT CONCAT_WS(' - ', rb.branch_name_en, rb.branch_name_ar)
                FROM order_items oi_branch
                LEFT JOIN vendors v_branch ON v_branch.vendor_id = oi_branch.vendor_id
                LEFT JOIN restaurant_branches rb
                    ON rb.vendor_id = v_branch.vendor_id
                   AND rb.is_active = 1
                WHERE oi_branch.order_id = o.orders_id
                  AND FIND_IN_SET(CAST(oi_branch.vendor_id AS CHAR), ov.vendor_ids) > 0
                ORDER BY oi_branch.order_item_id ASC
                LIMIT 1
            ), '') AS restaurant_address,
            COALESCE(vss.store_latitude, (
                SELECT MIN(rb.latitude)
                FROM order_items oi_lat
                JOIN vendors v_lat ON v_lat.vendor_id = oi_lat.vendor_id
                LEFT JOIN restaurant_branches rb
                    ON rb.vendor_id = v_lat.vendor_id
                   AND rb.is_active = 1
                WHERE oi_lat.order_id = o.orders_id
                  AND FIND_IN_SET(CAST(oi_lat.vendor_id AS CHAR), ov.vendor_ids) > 0
            ), NULL) AS restaurant_lat,
            COALESCE(vss.store_longitude, (
                SELECT MIN(rb.longitude)
                FROM order_items oi_lng
                JOIN vendors v_lng ON v_lng.vendor_id = oi_lng.vendor_id
                LEFT JOIN restaurant_branches rb
                    ON rb.vendor_id = v_lng.vendor_id
                   AND rb.is_active = 1
                WHERE oi_lng.order_id = o.orders_id
                  AND FIND_IN_SET(CAST(oi_lng.vendor_id AS CHAR), ov.vendor_ids) > 0
            ), NULL) AS restaurant_lng,
            COALESCE((
                SELECT CONCAT_WS(' - ', rb.branch_name_en, rb.branch_name_ar)
                FROM order_items oi_branch
                LEFT JOIN vendors v_branch ON v_branch.vendor_id = oi_branch.vendor_id
                LEFT JOIN restaurant_branches rb
                    ON rb.vendor_id = v_branch.vendor_id
                   AND rb.is_active = 1
                WHERE oi_branch.order_id = o.orders_id
                  AND FIND_IN_SET(CAST(oi_branch.vendor_id AS CHAR), ov.vendor_ids) > 0
                ORDER BY oi_branch.order_item_id ASC
                LIMIT 1
            ), '') AS branch_label,
            COALESCE((
                SELECT CONCAT(
                    '[',
                    GROUP_CONCAT(
                        JSON_OBJECT(
                            'order_item_id', oi.order_item_id,
                            'item_id', oi.item_id,
                            'name', COALESCE(NULLIF(oi.item_name, ''), CONCAT('Item #', oi.item_id)),
                            'image_url', COALESCE(NULLIF(i.items_image, ''), ''),
                            'quantity', oi.quantity,
                            'quantity_weight', COALESCE(oi.quantity_weight, 0),
                            'item_color', COALESCE(oi.item_color, ''),
                            'item_size', COALESCE(oi.item_size, ''),
                            'product_type', COALESCE(i.product_type, 'food'),
                            'stock_unit', COALESCE(oi.stock_unit, i.stock_unit, 'piece'),
                            'unit_price', COALESCE(oi.item_price, i.items_price, 0),
                            'discount', COALESCE(oi.item_discount, i.items_discount, 0),
                            'line_total', COALESCE(
                                oi.line_total,
                                oi.subtotal,
                                (
                                    (COALESCE(oi.item_price, i.items_price, 0) -
                                        ((COALESCE(oi.item_price, i.items_price, 0) * COALESCE(oi.item_discount, i.items_discount, 0)) / 100)
                                    ) * oi.quantity
                                )
                            ),
                            'note', COALESCE(oi.food_item_note, ''),
                            'currency_symbol', '€'
                        )
                        ORDER BY oi.order_item_id
                        SEPARATOR ','
                    ),
                    ']'
                )
                FROM order_items oi
                LEFT JOIN items i ON i.items_id = oi.item_id
                WHERE oi.order_id = o.orders_id
                  AND FIND_IN_SET(CAST(oi.vendor_id AS CHAR), ov.vendor_ids) > 0
            ), '[]') AS items_json,
            COALESCE((
                SELECT GROUP_CONCAT(
                    CONCAT(
                        oi.quantity,
                        ' x ',
                        COALESCE(oi.item_name, CONCAT('Item #', oi.item_id))
                    )
                    ORDER BY oi.order_item_id
                    SEPARATOR '\n'
                )
                FROM order_items oi
                WHERE oi.order_id = o.orders_id
                  AND FIND_IN_SET(CAST(oi.vendor_id AS CHAR), ov.vendor_ids) > 0
            ), '') AS items,
            o.orders_recipient_address_name AS customer_address,
            COALESCE(o.orders_recipient_location_note, o.orders_recipient_address_name, '') AS zone,
            du.latitude AS driver_current_latitude,
            du.longitude AS driver_current_longitude,
            0 AS distance_km
        FROM orders o
        INNER JOIN (
            SELECT
                vo.order_id,
                MIN(vo.vendor_id) AS vendor_id,
                GROUP_CONCAT(DISTINCT vo.vendor_id ORDER BY vo.vendor_id) AS vendor_ids
            FROM vendor_orders vo
            INNER JOIN orders assigned_order ON assigned_order.orders_id = vo.order_id
            WHERE vo.delivery_id = ?
               OR (
                    vo.delivery_id IS NULL
                    AND assigned_order.delivery_id = ?
                    AND NOT EXISTS (
                        SELECT 1 FROM vendor_orders assigned_vendor
                        WHERE assigned_vendor.order_id = vo.order_id
                          AND assigned_vendor.delivery_id IS NOT NULL
                    )
               )
            GROUP BY vo.order_id
        ) ov ON ov.order_id = o.orders_id
        LEFT JOIN vendors v ON v.vendor_id = ov.vendor_id
        LEFT JOIN users u ON u.users_id = o.orders_usersid
        LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
        LEFT JOIN address a ON a.address_id = o.orders_address
        LEFT JOIN delivery_users du ON du.id = o.delivery_id
        WHERE {$whereClause}
        ORDER BY o.orders_id DESC
    ";
    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as &$row) {
        $row['distance_km'] = resolveDistanceKm($row);
        $row['route_distance_km'] = resolveRouteDistanceKm($row);
    }
    unset($row);
    return $rows;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"]);
    exit;
}
$driverId = (int)($_POST['driver_id'] ?? 0);
if ($driverId <= 0) {
    echo json_encode(["status" => "error", "message" => "driver_id is required"]);
    exit;
}
try {
    ensureVendorOrderDeliverySchema();
    $profileStmt = $con->prepare("SELECT * FROM delivery_users WHERE id = ? LIMIT 1");
    $profileStmt->execute([$driverId]);
    $profile = $profileStmt->fetch(PDO::FETCH_ASSOC) ?: null;
    if (is_array($profile)) {
        unset($profile['password']);
    }
    $activeOrders = fetchOrderDetails(
        $con,
        "o.delivery_id = ? AND COALESCE(o.status, 'new') IN ('accepted', 'heading_to_restaurant', 'heading_to_restauran', 'on_the_way', 'arrived_at_restaurant', 'arrived_at_restauran', 'picked_up', 'heading_to_customer', 'arrived_at_customer', 'awaiting_delivery_code', 'awaiting_verification')",
        [$driverId]
    );
    $activeOrder = $activeOrders[0] ?? null;
    $incomingOrders = fetchOrderDetails(
        $con,
        "o.delivery_id = ? AND COALESCE(o.status, '') = 'assigned'",
        [$driverId]
    );
    $incomingOrder = $incomingOrders[0] ?? null;
    $history = fetchOrderDetails(
        $con,
        "o.delivery_id = ? AND COALESCE(o.status, '') IN ('delivered', 'completed')",
        [$driverId]
    );
    echo json_encode([
        "status" => "success",
        "profile" => $profile,
        "active_order" => $activeOrder,
        "incoming_order" => $incomingOrder,
        "history" => array_slice($history, 0, 50),
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
