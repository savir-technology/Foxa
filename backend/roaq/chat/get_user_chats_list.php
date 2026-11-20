<?php
header('Content-Type: application/json; charset=utf-8');
include '../connect.php';

/**
 * API: جلب كل الدردشات بأسماء المنتجات
 * Parameters: user_id (POST)
 * Returns: قائمة الدردشات مع اسم المنتج وآخر رسالة
 */

try {
    // فحص المستخدم
    if (!isset($_POST['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'status' => 'fail',
            'message' => 'معرف المستخدم مطلوب (user_id)'
        ]);
        exit;
    }

    $user_id = intval($_POST['user_id']);

    if ($user_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'status' => 'fail',
            'message' => 'معرف المستخدم غير صحيح'
        ]);
        exit;
    }

    // جلب جميع الدردشات للمستخدم مع تفاصيل المنتجات
    $query = "
        SELECT 
            c.id AS chat_id,
            c.item_id,
            c.other_user_id,
            i.items_id,
            i.items_name_ar,
            i.items_name_en,
            i.items_image,
            i.items_price,
            u.users_name,
            u.users_image,
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
            -- عدد الرسائل غير المقروءة من منظور المستخدم
            (SELECT COUNT(*) FROM chat_messages 
             WHERE chat_id = c.id AND user_id != :user_id) AS new_messages_count
        FROM chats c
        INNER JOIN items i ON c.item_id = i.items_id
        INNER JOIN users u ON c.other_user_id = u.users_id
        WHERE c.user_id = :user_id OR c.other_user_id = :user_id2
        ORDER BY c.updated_at DESC
    ";

    $stmt = $connect->prepare($query);
    $stmt->execute([
        ':user_id' => $user_id,
        ':user_id2' => $user_id
    ]);

    $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($chats)) {
        echo json_encode([
            'status' => 'success',
            'data' => [],
            'count' => 0,
            'message' => 'لا توجد دردشات حالياً'
        ]);
        exit;
    }

    // تنسيق البيانات
    $formattedChats = [];
    foreach ($chats as $chat) {
        $formattedChats[] = [
            'chat_id' => intval($chat['chat_id']),
            'item_id' => intval($chat['item_id']),
            'product_name_ar' => $chat['items_name_ar'],
            'product_name_en' => $chat['items_name_en'],
            'product_image' => !empty($chat['items_image']) 
                ? 'https://savir-technology.online/roaqv2/' . $chat['items_image']
                : 'https://via.placeholder.com/200x200',
            'product_price' => floatval($chat['items_price']),
            'other_user_id' => intval($chat['other_user_id']),
            'other_user_name' => $chat['users_name'],
            'other_user_image' => !empty($chat['users_image'])
                ? 'https://savir-technology.online/roaqv2/' . $chat['users_image']
                : 'https://via.placeholder.com/200x200',
            'last_message' => !empty($chat['last_message']) ? $chat['last_message'] : 'لا توجد رسائل',
            'last_message_time' => $chat['last_message_time'],
            'last_message_ts' => isset($chat['last_message_ts']) ? intval($chat['last_message_ts']) : null,
            'unread_count' => intval($chat['unread_count']),
            'lead_status' => $chat['lead_status'] ?: 'interested',
            'selected_plan_id' => isset($chat['selected_plan_id']) ? intval($chat['selected_plan_id']) : null,
            'selected_plan_type' => $chat['selected_plan_type'],
            'selected_total_price' => isset($chat['selected_total_price']) ? floatval($chat['selected_total_price']) : null,
            'selected_duration_months' => isset($chat['selected_duration_months']) ? intval($chat['selected_duration_months']) : null,
            'new_messages' => intval($chat['new_messages_count']),
            'created_at' => $chat['created_at'],
            'updated_at' => $chat['updated_at']
        ];
    }

    echo json_encode([
        'status' => 'success',
        'data' => $formattedChats,
        'count' => count($formattedChats),
        'message' => 'تم جلب الدردشات بنجاح'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'fail',
        'message' => 'حدث خطأ: ' . $e->getMessage(),
        'error' => $e->getMessage()
    ]);
}
?>
