<?php
require_once "../../../connect.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterSaveEntityFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterSaveEntityPayload(): array
{
    $payload = getRequestPayload();
    return is_array($payload) ? $payload : [];
}

function masterSaveEntityImage(array $data, string $key, string $current, string $folder): string
{
    $value = trim((string)($data[$key] ?? ''));
    if (!str_starts_with($value, 'data:image/')) return $value !== '' ? $value : $current;
    if (!preg_match('/^data:image\/(png|jpe?g|webp|gif);base64,(.+)$/s', $value, $match)) return $current;
    $bytes = base64_decode($match[2], true);
    if ($bytes === false || strlen($bytes) > 8 * 1024 * 1024) return $current;
    $extension = strtolower($match[1]) === 'jpeg' ? 'jpg' : strtolower($match[1]);
    $name = 'master_' . bin2hex(random_bytes(8)) . '.' . $extension;
    $directory = __DIR__ . '/../../../uploud/' . $folder . '/';
    if (!is_dir($directory)) @mkdir($directory, 0755, true);
    return file_put_contents($directory . $name, $bytes) === false ? $current : $name;
}

function masterSaveEntityString(array $data, string $key, string $fallback = ''): string
{
    $value = trim((string)($data[$key] ?? $fallback));
    return $value;
}

function masterSaveEntityInt(array $data, string $key, int $fallback = 0): int
{
    return (int)($data[$key] ?? $fallback);
}

function masterSaveEntityFloat(array $data, string $key, float $fallback = 0): float
{
    return (float)($data[$key] ?? $fallback);
}

function masterSaveEntitySlug(string $value): string
{
    $slug = strtolower(trim(preg_replace('/[^a-zA-Z0-9\p{Arabic}]+/u', '-', $value), '-'));
    return $slug !== '' ? $slug : 'store-' . bin2hex(random_bytes(4));
}

