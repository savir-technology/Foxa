<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php";
require_once __DIR__ . '/../notifications/notification_helper.php';
require_once __DIR__ . '/../notifications/fcm_token_utils.php';

function ensureOrderVoiceCallSchema(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS order_voice_call_sessions (
            order_id INT NOT NULL,
            status VARCHAR(32) NOT NULL DEFAULT 'idle',
            caller_role VARCHAR(32) NOT NULL DEFAULT '',
            caller_ref_id VARCHAR(64) NOT NULL DEFAULT '',
            caller_name VARCHAR(255) NOT NULL DEFAULT '',
            callee_role VARCHAR(32) NOT NULL DEFAULT '',
            callee_ref_id VARCHAR(64) NOT NULL DEFAULT '',
            callee_name VARCHAR(255) NOT NULL DEFAULT '',
            offer_json LONGTEXT DEFAULT NULL,
            answer_json LONGTEXT DEFAULT NULL,
            created_at_ms BIGINT NOT NULL DEFAULT 0,
            updated_at_ms BIGINT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (order_id),
            KEY idx_status_updated (status, updated_at_ms)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    $con->exec("
        CREATE TABLE IF NOT EXISTS order_voice_call_candidates (
            candidate_id BIGINT NOT NULL AUTO_INCREMENT,
            order_id INT NOT NULL,
            bucket VARCHAR(32) NOT NULL,
            candidate_text LONGTEXT NOT NULL,
            sdp_mid VARCHAR(64) DEFAULT NULL,
            sdp_m_line_index INT DEFAULT NULL,
            timestamp_ms BIGINT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (candidate_id),
            KEY idx_order_bucket_id (order_id, bucket, candidate_id),
            KEY idx_order_created (order_id, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    $con->exec("
        CREATE TABLE IF NOT EXISTS order_voice_call_events (
            event_id BIGINT NOT NULL AUTO_INCREMENT,
            order_id INT NOT NULL,
            event_type VARCHAR(32) NOT NULL,
            status VARCHAR(32) NOT NULL,
            caller_role VARCHAR(32) DEFAULT NULL,
            caller_ref_id VARCHAR(64) DEFAULT NULL,
            caller_name VARCHAR(255) DEFAULT NULL,
            callee_role VARCHAR(32) DEFAULT NULL,
            callee_ref_id VARCHAR(64) DEFAULT NULL,
            callee_name VARCHAR(255) DEFAULT NULL,
            event_at_ms BIGINT DEFAULT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (event_id),
            KEY idx_order_created (order_id, created_at),
            KEY idx_event_type (event_type),
            KEY idx_status_created (status, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

ensureOrderVoiceCallSchema($con);

function voiceCallLog(string $message, array $data = []): void
{
    $suffix = '';
    if (!empty($data)) {
        $encoded = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $suffix = $encoded === false ? '' : ' ' . $encoded;
    }

    error_log('[VOICE CALL] ' . $message . $suffix);
}

function voiceCallLogError(string $message, Throwable $error, array $data = []): void
{
    $suffix = '';
    if (!empty($data)) {
        $encoded = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $suffix = $encoded === false ? '' : ' ' . $encoded;
    }

    error_log(
        '[VOICE CALL] ERROR ' . $message . $suffix . ' exception=' . $error->getMessage() . ' trace=' . $error->getTraceAsString()
    );
}

function normalizeLocaleCode(?string $locale, string $fallback): string
{
    $normalized = strtolower(trim((string)$locale));
    if ($normalized === '') {
        return $fallback;
    }

    return in_array($normalized, ['ar', 'en'], true) ? $normalized : $fallback;
}

function fetchUserLocaleCode(PDO $con, int $userId): string
{
    if ($userId <= 0) {
        return 'ar';
    }

    $stmt = $con->prepare("
        SELECT COALESCE(NULLIF(TRIM(users_locale), ''), 'ar') AS locale_code
        FROM users
        WHERE users_id = ?
        LIMIT 1
    ");
    $stmt->execute([$userId]);
    $locale = $stmt->fetchColumn();

    return normalizeLocaleCode($locale !== false ? (string)$locale : null, 'ar');
}

function fetchDriverLocaleCode(PDO $con, int $driverId): string
{
    if ($driverId <= 0) {
        return 'en';
    }

    $stmt = $con->prepare("
        SELECT COALESCE(NULLIF(TRIM(locale_code), ''), 'en') AS locale_code
        FROM delivery_users
        WHERE id = ?
        LIMIT 1
    ");
    $stmt->execute([$driverId]);
    $locale = $stmt->fetchColumn();

    return normalizeLocaleCode($locale !== false ? (string)$locale : null, 'en');
}

function buildVoiceCallNotificationText(PDO $con, array $session): array
{
    $orderId = (int)($session['order_id'] ?? 0);
    $callerRole = strtolower(trim((string)($session['caller_role'] ?? '')));
    $callerId = (int)($session['caller_ref_id'] ?? 0);
    $callerName = trim((string)($session['caller_name'] ?? ''));
    $calleeRole = strtolower(trim((string)($session['callee_role'] ?? '')));
    $calleeId = (int)($session['callee_ref_id'] ?? 0);

    $isDriverRecipient = $calleeRole === 'driver';
    $locale = $isDriverRecipient
        ? fetchDriverLocaleCode($con, $calleeId)
        : fetchUserLocaleCode($con, $calleeId);

    $callerLabelAr = $callerRole === 'driver' ? 'السائق' : 'العميل';
    $callerLabelEn = $callerRole === 'driver' ? 'Driver' : 'Customer';
    $resolvedCallerName = $callerName !== '' ? $callerName : $callerLabelEn;

    if ($locale === 'en') {
        $title = $isDriverRecipient ? 'Incoming call from customer' : 'Incoming call from driver';
        $body = sprintf('%s is calling about order #%d.', $resolvedCallerName, $orderId);
    } else {
        $title = $isDriverRecipient ? 'مكالمة واردة من العميل' : 'مكالمة واردة من السائق';
        $body = sprintf('%s يتصل بك بخصوص الطلب #%d.', $callerName !== '' ? $callerName : $callerLabelAr, $orderId);
    }

    return [
        'title' => $title,
        'body' => $body,
        'locale' => $locale,
    ];
}

function fetchVoiceCallCallerTokens(PDO $con, array $record): array
{
    $callerRole = strtolower(trim((string)($record['caller_role'] ?? '')));
    $callerId = (int)($record['caller_ref_id'] ?? 0);

    if ($callerRole === 'driver' && $callerId > 0) {
        return fetchDriverPushTokens($con, $callerId);
    }

    if (in_array($callerRole, ['user', 'customer'], true) && $callerId > 0) {
        $token = fetchUserFcmToken($con, $callerId);
        return $token ? [$token] : [];
    }

    return [];
}

function sendVoiceCallEndedNotification(PDO $con, array $record, string $terminalStatus = 'ended'): void
{
    $orderId = (int)($record['order_id'] ?? 0);
    if ($orderId <= 0) {
        return;
    }

    $status = strtolower(trim($terminalStatus));
    if (!in_array($status, ['ended', 'failed'], true)) {
        $status = 'ended';
    }

    voiceCallLog('sendVoiceCallEndedNotification() start', [
        'orderId' => $orderId,
        'status' => $status,
    ]);

    $payload = [
        'type' => 'voice_call_status',
        'screen' => 'voice_call',
        'call_status' => $status,
        'order_id' => (string)$orderId,
        'caller_role' => (string)($record['caller_role'] ?? ''),
        'caller_id' => (string)($record['caller_ref_id'] ?? ''),
        'caller_name' => (string)($record['caller_name'] ?? ''),
        'callee_role' => (string)($record['callee_role'] ?? ''),
        'callee_id' => (string)($record['callee_ref_id'] ?? ''),
        'callee_name' => (string)($record['callee_name'] ?? ''),
    ];

    foreach (['caller', 'callee'] as $participantKey) {
        $participantRole = strtolower(trim((string)($record[$participantKey . '_role'] ?? '')));
        $participantId = (int)($record[$participantKey . '_ref_id'] ?? 0);
        if ($participantRole === '' || $participantId <= 0) {
            continue;
        }

        $locale = $participantRole === 'driver'
            ? fetchDriverLocaleCode($con, $participantId)
            : fetchUserLocaleCode($con, $participantId);

        if ($locale === 'en') {
            $title = 'Call ended';
            $body = sprintf('Voice call about order #%d has ended.', $orderId);
        } else {
            $title = 'تم إنهاء المكالمة';
            $body = sprintf('انتهت المكالمة الصوتية الخاصة بالطلب #%d.', $orderId);
        }

        if ($status === 'failed') {
            if ($locale === 'en') {
                $title = 'Call failed';
                $body = sprintf(
                    'Voice call about order #%d could not be connected.',
                    $orderId
                );
            } else {
                $title = 'فشل الاتصال';
                $body = sprintf('تعذر إتمام المكالمة الصوتية الخاصة بالطلب #%d.', $orderId);
            }
        }

        if ($status === 'failed' && $locale !== 'en') {
            $title = "\u{0641}\u{0634}\u{0644} \u{0627}\u{0644}\u{0627}\u{062a}\u{0635}\u{0627}\u{0644}";
            $body = sprintf(
                "\u{062a}\u{0639}\u{0630}\u{0631} \u{0625}\u{062a}\u{0645}\u{0627}\u{0645} \u{0627}\u{0644}\u{0645}\u{0643}\u{0627}\u{0644}\u{0645}\u{0629} \u{0627}\u{0644}\u{0635}\u{0648}\u{062a}\u{064a}\u{0629} \u{0627}\u{0644}\u{062e}\u{0627}\u{0635}\u{0629} \u{0628}\u{0627}\u{0644}\u{0637}\u{0644}\u{0628} #%d.",
                $orderId
            );
        }

        if ($participantRole === 'driver') {
            voiceCallLog('sendVoiceCallEndedNotification() notifyDriver', [
                'orderId' => $orderId,
                'participantId' => $participantId,
                'status' => $status,
            ]);
            notifyDriver(
                $con,
                $participantId,
                'voice_call_status',
                $title,
                $body,
                'order',
                $orderId,
                $payload,
                true
            );
            continue;
        }

        voiceCallLog('sendVoiceCallEndedNotification() notifyUser', [
            'orderId' => $orderId,
            'participantId' => $participantId,
            'status' => $status,
        ]);
        notifyUser(
            $con,
            $participantId,
            'voice_call_status',
            $title,
            $body,
            'order',
            $orderId,
            $payload,
            true
        );
    }
}

function sendVoiceCallNotification(PDO $con, array $record, ?array $previous = null): void
{
    if (($record['status'] ?? '') !== 'ringing') {
        return;
    }

    if ($previous !== null && ($previous['status'] ?? '') === 'ringing') {
        return;
    }

    $orderId = (int)($record['order_id'] ?? 0);
    $calleeRole = strtolower(trim((string)($record['callee_role'] ?? '')));
    $calleeId = (int)($record['callee_ref_id'] ?? 0);

    if ($orderId <= 0 || $calleeRole === '' || $calleeId <= 0) {
        return;
    }

    voiceCallLog('sendVoiceCallNotification() start', [
        'orderId' => $orderId,
        'calleeRole' => $calleeRole,
        'calleeId' => $calleeId,
        'status' => $record['status'] ?? null,
    ]);
    $text = buildVoiceCallNotificationText($con, $record);
    $callerTokens = normalizeFcmTokenList(fetchVoiceCallCallerTokens($con, $record));
    voiceCallLog('sendVoiceCallNotification() caller token fingerprint set', [
        'orderId' => $orderId,
        'callerRole' => $record['caller_role'] ?? null,
        'callerId' => $record['caller_ref_id'] ?? null,
        'fingerprints' => array_map('fcmTokenFingerprint', $callerTokens),
    ]);
    voiceCallLog('sendVoiceCallNotification() destination resolved', [
        'orderId' => $orderId,
        'destinationRole' => $calleeRole,
        'destinationUserId' => $calleeId,
        'callerId' => (int)($record['caller_ref_id'] ?? 0),
        'receiverId' => $calleeId,
    ]);
    $payload = [
        'type' => 'voice_call',
        'screen' => 'voice_call',
        'call_status' => 'ringing',
        'order_id' => (string)$orderId,
        'caller_role' => (string)($record['caller_role'] ?? ''),
        'caller_id' => (string)($record['caller_ref_id'] ?? ''),
        'caller_name' => (string)($record['caller_name'] ?? ''),
        'callee_role' => (string)($record['callee_role'] ?? ''),
        'callee_id' => (string)($record['callee_ref_id'] ?? ''),
        'callee_name' => (string)($record['callee_name'] ?? ''),
    ];

    if ($calleeRole === 'driver') {
        voiceCallLog('sendVoiceCallNotification() notifyDriver', [
            'orderId' => $orderId,
            'calleeId' => $calleeId,
            'excludeFingerprints' => array_map('fcmTokenFingerprint', $callerTokens),
        ]);
        notifyDriver(
            $con,
            $calleeId,
            'voice_call',
            $text['title'],
            $text['body'],
            'order',
            $orderId,
            $payload,
            true,
            $callerTokens
        );
        return;
    }

    if ($calleeRole === 'user') {
        voiceCallLog('sendVoiceCallNotification() notifyUser', [
            'orderId' => $orderId,
            'calleeId' => $calleeId,
            'excludeFingerprints' => array_map('fcmTokenFingerprint', $callerTokens),
        ]);
        notifyUser(
            $con,
            $calleeId,
            'voice_call',
            $text['title'],
            $text['body'],
            'order',
            $orderId,
            $payload,
            true,
            $callerTokens
        );
    }
}

function isVoiceCallTerminalStatus(string $status): bool
{
    return in_array(strtolower(trim($status)), ['ended', 'declined', 'missed', 'failed'], true);
}

function sendVoiceCallOutcomeNotification(PDO $con, array $record, ?array $previous = null): void
{
    $status = strtolower(trim((string)($record['status'] ?? '')));
    if (!isVoiceCallTerminalStatus($status)) {
        return;
    }

    if ($previous !== null && strtolower(trim((string)($previous['status'] ?? ''))) === $status) {
        return;
    }

    if (in_array($status, ['ended', 'failed'], true)) {
        voiceCallLog('sendVoiceCallOutcomeNotification() ended/failed', [
            'orderId' => (int)($record['order_id'] ?? 0),
            'status' => $status,
        ]);
        sendVoiceCallEndedNotification($con, $record, $status);
        return;
    }

    $orderId = (int)($record['order_id'] ?? 0);
    $callerRole = strtolower(trim((string)($record['caller_role'] ?? '')));
    $callerId = (int)($record['caller_ref_id'] ?? 0);
    $calleeName = trim((string)($record['callee_name'] ?? ''));

    if ($orderId <= 0 || $callerId <= 0 || $callerRole === '') {
        return;
    }

    voiceCallLog('sendVoiceCallOutcomeNotification() start', [
        'orderId' => $orderId,
        'status' => $status,
        'callerRole' => $callerRole,
        'callerId' => $callerId,
    ]);
    $isMissed = $status === 'missed';
    $title = $isMissed ? 'مكالمة فائتة' : 'تم رفض المكالمة';
    $body = ($calleeName !== '' ? $calleeName : 'الطرف الآخر') .
        ($isMissed
            ? ' لم يرد على مكالمتك بخصوص الطلب #' . $orderId . '.'
            : ' رفض المكالمة بخصوص الطلب #' . $orderId . '.');

    $payload = [
        'type' => 'voice_call_status',
        'screen' => 'voice_call',
        'call_status' => $status,
        'order_id' => (string)$orderId,
        'caller_role' => (string)($record['caller_role'] ?? ''),
        'caller_id' => (string)($record['caller_ref_id'] ?? ''),
        'caller_name' => (string)($record['caller_name'] ?? ''),
        'callee_role' => (string)($record['callee_role'] ?? ''),
        'callee_id' => (string)($record['callee_ref_id'] ?? ''),
        'callee_name' => (string)($record['callee_name'] ?? ''),
    ];

    if ($callerRole === 'driver') {
        voiceCallLog('sendVoiceCallOutcomeNotification() notifyDriver', [
            'orderId' => $orderId,
            'callerId' => $callerId,
            'status' => $status,
        ]);
        notifyDriver($con, $callerId, 'voice_call_status', $title, $body, 'order', $orderId, $payload, true);
        return;
    }

    if ($callerRole === 'user') {
        voiceCallLog('sendVoiceCallOutcomeNotification() notifyUser', [
            'orderId' => $orderId,
            'callerId' => $callerId,
            'status' => $status,
        ]);
        notifyUser($con, $callerId, 'voice_call_status', $title, $body, 'order', $orderId, $payload, true);
    }
}

function cleanText($value): ?string
{
    if ($value === null) {
        return null;
    }

    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }

    return $text;
}

function toIntOrNull($value): ?int
{
    if ($value === null) {
        return null;
    }

    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null' || !is_numeric($text)) {
        return null;
    }

    return (int)$text;
}

function nowMs(): int
{
    return (int)round(microtime(true) * 1000);
}

function decodeJsonMap(?string $json): ?array
{
    if ($json === null) {
        return null;
    }

    $text = trim($json);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }

    $decoded = json_decode($text, true);
    if (!is_array($decoded) || json_last_error() !== JSON_ERROR_NONE) {
        return null;
    }

    return $decoded;
}

function normalizeJsonString($value): ?string
{
    if ($value === null) {
        return null;
    }

    if (is_array($value) || is_object($value)) {
        $encoded = json_encode($value, JSON_UNESCAPED_UNICODE);
        return $encoded === false ? null : $encoded;
    }

    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }

    json_decode($text, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        return null;
    }

    return $text;
}

function querySessionRow(PDO $con, int $orderId): ?array
{
    voiceCallLog('querySessionRow() start', ['orderId' => $orderId]);
    $stmt = $con->prepare("
        SELECT
            order_id,
            status,
            caller_role,
            caller_ref_id,
            caller_name,
            callee_role,
            callee_ref_id,
            callee_name,
            offer_json,
            answer_json,
            created_at_ms,
            updated_at_ms,
            created_at,
            updated_at
        FROM order_voice_call_sessions
        WHERE order_id = ?
        ORDER BY updated_at_ms DESC, created_at_ms DESC, updated_at DESC, created_at DESC
        LIMIT 1
    ");
    $stmt->execute([$orderId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    voiceCallLog('querySessionRow() done', [
        'orderId' => $orderId,
        'found' => $row !== false,
        'status' => $row['status'] ?? null,
        'hasOffer' => !empty($row['offer_json'] ?? null),
        'hasAnswer' => !empty($row['answer_json'] ?? null),
    ]);

    return $row === false ? null : $row;
}

function fetchSessionPayload(PDO $con, int $orderId): ?array
{
    voiceCallLog('fetchSessionPayload() start', ['orderId' => $orderId]);
    $row = querySessionRow($con, $orderId);
    if ($row === null) {
        voiceCallLog('fetchSessionPayload() no session', ['orderId' => $orderId]);
        return null;
    }

    $candidateStmt = $con->prepare("
        SELECT
            candidate_id,
            order_id,
            bucket,
            candidate_text,
            sdp_mid,
            sdp_m_line_index,
            timestamp_ms,
            created_at
        FROM order_voice_call_candidates
        WHERE order_id = ?
        ORDER BY candidate_id ASC
    ");
    $candidateStmt->execute([$orderId]);

    $callerCandidates = [];
    $calleeCandidates = [];
    while ($candidate = $candidateStmt->fetch(PDO::FETCH_ASSOC)) {
        $mappedCandidate = [
            'candidateId' => (int)($candidate['candidate_id'] ?? 0),
            'orderId' => (int)($candidate['order_id'] ?? 0),
            'bucket' => (string)($candidate['bucket'] ?? ''),
            'candidate' => (string)($candidate['candidate_text'] ?? ''),
            'sdpMid' => $candidate['sdp_mid'] !== null ? (string)$candidate['sdp_mid'] : null,
            'sdpMLineIndex' => $candidate['sdp_m_line_index'] !== null
                ? (int)$candidate['sdp_m_line_index']
                : null,
            'timestampMs' => (int)($candidate['timestamp_ms'] ?? 0),
            'createdAt' => $candidate['created_at'],
        ];

        if (($mappedCandidate['bucket'] ?? '') === 'calleeCandidates') {
            $calleeCandidates[] = $mappedCandidate;
        } else {
            $callerCandidates[] = $mappedCandidate;
        }
    }

    voiceCallLog('fetchSessionPayload() done', [
        'orderId' => $orderId,
        'status' => $row['status'] ?? null,
        'callerCandidates' => count($callerCandidates),
        'calleeCandidates' => count($calleeCandidates),
        'hasOffer' => !empty($row['offer_json'] ?? null),
        'hasAnswer' => !empty($row['answer_json'] ?? null),
    ]);

    return [
        'session' => [
            'orderId' => (string)$row['order_id'],
            'status' => (string)$row['status'],
            'callerRole' => (string)$row['caller_role'],
            'callerId' => (string)$row['caller_ref_id'],
            'callerName' => (string)$row['caller_name'],
            'calleeRole' => (string)$row['callee_role'],
            'calleeId' => (string)$row['callee_ref_id'],
            'calleeName' => (string)$row['callee_name'],
            'createdAtMs' => (int)($row['created_at_ms'] ?? 0),
            'updatedAtMs' => (int)($row['updated_at_ms'] ?? 0),
            'offer' => decodeJsonMap($row['offer_json'] ?? null),
            'answer' => decodeJsonMap($row['answer_json'] ?? null),
            'callerCandidates' => $callerCandidates,
            'calleeCandidates' => $calleeCandidates,
        ],
    ];
}

function saveSessionRow(PDO $con, array $record): void
{
    voiceCallLog('saveSessionRow() start', [
        'orderId' => $record['order_id'] ?? null,
        'status' => $record['status'] ?? null,
        'hasOffer' => !empty($record['offer_json'] ?? null),
        'hasAnswer' => !empty($record['answer_json'] ?? null),
    ]);
    $startedTransaction = !$con->inTransaction();
    if ($startedTransaction) {
        $con->beginTransaction();
    }

    try {
        $deleteStmt = $con->prepare("
            DELETE FROM order_voice_call_sessions
            WHERE order_id = ?
        ");
        $deleteStmt->execute([$record['order_id']]);

        $stmt = $con->prepare("
            INSERT INTO order_voice_call_sessions (
                order_id,
                status,
                caller_role,
                caller_ref_id,
                caller_name,
                callee_role,
                callee_ref_id,
                callee_name,
                offer_json,
                answer_json,
                created_at_ms,
                updated_at_ms
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $record['order_id'],
            $record['status'],
            $record['caller_role'],
            $record['caller_ref_id'],
            $record['caller_name'],
            $record['callee_role'],
            $record['callee_ref_id'],
            $record['callee_name'],
            $record['offer_json'],
            $record['answer_json'],
            $record['created_at_ms'],
            $record['updated_at_ms'],
        ]);

        if ($startedTransaction) {
            $con->commit();
        }
    } catch (Throwable $e) {
        if ($startedTransaction && $con->inTransaction()) {
            $con->rollBack();
        }
        throw $e;
    }

    voiceCallLog('saveSessionRow() done', [
        'orderId' => $record['order_id'] ?? null,
        'status' => $record['status'] ?? null,
    ]);
}

function normalizeSessionRecord(?array $existing, array $input): array
{
    $orderId = toIntOrNull($input['order_id'] ?? ($existing['order_id'] ?? null)) ?? 0;
    $status = cleanText($input['status'] ?? ($existing['status'] ?? null)) ?? 'idle';
    $callerRole = cleanText($input['caller_role'] ?? ($existing['caller_role'] ?? null)) ?? '';
    $callerRefId = cleanText($input['caller_ref_id'] ?? ($existing['caller_ref_id'] ?? null)) ?? '';
    $callerName = cleanText($input['caller_name'] ?? ($existing['caller_name'] ?? null)) ?? '';
    $calleeRole = cleanText($input['callee_role'] ?? ($existing['callee_role'] ?? null)) ?? '';
    $calleeRefId = cleanText($input['callee_ref_id'] ?? ($existing['callee_ref_id'] ?? null)) ?? '';
    $calleeName = cleanText($input['callee_name'] ?? ($existing['callee_name'] ?? null)) ?? '';

    $offerJson = null;
    if (array_key_exists('offer_json', $input)) {
        $offerJson = normalizeJsonString($input['offer_json']);
    } elseif (!empty($existing['offer_json'] ?? null)) {
        $offerJson = normalizeJsonString($existing['offer_json']);
    }

    $answerJson = null;
    if (array_key_exists('answer_json', $input)) {
        $answerJson = normalizeJsonString($input['answer_json']);
    } elseif (!empty($existing['answer_json'] ?? null)) {
        $answerJson = normalizeJsonString($existing['answer_json']);
    }

    $createdAtMs = toIntOrNull($input['created_at_ms'] ?? ($existing['created_at_ms'] ?? null));
    if ($createdAtMs === null || $createdAtMs <= 0) {
        $createdAtMs = nowMs();
    }

    $updatedAtMs = toIntOrNull($input['updated_at_ms'] ?? null);
    if ($updatedAtMs === null || $updatedAtMs <= 0) {
        $updatedAtMs = nowMs();
    }

    return [
        'order_id' => $orderId,
        'status' => $status,
        'caller_role' => $callerRole,
        'caller_ref_id' => $callerRefId,
        'caller_name' => $callerName,
        'callee_role' => $calleeRole,
        'callee_ref_id' => $calleeRefId,
        'callee_name' => $calleeName,
        'offer_json' => $offerJson,
        'answer_json' => $answerJson,
        'created_at_ms' => $createdAtMs,
        'updated_at_ms' => $updatedAtMs,
    ];
}

function upsertSession(PDO $con, array $input): void
{
    $orderId = toIntOrNull($input['order_id'] ?? null) ?? 0;
    if ($orderId <= 0) {
        throw new RuntimeException('order_id is required');
    }

    voiceCallLog('upsertSession() start', [
        'orderId' => $orderId,
        'status' => $input['status'] ?? null,
        'hasOfferJson' => array_key_exists('offer_json', $input),
        'hasAnswerJson' => array_key_exists('answer_json', $input),
    ]);
    $existing = querySessionRow($con, $orderId);
    $record = normalizeSessionRecord($existing, $input);
    saveSessionRow($con, $record);
    sendVoiceCallNotification($con, $record, $existing);
    voiceCallLog('upsertSession() done', [
        'orderId' => $orderId,
        'status' => $record['status'] ?? null,
        'hasOffer' => !empty($record['offer_json'] ?? null),
        'hasAnswer' => !empty($record['answer_json'] ?? null),
    ]);
}

function patchSession(PDO $con, array $input): void
{
    $orderId = toIntOrNull($input['order_id'] ?? null) ?? 0;
    if ($orderId <= 0) {
        throw new RuntimeException('order_id is required');
    }

    voiceCallLog('patchSession() start', [
        'orderId' => $orderId,
        'status' => $input['status'] ?? null,
        'hasOfferJson' => array_key_exists('offer_json', $input),
        'hasAnswerJson' => array_key_exists('answer_json', $input),
    ]);
    $existing = querySessionRow($con, $orderId);
    $record = normalizeSessionRecord($existing, array_merge(
        $existing ?? [],
        $input,
        ['order_id' => $orderId]
    ));

    if ($existing === null) {
        $record['created_at_ms'] = $record['created_at_ms'] > 0 ? $record['created_at_ms'] : nowMs();
    } else {
        $record['created_at_ms'] = (int)($existing['created_at_ms'] ?? $record['created_at_ms']);
    }

    $record['updated_at_ms'] = nowMs();
    saveSessionRow($con, $record);
    sendVoiceCallNotification($con, $record, $existing);
    sendVoiceCallOutcomeNotification($con, $record, $existing);

    if (isVoiceCallTerminalStatus((string)($record['status'] ?? ''))) {
        voiceCallLog('patchSession() terminal status cleanup', [
            'orderId' => $orderId,
            'status' => $record['status'] ?? null,
        ]);
        cleanupVoiceCallCandidates($con, $orderId);
    }

    voiceCallLog('patchSession() done', [
        'orderId' => $orderId,
        'status' => $record['status'] ?? null,
        'hasOffer' => !empty($record['offer_json'] ?? null),
        'hasAnswer' => !empty($record['answer_json'] ?? null),
    ]);
}

function clearSession(PDO $con, int $orderId): void
{
    voiceCallLog('clearSession() start', ['orderId' => $orderId]);
    $candidateStmt = $con->prepare("DELETE FROM order_voice_call_candidates WHERE order_id = ?");
    $candidateStmt->execute([$orderId]);

    $sessionStmt = $con->prepare("DELETE FROM order_voice_call_sessions WHERE order_id = ?");
    $sessionStmt->execute([$orderId]);
    voiceCallLog('clearSession() done', ['orderId' => $orderId]);
}

function cleanupVoiceCallCandidates(PDO $con, int $orderId): void
{
    if ($orderId <= 0) {
        return;
    }

    voiceCallLog('cleanupVoiceCallCandidates() start', ['orderId' => $orderId]);
    $candidateStmt = $con->prepare("DELETE FROM order_voice_call_candidates WHERE order_id = ?");
    $candidateStmt->execute([$orderId]);
    voiceCallLog('cleanupVoiceCallCandidates() done', ['orderId' => $orderId]);
}

function addCandidate(PDO $con, array $input): void
{
    $orderId = toIntOrNull($input['order_id'] ?? null) ?? 0;
    if ($orderId <= 0) {
        throw new RuntimeException('order_id is required');
    }

    $bucket = cleanText($input['bucket'] ?? null) ?? 'callerCandidates';
    if ($bucket !== 'callerCandidates' && $bucket !== 'calleeCandidates') {
        $bucket = 'callerCandidates';
    }

    $candidateText = cleanText($input['candidate_text'] ?? ($input['candidate'] ?? null)) ?? '';
    if ($candidateText === '') {
        throw new RuntimeException('candidate is required');
    }

    $sdpMid = cleanText($input['sdp_mid'] ?? ($input['sdpMid'] ?? null));
    $sdpMLineIndex = toIntOrNull($input['sdp_m_line_index'] ?? ($input['sdpMLineIndex'] ?? null));
    $timestampMs = toIntOrNull($input['timestamp_ms'] ?? ($input['timestampMs'] ?? null));
    if ($timestampMs === null || $timestampMs <= 0) {
        $timestampMs = nowMs();
    }

    voiceCallLog('addCandidate() start', [
        'orderId' => $orderId,
        'bucket' => $bucket,
        'candidate' => $candidateText,
        'sdpMid' => $sdpMid,
        'sdpMLineIndex' => $sdpMLineIndex,
    ]);

    $duplicateStmt = $con->prepare("
        SELECT candidate_id
        FROM order_voice_call_candidates
        WHERE order_id = ? AND bucket = ? AND candidate_text = ?
        LIMIT 1
    ");
    $duplicateStmt->execute([$orderId, $bucket, $candidateText]);
    if ($duplicateStmt->fetchColumn() !== false) {
        voiceCallLog('addCandidate() duplicate ignored', [
            'orderId' => $orderId,
            'bucket' => $bucket,
        ]);
        return;
    }

    $stmt = $con->prepare("
        INSERT INTO order_voice_call_candidates (
            order_id,
            bucket,
            candidate_text,
            sdp_mid,
            sdp_m_line_index,
            timestamp_ms
        ) VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $orderId,
        $bucket,
        $candidateText,
        $sdpMid,
        $sdpMLineIndex,
        $timestampMs,
    ]);
    voiceCallLog('addCandidate() done', [
        'orderId' => $orderId,
        'bucket' => $bucket,
    ]);
}

function logEvent(PDO $con, array $input): void
{
    $orderId = toIntOrNull($input['order_id'] ?? null) ?? 0;
    $eventType = cleanText($input['event_type'] ?? null) ?? '';
    $status = cleanText($input['status'] ?? null) ?? '';
    $callerRole = cleanText($input['caller_role'] ?? null);
    $callerRefId = cleanText($input['caller_ref_id'] ?? null);
    $callerName = cleanText($input['caller_name'] ?? null);
    $calleeRole = cleanText($input['callee_role'] ?? null);
    $calleeRefId = cleanText($input['callee_ref_id'] ?? null);
    $calleeName = cleanText($input['callee_name'] ?? null);
    $eventAtMs = toIntOrNull($input['event_at_ms'] ?? null) ?? nowMs();

    if ($orderId <= 0 || $eventType === '' || $status === '') {
        throw new RuntimeException('order_id, event_type and status are required');
    }

    voiceCallLog('logEvent() start', [
        'orderId' => $orderId,
        'eventType' => $eventType,
        'status' => $status,
    ]);
    $stmt = $con->prepare("
        INSERT INTO order_voice_call_events (
            order_id,
            event_type,
            status,
            caller_role,
            caller_ref_id,
            caller_name,
            callee_role,
            callee_ref_id,
            callee_name,
            event_at_ms
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $orderId,
        $eventType,
        $status,
        $callerRole,
        $callerRefId,
        $callerName,
        $calleeRole,
        $calleeRefId,
        $calleeName,
        $eventAtMs,
    ]);
    voiceCallLog('logEvent() done', [
        'orderId' => $orderId,
        'eventType' => $eventType,
        'status' => $status,
    ]);
}

function respondSuccess(array $data = [], string $message = 'success'): void
{
    echo json_encode([
        'status' => 'success',
        'message' => $message,
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function respondError(string $message, int $code = 400): void
{
    http_response_code($code);
    echo json_encode([
        'status' => 'error',
        'message' => $message,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $orderId = toIntOrNull($_GET['order_id'] ?? null) ?? 0;
    if ($orderId <= 0) {
        respondError('order_id is required');
    }

    try {
        voiceCallLog('GET session request', ['orderId' => $orderId]);
        $payload = fetchSessionPayload($con, $orderId) ?? [];
        respondSuccess($payload, 'loaded');
    } catch (Throwable $e) {
        voiceCallLogError('GET session request failed', $e, ['orderId' => $orderId]);
        respondError($e->getMessage(), 500);
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respondError('POST required');
}

$action = strtolower(trim((string)($_POST['action'] ?? '')));

try {
    if ($action === 'session_upsert') {
        voiceCallLog('POST action session_upsert', ['orderId' => toIntOrNull($_POST['order_id'] ?? null) ?? 0]);
        upsertSession($con, $_POST);
        $orderId = toIntOrNull($_POST['order_id'] ?? null) ?? 0;
        respondSuccess(fetchSessionPayload($con, $orderId) ?? [], 'session_saved');
    }

    if ($action === 'session_patch') {
        voiceCallLog('POST action session_patch', ['orderId' => toIntOrNull($_POST['order_id'] ?? null) ?? 0]);
        patchSession($con, $_POST);
        $orderId = toIntOrNull($_POST['order_id'] ?? null) ?? 0;
        respondSuccess(fetchSessionPayload($con, $orderId) ?? [], 'session_saved');
    }

    if ($action === 'session_clear') {
        $orderId = toIntOrNull($_POST['order_id'] ?? null) ?? 0;
        if ($orderId <= 0) {
            respondError('order_id is required');
        }
        voiceCallLog('POST action session_clear', ['orderId' => $orderId]);
        clearSession($con, $orderId);
        respondSuccess([], 'session_cleared');
    }

    if ($action === 'candidate_add') {
        voiceCallLog('POST action candidate_add', ['orderId' => toIntOrNull($_POST['order_id'] ?? null) ?? 0]);
        addCandidate($con, $_POST);
        $orderId = toIntOrNull($_POST['order_id'] ?? null) ?? 0;
        respondSuccess(fetchSessionPayload($con, $orderId) ?? [], 'candidate_added');
    }

    if ($action === 'session_get') {
        $orderId = toIntOrNull($_POST['order_id'] ?? null) ?? 0;
        if ($orderId <= 0) {
            respondError('order_id is required');
        }
        voiceCallLog('POST action session_get', ['orderId' => $orderId]);
        respondSuccess(fetchSessionPayload($con, $orderId) ?? [], 'loaded');
    }

    voiceCallLog('POST action logEvent', [
        'orderId' => toIntOrNull($_POST['order_id'] ?? null) ?? 0,
        'eventType' => $_POST['event_type'] ?? null,
        'status' => $_POST['status'] ?? null,
    ]);
    logEvent($con, $_POST);
    respondSuccess([], 'logged');
} catch (Throwable $e) {
    voiceCallLogError('POST action failed', $e, [
        'orderId' => toIntOrNull($_POST['order_id'] ?? null) ?? 0,
        'action' => $action,
    ]);
    respondError($e->getMessage(), 500);
}
