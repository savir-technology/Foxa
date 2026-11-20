<?php
date_default_timezone_set("Africa/Cairo");

// ==== LOG FILE ====
$logFile = __DIR__ . "/upload_log.txt";

function writeLog($msg) {
    global $logFile;
    file_put_contents($logFile, "[" . date("Y-m-d H:i:s") . "] " . $msg . "\n", FILE_APPEND);
}

writeLog("=== START UPLOAD ===");

// ==== INCLUDE DB CONNECTION ====
include "../../../connect.php"; 
// يجب أن يحتوي connect.php على متغير $con  

if (!$con) {
    writeLog("DB CONNECTION FAILED");
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit;
}

// ==== VALIDATE USER ID ====
if (!isset($_POST['user_id'])) {
    writeLog("Missing user_id");
    echo json_encode(["status" => "error", "message" => "Missing user_id"]);
    exit;
}

$user_id = intval($_POST['user_id']);
writeLog("User ID: $user_id");

// ==== CHECK FILE ====
if (!isset($_FILES['file'])) {
    writeLog("No file uploaded");
    echo json_encode(["status" => "error", "message" => "No file uploaded"]);
    exit;
}

$file = $_FILES['file'];

writeLog("TMP: " . $file['tmp_name']);
writeLog("Type: " . $file['type']);
writeLog("Size: " . $file['size']);
writeLog("Error Code: " . $file['error']);

// ==== ALLOWED MIME TYPES ====
$allowed = [
    "image/jpeg",
    "image/png",
    "image/jpg",
    "image/gif",
    "image/webp"
];

// === REAL MIME CHECK ===
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$realMime = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

writeLog("Real MIME: $realMime");

if (!in_array($realMime, $allowed)) {
    writeLog("Invalid file type");
    echo json_encode(["status" => "error", "message" => "Invalid file type"]);
    exit;
}

// ==== UPLOAD DIRECTORY ====
// from: /dash/users/profile/upload_image.php
// to:   /uploads/users/img/
$uploadDir = __DIR__ . "/../../../uploads/users/img/";
writeLog("Upload Dir: $uploadDir");

// ==== CREATE DIR IF NOT EXISTS ====
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
    writeLog("Created directory");
}

// ==== NEW FILE NAME ====
$ext = pathinfo($file['name'], PATHINFO_EXTENSION);
$newName = "user_" . $user_id . "_" . time() . "." . $ext;
$uploadPath = $uploadDir . $newName;

writeLog("New File Name: $newName");

if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
    writeLog("Failed to move file");
    echo json_encode(["status" => "error", "message" => "Upload failed"]);
    exit;
}

writeLog("File uploaded successfully");

// ==== GET OLD IMAGE ====
$stmtOld = $con->prepare("SELECT users_image FROM users WHERE users_id = ?");
$stmtOld->execute([$user_id]);
$oldData = $stmtOld->fetch(PDO::FETCH_ASSOC);

$oldImage = $oldData ? $oldData['users_image'] : "";

if (!empty($oldImage)) {
    $oldPath = $uploadDir . $oldImage;
    if (file_exists($oldPath)) {
        unlink($oldPath);
        writeLog("Old image removed: $oldImage");
    }
}

// ==== UPDATE DATABASE ====
$stmt = $con->prepare("UPDATE users SET users_image = ? WHERE users_id = ?");
$updated = $stmt->execute([$newName, $user_id]);

if ($updated) {
    writeLog("Database updated successfully");
} else {
    writeLog("DB update FAILED");
}

// ==== FINAL URL ====
$url = "https://savir-technology.online/roaqv2/uploads/users/img/$newName";

// ==== RETURN RESPONSE ====
echo json_encode([
    "status" => "success",
    "url" => $url,
    "name" => $newName
]);

writeLog("=== END UPLOAD ===");
?>
