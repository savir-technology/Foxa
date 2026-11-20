<?php

define('FCM_LOG_FILE', __DIR__ . '/debug_fcm_log.txt');
define('FCM_SERVICE_ACCOUNT_PATH', __DIR__ . '/service-account.json');
require_once __DIR__ . '/../../notifications/fcm_token_utils.php';

function loadFcmConfig()
{
    if (!file_exists(FCM_SERVICE_ACCOUNT_PATH)) {
        file_put_contents(FCM_LOG_FILE, "Service account file not found.\n", FILE_APPEND);
        notificationFlowLog('loadFcmConfig() missing service account file');
        return null;
    }

    $serviceAccount = json_decode(file_get_contents(FCM_SERVICE_ACCOUNT_PATH), true);
    if (!is_array($serviceAccount)) {
        file_put_contents(FCM_LOG_FILE, "Failed to decode service account JSON.\n", FILE_APPEND);
        notificationFlowLog('loadFcmConfig() failed to decode service account JSON');
        return null;
    }

    $projectId = trim((string)($serviceAccount['project_id'] ?? ''));
    $clientEmail = trim((string)($serviceAccount['client_email'] ?? ''));
    $privateKey = (string)($serviceAccount['private_key'] ?? '');

    if ($projectId === '' || $clientEmail === '' || $privateKey === '') {
        file_put_contents(FCM_LOG_FILE, "Service account is missing required keys.\n", FILE_APPEND);
        notificationFlowLog('loadFcmConfig() service account missing required keys', [
            'projectIdPresent' => $projectId !== '',
            'clientEmailPresent' => $clientEmail !== '',
            'privateKeyPresent' => $privateKey !== '',
        ]);
        return null;
    }

    return [
        'project_id' => $projectId,
        'client_email' => $clientEmail,
        'private_key' => $privateKey,
    ];
}

function fetchFcmAccessToken($config)
{
    notificationFlowLog('fetchFcmAccessToken() start', [
        'projectId' => $config['project_id'] ?? '',
        'clientEmail' => $config['client_email'] ?? '',
    ]);

    $jwtHeader = base64_encode(json_encode([
        'alg' => 'RS256',
        'typ' => 'JWT',
    ]));

    $now = time();
    $jwtClaimSet = base64_encode(json_encode([
        'iss' => $config['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now,
    ]));

    $unsignedJwt = $jwtHeader . '.' . $jwtClaimSet;
    $privateKeyResource = openssl_pkey_get_private($config['private_key']);
    if ($privateKeyResource === false) {
        file_put_contents(FCM_LOG_FILE, "Failed to load private key from service account.\n", FILE_APPEND);
        notificationFlowLog('fetchFcmAccessToken() failed to load private key', [
            'projectId' => $config['project_id'] ?? '',
        ]);
        return null;
    }

    openssl_sign($unsignedJwt, $signature, $privateKeyResource, 'sha256');
    $jwt = $unsignedJwt . '.' . base64_encode($signature);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt,
    ]));
    $tokenResponse = curl_exec($ch);
    $tokenCurlError = curl_error($ch);
    curl_close($ch);

    file_put_contents(
        FCM_LOG_FILE,
        "ProjectId: {$config['project_id']}\nClientEmail: {$config['client_email']}\nAccessTokenResponse:\n$tokenResponse\nCURL_Error:$tokenCurlError\n\n",
        FILE_APPEND
    );
    notificationFlowLog('fetchFcmAccessToken() response', [
        'projectId' => $config['project_id'] ?? '',
        'responseLength' => is_string($tokenResponse) ? strlen($tokenResponse) : 0,
        'curlError' => $tokenCurlError,
    ]);

    $tokenData = json_decode((string)$tokenResponse, true);
    $accessToken = $tokenData['access_token'] ?? null;
    if (!$accessToken) {
        file_put_contents(FCM_LOG_FILE, "Failed to fetch access token.\n", FILE_APPEND);
        notificationFlowLog('fetchFcmAccessToken() failed', [
            'projectId' => $config['project_id'] ?? '',
        ]);
        return null;
    }

    return $accessToken;
}

