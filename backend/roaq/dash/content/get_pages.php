<?php
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $con->query("
        SELECT page_id, page_key, title_ar, title_en, body_ar, body_en, is_active, updated_at
        FROM app_content_pages
        ORDER BY page_id ASC
    ");
    $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];

    echo json_encode([
        'status' => 'success',
        'data' => $rows ?: [],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

