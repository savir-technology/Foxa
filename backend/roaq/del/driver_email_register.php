<?php
include __DIR__ . "/connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respondJson([
        'status' => 'error',
        'message' => 'POST required',
    ], 405);
}

try {
    ensureDriverOtpSchema();

    $verificationToken = trim((string)($_POST['verification_token'] ?? ''));
    $password = trim((string)($_POST['password'] ?? ''));
    $name = trim((string)($_POST['name'] ?? ''));
    $phone = trim((string)($_POST['phone'] ?? ''));
    $vendorId = (int)($_POST['vendor_id'] ?? 0);
    $vehicleType = trim((string)($_POST['vehicle_type'] ?? ''));
    $vehicleNumber = trim((string)($_POST['vehicle_number'] ?? ''));
    $locale = trim((string)($_POST['locale_code'] ?? $_POST['locale'] ?? ''));

    if ($vendorId > 0) {
        $vendorStmt = $con->prepare("SELECT vendor_id FROM vendors WHERE vendor_id = :id AND vendor_status = 'active' AND vendor_is_verified = 1 AND (vendor_approval_status = 'approved' OR vendor_approval_status IS NULL) LIMIT 1");
        $vendorStmt->execute([':id' => $vendorId]);
        if (!$vendorStmt->fetchColumn()) {
            respondJson(['status' => 'error', 'message' => 'selected store is not available for driver registration'], 400);
        }
    }

    if ($verificationToken === '' || $password === '' || $name === '' || $phone === '' || $vehicleType === '' || $vehicleNumber === '') {
        respondJson([
            'status' => 'error',
            'message' => 'verification token, password, name, phone, vehicle type and vehicle number are required',
        ], 400);
    }

    if (strlen($password) < 8) {
        respondJson([
            'status' => 'error',
            'message' => 'password too short',
        ], 400);
    }

    if (!preg_match('/[A-Z]/', $password) || !preg_match('/[a-z]/', $password) || !preg_match('/\d/', $password) || !preg_match('/[^A-Za-z0-9]/', $password)) {
        respondJson([
            'status' => 'error',
            'message' => 'password must be strong',
        ], 400);
    }

    $requestStmt = $con->prepare("
        SELECT *
        FROM driver_email_otp_requests
        WHERE verification_token = :token
          AND verified_at IS NOT NULL
          AND used_at IS NULL
          AND expires_at > NOW()
        ORDER BY otp_request_id DESC
        LIMIT 1
    ");
    $requestStmt->execute([':token' => $verificationToken]);
    $verificationRequest = $requestStmt->fetch(PDO::FETCH_ASSOC);

    if (!$verificationRequest) {
        respondJson([
            'status' => 'error',
            'message' => 'verification token is invalid or expired',
        ], 404);
    }

    $email = strtolower(trim((string)($verificationRequest['email'] ?? '')));
    if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        respondJson([
            'status' => 'error',
            'message' => 'verified email is invalid',
        ], 400);
    }

    $duplicatesStmt = $con->prepare("
        SELECT *
        FROM delivery_users
        WHERE LOWER(email) = :email
           OR phone = :phone
        LIMIT 2
    ");
    $duplicatesStmt->execute([
        ':email' => strtolower($email),
        ':phone' => $phone,
    ]);
    $matches = $duplicatesStmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($matches) > 1) {
        $ids = array_unique(array_map(static function ($row) {
            return $row['id'] ?? null;
        }, $matches));
        if (count($ids) > 1) {
            respondJson([
                'status' => 'error',
                'message' => 'phone/email already linked to another driver',
            ], 409);
        }
    }

    $driver = !empty($matches) ? $matches[0] : null;
    if ($driver && (int)($driver['profile_completed'] ?? 0) === 1) {
        respondJson([
            'status' => 'error',
            'message' => 'This email is already registered. Please sign in instead.',
        ], 409);
    }

    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
    $photoPath = null;
    if (isset($_FILES['profile_image']) && !empty($_FILES['profile_image']['name'])) {
        $uploadDir = __DIR__ . '/../uploads/drivers';
        if (!is_dir($uploadDir)) {
            @mkdir($uploadDir, 0775, true);
        }
        $uploaded = imageUpload($uploadDir, 'profile_image');
        if ($uploaded !== 'fail' && $uploaded !== 'empty') {
            $photoPath = 'uploads/drivers/' . $uploaded;
        }
    }

    $baseFields = [
        'name' => $name,
        'phone' => $phone,
        'email' => $email,
        'password' => $passwordHash,
        'vendor_id' => $vendorId > 0 ? $vendorId : null,
        'vehicle_type' => $vehicleType,
        'vehicle_number' => $vehicleNumber,
        'auth_provider' => 'email',
        'profile_completed' => 1,
        'email_verified_at' => date('Y-m-d H:i:s'),
        'password_set_at' => date('Y-m-d H:i:s'),
        'last_login_at' => date('Y-m-d H:i:s'),
        'locale_code' => $locale !== '' ? $locale : 'en',
    ];

    $hasApprovalStatus = function_exists('driverColumnExists') && driverColumnExists('delivery_users', 'approval_status');
    if ($hasApprovalStatus) {
        $baseFields['approval_status'] = $vendorId > 0 ? 'vendor_pending' : 'pending';
    }

    if ($photoPath !== null) {
        $baseFields['profile_image'] = $photoPath;
    }

    if (!$driver) {
        $insertSql = "
            INSERT INTO delivery_users (
                name,
                phone,
                email,
                password,
                vendor_id,
                vehicle_type,
                vehicle_number,
                auth_provider,
                profile_completed,
                email_verified_at,
                password_set_at,
                last_login_at,
                locale_code
                " . ($hasApprovalStatus ? ", approval_status" : "") . "
                " . ($photoPath !== null ? ", profile_image" : "") . "
            ) VALUES (
                :name,
                :phone,
                :email,
                :password,
                :vendor_id,
                :vehicle_type,
                :vehicle_number,
                :auth_provider,
                :profile_completed,
                :email_verified_at,
                :password_set_at,
                :last_login_at,
                :locale_code
                " . ($hasApprovalStatus ? ", :approval_status" : "") . "
                " . ($photoPath !== null ? ", :profile_image" : "") . "
            )
        ";
        $insertStmt = $con->prepare($insertSql);
        $insertStmt->execute($baseFields);

        $freshStmt = $con->prepare("
            SELECT du.*
            FROM delivery_users du
            WHERE du.id = LAST_INSERT_ID()
            LIMIT 1
        ");
        $freshStmt->execute();
        $driver = $freshStmt->fetch(PDO::FETCH_ASSOC);
    } else {
        $setParts = [];
        $params = [':id' => (int)$driver['id']];
        foreach ($baseFields as $column => $value) {
            $setParts[] = "{$column} = :{$column}";
            $params[":{$column}"] = $value;
        }

        $updateSql = "
            UPDATE delivery_users
            SET " . implode(', ', $setParts) . "
            WHERE id = :id
        ";
        $updateStmt = $con->prepare($updateSql);
        $updateStmt->execute($params);

        $freshStmt = $con->prepare("
            SELECT du.*
            FROM delivery_users du
            WHERE du.id = :id
            LIMIT 1
        ");
        $freshStmt->execute([':id' => (int)$driver['id']]);
        $driver = $freshStmt->fetch(PDO::FETCH_ASSOC);
    }

    if (!$driver) {
        respondJson([
            'status' => 'error',
            'message' => 'driver not found after registration',
        ], 500);
    }

    $markTokenStmt = $con->prepare("
        UPDATE driver_email_otp_requests
        SET used_at = NOW(),
            request_status = 'used'
        WHERE otp_request_id = :otp_request_id
    ");
    $markTokenStmt->execute([
        ':otp_request_id' => (int)$verificationRequest['otp_request_id'],
    ]);

    unset($driver['password']);

    respondJson([
        'status' => 'success',
        'message' => 'driver account created successfully',
        'driver_id' => $driver['id'] ?? null,
        'data' => $driver,
    ]);
} catch (Throwable $e) {
    error_log('driver_email_register failed: ' . $e->getMessage());
    respondJson([
        'status' => 'error',
        'message' => 'تعذر إكمال التسجيل، حاول مرة أخرى.',
    ], 500);
}
