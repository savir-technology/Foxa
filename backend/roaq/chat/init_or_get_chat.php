<?php
/**
 * init_or_get_chat.php
 * Creates or returns chat for (user_id, item_id, other_user_id).
 * Also stores selected plan context and defaults lead_status to interested.
 */

header('Content-Type: application/json; charset=utf-8');
require_once "../connect.php";

function resolveSupportUserId(PDO $con): int
{
    // Force a single support owner for all chats.
    $fixedSupportUserId = 89;
    $stmt = $con->prepare(
        "SELECT users_id
         FROM users
         WHERE users_id = :id
           AND users_approve = 1
         LIMIT 1"
    );
    $stmt->execute([':id' => $fixedSupportUserId]);
    return intval($stmt->fetchColumn() ?: 0);
}

try {
    $user_id = intval($_POST['user_id'] ?? 0);
    $item_id = intval($_POST['item_id'] ?? 0);
    $other_user_id = intval($_POST['other_user_id'] ?? 0);

    $selected_plan_id = intval($_POST['plan_id'] ?? 0);
    $selected_plan_type = trim((string)($_POST['plan_type'] ?? ''));
    $selected_total_price = floatval($_POST['total_price'] ?? 0);
    $selected_duration_months = intval($_POST['duration_months'] ?? 0);

    if ($user_id <= 0) {
        throw new Exception("Missing user_id");
    }

    if ($item_id <= 0) {
        throw new Exception("Missing item_id");
    }

    // Resolve admin receiver dynamically when not explicitly provided.
    if ($other_user_id <= 0) {
        $other_user_id = resolveSupportUserId($con);
    }

    if ($other_user_id <= 0) {
        throw new Exception("No active admin user found");
    }

    $search_stmt = $con->prepare(
        "SELECT id
         FROM chats
         WHERE item_id = :item_id
           AND user_id = :user_id
         ORDER BY (other_user_id = :other_user_id) DESC, id DESC
         LIMIT 1"
    );
    $search_stmt->execute([
        ':item_id' => $item_id,
        ':user_id' => $user_id,
        ':other_user_id' => $other_user_id,
    ]);
    $existing_chat = $search_stmt->fetch(PDO::FETCH_ASSOC);

    if ($existing_chat) {
        $chat_id = intval($existing_chat['id']);
        $reassign_stmt = $con->prepare(
            "UPDATE chats
             SET other_user_id = :other_user_id,
                 updated_at = NOW()
             WHERE id = :chat_id"
        );
        $reassign_stmt->execute([
            ':other_user_id' => $other_user_id,
            ':chat_id' => $chat_id,
        ]);

        if ($selected_plan_id > 0 || $selected_plan_type !== '' || $selected_total_price > 0 || $selected_duration_months > 0) {
            $update_stmt = $con->prepare(
                "UPDATE chats
                 SET
                   selected_plan_id = CASE WHEN :plan_id > 0 THEN :plan_id ELSE selected_plan_id END,
                   selected_plan_type = CASE WHEN :plan_type <> '' THEN :plan_type ELSE selected_plan_type END,
                   selected_total_price = CASE WHEN :total_price > 0 THEN :total_price ELSE selected_total_price END,
                   selected_duration_months = CASE WHEN :duration_months > 0 THEN :duration_months ELSE selected_duration_months END,
                   updated_at = NOW()
                 WHERE id = :chat_id"
            );
            $update_stmt->execute([
                ':plan_id' => $selected_plan_id,
                ':plan_type' => $selected_plan_type,
                ':total_price' => $selected_total_price,
                ':duration_months' => $selected_duration_months,
                ':chat_id' => $chat_id,
            ]);
        }

        echo json_encode([
            "status" => "success",
            "is_new" => false,
            "chat_id" => $chat_id,
        ]);
        exit;
    }

    $create_stmt = $con->prepare(
        "INSERT INTO chats (
            item_id,
            user_id,
            other_user_id,
            lead_status,
            selected_plan_id,
            selected_plan_type,
            selected_total_price,
            selected_duration_months,
            created_at,
            updated_at
        ) VALUES (
            :item_id,
            :user_id,
            :other_user_id,
            'interested',
            :selected_plan_id,
            :selected_plan_type,
            :selected_total_price,
            :selected_duration_months,
            NOW(),
            NOW()
        )"
    );

    $create_stmt->execute([
        ':item_id' => $item_id,
        ':user_id' => $user_id,
        ':other_user_id' => $other_user_id,
        ':selected_plan_id' => $selected_plan_id > 0 ? $selected_plan_id : null,
        ':selected_plan_type' => $selected_plan_type !== '' ? $selected_plan_type : null,
        ':selected_total_price' => $selected_total_price > 0 ? $selected_total_price : null,
        ':selected_duration_months' => $selected_duration_months > 0 ? $selected_duration_months : null,
    ]);

    echo json_encode([
        "status" => "success",
        "is_new" => true,
        "chat_id" => intval($con->lastInsertId()),
    ]);
} catch (Throwable $e) {
    error_log("init_or_get_chat.php error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ]);
}

