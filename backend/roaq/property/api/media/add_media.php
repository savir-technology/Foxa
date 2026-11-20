<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../../asset_urls.php';

function detectMediaTable(PDO $con): string
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
    if ($table) {
        return (string) $table;
    }

    // Auto-create modern media table if missing.
    $con->exec("
        CREATE TABLE IF NOT EXISTS product_media (
            id INT AUTO_INCREMENT PRIMARY KEY,
            item_id INT NOT NULL,
            file_path VARCHAR(500) NOT NULL,
            media_type ENUM('image','video') NOT NULL,
            sort_order INT DEFAULT 0,
            caption VARCHAR(255) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");
    return 'product_media';
}

try {
    $itemId = intval($_POST['item_id'] ?? 0);
    if ($itemId <= 0 || !isset($_FILES['media'])) {
        echo json_encode(['status' => false, 'msg' => 'invalid_request'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $uploadDir = __DIR__ . '/../../../uploads/items_media/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    $file = $_FILES['media'];
    if (!isset($file['error']) || $file['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(['status' => false, 'msg' => 'upload_error'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $mime = '';
    if (function_exists('finfo_open')) {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo) {
            $detected = finfo_file($finfo, $file['tmp_name']);
            finfo_close($finfo);
            if (is_string($detected)) {
                $mime = $detected;
            }
        }
    }

    $originalName = (string) ($file['name'] ?? '');
    $ext = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
    $imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    $videoExts = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'];

    if (strpos($mime, 'image/') === 0 || in_array($ext, $imageExts, true)) {
        $mediaType = 'image';
        if ($ext === '') $ext = 'jpg';
    } elseif (strpos($mime, 'video/') === 0 || in_array($ext, $videoExts, true)) {
        $mediaType = 'video';
        if ($ext === '') $ext = 'mp4';
    } else {
        echo json_encode([
            'status' => false,
            'msg' => 'unsupported_media_type',
            'mime' => $mime,
            'ext' => $ext,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $filename = uniqid('m_', true) . '.' . $ext;
    $targetPath = $uploadDir . $filename;
    if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
        echo json_encode(['status' => false, 'msg' => 'move_failed'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $relative = 'zahra/uploads/items_media/' . $filename;
    $caption = trim((string) ($_POST['caption'] ?? ''));
    $sortOrder = intval($_POST['sort_order'] ?? 0);
    $table = detectMediaTable($con);

    if ($table === 'product_media') {
        $stmt = $con->prepare("
            INSERT INTO product_media (item_id, file_path, media_type, sort_order, caption)
            VALUES (:item_id, :file_path, :media_type, :sort_order, :caption)
        ");
        $stmt->execute([
            ':item_id' => $itemId,
            ':file_path' => $relative,
            ':media_type' => $mediaType,
            ':sort_order' => $sortOrder,
            ':caption' => ($caption === '' ? null : $caption),
        ]);
        $id = intval($con->lastInsertId());
    } else {
        $stmt = $con->prepare("
            INSERT INTO item_media (item_id, media_url, media_type, is_primary, sort_order)
            VALUES (:item_id, :media_url, :media_type, 0, :sort_order)
        ");
        $stmt->execute([
            ':item_id' => $itemId,
            ':media_url' => $relative,
            ':media_type' => $mediaType,
            ':sort_order' => $sortOrder,
        ]);
        $id = intval($con->lastInsertId());
    }

    echo json_encode([
        'status' => true,
        'data' => [
            'id' => $id,
            'item_id' => $itemId,
            'file_path' => $relative,
            'file_url' => zahra_media_file_url($relative),
            'media_type' => $mediaType,
            'sort_order' => $sortOrder,
            'caption' => ($caption === '' ? null : $caption),
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'msg' => 'server_error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
