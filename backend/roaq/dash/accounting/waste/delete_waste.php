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

    $wasteId = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    if ($wasteId <= 0) {
        respond(['status' => 'error', 'message' => 'id is required'], 400);
    }

    $wasteStmt = $con->prepare("
        SELECT waste_id, item_id, variant_id, quantity
        FROM inventory_waste
        WHERE waste_id = :waste_id
          AND vendor_id = :vendor_id
        LIMIT 1
    ");
    $wasteStmt->execute([
        ':waste_id' => $wasteId,
        ':vendor_id' => $vendorId,
    ]);
    $waste = $wasteStmt->fetch(PDO::FETCH_ASSOC);

    if (!$waste) {
        respond(['status' => 'error', 'message' => 'Waste row not found'], 404);
    }

    $itemId = (int)$waste['item_id'];
    $variantId = $waste['variant_id'] !== null ? (int)$waste['variant_id'] : null;
    $quantity = (int)$waste['quantity'];

    $con->beginTransaction();

    if ($variantId !== null) {
        $restoreVariantStmt = $con->prepare("
            UPDATE item_variants
            SET stock = stock + :qty
            WHERE variant_id = :variant_id
        ");
        $restoreVariantStmt->execute([
            ':qty' => $quantity,
            ':variant_id' => $variantId,
        ]);
    }

    $restoreItemStmt = $con->prepare("
        UPDATE items
        SET items_count = items_count + :qty
        WHERE items_id = :item_id
          AND vendor_id = :vendor_id
    ");
    $restoreItemStmt->execute([
        ':qty' => $quantity,
        ':item_id' => $itemId,
        ':vendor_id' => $vendorId,
    ]);

    $deleteStmt = $con->prepare("
        DELETE FROM inventory_waste
        WHERE waste_id = :waste_id
          AND vendor_id = :vendor_id
    ");
    $deleteStmt->execute([
        ':waste_id' => $wasteId,
        ':vendor_id' => $vendorId,
    ]);

    $con->commit();

    respond([
        'status' => 'success',
        'message' => 'Waste entry deleted successfully',
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
