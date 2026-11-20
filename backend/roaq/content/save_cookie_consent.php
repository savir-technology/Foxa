<?php
include "../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
function normalizePreferences($value)
{
    if (is_string($value) && trim($value) !== '') {
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            $value = $decoded;
        }
    }
    if (!is_array($value)) {
        return [];
    }
    $normalized = [];
    foreach ($value as $key => $item) {
        $normalized[(string)$key] = filter_var($item, FILTER_VALIDATE_BOOL, FILTER_NULL_ON_FAILURE);
        if ($normalized[(string)$key] === null) {
            $normalized[(string)$key] = in_array(strtolower(trim((string)$item)), ['1', 'true', 'yes', 'on'], true);
        }
    }
    return $normalized;
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
try {
    $payload = getRequestPayload();
    $profileKey = strtolower(trim((string)($payload['profile_key'] ?? 'first_launch_cookie_policy')));
    if ($profileKey === '') {
        $profileKey = 'first_launch_cookie_policy';
    }
    $profileStmt = $con->prepare("
        SELECT profile_key
        FROM app_cookie_consent_profiles
        WHERE profile_key = :profile_key
          AND is_active = 1
        LIMIT 1
    ");
    $profileStmt->execute([':profile_key' => $profileKey]);
    if (!$profileStmt->fetch(PDO::FETCH_ASSOC)) {
        respondJson([
            'status' => 'failure',
            'message' => 'Cookie consent profile not found',
        ], 404);
    }
    $installationKey = trim((string)($payload['installation_key'] ?? ''));
    if ($installationKey === '') {
        respondJson([
            'status' => 'failure',
            'message' => 'Installation key is required',
        ], 400);
    }
    $consentMode = strtolower(trim((string)($payload['consent_mode'] ?? '')));
    if ($consentMode === '') {
        respondJson([
            'status' => 'failure',
            'message' => 'Consent mode is required',
        ], 400);
    }
    $localeCode = strtolower(trim((string)($payload['locale_code'] ?? 'ar')));
    if (!in_array($localeCode, ['ar', 'en'], true)) {
        $localeCode = 'ar';
    }
    $preferences = normalizePreferences($payload['preferences'] ?? []);
    if (!$preferences) {
        $preferences = [
            'cookie_consent_necessary_v2' => true,
        ];
    }
    $userId = null;
    $token = getBearerToken();
    if ($token !== '') {
        $user = getUserBySessionToken($token);
        if (is_array($user) && isset($user['users_id'])) {
            $userId = (int)$user['users_id'];
        }
    }
    if ($userId === null && isset($payload['user_id']) && is_numeric($payload['user_id'])) {
        $userId = (int)$payload['user_id'];
    }
    $recordSource = trim((string)($payload['record_source'] ?? 'app'));
    if ($recordSource === '') {
        $recordSource = 'app';
    }
    $preferencesJson = json_encode($preferences, JSON_UNESCAPED_UNICODE);
    if ($preferencesJson === false) {
        $preferencesJson = '{}';
    }
    $stmt = $con->prepare("
        INSERT INTO app_cookie_consent_records (
            profile_key,
            user_id,
            installation_key,
            locale_code,
            consent_mode,
            preferences_json,
            record_source
        ) VALUES (
            :profile_key,
            :user_id,
            :installation_key,
            :locale_code,
            :consent_mode,
            :preferences_json,
            :record_source
        )
        ON DUPLICATE KEY UPDATE
            user_id = VALUES(user_id),
            locale_code = VALUES(locale_code),
            consent_mode = VALUES(consent_mode),
            preferences_json = VALUES(preferences_json),
            record_source = VALUES(record_source),
            updated_at = CURRENT_TIMESTAMP
    ");
    $stmt->execute([
        ':profile_key' => $profileKey,
        ':user_id' => $userId,
        ':installation_key' => $installationKey,
        ':locale_code' => $localeCode,
        ':consent_mode' => $consentMode,
        ':preferences_json' => $preferencesJson,
        ':record_source' => $recordSource,
    ]);
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
    $recordRow = $recordStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    respondJson([
        'status' => 'success',
        'record' => [
            'profile_key' => $recordRow['profile_key'] ?? $profileKey,
            'user_id' => isset($recordRow['user_id']) ? (int)$recordRow['user_id'] : $userId,
            'installation_key' => $recordRow['installation_key'] ?? $installationKey,
            'locale_code' => $recordRow['locale_code'] ?? $localeCode,
            'consent_mode' => $recordRow['consent_mode'] ?? $consentMode,
            'preferences' => decodeJsonObject($recordRow['preferences_json'] ?? $preferencesJson),
            'record_source' => $recordRow['record_source'] ?? $recordSource,
            'created_at' => $recordRow['created_at'] ?? null,
            'updated_at' => $recordRow['updated_at'] ?? null,
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}