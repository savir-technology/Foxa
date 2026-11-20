<?php
header('Content-Type: application/json; charset=utf-8');
include "connect.php";

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => 'error',
        'message' => 'POST required',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$driverId = (int)($_POST['driver_id'] ?? 0);
$pushToken = trim((string)($_POST['push_token'] ?? ''));
$platform = trim((string)($_POST['platform'] ?? ''));
$deviceName = trim((string)($_POST['device_name'] ?? ''));

if ($driverId <= 0 || $pushToken === '') {
    echo json_encode([
        'status' => 'error',
        'message' => 'driver_id and push_token are required',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $driverStmt = $con->prepare('SELECT id FROM delivery_users WHERE id = ? LIMIT 1');
    $driverStmt->execute([$driverId]);
    if (!$driverStmt->fetchColumn()) {
        echo json_encode([
            'status' => 'error',
            'message' => 'driver not found',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $normalizeNullable = static function (string $value): ?string {
        $value = trim($value);
        return $value === '' ? null : $value;
    };

    $platform = $normalizeNullable($platform) ?? null;
    $deviceName = $normalizeNullable($deviceName) ?? null;

    $existingStmt = $con->prepare('
        SELECT token_id
        FROM delivery_driver_push_tokens
        WHERE push_token = ?
        LIMIT 1
    ');
    $existingStmt->execute([$pushToken]);
    $existingTokenId = (int)($existingStmt->fetchColumn() ?: 0);

    if ($existingTokenId > 0) {
        $updateStmt = $con->prepare('
            UPDATE delivery_driver_push_tokens
            SET driver_id = ?,
                platform = ?,
                device_name = ?,
                is_active = 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE token_id = ?
        ');
        $updateStmt->execute([
            $driverId,
            $platform,
            $deviceName,
            $existingTokenId,
        ]);
    } else {
        $insertStmt = $con->prepare('
            INSERT INTO delivery_driver_push_tokens (
                driver_id,
                push_token,
                platform,
                device_name,
                is_active,
                created_at,
                updated_at
            ) VALUES (?, ?, ?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ');
        $insertStmt->execute([
            $driverId,
            $pushToken,
            $platform,
            $deviceName,
        ]);
        $existingTokenId = (int)$con->lastInsertId();
    }

    if ($existingTokenId > 0) {
        $deactivateStmt = $con->prepare('
            UPDATE delivery_driver_push_tokens
            SET is_active = 0,
                updated_at = CURRENT_TIMESTAMP
            WHERE driver_id = ?
              AND token_id <> ?
        ');
        $deactivateStmt->execute([
            $driverId,
            $existingTokenId,
        ]);
    }

    echo json_encode([
        'status' => 'success',
        'message' => 'push token saved',
        'data' => [
            'driver_id' => $driverId,
            'push_token' => $pushToken,
            'platform' => $platform,
            'device_name' => $deviceName,
        ],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
