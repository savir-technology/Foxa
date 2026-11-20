<?php
include "../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
function decodeJsonList($value)
{
    if (is_array($value)) {
        return array_values($value);
    }
    if (!is_string($value) || trim($value) === '') {
        return [];
    }
    $decoded = json_decode($value, true);
    return is_array($decoded) ? array_values($decoded) : [];
}
function legalDocumentRowToArray(array $row)
{
    return [
        'document_key' => $row['document_key'] ?? '',
        'document_type' => $row['document_type'] ?? 'policy',
        'title_ar' => $row['title_ar'] ?? '',
        'title_en' => $row['title_en'] ?? '',
        'subtitle_ar' => $row['subtitle_ar'] ?? null,
        'subtitle_en' => $row['subtitle_en'] ?? null,
        'summary_ar' => decodeJsonList($row['summary_ar_json'] ?? null),
        'summary_en' => decodeJsonList($row['summary_en_json'] ?? null),
        'content_ar' => $row['content_ar'] ?? '',
        'content_en' => $row['content_en'] ?? '',
        'accent_color' => $row['accent_color'] ?? null,
        'hero_icon' => $row['hero_icon'] ?? null,
        'sort_order' => isset($row['sort_order']) ? (int)$row['sort_order'] : 0,
        'is_active' => isset($row['is_active']) ? (int)$row['is_active'] : 1,
        'created_at' => $row['created_at'] ?? null,
        'updated_at' => $row['updated_at'] ?? null,
    ];
}
try {
    $documentKey = strtolower(trim((string)($_GET['key'] ?? $_GET['document_key'] ?? '')));
    if ($documentKey !== '') {
        $stmt = $con->prepare("
            SELECT *
            FROM app_legal_documents
            WHERE document_key = :document_key
              AND is_active = 1
            LIMIT 1
        ");
        $stmt->execute([':document_key' => $documentKey]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            respondJson([
                'status' => 'failure',
                'message' => 'Document not found',
            ], 404);
        }
        respondJson([
            'status' => 'success',
            'document' => legalDocumentRowToArray($row),
        ]);
    }
    $stmt = $con->query("
        SELECT *
        FROM app_legal_documents
        WHERE is_active = 1
        ORDER BY sort_order ASC, document_id ASC
    ");
    $documents = [];
    if ($stmt) {
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $documents[] = legalDocumentRowToArray($row);
        }
    }
    respondJson([
        'status' => 'success',
        'documents' => $documents,
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}