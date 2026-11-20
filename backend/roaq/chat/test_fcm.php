<?php
date_default_timezone_set('UTC');
header('Content-Type: application/json; charset=utf-8');

$debugLog = __DIR__ . "/debug_fcm_log.txt";
file_put_contents($debugLog, "=== Test FCM Started ===\n", FILE_APPEND);

// 🔹 بيانات تجريبية
$fcm_token = "ضع هنا توكين الجهاز للتجربة";
$serviceAccountPath = __DIR__ . '/firebase/service-account.json';
$serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
$projectId = "savir-15-1-2003";

// 🔹 طباعة معلومات Service Account
file_put_contents($debugLog, "Service Account Email: " . $serviceAccount['client_email'] . "\n", FILE_APPEND);
file_put_contents($debugLog, "Project ID: $projectId\n", FILE_APPEND);

// 🔹 إنشاء JWT
$header = base64_encode(json_encode(["alg" => "RS256", "typ" => "JWT"]));
$now = time();
$claimSet = base64_encode(json_encode([
    "iss" => $serviceAccount["client_email"],
    "scope" => "https://www.googleapis.com/auth/firebase.messaging",
    "aud" => "https://oauth2.googleapis.com/token",
    "exp" => $now + 3600,
    "iat" => $now
]));

$data = $header . '.' . $claimSet;
openssl_sign($data, $signature, openssl_pkey_get_private($serviceAccount["private_key"]), "sha256");
$jwt = $data . '.' . base64_encode($signature);

// 🔹 طلب Access Token
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "https://oauth2.googleapis.com/token");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion" => $jwt
]));
$response = curl_exec($ch);
$curl_error = curl_error($ch);
curl_close($ch);

file_put_contents($debugLog, "AccessTokenResponse:\n$response\nCURL_Error:$curl_error\n\n", FILE_APPEND);

$tokenData = json_decode($response, true);
$accessToken = $tokenData['access_token'] ?? null;

if (!$accessToken) {
    echo json_encode(["status" => "fail", "message" => "Failed to fetch access token. Check debug_fcm_log.txt"]);
    exit;
}

// 🔹 إرسال إشعار FCM تجريبي
$url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";
$notification = [
    "message" => [
        "token" => $fcm_token,
        "notification" => [
            "title" => "📩 إشعار تجريبي",
            "body" => "هذا إشعار تجريبي من السيرفر"
        ],
        "data" => [
            "click_action" => "FLUTTER_NOTIFICATION_CLICK",
            "type" => "test"
        ]
    ]
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer $accessToken",
    "Content-Type: application/json"
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($notification));
$result = curl_exec($ch);
$error = curl_error($ch);
curl_close($ch);

file_put_contents($debugLog, "SendResult:\n$result\nError:$error\n\n", FILE_APPEND);

echo json_encode(["status" => "success", "message" => "Check debug_fcm_log.txt for details"]);
?>
