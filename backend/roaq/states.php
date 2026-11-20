<?php
include "connect.php";

try {
    $sql = "SELECT id, status FROM control_panel_status WHERE id = id";
    $stmt = $con->prepare($sql);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        $status = $result['status'];

        if ($status == 'active') {
            echo json_encode(array(
                "status" => "active",
                "message" => "✅ مرحبًا بك في لوحة التحكم."
            ));
        } else {
            echo json_encode(array(
                "status" => "inactive",
                "message" => "❌ من فضلك تواصل مع فريق الدعم علي الواتساب لسداد الاشتراك."
            ));
        }
    } else {
        echo json_encode(array(
            "status" => "error",
            "message" => "⚠️ لا توجد معلومات حول لوحة التحكم."
        ));
    }
} catch (PDOException $e) {
    echo json_encode(array(
        "status" => "error",
        "message" => "⚠️ حدث خطأ: ".$e->getMessage()
    ));
}
