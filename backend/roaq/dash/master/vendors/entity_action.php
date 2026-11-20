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

function masterVendorEntityError(string $message, int $statusCode = 400): void
{
    respondJson([
        'status' => 'error',
        'message' => $message,
    ], $statusCode);
}

function masterVendorEntityPayload(): array
{
    $payload = getRequestPayload();
    return is_array($payload) ? $payload : [];
}

function masterVendorEntityRequireTable(string $table): void
{
    if (!tableExists($table)) {
        masterVendorEntityError("Table {$table} is not available", 404);
    }
}

try {
    $admin = requireMasterAuth();
    $payload = masterVendorEntityPayload();
    $entity = strtolower(trim((string)($payload['entity'] ?? '')));
    $action = strtolower(trim((string)($payload['action'] ?? '')));
    $id = (int)($payload['id'] ?? 0);

    if ($entity === '' || $action === '' || $id <= 0) {
        masterVendorEntityError('Invalid entity action payload');
    }

    $allowedActions = ['activate', 'deactivate', 'delete'];
    if (!in_array($action, $allowedActions, true)) {
        masterVendorEntityError('Unsupported action');
    }

    if ($action === 'delete') {
        requireMasterPermission($admin, 'restaurants.delete');
    } else {
        requireMasterPermission($admin, 'restaurants.edit');
    }

    $con->beginTransaction();

    switch ($entity) {
        case 'restaurant':
            masterVendorEntityRequireTable('vendors');
            $productCount = 0;
            if (tableExists('items') && columnExists('items', 'vendor_id')) {
                $stmt = $con->prepare('SELECT COUNT(*) FROM items WHERE vendor_id = :id');
                $stmt->execute([':id' => $id]);
                $productCount = (int)$stmt->fetchColumn();
            }
            $orderCount = 0;
            if (tableExists('vendor_orders') && columnExists('vendor_orders', 'vendor_id')) {
                $stmt = $con->prepare('SELECT COUNT(*) FROM vendor_orders WHERE vendor_id = :id');
                $stmt->execute([':id' => $id]);
                $orderCount = (int)$stmt->fetchColumn();
            }
            if ($productCount > 0 || $orderCount > 0) {
                masterVendorEntityError(
                    'Cannot delete a restaurant with products or orders. Suspend it instead.',
                    409
                );
            }
            if (tableExists('vendor_store_settings')) {
                $stmt = $con->prepare('DELETE FROM vendor_store_settings WHERE vendor_id = :id');
                $stmt->execute([':id' => $id]);
            }
            $stmt = $con->prepare('DELETE FROM vendors WHERE vendor_id = :id');
            $stmt->execute([':id' => $id]);
            if ($stmt->rowCount() === 0) {
                masterVendorEntityError('Restaurant was not found', 404);
            }
            break;

        case 'product':
            masterVendorEntityRequireTable('items');
            if ($action === 'delete') {
                $usageCount = 0;
                if (tableExists('order_items')) {
                    $usageColumns = [];
                    if (columnExists('order_items', 'item_id')) {
                        $usageColumns[] = 'item_id';
                    }
                    if (columnExists('order_items', 'items_id')) {
                        $usageColumns[] = 'items_id';
                    }
                    if (!empty($usageColumns)) {
                        $where = implode(' = :id OR ', $usageColumns) . ' = :id';
                        $usageStmt = $con->prepare("
                            SELECT COUNT(*)
                            FROM order_items
                            WHERE {$where}
                        ");
                        $usageStmt->execute([':id' => $id]);
                        $usageCount = (int)$usageStmt->fetchColumn();
                    }
                }
                if ($usageCount > 0) {
                    masterVendorEntityError('Cannot delete a product linked to orders', 409);
                }
                $deleteStmt = $con->prepare("DELETE FROM items WHERE items_id = :id");
                $deleteStmt->execute([':id' => $id]);
            } else {
                $active = $action === 'activate' ? 1 : 0;
                $stmt = $con->prepare("UPDATE items SET items_active = :active WHERE items_id = :id");
                $stmt->execute([':active' => $active, ':id' => $id]);
            }
            break;

        case 'category':
            masterVendorEntityRequireTable('categories');
            if ($action === 'delete') {
                if (tableExists('items') && columnExists('items', 'items_cat')) {
                    $usageStmt = $con->prepare("SELECT COUNT(*) FROM items WHERE items_cat = :id");
                    $usageStmt->execute([':id' => $id]);
                    if ((int)$usageStmt->fetchColumn() > 0) {
                        masterVendorEntityError('Cannot delete a category with products', 409);
                    }
                }
                $deleteStmt = $con->prepare("DELETE FROM categories WHERE categories_id = :id");
                $deleteStmt->execute([':id' => $id]);
            } else {
                if (!columnExists('categories', 'categories_active')) {
                    masterVendorEntityError('Category activation column is not available', 409);
                }
                $active = $action === 'activate' ? 1 : 0;
                $stmt = $con->prepare("UPDATE categories SET categories_active = :active WHERE categories_id = :id");
                $stmt->execute([':active' => $active, ':id' => $id]);
            }
            break;

        case 'topping':
            masterVendorEntityRequireTable('food_item_modifiers');
            if ($action === 'delete') {
                $deleteStmt = $con->prepare("DELETE FROM food_item_modifiers WHERE modifier_id = :id");
                $deleteStmt->execute([':id' => $id]);
            } else {
                $active = $action === 'activate' ? 1 : 0;
                $stmt = $con->prepare("UPDATE food_item_modifiers SET is_active = :active WHERE modifier_id = :id");
                $stmt->execute([':active' => $active, ':id' => $id]);
            }
            break;

        case 'offer':
            $active = $action === 'activate' ? 1 : 0;
            if (tableExists('restaurant_banners')) {
                if ($action === 'delete') {
                    $stmt = $con->prepare("DELETE FROM restaurant_banners WHERE banner_id = :id");
                    $stmt->execute([':id' => $id]);
                } else {
                    $stmt = $con->prepare("UPDATE restaurant_banners SET is_active = :active WHERE banner_id = :id");
                    $stmt->execute([':active' => $active, ':id' => $id]);
                }
            } elseif (tableExists('ads2')) {
                if ($action === 'delete') {
                    $stmt = $con->prepare("DELETE FROM ads2 WHERE id = :id");
                    $stmt->execute([':id' => $id]);
                } else {
                    $stmt = $con->prepare("UPDATE ads2 SET is_active = :active WHERE id = :id");
                    $stmt->execute([':active' => $active, ':id' => $id]);
                }
            } else {
                masterVendorEntityError('Offers table is not available', 404);
            }
            break;

        case 'coupon':
            masterVendorEntityRequireTable('coupon');
            if ($action === 'delete') {
                $stmt = $con->prepare("DELETE FROM coupon WHERE coupon_id = :id");
                $stmt->execute([':id' => $id]);
            } else {
                $count = $action === 'activate' ? 1 : 0;
                $stmt = $con->prepare("
                    UPDATE coupon
                    SET coupon_count = CASE WHEN coupon_count <= 0 THEN :count ELSE coupon_count END
                    WHERE coupon_id = :id
                ");
                $stmt->execute([':count' => $count, ':id' => $id]);
            }
            break;

        default:
            masterVendorEntityError('Unsupported entity');
    }

    $con->commit();

    respondJson([
        'status' => 'success',
        'message' => 'Entity action completed',
        'data' => [
            'entity' => $entity,
            'action' => $action,
            'id' => $id,
        ],
    ]);
} catch (Throwable $e) {
    if (isset($con) && $con instanceof PDO && $con->inTransaction()) {
        $con->rollBack();
    }
    masterVendorEntityError($e->getMessage(), 500);
}
