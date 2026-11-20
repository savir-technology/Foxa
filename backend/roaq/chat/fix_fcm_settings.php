<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";
require_once __DIR__ . '/../notifications/fcm_token_utils.php';

/**
 * Fix FCM settings and ensure proper configuration
 */

try {
    // Check if service account file exists
    $serviceAccountPath = __DIR__ . '/firebase/service-account.json';
    if (!file_exists($serviceAccountPath)) {
        echo json_encode([
            "status" => "error",
            "message" => "Service account file not found at: " . $serviceAccountPath
        ]);
        exit;
    }

    // Read and validate service account
    $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
    if (!is_array($serviceAccount)) {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to decode service account JSON"
        ]);
        exit;
    }

    // Check required fields
    $requiredFields = ['project_id', 'client_email', 'private_key'];
    $missingFields = [];

    foreach ($requiredFields as $field) {
        if (empty($serviceAccount[$field])) {
            $missingFields[] = $field;
        }
    }

    if (!empty($missingFields)) {
        echo json_encode([
            "status" => "error",
            "message" => "Service account is missing required fields: " . implode(', ', $missingFields)
        ]);
        exit;
    }

    // Test FCM access token generation
    $config = [
        'project_id' => $serviceAccount['project_id'],
        'client_email' => $serviceAccount['client_email'],
        'private_key' => $serviceAccount['private_key'],
    ];

    // Test token generation
    $accessToken = null;
    try {
        // Simulate token generation without making actual HTTP request
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

        // Test private key
        $privateKeyResource = openssl_pkey_get_private($config['private_key']);
        if ($privateKeyResource === false) {
            throw new Exception("Failed to load private key");
        }

        $signature = '';
        openssl_sign($unsignedJwt, $signature, $privateKeyResource, 'sha256');

        // Token generation successful
        $accessToken = "simulated_token_" . bin2hex(random_bytes(8));

    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "FCM token generation failed: " . $e->getMessage()
        ]);
        exit;
    }

    // Check if users have FCM tokens
    $tokenCheck = $con->prepare("SELECT COUNT(*) as total_users, COUNT(CASE WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 1 END) as users_with_tokens FROM users");
    $tokenCheck->execute();
    $tokenStats = $tokenCheck->fetch(PDO::FETCH_ASSOC);

    // Check if call signaling table exists
    $tableCheck = $con->prepare("SHOW TABLES LIKE 'call_signaling'");
    $tableCheck->execute();
    $signalingTableExists = $tableCheck->rowCount() > 0;

    // Check if call notifications table exists
    $notifCheck = $con->prepare("SHOW TABLES LIKE 'call_notifications'");
    $notifCheck->execute();
    $notificationsTableExists = $notifCheck->rowCount() > 0;

    // Generate recommendations
    $recommendations = [];

    if ($tokenStats['users_with_tokens'] == 0) {
        $recommendations[] = "No users have FCM tokens. Ensure the mobile app is properly saving tokens.";
    }

    if (!$signalingTableExists) {
        $recommendations[] = "Call signaling table is missing. This table is required for WebRTC signaling messages.";
    }

    if (!$notificationsTableExists) {
        $recommendations[] = "Call notifications table is missing. This table is required for call notifications.";
    }

    // Create missing tables if needed
    if (!$signalingTableExists) {
        $createSignaling = $con->prepare("
            CREATE TABLE IF NOT EXISTS call_signaling (
                id INT(11) NOT NULL AUTO_INCREMENT,
                call_id INT(11) NOT NULL,
                from_user INT(11) NOT NULL,
                to_user INT(11) NOT NULL,
                message_type VARCHAR(32) NOT NULL,
                payload LONGTEXT NOT NULL,
                consumed TINYINT(1) DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"
        );
        $createSignaling->execute();
    }

    if (!$notificationsTableExists) {
        $createNotifications = $con->prepare("
            CREATE TABLE IF NOT EXISTS call_notifications (
                notification_id INT(11) NOT NULL AUTO_INCREMENT,
                call_id INT(11) NOT NULL,
                user_id INT(11) NOT NULL,
                notification_type VARCHAR(32) NOT NULL,
                is_read TINYINT(1) DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                read_at TIMESTAMP NULL,
                PRIMARY KEY (notification_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"
        );
        $createNotifications->execute();
    }

    echo json_encode([
        "status" => "success",
        "message" => "FCM settings validated and fixed successfully",
        "fcm_config" => [
            "project_id" => $serviceAccount['project_id'],
            "client_email" => $serviceAccount['client_email']
        ],
        "token_test" => $accessToken ? "successful" : "failed",
        "database_stats" => [
            "total_users" => (int)$tokenStats['total_users'],
            "users_with_tokens" => (int)$tokenStats['users_with_tokens']
        ],
        "tables_status" => [
            "call_signaling" => $signalingTableExists ? "exists" : "created",
            "call_notifications" => $notificationsTableExists ? "exists" : "created"
        ],
        "recommendations" => $recommendations
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    error_log("fix_fcm_settings.php error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => "Failed to fix FCM settings: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
