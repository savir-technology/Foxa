<?php
include "../connect.php";
require_once __DIR__ . '/helpers.php';

header("Content-Type: application/json; charset=UTF-8");

$itemId = (int) ($_POST['items_id'] ?? 0);
$userId = (int) ($_POST['users_id'] ?? 0);
$rating = (float) ($_POST['rating'] ?? 0);
$comment = trim($_POST['comment'] ?? '');

if ($itemId <= 0 || $userId <= 0 || $rating <= 0) {
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
    if (!userCanRateItem($con, $userId, $itemId)) {
        echo json_encode([
            "status" => "error",
            "message" => "You can only rate an item after your order has been delivered.",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $check = $con->prepare("SELECT id FROM ratings WHERE item_id = ? AND user_id = ? LIMIT 1");
    $check->execute([$itemId, $userId]);
    $existing = $check->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        $stmt = $con->prepare("
            UPDATE ratings
            SET rating = ?, comment = ?, created_at = NOW()
            WHERE id = ? AND user_id = ?
        ");
        $stmt->execute([$rating, $comment, $existing['id'], $userId]);

        echo json_encode([
            "status" => "success",
            "message" => "Rating updated successfully",
            "rating_id" => (int) $existing['id']
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("
        INSERT INTO ratings (user_id, item_id, rating, comment, is_verified, created_at)
        VALUES (?, ?, ?, ?, 0, NOW())
    ");
    $stmt->execute([$userId, $itemId, $rating, $comment]);

    echo json_encode([
        "status" => "success",
        "message" => "Rating added successfully",
        "rating_id" => (int) $con->lastInsertId()
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
