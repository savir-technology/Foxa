<?php
include "../../../connect.php";

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function respond(array $payload, int $statusCode = 200): void
{
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

function ensureWasteTable(PDO $con): void
{
    $con->exec("
        CREATE TABLE IF NOT EXISTS inventory_waste (
            waste_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            vendor_id INT NOT NULL DEFAULT 0,
            item_id INT NOT NULL,
            variant_id INT NULL,
            quantity INT NOT NULL DEFAULT 0,
            cost_per_unit DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            total_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
            reason VARCHAR(255) NULL,
            notes TEXT NULL,
            waste_date DATE NOT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

try {
    $actor = requireDashboardActor(['vendor']);
    $vendorId = (int)($actor['vendor']['vendor_id'] ?? 0);

    ensureWasteTable($con);

    $itemId = isset($_POST['item_id']) ? (int)$_POST['item_id'] : 0;
    $variantId = isset($_POST['variant_id']) && $_POST['variant_id'] !== ''
        ? (int)$_POST['variant_id']
        : null;
    $quantity = isset($_POST['quantity']) ? (int)$_POST['quantity'] : 0;
    $reason = isset($_POST['reason']) ? trim((string)$_POST['reason']) : '';
    $notes = isset($_POST['notes']) ? trim((string)$_POST['notes']) : null;
    $wasteDate = isset($_POST['waste_date']) && trim((string)$_POST['waste_date']) !== ''
        ? trim((string)$_POST['waste_date'])
        : date('Y-m-d');
    $costPerUnitInput = isset($_POST['cost_per_unit']) ? (float)$_POST['cost_per_unit'] : 0.0;

    if ($itemId <= 0 || $quantity <= 0) {
        respond(['status' => 'error', 'message' => 'item_id and quantity are required'], 400);
    }

    $itemStmt = $con->prepare("
        SELECT items_id, items_name_ar, items_name_en, items_count, items_price, vendor_id
        FROM items
        WHERE items_id = :item_id
          AND vendor_id = :vendor_id
        LIMIT 1
    ");
    $itemStmt->execute([
        ':item_id' => $itemId,
        ':vendor_id' => $vendorId,
    ]);
    $item = $itemStmt->fetch(PDO::FETCH_ASSOC);
    if (!$item) {
        respond(['status' => 'error', 'message' => 'Product not found'], 404);
    }

    $availableStock = (int)($item['items_count'] ?? 0);
    $resolvedCostPerUnit = $costPerUnitInput > 0 ? $costPerUnitInput : (float)($item['items_price'] ?? 0);

    if ($variantId !== null) {
        $variantStmt = $con->prepare("
            SELECT variant_id, item_id, stock, price
            FROM item_variants
            WHERE variant_id = :variant_id
            LIMIT 1
        ");
        $variantStmt->execute([':variant_id' => $variantId]);
        $variant = $variantStmt->fetch(PDO::FETCH_ASSOC);

        if (!$variant || (int)$variant['item_id'] !== $itemId) {
            respond(['status' => 'error', 'message' => 'Invalid variant'], 400);
        }

        $availableStock = (int)($variant['stock'] ?? 0);
        if ((float)($variant['price'] ?? 0) > 0 && $costPerUnitInput <= 0) {
            $resolvedCostPerUnit = (float)$variant['price'];
        }
    }

    if ($availableStock < $quantity) {
        respond([
            'status' => 'error',
            'message' => 'Requested quantity is greater than available stock',
            'available' => $availableStock,
        ], 400);
    }

    $totalCost = $quantity * $resolvedCostPerUnit;

    $con->beginTransaction();

    if ($variantId !== null) {
        $updateVariantStmt = $con->prepare("
            UPDATE item_variants
            SET stock = GREATEST(stock - :qty, 0)
            WHERE variant_id = :variant_id
        ");
        $updateVariantStmt->execute([
            ':qty' => $quantity,
            ':variant_id' => $variantId,
        ]);

        $updateItemCountStmt = $con->prepare("
            UPDATE items
            SET items_count = GREATEST(items_count - :qty, 0)
            WHERE items_id = :item_id
              AND vendor_id = :vendor_id
        ");
        $updateItemCountStmt->execute([
            ':qty' => $quantity,
            ':item_id' => $itemId,
            ':vendor_id' => $vendorId,
        ]);
    } else {
        $updateItemStmt = $con->prepare("
            UPDATE items
            SET items_count = GREATEST(items_count - :qty, 0)
            WHERE items_id = :item_id
              AND vendor_id = :vendor_id
        ");
        $updateItemStmt->execute([
            ':qty' => $quantity,
            ':item_id' => $itemId,
            ':vendor_id' => $vendorId,
        ]);
    }

    $insertStmt = $con->prepare("
        INSERT INTO inventory_waste
            (vendor_id, item_id, variant_id, quantity, cost_per_unit, total_cost, reason, notes, waste_date)
        VALUES
            (:vendor_id, :item_id, :variant_id, :quantity, :cost_per_unit, :total_cost, :reason, :notes, :waste_date)
    ");
    $insertStmt->execute([
        ':vendor_id' => $vendorId,
        ':item_id' => $itemId,
        ':variant_id' => $variantId,
        ':quantity' => $quantity,
        ':cost_per_unit' => $resolvedCostPerUnit,
        ':total_cost' => $totalCost,
        ':reason' => $reason !== '' ? $reason : null,
        ':notes' => $notes,
        ':waste_date' => $wasteDate,
    ]);

    $wasteId = (int)$con->lastInsertId();
    $con->commit();

    respond([
        'status' => 'success',
        'message' => 'Waste entry saved successfully',
        'waste_id' => $wasteId,
        'item_id' => $itemId,
        'variant_id' => $variantId,
        'quantity' => $quantity,
        'cost_per_unit' => number_format($resolvedCostPerUnit, 2, '.', ''),
        'total_cost' => number_format($totalCost, 2, '.', ''),
    ]);
} catch (Throwable $e) {
    if ($con->inTransaction()) {
        $con->rollBack();
    }

    respond([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], 500);
}
