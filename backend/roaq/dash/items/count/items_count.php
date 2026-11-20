<?php
include "../../../connect.php";
$actor = requireDashboardActor(['vendor', 'master']);
$isVendor = $actor['role'] === 'vendor';
$vendorId = $isVendor ? (int)$actor['vendor']['vendor_id'] : 0;

header('Content-Type: application/json; charset=UTF-8');
masterSetCorsHeaders();

function stockLabel($stock)
{
    if ($stock <= 0) return 'out';
    if ($stock <= 5) return 'low';
    return 'ok';
}

function stockLabelAr($level)
{
    if ($level === 'out') return 'نفدت الكمية';
    if ($level === 'low') return 'كمية قليلة';
    return 'كمية كافية';
}

try {
    $query = "
        SELECT
            i.items_id,
            i.items_name_ar,
            i.items_name_en,
            i.items_count,
            i.items_price,
            i.items_discount,
            i.vendor_id,
            iv.variant_id,
            iv.stock AS variant_stock,
            iv.price AS variant_price,
            c.color_name,
            c.color_hex,
            s.size_name
        FROM items i
        LEFT JOIN item_variants iv ON iv.item_id = i.items_id
        LEFT JOIN colors c ON c.color_id = iv.color_id
        LEFT JOIN sizes s ON s.size_id = iv.size_id
    ";

    if ($isVendor) {
        $query .= " WHERE i.vendor_id = :vendor_id";
    }

    $query .= " ORDER BY i.items_id DESC, iv.variant_id ASC";

    $stmt = $con->prepare($query);
    if ($isVendor) {
        $stmt->execute([':vendor_id' => $vendorId]);
    } else {
        $stmt->execute();
    }
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $data = [];
    $summary = [
        'total_rows' => 0,
        'out_count' => 0,
        'low_count' => 0,
        'ok_count' => 0,
        'total_units' => 0,
    ];

    foreach ($rows as $row) {
        $stock = isset($row['variant_stock']) && $row['variant_stock'] !== null
            ? (int)$row['variant_stock']
            : (int)$row['items_count'];
        $level = stockLabel($stock);

        $entry = [
            'item_id' => (int)$row['items_id'],
            'vendor_id' => (int)$row['vendor_id'],
            'variant_id' => $row['variant_id'] !== null ? (int)$row['variant_id'] : null,
            'product_name' => $row['items_name_ar'] ?: ($row['items_name_en'] ?: 'منتج بدون اسم'),
            'product_name_en' => $row['items_name_en'],
            'color_name' => $row['color_name'] ?: '-',
            'color_hex' => $row['color_hex'] ?: null,
            'size_name' => $row['size_name'] ?: '-',
            'quantity' => $stock,
            'price' => $row['variant_price'] !== null ? (float)$row['variant_price'] : (float)$row['items_price'],
            'discount' => (int)$row['items_discount'],
            'stock_level' => $level,
            'quantity_status' => stockLabelAr($level),
        ];

        $data[] = $entry;
        $summary['total_rows']++;
        $summary['total_units'] += $stock;
        if ($level === 'out') $summary['out_count']++;
        if ($level === 'low') $summary['low_count']++;
        if ($level === 'ok') $summary['ok_count']++;
    }

    echo json_encode([
        'status' => 'success',
        'summary' => $summary,
        'data' => $data,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
?>
