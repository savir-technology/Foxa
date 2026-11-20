<?php
header('Content-Type: application/json; charset=utf-8');

include "../connect.php";
include "filter_repository.php";

$itemId = (int) filterRequest("itemid");
$variantId = filterRequest("variantid");
$variantId = ($variantId === null || $variantId === '') ? null : (int) $variantId;

if ($itemId <= 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "failure",
        "message" => "itemid is required"
    ]);
    exit();
}

$filter = getItemArFilter($con, $itemId, $variantId);

if ($filter === null) {
    echo json_encode([
        "status" => "failure",
        "message" => "No AR filter configured for this product"
    ]);
    exit();
}

echo json_encode([
    "status" => "success",
    "data" => $filter
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