function masterSaveEntityAudit(string $entity, string $mode, int $id, array $payload): void
{
    global $con;
    if (!tableExists('master_audit_logs')) {
        return;
    }
    try {
        $actorName = trim((string)($GLOBALS['masterAuthAdmin']['admin_name'] ?? 'Master'));
        $stmt = $con->prepare("
            INSERT INTO master_audit_logs (actor_name, action_text, entity_label, action_time_label, tint_hex, created_at)
            VALUES (:actor_name, :action_text, :entity_label, :action_time_label, :tint_hex, NOW())
        ");
        $stmt->execute([
            ':actor_name' => $actorName !== '' ? $actorName : 'Master',
            ':action_text' => "{$mode} {$entity}",
            ':entity_label' => "{$entity} #{$id}",
            ':action_time_label' => date('H:i'),
            ':tint_hex' => $mode === 'create' ? '#16A34A' : '#2563EB',
        ]);
    } catch (Throwable $e) {
        error_log('master save entity audit failed: ' . $e->getMessage());
    }
}

function masterSaveEntityEnsureTable(string $table): void
{
    if (!tableExists($table)) {
        masterSaveEntityFail("Table {$table} is not available", 404);
    }
}

function masterSaveEntityCurrentRow(string $table, string $idColumn, int $id): array
{
    global $con;
    if ($id <= 0) {
        return [];
    }
    $stmt = $con->prepare("SELECT * FROM `{$table}` WHERE `{$idColumn}` = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return is_array($row) ? $row : [];
}

function masterSaveEntityStringValue(array $data, string $key, array $row, string $column, string $fallback = ''): string
{
    if (array_key_exists($key, $data)) {
        return masterSaveEntityString($data, $key, $fallback);
    }
    return trim((string)($row[$column] ?? $fallback));
}

function masterSaveEntityIntValue(array $data, string $key, array $row, string $column, int $fallback = 0): int
{
    if (array_key_exists($key, $data)) {
        return masterSaveEntityInt($data, $key, $fallback);
    }
    return (int)($row[$column] ?? $fallback);
}

function masterSaveEntityFloatValue(array $data, string $key, array $row, string $column, float $fallback = 0): float
{
    if (array_key_exists($key, $data)) {
        return masterSaveEntityFloat($data, $key, $fallback);
    }
    return (float)($row[$column] ?? $fallback);
}

try {
    $admin = requireMasterAuth();
    requireMasterPermission($admin, 'restaurants.edit');
    $GLOBALS['masterAuthAdmin'] = $admin;

    $payload = masterSaveEntityPayload();
    $entity = strtolower(trim((string)($payload['entity'] ?? '')));
    $mode = strtolower(trim((string)($payload['mode'] ?? '')));
    $id = (int)($payload['id'] ?? 0);
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];

    if ($entity === '' || !in_array($mode, ['create', 'update'], true)) {
        masterSaveEntityFail('Invalid save payload');
    }
    if ($mode === 'update' && $id <= 0) {
        masterSaveEntityFail('Missing entity id for update');
    }

    $con->beginTransaction();
    $savedId = $id;

    switch ($entity) {
        case 'restaurant':
            masterSaveEntityEnsureTable('vendors');
            $current = $mode === 'update' ? masterSaveEntityCurrentRow('vendors', 'vendor_id', $id) : [];
            $storeName = masterSaveEntityStringValue($data, 'name', $current, 'store_name', masterSaveEntityString($data, 'store_name', 'New restaurant'));
            $vendorName = masterSaveEntityStringValue($data, 'owner', $current, 'vendor_name', masterSaveEntityString($data, 'vendor_name', $storeName));
            $email = masterSaveEntityStringValue($data, 'email', $current, 'vendor_email', 'vendor-' . time() . '@savir.local');
            $phone = masterSaveEntityStringValue($data, 'phone', $current, 'vendor_phone');
            $description = masterSaveEntityStringValue($data, 'description', $current, 'vendor_description', masterSaveEntityString($data, 'notes'));
            $slug = masterSaveEntityStringValue($data, 'slug', $current, 'store_slug', masterSaveEntitySlug($storeName));
            $status = masterSaveEntityStringValue($data, 'status', $current, 'vendor_status', 'active');
            $vendorType = strtolower(masterSaveEntityString($data, 'vendor_type', $current['vendor_type'] ?? 'restaurant')) === 'store' ? 'store' : 'restaurant';
            $storeCategory = masterSaveEntityString($data, 'store_category', $current['store_category'] ?? '');
            $allowedStoreCategories = ['fashion', 'shoes', 'perfume', 'grocery', 'fresh_food', 'canned_food', 'electronics', 'toys', 'general'];
            if ($vendorType === 'store' && !in_array($storeCategory, $allowedStoreCategories, true)) {
                throw new RuntimeException('يجب اختيار تخصص المتجر');
            }
            if ($vendorType === 'restaurant') {
                $storeCategory = '';
            }

            if ($mode === 'create') {
                $vendorColumns = 'vendor_name, store_name, store_slug, vendor_email, vendor_phone, vendor_password, vendor_description, vendor_status, vendor_is_verified';
                $vendorValues = ':vendor_name, :store_name, :store_slug, :vendor_email, :vendor_phone, :vendor_password, :vendor_description, :vendor_status, 1';
                if (columnExists('vendors', 'vendor_type')) { $vendorColumns .= ', vendor_type'; $vendorValues .= ', :vendor_type'; }
                if (columnExists('vendors', 'store_category')) { $vendorColumns .= ', store_category'; $vendorValues .= ', :store_category'; }
                $stmt = $con->prepare("INSERT INTO vendors ({$vendorColumns}) VALUES ({$vendorValues})");
                $stmt->execute([
                    ':vendor_name' => $vendorName,
                    ':store_name' => $storeName,
                    ':store_slug' => $slug,
                    ':vendor_email' => $email,
                    ':vendor_phone' => $phone,
                    ':vendor_password' => password_hash(bin2hex(random_bytes(8)), PASSWORD_DEFAULT),
                    ':vendor_description' => $description,
                    ':vendor_status' => $status,
                    ':vendor_type' => $vendorType,
                    ':store_category' => $storeCategory !== '' ? $storeCategory : null,
                ]);
                $savedId = (int)$con->lastInsertId();
            } else {
                $updates = 'vendor_name = :vendor_name, store_name = :store_name, store_slug = :store_slug, vendor_email = :vendor_email, vendor_phone = :vendor_phone, vendor_description = :vendor_description, vendor_status = :vendor_status';
                if (columnExists('vendors', 'vendor_type')) { $updates .= ', vendor_type = :vendor_type'; }
                if (columnExists('vendors', 'store_category')) { $updates .= ', store_category = :store_category'; }
                $stmt = $con->prepare("UPDATE vendors SET {$updates} WHERE vendor_id = :id");
                $stmt->execute([
                    ':vendor_name' => $vendorName,
                    ':store_name' => $storeName,
                    ':store_slug' => $slug,
                    ':vendor_email' => $email,
                    ':vendor_phone' => $phone,
                    ':vendor_description' => $description,
                    ':vendor_status' => $status,
                    ':vendor_type' => $vendorType,
                    ':store_category' => $storeCategory !== '' ? $storeCategory : null,
                    ':id' => $id,
                ]);
            }

            if (tableExists('vendor_store_settings')) {
                $address = masterSaveEntityString($data, 'address');
                $lat = masterSaveEntityFloat($data, 'latitude', 0);
                $lng = masterSaveEntityFloat($data, 'longitude', 0);
                $settingsStmt = $con->prepare("
                    INSERT INTO vendor_store_settings (
                        vendor_id, store_name, store_slug, vendor_name, vendor_email,
                        vendor_phone, vendor_description, store_address, store_latitude, store_longitude
                    ) VALUES (
                        :vendor_id, :store_name, :store_slug, :vendor_name, :vendor_email,
                        :vendor_phone, :vendor_description, :store_address, :store_latitude, :store_longitude
                    )
                    ON DUPLICATE KEY UPDATE
                        store_name = VALUES(store_name),
                        store_slug = VALUES(store_slug),
                        vendor_name = VALUES(vendor_name),
                        vendor_email = VALUES(vendor_email),
                        vendor_phone = VALUES(vendor_phone),
                        vendor_description = VALUES(vendor_description),
                        store_address = VALUES(store_address),
                        store_latitude = VALUES(store_latitude),
                        store_longitude = VALUES(store_longitude)
                ");
                $settingsStmt->execute([
                    ':vendor_id' => $savedId,
                    ':store_name' => $storeName,
                    ':store_slug' => $slug,
                    ':vendor_name' => $vendorName,
                    ':vendor_email' => $email,
                    ':vendor_phone' => $phone,
                    ':vendor_description' => $description,
                    ':store_address' => $address,
                    ':store_latitude' => $lat,
                    ':store_longitude' => $lng,
                ]);
            }
            break;

        case 'category':
            masterSaveEntityEnsureTable('categories');
            $current = $mode === 'update' ? masterSaveEntityCurrentRow('categories', 'categories_id', $id) : [];
            $name = masterSaveEntityStringValue($data, 'name', $current, 'categories_name_ar', 'New category');
            $nameEn = masterSaveEntityStringValue($data, 'name_en', $current, 'categories_name_en', $name);
            $image = masterSaveEntityImage($data, 'image', masterSaveEntityStringValue($data, 'image', $current, 'categories_image', 'placeholder.png'), 'categories');
            $vendorId = masterSaveEntityIntValue($data, 'vendor_id', $current, 'vendor_id', 0);
            $categoryType = strtolower(masterSaveEntityString($data, 'category_type', $current['category_type'] ?? 'restaurant')) === 'store' ? 'store' : 'restaurant';
            if ($vendorId > 0 && tableExists('vendors') && columnExists('vendors', 'vendor_type')) {
                $typeStmt = $con->prepare('SELECT vendor_type FROM vendors WHERE vendor_id = :vendor_id LIMIT 1');
                $typeStmt->execute([':vendor_id' => $vendorId]);
                $ownerType = strtolower((string)$typeStmt->fetchColumn());
                if ($ownerType === 'store') { $categoryType = 'store'; }
            }
            $categoryColumns = 'categories_name_en, categories_name_ar, categories_image, vendor_id';
            $categoryValues = ':name_en, :name_ar, :image, :vendor_id';
            if (columnExists('categories', 'category_type')) { $categoryColumns .= ', category_type'; $categoryValues .= ', :category_type'; }
            if ($mode === 'create') {
                $stmt = $con->prepare("INSERT INTO categories ({$categoryColumns}) VALUES ({$categoryValues})");
                $stmt->execute([
                    ':name_en' => $nameEn,
                    ':name_ar' => $name,
                    ':image' => $image,
                    ':vendor_id' => $vendorId,
                    ':category_type' => $categoryType,
                ]);
                $savedId = (int)$con->lastInsertId();
            } else {
                $categoryUpdates = 'categories_name_en = :name_en, categories_name_ar = :name_ar, categories_image = :image, vendor_id = :vendor_id';
                if (columnExists('categories', 'category_type')) { $categoryUpdates .= ', category_type = :category_type'; }
                $stmt = $con->prepare("UPDATE categories SET {$categoryUpdates} WHERE categories_id = :id");
                $stmt->execute([
                    ':name_en' => $nameEn,
                    ':name_ar' => $name,
                    ':image' => $image,
                    ':vendor_id' => $vendorId,
                    ':category_type' => $categoryType,
                    ':id' => $id,
                ]);
            }
            break;

        case 'product':
            masterSaveEntityEnsureTable('items');
            $current = $mode === 'update' ? masterSaveEntityCurrentRow('items', 'items_id', $id) : [];
            $name = masterSaveEntityStringValue($data, 'name', $current, 'items_name_ar', 'New product');
            $nameEn = masterSaveEntityStringValue($data, 'name_en', $current, 'items_name_en', $name);
            $description = masterSaveEntityStringValue($data, 'description', $current, 'items_desc_ar', masterSaveEntityString($data, 'notes'));
            $descEn = masterSaveEntityStringValue($data, 'description_en', $current, 'items_desc_en', $description);
            $image = masterSaveEntityImage($data, 'image', masterSaveEntityStringValue($data, 'image', $current, 'items_image', 'placeholder.png'), 'items');
            $price = masterSaveEntityFloatValue($data, 'price', $current, 'items_price', 0);
            $discount = masterSaveEntityIntValue($data, 'discount', $current, 'items_discount', 0);
            $count = masterSaveEntityIntValue($data, 'count', $current, 'items_count', 0);
            $active = masterSaveEntityIntValue($data, 'active', $current, 'items_active', 1) === 1 ? 1 : 0;
            $categoryId = masterSaveEntityIntValue($data, 'category_id', $current, 'items_cat', masterSaveEntityInt($data, 'items_cat', 0));
            $vendorId = masterSaveEntityIntValue($data, 'vendor_id', $current, 'vendor_id', 0);
            $productType = masterSaveEntityString($data, 'product_type', $current['product_type'] ?? 'food');
            $stockUnit = masterSaveEntityString($data, 'stock_unit', $current['stock_unit'] ?? 'piece');
            $stockStep = masterSaveEntityFloat($data, 'stock_step', (float)($current['stock_step'] ?? 1));
            if ($vendorId > 0 && tableExists('vendors') && columnExists('vendors', 'vendor_type')) {
                $vendorStmt = $con->prepare('SELECT vendor_type, store_category FROM vendors WHERE vendor_id = :vendor_id LIMIT 1');
                $vendorStmt->execute([':vendor_id' => $vendorId]);
                $vendorRow = $vendorStmt->fetch(PDO::FETCH_ASSOC) ?: [];
                if (strtolower((string)($vendorRow['vendor_type'] ?? 'restaurant')) === 'store') {
                    $productType = trim((string)($vendorRow['store_category'] ?? '')) ?: 'general';
                } else {
                    $productType = 'food';
                }
            }
            if ($categoryId <= 0 && tableExists('categories')) {
                $categoryId = (int)$con->query("SELECT categories_id FROM categories ORDER BY categories_id DESC LIMIT 1")->fetchColumn();
            }
            if ($vendorId <= 0 && tableExists('vendors')) {
                $vendorId = (int)$con->query("SELECT vendor_id FROM vendors ORDER BY vendor_id ASC LIMIT 1")->fetchColumn();
            }
            if ($mode === 'create') {
                $itemColumns = 'items_name_en, items_name_ar, items_desc_en, items_desc_ar, items_image, items_count, items_active, items_price, items_discount, items_cat, vendor_id';
                $itemValues = ':name_en, :name_ar, :desc_en, :desc_ar, :image, :count, :active, :price, :discount, :category_id, :vendor_id';
                if (columnExists('items', 'product_type')) { $itemColumns .= ', product_type'; $itemValues .= ', :product_type'; }
                if (columnExists('items', 'stock_unit')) { $itemColumns .= ', stock_unit'; $itemValues .= ', :stock_unit'; }
                if (columnExists('items', 'stock_step')) { $itemColumns .= ', stock_step'; $itemValues .= ', :stock_step'; }
                $stmt = $con->prepare("INSERT INTO items ({$itemColumns}) VALUES ({$itemValues})");
                $stmt->execute([
                    ':name_en' => $nameEn,
                    ':name_ar' => $name,
                    ':desc_en' => $descEn,
                    ':desc_ar' => $description,
                    ':image' => $image,
                    ':count' => $count,
                    ':active' => $active,
                    ':price' => $price,
                    ':discount' => $discount,
                    ':category_id' => $categoryId,
                    ':vendor_id' => $vendorId,
                    ':product_type' => $productType,
                    ':stock_unit' => $stockUnit,
                    ':stock_step' => $stockStep,
                ]);
                $savedId = (int)$con->lastInsertId();
            } else {
                $itemUpdates = 'items_name_en = :name_en, items_name_ar = :name_ar, items_desc_en = :desc_en, items_desc_ar = :desc_ar, items_image = :image, items_count = :count, items_active = :active, items_price = :price, items_discount = :discount, items_cat = :category_id, vendor_id = :vendor_id';
                if (columnExists('items', 'product_type')) { $itemUpdates .= ', product_type = :product_type'; }
                if (columnExists('items', 'stock_unit')) { $itemUpdates .= ', stock_unit = :stock_unit'; }
                if (columnExists('items', 'stock_step')) { $itemUpdates .= ', stock_step = :stock_step'; }
                $stmt = $con->prepare("UPDATE items SET {$itemUpdates} WHERE items_id = :id");
                $stmt->execute([
                    ':name_en' => $nameEn,
                    ':name_ar' => $name,
                    ':desc_en' => $descEn,
                    ':desc_ar' => $description,
                    ':image' => $image,
                    ':count' => $count,
                    ':active' => $active,
                    ':price' => $price,
                    ':discount' => $discount,
                    ':category_id' => $categoryId,
                    ':vendor_id' => $vendorId,
                    ':product_type' => $productType,
                    ':stock_unit' => $stockUnit,
                    ':stock_step' => $stockStep,
                    ':id' => $id,
                ]);
            }
            break;

        case 'topping':
            masterSaveEntityEnsureTable('food_item_modifiers');
            $current = $mode === 'update' ? masterSaveEntityCurrentRow('food_item_modifiers', 'modifier_id', $id) : [];
            $name = masterSaveEntityStringValue($data, 'name', $current, 'name_ar', 'New option');
            $nameEn = masterSaveEntityStringValue($data, 'name_en', $current, 'name_en', $name);
            $price = masterSaveEntityFloatValue($data, 'price', $current, 'price_delta', 0);
            $image = masterSaveEntityStringValue($data, 'image', $current, 'image_url');
            $active = masterSaveEntityIntValue($data, 'active', $current, 'is_active', 1) === 1 ? 1 : 0;
            $groupId = masterSaveEntityIntValue($data, 'group_id', $current, 'group_id', 0);
            if ($groupId <= 0 && tableExists('food_item_modifier_groups')) {
                $groupId = (int)$con->query("SELECT group_id FROM food_item_modifier_groups ORDER BY group_id ASC LIMIT 1")->fetchColumn();
            }
            if ($groupId <= 0) {
                masterSaveEntityFail('No modifier group is available for topping save', 409);
            }
            $groupCurrent = tableExists('food_item_modifier_groups')
                ? masterSaveEntityCurrentRow('food_item_modifier_groups', 'group_id', $groupId)
                : [];
            $minSelect = masterSaveEntityIntValue($data, 'min_choice', $groupCurrent, 'min_select', 0);
            $maxSelect = masterSaveEntityIntValue($data, 'max_choice', $groupCurrent, 'max_select', 1);
            $isRequired = masterSaveEntityIntValue($data, 'is_required', $groupCurrent, 'is_required', 0) === 1 ? 1 : 0;
            $groupType = masterSaveEntityStringValue($data, 'group_type', $groupCurrent, 'group_type', 'modifier');
            $groupType = $groupType === 'ingredient' ? 'ingredient' : 'modifier';
            if ($mode === 'create') {
                $stmt = $con->prepare("
                    INSERT INTO food_item_modifiers (group_id, name_ar, name_en, image_url, price_delta, is_active)
                    VALUES (:group_id, :name_ar, :name_en, :image, :price_delta, :active)
                ");
                $stmt->execute([
                    ':group_id' => $groupId,
                    ':name_ar' => $name,
                    ':name_en' => $nameEn,
                    ':image' => $image,
                    ':price_delta' => $price,
                    ':active' => $active,
                ]);
                $savedId = (int)$con->lastInsertId();
            } else {
                $stmt = $con->prepare("
                    UPDATE food_item_modifiers
                    SET group_id = :group_id,
                        name_ar = :name_ar,
                        name_en = :name_en,
                        image_url = :image,
                        is_active = :active,
                        price_delta = :price_delta
                    WHERE modifier_id = :id
                ");
                $stmt->execute([
                    ':group_id' => $groupId,
                    ':name_ar' => $name,
                    ':name_en' => $nameEn,
                    ':image' => $image,
                    ':price_delta' => $price,
                    ':active' => $active,
                    ':id' => $id,
                ]);
            }
            if (tableExists('food_item_modifier_groups')) {
                $groupStmt = $con->prepare("UPDATE food_item_modifier_groups SET group_type = :group_type, min_select = :min_select, max_select = :max_select, is_required = :is_required WHERE group_id = :group_id");
                $groupStmt->execute([
                    ':group_type' => $groupType,
                    ':min_select' => $minSelect,
                    ':max_select' => max($minSelect, $maxSelect),
                    ':is_required' => $isRequired,
                    ':group_id' => $groupId,
                ]);
            }
            break;

        case 'offer':
            if (tableExists('restaurant_banners')) {
                $current = $mode === 'update' ? masterSaveEntityCurrentRow('restaurant_banners', 'banner_id', $id) : [];
                $name = masterSaveEntityStringValue($data, 'name', $current, 'title_ar', 'New offer');
                $subtitle = masterSaveEntityStringValue($data, 'description', $current, 'subtitle_ar', masterSaveEntityString($data, 'notes'));
                $image = masterSaveEntityStringValue($data, 'image', $current, 'image_url');
                $sort = masterSaveEntityIntValue($data, 'sort_order', $current, 'sort_order', 0);
                if ($mode === 'create') {
                    $stmt = $con->prepare("
                        INSERT INTO restaurant_banners (title_ar, title_en, subtitle_ar, subtitle_en, image_url, is_active, sort_order)
                        VALUES (:title_ar, :title_en, :subtitle_ar, :subtitle_en, :image_url, 1, :sort_order)
                    ");
                    $stmt->execute([
                        ':title_ar' => $name,
                        ':title_en' => $name,
                        ':subtitle_ar' => $subtitle,
                        ':subtitle_en' => $subtitle,
                        ':image_url' => $image,
                        ':sort_order' => $sort,
                    ]);
                    $savedId = (int)$con->lastInsertId();
                } else {
                    $stmt = $con->prepare("
                        UPDATE restaurant_banners
                        SET title_ar = :title_ar,
                            title_en = :title_en,
                            subtitle_ar = :subtitle_ar,
                            subtitle_en = :subtitle_en,
                            image_url = :image_url,
                            sort_order = :sort_order
                        WHERE banner_id = :id
                    ");
                    $stmt->execute([
                        ':title_ar' => $name,
                        ':title_en' => $name,
                        ':subtitle_ar' => $subtitle,
                        ':subtitle_en' => $subtitle,
                        ':image_url' => $image,
                        ':sort_order' => $sort,
                        ':id' => $id,
                    ]);
                }
            } else {
                masterSaveEntityFail('Offers table is not available', 404);
            }
            break;

        case 'coupon':
            masterSaveEntityEnsureTable('coupon');
            $current = $mode === 'update' ? masterSaveEntityCurrentRow('coupon', 'coupon_id', $id) : [];
            $code = masterSaveEntityStringValue($data, 'name', $current, 'coupon_name', masterSaveEntityString($data, 'code', 'NEWCOUPON'));
            $discount = masterSaveEntityIntValue($data, 'discount', $current, 'coupon_discount', 10);
            $count = masterSaveEntityIntValue($data, 'count', $current, 'coupon_count', 100);
            $expire = masterSaveEntityStringValue($data, 'expire_date', $current, 'coupon_expiredate', date('Y-m-d H:i:s', strtotime('+30 days')));
            if ($mode === 'create') {
                $stmt = $con->prepare("
                    INSERT INTO coupon (coupon_name, coupon_count, coupon_expiredate, coupon_discount)
                    VALUES (:name, :count, :expire, :discount)
                ");
                $stmt->execute([
                    ':name' => $code,
                    ':count' => $count,
                    ':expire' => $expire,
                    ':discount' => $discount,
                ]);
                $savedId = (int)$con->lastInsertId();
            } else {
                $stmt = $con->prepare("
                    UPDATE coupon
                    SET coupon_name = :name,
                        coupon_count = :count,
                        coupon_expiredate = :expire,
                        coupon_discount = :discount
                    WHERE coupon_id = :id
                ");
                $stmt->execute([
                    ':name' => $code,
                    ':count' => $count,
                    ':expire' => $expire,
                    ':discount' => $discount,
                    ':id' => $id,
                ]);
            }
            break;

        default:
            masterSaveEntityFail('Unsupported entity');
    }

    masterSaveEntityAudit($entity, $mode, $savedId, $data);
    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Entity saved successfully',
        'data' => [
            'entity' => $entity,
            'mode' => $mode,
            'id' => $savedId,
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    masterSaveEntityFail($e->getMessage(), 500);
}
