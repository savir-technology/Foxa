<?php
include "connect.php";

header("Content-Type: application/json; charset=utf-8");

$approvalWhere = '';
if (function_exists('driverColumnExists') && driverColumnExists('delivery_users', 'approval_status')) {
    $approvalWhere = "AND approval_status = 'approved'";
}

$stmt = $con->prepare("
    SELECT
        id,
        name,
        phone,
        latitude,
        longitude,
        status,
        last_seen_at
    FROM delivery_users
    WHERE (status = 'online'
       OR (last_seen_at IS NOT NULL AND last_seen_at >= (NOW() - INTERVAL 5 MINUTE)))
      {$approvalWhere}
    ORDER BY last_seen_at DESC, name ASC
");
$stmt->execute();
$drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($drivers) {
    echo json_encode(["status" => "success", "drivers" => $drivers], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode(["status" => "failed", "message" => "لا يوجد ديلفري متاح"], JSON_UNESCAPED_UNICODE);
}
?>
