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

function masterUsersWalletError(string $message, int $statusCode = 400): void
{
    respondJson([
        'status' => 'error',
        'message' => $message,
    ], $statusCode);
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'customers.edit');
    $payload = getRequestPayload();
    $userId = (int)($payload['user_id'] ?? 0);

    if ($userId <= 0) {
        masterUsersWalletError('معرف المستخدم مطلوب');
    }

    if (!tableExists('users')) {
        masterUsersWalletError('جدول المستخدمين غير متاح');
    }

    $userStmt = $con->prepare("
        SELECT users_id
        FROM users
        WHERE users_id = :user_id
        LIMIT 1
    ");
    $userStmt->execute([':user_id' => $userId]);
    if (!$userStmt->fetchColumn()) {
        masterUsersWalletError('المستخدم غير موجود', 404);
    }

    $walletRequiredColumns = ['id', 'user_id', 'points', 'balance'];
    if (!tableExists('wallet')) {
        masterUsersWalletError('جدول المحفظة غير متاح. طبّق migration 20260818_master_wallet_tables.sql أولًا.', 409);
    }
    foreach ($walletRequiredColumns as $column) {
        if (!columnExists('wallet', $column)) {
            masterUsersWalletError('بنية المحفظة غير مكتملة. طبّق migration 20260818_master_wallet_tables.sql أولًا.', 409);
        }
    }

    $walletStmt = $con->prepare("
        SELECT " . (columnExists('wallet', 'id') ? 'id' : 'user_id') . " AS wallet_key
        FROM wallet
        WHERE user_id = :user_id
        LIMIT 1
    ");
    $walletStmt->execute([':user_id' => $userId]);
    $walletKey = $walletStmt->fetchColumn();

    if (!$walletKey) {
        $insertWallet = $con->prepare("
            INSERT INTO wallet (user_id, points, balance)
            VALUES (:user_id, 0, 0)
        ");
        $insertWallet->execute([':user_id' => $userId]);
    }

    respondJson([
        'status' => 'success',
        'message' => $walletKey ? 'المحفظة موجودة بالفعل' : 'تم إنشاء محفظة للمستخدم',
        'data' => [
            'user_id' => $userId,
            'wallet_exists' => true,
        ],
    ]);
} catch (Throwable $e) {
    masterUsersWalletError($e->getMessage(), 500);
}
