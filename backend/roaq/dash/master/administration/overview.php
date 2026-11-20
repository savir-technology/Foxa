<?php
require_once "../../../connect.php";
require_once __DIR__ . "/common.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function administrationPendingRestaurants(): array
{
    global $con;
    if (!tableExists('vendors')) {
        return [];
    }

    // التأكد من وجود الأعمدة اللازمة
    $hasApprovalStatus = columnExists('vendors', 'vendor_approval_status');
    $hasApprovalNote = columnExists('vendors', 'vendor_approval_note');
    $hasSettings = tableExists('vendor_store_settings') && columnExists('vendor_store_settings', 'store_address');
    $hasCover = tableExists('vendor_store_settings') && columnExists('vendor_store_settings', 'store_banner_url');

    // تحديد الأعمدة للاستعلام
    $approvalStatusSelect = $hasApprovalStatus
        ? "v.vendor_approval_status"
        : "CASE
            WHEN v.vendor_status = 'active' AND v.vendor_is_verified = 1 THEN 'approved'
            WHEN v.vendor_status = 'suspended' THEN 'suspended'
            ELSE 'pending'
        END AS vendor_approval_status";
        
    $approvalNoteSelect = $hasApprovalNote
        ? "v.vendor_approval_note"
        : "NULL AS vendor_approval_note";
        
    $addressSelect = $hasSettings
        ? "s.store_address"
        : "'' AS store_address";
        
    $coverSelect = $hasCover
        ? "s.store_banner_url"
        : "'' AS store_banner_url";

    // بناء شروط الاستعلام
    if ($hasApprovalStatus) {
        // إذا كان عمود الحالة موجوداً، نعرض المطاعم التي لم تتم الموافقة عليها بعد
        $condition = "(
            v.vendor_approval_status IN ('pending', 'more_info', 'rejected')
            OR v.vendor_status = 'pending'
            OR v.vendor_is_verified = 0
        )";
    } else {
        // إذا لم يكن عمود الحالة موجوداً، نعرض المطاعم التي لم يتم التحقق منها أو لها حالة pending
        $condition = "(v.vendor_is_verified = 0 OR v.vendor_status = 'pending' OR v.vendor_status IS NULL)";
    }

    // تنفيذ الاستعلام
    $stmt = $con->query("
        SELECT
            v.vendor_id,
            v.vendor_name,
            v.store_name,
            v.vendor_email,
            v.vendor_phone,
            v.vendor_type,
            v.store_category,
            v.vendor_logo,
            v.vendor_status,
            v.vendor_is_verified,
            {$approvalStatusSelect},
            {$approvalNoteSelect},
            v.vendor_created_at,
            {$addressSelect},
            {$coverSelect}
        FROM vendors v
        LEFT JOIN vendor_store_settings s ON s.vendor_id = v.vendor_id
        WHERE $condition
        ORDER BY v.vendor_created_at DESC, v.vendor_id DESC
        LIMIT 100
    ");

    $rows = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $rows[] = [
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'restaurant_name' => (string)($row['store_name'] ?? ''),
            'store_name' => (string)($row['store_name'] ?? ''),
            'owner_name' => (string)($row['vendor_name'] ?? ''),
            'vendor_type' => (string)($row['vendor_type'] ?? 'restaurant'),
            'store_category' => (string)($row['store_category'] ?? ''),
            'phone' => (string)($row['vendor_phone'] ?? ''),
            'email' => (string)($row['vendor_email'] ?? ''),
            'logo' => (string)($row['vendor_logo'] ?? ''),
            'cover_image' => (string)($row['store_banner_url'] ?? ''),
            'address' => (string)($row['store_address'] ?? ''),
            'commercial_registration' => '',
            'tax_number' => '',
            'registration_date' => (string)($row['vendor_created_at'] ?? ''),
            'status' => (string)($row['vendor_approval_status'] ?? $row['vendor_status'] ?? 'pending'),
            'vendor_status' => (string)($row['vendor_status'] ?? 'pending'),
            'approval_note' => (string)($row['vendor_approval_note'] ?? ''),
            'is_verified' => (int)($row['vendor_is_verified'] ?? 0),
        ];
    }
    
    // تسجيل عدد المطاعم المعروضة للتصحيح
    error_log("Found " . count($rows) . " pending restaurants");
    
    return $rows;
}

