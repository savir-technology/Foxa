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

function masterFinanceActionFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterFinanceAudit(string $entity, string $action, int $id): void
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
            ':action_text' => "{$entity} {$action}",
            ':entity_label' => "{$entity} #{$id}",
            ':action_time_label' => date('H:i'),
            ':tint_hex' => in_array($action, ['save', 'credit', 'activate'], true) ? '#16A34A' : '#DC2626',
        ]);
    } catch (Throwable $e) {
        error_log('master finance action audit failed: ' . $e->getMessage());
    }
}

function masterFinanceRequireWalletTable(): void
{
    $requiredColumns = ['id', 'user_id', 'points', 'balance'];
    if (!tableExists('wallet')) {
        masterFinanceActionFail('Wallet table is not available. Apply migration 20260818_master_wallet_tables.sql first.', 409);
    }
    foreach ($requiredColumns as $column) {
        if (!columnExists('wallet', $column)) {
            masterFinanceActionFail('Wallet schema is incomplete. Apply migration 20260818_master_wallet_tables.sql first.', 409);
        }
    }
}

function masterFinanceLogEntry(string $type, float $debit, float $credit, string $description, ?int $userId = null): void
{
    global $con;
    if (!tableExists('accounting_entries')) {
        return;
    }
    $stmt = $con->prepare("
        INSERT INTO accounting_entries (entry_type, reference_table, reference_id, debit, credit, description, user_id)
        VALUES (:entry_type, :reference_table, :reference_id, :debit, :credit, :description, :user_id)
    ");
    $stmt->execute([
        ':entry_type' => $type,
        ':reference_table' => 'wallet',
        ':reference_id' => $userId,
        ':debit' => $debit,
        ':credit' => $credit,
        ':description' => $description,
        ':user_id' => $userId,
    ]);
}

try {
    $admin = requireMasterAuth();
    $GLOBALS['masterAuthAdmin'] = $admin;

    $payload = getRequestPayload();
    $entity = strtolower(trim((string)($payload['entity'] ?? '')));
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $id = (int)($payload['id'] ?? 0);
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];

    if ($entity === '' || $action === '') {
        masterFinanceActionFail('Invalid finance action payload');
    }

    if ($action === 'refund' || $entity === 'refund') {
        requireMasterPermission($admin, 'finance.refund');
    } elseif ($entity === 'wallet') {
        // Reading the finance dashboard must not grant wallet mutation rights.
        if (in_array($action, ['credit', 'debit', 'activate', 'disable'], true)) {
            requireMasterPermission($admin, 'finance.wallets');
        } else {
            requireMasterPermission($admin, 'finance.view');
        }
    } elseif ($entity === 'coupon') {
        if (in_array($action, ['delete', 'disable'], true)) {
            requireMasterPermission($admin, 'coupons.delete');
        } elseif (in_array($action, ['activate', 'save', 'create', 'update'], true)) {
            requireMasterPermission($admin, $id > 0 ? 'coupons.edit' : 'coupons.create');
        } else {
            requireMasterPermission($admin, 'coupons.view');
        }
    } elseif ($entity === 'expense') {
        requireMasterPermission($admin, 'finance.expenses');
    } elseif ($entity === 'accounting_account') {
        requireMasterPermission($admin, 'finance.expenses');
    } else {
        requireMasterPermission($admin, 'finance.view');
    }

    $con->beginTransaction();

    switch ($entity) {
        case 'wallet':
            if ($id <= 0) {
                masterFinanceActionFail('User id is required for wallet action');
            }
            if (!tableExists('users')) {
                masterFinanceActionFail('Users table is not available', 404);
            }
            $userStmt = $con->prepare("SELECT users_id FROM users WHERE users_id = :id LIMIT 1");
            $userStmt->execute([':id' => $id]);
            if (!$userStmt->fetchColumn()) {
                masterFinanceActionFail('User was not found', 404);
            }
            masterFinanceRequireWalletTable();
            $walletStmt = $con->prepare("SELECT id FROM wallet WHERE user_id = :id LIMIT 1");
            $walletStmt->execute([':id' => $id]);
            $walletId = (int)($walletStmt->fetchColumn() ?: 0);
            if ($walletId <= 0) {
                $insertWallet = $con->prepare("INSERT INTO wallet (user_id, points, balance) VALUES (:id, 0, 0)");
                $insertWallet->execute([':id' => $id]);
            }

            if ($action === 'credit' || $action === 'debit') {
                $amount = (float)($data['amount'] ?? 0);
                $points = (int)($data['points'] ?? 0);
                $note = trim((string)($data['note'] ?? 'Master wallet adjustment'));
                if ($amount <= 0 && $points <= 0) {
                    masterFinanceActionFail('Amount or points are required');
                }
                $balanceDelta = $amount > 0 ? $amount : (float)$points;
                $sign = $action === 'credit' ? 1 : -1;
                $stmt = $con->prepare("
                    UPDATE wallet
                    SET balance = GREATEST(0, balance + :balance_delta),
                        points = GREATEST(0, points + :points_delta)
                    WHERE user_id = :id
                ");
                $stmt->execute([
                    ':balance_delta' => $balanceDelta * $sign,
                    ':points_delta' => $points * $sign,
                    ':id' => $id,
                ]);
                masterFinanceLogEntry(
                    $action === 'credit' ? 'wallet_add' : 'wallet_use',
                    $action === 'credit' ? $balanceDelta : 0,
                    $action === 'debit' ? $balanceDelta : 0,
                    $note,
                    $id
                );
            } elseif ($action === 'disable') {
                $stmt = $con->prepare("UPDATE users SET users_approve = 0 WHERE users_id = :id");
                $stmt->execute([':id' => $id]);
            } elseif ($action === 'activate') {
                $stmt = $con->prepare("UPDATE users SET users_approve = 1 WHERE users_id = :id");
                $stmt->execute([':id' => $id]);
            } else {
                masterFinanceActionFail('Unsupported wallet action');
            }
            break;

        case 'accounting_account':
            if (!tableExists('accounting_accounts')) {
                masterFinanceActionFail('Accounting accounts table is not available', 409);
            }
            if ($action === 'delete') {
                if ($id <= 0) {
                    masterFinanceActionFail('Account id is required');
                }
                if (tableExists('accounting_entries')) {
                    $used = $con->prepare("SELECT COUNT(*) FROM accounting_entries WHERE reference_id = :id AND reference_table = 'accounting_accounts'");
                    $used->execute([':id' => $id]);
                    if ((int)$used->fetchColumn() > 0) {
                        masterFinanceActionFail('Cannot delete an account used by accounting entries', 409);
                    }
                }
                $stmt = $con->prepare('DELETE FROM accounting_accounts WHERE account_id = :id LIMIT 1');
                $stmt->execute([':id' => $id]);
                masterFinanceAudit('accounting account', 'delete', $id);
                break;
            }
            $name = trim((string)($data['account_name'] ?? $data['name'] ?? ''));
            $type = strtolower(trim((string)($data['account_type'] ?? $data['type'] ?? '')));
            $allowedTypes = ['asset', 'liability', 'equity', 'revenue', 'expense'];
            if ($name === '' || !in_array($type, $allowedTypes, true)) {
                masterFinanceActionFail('Account name and valid account type are required', 422);
            }
            if ($id > 0) {
                $stmt = $con->prepare('UPDATE accounting_accounts SET account_name = :name, account_type = :type WHERE account_id = :id');
                $stmt->execute([':name' => $name, ':type' => $type, ':id' => $id]);
            } else {
                $stmt = $con->prepare('INSERT INTO accounting_accounts (account_name, account_type) VALUES (:name, :type)');
                $stmt->execute([':name' => $name, ':type' => $type]);
                $id = (int)$con->lastInsertId();
            }
            masterFinanceAudit('accounting account', 'save', $id);
            break;

        case 'coupon':
            if (!tableExists('coupon')) {
                masterFinanceActionFail('Coupon table is not available', 404);
            }
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE coupon SET coupon_count = 0 WHERE coupon_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("
                    UPDATE coupon
                    SET coupon_count = CASE WHEN coupon_count <= 0 THEN 100 ELSE coupon_count END,
                        coupon_expiredate = CASE
                            WHEN coupon_expiredate < NOW() THEN DATE_ADD(NOW(), INTERVAL 30 DAY)
                            ELSE coupon_expiredate
                        END
                    WHERE coupon_id = :id
                ");
                $stmt->execute([':id' => $id]);
                break;
            }
            $code = trim((string)($data['code'] ?? $data['title'] ?? 'NEWCOUPON'));
            $count = (int)($data['count'] ?? 100);
            $discount = (int)($data['discount'] ?? 10);
            $expire = trim((string)($data['end_date'] ?? date('Y-m-d H:i:s', strtotime('+30 days'))));
            if ($id > 0) {
                $stmt = $con->prepare("
                    UPDATE coupon
                    SET coupon_name = :code,
                        coupon_count = :count,
                        coupon_discount = :discount,
                        coupon_expiredate = :expire
                    WHERE coupon_id = :id
                ");
                $stmt->execute([
                    ':code' => $code,
                    ':count' => $count,
                    ':discount' => $discount,
                    ':expire' => $expire,
                    ':id' => $id,
                ]);
            } else {
                $stmt = $con->prepare("
                    INSERT INTO coupon (coupon_name, coupon_count, coupon_expiredate, coupon_discount)
                    VALUES (:code, :count, :expire, :discount)
                ");
                $stmt->execute([
                    ':code' => $code,
                    ':count' => $count,
                    ':expire' => $expire,
                    ':discount' => $discount,
                ]);
                $id = (int)$con->lastInsertId();
            }
            break;

        case 'expense':
            if (!tableExists('expenses')) {
                masterFinanceActionFail('Expenses table is not available', 404);
            }
            $title = trim((string)($data['title'] ?? 'مصروف جديد'));
            $amount = (float)($data['amount'] ?? 0);
            $vendorId = (int)($data['vendor_id'] ?? 1);
            $date = trim((string)($data['expense_date'] ?? date('Y-m-d')));
            $notes = trim((string)($data['notes'] ?? ''));
            if ($amount <= 0) {
                masterFinanceActionFail('Expense amount is required');
            }
            $stmt = $con->prepare("
                INSERT INTO expenses (expense_title, amount, vendor_id, expense_date, notes)
                VALUES (:title, :amount, :vendor_id, :expense_date, :notes)
            ");
            $stmt->execute([
                ':title' => $title,
                ':amount' => $amount,
                ':vendor_id' => $vendorId,
                ':expense_date' => $date,
                ':notes' => $notes,
            ]);
            $id = (int)$con->lastInsertId();
            masterFinanceLogEntry('expense', $amount, 0, 'Expense: ' . $title, null);
            break;

        default:
            masterFinanceActionFail('Unsupported finance entity');
    }

    masterFinanceAudit($entity, $action, $id);
    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Finance action completed',
        'data' => [
            'entity' => $entity,
            'action' => $action,
            'id' => $id,
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    masterFinanceActionFail($e->getMessage(), 500);
}
