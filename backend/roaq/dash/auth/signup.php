<?php
include "../../connect.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$signupUploadRoot = realpath(__DIR__ . '/../../');
if ($signupUploadRoot === false) {
    respondJson([
        'status' => 'error',
        'message' => 'Unable to resolve upload root',
    ], 500);
}

function isBase64Image($value)
{
    return is_string($value) && trim($value) !== '' && strlen(trim($value)) > 100;
}

function saveBase64Image($base64Image, $uploadDir, $baseUrl, $prefix)
{
    if (!isBase64Image($base64Image)) {
        return null;
    }

    $payload = trim($base64Image);
    $mime = null;

    if (preg_match('#^data:(image/[a-zA-Z0-9.+-]+);base64,(.+)$#s', $payload, $matches)) {
        $mime = strtolower($matches[1]);
        $payload = $matches[2];
    }

    $decoded = base64_decode($payload, true);
    if ($decoded === false) {
        return null;
    }

    if ($mime === null && function_exists('finfo_open')) {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo) {
            $detectedMime = finfo_buffer($finfo, $decoded);
            if (is_string($detectedMime) && $detectedMime !== '') {
                $mime = strtolower($detectedMime);
            }
            finfo_close($finfo);
        }
    }

    $extensionMap = [
        'image/jpeg' => 'jpg',
        'image/jpg' => 'jpg',
        'image/png' => 'png',
        'image/gif' => 'gif',
        'image/webp' => 'webp',
        'image/bmp' => 'bmp',
        'image/svg+xml' => 'svg',
    ];
    $extension = $extensionMap[$mime] ?? 'png';

    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $fileName = $prefix . '_' . uniqid('', true) . '.' . $extension;
    $filePath = $uploadDir . DIRECTORY_SEPARATOR . $fileName;
    if (file_put_contents($filePath, $decoded) === false) {
        return null;
    }

    return [
        'file_name' => $fileName,
        'url' => rtrim($baseUrl, '/') . '/' . $fileName,
    ];
}

function defaultSignupWorkingHoursJson()
{
    return json_encode([
        ['day_key' => 'mon', 'day_label' => 'الاثنين', 'is_open' => 1, 'open_time' => '10:00', 'close_time' => '23:00'],
        ['day_key' => 'tue', 'day_label' => 'الثلاثاء', 'is_open' => 1, 'open_time' => '10:00', 'close_time' => '23:00'],
        ['day_key' => 'wed', 'day_label' => 'الأربعاء', 'is_open' => 1, 'open_time' => '10:00', 'close_time' => '23:00'],
        ['day_key' => 'thu', 'day_label' => 'الخميس', 'is_open' => 1, 'open_time' => '10:00', 'close_time' => '23:00'],
        ['day_key' => 'fri', 'day_label' => 'الجمعة', 'is_open' => 1, 'open_time' => '12:00', 'close_time' => '23:30'],
        ['day_key' => 'sat', 'day_label' => 'السبت', 'is_open' => 1, 'open_time' => '10:00', 'close_time' => '23:00'],
        ['day_key' => 'sun', 'day_label' => 'الأحد', 'is_open' => 1, 'open_time' => '10:00', 'close_time' => '23:00'],
    ], JSON_UNESCAPED_UNICODE);
}

$payload = json_decode(file_get_contents("php://input"), true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$vendorName = trim((string)($payload['vendor_name'] ?? ''));
$storeName = trim((string)($payload['store_name'] ?? ''));
$email = strtolower(trim((string)($payload['email'] ?? $payload['vendor_email'] ?? '')));
$phone = trim((string)($payload['phone'] ?? $payload['vendor_phone'] ?? ''));
$password = (string)($payload['password'] ?? '');
$storeAddress = trim((string)($payload['store_address'] ?? ''));
$storeLatitude = $payload['store_latitude'] ?? null;
$storeLongitude = $payload['store_longitude'] ?? null;
$vendorLogoBase64 = $payload['vendor_logo_base64'] ?? ($payload['vendor_logo'] ?? null);
$vendorDescription = trim((string)($payload['vendor_description'] ?? ''));
$vendorType = strtolower(trim((string)($payload['vendor_type'] ?? 'restaurant')));
$storeCategory = strtolower(trim((string)($payload['store_category'] ?? '')));

$allowedVendorTypes = ['restaurant', 'store'];
$allowedStoreCategories = ['fashion', 'shoes', 'perfume', 'grocery', 'fresh_food', 'canned_food', 'electronics', 'toys', 'general'];
if (!in_array($vendorType, $allowedVendorTypes, true)) {
    $vendorType = 'restaurant';
}
if ($vendorType === 'store' && !in_array($storeCategory, $allowedStoreCategories, true)) {
    respondJson(['status' => 'error', 'message' => 'Store category is required'], 400);
}
if ($vendorType === 'restaurant') {
    $storeCategory = null;
}

if (
    $vendorName === '' ||
    $storeName === '' ||
    $email === '' ||
    $phone === '' ||
    $password === '' ||
    $storeAddress === '' ||
    $storeLatitude === null ||
    $storeLongitude === null ||
    $vendorLogoBase64 === null
) {
    respondJson([
        'status' => 'error',
        'message' => 'Missing required signup fields',
    ], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid email address',
    ], 400);
}

