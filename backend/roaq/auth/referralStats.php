<?php
include "../connect.php";

$userId = (int) filterRequest("user_id");

if ($userId <= 0) {
    printFailure("MISSING_USER");
    exit;
}

$ensureWallet = $con->prepare("
    INSERT INTO wallet (user_id, points, balance)
    VALUES (:uid, 0, 0)
    ON DUPLICATE KEY UPDATE user_id = user_id
");
$ensureWallet->execute([':uid' => $userId]);

$walletStmt = $con->prepare("
    SELECT points, balance
    FROM wallet
    WHERE user_id = :uid
");
$walletStmt->execute([':uid' => $userId]);
$wallet = $walletStmt->fetch(PDO::FETCH_ASSOC) ?: ['points' => 0, 'balance' => 0];

$referralsStmt = $con->prepare("SELECT COUNT(*) FROM referrals WHERE referred_by = ?");
$referralsStmt->execute([$userId]);
$totalReferrals = (int)$referralsStmt->fetchColumn();

$activatedStmt = $con->prepare("SELECT COUNT(*) FROM referrals WHERE referred_by = ? AND is_activated = 1");
$activatedStmt->execute([$userId]);
$activatedReferrals = (int)$activatedStmt->fetchColumn();

echo json_encode([
    "referral_code" => 'AE-' . $userId,
    "referral_points" => (int)($wallet['points'] ?? 0),
    "wallet_balance" => (float)($wallet['balance'] ?? 0),
    "total_referrals" => $totalReferrals,
    "activated_referrals" => $activatedReferrals,
]);

