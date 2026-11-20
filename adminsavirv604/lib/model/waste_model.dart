class WasteRecord {
  WasteRecord({
    required this.wasteId,
    required this.itemId,
    required this.variantId,
    required this.productName,
    required this.colorName,
    required this.sizeName,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
    required this.reason,
    required this.notes,
    required this.wasteDate,
  });

  factory WasteRecord.fromJson(Map<String, dynamic> json) {
    final productNameAr = json['items_name_ar']?.toString().trim() ?? '';
    final productNameEn = json['items_name_en']?.toString().trim() ?? '';
    return WasteRecord(
      wasteId: int.tryParse(json['waste_id']?.toString() ?? '') ?? 0,
      itemId: int.tryParse(json['item_id']?.toString() ?? '') ?? 0,
      variantId: int.tryParse(json['variant_id']?.toString() ?? ''),
      productName: productNameAr.isNotEmpty
          ? productNameAr
          : (productNameEn.isNotEmpty ? productNameEn : 'Product'),
      colorName: json['color_name']?.toString() ?? '-',
      sizeName: json['size_name']?.toString() ?? '-',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      costPerUnit:
          double.tryParse(json['cost_per_unit']?.toString() ?? '') ?? 0,
      totalCost: double.tryParse(json['total_cost']?.toString() ?? '') ?? 0,
      reason: json['reason']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      wasteDate: json['waste_date']?.toString() ?? '',
    );
  }

  final int wasteId;
  final int itemId;
  final int? variantId;
  final String productName;
  final String colorName;
  final String sizeName;
  final int quantity;
  final double costPerUnit;
  final double totalCost;
  final String reason;
  final String notes;
  final String wasteDate;
}

class WasteSummary {
  WasteSummary({
    required this.rowsCount,
    required this.totalQuantity,
    required this.totalCost,
  });

  factory WasteSummary.fromJson(Map<String, dynamic> json) {
    return WasteSummary(
      rowsCount: int.tryParse(json['rows_count']?.toString() ?? '') ?? 0,
      totalQuantity:
          int.tryParse(json['total_quantity']?.toString() ?? '') ?? 0,
      totalCost: double.tryParse(json['total_cost']?.toString() ?? '') ?? 0,
    );
  }

  final int rowsCount;
  final int totalQuantity;
  final double totalCost;
}

class WasteLedgerResponse {
  WasteLedgerResponse({
    required this.summary,
    required this.rows,
  });

  final WasteSummary summary;
  final List<WasteRecord> rows;
}

class InventoryVariantOption {
  InventoryVariantOption({
    required this.itemId,
    required this.variantId,
    required this.productName,
    required this.colorName,
    required this.sizeName,
    required this.availableQuantity,
    required this.price,
  });

  factory InventoryVariantOption.fromJson(Map<String, dynamic> json) {
    return InventoryVariantOption(
      itemId: int.tryParse(json['item_id']?.toString() ?? '') ?? 0,
      variantId: int.tryParse(json['variant_id']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ?? 'Product',
      colorName: json['color_name']?.toString() ?? '-',
      sizeName: json['size_name']?.toString() ?? '-',
      availableQuantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
    );
  }

  final int itemId;
  final int variantId;
  final String productName;
  final String colorName;
  final String sizeName;
  final int availableQuantity;
  final double price;
}

