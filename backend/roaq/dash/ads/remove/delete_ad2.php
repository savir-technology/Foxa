<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../../connect.php';

try {
    $adId = intval($_POST['ad_id'] ?? 0);
    if ($adId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'ad_id is required']);
        exit;
    }

    $sel = $con->prepare("SELECT image_url FROM ads2 WHERE id = :id LIMIT 1");
    $sel->execute([':id' => $adId]);
    $row = $sel->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        echo json_encode(['status' => 'error', 'message' => 'Ad not found']);
        exit;
    }

    $del = $con->prepare("DELETE FROM ads2 WHERE id = :id");
    $del->execute([':id' => $adId]);

    $url = trim((string)($row['image_url'] ?? ''));
    if ($url !== '') {
      $pathPart = parse_url($url, PHP_URL_PATH);
      if (is_string($pathPart)) {
          $fileName = basename($pathPart);
          $local = __DIR__ . '/../../../ads/uploud/img/' . $fileName;
          if (is_file($local)) {
              @unlink($local);
          }
      }
    }

    echo json_encode(['status' => 'success'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
?>
