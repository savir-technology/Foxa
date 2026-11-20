<?php
include "../connect.php";

$stmt = $con->prepare("
    SELECT DISTINCT c.user_id, u.users_name 
    FROM chat_messages c
    INNER JOIN users u ON c.user_id = u.users_id
    ORDER BY c.id DESC
");
$stmt->execute();

$data = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode([
    "status" => "success",
    "data" => $data
]);
?>
