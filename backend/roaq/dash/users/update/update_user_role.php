<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../../../connect.php";

$adminId = intval($_POST['admin_id'] ?? 0);
$targetUserId = intval($_POST['target_user_id'] ?? 0);
$newRole = strtolower(trim((string)($_POST['user_role'] ?? '')));

$allowedRoles = ['admin', 'user', 'accounts', 'crm', 'content', 'property', 'conect'];

if ($adminId <= 0 || $targetUserId <= 0 || $newRole === '') {
    http_response_code(400);
    echo json_encode([
        'status' => 'fail',
        'message' => 'admin_id, target_user_id and user_role are required',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

if (!in_array($newRole, $allowedRoles, true)) {
    http_response_code(400);
    echo json_encode([
        'status' => 'fail',
        'message' => 'Invalid role',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
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
            'message' => 'Only primary admin can change roles',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $targetStmt = $con->prepare("
        SELECT users_id, user_role
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

    if (strtolower((string)($target['user_role'] ?? '')) === 'admin') {
        http_response_code(403);
        echo json_encode([
            'status' => 'fail',
            'message' => 'Primary admin role cannot be edited',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $upd = $con->prepare("
        UPDATE users
        SET user_role = :role
        WHERE users_id = :id
        LIMIT 1
    ");
    $upd->execute([
        ':role' => $newRole,
        ':id' => $targetUserId,
    ]);

    echo json_encode([
        'status' => 'success',
        'message' => 'Role updated successfully',
        'data' => [
            'users_id' => $targetUserId,
            'user_role' => $newRole,
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('update_user_role.php error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
