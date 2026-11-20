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

function masterOrderActionFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterOrderActionColumnType(string $table, string $column): string
{
    global $con;
    try {
        $stmt = $con->prepare("
            SELECT DATA_TYPE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table
              AND COLUMN_NAME = :column
            LIMIT 1
        ");
        $stmt->execute([':table' => $table, ':column' => $column]);
        return strtolower((string)($stmt->fetchColumn() ?: ''));
    } catch (Throwable $e) {
        return '';
    }
}

function masterOrderActionStatusValue(string $column, string $status)
{
    $type = masterOrderActionColumnType('orders', $column);
    if (in_array($type, ['tinyint', 'smallint', 'mediumint', 'int', 'bigint'], true)) {
        return [
            'pending' => 0,
            'preparing' => 1,
            'ready' => 2,
            'with_driver' => 3,
            'on_way' => 3,
            'delivered' => 4,
            'canceled' => 5,
            'returned' => 6,
        ][$status] ?? 0;
    }
    return $status;
}

function masterOrderActionNormalizeStatus(array $order): string
{
    $rawStatus = trim((string)($order['status'] ?? $order['orders_status'] ?? ''));
    if ($rawStatus === '') {
        return 'pending';
    }

    if (is_numeric($rawStatus)) {
        $numericMap = [
            1 => 'preparing',
            2 => 'ready',
            3 => 'with_driver',
            4 => 'delivered',
            5 => 'canceled',
            6 => 'returned',
        ];
        $numericStatus = (int)$rawStatus;
        return $numericMap[$numericStatus] ?? 'pending';
    }

    $rawStatus = strtolower($rawStatus);
    $statusMap = [
        'new' => 'pending',
        'pending' => 'pending',
        '0' => 'pending',
        'accepted' => 'preparing',
        'preparing' => 'preparing',
        'heading_to_restaurant' => 'preparing',
        'arrived_at_restaurant' => 'preparing',
        'ready' => 'ready',
        'picked_up' => 'ready',
        'assigned' => 'ready',
        'with_driver' => 'with_driver',
        'on_driver' => 'with_driver',
        'on_way' => 'on_way',
        'on_the_way' => 'on_way',
        'out_for_delivery' => 'on_way',
        'delivered' => 'delivered',
        'completed' => 'delivered',
        'paid' => 'delivered',
        '4' => 'delivered',
        'canceled' => 'canceled',
        'cancelled' => 'canceled',
        'failed' => 'canceled',
        'rejected' => 'canceled',
        'returned' => 'returned',
        'refunded' => 'returned',
        'return' => 'returned',
        'refund' => 'returned',
    ];
    return $statusMap[$rawStatus] ?? $rawStatus;
}

function masterOrderActionAllowedTransitions(string $currentStatus, string $requestedStatus): bool
{
    $allowedTransitions = [
        'pending' => ['preparing', 'canceled'],
        'preparing' => ['ready', 'canceled'],
        'ready' => ['with_driver', 'canceled'],
        'with_driver' => ['on_way', 'canceled'],
        'on_way' => ['delivered', 'canceled'],
        'delivered' => ['returned'],
        'canceled' => ['pending'],
        'returned' => ['pending'],
    ];

    if ($currentStatus === $requestedStatus) {
        return true;
    }

    return in_array($requestedStatus, $allowedTransitions[$currentStatus] ?? [], true);
}

function masterOrderActionAudit(string $action, int $orderId, string $note = ''): void
{
    global $con;
    if (!tableExists('master_audit_logs')) {
        return;
    }
    try {
        $admin = $GLOBALS['masterAuthAdmin'] ?? [];
        $actorName = trim((string)($admin['admin_name'] ?? 'Master'));
        $stmt = $con->prepare("
            INSERT INTO master_audit_logs (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
            VALUES (:actor_name, :action_text, :entity_label, :action_time_label, :tint_hex, NOW())
        ");
        $stmt->execute([
            ':actor_name' => $actorName !== '' ? $actorName : 'Master',
            ':action_text' => trim("order {$action} {$note}"),
            ':entity_label' => "Order #{$orderId}",
            ':action_time_label' => date('H:i'),
            ':tint_hex' => in_array($action, ['delivered', 'reopen'], true) ? '#16A34A' : '#DC2626',
        ]);
    } catch (Throwable $e) {
        error_log('master order action audit failed: ' . $e->getMessage());
    }
}

function masterOrderActionChatNote(int $orderId, int $adminId, string $message): void
{
    global $con;
    if (!tableExists('order_chat_messages')) {
        return;
    }
    try {
        $stmt = $con->prepare("
            INSERT INTO order_chat_messages (order_id, chat_scope, sender_role, sender_ref_id, message, is_read)
            VALUES (:order_id, 'order', 'admin', :admin_id, :message, 0)
        ");
        $stmt->execute([
            ':order_id' => $orderId,
            ':admin_id' => $adminId,
            ':message' => $message,
        ]);
    } catch (Throwable $e) {
        error_log('master order action chat note failed: ' . $e->getMessage());
    }
}

try {
    $admin = requireMasterAuth();
    $GLOBALS['masterAuthAdmin'] = $admin;

    if (!tableExists('orders')) {
        masterOrderActionFail('Orders table is not available', 404);
    }

    $payload = getRequestPayload();
    $orderId = (int)($payload['order_id'] ?? $payload['id'] ?? 0);
    $action = strtolower(trim((string)($payload['action'] ?? 'set_status')));
    $status = strtolower(trim((string)($payload['status'] ?? '')));
    $note = trim((string)($payload['note'] ?? ''));

    if ($orderId <= 0) {
        masterOrderActionFail('order_id is required');
    }

    if ($action === 'cancel') {
        requireMasterPermission($admin, 'orders.cancel');
        $status = 'canceled';
    } elseif ($action === 'return' || $action === 'refund') {
        requireMasterPermission($admin, 'finance.refund');
        $status = 'returned';
    } elseif ($action === 'reopen') {
        requireMasterPermission($admin, 'orders.edit');
        $status = 'pending';
    } else {
        requireMasterPermission($admin, 'orders.edit');
    }

    $allowed = ['pending', 'preparing', 'ready', 'with_driver', 'on_way', 'delivered', 'canceled', 'returned'];
    if (!in_array($status, $allowed, true)) {
        masterOrderActionFail('Unsupported order status');
    }

    $existsStmt = $con->prepare("SELECT orders_id FROM orders WHERE orders_id = :order_id LIMIT 1");
    $existsStmt->execute([':order_id' => $orderId]);
    if (!$existsStmt->fetchColumn()) {
        masterOrderActionFail('Order not found', 404);
    }

    $currentStmt = $con->prepare("
        SELECT
            orders_id,
            status,
            orders_status
        FROM orders
        WHERE orders_id = :order_id
        LIMIT 1
    ");
    $currentStmt->execute([':order_id' => $orderId]);
    $currentOrder = $currentStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $currentStatus = masterOrderActionNormalizeStatus($currentOrder);
    if (!masterOrderActionAllowedTransitions($currentStatus, $status)) {
        masterOrderActionFail(
            'Invalid order status transition from ' . $currentStatus . ' to ' . $status,
            409
        );
    }

    $sets = [];
    $params = [':order_id' => $orderId];
    if (columnExists('orders', 'status')) {
        $sets[] = 'status = :status';
        $params[':status'] = masterOrderActionStatusValue('status', $status);
    }
    if (columnExists('orders', 'orders_status')) {
        $sets[] = 'orders_status = :orders_status';
        $params[':orders_status'] = masterOrderActionStatusValue('orders_status', $status);
    }
    if (columnExists('orders', 'updated_at')) {
        $sets[] = 'updated_at = NOW()';
    }
    if ($status === 'preparing' && columnExists('orders', 'accepted_at')) {
        $sets[] = 'accepted_at = COALESCE(accepted_at, NOW())';
    }
    if ($status === 'ready' && columnExists('orders', 'ready_at')) {
        $sets[] = 'ready_at = COALESCE(ready_at, NOW())';
    }
    if ($status === 'delivered' && columnExists('orders', 'delivered_at')) {
        $sets[] = 'delivered_at = COALESCE(delivered_at, NOW())';
    }
    if ($status === 'canceled' && columnExists('orders', 'canceled_at')) {
        $sets[] = 'canceled_at = COALESCE(canceled_at, NOW())';
    }
    if ($status === 'returned' && columnExists('orders', 'refunded_at')) {
        $sets[] = 'refunded_at = COALESCE(refunded_at, NOW())';
    }
    if (empty($sets)) {
        masterOrderActionFail('No writable status column was found', 500);
    }

    $con->beginTransaction();
    $stmt = $con->prepare('UPDATE orders SET ' . implode(', ', $sets) . ' WHERE orders_id = :order_id');
    $stmt->execute($params);

    $adminId = (int)($admin['admin_id'] ?? 0);
    if ($note !== '' || in_array($action, ['cancel', 'return', 'refund', 'reopen'], true)) {
        $label = [
            'pending' => 'تمت إعادة فتح الطلب',
            'preparing' => 'تم تحويل الطلب إلى قيد التحضير',
            'ready' => 'تم تجهيز الطلب',
            'with_driver' => 'تم تحويل الطلب إلى السائق',
            'on_way' => 'الطلب في الطريق',
            'delivered' => 'تم تسليم الطلب',
            'canceled' => 'تم إلغاء الطلب من لوحة الماستر',
            'returned' => 'تم تسجيل الطلب كمردود',
        ][$status] ?? 'تم تحديث حالة الطلب';
        masterOrderActionChatNote($orderId, $adminId, trim($label . ($note !== '' ? ': ' . $note : '')));
    }

    masterOrderActionAudit($status, $orderId, $note);
    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'order updated',
        'data' => [
            'order_id' => $orderId,
            'status' => $status,
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    respondJson(['status' => 'error', 'message' => $e->getMessage()], 500);
}
