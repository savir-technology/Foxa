<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../../../connect.php';

$id = intval($_POST['id'] ?? 0);
if ($id <= 0) {
    echo json_encode(['status' => false, 'msg' => 'invalid_id'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function resolveMediaFilePath(string $path): string
{
    $path = trim($path);
    if ($path === '') return '';

    if (stripos($path, 'http://') === 0 || stripos($path, 'https://') === 0) {
        $path = ltrim((string)parse_url($path, PHP_URL_PATH), '/');
    }

    $path = ltrim($path, '/');
    if (stripos($path, 'zahra/') === 0) {
        $path = substr($path, strlen('zahra/'));
    }

    $uploadsPos = stripos($path, 'uploads/items_media/');
    if ($uploadsPos !== false) {
        $path = substr($path, $uploadsPos);
    }

    $main = __DIR__ . '/../../../' . $path;
    if (is_file($main)) return $main;

    $legacy = __DIR__ . '/../../' . $path;
    if (is_file($legacy)) return $legacy;

    return $main;
}

try {
    $foundTable = null;
    $filePath = '';

    $stmt = $con->prepare("SELECT file_path FROM product_media WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row && isset($row['file_path'])) {
        $foundTable = 'product_media';
        $filePath = (string)$row['file_path'];
    } else {
        $stmt = $con->prepare("SELECT media_url FROM item_media WHERE media_id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row && isset($row['media_url'])) {
            $foundTable = 'item_media';
            $filePath = (string)$row['media_url'];
        }
    }

    if ($foundTable === null) {
        echo json_encode(['status' => false, 'msg' => 'not_found'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $physical = resolveMediaFilePath($filePath);
    if ($physical !== '' && is_file($physical)) {
        @unlink($physical);
    }

    if ($foundTable === 'product_media') {
        $del = $con->prepare("DELETE FROM product_media WHERE id = :id");
        $del->execute([':id' => $id]);
    } else {
        $del = $con->prepare("DELETE FROM item_media WHERE media_id = :id");
        $del->execute([':id' => $id]);
    }

    echo json_encode(['status' => true, 'msg' => 'deleted'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'msg' => 'server_error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
