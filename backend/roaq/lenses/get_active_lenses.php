<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $con->prepare("
        SELECT
            lens_id,
            lens_code,
            lens_name_ar,
            lens_name_en,
            lens_type,
            lens_color,
            lens_price,
            lens_features_ar,
            lens_features_en,
            priority_light,
            priority_medium,
            priority_high
        FROM lenses
        WHERE is_active = 1
        ORDER BY lens_id ASC
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(['status' => 'success', 'data' => $rows]);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
