<?php
require_once "../../../connect.php";
require_once "../../../notifications/notification_helper.php";

header("Content-Type: application/json; charset=utf-8");
masterSetCorsHeaders();
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, no-store, must-revalidate");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function masterMarketingActionFail(string $message, int $statusCode = 400): void
{
    respondJson(['status' => 'error', 'message' => $message], $statusCode);
}

function masterMarketingRequireColumns(string $table, array $columns): void
{
    if (!tableExists($table)) {
        masterMarketingActionFail('Marketing table is not available', 404);
    }
    foreach ($columns as $column) {
        if (!columnExists($table, $column)) {
            masterMarketingActionFail(
                'Marketing schema is incomplete. Apply migration 20260818_master_marketing_schema.sql first.',
                409
            );
        }
    }
}

function masterMarketingString(array $data, string $key, array $row, string $column, string $fallback = ''): string
{
    if (array_key_exists($key, $data)) {
        return trim((string)$data[$key]);
    }
    return trim((string)($row[$column] ?? $fallback));
}

function masterMarketingInt(array $data, string $key, array $row, string $column, int $fallback = 0): int
{
    if (array_key_exists($key, $data)) {
        return (int)$data[$key];
    }
    return (int)($row[$column] ?? $fallback);
}

function masterMarketingDateOrNull(array $data, string $key, array $row, string $column): ?string
{
    $value = array_key_exists($key, $data) ? trim((string)$data[$key]) : trim((string)($row[$column] ?? ''));
    return $value === '' || $value === '-' ? null : $value;
}

function masterMarketingRow(string $table, string $idColumn, int $id): array
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

function masterMarketingPlacementTable(string $placement): string
{
    $normalized = strtolower(trim($placement));
    if ($normalized === 'home_middle' || $normalized === 'slider_secondary' || $normalized === 'slider_2' || $normalized === 'second') {
        return 'ads';
    }
    return 'ads2';
}

function masterMarketingAdSource(int $id, string $placement = ''): string
{
    global $con;
    if ($id <= 0) {
        return masterMarketingPlacementTable($placement);
    }

    $placement = strtolower(trim($placement));
    $adsExists = false;
    $ads2Exists = false;

    $stmt = $con->prepare('SELECT id FROM ads WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $id]);
    $adsExists = (bool)$stmt->fetch(PDO::FETCH_ASSOC);

    $stmt = $con->prepare('SELECT id FROM ads2 WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $id]);
    $ads2Exists = (bool)$stmt->fetch(PDO::FETCH_ASSOC);

    if ($placement === 'home_middle') {
        if ($adsExists) {
            return 'ads';
        }
        if ($ads2Exists) {
            return 'ads2';
        }
    }

    if ($placement === 'home') {
        if ($ads2Exists) {
            return 'ads2';
        }
        if ($adsExists) {
            return 'ads';
        }
    }

    if ($ads2Exists) {
        return 'ads2';
    }
    if ($adsExists) {
        return 'ads';
    }

    return masterMarketingPlacementTable($placement);
}

function masterMarketingAudit(string $entity, string $action, int $id): void
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
            ':action_text' => "{$entity} {$action}",
            ':entity_label' => "{$entity} #{$id}",
            ':action_time_label' => date('H:i'),
            ':tint_hex' => in_array($action, ['save', 'activate'], true) ? '#16A34A' : '#DC2626',
        ]);
    } catch (Throwable $e) {
        error_log('master marketing action audit failed: ' . $e->getMessage());
    }
}

