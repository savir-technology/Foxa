<?php

if (!function_exists('dashboardModifierValue')) {
    function dashboardModifierValue($source, string $key, $default = null)
    {
        if (is_array($source) && array_key_exists($key, $source)) {
            return $source[$key];
        }

        if (is_object($source) && isset($source->$key)) {
            return $source->$key;
        }

        return $default;
    }
}

if (!function_exists('dashboardModifierString')) {
    function dashboardModifierString($value, string $default = ''): string
    {
        if ($value === null) {
            return $default;
        }

        return trim((string)$value);
    }
}

if (!function_exists('dashboardModifierBool')) {
    function dashboardModifierBool($value, bool $default = false): bool
    {
        if ($value === null || $value === '') {
            return $default;
        }

        if (is_bool($value)) {
            return $value;
        }

        $normalized = strtolower(trim((string)$value));
        return in_array($normalized, ['1', 'true', 'yes', 'on'], true);
    }
}

if (!function_exists('dashboardModifierInt')) {
    function dashboardModifierInt($value, int $default = 0): int
    {
        if ($value === null || $value === '') {
            return $default;
        }

        return (int)$value;
    }
}

if (!function_exists('dashboardModifierFloat')) {
    function dashboardModifierFloat($value, float $default = 0.0): float
    {
        if ($value === null || $value === '') {
            return $default;
        }

        return (float)$value;
    }
}

if (!function_exists('dashboardModifierUploadPaths')) {
    function dashboardModifierUploadPaths(): array
    {
        $root = realpath(__DIR__ . '/../../');
        if ($root === false) {
            throw new RuntimeException('Unable to resolve dashboard upload root');
        }

        return [
            'dir' => $root . DIRECTORY_SEPARATOR . 'uploud' . DIRECTORY_SEPARATOR . 'modifier_options',
            'url' => 'https://savir-technology.online/roaqv2/uploud/modifier_options',
        ];
    }
}

if (!function_exists('dashboardModifierLooksLikeBase64Image')) {
    function dashboardModifierLooksLikeBase64Image($value): bool
    {
        if (!is_string($value)) {
            return false;
        }

        $normalized = trim($value);
        if ($normalized === '') {
            return false;
        }

        if (preg_match('/^https?:\/\//i', $normalized)) {
            return false;
        }

        if (preg_match('/^data:image\/[a-zA-Z0-9.+-]+;base64,/', $normalized)) {
            return true;
        }

        return strlen($normalized) > 120;
    }
}

if (!function_exists('dashboardSaveModifierBase64Image')) {
    function dashboardSaveModifierBase64Image(string $value): ?string
    {
        $paths = dashboardModifierUploadPaths();
        $uploadDir = $paths['dir'];
        $baseUrl = $paths['url'];

        $payload = trim($value);
        if (preg_match('/^data:image\/[a-zA-Z0-9.+-]+;base64,/', $payload)) {
            $payload = substr($payload, strpos($payload, ',') + 1);
        }

        $decoded = base64_decode($payload, true);
        if ($decoded === false) {
            return null;
        }

        if (!file_exists($uploadDir) && !mkdir($uploadDir, 0777, true) && !file_exists($uploadDir)) {
            return null;
        }

        $fileName = uniqid('modifier_', true) . '.png';
        $filePath = $uploadDir . DIRECTORY_SEPARATOR . $fileName;
        if (file_put_contents($filePath, $decoded) === false) {
            return null;
        }

        return rtrim($baseUrl, '/') . '/' . $fileName;
    }
}

if (!function_exists('dashboardResolveModifierImageUrl')) {
    function dashboardResolveModifierImageUrl($value): string
    {
        $normalized = dashboardModifierString($value, '');
        if ($normalized === '') {
            return '';
        }

        if (!dashboardModifierLooksLikeBase64Image($normalized)) {
            return $normalized;
        }

        $savedUrl = dashboardSaveModifierBase64Image($normalized);
        if ($savedUrl === null) {
            throw new RuntimeException('Failed to save modifier option image');
        }

        return $savedUrl;
    }
}

if (!function_exists('dashboardNormalizeModifierGroupType')) {
    function dashboardNormalizeModifierGroupType($value): string
    {
        return dashboardModifierString($value, 'modifier') === 'ingredient'
            ? 'ingredient'
            : 'modifier';
    }
}

