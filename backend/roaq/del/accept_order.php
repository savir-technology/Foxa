<?php
header("Content-Type: application/json; charset=utf-8");

function readRequestData(): array
{
    if (!empty($_POST)) {
        return $_POST;
    }

    $raw = trim((string)file_get_contents('php://input'));
    if ($raw === '') {
        return [];
    }

    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        return $decoded;
    }

    parse_str($raw, $parsed);
    return is_array($parsed) ? $parsed : [];
}

$parsedData = readRequestData();
if (!isset($parsedData['action'])) {
    $parsedData['action'] = 'accept';
}
$_POST = $parsedData;

require __DIR__ . '/driver_order_action.php';
