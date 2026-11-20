<?php
require_once '../connect.php';
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

$pageKey = trim((string) ($_GET['page_key'] ?? $_POST['page_key'] ?? ''));
$lang = strtolower(trim((string) ($_GET['lang'] ?? $_POST['lang'] ?? 'ar')));
if ($pageKey === '') {
    echo json_encode([
        'status' => 'fail',
        'message' => 'Missing page_key',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

if (!in_array($lang, ['ar', 'en'], true)) {
    $lang = 'ar';
}

try {
    $stmt = $con->prepare("
        SELECT page_id, page_key, title_ar, title_en, body_ar, body_en, is_active, updated_at
        FROM app_content_pages
        WHERE page_key = :page_key
        LIMIT 1
    ");
    $stmt->execute([':page_key' => $pageKey]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row || (int) ($row['is_active'] ?? 0) !== 1) {
        echo json_encode([
            'status' => 'not_found',
            'message' => 'Page not found',
            'data' => null,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $title = $lang === 'en' ? (string) ($row['title_en'] ?? '') : (string) ($row['title_ar'] ?? '');
    $body = $lang === 'en' ? (string) ($row['body_en'] ?? '') : (string) ($row['body_ar'] ?? '');

    if ($title === '') {
        $title = (string) ($row['title_ar'] ?? $row['title_en'] ?? '');
    }
    if ($body === '') {
        $body = (string) ($row['body_ar'] ?? $row['body_en'] ?? '');
    }

    echo json_encode([
        'status' => 'success',
        'data' => [
            'page_id' => (int) ($row['page_id'] ?? 0),
            'page_key' => (string) ($row['page_key'] ?? ''),
            'title' => $title,
            'body' => $body,
            'title_ar' => (string) ($row['title_ar'] ?? ''),
            'title_en' => (string) ($row['title_en'] ?? ''),
            'body_ar' => (string) ($row['body_ar'] ?? ''),
            'body_en' => (string) ($row['body_en'] ?? ''),
            'updated_at' => (string) ($row['updated_at'] ?? ''),
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('content/get_page.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

