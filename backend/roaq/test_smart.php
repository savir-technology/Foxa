<?php
$post = [
    "question" => "ابحث عن كريم",
    "userid"   => 95
];

$ch = curl_init("https://savir-technology.online/roaqv2/smartQuery.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
$result = curl_exec($ch);
curl_close($ch);

echo $result;
