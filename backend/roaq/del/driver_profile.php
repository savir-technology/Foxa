<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");

function ensureDriverProfileColumns(PDO $con): void
{
    static $checked = false;
    if ($checked) {
        return;
    }

    $checked = true;
    $requiredColumns = [
        'email' => "VARCHAR(190) NULL",
        'password' => "VARCHAR(255) NULL",
        'vehicle_type' => "VARCHAR(100) NULL",
        'vehicle_number' => "VARCHAR(100) NULL",
        'vendor_id' => "INT(11) NULL",
        'notifications_enabled' => "TINYINT(1) NOT NULL DEFAULT 1",
        'location_sharing_enabled' => "TINYINT(1) NOT NULL DEFAULT 1",
        'locale_code' => "VARCHAR(10) NOT NULL DEFAULT 'en'",
        'theme_mode' => "VARCHAR(10) NOT NULL DEFAULT 'dark'",
    ];

    foreach ($requiredColumns as $column => $definition) {
        $stmt = $con->prepare("SHOW COLUMNS FROM delivery_users LIKE ?");
        $stmt->execute([$column]);
        $exists = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$exists) {
            $con->exec("ALTER TABLE delivery_users ADD COLUMN {$column} {$definition}");
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "POST required"]);
    exit;
}

$phone = trim((string)($_POST['phone'] ?? ''));
$email = trim((string)($_POST['email'] ?? ''));
$name = trim((string)($_POST['name'] ?? ''));
$vehicleType = trim((string)($_POST['vehicle_type'] ?? ''));
$vehicleNumber = trim((string)($_POST['vehicle_number'] ?? ''));
$vendorId = (int)($_POST['vendor_id'] ?? 0);
$password = trim((string)($_POST['password'] ?? ''));
$notificationsEnabled = trim((string)($_POST['notifications_enabled'] ?? ''));
$locationSharingEnabled = trim((string)($_POST['location_sharing_enabled'] ?? ''));
$localeCode = trim((string)($_POST['locale_code'] ?? ''));
$themeMode = trim((string)($_POST['theme_mode'] ?? ''));

if ($phone === '' && $email === '') {
    echo json_encode(["status" => "error", "message" => "phone or email is required"]);
    exit;
}

try {
    try {
        ensureDriverProfileColumns($con);
    } catch (Throwable $schemaError) {
        // The profile still works even if schema upgrades are not permitted.
    }

    $conditions = [];
    $params = [];
    if ($phone !== '') {
        $conditions[] = "phone = ?";
        $params[] = $phone;
    }
    if ($email !== '') {
        $conditions[] = "email = ?";
        $params[] = $email;
    }

    $driver = null;
    if (!empty($conditions)) {
        $select = $con->prepare(
            "SELECT * FROM delivery_users WHERE " . implode(" OR ", $conditions) . " LIMIT 2"
        );
        $select->execute($params);
        $matches = $select->fetchAll(PDO::FETCH_ASSOC);

        if (count($matches) > 1) {
            $ids = array_unique(array_map(function ($row) {
                return $row['id'] ?? null;
            }, $matches));
            if (count($ids) > 1) {
                echo json_encode([
                    "status" => "error",
                    "message" => "phone/email already linked to another driver",
                ], JSON_UNESCAPED_UNICODE);
                exit;
            }
        }

        if (!empty($matches)) {
            $driver = $matches[0];
        }
    }

    if (!$driver) {
        $insert = $con->prepare("
            INSERT INTO delivery_users (
                name, phone, email, password, status, latitude, longitude,
                vendor_id, notifications_enabled, location_sharing_enabled, locale_code, theme_mode
            )
            VALUES (?, ?, ?, ?, 'offline', NULL, NULL, ?, ?, ?, ?, ?)
        ");
        $insert->execute([
            $name !== '' ? $name : ($email !== '' ? $email : $phone),
            $phone !== '' ? $phone : $email,
            $email !== '' ? $email : null,
            $password !== '' ? password_hash($password, PASSWORD_DEFAULT) : null,
            $vendorId > 0 ? $vendorId : null,
            $notificationsEnabled !== '' ? (int)($notificationsEnabled !== '0') : 1,
            $locationSharingEnabled !== '' ? (int)($locationSharingEnabled !== '0') : 1,
            $localeCode !== '' ? $localeCode : 'en',
            $themeMode !== '' ? $themeMode : 'dark',
        ]);

        $select = $con->prepare("
            SELECT du.*
            FROM delivery_users du
            WHERE du.id = LAST_INSERT_ID()
            LIMIT 1
        ");
        $select->execute();
        $driver = $select->fetch(PDO::FETCH_ASSOC);
    } else {
        $updates = [];
        $values = [];

        if ($name !== '') {
            $updates[] = "name = ?";
            $values[] = $name;
        }
        if ($phone !== '') {
            $updates[] = "phone = ?";
            $values[] = $phone;
        }
        if ($email !== '') {
            $updates[] = "email = ?";
            $values[] = $email;
        }
        if ($password !== '') {
            $updates[] = "password = ?";
            $values[] = password_hash($password, PASSWORD_DEFAULT);
        }
        if ($notificationsEnabled !== '' && array_key_exists('notifications_enabled', $driver)) {
            $updates[] = "notifications_enabled = ?";
            $values[] = (int)($notificationsEnabled !== '0');
        }
        if ($locationSharingEnabled !== '' && array_key_exists('location_sharing_enabled', $driver)) {
            $updates[] = "location_sharing_enabled = ?";
            $values[] = (int)($locationSharingEnabled !== '0');
        }
        if ($localeCode !== '' && array_key_exists('locale_code', $driver)) {
            $updates[] = "locale_code = ?";
            $values[] = $localeCode;
        }
        if ($themeMode !== '' && array_key_exists('theme_mode', $driver)) {
            $updates[] = "theme_mode = ?";
            $values[] = $themeMode;
        }
        if ($vehicleType !== '' && array_key_exists('vehicle_type', $driver)) {
            $updates[] = "vehicle_type = ?";
            $values[] = $vehicleType;
        }
        if ($vehicleNumber !== '' && array_key_exists('vehicle_number', $driver)) {
            $updates[] = "vehicle_number = ?";
            $values[] = $vehicleNumber;
        }
        if ($vendorId > 0 && array_key_exists('vendor_id', $driver)) {
            $updates[] = "vendor_id = ?";
            $values[] = $vendorId;
        }

        if (!empty($updates)) {
            $values[] = $driver['id'];
            $update = $con->prepare(
                "UPDATE delivery_users SET " . implode(', ', $updates) . " WHERE id = ?"
            );
            $update->execute($values);
        }

        $select = $con->prepare("
            SELECT du.*
            FROM delivery_users du
            WHERE du.id = ?
            LIMIT 1
        ");
        $select->execute([$driver['id']]);
        $driver = $select->fetch(PDO::FETCH_ASSOC);
    }

    if (!$driver) {
        echo json_encode(["status" => "error", "message" => "driver not found"]);
        exit;
    }

    unset($driver['password']);

    echo json_encode([
        "status" => "success",
        "message" => "driver profile loaded",
        "driver_id" => $driver['id'] ?? null,
        "data" => $driver,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
