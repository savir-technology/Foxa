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

$admin = requireMasterAuth();
requireMasterPermission($admin, 'dashboard.view');

$requiredTables = [
    'master_admins',
    'master_role_profiles',
    'master_role_permissions',
    'master_permissions',
    'master_audit_logs',
    'orders',
    'vendors',
    'vendor_return_requests',
    'vendor_item_stock_rules',
    'vendor_scheduled_reports',
    'vendor_printers',
    'vendor_print_settings',
    'vendor_print_jobs',
    'vendor_invoice_templates',
];

try {
    $missingTables = [];
    foreach ($requiredTables as $table) {
        if (!tableExists($table)) {
            $missingTables[] = $table;
        }
    }

    $databaseReady = false;
    try {
        $databaseReady = (int)$con->query('SELECT 1')->fetchColumn() === 1;
    } catch (Throwable $ignored) {
        $databaseReady = false;
    }

    $healthy = $databaseReady && empty($missingTables);
    respondJson([
        'status' => $healthy ? 'success' : 'degraded',
        'data' => [
            'healthy' => $healthy,
            'php_version' => PHP_VERSION,
            'database_ready' => $databaseReady,
            'missing_tables' => $missingTables,
            'checked_at' => date('c'),
        ],
    ], $healthy ? 200 : 503);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => 'Deployment health check failed',
    ], 500);
}
