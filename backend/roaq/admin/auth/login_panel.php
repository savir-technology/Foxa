<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../connect.php';

const ALL_MODULES = ['super_admin', 'accounts', 'crm', 'property', 'content'];

function normalizeModules($rawModules)
{
    if (!is_array($rawModules)) {
        return [];
    }

    $allowed = array_fill_keys(ALL_MODULES, true);
    $normalized = [];
    foreach ($rawModules as $module) {
        $key = strtolower(trim((string)$module));
        if ($key !== '' && isset($allowed[$key]) && !in_array($key, $normalized, true)) {
            $normalized[] = $key;
        }
    }
    return $normalized;
}

function modulesFromCsv($raw)
{
    $value = trim((string)$raw);
    if ($value === '') return [];
    return normalizeModules(explode(',', $value));
}

function hasColumn(PDO $con, $table, $column)
{
    $stmt = $con->prepare("SHOW COLUMNS FROM `$table` LIKE :col");
    $stmt->execute([':col' => $column]);
    return (bool)$stmt->fetch(PDO::FETCH_ASSOC);
}

function resolveModules(PDO $con, $accountType, $accountId, $email)
{
    // 1) Explicit per-account permissions table (optional).
    $hasPermTable = (bool)$con->query("SHOW TABLES LIKE 'admin_module_permissions'")->fetchColumn();
    if ($hasPermTable) {
        $stmt = $con->prepare(
            "SELECT module_key, is_enabled
             FROM admin_module_permissions
             WHERE account_type = :account_type
               AND account_id = :account_id"
        );
        $stmt->execute([
            ':account_type' => $accountType,
            ':account_id' => intval($accountId),
        ]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($rows)) {
            $modules = [];
            foreach ($rows as $row) {
                if (intval($row['is_enabled'] ?? 0) === 1) {
                    $modules[] = (string)($row['module_key'] ?? '');
                }
            }
            $parsed = normalizeModules($modules);
            if (!empty($parsed)) return $parsed;
        }
    }

    // 2) Optional CSV columns in admin/users table.
    if ($accountType === 'admin' && hasColumn($con, 'admin', 'dashboard_modules')) {
        $stmt = $con->prepare("SELECT dashboard_modules FROM admin WHERE admin_id = :id LIMIT 1");
        $stmt->execute([':id' => intval($accountId)]);
        $csv = $stmt->fetchColumn();
        $parsed = modulesFromCsv($csv);
        if (!empty($parsed)) return $parsed;
    }
    if ($accountType === 'employee' && hasColumn($con, 'users', 'dashboard_modules')) {
        $stmt = $con->prepare("SELECT dashboard_modules FROM users WHERE users_id = :id LIMIT 1");
        $stmt->execute([':id' => intval($accountId)]);
        $csv = $stmt->fetchColumn();
        $parsed = modulesFromCsv($csv);
        if (!empty($parsed)) return $parsed;
    }

    // 3) Fallback defaults.
    if ($accountType === 'admin') {
        return ALL_MODULES;
    }
    return ['accounts', 'crm', 'property', 'content'];
}

$email = trim((string)($_POST['email'] ?? ''));
$password = trim((string)($_POST['password'] ?? ''));

if ($email === '' || $password === '') {
    echo json_encode([
        'status' => 'fail',
        'message' => 'Email and password are required'
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

try {
    // 1) Primary panel admin account.
    $stmtAdmin = $con->prepare(
        "SELECT admin_id, admin_name, admin_email, admin_password, admin_approve
         FROM admin
         WHERE admin_email = :email
         LIMIT 1"
    );
    $stmtAdmin->execute([':email' => $email]);
    $admin = $stmtAdmin->fetch(PDO::FETCH_ASSOC);

    if ($admin && intval($admin['admin_approve']) === 1 && password_verify($password, (string)$admin['admin_password'])) {
        $chatAdminUserId = 0;
        $chatStmt = $con->prepare(
            "SELECT users_id
             FROM users
             WHERE users_email = :email AND user_role = 'admin'
             LIMIT 1"
        );
        $chatStmt->execute([':email' => $email]);
        $chatAdminUserId = intval($chatStmt->fetchColumn() ?: 0);
        if ($chatAdminUserId <= 0) {
            $fallbackStmt = $con->query("SELECT users_id FROM users WHERE user_role = 'admin' LIMIT 1");
            $chatAdminUserId = intval($fallbackStmt->fetchColumn() ?: 0);
        }

        echo json_encode([
            'status' => 'success',
            'message' => 'Login successful',
            'data' => [
                'id' => intval($admin['admin_id']),
                'name' => (string)$admin['admin_name'],
                'email' => (string)$admin['admin_email'],
                'role' => 'admin',
                'chat_user_id' => $chatAdminUserId,
                'modules' => resolveModules($con, 'admin', intval($admin['admin_id']), (string)$admin['admin_email']),
            ]
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    // 2) Employee account (from users table with admin role).
    $stmtEmployee = $con->prepare(
        "SELECT users_id, users_name, users_email, users_password, users_approve, password_hashed, user_role
         FROM users
         WHERE users_email = :email
         LIMIT 1"
    );
    $stmtEmployee->execute([':email' => $email]);
    $employee = $stmtEmployee->fetch(PDO::FETCH_ASSOC);

    if ($employee && intval($employee['users_approve']) === 1 && (string)$employee['user_role'] === 'admin') {
        $isHashed = intval($employee['password_hashed']) === 1;
        $ok = $isHashed
            ? password_verify($password, (string)$employee['users_password'])
            : hash_equals((string)$employee['users_password'], $password);

        if ($ok) {
            echo json_encode([
                'status' => 'success',
                'message' => 'Login successful',
                'data' => [
                    'id' => intval($employee['users_id']),
                    'name' => (string)$employee['users_name'],
                    'email' => (string)$employee['users_email'],
                    'role' => 'employee',
                    'chat_user_id' => intval($employee['users_id']),
                    'modules' => resolveModules($con, 'employee', intval($employee['users_id']), (string)$employee['users_email']),
                ]
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            exit;
        }
    }

    echo json_encode([
        'status' => 'fail',
        'message' => 'Invalid credentials or account is not permitted for dashboard'
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('login_panel.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
