<?php
ob_start();
include "../connect.php";
require_once __DIR__ . "/../notifications/notification_helper.php";
header('Content-Type: application/json; charset=utf-8');
$usersid = filterRequest("usersid");
$addressid = filterRequest("addressid");
$orderstype = filterRequest("orderstype");
$pricedelivery = filterRequest("pricedelivery");
$couponid = filterRequest("couponid");
$paymentmethod = filterRequest("paymentmethod");
$recipientName = trim((string) filterRequest("recipient_name"));
$recipientPhone = trim((string) filterRequest("recipient_phone"));
$recipientLabel = trim((string) filterRequest("recipient_label"));
$recipientAddressName = trim((string) filterRequest("recipient_address_name"));
$recipientAddressLine = trim((string) filterRequest("recipient_address_line"));
$recipientLocationNote = trim((string) filterRequest("recipient_location_note"));
$recipientBuilding = trim((string) filterRequest("recipient_building"));
$recipientFloor = trim((string) filterRequest("recipient_floor"));
$recipientLat = trim((string) filterRequest("recipient_lat"));
$recipientLng = trim((string) filterRequest("recipient_lng"));
$addressLat = trim((string) filterRequest("address_lat"));
$addressLng = trim((string) filterRequest("address_lng"));
$deliveryLatitude = trim((string) filterRequest("delivery_latitude"));
$deliveryLongitude = trim((string) filterRequest("delivery_longitude"));
$deliveryAddress = trim((string) filterRequest("delivery_address"));
$deliveryDistanceKm = trim((string) filterRequest("delivery_distance_km"));
$orderMode = strtolower(trim((string) filterRequest("order_mode")));
$scheduledForRaw = trim((string) filterRequest("scheduled_for"));
$giftMessage = trim((string) filterRequest("gift_message"));
$deliveryNote = trim((string) filterRequest("delivery_note"));
if (!in_array($orderMode, ['asap', 'scheduled', 'preorder'], true)) {
    $orderMode = 'asap';
}
$scheduledFor = null;
if ($scheduledForRaw !== '') {
    $normalizedScheduledFor = str_replace('T', ' ', $scheduledForRaw);
    $timestamp = strtotime($normalizedScheduledFor);
    if ($timestamp !== false) {
        $scheduledFor = date('Y-m-d H:i:s', $timestamp);
    }
}
if ($orderMode !== 'asap' && $scheduledFor === null) {
    echo json_encode(["status" => "error", "message" => "Missing scheduled delivery time"]);
    exit;
}
function loadVendorScheduleState(PDO $con, int $vendorId): array
{
    $hasStoreSettings = tableExists('vendor_store_settings');
    $hasProfiles = tableExists('restaurant_profiles');
    $settingsSelect = $hasStoreSettings
        ? "COALESCE(vs.is_open, 1) AS store_is_open,
           COALESCE(vs.accepts_preorders, 1) AS accepts_preorders,
           COALESCE(vs.preorder_days_limit, 7) AS preorder_days_limit,
           vs.restaurant_working_hours_json,
           vs.working_hours_json"
        : "1 AS store_is_open,
           1 AS accepts_preorders,
           7 AS preorder_days_limit,
           NULL AS restaurant_working_hours_json,
           NULL AS working_hours_json";
    $profileSelect = $hasProfiles
        ? "rp.open_override AS manual_open_override"
        : "NULL AS manual_open_override";
    $settingsJoin = $hasStoreSettings
        ? "LEFT JOIN vendor_store_settings vs ON vs.vendor_id = v.vendor_id"
        : "";
    $profileJoin = $hasProfiles
        ? "LEFT JOIN restaurant_profiles rp ON rp.vendor_id = v.vendor_id"
        : "";
    $stmt = $con->prepare("
        SELECT
            v.vendor_id,
            {$settingsSelect},
            {$profileSelect}
        FROM vendors v
        {$settingsJoin}
        {$profileJoin}
        WHERE v.vendor_id = :vendor_id
        LIMIT 1
    ");
    $stmt->execute([':vendor_id' => $vendorId]);
    $vendorRow = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$vendorRow) {
        return [];
    }
    $hoursRows = [];
    if (tableExists('restaurant_hours')) {
        $hoursStmt = $con->prepare("
            SELECT day_key, opens_at, closes_at, is_open
            FROM restaurant_hours
            WHERE vendor_id = :vendor_id
              AND is_active = 1
        ");
        $hoursStmt->execute([':vendor_id' => $vendorId]);
        $hoursRows = $hoursStmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }
    if (empty($hoursRows)) {
        $hoursRows = workingHoursRowsFromPayload(
            $vendorRow['restaurant_working_hours_json'] ?? $vendorRow['working_hours_json'] ?? null,
            $vendorId
        );
    }
    return [
        'vendor' => $vendorRow,
        'hours_rows' => $hoursRows,
    ];
}
function validateVendorScheduleForOrder(array $scheduleState, string $orderMode, ?int $scheduledTimestamp): ?string
{
    $vendor = $scheduleState['vendor'] ?? [];
    $hoursRows = $scheduleState['hours_rows'] ?? [];
    $manualOverride = $vendor['manual_open_override'] ?? null;
    if ($manualOverride !== null && $manualOverride !== '') {
        return (int)$manualOverride === 1 ? null : 'Restaurant is currently closed';
    }
    if (isset($vendor['store_is_open']) && (int)$vendor['store_is_open'] === 0) {
        return 'Restaurant is currently closed';
    }
    $hoursMap = workingHoursRowsByDayKey($hoursRows);
    $checkTimestamp = $orderMode === 'asap' ? time() : ($scheduledTimestamp ?? time());
    if (!workingHoursMapAllowsTimestamp($hoursMap, $checkTimestamp)) {
        return $orderMode === 'asap'
            ? 'Restaurant is currently closed'
            : 'Selected time is outside working hours';
    }
    if ($orderMode !== 'asap') {
        if (isset($vendor['accepts_preorders']) && (int)$vendor['accepts_preorders'] !== 1) {
            return 'Restaurant does not accept scheduled orders';
        }
        $limitDays = isset($vendor['preorder_days_limit']) ? (int)$vendor['preorder_days_limit'] : 0;
        if ($limitDays > 0 && $scheduledTimestamp !== null) {
            $maxTimestamp = strtotime('+' . $limitDays . ' days', time());
            if ($maxTimestamp !== false && $scheduledTimestamp > $maxTimestamp) {
                return 'Selected time exceeds the allowed preorder window';
            }
        }
    }
    return null;
}
function resolveActiveDeliveryZone(PDO $con, ?string $latitude, ?string $longitude): ?array
{
    if ($latitude === null || $longitude === null || !is_numeric($latitude) || !is_numeric($longitude)) {
        return null;
    }
    if (!tableExists('delivery_zones')) {
        return null;
    }
    $lat = (float)$latitude;
    $lng = (float)$longitude;
    if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
        return null;
    }
    $stmt = $con->query("
        SELECT
            zone_id,
            delivery_fee,
            estimated_min_minutes,
            estimated_max_minutes,
            center_latitude,
            center_longitude,
            coverage_km
        FROM delivery_zones
        WHERE is_active = 1
          AND center_latitude IS NOT NULL
          AND center_longitude IS NOT NULL
          AND coverage_km IS NOT NULL
          AND coverage_km > 0
    ");
    $closest = null;
    while ($zone = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $zoneLat = (float)$zone['center_latitude'];
        $zoneLng = (float)$zone['center_longitude'];
        $latDelta = deg2rad($zoneLat - $lat);
        $lngDelta = deg2rad($zoneLng - $lng);
        $a = sin($latDelta / 2) ** 2
            + cos(deg2rad($lat)) * cos(deg2rad($zoneLat)) * sin($lngDelta / 2) ** 2;
        $distanceKm = 6371 * 2 * atan2(sqrt($a), sqrt(max(0, 1 - $a)));
        if ($distanceKm > (float)$zone['coverage_km']) {
            continue;
        }
        if ($closest === null || $distanceKm < $closest['distance_km']) {
            $zone['distance_km'] = $distanceKm;
            $closest = $zone;
        }
    }
    return $closest;
}
if (!$usersid) {
    echo json_encode(["status" => "error", "message" => "Missing user id"]);
    exit;
}
if ($orderstype == "1") {
    $pricedelivery = 0;
}
$pricedelivery = is_numeric($pricedelivery) ? max(0, (float)$pricedelivery) : 0;
$paymentMethodValue = 0;
$paymentMethodText = 'cash_on_delivery';
if (is_string($paymentmethod)) {
    $normalizedPaymentMethod = strtolower(trim($paymentmethod));
    if ($normalizedPaymentMethod === 'wallet') {
        $paymentMethodValue = 2;
        $paymentMethodText = 'wallet';
    } elseif (ctype_digit($normalizedPaymentMethod)) {
        $paymentMethodValue = (int) $normalizedPaymentMethod;
        $paymentMethodText = $paymentMethodValue === 2
            ? 'wallet'
            : ($paymentMethodValue === 1 ? 'visa' : 'cash_on_delivery');
    } elseif (in_array($normalizedPaymentMethod, ['visa', 'card', 'credit', 'online', 'paymob'], true)) {
        $paymentMethodValue = 1;
        $paymentMethodText = 'visa';
    } elseif (in_array($normalizedPaymentMethod, ['cash', 'cod', 'cash_on_delivery'], true)) {
        $paymentMethodValue = 0;
        $paymentMethodText = 'cash_on_delivery';
    }
} elseif (is_numeric($paymentmethod)) {
    $paymentMethodValue = (int) $paymentmethod;
    $paymentMethodText = $paymentMethodValue === 2
        ? 'wallet'
        : ($paymentMethodValue === 1 ? 'visa' : 'cash_on_delivery');
}
$hasRecipientDestination =
    $recipientAddressName !== '' ||
    $recipientAddressLine !== '' ||
    ($recipientLat !== '' && $recipientLng !== '');
$addressRow = [];
if ($addressid) {
    $addressStmt = $con->prepare("
        SELECT address_name, address_city, address_street, address_phone, address_lat, address_long
        FROM address
        WHERE address_id = :address_id AND address_usersid = :user_id
        LIMIT 1
    ");
    $addressStmt->execute([
        ':address_id' => $addressid,
        ':user_id' => $usersid,
    ]);
    $addressRow = $addressStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    if ($recipientAddressName === '' && !empty($addressRow['address_name'])) {
        $recipientAddressName = trim((string)$addressRow['address_name']);
    }
    if ($recipientAddressLine === '' && !empty($addressRow['address_street'])) {
        $recipientAddressLine = trim((string)$addressRow['address_street']);
    }
    if ($recipientPhone === '' && !empty($addressRow['address_phone'])) {
        $recipientPhone = trim((string)$addressRow['address_phone']);
    }
    if ($recipientLat === '' && !empty($addressRow['address_lat'])) {
        $recipientLat = trim((string)$addressRow['address_lat']);
    }
    if ($recipientLng === '' && !empty($addressRow['address_long'])) {
        $recipientLng = trim((string)$addressRow['address_long']);
    }
}
if (($recipientLat === '' || $recipientLng === '') && ($addressLat !== '' || $addressLng !== '')) {
    if ($recipientLat === '' && $addressLat !== '') {
        $recipientLat = $addressLat;
    }
    if ($recipientLng === '' && $addressLng !== '') {
        $recipientLng = $addressLng;
    }
}
$deliveryLatitude = $deliveryLatitude !== '' ? $deliveryLatitude : $recipientLat;
$deliveryLongitude = $deliveryLongitude !== '' ? $deliveryLongitude : $recipientLng;
if ($deliveryAddress === '') {
    $deliveryAddressParts = array_values(array_filter([
        $recipientAddressName,
        $recipientAddressLine,
        $recipientLocationNote,
    ], function ($value) {
        return trim((string)$value) !== '';
    }));
    if (!$deliveryAddressParts && $addressid) {
        $deliveryAddressParts = array_values(array_filter([
            $addressRow['address_name'] ?? null,
            $addressRow['address_street'] ?? null,
            $addressRow['address_city'] ?? null,
        ], function ($value) {
            return trim((string)$value) !== '';
        }));
    }
    $deliveryAddress = implode(' - ', $deliveryAddressParts);
}
$resolvedRecipientCoords = deliveryResolveCoordinatePair(
    $recipientLat !== '' ? $recipientLat : null,
    $recipientLng !== '' ? $recipientLng : null,
    trim($recipientAddressName . ' ' . $recipientAddressLine)
);
$recipientLat = $resolvedRecipientCoords['lat'] !== null
    ? (string)$resolvedRecipientCoords['lat']
    : '';
$recipientLng = $resolvedRecipientCoords['lng'] !== null
    ? (string)$resolvedRecipientCoords['lng']
    : '';
// Use the final coordinates stored with the order. A saved address can supply
// them after the initial request fields have been normalized above.
$deliveryLatitude = $deliveryLatitude !== '' ? $deliveryLatitude : $recipientLat;
$deliveryLongitude = $deliveryLongitude !== '' ? $deliveryLongitude : $recipientLng;
$matchedDeliveryZone = null;
if ($orderstype == "0") {
    $distanceValue = is_numeric($deliveryDistanceKm)
        ? max(0, (float)$deliveryDistanceKm)
        : 0.0;
    if (tableExists('platform_settings')) {
        $settingsStmt = $con->query("SELECT delivery_base_fee, delivery_cost_per_km FROM platform_settings WHERE id = 1 LIMIT 1");
        $settings = $settingsStmt->fetch(PDO::FETCH_ASSOC) ?: [];
        $baseFee = is_numeric($settings['delivery_base_fee'] ?? null)
            ? max(0, (float)$settings['delivery_base_fee'])
            : 10.0;
        $costPerKm = is_numeric($settings['delivery_cost_per_km'] ?? null)
            ? max(0, (float)$settings['delivery_cost_per_km'])
            : 2.5;
        $pricedelivery = $costPerKm > 0
            ? $baseFee + ($distanceValue * $costPerKm)
            : $baseFee;
    }
    $matchedDeliveryZone = resolveActiveDeliveryZone(
        $con,
        $deliveryLatitude !== '' ? $deliveryLatitude : null,
        $deliveryLongitude !== '' ? $deliveryLongitude : null
    );
    $zoneFee = $matchedDeliveryZone['delivery_fee'] ?? null;
    if ($zoneFee !== null && is_numeric($zoneFee) && (float)$zoneFee >= 0) {
        $pricedelivery = (float)$zoneFee;
    }
}
if ($orderstype == "0" && !$addressid && !$hasRecipientDestination) {
    echo json_encode(["status" => "error", "message" => "Missing delivery destination"]);
    exit;
}
try {
    $con->beginTransaction();
    $outboxEnabled = notificationOutboxEnabled();
    $stmt = $con->prepare("
        SELECT
            c.cart_id,
            c.cart_itemsid,
            c.cart_variantid,
            c.cart_quantity,
            c.cart_context_type,
            c.cart_vendor_id,
            c.cart_unit_price,
            c.cart_item_note,
            c.cart_menu_options_json,
            c.cart_menu_options_summary,
            c.cart_variant_attributes_json,
            c.cart_quantity_weight,
            c.cart_lens_code,
            c.cart_lens_name,
            c.cart_lens_color,
            c.cart_lens_features,
            c.cart_lens_price,
            c.cart_prescription_json,
            c.cart_prescription_summary,
            i.vendor_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_price,
            i.items_discount,
            i.stock_unit,
            vnd.store_name,
            v.price AS variant_price,
            v.sku AS variant_sku,
            COALESCE(v.unit_quantity, 1) AS unit_quantity,
            col.color_name AS item_color,
            siz.size_name AS item_size
        FROM cart c
        JOIN items i ON i.items_id = c.cart_itemsid
        JOIN vendors vnd ON vnd.vendor_id = i.vendor_id
        LEFT JOIN item_variants v ON v.variant_id = c.cart_variantid
        LEFT JOIN colors col ON col.color_id = v.color_id
        LEFT JOIN sizes siz ON siz.size_id = v.size_id
        WHERE c.cart_usersid = :uid AND c.cart_orders = 0
        FOR UPDATE
    ");
    $stmt->execute([":uid" => $usersid]);
    $cartItems = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!$cartItems) {
        $con->rollBack();
        echo json_encode(["status" => "error", "message" => "Cart is empty"]);
        exit;
    }
    $scheduleCheckTimestamp = $scheduledFor !== null ? strtotime($scheduledFor) : null;
    if ($scheduleCheckTimestamp === false) {
        $scheduleCheckTimestamp = null;
    }
    $uniqueVendorIds = [];
    foreach ($cartItems as $itemRow) {
        $vendorId = (int)($itemRow['vendor_id'] ?? 0);
        if ($vendorId > 0) {
            $uniqueVendorIds[$vendorId] = true;
        }
    }
    foreach (array_keys($uniqueVendorIds) as $vendorId) {
        $scheduleState = loadVendorScheduleState($con, $vendorId);
        if (!$scheduleState) {
            $con->rollBack();
            echo json_encode(["status" => "error", "message" => "Restaurant not found"]);
            exit;
        }
        $validationMessage = validateVendorScheduleForOrder(
            $scheduleState,
            $orderMode,
            $scheduleCheckTimestamp
        );
        if ($validationMessage !== null) {
            $con->rollBack();
            echo json_encode(["status" => "error", "message" => $validationMessage]);
            exit;
        }
    }
    $computedOrdersPrice = 0.00;
    foreach ($cartItems as $it) {
        $basePrice = $it['variant_price'] !== null ? (float) $it['variant_price'] : (float) $it['items_price'];
        $discount = $it['variant_price'] !== null ? 0 : (float) $it['items_discount'];
        $lensPrice = (float) $it['cart_lens_price'];
        $qty = (int) $it['cart_quantity'];
        $priceAfterDiscount = $basePrice - ($basePrice * $discount / 100.0);
        $foodUnitPrice = $it['cart_unit_price'] !== null && $it['cart_unit_price'] !== ''
            ? (float) $it['cart_unit_price']
            : $priceAfterDiscount;
        $billableQuantity = ($it['stock_unit'] ?? '') === 'kg'
            ? (float)($it['cart_quantity_weight'] ?? $qty)
            : $qty;
        $computedOrdersPrice += ($foodUnitPrice + ($lensPrice * 2)) * $billableQuantity;
    }
    $now = date("Y-m-d H:i:s");
    $couponIdToInsert = null;
    $couponDiscountPercent = 0;
    if ($couponid) {
        // A coupon belongs to exactly one restaurant. Do not apply a
        // restaurant coupon to a mixed-vendor cart.
        $couponVendorId = count($uniqueVendorIds) === 1
            ? (int)array_key_first($uniqueVendorIds)
            : 0;
        $cstmt = $con->prepare("SELECT coupon_id, coupon_discount, coupon_count, coupon_expiredate FROM coupon WHERE coupon_id = :cid AND vendor_id = :vendor_id FOR UPDATE");
        $cstmt->execute([":cid" => $couponid, ':vendor_id' => $couponVendorId]);
        $couponRow = $cstmt->fetch(PDO::FETCH_ASSOC);
        if ($couponRow && $couponRow['coupon_expiredate'] > $now && $couponRow['coupon_count'] > 0) {
            $couponIdToInsert = $couponRow['coupon_id'];
            $couponDiscountPercent = (float) $couponRow['coupon_discount'];
        } else {
            $con->rollBack();
            echo json_encode([
                'status' => 'error',
                'message' => count($uniqueVendorIds) > 1
                    ? 'A coupon can only be used with one store per order'
                    : 'Coupon is no longer valid',
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }
    $totalBeforeDelivery = $computedOrdersPrice;
    if ($couponDiscountPercent > 0) {
        $totalBeforeDelivery *= (1 - $couponDiscountPercent / 100.0);
    }
    $totalprice = $totalBeforeDelivery + (float) $pricedelivery;
    $shareToken = substr(bin2hex(random_bytes(16)), 0, 24);
    $estimatedMinutes = $orderstype == "1" ? 20 : 45;
    $zoneMinMinutes = $matchedDeliveryZone['estimated_min_minutes'] ?? null;
    $zoneMaxMinutes = $matchedDeliveryZone['estimated_max_minutes'] ?? null;
    if ($orderstype == "0"
        && is_numeric($zoneMinMinutes)
        && is_numeric($zoneMaxMinutes)
        && (int)$zoneMinMinutes >= 0
        && (int)$zoneMaxMinutes >= (int)$zoneMinMinutes) {
        $estimatedMinutes = (int)round(((int)$zoneMinMinutes + (int)$zoneMaxMinutes) / 2);
    }
    $deliveryCode = str_pad((string)random_int(1000, 9999), 4, '0', STR_PAD_LEFT);
    $ins = $con->prepare("
        INSERT INTO orders
        (
            orders_usersid,
            orders_address,
            orders_recipient_label,
            orders_recipient_name,
            orders_recipient_phone,
            orders_recipient_address_name,
            orders_recipient_address_line,
            orders_recipient_location_note,
            orders_recipient_building,
            orders_recipient_floor,
            orders_recipient_lat,
            orders_recipient_lng,
            delivery_latitude,
            delivery_longitude,
            delivery_address,
            orders_gift_message,
            orders_delivery_note,
            orders_share_token,
            order_mode,
            scheduled_for,
            orders_estimated_minutes,
            orders_type,
            orders_pricedelivery,
            delivery_zone_id,
            orders_price,
            orders_coupon,
            orders_totalprice,
            orders_paymentmethod,
            payment_method,
            orders_status,
            delivery_code,
            orders_datetime
        )
        VALUES
        (
            :uid,
            :addr,
            :recipient_label,
            :recipient_name,
            :recipient_phone,
            :recipient_address_name,
            :recipient_address_line,
            :recipient_location_note,
            :recipient_building,
            :recipient_floor,
            :recipient_lat,
            :recipient_lng,
            :delivery_latitude,
            :delivery_longitude,
            :delivery_address,
            :gift_message,
            :delivery_note,
            :share_token,
            :order_mode,
            :scheduled_for,
            :estimated_minutes,
            :otype,
            :pricedelivery,
            :delivery_zone_id,
            :ordersprice,
            :coupon,
            :totalprice,
            :pmethod,
            :payment_method,
            'pending',
            :delivery_code,
            NOW()
        )
    ");
    $ins->execute([
        ":uid" => $usersid,
        ":addr" => $addressid ?: null,
        ":recipient_label" => $recipientLabel !== '' ? $recipientLabel : null,
        ":recipient_name" => $recipientName !== '' ? $recipientName : null,
        ":recipient_phone" => $recipientPhone !== '' ? $recipientPhone : null,
        ":recipient_address_name" => $recipientAddressName !== '' ? $recipientAddressName : null,
        ":recipient_address_line" => $recipientAddressLine !== '' ? $recipientAddressLine : null,
        ":recipient_location_note" => $recipientLocationNote !== '' ? $recipientLocationNote : null,
        ":recipient_building" => $recipientBuilding !== '' ? $recipientBuilding : null,
        ":recipient_floor" => $recipientFloor !== '' ? $recipientFloor : null,
        ":recipient_lat" => $recipientLat !== '' ? $recipientLat : null,
        ":recipient_lng" => $recipientLng !== '' ? $recipientLng : null,
        ":delivery_latitude" => $deliveryLatitude !== '' ? $deliveryLatitude : null,
        ":delivery_longitude" => $deliveryLongitude !== '' ? $deliveryLongitude : null,
        ":delivery_address" => $deliveryAddress !== '' ? $deliveryAddress : null,
        ":gift_message" => $giftMessage !== '' ? $giftMessage : null,
        ":delivery_note" => $deliveryNote !== '' ? $deliveryNote : null,
        ":share_token" => $shareToken,
        ":order_mode" => $orderMode,
        ":scheduled_for" => $scheduledFor,
        ":estimated_minutes" => $estimatedMinutes,
        ":otype" => $orderstype ?: 0,
        ":pricedelivery" => $pricedelivery,
        ":delivery_zone_id" => $matchedDeliveryZone === null
            ? null
            : (int)$matchedDeliveryZone['zone_id'],
        ":ordersprice" => $computedOrdersPrice,
        ":coupon" => $couponIdToInsert,
        ":totalprice" => $totalprice,
        ":pmethod" => $paymentMethodValue,
        ":payment_method" => $paymentMethodText,
        ":delivery_code" => $deliveryCode,
    ]);
    $orderId = $con->lastInsertId();
    $insertItemStmt = $con->prepare("
        INSERT INTO order_items (
            order_id, vendor_id, item_id, variant_id, item_name, item_color, item_size, item_price, item_discount, quantity, quantity_weight,
            user_id, lens_code, lens_name, lens_color, lens_features,
            lens_unit_price, lens_total_price, prescription_json,
            prescription_summary, line_total, food_item_note,
            food_menu_options_json, food_menu_options_summary, variant_attributes_json, stock_unit
        )
        VALUES (
            :oid, :vendor_id, :iid, :variant_id, :name, :item_color, :item_size, :price, :discount, :q, :quantity_weight,
            :user_id, :lens_code, :lens_name, :lens_color, :lens_features,
            :lens_unit_price, :lens_total_price, :prescription_json,
            :prescription_summary, :line_total, :food_item_note,
            :food_menu_options_json, :food_menu_options_summary, :variant_attributes_json, :stock_unit
        )
    ");
    foreach ($cartItems as $it) {
        $qty = (int) $it['cart_quantity'];
        $basePrice = $it['variant_price'] !== null ? (float) $it['variant_price'] : (float) $it['items_price'];
        $discount = $it['variant_price'] !== null ? 0 : (float) $it['items_discount'];
        $lensPrice = (float) $it['cart_lens_price'];
        $priceAfterDiscount = $basePrice - ($basePrice * $discount / 100.0);
        $foodUnitPrice = $it['cart_unit_price'] !== null && $it['cart_unit_price'] !== ''
            ? (float) $it['cart_unit_price']
            : $priceAfterDiscount;
        $billableQuantity = ($it['stock_unit'] ?? '') === 'kg'
            ? (float)($it['cart_quantity_weight'] ?? $qty)
            : $qty;
        $lineTotal = ($foodUnitPrice + ($lensPrice * 2)) * $billableQuantity;
        $insertItemStmt->execute([
            ":oid" => $orderId,
            ":vendor_id" => (int)$it['vendor_id'],
            ":iid" => $it['cart_itemsid'],
            ":variant_id" => $it['cart_variantid'] ?: null,
            ":name" => $it['items_name_en'] ?: $it['items_name_ar'],
            ":item_color" => $it['item_color'] ?: null,
            ":item_size" => $it['item_size'] ?: ($it['variant_sku'] ?? null),
            ":price" => $basePrice,
            ":discount" => $discount,
            ":q" => $qty,
            ":quantity_weight" => ($it['stock_unit'] ?? '') === 'kg'
                ? $billableQuantity
                : $qty * (float)($it['unit_quantity'] ?? 1),
            ":user_id" => $usersid,
            ":lens_code" => $it['cart_lens_code'] ?: null,
            ":lens_name" => $it['cart_lens_name'] ?: null,
            ":lens_color" => $it['cart_lens_color'] ?: null,
            ":lens_features" => $it['cart_lens_features'] ?: null,
            ":lens_unit_price" => $lensPrice,
            ":lens_total_price" => $lensPrice * 2 * $qty,
            ":prescription_json" => $it['cart_prescription_json'] ?: null,
            ":prescription_summary" => $it['cart_prescription_summary'] ?: null,
            ":line_total" => $lineTotal,
            ":food_item_note" => $it['cart_item_note'] ?: null,
            ":food_menu_options_json" => $it['cart_menu_options_json'] ?: null,
            ":food_menu_options_summary" => $it['cart_menu_options_summary'] ?: null,
            ":variant_attributes_json" => $it['cart_variant_attributes_json'] ?: null,
            ":stock_unit" => $it['stock_unit'] ?? null,
        ]);
    }
    $vendorOrderStmt = $con->prepare("
        INSERT INTO vendor_orders (
            order_id,
            vendor_id,
            customer_user_id,
            vendor_subtotal,
            vendor_total,
            vendor_status,
            created_at,
            updated_at
        )
        VALUES (
            :order_id,
            :vendor_id,
            :customer_user_id,
            :vendor_subtotal,
            :vendor_total,
            'pending',
            NOW(),
            NOW()
        )
    ");
    $groupStmt = $con->prepare("
        SELECT
            vendor_id,
            ROUND(SUM(line_total), 2) AS vendor_subtotal
        FROM order_items
        WHERE order_id = :order_id
        GROUP BY vendor_id
    ");
    $groupStmt->execute([":order_id" => $orderId]);
    $vendorRows = $groupStmt->fetchAll(PDO::FETCH_ASSOC);
    $vendorNotificationRows = [];
    foreach ($vendorRows as $vendorRow) {
        $vendorOrderStmt->execute([
            ':order_id' => $orderId,
            ':vendor_id' => (int)$vendorRow['vendor_id'],
            ':customer_user_id' => (int)$usersid,
            ':vendor_subtotal' => (float)$vendorRow['vendor_subtotal'],
            ':vendor_total' => (float)$vendorRow['vendor_subtotal'],
        ]);
        /*
         * Vendor notifications are intentionally sent after commit. Keeping
         * notification storage/push delivery out of this transaction reduces
         * lock time during checkout bursts.
         */
        $vendorId = (int)$vendorRow['vendor_id'];
        if ($outboxEnabled) {
            enqueueNotificationOutbox(
                $con,
                'vendor',
                $vendorId,
                'vendor_orders_' . $vendorId,
                'vendor_new_order',
                'New order',
                "New order received #$orderId",
                'order',
                (int)$orderId,
                [
                    'order_id' => (string)$orderId,
                    'vendor_id' => (string)$vendorId,
                    'user_id' => (string)$usersid,
                    'gift_message' => $giftMessage,
                    'delivery_note' => $deliveryNote,
                    'screen' => 'orders',
                    'order_mode' => $orderMode,
                    'scheduled_for' => $scheduledFor,
                ]
            );
        } else {
            $vendorNotificationRows[] = $vendorId;
        }
        /* try {
            notifyVendor(
                $con,
                (int)$vendorRow['vendor_id'],
                'vendor_new_order',
                'طلب جديد',
                "تم استلام طلب جديد رقم #$orderId",
                'order',
                (int)$orderId,
                [
                    'order_id' => (string)$orderId,
                    'vendor_id' => (string)$vendorRow['vendor_id'],
                    'user_id' => (string)$usersid,
                    'gift_message' => $giftMessage,
                    'delivery_note' => $deliveryNote,
                    'screen' => 'orders',
                    'order_mode' => $orderMode,
                    'scheduled_for' => $scheduledFor,
                ],
                true
            );
        } catch (Throwable $notificationError) {
            error_log('Vendor checkout notification failed: ' . $notificationError->getMessage());
        } */
        /* sendFCMToTopic(
            'طلب جديد',
            "تم استلام طلب جديد رقم #$orderId",
            'vendor_orders_' . (int)$vendorRow['vendor_id'],
            [
                'type' => 'vendor_new_order',
                'order_id' => (string)$orderId,
                'vendor_id' => (string)$vendorRow['vendor_id'],
                'user_id' => (string)$usersid,
                'gift_message' => $giftMessage,
                'delivery_note' => $deliveryNote,
                'screen' => 'orders',
            ]
        ); */
    }
    if ($couponIdToInsert) {
        $dec = $con->prepare("UPDATE coupon SET coupon_count = coupon_count - 1 WHERE coupon_id = :cid");
        $dec->execute([":cid" => $couponIdToInsert]);
    }
    $del = $con->prepare("DELETE FROM cart WHERE cart_usersid = :uid AND cart_orders = 0");
    $del->execute([":uid" => $usersid]);
    if ($outboxEnabled) {
        enqueueNotificationOutbox(
            $con,
            'user',
            (int)$usersid,
            null,
            'order_created',
            'Order created',
            "Your order #$orderId was received and will be updated step by step.",
            'order',
            (int)$orderId,
            [
                'order_id' => (string)$orderId,
                'order_mode' => $orderMode,
                'scheduled_for' => $scheduledFor,
                'estimated_minutes' => (string)$estimatedMinutes,
                'delivery_code' => $deliveryCode,
                'screen' => 'order_tracking',
            ]
        );
        enqueueNotificationOutbox(
            $con,
            'topic',
            0,
            'admin_orders',
            'admin_new_order',
            'New order',
            "New order received #$orderId",
            'order',
            (int)$orderId,
            [
                'type' => 'admin_new_order',
                'order_id' => (string)$orderId,
                'user_id' => (string)$usersid,
                'gift_message' => $giftMessage,
                'delivery_note' => $deliveryNote,
                'screen' => 'orders',
            ]
        );
    }
    // Some MySQL operations/triggers may implicitly close the transaction.
    // The order has already been persisted in that case, so do not turn a
    // successful checkout into a false error by calling commit() again.
    if ($con->inTransaction()) {
        $con->commit();
    }
    if (!$outboxEnabled) {
    foreach ($vendorNotificationRows as $vendorId) {
        try {
            notifyVendor(
                $con,
                $vendorId,
                'vendor_new_order',
                'Ø·Ù„Ø¨ Ø¬Ø¯ÙŠØ¯',
                "ØªÙ… Ø§Ø³ØªÙ„Ø§Ù… Ø·Ù„Ø¨ Ø¬Ø¯ÙŠØ¯ Ø±Ù‚Ù… #$orderId",
                'order',
                (int)$orderId,
                [
                    'order_id' => (string)$orderId,
                    'vendor_id' => (string)$vendorId,
                    'user_id' => (string)$usersid,
                    'gift_message' => $giftMessage,
                    'delivery_note' => $deliveryNote,
                    'screen' => 'orders',
                    'order_mode' => $orderMode,
                    'scheduled_for' => $scheduledFor,
                ],
                true
            );
        } catch (Throwable $notificationError) {
            error_log('Vendor checkout notification failed: ' . $notificationError->getMessage());
        }
    }
    try {
        notifyUser(
            $con,
            (int)$usersid,
            'order_created',
            'تم إنشاء طلبك',
            "استلمنا طلبك رقم #$orderId وسيتم تحديثك بكل خطوة.",
            'order',
            (int)$orderId,
            [
                'order_id' => (string)$orderId,
                'order_mode' => $orderMode,
                'scheduled_for' => $scheduledFor,
                'estimated_minutes' => (string)$estimatedMinutes,
                'delivery_code' => $deliveryCode,
                'screen' => 'order_tracking',
            ],
            true
        );
    } catch (Throwable $notificationError) {
        error_log('User checkout notification failed: ' . $notificationError->getMessage());
    }
    try {
        sendFCMToTopic(
            'New order',
            "New order received #$orderId",
            'admin_orders',
            [
                'type' => 'admin_new_order',
                'order_id' => (string)$orderId,
                'user_id' => (string)$usersid,
                'gift_message' => $giftMessage,
                'delivery_note' => $deliveryNote,
                'screen' => 'orders',
            ]
        );
    } catch (Throwable $notificationError) {
        error_log('Admin checkout notification failed: ' . $notificationError->getMessage());
    }
    }
    if (ob_get_length() !== false) {
        ob_clean();
    }
    echo json_encode([
        "status" => "success",
        "order_id" => $orderId,
        "share_token" => $shareToken,
        "order_mode" => $orderMode,
        "scheduled_for" => $scheduledFor,
        "estimated_minutes" => $estimatedMinutes,
        "delivery_code" => $deliveryCode,
        "total" => number_format($totalprice, 2, ".", "")
    ]);
} catch (Exception $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    if (ob_get_length() !== false) {
        ob_clean();
    }
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
