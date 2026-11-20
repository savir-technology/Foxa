<?php
include "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$admin = requireMasterAuth();
deleteMasterSessionByToken($admin['_access_token'] ?? '');

respondJson([
    'status' => 'success',
    'message' => 'Logged out successfully',
]);
