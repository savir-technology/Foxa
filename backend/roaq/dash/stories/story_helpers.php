<?php

function storyMediaUploadDir()
{
    return __DIR__ . "/uploud/media/";
}

function storyMediaBaseUrl()
{
    return "https://savir-technology.online/roaqv2/dash/stories/uploud/media/";
}

function storyEnsureUploadDir()
{
    $uploadDir = storyMediaUploadDir();
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
}

function storyFailResponse($message, $code = 400)
{
    http_response_code($code);
    echo json_encode([
        "status" => "failure",
        "message" => $message,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function storyNormalizeDateTimeInput($value)
{
    $value = trim((string) $value);
    if ($value === '') {
        return null;
    }

    $normalized = str_replace('T', ' ', $value);
    if (strlen($normalized) === 16) {
        $normalized .= ':00';
    }

    return $normalized;
}

function storyResolveMediaUrl($value)
{
    $raw = trim((string) $value);
    if ($raw === '') {
        return '';
    }

    if (strpos($raw, 'http://') === 0 ||
        strpos($raw, 'https://') === 0 ||
        strpos($raw, 'data:') === 0) {
        return $raw;
    }

    $normalized = ltrim(str_replace('\\', '/', $raw), '/');
    if (strpos($normalized, 'uploads/') === 0 || strpos($normalized, 'uploud/') === 0) {
        return 'https://savir-technology.online/roaqv2/' . $normalized;
    }

    return storyMediaBaseUrl() . $normalized;
}

function storyDeleteLocalMedia($url)
{
    $url = trim((string) $url);
    if ($url === '' || strpos($url, storyMediaBaseUrl()) !== 0) {
        return;
    }

    $localPath = storyMediaUploadDir() . basename($url);
    if (file_exists($localPath)) {
        unlink($localPath);
    }
}

function storyUploadMediaFile(array $file, string $prefix)
{
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        storyFailResponse('Failed to upload media');
    }

    $extension = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov', 'm4v', 'webm'];
    if (!in_array($extension, $allowed, true)) {
        storyFailResponse('Unsupported media format');
    }

    storyEnsureUploadDir();

    $fileName = $prefix . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
    $targetPath = storyMediaUploadDir() . $fileName;

    if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
        storyFailResponse('Failed to save media file');
    }

    return storyMediaBaseUrl() . $fileName;
}
