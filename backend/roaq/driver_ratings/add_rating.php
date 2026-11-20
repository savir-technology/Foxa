<?php
include "../connect.php";
require_once __DIR__ . '/helpers.php';

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
$rating = (float)($_POST['rating'] ?? 0);

if ($orderId <= 0 || $driverId <= 0 || $userId <= 0 || $rating <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($rating > 5) {
    $rating = 5;
}

try {
    ensureDriverRatingsTable($con);

    if (!userCanRateDriver($con, $userId, $orderId, $driverId)) {
        echo json_encode([
            "status" => "error",
            "message" => "You can only rate the driver after the order has been delivered.",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $con->prepare("
        INSERT INTO driver_ratings (order_id, driver_id, user_id, rating)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            driver_id = VALUES(driver_id),
            rating = VALUES(rating),
            updated_at = NOW()
    ");
    $stmt->execute([$orderId, $driverId, $userId, $rating]);

    $ratingIdStmt = $con->prepare("
        SELECT rating_id
        FROM driver_ratings
        WHERE order_id = ? AND user_id = ?
        LIMIT 1
    ");
    $ratingIdStmt->execute([$orderId, $userId]);
    $ratingId = (int)($ratingIdStmt->fetchColumn() ?: 0);

    echo json_encode([
        "status" => "success",
        "message" => "Driver rating saved",
        "rating_id" => $ratingId,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
