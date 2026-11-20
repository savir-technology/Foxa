<?php
header('Content-Type: application/json; charset=utf-8');
require_once "../../../connect.php";

$adminId = intval($_POST['admin_id'] ?? 0);
$rawIds = trim((string)($_POST['target_user_ids'] ?? ''));

if ($adminId <= 0 || $rawIds === '') {
    http_response_code(400);
    echo json_encode([
        'status' => 'fail',
        'message' => 'admin_id and target_user_ids are required',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

$ids = array_values(array_unique(array_filter(array_map(
    static fn($v) => intval(trim((string)$v)),
    explode(',', $rawIds)
), static fn($v) => $v > 0)));

if (empty($ids)) {
    http_response_code(400);
    echo json_encode([
        'status' => 'fail',
        'message' => 'No valid user ids provided',
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
            'message' => 'Only primary admin can delete users',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $ids = array_values(array_filter($ids, static fn($id) => $id !== $adminId));
    if (empty($ids)) {
        http_response_code(400);
        echo json_encode([
            'status' => 'fail',
            'message' => 'No users available to delete',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $in = implode(',', array_fill(0, count($ids), '?'));
    $roleStmt = $con->prepare("SELECT users_id, user_role FROM users WHERE users_id IN ($in)");
    $roleStmt->execute($ids);
    $rows = $roleStmt->fetchAll(PDO::FETCH_ASSOC);

    $deletableIds = [];
    foreach ($rows as $row) {
        $role = strtolower(trim((string)($row['user_role'] ?? '')));
        if ($role !== 'admin') {
            $deletableIds[] = intval($row['users_id'] ?? 0);
        }
    }

    if (empty($deletableIds)) {
        http_response_code(403);
        echo json_encode([
            'status' => 'fail',
            'message' => 'Selected users cannot be deleted',
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    $inDelete = implode(',', array_fill(0, count($deletableIds), '?'));
    $del = $con->prepare("DELETE FROM users WHERE users_id IN ($inDelete)");
    $del->execute($deletableIds);

    echo json_encode([
        'status' => 'success',
        'message' => 'Users deleted successfully',
        'data' => [
            'deleted_count' => intval($del->rowCount()),
            'deleted_user_ids' => $deletableIds,
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('delete_users_bulk.php error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
