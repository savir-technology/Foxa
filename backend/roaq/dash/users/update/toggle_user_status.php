<?php
include "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");

function failResponse($message, $code = 400) {
   http_response_code($code);
   echo json_encode([
      "status" => "failure",
      "message" => $message,
   ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
   exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
   failResponse("Invalid request method", 405);
}

$userId = (int) ($_POST["user_id"] ?? 0);
$approve = (int) ($_POST["users_approve"] ?? -1);

if ($userId <= 0) {
   failResponse("Invalid user id");
}

if ($approve !== 0 && $approve !== 1) {
   failResponse("Invalid status value");
}

try {
   $stmt = $con->prepare("UPDATE users SET users_approve = ? WHERE users_id = ?");
   $stmt->execute([$approve, $userId]);

   echo json_encode([
      "status" => "success",
      "message" => $approve === 1 ? "User activated successfully" : "User blocked successfully",
      "data" => [
         "user_id" => $userId,
         "users_approve" => $approve
      ]
   ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (PDOException $e) {
   failResponse($e->getMessage(), 500);
}
?>
