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
function decodeJsonObject($value)
{
    if (is_array($value)) {
        return $value;
    }
    if (!is_string($value) || trim($value) === '') {
        return [];
    }
    $decoded = json_decode($value, true);
    return is_array($decoded) ? $decoded : [];
}
function cookieConsentOptionRowToArray(array $row)
{
    return [
        'option_key' => $row['option_key'] ?? '',
        'profile_key' => $row['profile_key'] ?? '',
        'title_ar' => $row['title_ar'] ?? '',
        'title_en' => $row['title_en'] ?? '',
        'description_ar' => $row['description_ar'] ?? '',
        'description_en' => $row['description_en'] ?? '',
        'badge_ar' => $row['badge_ar'] ?? null,
        'badge_en' => $row['badge_en'] ?? null,
        'icon_name' => $row['icon_name'] ?? 'policy',
        'badge_color' => $row['badge_color'] ?? '#1B7A3A',
        'is_locked' => isset($row['is_locked']) ? (int)$row['is_locked'] : 0,
        'default_enabled' => isset($row['default_enabled']) ? (int)$row['default_enabled'] : 0,
        'sort_order' => isset($row['sort_order']) ? (int)$row['sort_order'] : 0,
        'preference_keys' => decodeJsonList($row['preference_keys_json'] ?? null),
        'is_active' => isset($row['is_active']) ? (int)$row['is_active'] : 1,
        'created_at' => $row['created_at'] ?? null,
        'updated_at' => $row['updated_at'] ?? null,
    ];
}
function cookieConsentProfileRowToArray(array $row)
{
    return [
        'profile_key' => $row['profile_key'] ?? '',
        'title_ar' => $row['title_ar'] ?? '',
        'title_en' => $row['title_en'] ?? '',
        'subtitle_ar' => $row['subtitle_ar'] ?? null,
        'subtitle_en' => $row['subtitle_en'] ?? null,
        'body_ar' => $row['body_ar'] ?? null,
        'body_en' => $row['body_en'] ?? null,
        'accept_all_label_ar' => $row['accept_all_label_ar'] ?? null,
        'accept_all_label_en' => $row['accept_all_label_en'] ?? null,
        'customize_label_ar' => $row['customize_label_ar'] ?? null,
        'customize_label_en' => $row['customize_label_en'] ?? null,
        'reject_optional_label_ar' => $row['reject_optional_label_ar'] ?? null,
        'reject_optional_label_en' => $row['reject_optional_label_en'] ?? null,
        'footer_note_ar' => $row['footer_note_ar'] ?? null,
        'footer_note_en' => $row['footer_note_en'] ?? null,
        'version_label' => $row['version_label'] ?? 'v1',
        'accent_color' => $row['accent_color'] ?? '#F97316',
        'is_active' => isset($row['is_active']) ? (int)$row['is_active'] : 1,
        'created_at' => $row['created_at'] ?? null,
        'updated_at' => $row['updated_at'] ?? null,
    ];
}
try {
    $profileKey = strtolower(trim((string)($_GET['profile_key'] ?? $_GET['key'] ?? 'first_launch_cookie_policy')));
    if ($profileKey === '') {
        $profileKey = 'first_launch_cookie_policy';
    }
    $profileStmt = $con->prepare("
        SELECT *
        FROM app_cookie_consent_profiles
        WHERE profile_key = :profile_key
          AND is_active = 1
        LIMIT 1
    ");
    $profileStmt->execute([':profile_key' => $profileKey]);
    $profileRow = $profileStmt->fetch(PDO::FETCH_ASSOC);
    if (!$profileRow) {
        respondJson([
            'status' => 'failure',
            'message' => 'Cookie consent profile not found',
        ], 404);
    }
    $optionsStmt = $con->prepare("
        SELECT *
        FROM app_cookie_consent_options
        WHERE profile_key = :profile_key
          AND is_active = 1
        ORDER BY sort_order ASC, option_id ASC
    ");
    $optionsStmt->execute([':profile_key' => $profileKey]);
    $options = [];
    while ($row = $optionsStmt->fetch(PDO::FETCH_ASSOC)) {
        $options[] = cookieConsentOptionRowToArray($row);
    }
    $installationKey = trim((string)($_GET['installation_key'] ?? ''));
    $record = null;
    if ($installationKey !== '') {
        $recordStmt = $con->prepare("
            SELECT *
            FROM app_cookie_consent_records
            WHERE profile_key = :profile_key
              AND installation_key = :installation_key
            LIMIT 1
        ");
        $recordStmt->execute([
            ':profile_key' => $profileKey,
            ':installation_key' => $installationKey,
        ]);
        $recordRow = $recordStmt->fetch(PDO::FETCH_ASSOC);
        if ($recordRow) {
            $record = [
                'profile_key' => $recordRow['profile_key'] ?? $profileKey,
                'user_id' => isset($recordRow['user_id']) ? (int)$recordRow['user_id'] : null,
                'installation_key' => $recordRow['installation_key'] ?? '',
                'locale_code' => $recordRow['locale_code'] ?? 'ar',
                'consent_mode' => $recordRow['consent_mode'] ?? '',
                'preferences' => decodeJsonObject($recordRow['preferences_json'] ?? null),
                'record_source' => $recordRow['record_source'] ?? 'app',
                'created_at' => $recordRow['created_at'] ?? null,
                'updated_at' => $recordRow['updated_at'] ?? null,
            ];
        }
    }
    respondJson([
        'status' => 'success',
        'profile' => cookieConsentProfileRowToArray($profileRow),
        'options' => $options,
        'record' => $record,
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}