<?php
include "../connect.php";

header("Content-Type: application/json; charset=utf-8");

try {
    $title_ar = trim($_POST["title_ar"] ?? "");
    $title_en = trim($_POST["title_en"] ?? "");
    $target_type = trim($_POST["target_type"] ?? "restaurant");
    $target_id = (int) ($_POST["target_id"] ?? 0);
    $sort_order = (int) ($_POST["sort_order"] ?? 0);
    $display_seconds = (int) ($_POST["display_seconds"] ?? 8);
    $is_active = (int) ($_POST["is_active"] ?? 1);
    $open_in_webview = (int) ($_POST["open_in_webview"] ?? 0);
    $placement = trim($_POST["placement"] ?? "home_middle");

    // Normalize placement to home_middle for ads table
    $placement = $placement !== "" ? $placement : "home_middle";

    // Build link_url from target_type and target_id
    $link_url = "";
    if ($target_id > 0 && in_array($target_type, ['restaurant', 'product'], true)) {
        $link_url = $target_type . ":" . $target_id;
    }

    // Handle image upload
    $image_url = "";
    if (isset($_FILES["image"]) && $_FILES["image"]["error"] == UPLOAD_ERR_OK) {
        $upload_dir = __DIR__ . "/uploud/img/";
        
        if (!is_dir($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }

        $file_name = time() . "_" . basename($_FILES["image"]["name"]);
        $file_path = $upload_dir . $file_name;

        if (move_uploaded_file($_FILES["image"]["tmp_name"], $file_path)) {
            $image_url = "https://savir-technology.online/roaqv2/ads/uploud/img/" . $file_name;
        }
    }

    if (empty($image_url)) {
        throw new Exception("Image upload failed");
    }

    $stmt = $con->prepare("
        INSERT INTO `ads` 
        (title_ar, title_en, image_url, link_url, target_type, target_id, placement, sort_order, display_seconds, is_active, open_in_webview)
        VALUES 
        (:title_ar, :title_en, :image_url, :link_url, :target_type, :target_id, :placement, :sort_order, :display_seconds, :is_active, :open_in_webview)
    ");

    $stmt->bindValue(":title_ar", $title_ar);
    $stmt->bindValue(":title_en", $title_en);
    $stmt->bindValue(":image_url", $image_url);
    $stmt->bindValue(":link_url", $link_url);
    $stmt->bindValue(":target_type", $target_type);
    $stmt->bindValue(":target_id", $target_id);
    $stmt->bindValue(":placement", $placement);
    $stmt->bindValue(":sort_order", $sort_order);
    $stmt->bindValue(":display_seconds", $display_seconds);
    $stmt->bindValue(":is_active", $is_active);
    $stmt->bindValue(":open_in_webview", $open_in_webview);

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Ad added successfully",
            "id" => $con->lastInsertId()
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to add ad"
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
