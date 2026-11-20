<?php
header('Content-Type: application/json; charset=utf-8');
include "../connect.php"; // your existing PDO $con connection
date_default_timezone_set('Africa/Cairo'); // keep consistent with your DB timestamps

// read input
$usersid = isset($_REQUEST['usersid']) ? intval($_REQUEST['usersid']) : 0;
if ($usersid <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'failure', 'message' => 'Missing or invalid usersid']);
    exit();
}

try {
    $now = new DateTime();
    $nowStr = $now->format('Y-m-d H:i:s');
    // cooldown in seconds (12 hours)
    $cooldownSeconds = 12 * 3600;

    // find last spin for user
    $stmt = $con->prepare("SELECT spin_time FROM user_spins WHERE user_id = ? ORDER BY spin_time DESC LIMIT 1");
    $stmt->execute([$usersid]);
    $last = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($last && !empty($last['spin_time'])) {
        $lastTime = new DateTime($last['spin_time']);
        $diff = $now->getTimestamp() - $lastTime->getTimestamp();
        if ($diff < $cooldownSeconds) {
            $remaining = $cooldownSeconds - $diff;
            http_response_code(429);
            echo json_encode([
                'status' => 'failure',
                'message' => 'Cooldown not finished',
                'next_allowed' => $remaining
            ]);
            exit();
        }
    }

    // decide outcome server-side: 25% win
    $rand = random_int(0, 99); // secure random
    $isWin = ($rand < 25); // 25% probability

    if (!$isWin) {
        // record a losing spin
        $insert = $con->prepare("INSERT INTO user_spins (user_id, outcome, coupon_id, spin_time) VALUES (?, 'lose', NULL, ?)");
        $insert->execute([$usersid, $nowStr]);

        echo json_encode([
            'status' => 'success',
            'result' => 'lose',
            'message' => 'Better luck next time.',
            'next_allowed' => $cooldownSeconds
        ]);
        exit();
    }

    // if win -> try to find a coupon not already assigned to user, not expired and with count > 0
    // use transaction to avoid race conditions
    $con->beginTransaction();

    // Choose a coupon random that user does not have and is valid
    // This uses a subquery to exclude coupons already in user_coupons
    $select = $con->prepare("
        SELECT coupon_id, coupon_name, coupon_discount, coupon_count, coupon_expiredate
        FROM coupon
        WHERE coupon_count > 0
          AND coupon_expiredate > :now
          AND vendor_id IS NOT NULL
          AND coupon_id NOT IN (SELECT coupon_id FROM user_coupons WHERE user_id = :uid)
        ORDER BY RAND()
        LIMIT 1
        FOR UPDATE
    ");
    $select->execute([':now' => $nowStr, ':uid' => $usersid]);
    $coupon = $select->fetch(PDO::FETCH_ASSOC);

    if (!$coupon) {
        // no available coupon -> treat as lose (but still record)
        $ins = $con->prepare("INSERT INTO user_spins (user_id, outcome, coupon_id, spin_time) VALUES (?, 'lose', NULL, ?)");
        $ins->execute([$usersid, $nowStr]);
        $con->commit();

        echo json_encode([
            'status' => 'failure',
            'result' => 'lose',
            'message' => 'No coupons available at the moment',
            'next_allowed' => $cooldownSeconds
        ]);
        exit();
    }

    // decrement coupon_count safely
    $update = $con->prepare("UPDATE coupon SET coupon_count = coupon_count - 1 WHERE coupon_id = ? AND coupon_count > 0");
    $update->execute([$coupon['coupon_id']]);
    if ($update->rowCount() <= 0) {
        // another process consumed it, rollback and return lose
        $con->rollBack();
        $ins = $con->prepare("INSERT INTO user_spins (user_id, outcome, coupon_id, spin_time) VALUES (?, 'lose', NULL, ?)");
        $ins->execute([$usersid, $nowStr]);
        echo json_encode([
            'status' => 'failure',
            'result' => 'lose',
            'message' => 'No coupons available, try again later',
            'next_allowed' => $cooldownSeconds
        ]);
        exit();
    }

    // assign coupon to user
    $insCoupon = $con->prepare("INSERT INTO user_coupons (user_id, coupon_id, assigned_at, is_redeemed) VALUES (?, ?, ?, 0)");
    $insCoupon->execute([$usersid, $coupon['coupon_id'], $nowStr]);

    // record spin as win
    $insSpin = $con->prepare("INSERT INTO user_spins (user_id, outcome, coupon_id, spin_time) VALUES (?, 'win', ?, ?)");
    $insSpin->execute([$usersid, $coupon['coupon_id'], $nowStr]);

    $con->commit();

    // Return coupon info
    echo json_encode([
        'status' => 'success',
        'result' => 'win',
        'coupon' => [
            'coupon_id' => $coupon['coupon_id'],
            'coupon_name' => $coupon['coupon_name'],
            'coupon_discount' => $coupon['coupon_discount'],
            'coupon_expiredate' => $coupon['coupon_expiredate']
        ],
        'next_allowed' => $cooldownSeconds
    ]);
    exit();
} catch (PDOException $e) {
    if ($con->inTransaction()) $con->rollBack();
    // log server error (do not expose detailed DB errors to clients in production)
    error_log('spin.php error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Server error']);
    exit();
}
