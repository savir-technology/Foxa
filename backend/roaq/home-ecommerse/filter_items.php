<?php
include "../connect.php";

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

function hasColumn(PDO $con, string $table, string $column): bool
{
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table
          AND COLUMN_NAME = :column
    ");
    $stmt->execute([
        ':table' => $table,
        ':column' => $column,
    ]);
    return ((int) $stmt->fetchColumn()) > 0;
}

$city = isset($_POST['city']) ? trim((string) $_POST['city']) : '';
$minPrice = isset($_POST['min_price']) ? (float) $_POST['min_price'] : null;
$maxPrice = isset($_POST['max_price']) ? (float) $_POST['max_price'] : null;
$durationMonths = isset($_POST['duration_months']) ? (int) $_POST['duration_months'] : null;
$propertyType = isset($_POST['property_type']) ? trim((string) $_POST['property_type']) : '';
$ownershipType = isset($_POST['ownership_type']) ? trim((string) $_POST['ownership_type']) : '';
$assetKind = isset($_POST['asset_kind']) ? trim((string) $_POST['asset_kind']) : '';
$area = isset($_POST['area']) ? (float) $_POST['area'] : null;
$rooms = isset($_POST['rooms']) ? (int) $_POST['rooms'] : null;
$bathrooms = isset($_POST['bathrooms']) ? (int) $_POST['bathrooms'] : null;
$floor = isset($_POST['floor']) ? (int) $_POST['floor'] : null;
$debug = isset($_POST['debug']) && (string) $_POST['debug'] === '1';

