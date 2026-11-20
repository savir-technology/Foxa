<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';
require_once '../../../asset_urls.php';

try {
    $itemId = intval($_POST['item_id'] ?? 0);
    if ($itemId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'item_id is required']);
        exit;
    }

    $itemStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = :id LIMIT 1");
    $itemStmt->execute([':id' => $itemId]);
    if (!$itemStmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode(['status' => 'error', 'message' => 'Item not found']);
        exit;
    }

    if (!isset($_FILES['image']) || !isset($_FILES['image']['tmp_name'])) {
        echo json_encode(['status' => 'error', 'message' => 'image is required']);
        exit;
    }

    $tmp = $_FILES['image']['tmp_name'];
    $mime = mime_content_type($tmp);
    if (strpos((string)$mime, 'image/') !== 0) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid image']);
        exit;
    }

    $ext = strtolower(pathinfo($_FILES['image']['name'] ?? 'ad.jpg', PATHINFO_EXTENSION));
    if ($ext === '') {
        $ext = 'jpg';
    }

    $uploadDir = __DIR__ . '/../../../ads/uploud/img/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    $fileName = 'ad2_' . time() . '_' . mt_rand(1000, 9999) . '.' . $ext;
    $target = $uploadDir . $fileName;
    if (!move_uploaded_file($tmp, $target)) {
        echo json_encode(['status' => 'error', 'message' => 'Upload failed']);
        exit;
    }

    $url = zahra_ad_image_url($fileName);
    $stmt = $con->prepare("
        INSERT INTO ads2 (image_url, item_id, created_at)
        VALUES (:image_url, :item_id, NOW())
    ");
    $stmt->execute([
        ':image_url' => $url,
        ':item_id' => $itemId,
    ]);

    echo json_encode([
        'status' => 'success',
        'ad_id' => intval($con->lastInsertId()),
        'image_url' => $url,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
