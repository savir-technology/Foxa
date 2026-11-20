<?php

function arCurrentBaseUrl(): string
{
    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['SERVER_PORT'] ?? '') == '443');
    $scheme = $https ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '');
    $basePath = rtrim(dirname(dirname($scriptName)), '/\\');

    return $scheme . '://' . $host . $basePath;
}

function arBuildPublicUrl(?string $path): string
{
    $path = trim((string) $path);
    if ($path === '') {
        return '';
    }

    if (preg_match('/^https?:\/\//i', $path)) {
        $currentBaseUrl = arCurrentBaseUrl();
        $normalized = preg_replace(
            '#^https?://[^/]+/(?:Zahra_store|savir603)/zahra#i',
            $currentBaseUrl,
            $path
        );

        return $normalized ?: $path;
    }

    $normalizedPath = ltrim(str_replace('\\', '/', $path), '/');

    return arCurrentBaseUrl() . '/' . $normalizedPath;
}

function arTableColumns(PDO $con, string $table): array
{
    static $cache = [];

    if (isset($cache[$table])) {
        return $cache[$table];
    }

    $stmt = $con->query("SHOW COLUMNS FROM `{$table}`");
    $columns = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $columns[$row['Field']] = true;
    }

    $cache[$table] = $columns;
    return $columns;
}

function arOptionalSelectColumns(array $columns): array
{
    $optional = [
        'left_temple_image_path',
        'right_temple_image_path',
        'frame_mode',
        'frame_width_ratio',
        'lens_width_ratio',
        'lens_height_ratio',
        'bridge_width_ratio',
        'temple_length_ratio',
        'temple_drop_ratio',
        'rim_thickness_ratio',
        'frame_color',
        'temple_color',
        'lens_tint',
        'frame_shape',
    ];

    $selected = [];
    foreach ($optional as $column) {
        if (isset($columns[$column])) {
            $selected[] = 'f.' . $column;
        }
    }

    return $selected;
}

function getItemArFilter(PDO $con, int $itemId, ?int $variantId = null): ?array
{
    $columns = arTableColumns($con, 'item_ar_filters');
    $select = [
        'f.filter_id',
        'f.item_id',
        'f.variant_id',
        'f.overlay_image_path',
        'f.scale_factor',
        'f.offset_x',
        'f.offset_y',
        'f.rotation_adjust',
        'f.bridge_y_adjust',
        'f.is_active',
        'i.items_name_ar',
        'i.items_name_en',
    ];
    $select = array_merge($select, arOptionalSelectColumns($columns));

    $sql = "
        SELECT
            " . implode(",\n            ", $select) . "
        FROM item_ar_filters f
        INNER JOIN items i ON i.items_id = f.item_id
        WHERE f.item_id = :itemid
          AND f.is_active = 1
    ";

    $params = [
        ':itemid' => $itemId,
    ];

    if ($variantId !== null) {
        $sql .= " AND (f.variant_id = :variantid OR f.variant_id IS NULL)";
        $params[':variantid'] = $variantId;
        $sql .= "
            ORDER BY
                CASE WHEN f.variant_id = :variantid THEN 0 ELSE 1 END,
                f.filter_id DESC
        ";
    } else {
        $sql .= " AND f.variant_id IS NULL ORDER BY f.filter_id DESC";
    }

    $sql .= " LIMIT 1";

    $stmt = $con->prepare($sql);
    $stmt->execute($params);
    $filter = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$filter) {
        return null;
    }

    $filter['overlay_url'] = arBuildPublicUrl($filter['overlay_image_path'] ?? '');
    $filter['front_frame_url'] = $filter['overlay_url'];
    $filter['left_temple_url'] = arBuildPublicUrl($filter['left_temple_image_path'] ?? '');
    $filter['right_temple_url'] = arBuildPublicUrl($filter['right_temple_image_path'] ?? '');

    $filter['frame_mode'] = (string) ($filter['frame_mode'] ?? 'image');
    $filter['scale_factor'] = (float) ($filter['scale_factor'] ?? 1.0);
    $filter['offset_x'] = (float) ($filter['offset_x'] ?? 0);
    $filter['offset_y'] = (float) ($filter['offset_y'] ?? 0);
    $filter['rotation_adjust'] = (float) ($filter['rotation_adjust'] ?? 0);
    $filter['bridge_y_adjust'] = (float) ($filter['bridge_y_adjust'] ?? 0);

    $filter['frame_width_ratio'] = (float) ($filter['frame_width_ratio'] ?? 1.0);
    $filter['lens_width_ratio'] = (float) ($filter['lens_width_ratio'] ?? 0.42);
    $filter['lens_height_ratio'] = (float) ($filter['lens_height_ratio'] ?? 0.42);
    $filter['bridge_width_ratio'] = (float) ($filter['bridge_width_ratio'] ?? 0.16);
    $filter['temple_length_ratio'] = (float) ($filter['temple_length_ratio'] ?? 0.95);
    $filter['temple_drop_ratio'] = (float) ($filter['temple_drop_ratio'] ?? 0.18);
    $filter['rim_thickness_ratio'] = (float) ($filter['rim_thickness_ratio'] ?? 0.018);
    $filter['frame_color'] = (string) ($filter['frame_color'] ?? '#2c322d');
    $filter['temple_color'] = (string) ($filter['temple_color'] ?? $filter['frame_color']);
    $filter['lens_tint'] = (string) ($filter['lens_tint'] ?? 'rgba(190,210,230,0.08)');
    $filter['frame_shape'] = (string) ($filter['frame_shape'] ?? 'round');

    return $filter;
}
