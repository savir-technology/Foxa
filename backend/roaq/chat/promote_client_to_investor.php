<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../connect.php';
require_once '../notifications/notification_service.php';

$chat_id = intval($_POST['chat_id'] ?? 0);
$admin_id = intval($_POST['admin_id'] ?? 0);
$plan_id_input = intval($_POST['plan_id'] ?? 0);

if ($chat_id <= 0 || $admin_id <= 0) {
    echo json_encode([
        'status' => 'fail',
        'message' => 'chat_id and admin_id are required',
    ]);
    exit;
}

try {
    $con->beginTransaction();

    $chatStmt = $con->prepare(
        "SELECT id, user_id, item_id, selected_plan_id
         FROM chats
         WHERE id = :chat_id
         LIMIT 1"
    );
    $chatStmt->execute([':chat_id' => $chat_id]);
    $chat = $chatStmt->fetch(PDO::FETCH_ASSOC);

    if (!$chat) {
        throw new Exception('Chat not found');
    }

    $user_id = intval($chat['user_id']);
    $item_id = intval($chat['item_id']);
    $plan_id = $plan_id_input > 0 ? $plan_id_input : intval($chat['selected_plan_id'] ?? 0);

    if ($user_id <= 0 || $item_id <= 0) {
        throw new Exception('Invalid chat data');
    }

    if ($plan_id <= 0) {
        $planStmt = $con->prepare(
            "SELECT plan_id
             FROM property_plans
             WHERE item_id = :item_id
               AND is_active = 1
             ORDER BY duration_months ASC, plan_id ASC
             LIMIT 1"
        );
        $planStmt->execute([':item_id' => $item_id]);
        $plan_id = intval($planStmt->fetchColumn() ?: 0);
    }

    if ($plan_id <= 0) {
        throw new Exception('No active plan found for this property');
    }

    $contractStmt = $con->prepare(
        "SELECT contract_id
         FROM property_contracts
         WHERE user_id = :user_id
           AND item_id = :item_id
           AND plan_id = :plan_id
         ORDER BY contract_id DESC
         LIMIT 1"
    );
    $contractStmt->execute([
        ':user_id' => $user_id,
        ':item_id' => $item_id,
        ':plan_id' => $plan_id,
    ]);
    $contract_id = intval($contractStmt->fetchColumn() ?: 0);

    if ($contract_id <= 0) {
        $insertContract = $con->prepare(
            "INSERT INTO property_contracts
             (user_id, item_id, plan_id, down_payment_amount, down_payment_paid, monthly_installment, status, created_at)
             VALUES (:user_id, :item_id, :plan_id, :down_payment, 0, :monthly_installment, 'active', NOW())"
        );
        $planDataStmt = $con->prepare(
            "SELECT down_payment, installment_amount
             FROM property_plans
             WHERE plan_id = :plan_id
             LIMIT 1"
        );
        $planDataStmt->execute([':plan_id' => $plan_id]);
        $planDataRow = $planDataStmt->fetch(PDO::FETCH_ASSOC) ?: [];
        $insertContract->execute([
            ':user_id' => $user_id,
            ':item_id' => $item_id,
            ':plan_id' => $plan_id,
            ':down_payment' => floatval($planDataRow['down_payment'] ?? 0),
            ':monthly_installment' => floatval($planDataRow['installment_amount'] ?? 0),
        ]);
        $contract_id = intval($con->lastInsertId());
    } else {
        $activateContract = $con->prepare(
            "UPDATE property_contracts
             SET status = 'active'
             WHERE contract_id = :contract_id"
        );
        $activateContract->execute([':contract_id' => $contract_id]);
    }

    $installmentsCountStmt = $con->prepare(
        "SELECT COUNT(*) FROM property_installments WHERE contract_id = :contract_id"
    );
    $installmentsCountStmt->execute([':contract_id' => $contract_id]);
    $existingInstallments = intval($installmentsCountStmt->fetchColumn() ?: 0);

    if ($existingInstallments === 0) {
        $planStmt = $con->prepare(
            "SELECT duration_months, installment_amount, start_date
             FROM property_plans
             WHERE plan_id = :plan_id
             LIMIT 1"
        );
        $planStmt->execute([':plan_id' => $plan_id]);
        $planData = $planStmt->fetch(PDO::FETCH_ASSOC);

        if ($planData) {
            $startRaw = trim((string) ($planData['start_date'] ?? ''));
            if ($startRaw === '' || $startRaw === '0000-00-00') {
                $startDate = new DateTime('today');
            } else {
                $startDate = new DateTime($startRaw);
            }

            $installmentStmt = $con->prepare(
                "INSERT INTO property_installments
                 (contract_id, plan_id, user_id, due_date, amount, status, created_at)
                 VALUES (:contract_id, :plan_id, :user_id, :due_date, :amount, 'pending', NOW())"
            );

            for ($i = 0; $i < intval($planData['duration_months']); $i++) {
                $dueDate = clone $startDate;
                $dueDate->modify('+' . $i . ' months');
                $installmentStmt->execute([
                    ':contract_id' => $contract_id,
                    ':plan_id' => $plan_id,
                    ':user_id' => $user_id,
                    ':due_date' => $dueDate->format('Y-m-d'),
                    ':amount' => $planData['installment_amount'],
                ]);
            }
        }
    }

    $updateChat = $con->prepare(
        "UPDATE chats
         SET lead_status = 'investor',
             selected_plan_id = :plan_id,
             updated_at = NOW()
         WHERE id = :chat_id"
    );
    $updateChat->execute([
        ':plan_id' => $plan_id,
        ':chat_id' => $chat_id,
    ]);

    $note = 'تم تحويل حالة العميل إلى مستثمر';
    $insertMsg = $con->prepare(
        "INSERT INTO chat_messages (chat_id, user_id, item_id, sender_type, message, media_type, timestamp)
         VALUES (:chat_id, :admin_id, :item_id, 'admin', :message, 'text', NOW())"
    );
    $insertMsg->execute([
        ':chat_id' => $chat_id,
        ':admin_id' => $admin_id,
        ':item_id' => $item_id,
        ':message' => $note,
    ]);

    notifyUser(
        $user_id,
        'تم تفعيل استثمارك',
        'تم تحويل حالتك إلى مستثمر ويمكنك متابعة استثماراتك الآن.',
        'contract',
        [
            'chat_id' => $chat_id,
            'contract_id' => $contract_id,
            'item_id' => $item_id,
            'plan_id' => $plan_id,
        ],
        'promote_investor_' . $chat_id
    );

    $con->commit();

    echo json_encode([
        'status' => 'success',
        'chat_id' => $chat_id,
        'contract_id' => $contract_id,
        'plan_id' => $plan_id,
        'lead_status' => 'investor',
        'message' => 'Client promoted to investor',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    error_log('promote_client_to_investor.php error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
