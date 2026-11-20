<?php
include "../connect.php";

header("Content-Type: application/json; charset=UTF-8");

try {
    $stmt = $con->prepare("
        SELECT
            i.items_id,
            i.items_name_ar,
            i.items_name_en,
            i.items_image,
            i.items_price,
            ROUND(IFNULL(AVG(r.rating), 0), 1) AS average_rating,
            COUNT(r.id) AS total_reviews,
            ROUND((IFNULL(AVG(r.rating), 0) / 5) * 100) AS rating_percentage,
            CASE
                WHEN IFNULL(AVG(r.rating), 0) >= 4 AND COUNT(r.id) >= 3 THEN 1
                ELSE 0
            END AS is_top_rated
        FROM items i
        LEFT JOIN ratings r ON i.items_id = r.item_id
        GROUP BY i.items_id
        ORDER BY is_top_rated DESC, average_rating DESC, total_reviews DESC, i.items_id DESC
    ");
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "items" => $data
    ]);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
