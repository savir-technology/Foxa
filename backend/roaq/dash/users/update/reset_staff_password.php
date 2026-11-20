<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../../../connect.php";

$adminId = intval($_POST['admin_id'] ?? 0);
$targetUserId = intval($_POST['target_user_id'] ?? 0);

if ($adminId <= 0 || $targetUserId <= 0) {
    http_response_code(400);
    echo json_encode([
        'status' => 'fail',
        'message' => 'admin_id and target_user_id are required',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function generateTemporaryPassword(int $length = 12): string
{
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#_-';
    $maxIndex = strlen($alphabet) - 1;
    $password = '';

    for ($i = 0; $i < $length; $i++) {
        $password .= $alphabet[random_int(0, $maxIndex)];
    }

    return $password;
}

try {
    $actorStmt = $con->prepare("
        SELECT users_id, user_role, users_approve
        FROM users
        WHERE users_id = :id
        LIMIT 1
    ");
    $actorStmt->execute([':id' => $adminId]);
    $actor = $actorStmt->fetch(PDO::FETCH_ASSOC);

    if (
        !$actor ||
        intval($actor['users_approve'] ?? 0) !== 1 ||
        strtolower((string)($actor['user_role'] ?? '')) !== 'admin'
    ) {
        http_response_code(403);
        echo json_encode([
            'status' => 'fail',
            'message' => 'Only primary admin can reset staff passwords',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $targetStmt = $con->prepare("
        SELECT users_id, users_name, users_email, user_role, users_approve
        FROM users
        WHERE users_id = :id
        LIMIT 1
    ");
    $targetStmt->execute([':id' => $targetUserId]);
    $target = $targetStmt->fetch(PDO::FETCH_ASSOC);

    if (!$target) {
        http_response_code(404);
        echo json_encode([
            'status' => 'fail',
            'message' => 'Target user not found',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $staffRoles = ['accounts', 'crm', 'content', 'property', 'conect'];
    $targetRole = strtolower((string)($target['user_role'] ?? ''));
    if (!in_array($targetRole, $staffRoles, true)) {
        http_response_code(403);
        echo json_encode([
            'status' => 'fail',
            'message' => 'Password recovery is available for staff accounts only',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $temporaryPassword = generateTemporaryPassword();
    $hashedPassword = password_hash($temporaryPassword, PASSWORD_DEFAULT);

    $updateStmt = $con->prepare("
        UPDATE users
        SET users_password = :password,
            password_hashed = 1
        WHERE users_id = :id
        LIMIT 1
    ");
    $updateStmt->execute([
        ':password' => $hashedPassword,
        ':id' => $targetUserId,
    ]);

    echo json_encode([
        'status' => 'success',
        'message' => 'Temporary password created successfully',
        'data' => [
            'users_id' => $targetUserId,
            'users_name' => (string)($target['users_name'] ?? ''),
            'users_email' => (string)($target['users_email'] ?? ''),
            'user_role' => $targetRole,
            'temporary_password' => $temporaryPassword,
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('reset_staff_password.php error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
