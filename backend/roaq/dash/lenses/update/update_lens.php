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
    $lensCode = isset($data->lens_code) ? trim((string) $data->lens_code) : '';
    $lensNameAr = isset($data->lens_name_ar) ? trim((string) $data->lens_name_ar) : '';
    $lensNameEn = isset($data->lens_name_en) ? trim((string) $data->lens_name_en) : '';
    $lensType = isset($data->lens_type) ? trim((string) $data->lens_type) : '';
    $lensColor = isset($data->lens_color) ? trim((string) $data->lens_color) : '';
    $lensPrice = isset($data->lens_price) ? (float) $data->lens_price : null;
    $featuresAr = isset($data->lens_features_ar) ? trim((string) $data->lens_features_ar) : null;
    $featuresEn = isset($data->lens_features_en) ? trim((string) $data->lens_features_en) : null;
    $priorityLight = isset($data->priority_light) ? (int) $data->priority_light : 99;
    $priorityMedium = isset($data->priority_medium) ? (int) $data->priority_medium : 99;
    $priorityHigh = isset($data->priority_high) ? (int) $data->priority_high : 99;
    $isActive = isset($data->is_active) ? (int) $data->is_active : 1;

    if ($lensId <= 0 || $lensCode === '' || $lensNameAr === '' || $lensPrice === null) {
        echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
        exit;
    }

    $stmt = $con->prepare("
        UPDATE lenses
        SET lens_code = :lens_code,
            lens_name_ar = :lens_name_ar,
            lens_name_en = :lens_name_en,
            lens_type = :lens_type,
            lens_color = :lens_color,
            lens_price = :lens_price,
            lens_features_ar = :lens_features_ar,
            lens_features_en = :lens_features_en,
            priority_light = :priority_light,
            priority_medium = :priority_medium,
            priority_high = :priority_high,
            is_active = :is_active
        WHERE lens_id = :lens_id
    ");
    $stmt->execute([
        ':lens_id' => $lensId,
        ':lens_code' => $lensCode,
        ':lens_name_ar' => $lensNameAr,
        ':lens_name_en' => $lensNameEn !== '' ? $lensNameEn : null,
        ':lens_type' => $lensType !== '' ? $lensType : null,
        ':lens_color' => $lensColor !== '' ? $lensColor : null,
        ':lens_price' => $lensPrice,
        ':lens_features_ar' => $featuresAr !== '' ? $featuresAr : null,
        ':lens_features_en' => $featuresEn !== '' ? $featuresEn : null,
        ':priority_light' => $priorityLight,
        ':priority_medium' => $priorityMedium,
        ':priority_high' => $priorityHigh,
        ':is_active' => $isActive,
    ]);

    echo json_encode(['status' => 'success']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
