<?php
include "../../../connect.php";

$user_id = filterRequest("user_id");

$stmt = $con->prepare("
    SELECT users_id, users_name, users_phone, users_email, users_image 
    FROM users 
    WHERE users_id = ?
");
$stmt->execute([$user_id]);

$data = $stmt->fetch(PDO::FETCH_ASSOC);

if ($data) {
    echo json_encode($data);
} else {
    echo json_encode(["status" => "not_found"]);
}
?>
