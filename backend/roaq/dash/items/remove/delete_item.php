<?php
include "../../../connect.php";
$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';

$id = filterRequest("id");

try {
    $itemSql = "
        SELECT items_id, vendor_id
        FROM items
        WHERE items_id = :item_id
    ";
    $itemParams = [
        ':item_id' => $id,
    ];
    if ($isVendor) {
        $itemSql .= " AND vendor_id = :vendor_id";
        $itemParams[':vendor_id'] = (int)$actor['vendor']['vendor_id'];
    }
    $itemSql .= " LIMIT 1";

    $itemStmt = $con->prepare($itemSql);
    $itemStmt->execute($itemParams);

    if (!$itemStmt->fetch(PDO::FETCH_ASSOC)) {
        respondJson([
            "status" => "error",
            "message" => "Item not found"
        ], 404);
    }

    $usageStmt = $con->prepare("
        SELECT COUNT(*)
        FROM order_items
        WHERE item_id = :item_id
    ");
    $usageStmt->execute([':item_id' => $id]);

    if ((int)$usageStmt->fetchColumn() > 0) {
        respondJson([
            "status" => "error",
            "message" => "This item is linked to existing orders and cannot be deleted"
        ], 409);
    }

    $con->beginTransaction();

    $cleanupStatements = [
        "DELETE FROM cart WHERE cart_itemsid = :item_id AND cart_orders = 0",
        "DELETE FROM favorite WHERE favorite_itemsid = :item_id",
        "DELETE FROM ratings WHERE item_id = :item_id",
        "DELETE FROM videos WHERE video_product_id = :item_id",
        "DELETE FROM item_ar_filters WHERE item_id = :item_id",
        "DELETE FROM item_variants WHERE item_id = :item_id",
        "DELETE FROM items_images WHERE item_id = :item_id",
    ];

    foreach ($cleanupStatements as $sql) {
        $stmt = $con->prepare($sql);
        $stmt->execute([':item_id' => $id]);
    }

    $deleteModifiersStmt = $con->prepare("
        DELETE FROM food_item_modifiers
        WHERE group_id IN (
            SELECT group_id
            FROM food_item_modifier_groups
            WHERE item_id = :item_id
        )
    ");
    $deleteModifiersStmt->execute([':item_id' => $id]);

    $deleteGroupsStmt = $con->prepare("
        DELETE FROM food_item_modifier_groups
        WHERE item_id = :item_id
    ");
    $deleteGroupsStmt->execute([':item_id' => $id]);

    $deleteSql = "
        DELETE FROM items
        WHERE items_id = :item_id
    ";
    $deleteParams = [':item_id' => $id];
    if ($isVendor) {
        $deleteSql .= " AND vendor_id = :vendor_id";
        $deleteParams[':vendor_id'] = (int)$actor['vendor']['vendor_id'];
    }
    $stmt = $con->prepare($deleteSql);
    $stmt->execute($deleteParams);

    $con->commit();

    echo json_encode([
        "status" => "success",
        "message" => "Item deleted successfully"
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