function sendFcmTarget($title, $body, $target, $targetType = 'token', $dataPayload = [])
{
    $config = loadFcmConfig();
    if ($config === null) {
        notificationFlowLog('sendFcmTarget() config missing', [
            'targetType' => $targetType,
            'targetFingerprint' => $targetType === 'token' ? fcmTokenFingerprint((string)$target) : (string)$target,
            'title' => $title,
        ]);
        return [
            'ok' => false,
            'http_code' => 0,
            'response' => null,
            'curl_error' => null,
            'error_code' => 'CONFIG_MISSING',
            'target' => $target,
            'target_type' => $targetType,
        ];
    }

    $target = trim((string)$target);
    if ($target === '' || strlen($target) < 3) {
        file_put_contents(FCM_LOG_FILE, "Invalid FCM target for type '$targetType': '$target'\n", FILE_APPEND);
        notificationFlowLog('sendFcmTarget() invalid target', [
            'targetType' => $targetType,
            'targetFingerprint' => $targetType === 'token' ? fcmTokenFingerprint($target) : $target,
            'title' => $title,
        ]);
        return [
            'ok' => false,
            'http_code' => 0,
            'response' => null,
            'curl_error' => null,
            'error_code' => 'INVALID_TARGET',
            'target' => $target,
            'target_type' => $targetType,
        ];
    }

    $accessToken = fetchFcmAccessToken($config);
    if (!$accessToken) {
        notificationFlowLog('sendFcmTarget() access token unavailable', [
            'targetType' => $targetType,
            'targetFingerprint' => $targetType === 'token' ? fcmTokenFingerprint($target) : $target,
            'title' => $title,
        ]);
        return [
            'ok' => false,
            'http_code' => 0,
            'response' => null,
            'curl_error' => null,
            'error_code' => 'ACCESS_TOKEN_FAILED',
            'target' => $target,
            'target_type' => $targetType,
        ];
    }

    $payloadData = [
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        'sender' => 'admin',
    ];

    foreach ($dataPayload as $key => $value) {
        $payloadData[(string)$key] = (string)$value;
    }

    $notificationType = strtolower(trim((string)($payloadData['type'] ?? '')));
    $isVoiceCallMessage = in_array($notificationType, ['voice_call', 'voice_call_status'], true);
    $channelId = $isVoiceCallMessage
        ? 'voice_call_channel'
        : 'high_importance_channel';
    $isVoiceCall = $notificationType === 'voice_call';
    $isVoiceCallStatus = $notificationType === 'voice_call_status';

    if ($isVoiceCall) {
        $payloadData['render_call_ui'] = $payloadData['render_call_ui'] ?? '1';
    } elseif ($isVoiceCallStatus) {
        $payloadData['render_call_ui'] = $payloadData['render_call_ui'] ?? '0';
    }

    if ($isVoiceCallMessage) {
        $apsPayload = [
            'content-available' => 1,
        ];
        if ($isVoiceCall) {
            $apsPayload['sound'] = 'default';
        }

        $messageBody = [
            'data' => $payloadData,
            'android' => [
                'priority' => 'HIGH',
                'ttl' => '30s',
                'direct_boot_ok' => true,
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-expiration' => (string)(time() + 30),
                ],
                'payload' => [
                    'aps' => $apsPayload,
                ],
            ],
        ];
    } else {
        $messageBody = [
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $payloadData,
            'android' => [
                'priority' => 'HIGH',
                'ttl' => '3600s',
                'notification' => [
                    'channel_id' => $channelId,
                    'sound' => 'default',
                    'visibility' => 'PUBLIC',
                    'default_vibrate_timings' => true,
                    'default_light_settings' => true,
                    'notification_priority' => 'PRIORITY_MAX',
                    'event_time' => date('c'),
                    'local_only' => false,
                    'sticky' => false,
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-expiration' => (string)(time() + 3600),
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'category' => 'GENERAL',
                    ],
                ],
            ],
        ];
    }

    if ($targetType === 'topic') {
        $messageBody['topic'] = $target;
    } else {
        if (strlen($target) < 10) {
            file_put_contents(FCM_LOG_FILE, "Invalid FCM token: '$target'\n", FILE_APPEND);
            notificationFlowLog('sendFcmTarget() token too short', [
                'targetFingerprint' => fcmTokenFingerprint($target),
                'title' => $title,
            ]);
            return [
                'ok' => false,
                'http_code' => 0,
                'response' => null,
                'curl_error' => null,
                'error_code' => 'INVALID_TOKEN',
                'target' => $target,
                'target_type' => $targetType,
            ];
        }
        $messageBody['token'] = $target;
    }

    $message = ['message' => $messageBody];
    $url = "https://fcm.googleapis.com/v1/projects/{$config['project_id']}/messages:send";
    notificationFlowLog('sendFcmTarget() request', [
        'targetType' => $targetType,
        'targetFingerprint' => $targetType === 'token' ? fcmTokenFingerprint($target) : $target,
        'title' => $title,
        'notificationType' => $notificationType,
        'channelId' => $channelId,
        'notificationId' => (string)($payloadData['notification_id'] ?? ''),
        'dataKeys' => array_keys($payloadData),
    ]);

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $accessToken",
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    $sendResponse = curl_exec($ch);
    $sendCurlError = curl_error($ch);
    $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    file_put_contents(
        FCM_LOG_FILE,
        "TargetType:$targetType\nTarget:$target\nSendResult:\n$sendResponse\nError:$sendCurlError\n\n",
        FILE_APPEND
    );
    notificationFlowLog('sendFcmTarget() response', [
        'targetType' => $targetType,
        'targetFingerprint' => $targetType === 'token' ? fcmTokenFingerprint($target) : $target,
        'title' => $title,
        'notificationType' => $notificationType,
        'httpCode' => $httpCode,
        'curlError' => $sendCurlError,
        'responseLength' => is_string($sendResponse) ? strlen($sendResponse) : 0,
    ]);

    $responseData = json_decode((string)$sendResponse, true);
    $errorCode = null;
    if (is_array($responseData)) {
        $errorCode = (string)(
            $responseData['error']['details'][0]['errorCode']
            ?? $responseData['error']['status']
            ?? ''
        );
        if (isset($responseData['name'])) {
            return [
                'ok' => true,
                'http_code' => $httpCode,
                'response' => $responseData,
                'curl_error' => $sendCurlError,
                'error_code' => null,
                'target' => $target,
                'target_type' => $targetType,
            ];
        }
    }

    return [
        'ok' => false,
        'http_code' => $httpCode,
        'response' => $responseData ?? $sendResponse,
        'curl_error' => $sendCurlError,
        'error_code' => $errorCode ?: ($sendCurlError !== '' ? 'CURL_ERROR' : 'UNKNOWN_ERROR'),
        'target' => $target,
        'target_type' => $targetType,
    ];
}

function sendFCM($title, $body, $token, $dataPayload = [])
{
    return sendFcmTarget($title, $body, $token, 'token', $dataPayload);
}

function sendFCMToTopic($title, $body, $topic, $dataPayload = [])
{
    return sendFcmTarget($title, $body, $topic, 'topic', $dataPayload);
}
?>
