<?php
$serviceAccountPath = __DIR__ . '/service-account.json';
$serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);

$header = base64_encode(json_encode([
    "alg" => "RS256",
    "typ" => "JWT"
]));

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

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "https://oauth2.googleapis.com/token");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion" => $jwt
]));
$response = curl_exec($ch);
curl_close($ch);

echo "<pre>AccessTokenResponse:\n$response</pre>";
?>