try {
    $hasOwnershipType = hasColumn($con, 'items', 'ownership_type');

    if ($minPrice !== null && $maxPrice !== null && $minPrice > 0 && $maxPrice > 0 && $minPrice > $maxPrice) {
        [$minPrice, $maxPrice] = [$maxPrice, $minPrice];
    }

    $allowedKinds = ['', 'property', 'land', 'apartment', 'shop', 'villa', 'office', 'restaurant'];
    if (!in_array($assetKind, $allowedKinds, true)) {
        $assetKind = '';
    }

    $sql = "
        SELECT
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            COALESCE((
                SELECT pm.file_path
                FROM product_media pm
                WHERE pm.item_id = i.items_id AND pm.media_type = 'image'
                ORDER BY pm.sort_order ASC, pm.id ASC
                LIMIT 1
            ), i.items_image) AS items_image,
            i.items_count,
            i.items_active,
            i.items_price,
            i.items_discount,
            ROUND((i.items_price * i.items_discount) / 100, 2) AS items_discount_price,
            i.items_date,
            i.items_cat,
            i.asset_kind,
            " . ($hasOwnershipType ? "i.ownership_type" : "NULL AS ownership_type") . ",
            i.property_rooms,
            i.property_bathrooms,
            i.property_floor,
            i.property_area,
            i.property_address,
            (
                SELECT pp.duration_months
                FROM property_plans pp
                WHERE pp.item_id = i.items_id AND pp.is_active = 1
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS plan_duration_months,
            COALESCE((
                SELECT pp.down_payment
                FROM property_plans pp
                WHERE pp.item_id = i.items_id AND pp.is_active = 1
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ), ROUND(i.items_price * 0.20, 2)) AS plan_down_payment,
            COALESCE((
                SELECT pp.total_price
                FROM property_plans pp
                WHERE pp.item_id = i.items_id AND pp.is_active = 1
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ), i.items_price) AS plan_total_price,
            COALESCE((
                SELECT pp.total_price
                FROM property_plans pp
                WHERE pp.item_id = i.items_id AND pp.is_active = 1
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ), i.items_price) AS display_price,
            COALESCE((
                SELECT pp.down_payment
                FROM property_plans pp
                WHERE pp.item_id = i.items_id AND pp.is_active = 1
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ), ROUND(i.items_price * 0.20, 2)) AS display_down_payment,
            (
                SELECT pp.duration_months
                FROM property_plans pp
                WHERE pp.item_id = i.items_id AND pp.is_active = 1
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS display_duration_months,
            (
                SELECT pp.duration_months
                FROM property_plans pp
                WHERE pp.item_id = i.items_id
                  AND pp.is_active = 1
                  AND LOWER(TRIM(pp.plan_type)) IN ('yearly', 'annual', 'سنوي')
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS yearly_duration_months,
            (
                SELECT pp.down_payment
                FROM property_plans pp
                WHERE pp.item_id = i.items_id
                  AND pp.is_active = 1
                  AND LOWER(TRIM(pp.plan_type)) IN ('yearly', 'annual', 'سنوي')
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS yearly_down_payment,
            (
                SELECT pp.total_price
                FROM property_plans pp
                WHERE pp.item_id = i.items_id
                  AND pp.is_active = 1
                  AND LOWER(TRIM(pp.plan_type)) IN ('yearly', 'annual', 'سنوي')
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS yearly_price,
            (
                SELECT pp.duration_months
                FROM property_plans pp
                WHERE pp.item_id = i.items_id
                  AND pp.is_active = 1
                  AND LOWER(TRIM(pp.plan_type)) IN ('monthly', 'month', 'شهري')
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS monthly_duration_months,
            (
                SELECT pp.down_payment
                FROM property_plans pp
                WHERE pp.item_id = i.items_id
                  AND pp.is_active = 1
                  AND LOWER(TRIM(pp.plan_type)) IN ('monthly', 'month', 'شهري')
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS monthly_down_payment,
            (
                SELECT pp.total_price
                FROM property_plans pp
                WHERE pp.item_id = i.items_id
                  AND pp.is_active = 1
                  AND LOWER(TRIM(pp.plan_type)) IN ('monthly', 'month', 'شهري')
                ORDER BY pp.duration_months ASC, pp.plan_id ASC
                LIMIT 1
            ) AS monthly_price,
            c.categories_id,
            c.categories_name_en,
            c.categories_name_ar,
            c.categories_image,
            c.categories_datetime
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE i.items_active = 1
    ";

    $params = [];

    $basePriceExpr = "COALESCE((
            SELECT MIN(pp.total_price)
            FROM property_plans pp
            WHERE pp.item_id = i.items_id
              AND pp.is_active = 1
              AND pp.total_price IS NOT NULL
              AND pp.total_price > 0
        ), i.items_price)";

    if ($city !== '') {
        $sql .= " AND i.property_address LIKE ? ";
        $params[] = '%' . $city . '%';
    }

    if ($assetKind !== '') {
        $sql .= " AND i.asset_kind = ? ";
        $params[] = $assetKind;
    }

    if ($durationMonths !== null && $durationMonths > 0) {
        $sql .= "
            AND EXISTS (
                SELECT 1
                FROM property_plans p
                WHERE p.item_id = i.items_id
                  AND p.is_active = 1
                  AND p.duration_months = ?
            )
        ";
        $params[] = $durationMonths;
    }

    if ($minPrice !== null && $minPrice > 0) {
        if ($durationMonths !== null && $durationMonths > 0) {
            $sql .= " AND COALESCE((
                        SELECT pp.total_price
                        FROM property_plans pp
                        WHERE pp.item_id = i.items_id
                          AND pp.is_active = 1
                          AND pp.duration_months = ?
                        ORDER BY pp.plan_id ASC
                        LIMIT 1
                    ), $basePriceExpr) >= ? ";
            $params[] = $durationMonths;
        } else {
            $sql .= " AND $basePriceExpr >= ? ";
        }
        $params[] = $minPrice;
    }

    if ($maxPrice !== null && $maxPrice > 0) {
        if ($durationMonths !== null && $durationMonths > 0) {
            $sql .= " AND COALESCE((
                        SELECT pp.total_price
                        FROM property_plans pp
                        WHERE pp.item_id = i.items_id
                          AND pp.is_active = 1
                          AND pp.duration_months = ?
                        ORDER BY pp.plan_id ASC
                        LIMIT 1
                    ), $basePriceExpr) <= ? ";
            $params[] = $durationMonths;
        } else {
            $sql .= " AND $basePriceExpr <= ? ";
        }
        $params[] = $maxPrice;
    }

    if ($propertyType !== '') {
        $sql .= " AND (
                    TRIM(c.categories_name_ar) LIKE TRIM(?)
                    OR TRIM(c.categories_name_en) LIKE TRIM(?)
                ) ";
        $params[] = '%' . $propertyType . '%';
        $params[] = '%' . $propertyType . '%';
    }

    if ($hasOwnershipType && $ownershipType !== '') {
        $sql .= " AND TRIM(i.ownership_type) = TRIM(?) ";
        $params[] = $ownershipType;
    }

    if (($assetKind === '' || in_array($assetKind, ['property', 'apartment', 'villa', 'office', 'shop', 'restaurant'], true)) && $rooms !== null && $rooms > 0) {
        $sql .= " AND i.property_rooms = ? ";
        $params[] = $rooms;
    }

    if (($assetKind === '' || in_array($assetKind, ['property', 'apartment', 'villa', 'office', 'shop', 'restaurant'], true)) && $bathrooms !== null && $bathrooms > 0) {
        $sql .= " AND i.property_bathrooms = ? ";
        $params[] = $bathrooms;
    }

    if (($assetKind === '' || in_array($assetKind, ['property', 'apartment', 'villa', 'office', 'shop', 'restaurant'], true)) && $floor !== null && $floor > 0) {
        $sql .= " AND i.property_floor = ? ";
        $params[] = $floor;
    }

    if (($assetKind === '' || $assetKind === 'land') && $area !== null && $area > 0) {
        $sql .= " AND i.property_area >= ? ";
        $params[] = $area;
    }

    $sql .= " ORDER BY i.items_date DESC LIMIT 80 ";

    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $response = [
        "status" => "success",
        "count" => count($data),
        "data" => $data,
        "applied_filters" => [
            "city" => $city,
            "asset_kind" => $assetKind,
            "min_price" => $minPrice,
            "max_price" => $maxPrice,
            "duration_months" => $durationMonths,
            "property_type" => $propertyType,
            "ownership_type" => $ownershipType,
            "area" => $area,
            "rooms" => $rooms,
            "bathrooms" => $bathrooms,
            "floor" => $floor,
        ],
    ];

    if ($debug) {
        $response["debug"] = [
            "sql" => $sql,
            "params" => $params,
        ];
    }

    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "failure",
        "message" => "Failed to filter items",
        "error" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