if (!function_exists('dashboardNormalizeModifierGroupPayload')) {
    function dashboardNormalizeModifierGroupPayload($group, int $fallbackIndex = 0): array
    {
        $options = dashboardModifierValue($group, 'options', []);
        if (!is_array($options)) {
            $options = [];
        }

        $normalizedOptions = [];
        foreach ($options as $index => $option) {
            $nameAr = dashboardModifierString(dashboardModifierValue($option, 'name_ar', dashboardModifierValue($option, 'nameAr', '')));
            $nameEn = dashboardModifierString(dashboardModifierValue($option, 'name_en', dashboardModifierValue($option, 'nameEn', '')));
            if ($nameAr === '' && $nameEn === '') {
                continue;
            }

            $normalizedOptions[] = [
                'name_ar' => $nameAr,
                'name_en' => $nameEn,
                'image_url' => dashboardModifierString(
                    dashboardModifierValue(
                        $option,
                        'image_url',
                        dashboardModifierValue($option, 'imageUrl', dashboardModifierValue($option, 'image', ''))
                    )
                ),
                'price_delta' => dashboardModifierFloat(
                    dashboardModifierValue($option, 'price_delta', dashboardModifierValue($option, 'priceDelta', 0))
                ),
                'is_default_selected' => dashboardModifierBool(
                    dashboardModifierValue($option, 'is_default_selected', dashboardModifierValue($option, 'isDefaultSelected', false)),
                    false
                ),
                'is_removable' => dashboardModifierBool(
                    dashboardModifierValue($option, 'is_removable', dashboardModifierValue($option, 'isRemovable', true)),
                    true
                ),
                'sort_order' => dashboardModifierInt(
                    dashboardModifierValue($option, 'sort_order', dashboardModifierValue($option, 'sortOrder', $index)),
                    $index
                ),
                'is_active' => dashboardModifierBool(
                    dashboardModifierValue($option, 'is_active', dashboardModifierValue($option, 'isActive', true)),
                    true
                ),
            ];
        }

        $minSelect = max(0, dashboardModifierInt(dashboardModifierValue($group, 'min_select', dashboardModifierValue($group, 'minSelect', 0)), 0));
        $maxSelect = max(1, dashboardModifierInt(dashboardModifierValue($group, 'max_select', dashboardModifierValue($group, 'maxSelect', 1)), 1));
        if ($maxSelect < $minSelect) {
            $maxSelect = $minSelect;
        }

        return [
            'name_ar' => dashboardModifierString(dashboardModifierValue($group, 'name_ar', dashboardModifierValue($group, 'nameAr', ''))),
            'name_en' => dashboardModifierString(dashboardModifierValue($group, 'name_en', dashboardModifierValue($group, 'nameEn', ''))),
            'group_type' => dashboardNormalizeModifierGroupType(
                dashboardModifierValue($group, 'group_type', dashboardModifierValue($group, 'groupType', 'modifier'))
            ),
            'min_select' => $minSelect,
            'max_select' => $maxSelect,
            'is_required' => dashboardModifierBool(
                dashboardModifierValue($group, 'is_required', dashboardModifierValue($group, 'isRequired', false)),
                false
            ),
            'sort_order' => dashboardModifierInt(
                dashboardModifierValue($group, 'sort_order', dashboardModifierValue($group, 'sortOrder', $fallbackIndex)),
                $fallbackIndex
            ),
            'is_active' => dashboardModifierBool(
                dashboardModifierValue($group, 'is_active', dashboardModifierValue($group, 'isActive', true)),
                true
            ),
            'options' => $normalizedOptions,
        ];
    }
}