try {
    $admin = requireMasterAuth();
    $GLOBALS['masterAuthAdmin'] = $admin;

    $payload = getRequestPayload();
    $entity = strtolower(trim((string)($payload['entity'] ?? '')));
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $id = (int)($payload['id'] ?? 0);
    $data = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : [];

    if ($entity === '' || $action === '') {
        masterMarketingActionFail('Invalid marketing action payload');
    }

    $permission = 'marketing.edit';
    if ($entity === 'coupon') {
        $permission = $action === 'delete' || $action === 'disable'
            ? 'coupons.delete'
            : ($id > 0 ? 'coupons.edit' : 'coupons.create');
    } elseif ($entity === 'notification') {
        $permission = 'notifications.send';
    } elseif ($action === 'delete' || $action === 'disable') {
        $permission = 'marketing.delete';
    } elseif ($id <= 0 && $action === 'save') {
        $permission = 'marketing.create';
    }
    requireMasterPermission($admin, $permission);

    $con->beginTransaction();
    $savedId = $id;

    switch ($entity) {
        case 'ad':
            $requestedPlacement = masterMarketingString($data, 'placement', [], 'placement', '');
            $table = $id > 0 ? masterMarketingAdSource($id, $requestedPlacement) : null;
            if ($id > 0 && !tableExists($table)) {
                masterMarketingActionFail('Ads table is not available', 404);
            }
            $row = $id > 0 ? masterMarketingRow($table, 'id', $id) : [];
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE {$table} SET is_active = 0 WHERE id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("UPDATE {$table} SET is_active = 1 WHERE id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            $title = masterMarketingString($data, 'title', $row, 'title_ar', 'عرض تسويقي');
            $image = masterMarketingString($data, 'image_url', $row, 'image_url', '');
            $targetType = masterMarketingString($data, 'target_type', $row, 'target_type', 'restaurant');
            $targetId = masterMarketingInt($data, 'target_id', $row, 'target_id', 0);
            $placement = masterMarketingString($data, 'placement', $row, 'placement', 'home');
            $sortOrder = masterMarketingInt($data, 'sort_order', $row, 'sort_order', 0);
            $seconds = masterMarketingInt($data, 'display_seconds', $row, 'display_seconds', 8);
            $isActive = masterMarketingInt($data, 'is_active', $row, 'is_active', 1);
            $targetTable = masterMarketingPlacementTable($placement);

            if ($id > 0) {
                if ($targetTable !== $table) {
                    if (!tableExists($targetTable)) {
                        masterMarketingActionFail('Ads table is not available', 404);
                    }
                    $insertStmt = $con->prepare("
                        INSERT INTO {$targetTable} (
                            title_ar, title_en, image_url, target_type, target_id,
                            placement, sort_order, display_seconds, is_active, created_at
                        ) VALUES (
                            :title_ar, :title_en, :image_url, :target_type, :target_id,
                            :placement, :sort_order, :display_seconds, :is_active, :created_at
                        )
                    ");
                    $insertStmt->execute([
                        ':title_ar' => $title,
                        ':title_en' => $title,
                        ':image_url' => $image,
                        ':target_type' => in_array($targetType, ['restaurant', 'product'], true) ? $targetType : 'restaurant',
                        ':target_id' => $targetId,
                        ':placement' => $placement,
                        ':sort_order' => $sortOrder,
                        ':display_seconds' => $seconds,
                        ':is_active' => $isActive,
                        ':created_at' => $row['created_at'] ?? date('Y-m-d H:i:s'),
                    ]);
                    $deletedStmt = $con->prepare("DELETE FROM {$table} WHERE id = :id");
                    $deletedStmt->execute([':id' => $id]);
                    $savedId = (int)$con->lastInsertId();
                } else {
                    $stmt = $con->prepare("
                        UPDATE {$table}
                        SET title_ar = :title_ar,
                            title_en = :title_en,
                            image_url = :image_url,
                            target_type = :target_type,
                            target_id = :target_id,
                            placement = :placement,
                            sort_order = :sort_order,
                            display_seconds = :display_seconds,
                            is_active = :is_active
                        WHERE id = :id
                    ");
                    $stmt->execute([
                        ':title_ar' => $title,
                        ':title_en' => $title,
                        ':image_url' => $image,
                        ':target_type' => in_array($targetType, ['restaurant', 'product'], true) ? $targetType : 'restaurant',
                        ':target_id' => $targetId,
                        ':placement' => $placement,
                        ':sort_order' => $sortOrder,
                        ':display_seconds' => $seconds,
                        ':is_active' => $isActive,
                        ':id' => $id,
                    ]);
                }
            } else {
                if (!tableExists($targetTable)) {
                    masterMarketingActionFail('Ads table is not available', 404);
                }
                $stmt = $con->prepare("
                    INSERT INTO {$targetTable} (
                        title_ar, title_en, image_url, target_type, target_id,
                        placement, sort_order, display_seconds, is_active
                    ) VALUES (
                        :title_ar, :title_en, :image_url, :target_type, :target_id,
                        :placement, :sort_order, :display_seconds, :is_active
                    )
                ");
                $stmt->execute([
                    ':title_ar' => $title,
                    ':title_en' => $title,
                    ':image_url' => $image,
                    ':target_type' => in_array($targetType, ['restaurant', 'product'], true) ? $targetType : 'restaurant',
                    ':target_id' => $targetId,
                    ':placement' => $placement,
                    ':sort_order' => $sortOrder,
                    ':display_seconds' => $seconds,
                    ':is_active' => $isActive,
                ]);
                $savedId = (int)$con->lastInsertId();
            }
            break;

        case 'coupon':
            if (!tableExists('coupon')) {
                masterMarketingActionFail('Coupon table is not available', 404);
            }
            $row = $id > 0 ? masterMarketingRow('coupon', 'coupon_id', $id) : [];
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE coupon SET coupon_count = 0 WHERE coupon_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("
                    UPDATE coupon
                    SET coupon_count = CASE WHEN coupon_count <= 0 THEN 100 ELSE coupon_count END,
                        coupon_expiredate = CASE
                            WHEN coupon_expiredate < NOW() THEN DATE_ADD(NOW(), INTERVAL 30 DAY)
                            ELSE coupon_expiredate
                        END
                    WHERE coupon_id = :id
                ");
                $stmt->execute([':id' => $id]);
                break;
            }
            $code = masterMarketingString($data, 'title', $row, 'coupon_name', 'NEWCOUPON');
            $count = masterMarketingInt($data, 'count', $row, 'coupon_count', 100);
            $discount = masterMarketingInt($data, 'discount', $row, 'coupon_discount', 10);
            $expire = masterMarketingString($data, 'end_date', $row, 'coupon_expiredate', date('Y-m-d H:i:s', strtotime('+30 days')));
            if ($id > 0) {
                $stmt = $con->prepare("
                    UPDATE coupon
                    SET coupon_name = :name,
                        coupon_count = :count,
                        coupon_discount = :discount,
                        coupon_expiredate = :expire
                    WHERE coupon_id = :id
                ");
                $stmt->execute([
                    ':name' => $code,
                    ':count' => $count,
                    ':discount' => $discount,
                    ':expire' => $expire,
                    ':id' => $id,
                ]);
            } else {
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
            }
            break;

        case 'offer':
        case 'banner':
            if (!tableExists('restaurant_banners')) {
                masterMarketingActionFail('Banners table is not available', 404);
            }
            $row = $id > 0 ? masterMarketingRow('restaurant_banners', 'banner_id', $id) : [];
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE restaurant_banners SET is_active = 0 WHERE banner_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("UPDATE restaurant_banners SET is_active = 1 WHERE banner_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            $title = masterMarketingString($data, 'title', $row, 'title_ar', 'بنر جديد');
            $subtitle = masterMarketingString($data, 'subtitle', $row, 'subtitle_ar', '');
            $image = masterMarketingString($data, 'image_url', $row, 'image_url', '');
            $placement = masterMarketingString($data, 'placement', $row, 'placement', 'home');
            $sortOrder = masterMarketingInt($data, 'sort_order', $row, 'sort_order', 0);
            $isActive = masterMarketingInt($data, 'is_active', $row, 'is_active', 1);
            $targetType = masterMarketingString($data, 'target_type', $row, 'target_type', 'restaurant');
            $targetId = masterMarketingInt($data, 'target_id', $row, 'target_id', 0);
            $ctaTarget = $targetId > 0
                ? (in_array($targetType, ['restaurant', 'product'], true) ? $targetType : 'restaurant') . ':' . $targetId
                : masterMarketingString($data, 'cta_target', $row, 'cta_target', '');
            if ($id > 0) {
                $stmt = $con->prepare("
                    UPDATE restaurant_banners
                    SET title_ar = :title_ar,
                        title_en = :title_en,
                        subtitle_ar = :subtitle_ar,
                        subtitle_en = :subtitle_en,
                        image_url = :image_url,
                        cta_target = :cta_target,
                        placement = :placement,
                        sort_order = :sort_order,
                        is_active = :is_active
                    WHERE banner_id = :id
                ");
                $stmt->execute([
                    ':title_ar' => $title,
                    ':title_en' => $title,
                    ':subtitle_ar' => $subtitle,
                    ':subtitle_en' => $subtitle,
                    ':image_url' => $image,
                    ':cta_target' => $ctaTarget,
                    ':placement' => $placement,
                    ':sort_order' => $sortOrder,
                    ':is_active' => $isActive,
                    ':id' => $id,
                ]);
            } else {
                $stmt = $con->prepare("
                    INSERT INTO restaurant_banners (
                        title_ar, title_en, subtitle_ar, subtitle_en,
                        image_url, cta_target, placement, sort_order, is_active
                    ) VALUES (
                        :title_ar, :title_en, :subtitle_ar, :subtitle_en,
                        :image_url, :cta_target, :placement, :sort_order, :is_active
                    )
                ");
                $stmt->execute([
                    ':title_ar' => $title,
                    ':title_en' => $title,
                    ':subtitle_ar' => $subtitle,
                    ':subtitle_en' => $subtitle,
                    ':image_url' => $image,
                    ':cta_target' => $ctaTarget,
                    ':placement' => $placement,
                    ':sort_order' => $sortOrder,
                    ':is_active' => $isActive,
                ]);
                $savedId = (int)$con->lastInsertId();
            }
            break;

        case 'video':
            masterMarketingRequireColumns('videos', [
                'video_id', 'video_title', 'video_desc', 'video_url',
                'video_thumbnail', 'video_product_id', 'video_target_type',
                'video_target_id', 'video_views', 'video_likes', 'video_userid',
                'video_is_active',
            ]);
            $row = $id > 0 ? masterMarketingRow('videos', 'video_id', $id) : [];
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE videos SET video_is_active = 0 WHERE video_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("UPDATE videos SET video_is_active = 1 WHERE video_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }

            $title = masterMarketingString($data, 'title', $row, 'video_title', 'Video');
            $description = masterMarketingString($data, 'subtitle', $row, 'video_desc', '');
            $video = masterMarketingString($data, 'video_url', $row, 'video_url', '');
            $thumbnail = masterMarketingString($data, 'video_thumbnail', $row, 'video_thumbnail', '');
            $image = masterMarketingString($data, 'image_url', $row, 'video_thumbnail', '');
            // Older web builds sent the uploaded video URL as image_url. Keep
            // accepting that payload so an upload is never orphaned just
            // because the frontend and backend were deployed at different times.
            if ($video === '' && $image !== '' && preg_match('/\.(mp4|mov|webm|m4v|m3u8)(\?.*)?$/i', $image)) {
                $video = $image;
            }
            if ($thumbnail === '' && $image !== '' && $video !== $image) {
                $thumbnail = $image;
            }
            if ($video === '') {
                masterMarketingActionFail('Video URL is required');
            }

            $targetType = strtolower(masterMarketingString($data, 'target_type', $row, 'video_target_type', ''));
            if (!in_array($targetType, ['restaurant', 'product'], true)) {
                $targetType = '';
            }
            $targetId = masterMarketingInt($data, 'target_id', $row, 'video_target_id', 0);
            $productId = masterMarketingInt($data, 'product_id', $row, 'video_product_id', 0);
            if ($productId <= 0 && $targetType === 'product') {
                $productId = $targetId;
            }
            $views = masterMarketingInt($data, 'views', $row, 'video_views', 0);
            $likes = masterMarketingInt($data, 'likes', $row, 'video_likes', 0);
            $userId = masterMarketingInt($data, 'user_id', $row, 'video_userid', 0);
            $isActive = masterMarketingInt($data, 'is_active', $row, 'video_is_active', 1);

            if ($id > 0) {
                $stmt = $con->prepare("
                    UPDATE videos
                    SET video_title = :title,
                        video_desc = :description,
                        video_url = :video_url,
                        video_thumbnail = :thumbnail,
                        video_product_id = :product_id,
                        video_target_type = :target_type,
                        video_target_id = :target_id,
                        video_views = :views,
                        video_likes = :likes,
                        video_userid = :user_id,
                        video_is_active = :is_active
                    WHERE video_id = :id
                ");
                $stmt->execute([
                    ':title' => $title,
                    ':description' => $description,
                    ':video_url' => $video,
                    ':thumbnail' => $thumbnail,
                    ':product_id' => $productId > 0 ? $productId : null,
                    ':target_type' => $targetType !== '' ? $targetType : null,
                    ':target_id' => $targetId > 0 ? $targetId : null,
                    ':views' => $views,
                    ':likes' => $likes,
                    ':user_id' => $userId > 0 ? $userId : null,
                    ':is_active' => $isActive,
                    ':id' => $id,
                ]);
            } else {
                $stmt = $con->prepare("
                    INSERT INTO videos (
                        video_title, video_desc, video_url, video_thumbnail,
                        video_product_id, video_target_type, video_target_id,
                        video_views, video_likes, video_userid, video_is_active
                    ) VALUES (
                        :title, :description, :video_url, :thumbnail,
                        :product_id, :target_type, :target_id,
                        :views, :likes, :user_id, :is_active
                    )
                ");
                $stmt->execute([
                    ':title' => $title,
                    ':description' => $description,
                    ':video_url' => $video,
                    ':thumbnail' => $thumbnail,
                    ':product_id' => $productId > 0 ? $productId : null,
                    ':target_type' => $targetType !== '' ? $targetType : null,
                    ':target_id' => $targetId > 0 ? $targetId : null,
                    ':views' => $views,
                    ':likes' => $likes,
                    ':user_id' => $userId > 0 ? $userId : null,
                    ':is_active' => $isActive,
                ]);
                $savedId = (int)$con->lastInsertId();
            }
            break;

        case 'story':
            masterMarketingRequireColumns('restaurant_stories', [
                'story_id', 'vendor_id', 'title_ar', 'title_en', 'media_type',
                'image_url', 'video_url', 'target_type', 'target_id', 'sort_order',
                'starts_at', 'ends_at', 'is_active',
            ]);
            $row = $id > 0 ? masterMarketingRow('restaurant_stories', 'story_id', $id) : [];
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE restaurant_stories SET is_active = 0 WHERE story_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("UPDATE restaurant_stories SET is_active = 1 WHERE story_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            $title = masterMarketingString($data, 'title', $row, 'title_ar', 'Story');
            $subtitle = masterMarketingString($data, 'subtitle', $row, 'title_en', '');
            $image = masterMarketingString($data, 'image_url', $row, 'image_url', '');
            $video = masterMarketingString($data, 'video_url', $row, 'video_url', '');
            $mediaType = strtolower(masterMarketingString($data, 'media_type', $row, 'media_type', $video !== '' ? 'video' : 'image'));
            $targetType = masterMarketingString($data, 'target_type', $row, 'target_type', 'restaurant');
            $targetId = masterMarketingInt($data, 'target_id', $row, 'target_id', 0);
            $vendorId = masterMarketingInt($data, 'vendor_id', $row, 'vendor_id', $targetType === 'restaurant' ? $targetId : 0);
            $sortOrder = masterMarketingInt($data, 'sort_order', $row, 'sort_order', 0);
            $isActive = masterMarketingInt($data, 'is_active', $row, 'is_active', 1);
            if ($id > 0) {
                $stmt = $con->prepare("
                    UPDATE restaurant_stories
                    SET vendor_id = :vendor_id,
                        title_ar = :title_ar,
                        title_en = :title_en,
                        media_type = :media_type,
                        image_url = :image_url,
                        video_url = :video_url,
                        target_type = :target_type,
                        target_id = :target_id,
                        sort_order = :sort_order,
                        starts_at = :starts_at,
                        ends_at = :ends_at,
                        is_active = :is_active
                    WHERE story_id = :id
                ");
                $stmt->execute([
                    ':vendor_id' => $vendorId,
                    ':title_ar' => $title,
                    ':title_en' => $subtitle,
                    ':media_type' => $mediaType === 'video' ? 'video' : 'image',
                    ':image_url' => $image,
                    ':video_url' => $video,
                    ':target_type' => in_array($targetType, ['restaurant', 'product'], true) ? $targetType : 'restaurant',
                    ':target_id' => $targetId,
                    ':sort_order' => $sortOrder,
                    ':starts_at' => masterMarketingDateOrNull($data, 'start_date', $row, 'starts_at'),
                    ':ends_at' => masterMarketingDateOrNull($data, 'end_date', $row, 'ends_at'),
                    ':is_active' => $isActive,
                    ':id' => $id,
                ]);
            } else {
                $stmt = $con->prepare("
                    INSERT INTO restaurant_stories (
                        vendor_id, title_ar, title_en, media_type, image_url, video_url,
                        target_type, target_id, sort_order, starts_at, ends_at, is_active
                    ) VALUES (
                        :vendor_id, :title_ar, :title_en, :media_type, :image_url, :video_url,
                        :target_type, :target_id, :sort_order, :starts_at, :ends_at, :is_active
                    )
                ");
                $stmt->execute([
                    ':vendor_id' => $vendorId,
                    ':title_ar' => $title,
                    ':title_en' => $subtitle,
                    ':media_type' => $mediaType === 'video' ? 'video' : 'image',
                    ':image_url' => $image,
                    ':video_url' => $video,
                    ':target_type' => in_array($targetType, ['restaurant', 'product'], true) ? $targetType : 'restaurant',
                    ':target_id' => $targetId,
                    ':sort_order' => $sortOrder,
                    ':starts_at' => masterMarketingDateOrNull($data, 'start_date', $row, 'starts_at'),
                    ':ends_at' => masterMarketingDateOrNull($data, 'end_date', $row, 'ends_at'),
                    ':is_active' => $isActive,
                ]);
                $savedId = (int)$con->lastInsertId();
            }
            break;

        case 'category':
            masterMarketingRequireColumns('categories', [
                'categories_id', 'categories_name_ar', 'categories_name_en',
                'categories_image', 'vendor_id', 'categories_active',
            ]);
            $row = $id > 0 ? masterMarketingRow('categories', 'categories_id', $id) : [];
            if ($action === 'delete' || $action === 'disable') {
                $stmt = $con->prepare("UPDATE categories SET categories_active = 0 WHERE categories_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate') {
                $stmt = $con->prepare("UPDATE categories SET categories_active = 1 WHERE categories_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            $title = masterMarketingString($data, 'title', $row, 'categories_name_ar', 'Featured category');
            $subtitle = masterMarketingString($data, 'subtitle', $row, 'categories_name_en', $title);
            $image = masterMarketingString($data, 'image_url', $row, 'categories_image', '');
            $vendorId = masterMarketingInt($data, 'vendor_id', $row, 'vendor_id', 0);
            $isActive = masterMarketingInt($data, 'is_active', $row, 'categories_active', 1);
            if ($id > 0) {
                $stmt = $con->prepare("
                    UPDATE categories
                    SET categories_name_ar = :title_ar,
                        categories_name_en = :title_en,
                        categories_image = :image,
                        vendor_id = :vendor_id,
                        categories_active = :is_active
                    WHERE categories_id = :id
                ");
                $stmt->execute([
                    ':title_ar' => $title,
                    ':title_en' => $subtitle !== '' ? $subtitle : $title,
                    ':image' => $image,
                    ':vendor_id' => $vendorId,
                    ':is_active' => $isActive,
                    ':id' => $id,
                ]);
            } else {
                $stmt = $con->prepare("
                    INSERT INTO categories (
                        categories_name_ar, categories_name_en, categories_image,
                        vendor_id, categories_active
                    ) VALUES (
                        :title_ar, :title_en, :image, :vendor_id, :is_active
                    )
                ");
                $stmt->execute([
                    ':title_ar' => $title,
                    ':title_en' => $subtitle !== '' ? $subtitle : $title,
                    ':image' => $image,
                    ':vendor_id' => $vendorId,
                    ':is_active' => $isActive,
                ]);
                $savedId = (int)$con->lastInsertId();
            }
            break;

        case 'notification':
            if (!tableExists('users')) {
                masterMarketingActionFail('Users table is not available', 404);
            }
            ensureNotificationsTable($con);
            if (($action === 'delete' || $action === 'disable') && $id > 0) {
                $stmt = $con->prepare("UPDATE notifications SET notification_is_read = 1 WHERE notification_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }
            if ($action === 'activate' && $id > 0) {
                $stmt = $con->prepare("UPDATE notifications SET notification_is_read = 0 WHERE notification_id = :id");
                $stmt->execute([':id' => $id]);
                break;
            }

            $title = trim((string)($data['title'] ?? 'إشعار من الإدارة'));
            $body = trim((string)($data['body'] ?? $data['subtitle'] ?? ''));
            $type = trim((string)($data['type'] ?? $data['type_label'] ?? 'marketing'));
            $target = strtolower(trim((string)($data['target'] ?? $data['audience'] ?? 'all')));
            $userId = (int)($data['user_id'] ?? $data['target_id'] ?? 0);
            $sendPush = !isset($data['send_push']) || (int)$data['send_push'] === 1 || $data['send_push'] === true;

            if ($title === '') {
                masterMarketingActionFail('Notification title is required');
            }
            if ($body === '') {
                masterMarketingActionFail('Notification body is required');
            }
            if ($type === '') {
                $type = 'marketing';
            }

            $payload = [
                'source' => 'master_marketing',
                'target' => $target === 'user' ? 'user' : 'all',
            ];

            if ($target === 'user' || $userId > 0) {
                if ($userId <= 0) {
                    masterMarketingActionFail('User id is required for individual notification');
                }
                notifyUser($con, $userId, $type, $title, $body, 'master_marketing', null, $payload, $sendPush);
                $savedId = (int)$con->lastInsertId();
            } else {
                broadcastNotification($con, $type, $title, $body, 'master_marketing', null, $payload);
                $savedId = 0;
            }
            break;

        default:
            masterMarketingActionFail('Unsupported marketing entity');
    }

    masterMarketingAudit($entity, $action, $savedId);
    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Marketing action completed',
        'data' => [
            'entity' => $entity,
            'action' => $action,
            'id' => $savedId,
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    masterMarketingActionFail($e->getMessage(), 500);
}
