<?php
include "../../../connect.php";
include "../story_helpers.php";

header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    storyFailResponse("Invalid request method", 405);
}

$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$id = (int) ($_POST['id'] ?? 0);

if ($id <= 0) {
    storyFailResponse("Invalid story id");
}

$sql = "SELECT story_id, vendor_id, image_url, video_url FROM restaurant_stories WHERE story_id = ?";
$params = [$id];
if ($isVendor) {
    $sql .= " AND vendor_id = ?";
    $params[] = (int)($actor['vendor']['vendor_id'] ?? 0);
}

$stmt = $con->prepare($sql);
$stmt->execute($params);
$current = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$current) {
    storyFailResponse("Story not found", 404);
}

try {
    $deleteStmt = $con->prepare("DELETE FROM restaurant_stories WHERE story_id = ?");
    $deleteStmt->execute([$id]);

    storyDeleteLocalMedia($current['image_url'] ?? '');
    storyDeleteLocalMedia($current['video_url'] ?? '');

    echo json_encode([
        "status" => "success",
        "message" => "Story deleted successfully"
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    storyFailResponse($e->getMessage(), 500);
}