if (!function_exists('dashboardSyncItemModifierGroups')) {
    function dashboardSyncItemModifierGroups(PDO $con, int $itemId, array $groups): array
    {
        $deleteGroupsStmt = $con->prepare("DELETE FROM food_item_modifier_groups WHERE item_id = :item_id");
        $deleteGroupsStmt->execute([':item_id' => $itemId]);

        $groupStmt = $con->prepare("
            INSERT INTO food_item_modifier_groups (
                item_id,
                name_ar,
                name_en,
                group_type,
                min_select,
                max_select,
                is_required,
                sort_order,
                is_active
            ) VALUES (
                :item_id,
                :name_ar,
                :name_en,
                :group_type,
                :min_select,
                :max_select,
                :is_required,
                :sort_order,
                :is_active
            )
        ");

        $optionStmt = $con->prepare("
            INSERT INTO food_item_modifiers (
                group_id,
                name_ar,
                name_en,
                image_url,
                price_delta,
                is_default_selected,
                is_removable,
                sort_order,
                is_active
            ) VALUES (
                :group_id,
                :name_ar,
                :name_en,
                :image_url,
                :price_delta,
                :is_default_selected,
                :is_removable,
                :sort_order,
                :is_active
            )
        ");

        $createdGroups = 0;
        $createdOptions = 0;

        foreach (array_values($groups) as $index => $groupRaw) {
            $group = dashboardNormalizeModifierGroupPayload($groupRaw, $index);
            if ($group['name_ar'] === '' && $group['name_en'] === '') {
                continue;
            }

            $groupStmt->execute([
                ':item_id' => $itemId,
                ':name_ar' => $group['name_ar'],
                ':name_en' => $group['name_en'],
                ':group_type' => $group['group_type'],
                ':min_select' => $group['min_select'],
                ':max_select' => $group['max_select'],
                ':is_required' => $group['is_required'] ? 1 : 0,
                ':sort_order' => $group['sort_order'],
                ':is_active' => $group['is_active'] ? 1 : 0,
            ]);

            $groupId = (int)$con->lastInsertId();
            $createdGroups++;

            foreach ($group['options'] as $optionIndex => $option) {
                $optionImageUrl = dashboardResolveModifierImageUrl($option['image_url'] ?? '');
                $optionStmt->execute([
                ':group_id' => $groupId,
                ':name_ar' => $option['name_ar'],
                ':name_en' => $option['name_en'],
                ':image_url' => $optionImageUrl,
                ':price_delta' => $option['price_delta'],
                ':is_default_selected' => $option['is_default_selected'] ? 1 : 0,
                ':is_removable' => $option['is_removable'] ? 1 : 0,
                ':sort_order' => $option['sort_order'] ?? $optionIndex,
                    ':is_active' => $option['is_active'] ? 1 : 0,
                ]);
                $createdOptions++;
            }
        }

        return [
            'groups' => $createdGroups,
            'options' => $createdOptions,
        ];
    }
}

if (!function_exists('dashboardFetchItemModifierGroups')) {
    function dashboardFetchItemModifierGroups(PDO $con, int $itemId): array
    {
        $groupsStmt = $con->prepare("
            SELECT group_id, name_ar, name_en, group_type, min_select, max_select, is_required, sort_order, is_active
            FROM food_item_modifier_groups
            WHERE item_id = :item_id
            ORDER BY sort_order ASC, group_id ASC
        ");
        $groupsStmt->execute([':item_id' => $itemId]);
        $groupsRows = $groupsStmt->fetchAll(PDO::FETCH_ASSOC);

        $groups = [];
        foreach ($groupsRows as $groupRow) {
            $optionsStmt = $con->prepare("
            SELECT modifier_id, name_ar, name_en, image_url, price_delta, is_default_selected, is_removable, sort_order, is_active
            FROM food_item_modifiers
            WHERE group_id = :group_id
            ORDER BY sort_order ASC, modifier_id ASC
            ");
            $optionsStmt->execute([':group_id' => $groupRow['group_id']]);
            $optionsRows = $optionsStmt->fetchAll(PDO::FETCH_ASSOC);

            $options = array_map(static function ($optionRow) {
                return [
                    'id' => (string)$optionRow['modifier_id'],
                    'name_ar' => trim((string)($optionRow['name_ar'] ?? '')),
                    'name_en' => trim((string)($optionRow['name_en'] ?? '')),
                    'image_url' => trim((string)($optionRow['image_url'] ?? '')),
                    'price_delta' => round((float)($optionRow['price_delta'] ?? 0), 2),
                    'is_default_selected' => (int)($optionRow['is_default_selected'] ?? 0) === 1,
                    'is_removable' => (int)($optionRow['is_removable'] ?? 1) === 1,
                    'sort_order' => (int)($optionRow['sort_order'] ?? 0),
                    'is_active' => (int)($optionRow['is_active'] ?? 1) === 1,
                ];
            }, $optionsRows);

            $groups[] = [
                'id' => (string)$groupRow['group_id'],
                'name_ar' => trim((string)($groupRow['name_ar'] ?? '')),
                'name_en' => trim((string)($groupRow['name_en'] ?? '')),
                'group_type' => trim((string)($groupRow['group_type'] ?? 'modifier')),
                'min_select' => (int)($groupRow['min_select'] ?? 0),
                'max_select' => (int)($groupRow['max_select'] ?? 1),
                'is_required' => (int)($groupRow['is_required'] ?? 0) === 1,
                'sort_order' => (int)($groupRow['sort_order'] ?? 0),
                'is_active' => (int)($groupRow['is_active'] ?? 1) === 1,
                'options' => $options,
            ];
        }

        return $groups;
    }
}
