<?php
include "../connect.php";

$userId = (int) filterRequest("user_id");
$pointsToConvert = (int) filterRequest("points");
$rate = 0.10;

if ($userId <= 0 || $pointsToConvert <= 0) {
    printFailure("MISSING_DATA");
    exit;
}

try {
    $con->beginTransaction();

    $ensureWallet = $con->prepare("
        INSERT INTO wallet (user_id, points, balance)
        VALUES (:uid, 0, 0)
        ON DUPLICATE KEY UPDATE user_id = user_id
    ");
    $ensureWallet->execute([':uid' => $userId]);

    $stmt = $con->prepare("
        SELECT points
        FROM wallet
        WHERE user_id = :uid
        FOR UPDATE
    ");
    $stmt->execute([':uid' => $userId]);
    $currentPoints = (int)($stmt->fetchColumn() ?: 0);

    if ($pointsToConvert > $currentPoints) {
        $con->rollBack();
        printFailure("NOT_ENOUGH_POINTS");
        exit;
    }

    $cash = $pointsToConvert * $rate;

    $stmt2 = $con->prepare("
        UPDATE wallet
        SET points = points - :points,
            balance = balance + :cash
        WHERE user_id = :uid
    ");
    $stmt2->execute([
        ':points' => $pointsToConvert,
        ':cash' => $cash,
        ':uid' => $userId,
    ]);

    $con->commit();
    printSuccess("CONVERT_SUCCESS");
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    printFailure($e->getMessage());
}

