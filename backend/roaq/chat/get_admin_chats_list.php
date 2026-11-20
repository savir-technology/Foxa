<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../connect.php';

try {
    if (!isset($_POST['admin_id'])) {
        http_response_code(400);
        echo json_encode([
            'status' => 'fail',
            'message' => 'admin_id is required',
        ]);
        exit;
    }

    $admin_id = intval($_POST['admin_id']);
    $filter_user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : null;
    $filter_item_id = isset($_POST['item_id']) ? intval($_POST['item_id']) : null;

    if ($admin_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'status' => 'fail',
            'message' => 'Invalid admin_id',
        ]);
        exit;
    }

    $query = "
        SELECT
            c.id AS chat_id,
            c.item_id,
            c.user_id,
            c.other_user_id,
            c.last_message,
            c.last_message_time,
            UNIX_TIMESTAMP(c.last_message_time) AS last_message_ts,
            c.unread_count,
            c.lead_status,
            c.selected_plan_id,
            c.selected_plan_type,
            c.selected_total_price,
            c.selected_duration_months,
            c.created_at,
            c.updated_at,
            i.items_name_ar,
            i.items_name_en,
            i.items_image,
            i.items_price,
            u1.users_name AS user_name,
            u1.users_image AS user_image,
            u2.users_name AS other_user_name,
            u2.users_image AS other_user_image,
            (SELECT COUNT(*) FROM chat_messages WHERE chat_id = c.id) AS total_messages
        FROM chats c
        INNER JOIN items i ON c.item_id = i.items_id
        LEFT JOIN users u1 ON c.user_id = u1.users_id
        LEFT JOIN users u2 ON c.other_user_id = u2.users_id
        WHERE c.other_user_id = :admin_id
    ";

    $params = [':admin_id' => $admin_id];
    if ($filter_user_id) {
        $query .= " AND (c.user_id = :user_id OR c.other_user_id = :user_id) ";
        $params[':user_id'] = $filter_user_id;
    }
    if ($filter_item_id) {
        $query .= " AND c.item_id = :item_id ";
        $params[':item_id'] = $filter_item_id;
    }

    $query .= " ORDER BY c.updated_at DESC ";

    $stmt = $con->prepare($query);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (!$rows) {
        echo json_encode([
            'status' => 'success',
            'data' => [],
            'count' => 0,
            'message' => 'No chats found',
        ]);
        exit;
    }

    $formatted = [];
    foreach ($rows as $chat) {
        $formatted[] = [
            'chat_id' => intval($chat['chat_id']),
            'item_id' => intval($chat['item_id']),
            'product_name_ar' => $chat['items_name_ar'] ?: 'عقار',
            'product_name_en' => $chat['items_name_en'] ?: 'Property',
            'product_image' => !empty($chat['items_image'])
                ? 'https://savir-technology.online/roaqv2/' . ltrim($chat['items_image'], '/')
                : 'https://via.placeholder.com/200x200',
            'product_price' => floatval($chat['items_price']),
            'user_1' => [
                'user_id' => intval($chat['user_id']),
                'user_name' => $chat['user_name'] ?: 'Unknown',
                'user_image' => !empty($chat['user_image'])
                    ? 'https://savir-technology.online/roaqv2/' . ltrim($chat['user_image'], '/')
                    : 'https://via.placeholder.com/200x200',
            ],
            'user_2' => [
                'user_id' => intval($chat['other_user_id']),
                'user_name' => $chat['other_user_name'] ?: 'Unknown',
                'user_image' => !empty($chat['other_user_image'])
                    ? 'https://savir-technology.online/roaqv2/' . ltrim($chat['other_user_image'], '/')
                    : 'https://via.placeholder.com/200x200',
            ],
            'last_message' => $chat['last_message'] ?: 'No messages',
            'last_message_time' => $chat['last_message_time'],
            'last_message_ts' => isset($chat['last_message_ts']) ? intval($chat['last_message_ts']) : null,
            'total_messages' => intval($chat['total_messages']),
            'unread_count' => intval($chat['unread_count']),
            'lead_status' => $chat['lead_status'] ?: 'interested',
            'selected_plan_id' => isset($chat['selected_plan_id']) ? intval($chat['selected_plan_id']) : null,
            'selected_plan_type' => $chat['selected_plan_type'],
            'selected_total_price' => isset($chat['selected_total_price']) ? floatval($chat['selected_total_price']) : null,
            'selected_duration_months' => isset($chat['selected_duration_months']) ? intval($chat['selected_duration_months']) : null,
            'created_at' => $chat['created_at'],
            'updated_at' => $chat['updated_at'],
        ];
    }

    echo json_encode([
        'status' => 'success',
        'data' => $formatted,
        'count' => count($formatted),
        'message' => 'Chats loaded successfully',
        'filters' => [
            'user_id' => $filter_user_id,
            'item_id' => $filter_item_id,
        ],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'fail',
        'message' => 'Server error',
        'error' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
