<?php

function call_openai($prompt) {

    // تحميل الملف السرّي
    $secretFile = __DIR__ . "/secret.env.php";
    if (!file_exists($secretFile)) {
        return ["error" => "secret.env.php file missing!"];
    }

    $secret = include $secretFile;
    $api_key = $secret["OPENAI_API_KEY"] ?? null;

    if (!$api_key) {
        return ["error" => "OPENAI_API_KEY is missing in secret.env.php"];
    }

    // إعداد طلب OpenAI
    $payload = [
        "model" => "gpt-4o-mini",
        "messages" => [
            ["role"=>"system", "content"=>"أنت مساعد افتراضي احترافي لمتجر إلكتروني. أجب بالعربية بنبرة ودودة ومختصرة، واذكر الأسعار والتوفر إن وُجد."],
            ["role"=>"user", "content"=>$prompt]
        ],
        "temperature" => 0.2,
        "max_tokens" => 500
    ];

    $ch = curl_init("https://api.openai.com/v1/chat/completions");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer {$api_key}",
        "Content-Type: application/json"
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload, JSON_UNESCAPED_UNICODE));
    $resp = curl_exec($ch);
    $err = curl_error($ch);
    curl_close($ch);

    if ($err) return ["error" => $err];

    $json = json_decode($resp, true);
    if (!$json) return ["error" => "Invalid JSON", "raw"=>$resp];

    if (isset($json['error'])) return ["error" => $json['error']];
    
    return [
        "text" => $json['choices'][0]['message']['content'] ?? '',
        "raw"  => $json
    ];
}
