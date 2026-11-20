<?php
include "../connect.php";
require_once __DIR__ . '/helpers.php';

header("Content-Type: application/json; charset=UTF-8");

$itemId = (int) ($_POST['items_id'] ?? $_GET['items_id'] ?? 0);
$userId = (int) ($_POST['users_id'] ?? $_GET['users_id'] ?? 0);

if ($itemId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing items_id"
    ]);
    exit;
}

try {
    $canRate = false;
    if ($userId > 0) {
        $canRate = userCanRateItem($con, $userId, $itemId);
    }

    $stmt = $con->prepare("
        SELECT
            r.id AS rating_id,
            r.item_id AS items_id,
            r.user_id AS users_id,
            r.rating,
            r.comment,
            r.is_verified,
            r.created_at,
            u.users_name
        FROM ratings r
        INNER JOIN users u ON r.user_id = u.users_id
        WHERE r.item_id = ?
        ORDER BY r.created_at DESC
    ");
    $stmt->execute([$itemId]);
    $ratings = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $stmtAvg = $con->prepare("
        SELECT
            ROUND(IFNULL(AVG(rating), 0), 1) AS avg_rating,
            COUNT(*) AS total_reviews
        FROM ratings
        WHERE item_id = ?
    ");
    $stmtAvg->execute([$itemId]);
    $avgData = $stmtAvg->fetch(PDO::FETCH_ASSOC);

    $userRating = null;
    if ($userId > 0) {
        $stmtUser = $con->prepare("
            SELECT
                id AS rating_id,
                item_id AS items_id,
                user_id AS users_id,
                rating,
                comment,
                is_verified,
                created_at
            FROM ratings
            WHERE item_id = ? AND user_id = ?
            LIMIT 1
        ");
        $stmtUser->execute([$itemId, $userId]);
        $userRating = $stmtUser->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    $averageRating = (float) ($avgData['avg_rating'] ?? 0);
    $totalReviews = (int) ($avgData['total_reviews'] ?? 0);

    echo json_encode([
        "status" => "success",
        "average_rating" => $averageRating,
        "total_reviews" => $totalReviews,
        "rating_percentage" => round(($averageRating / 5) * 100),
        "can_rate" => $canRate,
        "user_rating" => $userRating,
        "ratings" => $ratings
    ], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
