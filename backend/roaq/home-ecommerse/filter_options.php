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

function cleanText(string $key): string
{
    return isset($_POST[$key]) ? trim((string) $_POST[$key]) : '';
}

function cleanFloat(string $key): ?float
{
    if (!isset($_POST[$key])) return null;
    $raw = trim((string) $_POST[$key]);
    if ($raw === '') return null;
    $raw = str_replace(',', '', $raw);
    return is_numeric($raw) ? (float) $raw : null;
}

function cleanInt(string $key): ?int
{
    if (!isset($_POST[$key])) return null;
    $raw = trim((string) $_POST[$key]);
    if ($raw === '') return null;
    return is_numeric($raw) ? (int) $raw : null;
}

try {
    $hasOwnershipType = hasColumn($con, 'items', 'ownership_type');

    $assetKind = cleanText('asset_kind');
    $city = cleanText('city');
    $durationMonths = cleanInt('duration_months');
    $propertyType = cleanText('property_type');
    $ownershipType = cleanText('ownership_type');
    $minPrice = cleanFloat('min_price');
    $maxPrice = cleanFloat('max_price');
    $area = cleanFloat('area');
    $rooms = cleanInt('rooms');
    $bathrooms = cleanInt('bathrooms');
    $floor = cleanInt('floor');

    $allowedKinds = ['', 'property', 'land', 'apartment', 'shop', 'villa', 'office', 'restaurant'];
    if (!in_array($assetKind, $allowedKinds, true)) {
        $assetKind = '';
    }

    if ($minPrice !== null && $maxPrice !== null && $minPrice > 0 && $maxPrice > 0 && $minPrice > $maxPrice) {
        [$minPrice, $maxPrice] = [$maxPrice, $minPrice];
    }

    $basePriceExpr = "COALESCE((
            SELECT MIN(pp.total_price)
            FROM property_plans pp
            WHERE pp.item_id = i.items_id
              AND pp.is_active = 1
              AND pp.total_price IS NOT NULL
              AND pp.total_price > 0
        ), i.items_price)";

    $where = ["i.items_active = 1"];
    $params = [];

    if ($assetKind !== '') {
        $where[] = "i.asset_kind = ?";
        $params[] = $assetKind;
    }

    if ($city !== '') {
        $where[] = "i.property_address LIKE ?";
        $params[] = '%' . $city . '%';
    }

    if ($durationMonths !== null && $durationMonths > 0) {
        $where[] = "EXISTS (
            SELECT 1
            FROM property_plans p
            WHERE p.item_id = i.items_id
              AND p.is_active = 1
              AND p.duration_months = ?
        )";
        $params[] = $durationMonths;
    }

    if ($minPrice !== null && $minPrice > 0) {
        if ($durationMonths !== null && $durationMonths > 0) {
            $where[] = "COALESCE((
                    SELECT pp.total_price
                    FROM property_plans pp
                    WHERE pp.item_id = i.items_id
                      AND pp.is_active = 1
                      AND pp.duration_months = ?
                    ORDER BY pp.plan_id ASC
                    LIMIT 1
                ), $basePriceExpr) >= ?";
            $params[] = $durationMonths;
            $params[] = $minPrice;
        } else {
            $where[] = "$basePriceExpr >= ?";
            $params[] = $minPrice;
        }
    }

    if ($maxPrice !== null && $maxPrice > 0) {
        if ($durationMonths !== null && $durationMonths > 0) {
            $where[] = "COALESCE((
                    SELECT pp.total_price
                    FROM property_plans pp
                    WHERE pp.item_id = i.items_id
                      AND pp.is_active = 1
                      AND pp.duration_months = ?
                    ORDER BY pp.plan_id ASC
                    LIMIT 1
                ), $basePriceExpr) <= ?";
            $params[] = $durationMonths;
            $params[] = $maxPrice;
        } else {
            $where[] = "$basePriceExpr <= ?";
            $params[] = $maxPrice;
        }
    }

    if ($propertyType !== '') {
        $where[] = "(TRIM(c.categories_name_ar) LIKE TRIM(?) OR TRIM(c.categories_name_en) LIKE TRIM(?))";
        $params[] = '%' . $propertyType . '%';
        $params[] = '%' . $propertyType . '%';
    }

    if ($hasOwnershipType && $ownershipType !== '') {
        $where[] = "TRIM(i.ownership_type) = TRIM(?)";
        $params[] = $ownershipType;
    }

    if (($assetKind === '' || in_array($assetKind, ['property', 'apartment', 'villa', 'office', 'shop', 'restaurant'], true)) && $rooms !== null && $rooms > 0) {
        $where[] = "i.property_rooms = ?";
        $params[] = $rooms;
    }

    if (($assetKind === '' || in_array($assetKind, ['property', 'apartment', 'villa', 'office', 'shop', 'restaurant'], true)) && $bathrooms !== null && $bathrooms > 0) {
        $where[] = "i.property_bathrooms = ?";
        $params[] = $bathrooms;
    }

    if (($assetKind === '' || in_array($assetKind, ['property', 'apartment', 'villa', 'office', 'shop', 'restaurant'], true)) && $floor !== null && $floor > 0) {
        $where[] = "i.property_floor = ?";
        $params[] = $floor;
    }

    if (($assetKind === '' || $assetKind === 'land') && $area !== null && $area > 0) {
        $where[] = "i.property_area >= ?";
        $params[] = $area;
    }

    $whereSql = implode("\n AND ", $where);

    $citiesStmt = $con->prepare("
        SELECT DISTINCT TRIM(i.property_address) AS city
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
          AND i.property_address IS NOT NULL
          AND i.property_address <> ''
        ORDER BY city ASC
    ");
    $citiesStmt->execute($params);
    $cities = $citiesStmt->fetchAll(PDO::FETCH_COLUMN);

    $durStmt = $con->prepare("
        SELECT DISTINCT pp.duration_months
        FROM property_plans pp
        INNER JOIN items i ON i.items_id = pp.item_id
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE pp.is_active = 1
          AND $whereSql
        ORDER BY pp.duration_months ASC
    ");
    $durStmt->execute($params);
    $durations = $durStmt->fetchAll(PDO::FETCH_COLUMN);

    $typesStmt = $con->prepare("
        SELECT DISTINCT TRIM(c.categories_name_ar) AS category_name
        FROM categories c
        INNER JOIN items i ON i.items_cat = c.categories_id
        WHERE $whereSql
          AND c.categories_name_ar IS NOT NULL
          AND c.categories_name_ar <> ''
        ORDER BY category_name ASC
    ");
    $typesStmt->execute($params);
    $propertyTypes = $typesStmt->fetchAll(PDO::FETCH_COLUMN);

    $assetKindsStmt = $con->prepare("
        SELECT DISTINCT i.asset_kind
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
          AND i.asset_kind IN ('property', 'land', 'apartment', 'shop', 'villa', 'office', 'restaurant')
        ORDER BY i.asset_kind ASC
    ");
    $assetKindsStmt->execute($params);
    $assetKinds = $assetKindsStmt->fetchAll(PDO::FETCH_COLUMN);

    $roomsStmt = $con->prepare("
        SELECT DISTINCT i.property_rooms
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
          AND i.property_rooms IS NOT NULL
          AND i.property_rooms > 0
        ORDER BY i.property_rooms ASC
    ");
    $roomsStmt->execute($params);
    $roomsList = $roomsStmt->fetchAll(PDO::FETCH_COLUMN);

    $bathStmt = $con->prepare("
        SELECT DISTINCT i.property_bathrooms
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
          AND i.property_bathrooms IS NOT NULL
          AND i.property_bathrooms > 0
        ORDER BY i.property_bathrooms ASC
    ");
    $bathStmt->execute($params);
    $bathroomsList = $bathStmt->fetchAll(PDO::FETCH_COLUMN);

    $floorStmt = $con->prepare("
        SELECT DISTINCT i.property_floor
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
          AND i.property_floor IS NOT NULL
          AND i.property_floor > 0
        ORDER BY i.property_floor ASC
    ");
    $floorStmt->execute($params);
    $floors = $floorStmt->fetchAll(PDO::FETCH_COLUMN);

    $areasStmt = $con->prepare("
        SELECT DISTINCT i.property_area
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
          AND i.property_area IS NOT NULL
          AND i.property_area > 0
        ORDER BY i.property_area ASC
    ");
    $areasStmt->execute($params);
    $areas = $areasStmt->fetchAll(PDO::FETCH_COLUMN);

    $ownershipTypes = [];
    if ($hasOwnershipType) {
        $ownershipStmt = $con->prepare("
            SELECT DISTINCT TRIM(i.ownership_type) AS ownership_type
            FROM items i
            INNER JOIN categories c ON c.categories_id = i.items_cat
            WHERE $whereSql
              AND i.ownership_type IS NOT NULL
              AND i.ownership_type <> ''
            ORDER BY ownership_type ASC
        ");
        $ownershipStmt->execute($params);
        $ownershipTypes = $ownershipStmt->fetchAll(PDO::FETCH_COLUMN);
    }
    if (empty($ownershipTypes)) {
        $ownershipTypes = ['طابو أخضر', 'حكم محكمة', 'وكالة'];
    }

    $priceRangeStmt = $con->prepare("
        SELECT
            MIN($basePriceExpr) AS min_effective_price,
            MAX($basePriceExpr) AS max_effective_price
        FROM items i
        INNER JOIN categories c ON c.categories_id = i.items_cat
        WHERE $whereSql
    ");
    $priceRangeStmt->execute($params);
    $priceRange = $priceRangeStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    echo json_encode([
        "status" => "success",
        "asset_kind_context" => $assetKind,
        "cities" => array_values(array_filter(array_map('strval', $cities))),
        "durations" => array_values(array_map('strval', $durations)),
        "asset_kinds" => array_values(array_filter(array_map('strval', $assetKinds))),
        "property_types" => array_values(array_filter(array_map('strval', $propertyTypes))),
        "ownership_types" => array_values(array_filter(array_map('strval', $ownershipTypes))),
        "rooms" => array_values(array_map('strval', $roomsList)),
        "bathrooms" => array_values(array_map('strval', $bathroomsList)),
        "floors" => array_values(array_map('strval', $floors)),
        "areas" => array_values(array_map('strval', $areas)),
        "price_range" => [
            "min" => isset($priceRange['min_effective_price']) ? (float) $priceRange['min_effective_price'] : 0,
            "max" => isset($priceRange['max_effective_price']) ? (float) $priceRange['max_effective_price'] : 0,
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "failure",
        "message" => "Failed to load filter options",
        "error" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
