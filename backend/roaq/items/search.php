<?php

include "../connect.php";

$search = trim(filterRequest("search"));

try {
    $stmt = $con->prepare("
        SELECT
            i.items_id,
            i.items_name_en,
            i.items_name_ar,
            i.items_desc_en,
            i.items_desc_ar,
            i.items_image,
            i.items_count,
            i.items_active,
            i.items_price,
            i.items_discount,
            i.items_date,
            i.items_cat,
            i.vendor_id,
            c.categories_id,
            c.categories_name_en,
            c.categories_name_ar,
            c.categories_image,
            c.categories_datetime,
            v.vendor_name,
            v.store_name,
            v.store_slug,
            v.vendor_logo,
            (i.items_price - (i.items_price * i.items_discount / 100)) AS items_discount_price,
            (i.items_price - (i.items_price * i.items_discount / 100)) AS itemspricedisount,
            COALESCE(g.gallery_images, i.items_image) AS gallery_images,
            ROUND(IFNULL(r.average_rating, 0), 1) AS average_rating,
            IFNULL(r.ratings_count, 0) AS ratings_count,
            ROUND((IFNULL(r.average_rating, 0) / 5) * 100) AS rating_percentage,
            CASE
                WHEN IFNULL(r.average_rating, 0) >= 4 AND IFNULL(r.ratings_count, 0) >= 3 THEN 1
                ELSE 0
            END AS is_top_rated
        FROM items i
        JOIN categories c ON c.categories_id = i.items_cat
        JOIN vendors v ON v.vendor_id = i.vendor_id
        LEFT JOIN (
            SELECT
                item_id,
                AVG(rating) AS average_rating,
                COUNT(*) AS ratings_count
            FROM ratings
            GROUP BY item_id
        ) r ON r.item_id = i.items_id
        LEFT JOIN (
            SELECT
                item_id,
                GROUP_CONCAT(img_path ORDER BY img_order ASC SEPARATOR '||') AS gallery_images
            FROM items_images
            GROUP BY item_id
        ) g ON g.item_id = i.items_id
        WHERE (
                i.items_name_en LIKE :search
             OR i.items_name_ar LIKE :search
             OR v.store_name LIKE :search
             OR v.vendor_name LIKE :search
        )
          AND i.items_active = 1
          AND v.vendor_status = 'active'
          AND v.vendor_is_verified = 1
        ORDER BY is_top_rated DESC, ratings_count DESC, i.items_id DESC
    ");
    $stmt->execute([
        ":search" => "%" . $search . "%"
    ]);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($data) > 0) {
        echo json_encode(["status" => "success", "data" => $data]);
    } else {
        echo json_encode(["status" => "failure", "data" => []]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

?>