if (!is_numeric($storeLatitude) || !is_numeric($storeLongitude)) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid store coordinates',
    ], 400);
}

if (strlen($password) < 6) {
    respondJson([
        'status' => 'error',
        'message' => 'Password must be at least 6 characters',
    ], 400);
}

$logoUploadDir = $signupUploadRoot . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'vendors' . DIRECTORY_SEPARATOR . 'logo';
$logoBaseUrl = 'https://savir-technology.online/roaqv2/uploads/vendors/logo';
$savedLogo = saveBase64Image(
    $vendorLogoBase64,
    $logoUploadDir,
    $logoBaseUrl,
    'vendor_logo'
);

if ($savedLogo === null) {
    respondJson([
        'status' => 'error',
        'message' => 'Invalid vendor logo image',
    ], 400);
}

try {
    $checkStmt = $con->prepare("
        SELECT vendor_id
        FROM vendors
        WHERE vendor_email = :email
        LIMIT 1
    ");
    $checkStmt->execute([':email' => $email]);

    if ($checkStmt->fetch(PDO::FETCH_ASSOC)) {
        respondJson([
            'status' => 'error',
            'message' => 'Email is already registered',
        ], 409);
    }

    $slugBase = generateStoreSlug($storeName !== '' ? $storeName : $vendorName);
    $slug = $slugBase;
    $suffix = 1;

    while (true) {
        $slugStmt = $con->prepare("
            SELECT vendor_id
            FROM vendors
            WHERE store_slug = :slug
            LIMIT 1
        ");
        $slugStmt->execute([':slug' => $slug]);
        if (!$slugStmt->fetch(PDO::FETCH_ASSOC)) {
            break;
        }
        $suffix++;
        $slug = $slugBase . '-' . $suffix;
    }

    $verifyCode = generateOtpCode();
    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
    $workingHoursJson = defaultSignupWorkingHoursJson();

    $con->beginTransaction();

    $insertStmt = $con->prepare("
        INSERT INTO vendors (
            vendor_name,
            store_name,
            store_slug,
            vendor_email,
            vendor_phone,
            vendor_password,
            vendor_logo,
            vendor_description,
            vendor_status,
            vendor_is_verified,
            vendor_type,
            store_category,
            vendor_verify_code
        ) VALUES (
            :vendor_name,
            :store_name,
            :store_slug,
            :vendor_email,
            :vendor_phone,
            :vendor_password,
            :vendor_logo,
            :vendor_description,
            'pending',
            0,
            :vendor_type,
            :store_category,
            :vendor_verify_code
        )
    ");

    $insertStmt->execute([
        ':vendor_name' => $vendorName,
        ':store_name' => $storeName,
        ':store_slug' => $slug,
        ':vendor_email' => $email,
        ':vendor_phone' => $phone,
        ':vendor_password' => $passwordHash,
        ':vendor_logo' => $savedLogo['url'],
        ':vendor_description' => $vendorDescription !== '' ? $vendorDescription : null,
        ':vendor_verify_code' => $verifyCode,
        ':vendor_type' => $vendorType,
        ':store_category' => $storeCategory,
    ]);

    $vendorId = (int)$con->lastInsertId();

    $settingsStmt = $con->prepare("
        INSERT INTO vendor_store_settings (
            vendor_id,
            store_name,
            store_slug,
            vendor_name,
            vendor_email,
            vendor_phone,
            vendor_logo,
            vendor_description,
            store_address,
            store_latitude,
            store_longitude,
            working_hours_json
        ) VALUES (
            :vendor_id,
            :store_name,
            :store_slug,
            :vendor_name,
            :vendor_email,
            :vendor_phone,
            :vendor_logo,
            :vendor_description,
            :store_address,
            :store_latitude,
            :store_longitude,
            :working_hours_json
        )
        ON DUPLICATE KEY UPDATE
            store_name = VALUES(store_name),
            store_slug = VALUES(store_slug),
            vendor_name = VALUES(vendor_name),
            vendor_email = VALUES(vendor_email),
            vendor_phone = VALUES(vendor_phone),
            vendor_logo = VALUES(vendor_logo),
            vendor_description = VALUES(vendor_description),
            store_address = VALUES(store_address),
            store_latitude = VALUES(store_latitude),
            store_longitude = VALUES(store_longitude),
            working_hours_json = VALUES(working_hours_json)
    ");
    $settingsStmt->execute([
        ':vendor_id' => $vendorId,
        ':store_name' => $storeName,
        ':store_slug' => $slug,
        ':vendor_name' => $vendorName,
        ':vendor_email' => $email,
        ':vendor_phone' => $phone,
        ':vendor_logo' => $savedLogo['url'],
        ':vendor_description' => $vendorDescription !== '' ? $vendorDescription : null,
        ':store_address' => $storeAddress,
        ':store_latitude' => (float)$storeLatitude,
        ':store_longitude' => (float)$storeLongitude,
        ':working_hours_json' => $workingHoursJson,
    ]);

    if (!sendEmailWithFallback($email, 'Vendor Signup Verification', $verifyCode)) {
        throw new RuntimeException('Unable to send verification email');
    }

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Signup completed. Verify your email to continue.',
        'email' => $email,
        'vendor_id' => $vendorId,
        'store_name' => $storeName,
        'vendor_name' => $vendorName,
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    respondJson([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
