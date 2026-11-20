<?php
// API: Upload item media (images/videos) - Admin only
require_once '../../connect.php';
header('Content-Type: application/json; charset=utf-8');

$item_id = isset($_POST['item_id']) ? intval($_POST['item_id']) : 0;
$media_type = isset($_POST['media_type']) ? trim($_POST['media_type']) : '';
$is_primary = isset($_POST['is_primary']) ? intval($_POST['is_primary']) : 0;
$sort_order = isset($_POST['sort_order']) ? intval($_POST['sort_order']) : 0;

if ($item_id <= 0 || !in_array($media_type, ['image', 'video'])) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid item_id or media_type'
    ]);
    exit;
}

try {
    // التحقق من وجود العقار
    $checkStmt = $con->prepare("SELECT items_id FROM items WHERE items_id = ?");
    $checkStmt->execute([$item_id]);
    if ($checkStmt->rowCount() === 0) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Item not found'
        ]);
        exit;
    }

    $media_url = '';

    if ($media_type === 'image') {
        // معالجة الصور
        if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Invalid file upload'
            ]);
            exit;
        }

        $allowed_exts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        $file_name = $_FILES['image']['name'];
        $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

        if (!in_array($file_ext, $allowed_exts)) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Invalid image format'
            ]);
            exit;
        }

        $new_name = 'item_' . $item_id . '_' . time() . '_' . rand(1000, 9999) . '.' . $file_ext;
        $upload_path = '../../uploads/items_media/' . $new_name;

        // إنشاء المجلد إذا لم يكن موجوداً
        if (!is_dir('../../uploads/items_media')) {
            mkdir('../../uploads/items_media', 0755, true);
        }

        if (move_uploaded_file($_FILES['image']['tmp_name'], $upload_path)) {
            $media_url = '/uploads/items_media/' . $new_name;
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => 'Failed to save image'
            ]);
            exit;
        }

    } elseif ($media_type === 'video') {
        // معالجة الفيديوهات - يمكن أن يكون رابط URL أو ملف
        $media_url = isset($_POST['video_url']) ? trim($_POST['video_url']) : '';
        
        if (empty($media_url)) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Video URL is required'
            ]);
            exit;
        }
    }

    // إدراج في قاعدة البيانات
    $insertStmt = $con->prepare("
        INSERT INTO item_media (item_id, media_url, media_type, is_primary, sort_order)
        VALUES (?, ?, ?, ?, ?)
    ");

    $insertStmt->execute([$item_id, $media_url, $media_type, $is_primary, $sort_order]);
    $media_id = $con->lastInsertId();

    echo json_encode([
        'status' => 'success',
        'message' => 'Media uploaded successfully',
        'media_id' => $media_id,
        'media_url' => $media_url
    ]);

} catch (Exception $e) {
    error_log("Error in upload_item_media: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error'
    ]);
}
?>
