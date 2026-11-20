<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../../asset_urls.php';

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
        echo json_encode(['status' => false, 'msg' => 'invalid_item'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $table = detectMediaTable($con);
    if ($table === null) {
        echo json_encode(['status' => true, 'data' => []], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
    $rows = fetchMediaRows($con, $itemId);

    foreach ($rows as &$row) {
        $row['file_url'] = zahra_media_file_url($row['file_path'] ?? '');
    }
    unset($row);

    echo json_encode(['status' => true, 'data' => $rows], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'msg' => 'server_error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
