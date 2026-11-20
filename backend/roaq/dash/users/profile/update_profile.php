<?php
include "../../../connect.php";

$user_id = filterRequest("user_id");
$name = filterRequest("users_name");
$phone = filterRequest("users_phone");
$email = filterRequest("users_email");

if (empty($user_id) || !is_numeric($user_id)) {
    echo json_encode(["status" => "invalid_user"]);
    exit;
}

if (empty($name) || strlen($name) > 100) {
    echo json_encode(["status" => "invalid_name"]);
    exit;
}

if (empty($phone) || strlen($phone) > 25) {
    echo json_encode(["status" => "invalid_phone"]);
    exit;
}

if (!preg_match('/^[0-9+\-\s()]+$/', $phone)) {
    echo json_encode(["status" => "invalid_phone"]);
    exit;
}

if (!empty($email) && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "invalid_email"]);
    exit;
}

$checkPhone = $con->prepare(
    "SELECT users_id FROM users WHERE users_phone = ? AND users_id <> ? LIMIT 1"
);
$checkPhone->execute([$phone, $user_id]);
if ($checkPhone->fetch(PDO::FETCH_ASSOC)) {
    echo json_encode(["status" => "phone_exists"]);
    exit;
}

if (!empty($email)) {
    $stmt = $con->prepare(
        "UPDATE users SET users_name = ?, users_phone = ?, users_email = ? WHERE users_id = ?"
    );
    $isUpdated = $stmt->execute([$name, $phone, $email, $user_id]);
} else {
    $stmt = $con->prepare(
        "UPDATE users SET users_name = ?, users_phone = ? WHERE users_id = ?"
    );
    $isUpdated = $stmt->execute([$name, $phone, $user_id]);
}

if (!$isUpdated) {
    echo json_encode(["status" => "failed"]);
    exit;
}

$fetch = $con->prepare(
    "SELECT users_id, users_name, users_phone, users_email, users_image FROM users WHERE users_id = ? LIMIT 1"
);
$fetch->execute([$user_id]);
$data = $fetch->fetch(PDO::FETCH_ASSOC);

echo json_encode([
    "status" => "success",
    "data" => $data,
]);
?>
