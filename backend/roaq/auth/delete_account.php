<?php
include "../connect.php";
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
function deleteWhereIfAvailable(PDO $con, string $table, string $where, array $params = [], array $requiredColumns = []): void
{
    if (!tableExists($table)) {
        return;
    }
    foreach ($requiredColumns as $column) {
        if (!columnExists($table, $column)) {
            return;
        }
    }
    $stmt = $con->prepare("DELETE FROM `$table` WHERE $where");
    $stmt->execute($params);
}
try {
    $user = requireUserAuth();
    $userId = (int)($user['users_id'] ?? 0);
    if ($userId <= 0) {
        respondJson([
            'status' => 'error',
            'message' => 'Session expired',
        ], 400);
    }
    $con->beginTransaction();
    $userParam = [':user_id' => $userId];
    deleteWhereIfAvailable(
        $con,
        'user_sessions',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'notifications',
        'notification_userid = :user_id',
        $userParam,
        ['notification_userid']
    );
    deleteWhereIfAvailable(
        $con,
        'chat_messages',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'order_chat_messages',
        "sender_role = 'user' AND sender_ref_id = :user_id",
        $userParam,
        ['sender_role', 'sender_ref_id']
    );
    deleteWhereIfAvailable(
        $con,
        'address',
        'address_usersid = :user_id',
        $userParam,
        ['address_usersid']
    );
    deleteWhereIfAvailable(
        $con,
        'favorite',
        'favorite_usersid = :user_id',
        $userParam,
        ['favorite_usersid']
    );
    deleteWhereIfAvailable(
        $con,
        'wallet',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'support',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'user_spins',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'user_coupons',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'referrals',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'referrals',
        'referred_by = :user_id',
        $userParam,
        ['referred_by']
    );
    deleteWhereIfAvailable(
        $con,
        'comment_likes',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'video_likes',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'video_views',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    deleteWhereIfAvailable(
        $con,
        'ratings',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    if (tableExists('comment_likes') && tableExists('video_comments')) {
        $likesStmt = $con->prepare("
            DELETE cl
            FROM comment_likes cl
            INNER JOIN video_comments vc ON vc.comment_id = cl.comment_id
            WHERE vc.user_id = :user_id
        ");
        $likesStmt->execute($userParam);
    }
    deleteWhereIfAvailable(
        $con,
        'video_comments',
        'user_id = :user_id',
        $userParam,
        ['user_id']
    );
    $deleteUser = $con->prepare("DELETE FROM users WHERE users_id = :user_id LIMIT 1");
    $deleteUser->execute($userParam);
    if ($deleteUser->rowCount() <= 0) {
        throw new RuntimeException('User not found');
    }
    $con->commit();
    respondJson([
        'status' => 'success',
        'message' => 'Account deleted successfully',
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    respondJson([
        'status' => 'error',
        'message' => 'Unable to delete account right now.',
    ], 500);
}