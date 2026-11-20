<?php
include "../../../connect.php";

try {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }

    // قراءة البيانات من الطلب
    $data = json_decode(file_get_contents("php://input"));

    if (!isset($data->users_id)) {
        echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
        exit();
    }

    $user_id = $data->users_id;
    $user_name = isset($data->users_name) ? $data->users_name : null;
    $user_image_base64 = isset($data->users_image) ? $data->users_image : null;
    $image_name = null;

    // 📂 مسار رفع صور المستخدمين
    $uploadDir = __DIR__ . "/../../../uploud/users/";
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    // 🖼️ معالجة الصورة إذا موجودة
    if ($user_image_base64) {
        $image_name = uniqid() . ".png";
        $image_data = base64_decode($user_image_base64);
        $imagePath = $uploadDir . $image_name;
        file_put_contents($imagePath, $image_data);
    }

    // بناء استعلام التحديث ديناميكياً
    $fields = [];
    $params = [':users_id' => $user_id];

    if ($user_name) {
        $fields[] = "users_name = :users_name";
        $params[':users_name'] = $user_name;
    }

    if ($image_name) {
        $fields[] = "users_image = :users_image";
        $params[':users_image'] = $image_name;
    }

    if (empty($fields)) {
        echo json_encode(['status' => 'error', 'message' => 'No fields to update']);
        exit();
    }

    $sql = "UPDATE users SET " . implode(", ", $fields) . " WHERE users_id = :users_id";
    $stmt = $con->prepare($sql);

    if ($stmt->execute($params)) {
        $image_url = $image_name ? "https://savir.site/Zahra_store/zahra/uploud/users/" . $image_name : null;
        echo json_encode([
            'status' => 'success',
            'message' => 'User updated successfully',
            'image' => $image_url
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update user']);
    }

} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
