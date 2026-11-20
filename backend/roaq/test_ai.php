<?php
header("Content-Type: application/json; charset=UTF-8");

// اختبار قراءة الـ secret.env.php
$secretFile = __DIR__ . "/secret.env.php";
echo "📌 Testing secret.env.php...\n";

if (!file_exists($secretFile)) {
    exit(json_encode(["error" => "secret.env.php NOT FOUND"]));
}

$secret = include $secretFile;

if (empty($secret["OPENAI_API_KEY"])) {
    exit(json_encode(["error" => "OPENAI_API_KEY is EMPTY"], JSON_UNESCAPED_UNICODE));
}

echo "👍 secret.env.php loaded successfully!\n";

// اختبار الاتصال بـ OpenAI
echo "📌 Testing OpenAI connection...\n";

$api_key = $secret["OPENAI_API_KEY"];

$payload = [
    "model" => "gpt-4o-mini",
    "messages" => [
        ["role" => "user", "content" => "Hello, this is a test!"]
    ]
];

$ch = curl_init("https://api.openai.com/v1/chat/completions");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer {$api_key}",
    "Content-Type: application/json"
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));

$resp = curl_exec($ch);
$err = curl_error($ch);
curl_close($ch);

if ($err) {
    exit(json_encode(["error" => "CURL Error", "details" => $err], JSON_UNESCAPED_UNICODE));
}

echo "👍 OpenAI Response:\n";
echo $resp;
