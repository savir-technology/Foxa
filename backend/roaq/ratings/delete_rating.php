<?php
include "../connect.php";
require_once __DIR__ . '/helpers.php';

header("Content-Type: application/json; charset=UTF-8");

$itemId = (int) ($_POST['items_id'] ?? 0);
$userId = (int) ($_POST['users_id'] ?? 0);

if ($itemId <= 0 || $userId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing fields"
    ]);
    exit;
}

try {
    if (!userCanRateItem($con, $userId, $itemId)) {
        echo json_encode([
            "status" => "error",
            "message" => "You can only delete a rating after your order has been delivered.",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("DELETE FROM ratings WHERE item_id = ? AND user_id = ?");
    $stmt->execute([$itemId, $userId]);

    if ($stmt->rowCount() > 0) {
        echo json_encode([
            "status" => "success",
            "message" => "Rating deleted successfully"
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "No rating found for this user and item"
        ], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
