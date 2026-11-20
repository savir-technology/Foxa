<?php
include "../connect.php";

header("Content-Type: application/json; charset=utf-8");

$uploadDir = __DIR__ . "/uploud/img/";
$baseUrl = "https://savir-technology.online/roaqv2/ads/uploud/img/";

if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

function failResponse($message, $code = 400) {
    http_response_code($code);
    echo json_encode([
        "status" => "failure",
        "message" => $message,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    failResponse("Invalid request method", 405);
}

if (!isset($_FILES["image"]) || !is_uploaded_file($_FILES["image"]["tmp_name"])) {
    failResponse("Media file is required");
}

$titleAr = trim($_POST["title_ar"] ?? "");
$titleEn = trim($_POST["title_en"] ?? "");
$linkUrl = trim($_POST["link_url"] ?? "");
$targetType = strtolower(trim($_POST["target_type"] ?? ""));
$targetId = (int) ($_POST["target_id"] ?? 0);
$placement = trim($_POST["placement"] ?? "home");
$sortOrder = (int) ($_POST["sort_order"] ?? 0);
$displaySeconds = max(4, (int) ($_POST["display_seconds"] ?? 8));
$isActive = isset($_POST["is_active"]) ? (int) $_POST["is_active"] : 1;
$openInWebView = isset($_POST["open_in_webview"]) ? (int) $_POST["open_in_webview"] : 0;

$internalTarget = null;
if (preg_match('/^(product|item|restaurant):\s*(\d+)$/i', $linkUrl, $matches)) {
    $internalTarget = [
        strtolower($matches[1]),
        (int)$matches[2],
    ];
}

if ($targetType === "item") {
    $targetType = "product";
}

if (!in_array($targetType, ["product", "restaurant"], true)) {
    if ($internalTarget !== null) {
        $targetType = $internalTarget[0] === "item"
            ? "product"
            : $internalTarget[0];
        $targetId = $internalTarget[1];
    } else {
        failResponse("Target must be a restaurant or product");
    }
}

if ($targetId <= 0 && $internalTarget !== null) {
    $targetId = $internalTarget[1];
}

if ($targetId <= 0) {
    failResponse("Target id is required");
}

$linkUrl = $targetType . ":" . $targetId;
$image = $_FILES["image"];

if (($image["error"] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    failResponse("Failed to upload media");
}

$extension = strtolower(pathinfo($image["name"], PATHINFO_EXTENSION));
$allowed = ["jpg", "jpeg", "png", "webp", "gif", "mp4", "webm", "mov", "m4v"];

if (!in_array($extension, $allowed, true)) {
    failResponse("Unsupported media format");
}

$fileName = "ads2_" . time() . "_" . bin2hex(random_bytes(4)) . "." . $extension;
$targetPath = $uploadDir . $fileName;

if (!move_uploaded_file($image["tmp_name"], $targetPath)) {
    failResponse("Failed to save media");
}

$imageUrl = $baseUrl . $fileName;

try {
    $stmt = $con->prepare("
        INSERT INTO ads2 (
            title_ar,
            title_en,
            image_url,
            link_url,
            target_type,
            target_id,
            placement,
            sort_order,
            display_seconds,
            is_active,
            open_in_webview,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    $stmt->execute([
        $titleAr,
        $titleEn,
        $imageUrl,
        $linkUrl,
        $targetType,
        $targetId > 0 ? $targetId : null,
        $placement !== "" ? $placement : "home",
        $sortOrder,
        $displaySeconds,
        $isActive ? 1 : 0,
        $openInWebView ? 1 : 0,
    ]);

    echo json_encode([
        "status" => "success",
        "message" => "Ad created successfully",
        "data" => [
            "id" => $con->lastInsertId(),
            "title" => $titleAr !== "" ? $titleAr : $titleEn,
            "title_ar" => $titleAr,
            "title_en" => $titleEn,
            "image_url" => $imageUrl,
            "link_url" => $linkUrl,
            "target_type" => $targetType,
            "target_id" => $targetId > 0 ? $targetId : null,
            "placement" => $placement !== "" ? $placement : "home",
            "sort_order" => $sortOrder,
            "display_seconds" => $displaySeconds,
            "is_active" => $isActive ? 1 : 0,
            "open_in_webview" => $openInWebView ? 1 : 0
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (PDOException $e) {
    if (file_exists($targetPath)) {
        unlink($targetPath);
    }
    failResponse($e->getMessage(), 500);
}
?>
