<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function legalMasterFail(string $message, int $status = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $status);
}

function legalMasterAudit(string $entity, string $action, int $id = 0): void
{
    global $con;
    if (!tableExists('master_auth_audit_log')) {
        return;
    }
    try {
        $stmt = $con->prepare("INSERT INTO master_auth_audit_log
            (actor_admin_id, action_key, portal_key, metadata_json, created_at)
            VALUES (:actor, :action_key, 'legal', :metadata, NOW())");
        $stmt->execute([
            ':actor' => (int)($GLOBALS['masterAuthAdmin']['admin_id'] ?? 0),
            ':action_key' => 'legal_' . $entity . '_' . $action,
            ':metadata' => json_encode(['id' => $id], JSON_UNESCAPED_UNICODE),
        ]);
    } catch (Throwable $e) {
        error_log('master legal audit failed: ' . $e->getMessage());
    }
}

function legalMasterText(array $data, string $key, string $fallback = ''): string
{
    return trim((string)($data[$key] ?? $fallback));
}

function legalMasterBool(array $data, string $key, int $fallback = 1): int
{
    return !empty($data[$key]) ? 1 : (array_key_exists($key, $data) ? 0 : $fallback);
}

try {
    $admin = requireMasterAuth();
    $GLOBALS['masterAuthAdmin'] = $admin;
    $method = strtoupper($_SERVER['REQUEST_METHOD']);

    requireMasterPermission($admin, $method === 'GET' ? 'settings.view' : 'settings.edit');

    if ($method === 'GET') {
        $documents = [];
        $profiles = [];
        $options = [];
        $recordStats = [];

        if (tableExists('app_legal_documents')) {
            $documents = $con->query("SELECT * FROM app_legal_documents ORDER BY sort_order ASC, document_id ASC")
                ->fetchAll(PDO::FETCH_ASSOC);
        }
        if (tableExists('app_cookie_consent_profiles')) {
            $profiles = $con->query("SELECT * FROM app_cookie_consent_profiles ORDER BY profile_id ASC")
                ->fetchAll(PDO::FETCH_ASSOC);
        }
        if (tableExists('app_cookie_consent_options')) {
            $options = $con->query("SELECT * FROM app_cookie_consent_options ORDER BY profile_key ASC, sort_order ASC, option_id ASC")
                ->fetchAll(PDO::FETCH_ASSOC);
        }
        if (tableExists('app_cookie_consent_records')) {
            $stmt = $con->query("SELECT profile_key, consent_mode, COUNT(*) AS total
                FROM app_cookie_consent_records GROUP BY profile_key, consent_mode
                ORDER BY profile_key ASC, consent_mode ASC");
            $recordStats = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
        }

        respondJson([
            'status' => 'success',
            'documents' => $documents,
            'cookie_profiles' => $profiles,
            'cookie_options' => $options,
            'consent_stats' => $recordStats,
            'can_edit' => true,
        ]);
    }

    $payload = getRequestPayload();
    $entity = strtolower(trim((string)($payload['entity'] ?? '')));
    $action = strtolower(trim((string)($payload['action'] ?? 'save')));
    $id = (int)($payload['id'] ?? 0);
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];
    $allowedEntities = ['document', 'cookie_profile', 'cookie_option'];
    if (!in_array($entity, $allowedEntities, true)) {
        legalMasterFail('Unsupported legal content entity', 422);
    }

    $tables = [
        'document' => 'app_legal_documents',
        'cookie_profile' => 'app_cookie_consent_profiles',
        'cookie_option' => 'app_cookie_consent_options',
    ];
    $table = $tables[$entity];
    if (!tableExists($table)) {
        legalMasterFail("Required table {$table} is not available", 409);
    }

    if ($action === 'delete') {
        if ($id <= 0) {
            legalMasterFail('A valid record id is required', 422);
        }
        // Soft delete keeps public history and prevents broken references.
        $stmt = $con->prepare("UPDATE `{$table}` SET is_active = 0 WHERE " . ($entity === 'document' ? 'document_id' : ($entity === 'cookie_profile' ? 'profile_id' : 'option_id')) . " = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        legalMasterAudit($entity, 'deactivate', $id);
        respondJson(['status' => 'success', 'id' => $id]);
    }

    $con->beginTransaction();
    if ($entity === 'document') {
        $fields = [
            'document_key' => legalMasterText($data, 'document_key'),
            'document_type' => legalMasterText($data, 'document_type', 'policy'),
            'title_ar' => legalMasterText($data, 'title_ar'), 'title_en' => legalMasterText($data, 'title_en'),
            'subtitle_ar' => legalMasterText($data, 'subtitle_ar'), 'subtitle_en' => legalMasterText($data, 'subtitle_en'),
            'summary_ar_json' => json_encode($data['summary_ar'] ?? [], JSON_UNESCAPED_UNICODE),
            'summary_en_json' => json_encode($data['summary_en'] ?? [], JSON_UNESCAPED_UNICODE),
            'content_ar' => legalMasterText($data, 'content_ar'), 'content_en' => legalMasterText($data, 'content_en'),
            'accent_color' => legalMasterText($data, 'accent_color', '#0F766E'), 'hero_icon' => legalMasterText($data, 'hero_icon', 'policy'),
            'sort_order' => (int)($data['sort_order'] ?? 0), 'is_active' => legalMasterBool($data, 'is_active'),
        ];
        if ($fields['document_key'] === '' || $fields['title_ar'] === '' || $fields['title_en'] === '') legalMasterFail('Document key and bilingual titles are required', 422);
        $key = $id > 0 ? 'document_id' : '';
    } elseif ($entity === 'cookie_profile') {
        $fields = [
            'profile_key' => legalMasterText($data, 'profile_key'), 'title_ar' => legalMasterText($data, 'title_ar'), 'title_en' => legalMasterText($data, 'title_en'),
            'subtitle_ar' => legalMasterText($data, 'subtitle_ar'), 'subtitle_en' => legalMasterText($data, 'subtitle_en'), 'body_ar' => legalMasterText($data, 'body_ar'), 'body_en' => legalMasterText($data, 'body_en'),
            'accept_all_label_ar' => legalMasterText($data, 'accept_all_label_ar'), 'accept_all_label_en' => legalMasterText($data, 'accept_all_label_en'),
            'customize_label_ar' => legalMasterText($data, 'customize_label_ar'), 'customize_label_en' => legalMasterText($data, 'customize_label_en'),
            'reject_optional_label_ar' => legalMasterText($data, 'reject_optional_label_ar'), 'reject_optional_label_en' => legalMasterText($data, 'reject_optional_label_en'),
            'footer_note_ar' => legalMasterText($data, 'footer_note_ar'), 'footer_note_en' => legalMasterText($data, 'footer_note_en'),
            'version_label' => legalMasterText($data, 'version_label', 'v1'), 'accent_color' => legalMasterText($data, 'accent_color', '#0F766E'), 'is_active' => legalMasterBool($data, 'is_active'),
        ];
        if ($fields['profile_key'] === '' || $fields['title_ar'] === '' || $fields['title_en'] === '') legalMasterFail('Profile key and bilingual titles are required', 422);
        $key = $id > 0 ? 'profile_id' : '';
    } else {
        $fields = [
            'profile_key' => legalMasterText($data, 'profile_key'), 'option_key' => legalMasterText($data, 'option_key'), 'title_ar' => legalMasterText($data, 'title_ar'), 'title_en' => legalMasterText($data, 'title_en'),
            'description_ar' => legalMasterText($data, 'description_ar'), 'description_en' => legalMasterText($data, 'description_en'), 'badge_ar' => legalMasterText($data, 'badge_ar'), 'badge_en' => legalMasterText($data, 'badge_en'),
            'icon_name' => legalMasterText($data, 'icon_name', 'policy'), 'badge_color' => legalMasterText($data, 'badge_color', '#0F766E'), 'is_locked' => legalMasterBool($data, 'is_locked', 0), 'default_enabled' => legalMasterBool($data, 'default_enabled', 0),
            'sort_order' => (int)($data['sort_order'] ?? 0), 'preference_keys_json' => json_encode($data['preference_keys'] ?? [], JSON_UNESCAPED_UNICODE), 'is_active' => legalMasterBool($data, 'is_active'),
        ];
        if ($fields['profile_key'] === '' || $fields['option_key'] === '' || $fields['title_ar'] === '' || $fields['title_en'] === '') legalMasterFail('Profile, option key and bilingual titles are required', 422);
        $key = $id > 0 ? 'option_id' : '';
    }

    if ($id > 0) {
        $set = implode(', ', array_map(fn($column) => "`{$column}` = :{$column}", array_keys($fields)));
        $stmt = $con->prepare("UPDATE `{$table}` SET {$set} WHERE `{$key}` = :id LIMIT 1");
        foreach ($fields as $column => $value) $stmt->bindValue(":{$column}", $value);
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->execute();
    } else {
        $columns = implode(', ', array_map(fn($column) => "`{$column}`", array_keys($fields)));
        $placeholders = implode(', ', array_map(fn($column) => ":{$column}", array_keys($fields)));
        $stmt = $con->prepare("INSERT INTO `{$table}` ({$columns}) VALUES ({$placeholders})");
        $stmt->execute(array_combine(array_map(fn($column) => ":{$column}", array_keys($fields)), array_values($fields)));
        $id = (int)$con->lastInsertId();
    }
    $con->commit();
    legalMasterAudit($entity, 'save', $id);
    respondJson(['status' => 'success', 'id' => $id]);
} catch (Throwable $e) {
    if ($con instanceof PDO && $con->inTransaction()) $con->rollBack();
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
