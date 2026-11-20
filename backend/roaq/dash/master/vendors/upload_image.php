<?php
require_once "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $admin = requireMasterAuth();
    $requestedEntity = strtolower(trim((string)($_POST['entity'] ?? '')));
    requireMasterPermission(
        $admin,
        $requestedEntity === 'marketing' ? 'marketing.edit' : 'restaurants.edit'
    );
    $entity = $requestedEntity;
    $folder = match ($entity) {
        'category' => 'categories',
        'product' => 'items',
        'marketing' => 'ads/uploud/img',
        default => throw new RuntimeException('Invalid image type'),
    };
    if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        throw new RuntimeException('لم يتم استلام الصورة');
    }
    $file = $_FILES['image'];
    if ((int)$file['size'] > 8 * 1024 * 1024) throw new RuntimeException('حجم الصورة يجب ألا يتجاوز 8 ميجابايت');
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    $extensions = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'image/gif' => 'gif'];
    if (!isset($extensions[$mime])) throw new RuntimeException('صيغة الصورة غير مدعومة');
    $filename = 'master_' . bin2hex(random_bytes(8)) . '.' . $extensions[$mime];
    $directory = str_starts_with($folder, 'ads/')
        ? __DIR__ . '/../../../' . $folder . '/'
        : __DIR__ . '/../../../uploud/' . $folder . '/';
    if (!is_dir($directory)) mkdir($directory, 0755, true);
    if (!move_uploaded_file($file['tmp_name'], $directory . $filename)) throw new RuntimeException('تعذر حفظ الصورة');
    respondJson([
        'status' => 'success',
        'data' => [
            'filename' => $filename,
            'path' => trim($folder, '/') . '/' . $filename,
        ],
    ]);
} catch (Throwable $error) {
    respondJson(['status' => 'error', 'message' => $error->getMessage()], 400);
}
