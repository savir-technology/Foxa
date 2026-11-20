<?php
require_once '../../connect.php';
require_once '../../asset_urls.php';
header('Content-Type: application/json; charset=utf-8');

function hasColumn(PDO $con, string $table, string $column): bool
{
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table
          AND COLUMN_NAME = :column
    ");
    $stmt->execute([':table' => $table, ':column' => $column]);
    return ((int) $stmt->fetchColumn()) > 0;
}

function detectMediaTable(PDO $con): ?string
{
    $stmt = $con->query("
        SELECT TABLE_NAME
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME IN ('product_media', 'item_media')
        ORDER BY FIELD(TABLE_NAME, 'product_media', 'item_media')
        LIMIT 1
    ");
    $table = $stmt ? $stmt->fetchColumn() : null;
    return $table ? (string) $table : null;
}

function tableExists(PDO $con, string $table): bool
{
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table
    ");
    $stmt->execute([':table' => $table]);
    return ((int) $stmt->fetchColumn()) > 0;
}

function fetchMediaRows(PDO $con, int $itemId): array
{
    $rows = [];

    if (tableExists($con, 'product_media')) {
        $stmt = $con->prepare("
            SELECT id, item_id, file_path, media_type, sort_order, caption, created_at
            FROM product_media
            WHERE item_id = :item_id
            ORDER BY sort_order ASC, id ASC
        ");
        $stmt->execute([':item_id' => $itemId]);
        $rows = array_merge($rows, $stmt->fetchAll(PDO::FETCH_ASSOC) ?: []);
    }

    if (tableExists($con, 'item_media')) {
        $stmt = $con->prepare("
            SELECT media_id AS id,
                   item_id,
                   media_url AS file_path,
                   media_type,
                   sort_order,
                   NULL AS caption,
                   NULL AS created_at
            FROM item_media
            WHERE item_id = :item_id
            ORDER BY sort_order ASC, media_id ASC
        ");
        $stmt->execute([':item_id' => $itemId]);
        $rows = array_merge($rows, $stmt->fetchAll(PDO::FETCH_ASSOC) ?: []);
    }

    $seen = [];
    $unique = [];
    foreach ($rows as $row) {
        $path = trim((string) ($row['file_path'] ?? ''));
        $type = strtolower(trim((string) ($row['media_type'] ?? 'image')));
        if ($path === '') {
            continue;
        }
        $key = strtolower($path) . '|' . $type;
        if (isset($seen[$key])) {
            continue;
        }
        $seen[$key] = true;
        $unique[] = $row;
    }

    usort($unique, function ($a, $b) {
        $orderCompare =
            intval($a['sort_order'] ?? 0) <=> intval($b['sort_order'] ?? 0);
        if ($orderCompare !== 0) {
            return $orderCompare;
        }
        return intval($a['id'] ?? 0) <=> intval($b['id'] ?? 0);
    });

    return $unique;
}

try {
    $itemId = intval($_GET['item_id'] ?? 0);
    if ($itemId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid item_id'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $hasAssetKind = hasColumn($con, 'items', 'asset_kind');
    $hasOwnershipType = hasColumn($con, 'items', 'ownership_type');
    $hasPropertyStatus = hasColumn($con, 'items', 'property_status');
    $hasFinishingStatus = hasColumn($con, 'items', 'finishing_status');

    $itemSql = "
        SELECT
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            i.items_image,
            i.items_price,
            i.items_discount,
            i.items_active,
            i.items_date,
            i.items_cat,
            " . ($hasAssetKind ? "i.asset_kind" : "NULL AS asset_kind") . ",
            " . ($hasOwnershipType ? "i.ownership_type" : "NULL AS ownership_type") . ",
            i.property_rooms,
            i.property_bathrooms,
            i.property_floor,
            i.property_area,
            i.property_address,
            i.property_lat,
            i.property_lng,
            " . ($hasPropertyStatus ? "i.property_status" : "NULL AS property_status") . ",
            " . ($hasFinishingStatus ? "i.finishing_status" : "NULL AS finishing_status") . "
        FROM items i
        WHERE i.items_id = :item_id
        LIMIT 1
    ";

    $itemStmt = $con->prepare($itemSql);
    $itemStmt->execute([':item_id' => $itemId]);
    $item = $itemStmt->fetch(PDO::FETCH_ASSOC);
    if (!$item) {
        echo json_encode(['status' => 'failure', 'message' => 'Item not found'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $media = [];
    $mediaTable = detectMediaTable($con);
    if ($mediaTable !== null) {
        $media = fetchMediaRows($con, $itemId);
    }

    foreach ($media as &$m) {
        $path = trim((string) ($m['file_path'] ?? ''));
        if ($path === '') {
            $m['file_url'] = '';
            continue;
        }
        $m['file_url'] = zahra_media_file_url($path);
    }
    unset($m);

    $item['items_image_url'] = zahra_item_image_url($item['items_image'] ?? '');

    $plans = [];
    $hasPlanType = hasColumn($con, 'property_plans', 'plan_type');
    $hasInstallmentAmount = hasColumn($con, 'property_plans', 'installment_amount');
    $hasStartDate = hasColumn($con, 'property_plans', 'start_date');

    $plansSql = "
        SELECT
            plan_id,
            " . ($hasPlanType ? "plan_type" : "'monthly' AS plan_type") . ",
            duration_months,
            total_price,
            down_payment,
            " . ($hasInstallmentAmount ? "installment_amount" : "ROUND((COALESCE(total_price,0)-COALESCE(down_payment,0))/NULLIF(duration_months,0),2) AS installment_amount") . ",
            " . ($hasStartDate ? "start_date" : "NULL AS start_date") . ",
            is_active
        FROM property_plans
        WHERE item_id = :item_id
          AND is_active = 1
        ORDER BY duration_months ASC, plan_id ASC
    ";
    $plansStmt = $con->prepare($plansSql);
    $plansStmt->execute([':item_id' => $itemId]);
    $plans = $plansStmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    echo json_encode([
        'status' => 'success',
        'item' => $item,
        'media' => $media,
        'images' => array_values(array_filter($media, fn($x) => ($x['media_type'] ?? '') === 'image')),
        'videos' => array_values(array_filter($media, fn($x) => ($x['media_type'] ?? '') === 'video')),
        'plans' => $plans,
        'property_specs' => [
            'rooms' => $item['property_rooms'] ?? null,
            'bathrooms' => $item['property_bathrooms'] ?? null,
            'floor' => $item['property_floor'] ?? null,
            'area' => $item['property_area'] ?? null,
            'property_status' => $item['property_status'] ?? null,
            'finishing_status' => $item['finishing_status'] ?? null,
        ],
        'location' => [
            'address' => $item['property_address'] ?? null,
            'lat' => isset($item['property_lat']) ? floatval($item['property_lat']) : 0,
            'lng' => isset($item['property_lng']) ? floatval($item['property_lng']) : 0,
            'has_location' => !empty($item['property_lat']) && !empty($item['property_lng']),
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    error_log('get_item_with_media.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
