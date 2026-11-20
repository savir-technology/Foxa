<?php

require_once __DIR__ . '/../../connect.php';

header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $actor = requireDashboardActor(['vendor', 'master']);
    $role = strtolower(trim((string)($actor['role'] ?? '')));
    $ownerId = $role === 'master'
        ? (int)($actor['master']['admin_id'] ?? 0)
        : (int)($actor['vendor']['vendor_id'] ?? 0);

    $payload = getRequestPayload();
    $token = trim((string)($payload['token'] ?? ''));
    if ($ownerId <= 0 || !in_array($role, ['vendor', 'master'], true) || $token === '') {
        respondJson(['status' => 'error', 'message' => 'Invalid push token payload'], 400);
    }

    $con->exec("CREATE TABLE IF NOT EXISTS dashboard_web_push_tokens (
        token_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        role VARCHAR(20) NOT NULL,
        owner_id INT NOT NULL,
        push_token TEXT NOT NULL,
        token_hash CHAR(64) NOT NULL,
        platform VARCHAR(20) NOT NULL DEFAULT 'web',
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (token_id),
        UNIQUE KEY uniq_dashboard_web_push_token (token_hash),
        KEY idx_dashboard_web_push_owner (role, owner_id, is_active)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    $stmt = $con->prepare("INSERT INTO dashboard_web_push_tokens
        (role, owner_id, push_token, token_hash, platform, is_active)
        VALUES (:role, :owner_id, :push_token, :token_hash, :platform, 1)
        ON DUPLICATE KEY UPDATE
            role = VALUES(role), owner_id = VALUES(owner_id),
            push_token = VALUES(push_token), platform = VALUES(platform),
            is_active = 1, updated_at = CURRENT_TIMESTAMP");
    $stmt->execute([
        ':role' => $role,
        ':owner_id' => $ownerId,
        ':push_token' => $token,
        ':token_hash' => hash('sha256', $token),
        ':platform' => trim((string)($payload['platform'] ?? 'web')) ?: 'web',
    ]);

    respondJson(['status' => 'success', 'message' => 'web_push_token_saved']);
} catch (Throwable $e) {
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
