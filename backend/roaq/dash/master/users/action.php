<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterUserActionFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterUserActionAudit(string $action, int $userId): void
{
    global $con;
    if (!tableExists('master_audit_logs')) {
        return;
    }
    try {
        $actorName = trim((string)($GLOBALS['masterAuthAdmin']['admin_name'] ?? 'Master'));
        $stmt = $con->prepare("
            INSERT INTO master_audit_logs (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
            VALUES (:actor_name, :action_text, :entity_label, :action_time_label, :tint_hex, NOW())
        ");
        $stmt->execute([
            ':actor_name' => $actorName !== '' ? $actorName : 'Master',
            ':action_text' => "user {$action}",
            ':entity_label' => "user #{$userId}",
            ':action_time_label' => date('H:i'),
            ':tint_hex' => in_array($action, ['approve', 'update'], true) ? '#16A34A' : '#DC2626',
        ]);
    } catch (Throwable $e) {
        error_log('master user action audit failed: ' . $e->getMessage());
    }
}

try {
    $admin = requireMasterAuth();
    $GLOBALS['masterAuthAdmin'] = $admin;

    if (!tableExists('users')) {
        masterUserActionFail('Users table is not available', 404);
    }

    $payload = getRequestPayload();
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $userId = (int)($payload['user_id'] ?? 0);
    $addressId = (int)($payload['address_id'] ?? 0);
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];

    if ($action === '') {
        masterUserActionFail('Invalid user action payload');
    }

    if (in_array($action, ['block', 'ban', 'disable', 'suspend'], true)) {
        requireMasterPermission($admin, 'customers.block');
    } else {
        requireMasterPermission($admin, 'customers.edit');
    }

    if ($action === 'create') {
        $name = trim((string)($data['name'] ?? ''));
        $email = trim((string)($data['email'] ?? ''));
        $phone = trim((string)($data['phone'] ?? ''));
        if ($name === '' || $email === '') {
            masterUserActionFail('Name and email are required');
        }
        $duplicate = $con->prepare("SELECT users_id FROM users WHERE users_email = :email OR users_phone = :phone LIMIT 1");
        $duplicate->execute([':email' => $email, ':phone' => $phone]);
        if ($duplicate->fetchColumn()) {
            masterUserActionFail('A user with the same email or phone already exists', 409);
        }
        $columns = ['users_name', 'users_email'];
        $values = [':name', ':email'];
        $params = [':name' => $name, ':email' => $email];
        if (columnExists('users', 'users_phone')) {
            $columns[] = 'users_phone';
            $values[] = ':phone';
            $params[':phone'] = $phone;
        }
        if (columnExists('users', 'users_password')) {
            $columns[] = 'users_password';
            $values[] = ':password';
            $params[':password'] = bin2hex(random_bytes(8));
        }
        if (columnExists('users', 'users_verfiycode')) {
            $columns[] = 'users_verfiycode';
            $values[] = ':verify';
            $params[':verify'] = (string)random_int(10000, 99999);
        }
        if (columnExists('users', 'users_approve')) {
            $columns[] = 'users_approve';
            $values[] = '1';
        }
        if (columnExists('users', 'users_creat')) {
            $columns[] = 'users_creat';
            $values[] = 'NOW()';
        }
        $stmt = $con->prepare("INSERT INTO users (" . implode(', ', $columns) . ") VALUES (" . implode(', ', $values) . ")");
        $stmt->execute($params);
        $createdId = (int)$con->lastInsertId();
        masterUserActionAudit('create', $createdId);
        respondJson([
            'status' => 'success',
            'message' => 'User created',
            'data' => ['user_id' => $createdId],
        ]);
    }

    if (in_array($action, ['address_create', 'address_update', 'address_delete'], true)) {
        if (!tableExists('address')) {
            masterUserActionFail('Address table is not available', 404);
        }
        if ($action === 'address_create') {
            $ownerId = (int)($payload['user_id'] ?? 0);
            $title = trim((string)($data['title'] ?? ''));
            $city = trim((string)($data['city'] ?? ''));
            $street = trim((string)($data['district'] ?? $data['street'] ?? ''));
            $phone = trim((string)($data['phone'] ?? ''));
            if ($ownerId <= 0 || $title === '' || $city === '' || $street === '') {
                masterUserActionFail('User, address title, city and street are required');
            }
            $ownerStmt = $con->prepare('SELECT users_id FROM users WHERE users_id = :id LIMIT 1');
            $ownerStmt->execute([':id' => $ownerId]);
            if (!$ownerStmt->fetchColumn()) { masterUserActionFail('User was not found', 404); }
            $stmt = $con->prepare('INSERT INTO address (address_usersid, address_name, address_city, address_street, address_phone) VALUES (:user_id, :title, :city, :street, :phone)');
            $stmt->execute([':user_id' => $ownerId, ':title' => $title, ':city' => $city, ':street' => $street, ':phone' => $phone]);
            masterUserActionAudit('address_create', $ownerId);
            respondJson(['status' => 'success', 'message' => 'Address created', 'data' => ['address_id' => (int)$con->lastInsertId()]]);
        }
        if ($addressId <= 0) {
            masterUserActionFail('Address id is required');
        }
        $addressStmt = $con->prepare("SELECT * FROM address WHERE address_id = :address_id LIMIT 1");
        $addressStmt->execute([':address_id' => $addressId]);
        $address = $addressStmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($address)) {
            masterUserActionFail('Address was not found', 404);
        }

        $con->beginTransaction();
        if ($action === 'address_delete') {
            $stmt = $con->prepare("DELETE FROM address WHERE address_id = :address_id");
            $stmt->execute([':address_id' => $addressId]);
        } else {
            $title = trim((string)($data['title'] ?? $address['address_name'] ?? ''));
            $city = trim((string)($data['city'] ?? $address['address_city'] ?? ''));
            $street = trim((string)($data['district'] ?? $data['street'] ?? $address['address_street'] ?? ''));
            $phone = trim((string)($data['phone'] ?? $address['address_phone'] ?? ''));
            if ($title === '' || $city === '' || $street === '') {
                masterUserActionFail('Address title, city and street are required');
            }
            $stmt = $con->prepare("
                UPDATE address
                SET address_name = :title,
                    address_city = :city,
                    address_street = :street,
                    address_phone = :phone
                WHERE address_id = :address_id
            ");
            $stmt->execute([
                ':title' => $title,
                ':city' => $city,
                ':street' => $street,
                ':phone' => $phone,
                ':address_id' => $addressId,
            ]);
        }
        masterUserActionAudit($action, (int)($address['address_usersid'] ?? 0));
        $con->commit();
        respondJson([
            'status' => 'success',
            'message' => 'Address action completed',
            'data' => [
                'address_id' => $addressId,
                'action' => $action,
            ],
        ]);
    }

    if ($userId <= 0) {
        masterUserActionFail('User id is required');
    }

    $userStmt = $con->prepare("SELECT * FROM users WHERE users_id = :user_id LIMIT 1");
    $userStmt->execute([':user_id' => $userId]);
    $current = $userStmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($current)) {
        masterUserActionFail('User was not found', 404);
    }

    $con->beginTransaction();

    switch ($action) {
        case 'note_create':
            if (!tableExists('master_audit_logs')) {
                masterUserActionFail('Audit log table is not available', 404);
            }
            $note = trim((string)($data['note'] ?? ''));
            if ($note === '') {
                masterUserActionFail('Note text is required');
            }
            if (mb_strlen($note) > 220) {
                masterUserActionFail('Note text is too long');
            }
            $actorName = trim((string)($admin['admin_name'] ?? 'Master')) ?: 'Master';
            $noteStmt = $con->prepare("
                INSERT INTO master_audit_logs
                    (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
                VALUES (:actor, :action_text, :entity, :time_label, '#7C3AED', NOW())
            ");
            $noteStmt->execute([
                ':actor' => $actorName,
                ':action_text' => 'user note: ' . $note,
                ':entity' => 'user #' . $userId,
                ':time_label' => date('H:i'),
            ]);
            break;

        case 'update':
            $name = trim((string)($data['name'] ?? $current['users_name'] ?? ''));
            $email = trim((string)($data['email'] ?? $current['users_email'] ?? ''));
            $phone = trim((string)($data['phone'] ?? $current['users_phone'] ?? ''));
            if ($name === '' || $email === '') {
                masterUserActionFail('Name and email are required');
            }
            $stmt = $con->prepare("
                UPDATE users
                SET users_name = :name,
                    users_email = :email,
                    users_phone = :phone
                WHERE users_id = :user_id
            ");
            $stmt->execute([
                ':name' => $name,
                ':email' => $email,
                ':phone' => $phone,
                ':user_id' => $userId,
            ]);
            break;

        case 'approve':
        case 'activate':
            $stmt = $con->prepare("UPDATE users SET users_approve = 1 WHERE users_id = :user_id");
            $stmt->execute([':user_id' => $userId]);
            break;

        case 'disable':
        case 'ban':
        case 'delete':
            $sessionSql = columnExists('users', 'session_version')
                ? ', session_version = session_version + 1'
                : '';
            $stmt = $con->prepare("
                UPDATE users
                SET users_approve = 0{$sessionSql}
                WHERE users_id = :user_id
            ");
            $stmt->execute([':user_id' => $userId]);
            break;

        default:
            masterUserActionFail('Unsupported user action');
    }

    masterUserActionAudit($action, $userId);
    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'User action completed',
        'data' => [
            'user_id' => $userId,
            'action' => $action,
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    masterUserActionFail($e->getMessage(), 500);
}
