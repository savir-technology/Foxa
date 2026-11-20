<?php

function zahra_origin(): string
{
    return 'https://savir-technology.online';
}

function zahra_base_url(): string
{
    return zahra_origin() . '/roaq';
}

function zahra_strip_leading_slashes(string $value): string
{
    return ltrim(trim($value), '/\\');
}

function zahra_strip_leading_store_prefix(string $value): string
{
    $clean = zahra_strip_leading_slashes($value);
    if (stripos($clean, 'zahra/') === 0) {
        return substr($clean, strlen('zahra/'));
    }
    return $clean;
}

function zahra_normalize_absolute_url(string $url): string
{
    $trimmed = trim($url);
    if ($trimmed === '') {
        return '';
    }

    $parts = parse_url($trimmed);
    $path = $parts['path'] ?? '';
    if ($path === '') {
        return $trimmed;
    }

    $path = str_replace('\\', '/', $path);
    $zahraPos = stripos($path, '/zahra/');
    if ($zahraPos !== false) {
        return zahra_base_url() . '/' . ltrim(substr($path, $zahraPos + strlen('/zahra/')), '/');
    }

    $aqarZahraPos = stripos($path, '/aqar/zahra/');
    if ($aqarZahraPos !== false) {
        return zahra_base_url() . '/' . ltrim(substr($path, $aqarZahraPos + strlen('/aqar/zahra/')), '/');
    }

    $storeZahraPos = stripos($path, '/Zahra_store/zahra/');
    if ($storeZahraPos !== false) {
        return zahra_base_url() . '/' . ltrim(substr($path, $storeZahraPos + strlen('/Zahra_store/zahra/')), '/');
    }

    return $trimmed;
}

function zahra_public_url(string $path): string
{
    $trimmed = trim($path);
    if ($trimmed === '') {
        return '';
    }

    if (stripos($trimmed, 'http://') === 0 || stripos($trimmed, 'https://') === 0) {
        return zahra_normalize_absolute_url($trimmed);
    }

    $clean = str_replace('\\', '/', zahra_strip_leading_store_prefix($trimmed));
    return zahra_base_url() . '/' . $clean;
}

function zahra_filename_from_path(string $value): string
{
    $trimmed = trim($value);
    if ($trimmed === '') {
        return '';
    }

    $path = $trimmed;
    if (stripos($trimmed, 'http://') === 0 || stripos($trimmed, 'https://') === 0) {
        $parsedPath = parse_url($trimmed, PHP_URL_PATH);
        if (is_string($parsedPath) && $parsedPath !== '') {
            $path = $parsedPath;
        }
    }

    return basename(str_replace('\\', '/', $path));
}

function zahra_item_image_url(?string $value): string
{
    $raw = trim((string) $value);
    if ($raw === '') {
        return '';
    }

    if (stripos($raw, 'http://') === 0 || stripos($raw, 'https://') === 0) {
        return zahra_normalize_absolute_url($raw);
    }

    $clean = zahra_strip_leading_store_prefix($raw);
    if (strpos($clean, '/') !== false) {
        return zahra_public_url($clean);
    }

    return zahra_public_url('uploud/items/' . $clean);
}

function zahra_category_image_url(?string $value): string
{
    $raw = trim((string) $value);
    if ($raw === '') {
        return '';
    }

    if (stripos($raw, 'http://') === 0 || stripos($raw, 'https://') === 0) {
        return zahra_normalize_absolute_url($raw);
    }

    $clean = zahra_strip_leading_store_prefix($raw);
    if (strpos($clean, '/') !== false) {
        return zahra_public_url($clean);
    }

    return zahra_public_url('uploud/categories/' . $clean);
}

function zahra_ad_image_url(?string $value): string
{
    $raw = trim((string) $value);
    if ($raw === '') {
        return '';
    }

    if (stripos($raw, 'http://') === 0 || stripos($raw, 'https://') === 0) {
        return zahra_normalize_absolute_url($raw);
    }

    $clean = zahra_strip_leading_store_prefix($raw);
    if (strpos($clean, '/') !== false) {
        return zahra_public_url($clean);
    }

    return zahra_public_url('ads/uploud/img/' . $clean);
}

function zahra_media_file_url(?string $value): string
{
    $raw = trim((string) $value);
    if ($raw === '') {
        return '';
    }
    return zahra_public_url($raw);
}

function zahra_user_image_url(?string $value): string
{
    $raw = trim((string) $value);
    if ($raw === '') {
        return '';
    }

    if (stripos($raw, 'http://') === 0 || stripos($raw, 'https://') === 0) {
        return zahra_normalize_absolute_url($raw);
    }

    $clean = zahra_strip_leading_store_prefix($raw);
    if (strpos($clean, '/') !== false) {
        return zahra_public_url($clean);
    }

    return zahra_public_url('uploads/users/img/' . $clean);
}
