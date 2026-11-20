<?php
include "../connect.php";

header("Content-Type: application/json; charset=utf-8");

try {
    $id = (int) ($_POST["id"] ?? 0);
    if ($id <= 0) {
        throw new Exception("Invalid ad ID");
    }

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

    // Get existing ad
    $existing_stmt = $con->prepare("SELECT image_url FROM ads WHERE id = :id");
    $existing_stmt->bindValue(":id", $id);
    $existing_stmt->execute();
    $existing = $existing_stmt->fetch(PDO::FETCH_ASSOC);

    if (!$existing) {
        throw new Exception("Ad not found");
    }

    $image_url = $existing["image_url"];

    // Handle image upload (optional)
    if (isset($_FILES["image"]) && $_FILES["image"]["error"] == UPLOAD_ERR_OK) {
        $upload_dir = __DIR__ . "/uploud/img/";
        
        if (!is_dir($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }

        $file_name = time() . "_" . basename($_FILES["image"]["name"]);
        $file_path = $upload_dir . $file_name;

        if (move_uploaded_file($_FILES["image"]["tmp_name"], $file_path)) {
            $new_image_url = "https://savir-technology.online/roaqv2/ads/uploud/img/" . $file_name;
            
            // Delete old image if it exists
            if (!empty($existing["image_url"])) {
                $old_file = str_replace("https://savir-technology.online/roaqv2/ads/uploud/img/", __DIR__ . "/uploud/img/", $existing["image_url"]);
                if (file_exists($old_file)) {
                    unlink($old_file);
                }
            }
            
            $image_url = $new_image_url;
        }
    }

    $stmt = $con->prepare("
        UPDATE `ads` SET
            title_ar = :title_ar,
            title_en = :title_en,
            image_url = :image_url,
            link_url = :link_url,
            target_type = :target_type,
            target_id = :target_id,
            placement = :placement,
            sort_order = :sort_order,
            display_seconds = :display_seconds,
            is_active = :is_active,
            open_in_webview = :open_in_webview
        WHERE id = :id
    ");

    $stmt->bindValue(":id", $id);
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
            "message" => "Ad updated successfully"
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to update ad"
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
