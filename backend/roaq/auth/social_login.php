<?php
include "../connect.php";

$provider = strtolower(trim((string) filterRequest("provider")));
$socialId = trim((string) filterRequest("social_id"));
$email = trim((string) filterRequest("email"));
$username = trim((string) filterRequest("username"));
$photo = trim((string) filterRequest("photo"));

if ($provider === "" || $socialId === "" || $email === "") {
    echo json_encode(array(
        "status" => "failure",
        "message" => "Missing provider, social_id or email"
    ));
    exit;
}

if ($username === "") {
    $username = $email;
}

try {
    // 1) Check existing user by email.
    $stmt = $con->prepare("SELECT * FROM users WHERE users_email = ? LIMIT 1");
    $stmt->execute(array($email));
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        // Ensure user is approved for social login.
        if ((int) ($existing["users_approve"] ?? 0) !== 1) {
            $up = $con->prepare("UPDATE users SET users_approve = 1 WHERE users_id = ?");
            $up->execute(array($existing["users_id"]));
        }

        // Update name if empty and social provides one.
        if (trim((string) ($existing["users_name"] ?? "")) === "" && $username !== "") {
            $upName = $con->prepare("UPDATE users SET users_name = ? WHERE users_id = ?");
            $upName->execute(array($username, $existing["users_id"]));
        }

        // Optional photo update if column exists and value provided.
        if ($photo !== "") {
            try {
                $upPhoto = $con->prepare("UPDATE users SET users_image = ? WHERE users_id = ?");
                $upPhoto->execute(array($photo, $existing["users_id"]));
            } catch (Exception $e) {
                // Ignore photo update issues to keep login flow successful.
            }
        }

        $stmtFresh = $con->prepare("SELECT * FROM users WHERE users_id = ? LIMIT 1");
        $stmtFresh->execute(array($existing["users_id"]));
        $data = $stmtFresh->fetch(PDO::FETCH_ASSOC);

        echo json_encode(array("status" => "success", "data" => $data));
        exit;
    }

    // 2) Create new social user.
    $verifyCode = rand(10000, 99999);
    $randomPassword = bin2hex(random_bytes(16));

    // Phone field exists in current schema; generate a unique placeholder.
    $basePhone = "social_" . substr(preg_replace("/[^a-zA-Z0-9]/", "", $socialId), 0, 20);
    if ($basePhone === "social_") {
        $basePhone = "social_" . time();
    }
    $phone = $basePhone;

    // Retry with unique suffix if phone conflicts.
    $inserted = false;
    $newUserId = 0;
    for ($i = 0; $i < 5; $i++) {
        try {
            $stmtInsert = $con->prepare(
                "INSERT INTO users (users_name, users_password, users_email, users_phone, users_verfiycode, users_approve)
                 VALUES (?, ?, ?, ?, ?, 1)"
            );
            $stmtInsert->execute(array($username, $randomPassword, $email, $phone, $verifyCode));
            $newUserId = (int) $con->lastInsertId();
            $inserted = true;
            break;
        } catch (PDOException $e) {
            // Try a different phone if conflict happens.
            $phone = $basePhone . "_" . rand(100, 9999);
            if ($i === 4) {
                throw $e;
            }
        }
    }

    if (!$inserted || $newUserId <= 0) {
        echo json_encode(array(
            "status" => "failure",
            "message" => "Unable to create social user"
        ));
        exit;
    }

    if ($photo !== "") {
        try {
            $upPhoto = $con->prepare("UPDATE users SET users_image = ? WHERE users_id = ?");
            $upPhoto->execute(array($photo, $newUserId));
        } catch (Exception $e) {
            // Ignore photo update issues to keep login flow successful.
        }
    }

    $stmtNew = $con->prepare("SELECT * FROM users WHERE users_id = ? LIMIT 1");
    $stmtNew->execute(array($newUserId));
    $data = $stmtNew->fetch(PDO::FETCH_ASSOC);

    echo json_encode(array("status" => "success", "data" => $data));
} catch (Exception $e) {
    echo json_encode(array(
        "status" => "failure",
        "message" => "social_login_error",
        "error" => $e->getMessage()
    ));
}

