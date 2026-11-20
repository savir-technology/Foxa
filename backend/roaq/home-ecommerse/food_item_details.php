<?php
include "../connect.php";
header('Content-Type: application/json; charset=utf-8');
$payload = getRequestPayload();
$itemId = isset($payload['item_id']) ? (int)$payload['item_id'] : 0;
if ($itemId <= 0) {
    respondJson([
        'status' => 'failure',
        'message' => 'Item id is required',
    ], 422);
}
function foodAssetUrl($path, $fallbackFolder = 'uploud/items')
{
    $value = trim((string)$path);
    if ($value === '') {
        return '';
    }
    if (strpos($value, 'http://') === 0 || strpos($value, 'https://') === 0) {
        return $value;
    }
    $value = ltrim($value, '/');
    if (strpos($value, 'uploads/') === 0 || strpos($value, 'uploud/') === 0) {
        return 'https://savir-technology.online/roaqv2/' . $value;
    }
    return 'https://savir-technology.online/roaqv2/' . $fallbackFolder . '/' . $value;
}
function modifierAssetUrl($path, $fallbackFolder = 'uploads/item_modifiers')
{
    $value = trim((string)$path);
    if ($value === '') {
        return '';
    }
    if (strpos($value, 'http://') === 0 || strpos($value, 'https://') === 0) {
        return $value;
    }
    $value = ltrim($value, '/');
    if (strpos($value, 'uploads/') === 0 || strpos($value, 'uploud/') === 0) {
        return 'https://savir-technology.online/roaqv2/' . $value;
    }
    return 'https://savir-technology.online/roaqv2/' . $fallbackFolder . '/' . $value;
}
function normalizeTagList($categoryNameAr, $categoryNameEn, $groups, $discount, $isAvailable)
{
    $tags = [];
    $categoryLabelAr = trim((string)$categoryNameAr);
    $categoryLabelEn = trim((string)$categoryNameEn);
    if ($categoryLabelAr !== '' || $categoryLabelEn !== '') {
        $tags[] = [
            'label_ar' => $categoryLabelAr !== '' ? $categoryLabelAr : $categoryLabelEn,
            'label_en' => $categoryLabelEn !== '' ? $categoryLabelEn : $categoryLabelAr,
            'icon' => 'category',
        ];
    }
    $firstGroup = null;
    foreach ($groups as $group) {
        $nameAr = trim((string)($group['name_ar'] ?? ''));
        $nameEn = trim((string)($group['name_en'] ?? ''));
        if ($nameAr !== '' || $nameEn !== '') {
            $firstGroup = [
                'label_ar' => $nameAr !== '' ? $nameAr : $nameEn,
                'label_en' => $nameEn !== '' ? $nameEn : $nameAr,
                'icon' => strtolower((string)($group['group_type'] ?? 'modifier')) === 'ingredient'
                    ? 'ingredient'
                    : 'toppings',
            ];
            break;
        }
    }
    if ($firstGroup !== null) {
        $tags[] = $firstGroup;
    }
    if (count($tags) < 2) {
        if ($discount > 0) {
            $tags[] = [
                'label_ar' => 'خصم ' . round($discount) . '%',
                'label_en' => 'Discount ' . round($discount) . '%',
                'icon' => 'discount',
            ];
        } else {
            $tags[] = [
                'label_ar' => $isAvailable ? 'متوفر الآن' : 'غير متوفر',
                'label_en' => $isAvailable ? 'Available now' : 'Unavailable',
                'icon' => $isAvailable ? 'available' : 'unavailable',
            ];
        }
    }
    return array_slice($tags, 0, 2);
}
try {
    $stmt = $con->prepare("
        SELECT
            i.items_id,
            i.vendor_id,
            i.items_cat,
            i.items_name_ar,
            i.items_name_en,
            i.items_desc_ar,
            i.items_desc_en,
            i.items_image,
            i.items_price,
            i.items_discount,
            i.items_count,
            COALESCE(c.categories_name_ar, '') AS categories_name_ar,
            COALESCE(c.categories_name_en, '') AS categories_name_en,
            COALESCE(rating_stats.average_rating, 0) AS average_rating,
            COALESCE(rating_stats.total_reviews, 0) AS total_reviews
        FROM items i
        JOIN vendors v ON v.vendor_id = i.vendor_id
        LEFT JOIN categories c ON c.categories_id = i.items_cat
        LEFT JOIN (
            SELECT
                item_id,
                ROUND(AVG(rating), 1) AS average_rating,
                COUNT(*) AS total_reviews
            FROM ratings
            GROUP BY item_id
        ) rating_stats ON rating_stats.item_id = i.items_id
        WHERE i.items_id = :item_id
          AND i.items_active = 1
          AND v.vendor_status = 'active'
          AND v.vendor_is_verified = 1
        LIMIT 1
    ");
    $stmt->execute([':item_id' => $itemId]);
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$item) {
        respondJson(['status' => 'failure', 'message' => 'Item not found'], 404);
    }
    $originalPrice = (float)($item['items_price'] ?? 0);
    $discount = (float)($item['items_discount'] ?? 0);
    $finalPrice = $originalPrice - ($originalPrice * ($discount / 100));
    $isAvailable = (int)($item['items_count'] ?? 0) > 0;
    $imagesStmt = $con->prepare("
        SELECT img_path
        FROM items_images
        WHERE item_id = :item_id
        ORDER BY img_order ASC, img_id ASC
    ");
    $imagesStmt->execute([':item_id' => $itemId]);
    $galleryImages = [];
    foreach ($imagesStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $url = foodAssetUrl($row['img_path']);
        if ($url !== '' && !in_array($url, $galleryImages, true)) {
            $galleryImages[] = $url;
        }
    }
    $groupStmt = $con->prepare("
        SELECT group_id, name_ar, name_en, group_type, min_select, max_select, is_required
        FROM food_item_modifier_groups
        WHERE item_id = :item_id
          AND is_active = 1
        ORDER BY sort_order ASC, group_id ASC
    ");
    $groupStmt->execute([':item_id' => $itemId]);
    $groupsRows = $groupStmt->fetchAll(PDO::FETCH_ASSOC);
    $groups = [];
    foreach ($groupsRows as $groupRow) {
        $optionsStmt = $con->prepare("
            SELECT modifier_id, name_ar, name_en, image_url, price_delta, is_default_selected, is_removable
            FROM food_item_modifiers
            WHERE group_id = :group_id
              AND is_active = 1
            ORDER BY sort_order ASC, modifier_id ASC
        ");
        $optionsStmt->execute([':group_id' => $groupRow['group_id']]);
        $options = array_map(function ($optionRow) {
            return [
                'id' => (string)$optionRow['modifier_id'],
                'name_ar' => trim((string)($optionRow['name_ar'] ?? '')),
                'name_en' => trim((string)($optionRow['name_en'] ?? '')),
                'image_url' => modifierAssetUrl($optionRow['image_url']),
                'price_delta' => round((float)($optionRow['price_delta'] ?? 0), 2),
                'is_default_selected' => (int)($optionRow['is_default_selected'] ?? 0) === 1,
                'is_removable' => (int)($optionRow['is_removable'] ?? 1) === 1,
            ];
        }, $optionsStmt->fetchAll(PDO::FETCH_ASSOC));
        $groups[] = [
            'id' => (string)$groupRow['group_id'],
            'name_ar' => trim((string)($groupRow['name_ar'] ?? '')),
            'name_en' => trim((string)($groupRow['name_en'] ?? '')),
            'group_type' => trim((string)($groupRow['group_type'] ?? 'modifier')),
            'min_select' => (int)($groupRow['min_select'] ?? 0),
            'max_select' => (int)($groupRow['max_select'] ?? 1),
            'is_required' => (int)($groupRow['is_required'] ?? 0) === 1,
            'options' => $options,
        ];
    }
    $tags = normalizeTagList(
        $item['categories_name_ar'] ?? '',
        $item['categories_name_en'] ?? '',
        $groupsRows,
        $discount,
        $isAvailable
    );
    if (empty($galleryImages)) {
        $primaryImage = foodAssetUrl($item['items_image']);
        if ($primaryImage !== '') {
            $galleryImages[] = $primaryImage;
        }
    }
    $suggestedStmt = $con->prepare("
        SELECT
            items_id,
            items_name_ar,
            items_name_en,
            items_image,
            (items_price - (items_price * items_discount / 100)) AS final_price
        FROM items
        WHERE vendor_id = :vendor_id
          AND items_id <> :item_id
          AND items_active = 1
        ORDER BY items_id DESC
        LIMIT 6
    ");
    $suggestedStmt->execute([
        ':vendor_id' => $item['vendor_id'],
        ':item_id' => $itemId,
    ]);
    $suggestedItems = array_map(function ($row) {
        return [
            'id' => (string)$row['items_id'],
            'name_ar' => trim((string)($row['items_name_ar'] ?? '')),
            'name_en' => trim((string)($row['items_name_en'] ?? '')),
            'image_url' => foodAssetUrl($row['items_image']),
            'price' => round((float)($row['final_price'] ?? 0), 2),
        ];
    }, $suggestedStmt->fetchAll(PDO::FETCH_ASSOC));
    respondJson([
        'status' => 'success',
        'data' => [
            'item' => [
                'id' => (string)$item['items_id'],
                'vendor_id' => (string)$item['vendor_id'],
                'category_id' => (string)$item['items_cat'],
                'category_name_ar' => trim((string)($item['categories_name_ar'] ?? '')),
                'category_name_en' => trim((string)($item['categories_name_en'] ?? '')),
                'name_ar' => trim((string)($item['items_name_ar'] ?? '')),
                'name_en' => trim((string)($item['items_name_en'] ?? '')),
                'description_ar' => trim((string)($item['items_desc_ar'] ?? '')),
                'description_en' => trim((string)($item['items_desc_en'] ?? '')),
                'image_url' => foodAssetUrl($item['items_image']),
                'price' => round($finalPrice, 2),
                'compare_price' => $discount > 0 ? round($originalPrice, 2) : null,
                'is_available' => $isAvailable,
            ],
            'gallery_images' => $galleryImages,
            'rating' => round((float)($item['average_rating'] ?? 0), 1),
            'reviews_count' => (int)($item['total_reviews'] ?? 0),
            'tags' => $tags,
            'modifier_groups' => $groups,
            'suggested_items' => $suggestedItems,
        ],
    ]);
} catch (Throwable $e) {
    respondJson([
        'status' => 'failure',
        'message' => $e->getMessage(),
    ], 500);
}