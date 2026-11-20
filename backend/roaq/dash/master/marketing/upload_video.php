<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterMarketingVideoUploadFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

try {
    $admin = requireMasterAuth();
    if (!masterHasPermission($admin, 'marketing.create')
        && !masterHasPermission($admin, 'marketing.edit')) {
        respondJson([
            'status' => 'error',
            'message' => 'Permission denied',
            'required_permission' => 'marketing.create or marketing.edit',
        ], 403);
    }

    if (!isset($_FILES['video_file']) || !is_array($_FILES['video_file'])) {
        masterMarketingVideoUploadFail('video file is required');
    }
    if ((int)($_FILES['video_file']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        masterMarketingVideoUploadFail('video upload failed');
    }

    $size = (int)($_FILES['video_file']['size'] ?? 0);
    if ($size <= 0 || $size > 120 * 1024 * 1024) {
        masterMarketingVideoUploadFail('video file must be less than 120MB');
    }

    $original = (string)($_FILES['video_file']['name'] ?? 'video.mp4');
    $ext = strtolower(pathinfo($original, PATHINFO_EXTENSION));
    $allowed = ['mp4', 'mov', 'webm', 'm4v'];
    if (!in_array($ext, $allowed, true)) {
        masterMarketingVideoUploadFail('unsupported video type');
    }
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file((string)$_FILES['video_file']['tmp_name']);
    $allowedMimes = [
        'video/mp4',
        'video/quicktime',
        'video/webm',
        'video/x-m4v',
        'application/mp4',
    ];
    if (!in_array($mime, $allowedMimes, true)) {
        masterMarketingVideoUploadFail('invalid video content type');
    }

    $root = dirname(__DIR__, 3);
    $relativeDir = 'uploud/video';
    $targetDir = $root . DIRECTORY_SEPARATOR . $relativeDir;
    if (!is_dir($targetDir) && !mkdir($targetDir, 0775, true) && !is_dir($targetDir)) {
        masterMarketingVideoUploadFail('could not create video directory', 500);
    }

    $safeBase = preg_replace('/[^a-zA-Z0-9._-]+/', '_', pathinfo($original, PATHINFO_FILENAME));
    $safeBase = trim((string)$safeBase, '._-');
    if ($safeBase === '') {
        $safeBase = 'video';
    }
    $fileName = 'master_' . time() . '_' . random_int(1000, 9999) . '_' . $safeBase . '.' . $ext;
    $targetPath = $targetDir . DIRECTORY_SEPARATOR . $fileName;

    if (!move_uploaded_file((string)$_FILES['video_file']['tmp_name'], $targetPath)) {
        masterMarketingVideoUploadFail('could not save video file', 500);
    }

    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $basePath = rtrim(dirname(dirname(dirname(dirname($_SERVER['SCRIPT_NAME'] ?? '/roaqv2/dash/master/marketing/upload_video.php')))), '/');
    $videoUrl = $scheme . '://' . ($_SERVER['HTTP_HOST'] ?? 'localhost')
        . $basePath . '/' . $relativeDir . '/' . $fileName;
    respondJson([
        'status' => 'success',
        'message' => 'video uploaded',
        'data' => [
            'video_url' => $videoUrl,
            'path' => $relativeDir . '/' . $fileName,
            'file_name' => $fileName,
        ],
    ]);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
