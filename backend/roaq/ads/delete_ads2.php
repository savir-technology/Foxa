<?php
include "../connect.php";

header("Content-Type: application/json; charset=utf-8");

$uploadDir = __DIR__ . "/uploud/img/";
$baseUrl = "https://savir-technology.online/roaqv2/ads/uploud/img/";

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

$id = (int) ($_POST["id"] ?? 0);
if ($id <= 0) {
    failResponse("Invalid ad id");
}

try {
    $stmt = $con->prepare("SELECT image_url FROM ads2 WHERE id = ?");
    $stmt->execute([$id]);
    $current = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$current) {
        failResponse("Ad not found", 404);
    }

    $deleteStmt = $con->prepare("DELETE FROM ads2 WHERE id = ?");
    $deleteStmt->execute([$id]);

    $imageUrl = $current["image_url"] ?? "";
    if ($imageUrl !== "" && strpos($imageUrl, $baseUrl) === 0) {
        $localPath = $uploadDir . basename($imageUrl);
        if (file_exists($localPath)) {
            unlink($localPath);
        }
    }

    echo json_encode([
        "status" => "success",
        "message" => "Ad deleted successfully"
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (PDOException $e) {
    failResponse($e->getMessage(), 500);
}
?>
