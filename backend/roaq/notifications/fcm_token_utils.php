<?php

if (!function_exists('normalizeFcmToken')) {
    function normalizeFcmToken(?string $token): string
    {
        $normalized = trim((string)$token);
        if ($normalized === '' || strtolower($normalized) === 'null') {
            return '';
        }

        return $normalized;
    }
}

if (!function_exists('fcmTokenFingerprint')) {
    function fcmTokenFingerprint(string $token): string
    {
        $normalized = normalizeFcmToken($token);
        if ($normalized === '') {
            return 'empty';
        }

        return sprintf('sha256:%s(len=%d)', substr(hash('sha256', $normalized), 0, 12), strlen($normalized));
    }
}

if (!function_exists('normalizeFcmTokenList')) {
    function normalizeFcmTokenList(array $tokens): array
    {
        $normalized = [];
        $seen = [];

        foreach ($tokens as $token) {
            $candidate = normalizeFcmToken(is_string($token) ? $token : (string)$token);
            if ($candidate === '' || isset($seen[$candidate])) {
                continue;
            }

            $seen[$candidate] = true;
            $normalized[] = $candidate;
        }

        return $normalized;
    }
}

if (!function_exists('notificationFlowLog')) {
    function notificationFlowLog(string $message, array $data = []): void
    {
        $suffix = '';
        if (!empty($data)) {
            $encoded = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            if ($encoded !== false) {
                $suffix = ' ' . $encoded;
            }
        }

        $line = '[FCM FLOW] ' . $message . $suffix;
        error_log($line);

        if (defined('FCM_LOG_FILE') && FCM_LOG_FILE !== '') {
            @file_put_contents(FCM_LOG_FILE, $line . PHP_EOL, FILE_APPEND);
        }
    }
}

if (!function_exists('purgeDuplicateUserFcmToken')) {
    function purgeDuplicateUserFcmToken(PDO $con, int $userId, string $token): void
    {
        $normalized = normalizeFcmToken($token);
        if ($userId <= 0 || $normalized === '') {
            return;
        }

        try {
            $stmt = $con->prepare("
                UPDATE users
                SET fcm_token = NULL
                WHERE users_id <> :user_id
                  AND fcm_token = :token
            ");
            $stmt->execute([
                ':user_id' => $userId,
                ':token' => $normalized,
            ]);

            notificationFlowLog('purgeDuplicateUserFcmToken()', [
                'userId' => $userId,
                'tokenFingerprint' => fcmTokenFingerprint($normalized),
                'clearedRows' => $stmt->rowCount(),
            ]);
        } catch (Throwable $error) {
            error_log('purgeDuplicateUserFcmToken failed: ' . $error->getMessage());
        }
    }
}
