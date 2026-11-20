<?php
include "../connect.php";

header("Content-Type: application/json; charset=UTF-8");

function ensureDriverRatingsTable(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS driver_ratings (
            rating_id INT(11) NOT NULL AUTO_INCREMENT,
            order_id INT(11) NOT NULL,
            driver_id INT(11) NOT NULL,
            user_id INT(11) NOT NULL,
            rating DECIMAL(3,1) NOT NULL DEFAULT 0.0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (rating_id),
            UNIQUE KEY uq_driver_ratings_order_user (order_id, user_id),
            KEY idx_driver_ratings_driver (driver_id),
            KEY idx_driver_ratings_user (user_id),
            CONSTRAINT fk_driver_ratings_order
                FOREIGN KEY (order_id) REFERENCES orders (orders_id)
                ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_driver_ratings_driver
                FOREIGN KEY (driver_id) REFERENCES delivery_users (id)
                ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_driver_ratings_user
                FOREIGN KEY (user_id) REFERENCES users (users_id)
                ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "status" => "error",
        "message" => "POST required",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$orderId = (int)($_POST['order_id'] ?? 0);
$driverId = (int)($_POST['driver_id'] ?? 0);
$userId = (int)($_POST['user_id'] ?? 0);

if ($orderId <= 0 || $driverId <= 0 || $userId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    ensureDriverRatingsTable($con);

    $stmt = $con->prepare("
        SELECT
            rating_id,
            order_id,
            driver_id,
            user_id,
            rating,
            created_at,
            updated_at
        FROM driver_ratings
        WHERE order_id = ? AND driver_id = ? AND user_id = ?
        LIMIT 1
    ");
    $stmt->execute([$orderId, $driverId, $userId]);
    $rating = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$rating) {
        echo json_encode([
            "status" => "success",
            "has_rating" => false,
            "rating" => null,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode([
        "status" => "success",
        "has_rating" => true,
        "rating_id" => (int)$rating['rating_id'],
        "order_id" => (int)$rating['order_id'],
        "driver_id" => (int)$rating['driver_id'],
        "user_id" => (int)$rating['user_id'],
        "rating" => (float)$rating['rating'],
        "created_at" => $rating['created_at'],
        "updated_at" => $rating['updated_at'],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
