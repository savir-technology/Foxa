<?php
/**
 * هذا السكريبت يقوم بإعادة تعيين صلاحيات الأدمن الأساسي (role_id = 1)
 * تشغيله مرة واحدة فقط سيحل مشكلة "تعذر تحميل بيانات الإدارة"
 */

// الاتصال بقاعدة البيانات مباشرة
require_once __DIR__ . "/../../connect.php";
require_once __DIR__ . "/../../functions.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// This maintenance endpoint changes platform-wide permissions and must never
// be callable anonymously.
$fixPermissionsAdmin = requireMasterAuth();
if (!masterHasPermission($fixPermissionsAdmin, 'super_admin')) {
    fixPermissionsRespondJson([
        'status' => 'error',
        'message' => 'Only the Super Admin can repair permissions',
    ], 403);
}

try {
    // 1. التأكد من وجود جدول صلاحيات الأدوار
    if (!fixPermissionsTableExists('master_role_permissions')) {
        fixPermissionsRespondJson([
            'status' => 'error',
            'message' => 'master_role_permissions table does not exist'
        ], 500);
    }
    
    // 2. حذف جميع صلاحيات الأدمن الأساسي (role_id = 1)
    $deleteStmt = $con->prepare("DELETE FROM master_role_permissions WHERE role_id = :role_id");
    $deleteStmt->execute([':role_id' => 1]);
    
    // 3. إدراج جميع الصلاحيات للأدمن الأساسي
    $allPermissions = [
        'dashboard.view',
        'restaurants.view', 'restaurants.approve', 'restaurants.reject', 'restaurants.suspend', 'restaurants.delete', 'restaurants.edit',
        'drivers.view', 'drivers.approve', 'drivers.reject', 'drivers.suspend', 'drivers.delete', 'drivers.edit',
        'orders.view', 'orders.edit', 'orders.cancel', 'orders.assign_driver',
        'customers.view', 'customers.edit', 'customers.block',
        'coupons.view', 'coupons.create', 'coupons.edit', 'coupons.delete',
        'reports.view', 'reports.export',
        'returns.view', 'returns.edit',
        'finance.view', 'finance.refund', 'finance.withdrawals',
        'finance.fees', 'finance.expenses', 'finance.settlements',
        'notifications.view', 'notifications.send',
        'settings.view', 'settings.edit',
        'administration.view', 'administration.create', 'administration.edit', 'administration.delete', 'administration.manage_roles',
        'super_admin',
        'Vendors', 'Restaurants', 'Drivers', 'Orders', 'Users', 'Finance', 'Reports', 'Support', 'Content', 'Settings',
    ];
    
    $insertStmt = $con->prepare("
        INSERT IGNORE INTO master_role_permissions (role_id, permission_key)
        VALUES (:role_id, :permission_key)
    ");
    
    foreach ($allPermissions as $permission) {
        $insertStmt->execute([
            ':role_id' => 1,
            ':permission_key' => $permission,
        ]);
    }
    
    // 4. تحديث خانة permissions_json في master_role_profiles
    $updateStmt = $con->prepare("
        UPDATE master_role_profiles 
        SET permissions_json = :permissions_json,
            role_name = 'Super Admin',
            role_scope = 'Full platform administration access'
        WHERE role_id = 1
    ");
    $updateStmt->execute([
        ':permissions_json' => json_encode($allPermissions, JSON_UNESCAPED_UNICODE),
    ]);
    
    // 5. التحقق من النتيجة
    $checkStmt = $con->prepare("SELECT COUNT(*) as cnt FROM master_role_permissions WHERE role_id = :role_id");
    $checkStmt->execute([':role_id' => 1]);
    $count = (int)$checkStmt->fetchColumn();
    
    if ($count > 0) {
        fixPermissionsRespondJson([
            'status' => 'success',
            'message' => "تم إصلاح صلاحيات الأدمن الأساسي بنجاح",
            'data' => [
                'permissions_count' => $count,
                'role_id' => 1,
                'role_name' => 'Super Admin',
            ]
        ]);
    } else {
        fixPermissionsRespondJson([
            'status' => 'error',
            'message' => 'لم يتم إدراج أي صلاحيات'
        ], 500);
    }
    
} catch (Throwable $e) {
    fixPermissionsRespondJson([
        'status' => 'error',
        'message' => $e->getMessage()
    ], 500);
}

/**
 * دوال مساعدة
 */
function fixPermissionsTableExists($tableName) {
    global $con;
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table_name
    ");
    $stmt->execute([':table_name' => $tableName]);
    return (int)$stmt->fetchColumn() > 0;
}

function fixPermissionsRespondJson($payload, $statusCode = 200) {
masterSetCorsHeaders();
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}
