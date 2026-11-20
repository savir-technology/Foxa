<?php
header('Content-Type: application/json; charset=utf-8');
include '../connect.php';

try {
    // التحقق من إرسال userId
    if (!isset($_POST['userId'])) {
        echo json_encode(['status' => 'fail', 'message' => 'User ID is required']);
        exit;
    }

    $userId = intval($_POST['userId']);

    // جلب الدردشات الخاصة بالمستخدم مع آخر رسالة في كل دردشة
    $query = "SELECT 
        c.id AS chatId,
        c.item_id AS itemId,
        i.name AS itemName,
        i.image AS productImage,
        c.created_at,
        u.name AS userId,
        
        -- آخر رسالة في الدردشة
        (SELECT message FROM chat_messages 
         WHERE chat_id = c.id 
         ORDER BY created_at DESC 
         LIMIT 1) AS lastMessage,
        
        -- تاريخ آخر رسالة
        (SELECT created_at FROM chat_messages 
         WHERE chat_id = c.id 
         ORDER BY created_at DESC 
         LIMIT 1) AS lastMessageTime,
        
        -- اسم المرسل الأخير
        (SELECT name FROM chat_messages 
         JOIN users ON chat_messages.user_id = users.id 
         WHERE chat_id = c.id 
         ORDER BY chat_messages.created_at DESC 
         LIMIT 1) AS senderName,
        
        -- عدد الرسائل غير المقروءة
        (SELECT COUNT(*) FROM chat_messages 
         WHERE chat_id = c.id AND is_read = 0 AND user_id != ?) AS unreadCount
    FROM chats c
    JOIN items i ON c.item_id = i.id
    JOIN users u ON c.user_id = u.id
    WHERE c.user_id = ? OR c.other_user_id = ?
    ORDER BY c.updated_at DESC";
    
    $stmt = $connect->prepare($query);
    $stmt->execute([$userId, $userId, $userId]);
    $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (!empty($chats)) {
        // تنسيق البيانات
        $formattedChats = [];
        foreach ($chats as $chat) {
            $formattedChats[] = [
                'id' => $chat['itemId'],
                'productName' => $chat['itemName'] ?? 'عقار',
                'productImage' => $chat['productImage'] ? 'https://savir-technology.online/roaqv2/' . $chat['productImage'] : 'https://via.placeholder.com/100x100',
                'lastMessage' => $chat['lastMessage'] ?? '',
                'timestamp' => $chat['lastMessageTime'] ? new DateTime($chat['lastMessageTime']) : new DateTime(),
                'unread' => intval($chat['unreadCount']) > 0,
                'senderName' => $chat['senderName'] ?? 'مستخدم'
            ];
        }
        
        echo json_encode([
            'status' => 'success',
            'data' => $formattedChats,
            'message' => 'Chats retrieved successfully'
        ]);
    } else {
        echo json_encode([
            'status' => 'success',
            'data' => [],
            'message' => 'No chats found'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
