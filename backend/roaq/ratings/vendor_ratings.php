<?php
include "../connect.php";
require_once __DIR__ . '/helpers.php';

header("Content-Type: application/json; charset=UTF-8");

$vendorId = (int) ($_POST['vendor_id'] ?? $_GET['vendor_id'] ?? 0);

if ($vendorId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing vendor_id",
    ]);
    exit;
}

try {
    $summaryStmt = $con->prepare("
        SELECT
            ROUND(IFNULL(AVG(r.rating), 0), 1) AS avg_rating,
            COUNT(*) AS total_reviews
        FROM ratings r
        INNER JOIN items i ON i.items_id = r.item_id
        WHERE i.vendor_id = ?
    ");
    $summaryStmt->execute([$vendorId]);
    $summary = $summaryStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $ratingsStmt = $con->prepare("
        SELECT
            r.id AS rating_id,
            r.item_id AS items_id,
            r.user_id AS users_id,
            COALESCE(NULLIF(TRIM(u.users_name), ''), 'مستخدم مجهول') AS users_name,
            r.rating,
            r.comment,
            r.created_at,
            COALESCE(NULLIF(TRIM(i.items_name_ar), ''), NULLIF(TRIM(i.items_name_en), ''), '') AS item_name
        FROM ratings r
        INNER JOIN items i ON i.items_id = r.item_id
        LEFT JOIN users u ON u.users_id = r.user_id
        WHERE i.vendor_id = ?
        ORDER BY r.created_at DESC, r.id DESC
    ");
    $ratingsStmt->execute([$vendorId]);
    $ratings = $ratingsStmt->fetchAll(PDO::FETCH_ASSOC);

    $averageRating = (float)($summary['avg_rating'] ?? 0);
    $totalReviews = (int)($summary['total_reviews'] ?? 0);

    echo json_encode([
        "status" => "success",
        "vendor_id" => $vendorId,
        "average_rating" => $averageRating,
        "total_reviews" => $totalReviews,
        "rating_percentage" => round(($averageRating / 5) * 100),
        "ratings" => $ratings,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
