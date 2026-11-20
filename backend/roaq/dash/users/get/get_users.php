<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
   http_response_code(200);
   exit();
}

try {
   // This legacy shared endpoint is still used by the vendor dashboard
   // without a bearer token. The Master dashboard uses the protected
   // dash/master/users/overview.php endpoint instead. Keep this legacy
   // contract compatible while returning only non-sensitive fields.

   // استعلام لجلب كل البيانات من جدول users
   $stmt = $con->prepare("SELECT users_id, users_name, users_phone, users_email, users_approve, users_image FROM users");
   $stmt->execute();

   // جلب البيانات كصفوف
   $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

   // إرسال البيانات بتنسيق JSON
   echo json_encode($users);
} catch (PDOException $e) {
   echo json_encode(['error' => $e->getMessage()]);
}
?>