function administrationPendingDrivers(): array
{
    global $con;
    if (!tableExists('delivery_users')) {
        return [];
    }

    $approvalSelect = columnExists('delivery_users', 'approval_status')
        ? "approval_status"
        : "'approved' AS approval_status";
    $approvalNoteSelect = columnExists('delivery_users', 'approval_note')
        ? "approval_note"
        : "NULL AS approval_note";

    $stmt = $con->query("
        SELECT
            id AS driver_id,
            name,
            phone,
            email,
            vehicle_type,
            vehicle_number,
            status,
            profile_image,
            created_at,
            {$approvalSelect},
            {$approvalNoteSelect}
        FROM delivery_users
        WHERE " . (columnExists('delivery_users', 'approval_status')
            ? "approval_status <> 'approved'"
            : "1 = 0") . "
        ORDER BY created_at DESC, id DESC
        LIMIT 100
    ");

    $rows = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $rows[] = [
            'driver_id' => (int)($row['driver_id'] ?? 0),
            'driver_name' => (string)($row['name'] ?? ''),
            'name' => (string)($row['name'] ?? ''),
            'phone' => (string)($row['phone'] ?? ''),
            'email' => (string)($row['email'] ?? ''),
            'driver_photo' => (string)($row['profile_image'] ?? ''),
            'national_id' => '',
            'driving_license' => '',
            'vehicle_license' => '',
            'vehicle_type' => (string)($row['vehicle_type'] ?? ''),
            'vehicle_number' => (string)($row['vehicle_number'] ?? ''),
            'registration_date' => (string)($row['created_at'] ?? ''),
            'status' => (string)($row['approval_status'] ?? 'pending'),
            'approval_note' => (string)($row['approval_note'] ?? ''),
            'live_status' => (string)($row['status'] ?? 'offline'),
        ];
    }
    return $rows;
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'administration.view');

    $administrators = adminModuleAdminRows();
    $roles = adminModuleRoleRows();
    $permissions = adminModulePermissionRows();
    $pendingRestaurants = administrationPendingRestaurants();
    $pendingDrivers = administrationPendingDrivers();
    $onboardingQueue = [];
    foreach ($pendingRestaurants as $restaurant) {
        $onboardingQueue[] = [
            'vendor_id' => $restaurant['vendor_id'] ?? 0,
            'vendor_name' => $restaurant['restaurant_name'] ?? '',
            'step_name' => 'Pending restaurant approval - ' . ($restaurant['registration_date'] ?? ''),
            'status_label' => 'Pending',
            'tint_hex' => '#F59E0B',
        ];
    }
    foreach ($pendingDrivers as $driver) {
        $onboardingQueue[] = [
            'driver_id' => $driver['driver_id'] ?? 0,
            'vendor_name' => $driver['driver_name'] ?? '',
            'step_name' => 'Pending driver approval - ' . ($driver['registration_date'] ?? ''),
            'status_label' => 'Pending',
            'tint_hex' => '#3B82F6',
        ];
    }

    respondJson([
        'status' => 'success',
        'data' => [
            'master' => masterPublicData($admin),
            'administrators' => $administrators,
            'employees' => $administrators,
            'roles' => $roles,
            'permissions' => $permissions,
            'pending_restaurants' => $pendingRestaurants,
            'pending_drivers' => $pendingDrivers,
            'onboarding_queue' => $onboardingQueue,
            'can_manage_roles' => adminModuleIsSuperAdmin($admin),
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
