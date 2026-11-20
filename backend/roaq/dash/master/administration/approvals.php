<?php
require_once "../../../connect.php";
require_once __DIR__ . "/common.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function approvalsPayload(): array
{
    $payload = json_decode(file_get_contents("php://input"), true);
    if (!is_array($payload)) {
        $payload = $_POST;
    }
    return is_array($payload) ? $payload : [];
}

function ensureApprovalColumns(): void
{
    global $con;

    $required = [
        'vendors' => ['vendor_approval_status', 'vendor_approval_note'],
        'delivery_users' => ['approval_status', 'approval_note'],
    ];
    foreach ($required as $table => $columns) {
        if (!tableExists($table)) {
            respondJson([
                'status' => 'error',
                'message' => 'Approval schema is unavailable. Apply migration 20260818_master_approval_columns.sql first.',
            ], 409);
        }
        foreach ($columns as $column) {
            if (!columnExists($table, $column)) {
                respondJson([
                    'status' => 'error',
                    'message' => 'Approval schema is incomplete. Apply migration 20260818_master_approval_columns.sql first.',
                ], 409);
            }
        }
    }
    return;
    
    // التأكد من وجود جدول vendors
    if (tableExists('vendors')) {
        // التأكد من وجود عمود vendor_approval_status
        if (!columnExists('vendors', 'vendor_approval_status')) {
            try {
                // Schema changes are applied by the database migration process.
                $con->exec("
                    UPDATE vendors
                    SET vendor_approval_status = CASE
                        WHEN vendor_status = 'active' AND vendor_is_verified = 1 THEN 'approved'
                        WHEN vendor_status = 'suspended' THEN 'suspended'
                        ELSE 'pending'
                    END
                ");
                error_log("Added vendor_approval_status column to vendors table");
            } catch (Exception $e) {
                error_log("Error adding vendor_approval_status column: " . $e->getMessage());
            }
        }
        
        // التأكد من وجود عمود vendor_approval_note
        if (!columnExists('vendors', 'vendor_approval_note')) {
            try {
                // Schema changes are applied by the database migration process.
                error_log("Added vendor_approval_note column to vendors table");
            } catch (Exception $e) {
                error_log("Error adding vendor_approval_note column: " . $e->getMessage());
            }
        }
        
        // التأكد من أن المطاعم الجديدة التي لم يتم التحقق منها لها الحالة الصحيحة
        try {
            $con->exec("
                UPDATE vendors
                SET vendor_approval_status = 'pending'
                WHERE vendor_is_verified = 0 AND vendor_status = 'pending' AND vendor_approval_status IS NULL
            ");
            error_log("Updated new restaurants with pending status");
        } catch (Exception $e) {
            error_log("Error updating new restaurants status: " . $e->getMessage());
        }
    }
    
    // التأكد من وجود جدول delivery_users
    if (tableExists('delivery_users')) {
        // التأكد من وجود عمود approval_status
        if (!columnExists('delivery_users', 'approval_status')) {
            try {
                // Schema changes are applied by the database migration process.
                error_log("Added approval_status column to delivery_users table");
            } catch (Exception $e) {
                error_log("Error adding approval_status column: " . $e->getMessage());
            }
        }
        
        // التأكد من وجود عمود approval_note
        if (!columnExists('delivery_users', 'approval_note')) {
            try {
                // Schema changes are applied by the database migration process.
                error_log("Added approval_note column to delivery_users table");
            } catch (Exception $e) {
                error_log("Error adding approval_note column: " . $e->getMessage());
            }
        }
    }
}

try {
    $admin = requireMasterAuth();
    ensureApprovalColumns();

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        requireMasterPermission($admin, 'administration.view');
        require_once __DIR__ . "/overview.php";
        exit();
    }

    $payload = approvalsPayload();
    $type = strtolower(trim((string)($payload['type'] ?? $payload['entity'] ?? '')));
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $id = (int)($payload['id'] ?? $payload['vendor_id'] ?? $payload['driver_id'] ?? 0);
    $note = trim((string)($payload['note'] ?? $payload['message'] ?? ''));

    if ($type === '' || $action === '' || $id <= 0) {
        respondJson(['status' => 'error', 'message' => 'type, action, and id are required'], 400);
    }

    if ($type === 'restaurant' || $type === 'vendor') {
        $permission = [
            'approve' => 'restaurants.approve',
            'reject' => 'restaurants.reject',
            'suspend' => 'restaurants.suspend',
            'request_more_info' => 'restaurants.edit',
        ][$action] ?? '';
        if ($permission === '') {
            respondJson(['status' => 'error', 'message' => 'Unsupported restaurant approval action'], 400);
        }
        requireMasterPermission($admin, $permission);

        $approvalStatus = 'pending';
        $vendorStatus = 'pending';
        $verified = 0;
        if ($action === 'approve') {
            $approvalStatus = 'approved';
            $vendorStatus = 'active';
            $verified = 1;
        } elseif ($action === 'reject') {
            $approvalStatus = 'rejected';
            $vendorStatus = 'pending';
            $verified = 0;
        } elseif ($action === 'suspend') {
            $approvalStatus = 'suspended';
            $vendorStatus = 'suspended';
            $verified = 1;
        } elseif ($action === 'request_more_info') {
            $approvalStatus = 'more_info';
            $vendorStatus = 'pending';
            $verified = 0;
        }

        $stmt = $con->prepare("
            UPDATE vendors
            SET vendor_approval_status = :approval_status,
                vendor_approval_note = :approval_note,
                vendor_status = :vendor_status,
                vendor_is_verified = :vendor_is_verified
            WHERE vendor_id = :vendor_id
        ");
        $stmt->execute([
            ':approval_status' => $approvalStatus,
            ':approval_note' => $note !== '' ? $note : null,
            ':vendor_status' => $vendorStatus,
            ':vendor_is_verified' => $verified,
            ':vendor_id' => $id,
        ]);

        respondJson(['status' => 'success', 'message' => 'Restaurant approval updated']);
    }

    if ($type === 'driver') {
        $permission = [
            'approve' => 'drivers.approve',
            'reject' => 'drivers.reject',
            'suspend' => 'drivers.suspend',
            'request_documents' => 'drivers.edit',
        ][$action] ?? '';
        if ($permission === '') {
            respondJson(['status' => 'error', 'message' => 'Unsupported driver approval action'], 400);
        }
        requireMasterPermission($admin, $permission);

        $approvalStatus = 'pending';
        if ($action === 'approve') {
            $approvalStatus = 'approved';
        } elseif ($action === 'reject') {
            $approvalStatus = 'rejected';
        } elseif ($action === 'suspend') {
            $approvalStatus = 'suspended';
        }

        $statusSql = $action === 'approve' ? "status = 'offline'," : "status = 'offline',";
        $stmt = $con->prepare("
            UPDATE delivery_users
            SET {$statusSql}
                approval_status = :approval_status,
                approval_note = :approval_note
            WHERE id = :driver_id
        ");
        $stmt->execute([
            ':approval_status' => $approvalStatus,
            ':approval_note' => $note !== '' ? $note : null,
            ':driver_id' => $id,
        ]);

        respondJson(['status' => 'success', 'message' => 'Driver approval updated']);
    }

    respondJson(['status' => 'error', 'message' => 'Unsupported approval type'], 400);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
