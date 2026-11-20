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

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$email = strtolower(trim((string)($payload['email'] ?? '')));
$password = (string)($payload['password'] ?? '');
$portal = strtolower(trim((string)($payload['portal'] ?? '')));
$portalByRole = [
    2 => 'finance',
    10 => 'finance',
    11 => 'support',
    12 => 'operations',
    13 => 'merchants',
    14 => 'analytics',
    15 => 'legal',
];

if ($email === '' || $password === '') {
    respondJson([
        'status' => 'error',
        'message' => 'Email and password are required',
    ], 400);
}

try {
    ensureMasterPortalRoles();
    $stmt = $con->prepare("
        SELECT
            a.*,
            rp.role_id AS master_role_id,
            rp.role_name AS master_role_name,
            rp.role_scope AS master_role_scope,
            rp.permissions_json AS master_role_permissions_json,
            rp.tint_hex AS master_role_tint_hex,
            rp.sort_order AS master_role_sort_order
        FROM admin a
        LEFT JOIN master_role_profiles rp
            ON rp.role_id = a.admin_role_id
        WHERE LOWER(a.admin_email) = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$admin) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid email or password',
        ], 401);
    }

    $approvalStatus = strtolower(trim((string)($admin['master_approval_status'] ?? '')));
    if ((int)($admin['admin_approve'] ?? 0) !== 1 ||
        ($approvalStatus !== '' && $approvalStatus !== 'approved')) {
        respondJson([
            'status' => 'error',
            'message' => $approvalStatus === 'rejected'
                ? 'Account request was rejected by the primary admin'
                : ($approvalStatus === 'suspended'
                    ? 'Account is suspended'
                    : 'Account is waiting for primary admin approval'),
        ], 403);
    }

    $storedPassword = (string)($admin['admin_password'] ?? '');
    $matchesHashedPassword =
        $storedPassword !== '' && password_verify($password, $storedPassword);
    $matchesLegacyPlainPassword =
        $storedPassword !== '' && hash_equals($storedPassword, $password);

    if (!$matchesHashedPassword && !$matchesLegacyPlainPassword) {
        respondJson([
            'status' => 'error',
            'message' => 'Invalid email or password',
        ], 401);
    }

    // A portal login is scoped to one department. The owner/super admin may
    // enter every portal, while department accounts are permanently bound to
    // the portal represented by their role. This is enforced server-side even
    // when a caller bypasses the Flutter client.
    $roleId = (int)($admin['admin_role_id'] ?? 0);
    $assignedPortal = trim((string)($admin['master_portal_key'] ?? ''));
    if ($assignedPortal === '') {
        $assignedPortal = $portalByRole[$roleId] ?? null;
    }
    if ($assignedPortal !== null) {
        if ($portal !== '' && $portal !== $assignedPortal) {
            respondJson([
                'status' => 'error',
                'message' => 'هذا الحساب غير مصرح له بدخول البوابة المختارة',
            ], 403);
        }
        $portal = $assignedPortal;
    } elseif ($portal !== '') {
        $portalPermissions = [
            'finance' => 'finance.view',
            'support' => 'support.view',
            'operations' => 'orders.view',
            'merchants' => 'restaurants.view',
            'analytics' => 'reports.view',
            'legal' => 'settings.view',
        ];
        if (!array_key_exists($portal, $portalPermissions)) {
            respondJson([
                'status' => 'error',
                'message' => 'Unknown portal',
            ], 400);
        }
        if (!masterHasPermission($admin, $portalPermissions[$portal])) {
            respondJson([
                'status' => 'error',
                'message' => 'هذا الحساب غير مصرح له بدخول البوابة المختارة',
            ], 403);
        }
    }

    // Upgrade legacy plain-text passwords to a secure hash after first
    // successful login so old admin accounts keep working.
    if ($matchesLegacyPlainPassword && !$matchesHashedPassword) {
        $newHash = password_hash($password, PASSWORD_DEFAULT);
        $updateStmt = $con->prepare("
            UPDATE admin
            SET admin_password = :admin_password
            WHERE admin_id = :admin_id
        ");
        $updateStmt->execute([
            ':admin_password' => $newHash,
            ':admin_id' => $admin['admin_id'],
        ]);
    }

    $touchStmt = $con->prepare("
        UPDATE admin
        SET admin_last_login_at = NOW()
        WHERE admin_id = :admin_id
    ");
    $touchStmt->execute([':admin_id' => $admin['admin_id']]);

    $session = createMasterSession((int)$admin['admin_id']);

    respondJson([
        'status' => 'success',
        'role' => 'master',
        'message' => 'Login successful',
        'token' => $session['token'],
        'expires_at' => $session['expires_at'],
        'portal' => $portal !== '' ? $portal : null,
        'master' => masterPublicData($admin),
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
