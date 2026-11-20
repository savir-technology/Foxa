<?php
require_once "../../../connect.php";
header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

try {
    $admin = requireMasterAuth();
    if (!tableExists('master_store_specialties')) {
        $con->exec("CREATE TABLE master_store_specialties (
            id INT AUTO_INCREMENT PRIMARY KEY,
            category_key VARCHAR(64) NOT NULL UNIQUE,
            name_ar VARCHAR(120) NOT NULL,
            name_en VARCHAR(120) NOT NULL DEFAULT '',
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    }
    $specialtyCount = (int)$con->query('SELECT COUNT(*) FROM master_store_specialties')->fetchColumn();
    if ($specialtyCount === 0) {
        $seed = [
            ['fashion', 'موضة وملابس', 'Fashion'], ['shoes', 'أحذية', 'Shoes'], ['perfume', 'عطور', 'Perfume'],
            ['grocery', 'بقالة', 'Grocery'], ['fresh_food', 'أغذية طازجة', 'Fresh food'], ['canned_food', 'معلبات', 'Canned food'],
            ['electronics', 'إلكترونيات', 'Electronics'], ['toys', 'ألعاب', 'Toys'], ['general', 'متجر عام', 'General'],
        ];
        $stmt = $con->prepare('INSERT INTO master_store_specialties (category_key,name_ar,name_en) VALUES (?,?,?)');
        foreach ($seed as $item) $stmt->execute($item);
    }
    $method = $_SERVER['REQUEST_METHOD'];
    if ($method === 'GET') {
        requireMasterPermission($admin, 'restaurants.view');
        $rows = $con->query('SELECT id, category_key, name_ar, name_en, is_active FROM master_store_specialties ORDER BY name_ar')->fetchAll(PDO::FETCH_ASSOC);
        respondJson(['status' => 'success', 'data' => $rows]);
    }
    $payload = getRequestPayload();
    $action = (string)($payload['action'] ?? 'save');
    if ($action === 'delete') {
        requireMasterPermission($admin, 'restaurants.delete');
        $stmt = $con->prepare('DELETE FROM master_store_specialties WHERE id = ?');
        $stmt->execute([(int)($payload['id'] ?? 0)]);
        respondJson(['status' => 'success']);
    }
    requireMasterPermission($admin, 'restaurants.edit');
    $id = (int)($payload['id'] ?? 0);
    $key = strtolower(trim((string)($payload['category_key'] ?? '')));
    $nameAr = trim((string)($payload['name_ar'] ?? ''));
    $nameEn = trim((string)($payload['name_en'] ?? $nameAr));
    if (!preg_match('/^[a-z0-9_]+$/', $key) || $nameAr === '') throw new RuntimeException('بيانات التخصص غير مكتملة');
    if ($id > 0) {
        $stmt = $con->prepare('UPDATE master_store_specialties SET category_key=?, name_ar=?, name_en=?, is_active=? WHERE id=?');
        $stmt->execute([$key, $nameAr, $nameEn, (int)($payload['is_active'] ?? 1), $id]);
    } else {
        $stmt = $con->prepare('INSERT INTO master_store_specialties (category_key,name_ar,name_en,is_active) VALUES (?,?,?,?)');
        $stmt->execute([$key, $nameAr, $nameEn, (int)($payload['is_active'] ?? 1)]);
    }
    respondJson(['status' => 'success']);
} catch (Throwable $error) {
    respondJson(['status' => 'error', 'message' => $error->getMessage()], 400);
}
