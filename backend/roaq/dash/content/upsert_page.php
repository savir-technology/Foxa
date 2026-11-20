<?php
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    $input = $_POST;
}

$pageKey = trim((string) ($input['page_key'] ?? ''));
$titleAr = trim((string) ($input['title_ar'] ?? ''));
$titleEn = trim((string) ($input['title_en'] ?? ''));
$bodyAr = (string) ($input['body_ar'] ?? '');
$bodyEn = (string) ($input['body_en'] ?? '');
$isActive = isset($input['is_active']) ? (int) $input['is_active'] : 1;

if ($pageKey === '' || $titleAr === '' || $titleEn === '') {
    echo json_encode([
        'status' => 'error',
        'message' => 'Missing required fields',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

if ($isActive !== 0 && $isActive !== 1) {
    $isActive = 1;
}

try {
    $stmt = $con->prepare("
        INSERT INTO app_content_pages (page_key, title_ar, title_en, body_ar, body_en, is_active)
        VALUES (:page_key, :title_ar, :title_en, :body_ar, :body_en, :is_active)
        ON DUPLICATE KEY UPDATE
            title_ar = VALUES(title_ar),
            title_en = VALUES(title_en),
            body_ar = VALUES(body_ar),
            body_en = VALUES(body_en),
            is_active = VALUES(is_active)
    ");
    $ok = $stmt->execute([
        ':page_key' => $pageKey,
        ':title_ar' => $titleAr,
        ':title_en' => $titleEn,
        ':body_ar' => $bodyAr,
        ':body_en' => $bodyEn,
        ':is_active' => $isActive,
    ]);

    echo json_encode([
        'status' => $ok ? 'success' : 'error',
        'message' => $ok ? 'saved' : 'failed',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

