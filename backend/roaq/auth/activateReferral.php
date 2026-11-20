<?php
include "../connect.php";

header("Content-Type: application/json; charset=utf-8");

$email = trim((string) filterRequest("email"));
$referralCode = trim((string) filterRequest("referral_code"));

if ($email === '' || $referralCode === '') {
    echo json_encode([
        "status" => "error",
        "message" => "Missing email or referral_code",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function normalizeReferralCode(string $code): ?int
{
    $code = trim($code);

    if (preg_match('/^AE-(\d+)$/i', $code, $matches)) {
        return (int) $matches[1];
    }

    if (ctype_digit($code)) {
        return (int) $code;
    }

    return null;
}

$referrerId = normalizeReferralCode($referralCode);
if (!$referrerId || $referrerId <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Invalid referral code",
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $con->beginTransaction();

    $userStmt = $con->prepare("SELECT users_id FROM users WHERE users_email = ? LIMIT 1 FOR UPDATE");
    $userStmt->execute([$email]);
    $newUser = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$newUser) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "User not found",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $newUserId = (int) $newUser['users_id'];

    if ($newUserId === $referrerId) {
        $con->rollBack();
        echo json_encode([
            "status" => "error",
            "message" => "You cannot use your own referral code",
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $alreadyStmt = $con->prepare("SELECT id, is_activated FROM referrals WHERE user_id = ? LIMIT 1 FOR UPDATE");
    $alreadyStmt->execute([$newUserId]);
    $existingReferral = $alreadyStmt->fetch(PDO::FETCH_ASSOC);

    if ($existingReferral) {
        if ((int) $existingReferral['is_activated'] === 1) {
            $con->rollBack();
            echo json_encode([
                "status" => "success",
                "message" => "Referral already activated",
                "referral_code" => $referralCode,
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }

        $updateReferral = $con->prepare("
            UPDATE referrals
            SET referred_by = ?, is_activated = 1
            WHERE id = ?
        ");
        $updateReferral->execute([$referrerId, (int) $existingReferral['id']]);
    } else {
        $insertReferral = $con->prepare("
            INSERT INTO referrals (user_id, referred_by, is_activated)
            VALUES (?, ?, 1)
        ");
        $insertReferral->execute([$newUserId, $referrerId]);
    }

    $walletStmt = $con->prepare("
        SELECT id, points, balance
        FROM wallet
        WHERE user_id = ?
        LIMIT 1
        FOR UPDATE
    ");
    $walletStmt->execute([$referrerId]);
    $wallet = $walletStmt->fetch(PDO::FETCH_ASSOC);

    if (!$wallet) {
        $createWallet = $con->prepare("
            INSERT INTO wallet (user_id, points, balance)
            VALUES (?, 0, 0.00)
        ");
        $createWallet->execute([$referrerId]);

        $walletStmt->execute([$referrerId]);
        $wallet = $walletStmt->fetch(PDO::FETCH_ASSOC);
    }

    $pointsToAdd = 1;
    $newPoints = (int) ($wallet['points'] ?? 0) + $pointsToAdd;
    $walletId = (int) $wallet['id'];

    $updateWallet = $con->prepare("
        UPDATE wallet
        SET points = ?
        WHERE id = ?
    ");
    $updateWallet->execute([$newPoints, $walletId]);

    $con->commit();

    echo json_encode([
        "status" => "success",
        "message" => "Referral activated successfully",
        "referrer_id" => $referrerId,
        "new_user_id" => $newUserId,
        "points_awarded" => $pointsToAdd,
        "referral_code" => $referralCode,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
