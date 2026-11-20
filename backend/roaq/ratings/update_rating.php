<?php
include "../connect.php";
require_once __DIR__ . '/helpers.php';

header("Content-Type: application/json; charset=UTF-8");

$ratingId = (int) ($_POST['rating_id'] ?? 0);
$userId = (int) ($_POST['users_id'] ?? 0);
$rating = (float) ($_POST['rating'] ?? 0);
$comment = trim($_POST['comment'] ?? '');

if ($ratingId <= 0 || $userId <= 0 || $rating <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing fields"
    ]);
    exit;
}

if ($rating > 5) {
    $rating = 5;
}

try {
    $stmtCheck = $con->prepare("SELECT id, item_id FROM ratings WHERE id = ? AND user_id = ? LIMIT 1");
    $stmtCheck->execute([$ratingId, $userId]);
    $existing = $stmtCheck->fetch(PDO::FETCH_ASSOC);

    if (!$existing) {
        echo json_encode([
            "status" => "error",
            "message" => "Rating not found or not authorized"
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if (!userCanRateItem($con, $userId, (int)$existing['item_id'])) {
        echo json_encode([
            "status" => "error",
            "message" => "You can only update a rating after your order has been delivered.",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("
        UPDATE ratings
        SET rating = ?, comment = ?, created_at = NOW()
        WHERE id = ? AND user_id = ?
    ");
    $stmt->execute([$rating, $comment, $ratingId, $userId]);

    echo json_encode([
        "status" => "success",
        "message" => "Rating updated successfully"
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
