<?php
include "../../../connect.php";
header('Content-Type: application/json; charset=utf-8');

try {
    $raw = file_get_contents("php://input");
    $data = json_decode($raw);
    if (!$data) {
        $data = (object) $_POST;
    }

    $lensId = isset($data->lens_id) ? (int) $data->lens_id : 0;

    if ($lensId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'Missing lens_id']);
        exit;
    }

    $stmt = $con->prepare("DELETE FROM lenses WHERE lens_id = :lens_id");
    $stmt->execute([':lens_id' => $lensId]);

    echo json_encode(['status' => 'success']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
