<?php
include "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    ensureMasterPortalRoles();
    $roles = array_values(array_filter(getMasterRoles(), static function ($role) {
        $roleId = (int)($role['role_id'] ?? 0);
        return $roleId >= 10 && $roleId <= 15;
    }));
    $superAdminCount = 0;

    try {
        $superAdminCount = (int)$con->query("
            SELECT COUNT(*)
            FROM admin
            WHERE admin_role_id = 1
        ")->fetchColumn();
    } catch (Throwable $ignored) {
        $superAdminCount = 0;
    }

    respondJson([
        'status' => 'success',
        'roles' => $roles,
        'can_create_super_admin' => $superAdminCount === 0,
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
