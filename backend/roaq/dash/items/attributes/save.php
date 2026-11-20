<?php
include "../../../connect.php";
ensureAleppoFoodOrderingSchema();
header("Content-Type: application/json; charset=utf-8");

try {
    $actor = requireDashboardActor(['vendor', 'master']);
    if (($actor['role'] ?? '') === 'master') {
        requireMasterPermission($actor['master'] ?? [], 'restaurants.edit');
    }
    $payload = json_decode(file_get_contents('php://input'), true) ?: [];
    $itemId = (int)($payload['item_id'] ?? 0);
    $attributes = is_array($payload['attributes'] ?? null) ? $payload['attributes'] : [];
    if ($itemId <= 0) {
        throw new RuntimeException('Missing item_id');
    }
    $itemStmt = $con->prepare("SELECT i.vendor_id, COALESCE(v.vendor_type, 'restaurant') AS vendor_type
        FROM items i LEFT JOIN vendors v ON v.vendor_id = i.vendor_id
        WHERE i.items_id = :item_id LIMIT 1");
    $itemStmt->execute([':item_id' => $itemId]);
    $item = $itemStmt->fetch(PDO::FETCH_ASSOC);
    if (!$item || ($actor['role'] === 'vendor' && (int)$item['vendor_id'] !== (int)$actor['vendor']['vendor_id'])) {
        http_response_code(404);
        throw new RuntimeException('Item not found');
    }
    if (strtolower((string)($item['vendor_type'] ?? 'restaurant')) !== 'store' && !empty($attributes)) {
        throw new RuntimeException('Restaurant products must use food modifiers, not generic product attributes');
    }

    $con->beginTransaction();
    $con->prepare('DELETE FROM item_attributes WHERE item_id = :item_id')->execute([':item_id' => $itemId]);
    $attributeStmt = $con->prepare('INSERT INTO item_attributes (item_id, name_ar, name_en, sort_order, is_required) VALUES (:item_id, :name_ar, :name_en, :sort_order, :is_required)');
    $valueStmt = $con->prepare('INSERT INTO item_attribute_values (attribute_id, value_ar, value_en, sort_order) VALUES (:attribute_id, :value_ar, :value_en, :sort_order)');
    foreach ($attributes as $attributeIndex => $attribute) {
        $nameAr = trim((string)($attribute['name_ar'] ?? ''));
        $nameEn = trim((string)($attribute['name_en'] ?? ''));
        if ($nameAr === '' && $nameEn === '') continue;
        $attributeStmt->execute([
            ':item_id' => $itemId,
            ':name_ar' => $nameAr !== '' ? $nameAr : $nameEn,
            ':name_en' => $nameEn !== '' ? $nameEn : $nameAr,
            ':sort_order' => $attributeIndex,
            ':is_required' => !empty($attribute['is_required']) ? 1 : 0,
        ]);
        $attributeId = (int)$con->lastInsertId();
        foreach ((array)($attribute['values'] ?? []) as $valueIndex => $value) {
            $valueAr = trim((string)($value['value_ar'] ?? $value['name_ar'] ?? $value));
            $valueEn = trim((string)($value['value_en'] ?? $value['name_en'] ?? $value));
            if ($valueAr === '' && $valueEn === '') continue;
            $valueStmt->execute([
                ':attribute_id' => $attributeId,
                ':value_ar' => $valueAr !== '' ? $valueAr : $valueEn,
                ':value_en' => $valueEn !== '' ? $valueEn : $valueAr,
                ':sort_order' => $valueIndex,
            ]);
        }
    }

    // When the vendor creates generic variants from the dashboard, variants
    // are entered in the same order as attribute values. Link them here so a
    // perfume's 30/50/100ml rows (or grocery package rows) resolve correctly
    // in the customer app without requiring a second hidden mapping screen.
    $variantStmt = $con->prepare('SELECT variant_id FROM item_variants WHERE item_id = :item_id ORDER BY variant_id ASC');
    $variantStmt->execute([':item_id' => $itemId]);
    $variantIds = array_map('intval', $variantStmt->fetchAll(PDO::FETCH_COLUMN));
    $valueGroupsStmt = $con->prepare('SELECT a.attribute_id, v.value_id FROM item_attributes a INNER JOIN item_attribute_values v ON v.attribute_id = a.attribute_id WHERE a.item_id = :item_id AND a.is_active = 1 AND v.is_active = 1 ORDER BY a.sort_order, a.attribute_id, v.sort_order, v.value_id');
    $valueGroupsStmt->execute([':item_id' => $itemId]);
    $valueGroups = [];
    foreach ($valueGroupsStmt->fetchAll(PDO::FETCH_ASSOC) as $valueRow) {
        $valueGroups[(string)$valueRow['attribute_id']][] = (int)$valueRow['value_id'];
    }
    $combinations = [[]];
    foreach ($valueGroups as $values) {
        $next = [];
        foreach ($combinations as $combination) {
            foreach ($values as $valueId) {
                $next[] = array_merge($combination, [$valueId]);
            }
        }
        $combinations = $next;
    }
    if (count($variantIds) === count($combinations) && count($variantIds) > 0) {
        $linkStmt = $con->prepare('INSERT IGNORE INTO item_variant_values (variant_id, value_id) VALUES (:variant_id, :value_id)');
        foreach ($variantIds as $index => $variantId) {
            foreach ($combinations[$index] as $valueId) {
                $linkStmt->execute([':variant_id' => $variantId, ':value_id' => $valueId]);
            }
        }
    }
    $con->commit();
    echo json_encode(['status' => 'success', 'message' => 'Product attributes saved']);
} catch (Throwable $e) {
    if ($con->inTransaction()) $con->rollBack();
    http_response_code(http_response_code() >= 400 ? http_response_code() : 400);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
