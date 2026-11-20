<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";
require_once __DIR__ . '/../notifications/fcm_token_utils.php';

/**
 * Connection settings configuration
 * Returns server configuration for WebRTC connections
 */

try {
    // Get server configuration
    $serverConfig = [
        "signaling_server" => [
            "url" => "https://".$_SERVER['HTTP_HOST'], // Use the current domain
            "endpoints" => [
                "send_signal" => "/chat/send_signal_fixed.php",
                "poll_signal" => "/chat/poll_signal_fixed.php",
                "initiate_call" => "/chat/initiate_call.php",
                "handle_call" => "/chat/handle_call.php",
                "get_call_notifications" => "/chat/get_call_notifications.php",
                "save_token" => "/chat/save_token.php"
            ]
        ],
        "webrtc_config" => [
            "iceServers" => [
                // Public STUN servers
                { "urls": "stun:stun.l.google.com:19302" },
                { "urls": "stun:stun1.l.google.com:19302" },
                { "urls": "stun:stun2.l.google.com:19302" }
            ],
            "iceTransportPolicy" => "all", // Allow both UDP and TCP
            "bundlePolicy" => "max-bundle",
            "rtcpMuxPolicy" => "require"
        ],
        "call_config" => [
            "maxCallDuration" => 3600, // 1 hour in seconds
            "callTimeout" => 30, // 30 seconds
            "maxParticipants" => 2,
            "supportedCodecs" => [
                "audio": ["opus", "PCMU", "PCMA"],
                "video": ["VP8", "VP9", "H264"]
            ]
        ],
        "notification_config" => [
            "fcm" => [
                "enabled" => true,
                "priority" => "high",
                "sound" => "default",
                "vibrate" => true,
                "light" => true
            ]
        ],
        "network_config" => [
            "enableTcpFallback" => true,
            "enableUdp" => true,
            "enableTurn" => false, // Set to true if you have a TURN server
            "forceRelay" => false
        ]
    ];

    // Add any custom configuration from database if needed
    $configStmt = $con->prepare("SELECT config_key, config_value FROM app_settings WHERE section = 'connection' AND is_active = 1");
    $configStmt->execute();
    $customConfigs = $configStmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($customConfigs as $config) {
        $key = $config['config_key'];
        $value = json_decode($config['config_value'], true);
        if (json_last_error() === JSON_ERROR_NONE) {
            // Use JSON value if valid
            $serverConfig[$key] = $value;
        } else {
            // Use raw value if not valid JSON
            $serverConfig[$key] = $config['config_value'];
        }
    }

    echo json_encode([
        "status" => "success",
        "config" => $serverConfig,
        "timestamp" => date('c')
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    error_log("connection_settings.php error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => "فشل في جلب إعدادات الاتصال",
        "error" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
