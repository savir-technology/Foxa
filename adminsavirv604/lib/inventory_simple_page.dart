import 'dart:convert';

import 'package:admin_tks/EditItemPage.dart';
import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/model/categories_model.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/remote/category_data.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/remote/store_operations_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventorySimplePage extends StatefulWidget {
  const InventorySimplePage({super.key});

  @override
  State<InventorySimplePage> createState() => _InventorySimplePageState();
}

class _InventorySimplePageState extends State<InventorySimplePage> {
  static const String _countUrl =
      'https://savir-technology.online/roaqv2/dash/items/count/items_count.php';

  final TextEditingController _searchController = TextEditingController();
  final ItemsData _itemsData = ItemsData();
  final CategoryData _categoryData = CategoryData();
  final StoreOperationsData _storeOperationsData = StoreOperationsData();

  final List<_InventoryRecord> _records = [];
  final Map<String, ItemsModel> _itemLookup = {};
  final Map<String, String> _categoryLookup = {};
  final Map<int, int> _minimumStockLookup = {};

  bool _loading = true;
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  int _rowsPerPage = 7;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final response = await DashboardApiClient.getUrl(_countUrl);
      final items = await _itemsData.getItems() ?? <ItemsModel>[];
      final categories = await _categoryData.getCategories();
      final overview = await _storeOperationsData.getOverview();

      _itemLookup
        ..clear()
        ..addEntries(
          items.where((item) => item.itemsId?.trim().isNotEmpty == true).map(
                (item) => MapEntry(item.itemsId!.trim(), item),
              ),
        );

      _categoryLookup
        ..clear()
        ..addEntries(
          categories
              .where((category) => category.categoriesId?.trim().isNotEmpty == true)
              .map(
                (category) => MapEntry(
                  category.categoriesId!.trim(),
                  _categoryLabel(category),
                ),
              ),
        );

      _minimumStockLookup
        ..clear()
        ..addEntries(
          (overview?.lowStockRows ?? const [])
              .map((row) => MapEntry(row.itemId, row.minimumStock)),
        );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final rows = <_InventoryRecord>[];

      if (decoded is Map && decoded['status'] == 'success') {
        final data = decoded['data'];
        if (data is List) {
          for (final entry in data.whereType<Map>()) {
            final row = _InventoryRecord.fromJson(
              entry.cast<String, dynamic>(),
              item: _itemLookup[
                entry['item_id']?.toString().trim() ?? ''
              ],
              categoryLookup: _categoryLookup,
              minimumStockLookup: _minimumStockLookup,
            );
            rows.add(row);
          }
        }
      } else if (decoded is List) {
        for (final entry in decoded.whereType<Map>()) {
          rows.add(
            _InventoryRecord.fromJson(
              entry.cast<String, dynamic>(),
              item: null,
              categoryLookup: _categoryLookup,
              minimumStockLookup: _minimumStockLookup,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _records
          ..clear()
          ..addAll(rows);
        _currentPage = 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل بيانات المخزون: $e')),
      );
    }
  }

  String _categoryLabel(cat value) {
    final ar = value.categoriesNameAr?.trim() ?? '';
    final en = value.categoriesNameEn?.trim() ?? '';
    if (ar.isNotEmpty && en.isNotEmpty) return '$ar / $en';
    if (ar.isNotEmpty) return ar;
    if (en.isNotEmpty) return en;
    return 'غير محدد';
  }

  List<_InventoryRecord> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((record) {
      final matchesStatus =
          _statusFilter == 'all' ? true : record.statusKey == _statusFilter;
      final matchesCategory =
          _categoryFilter == 'all' ? true : record.categoryId == _categoryFilter;
      final haystack = [
        record.productNameAr,
        record.productNameEn,
        record.categoryName,
        record.unit,
        record.colorName,
        record.sizeName,
        record.itemId.toString(),
      ].join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesStatus && matchesCategory && matchesQuery;
    }).toList();
  }

  int get _outCount => _filteredRecords.where((row) => row.statusKey == 'out').length;

  int get _lowCount => _filteredRecords.where((row) => row.statusKey == 'low').length;

  double get _inventoryValue => _filteredRecords.fold<double>(
        0,
        (sum, row) => sum + (row.price * row.quantity),
      );

  List<_InventoryRecord> get _pageRecords {
    final filtered = _filteredRecords;
    final start = _currentPage * _rowsPerPage;
    if (start >= filtered.length) {
      return const <_InventoryRecord>[];
    }
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _pageCount {
    final filtered = _filteredRecords.length;
    if (filtered == 0) return 1;
    return (filtered / _rowsPerPage).ceil();
  }

  Future<void> _openItemDetails(_InventoryRecord record) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.productNameAr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الفئة: ${record.categoryName}'),
            Text('الوحدة: ${record.unit}'),
            Text('الكمية: ${record.quantity}'),
            Text('السعر: ${record.price.toStringAsFixed(0)} SAR'),
            Text('الحالة: ${record.quantityStatusAr}'),
            const SizedBox(height: 8),
            Text(
              record.updatedLabel,
              style: const TextStyle(color: kTextSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.offNamed(DashboardRoutes.menu);
            },
            child: const Text('فتح القائمة'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditItem(_InventoryRecord record) async {
    final item = record.item;
    if (item == null) {
      Get.snackbar(
        'المخزون',
        'تعذر العثور على بيانات الصنف الكاملة للتحرير.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.to(() => EditItemPage(item: item));
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _deleteItem(_InventoryRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل تريد حذف "${record.productNameAr}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _itemsData.deleteItem(
        record.itemId.toString(),
        record.imageName ?? '',
      );
      final status = response?['status']?.toString();
      if (status == 'success') {
        Get.snackbar(
          'المخزون',
          'تم حذف الصنف بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );
        await _loadData();
        return;
      }

      Get.snackbar(
        'المخزون',
        response?['message']?.toString() ?? 'تعذر حذف الصنف',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'المخزون',
        'تعذر حذف الصنف: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _pageRecords;
    final startIndex = _records.isEmpty
        ? 0
        : (_currentPage * _rowsPerPage) + 1;
    final endIndex = _records.isEmpty
        ? 0
        : ((_currentPage * _rowsPerPage) + visible.length);

    return DashboardPageShell(
      title: 'المخزون المبسط',
      subtitle: 'إدارة المواد والمكونات الأساسية من شاشة خفيفة وسريعة.',
      icon: Icons.inventory_2_rounded,
      actions: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _loadData,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تحديث'),
        ),
        FilledButton.icon(
          onPressed: () => Get.toNamed(DashboardRoutes.menu),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('القائمة'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'منخفض المخزون',
          value: '$_lowCount',
          icon: Icons.warning_amber_rounded,
          tint: const Color(0xFFF59E0B),
        ),
        DashboardStatCard(
          label: 'نفد المخزون',
          value: '$_outCount',
          icon: Icons.error_outline_rounded,
          tint: Colors.redAccent,
        ),
        DashboardStatCard(
          label: 'إجمالي المواد',
          value: '${_filteredRecords.length}',
          icon: Icons.inventory_2_outlined,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'قيمة المخزون',
          value: '${_inventoryValue.toStringAsFixed(0)} SAR',
          icon: Icons.payments_rounded,
          tint: const Color(0xFF0F766E),
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardPanel(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {
                            _currentPage = 0;
                          }),
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن مادة...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'الحالة',
                            prefixIcon: Icon(Icons.filter_alt_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('كل الحالات'),
                            ),
                            DropdownMenuItem(
                              value: 'ok',
                              child: Text('متوفر'),
                            ),
                            DropdownMenuItem(
                              value: 'low',
                              child: Text('منخفض'),
                            ),
                            DropdownMenuItem(
                              value: 'out',
                              child: Text('نفد المخزون'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _statusFilter = value;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          initialValue: _categoryFilter,
                          decoration: const InputDecoration(
                            labelText: 'كل الفئات',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('كل الفئات'),
                            ),
                            ..._categoryLookup.entries.map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _categoryFilter = value;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          borderRadius: BorderRadius.circular(18),
                          items: const [
                            DropdownMenuItem(value: 6, child: Text('6 لكل صفحة')),
                            DropdownMenuItem(value: 7, child: Text('7 لكل صفحة')),
                            DropdownMenuItem(value: 10, child: Text('10 لكل صفحة')),
                            DropdownMenuItem(value: 14, child: Text('14 لكل صفحة')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _rowsPerPage = value;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_filteredRecords.isEmpty)
                  const DashboardEmptyState(
                    title: 'لا توجد مواد مطابقة',
                    subtitle: 'جرّب تغيير الفلتر أو البحث بالاسم أو الكمية.',
                    icon: Icons.inventory_2_outlined,
                  )
                else
                  DashboardPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'عرض المواد',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                'عرض $startIndex - $endIndex من ${_filteredRecords.length} مادة',
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: kStroke),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            dataRowMinHeight: 76,
                            dataRowMaxHeight: 88,
                            headingRowColor: WidgetStateColor.resolveWith(
                              (states) => kSurfaceElevated,
                            ),
                            columns: const [
                              DataColumn(label: Text('المادة')),
                              DataColumn(label: Text('الفئة')),
                              DataColumn(label: Text('الكمية المتوفرة')),
                              DataColumn(label: Text('الوحدة')),
                              DataColumn(label: Text('الحد الأدنى')),
                              DataColumn(label: Text('الحالة')),
                              DataColumn(label: Text('آخر تحديث')),
                              DataColumn(label: Text('الإجراءات')),
                            ],
                            rows: visible.map((row) {
                              final rowColor = row.statusKey == 'out'
                                  ? Colors.red.withValues(alpha: 0.035)
                                  : row.statusKey == 'low'
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.04)
                                      : Colors.transparent;

                              return DataRow(
                                color: WidgetStateProperty.resolveWith(
                                  (states) => rowColor,
                                ),
                                cells: [
                                  DataCell(_InventoryProductCell(row: row)),
                                  DataCell(Text(row.categoryName)),
                                  DataCell(_QuantityCell(quantity: row.quantity)),
                                  DataCell(Text(row.unit)),
                                  DataCell(Text('${row.minimumStock}')),
                                  DataCell(_StatusBadge(row: row)),
                                  DataCell(Text(row.updatedLabel)),
                                  DataCell(
                                    _RowActions(
                                      onInfo: () => _openItemDetails(row),
                                      onEdit: () => _openEditItem(row),
                                      onDelete: () => _deleteItem(row),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          child: Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'لكل صفحة',
                                    style: TextStyle(
                                      color: kTextSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _rowsPerPage,
                                      items: const [
                                        DropdownMenuItem(value: 6, child: Text('6')),
                                        DropdownMenuItem(value: 7, child: Text('7')),
                                        DropdownMenuItem(value: 10, child: Text('10')),
                                        DropdownMenuItem(value: 14, child: Text('14')),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _rowsPerPage = value;
                                          _currentPage = 0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Center(
                                  child: Wrap(
                                    spacing: 6,
                                    children: List.generate(_pageCount, (index) {
                                      final selected = index == _currentPage;
                                      return InkWell(
                                        onTap: () => setState(() => _currentPage = index),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? kPrimary
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: kStroke),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: selected
                                                  ? Colors.white
                                                  : kTextPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Text(
                                'عرض ${_filteredRecords.isEmpty ? 0 : startIndex} - ${_filteredRecords.isEmpty ? 0 : endIndex} من ${_filteredRecords.length} مادة',
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _InventoryRecord {
  const _InventoryRecord({
    required this.itemId,
    required this.vendorId,
    required this.variantId,
    required this.productNameAr,
    required this.productNameEn,
    required this.categoryId,
    required this.categoryName,
    required this.colorName,
    required this.colorHex,
    required this.sizeName,
    required this.quantity,
    required this.price,
    required this.minimumStock,
    required this.statusKey,
    required this.quantityStatusAr,
    required this.updatedLabel,
    required this.imageName,
    required this.item,
  });

  factory _InventoryRecord.fromJson(
    Map<String, dynamic> json, {
    required ItemsModel? item,
    required Map<String, String> categoryLookup,
    required Map<int, int> minimumStockLookup,
  }) {
    final quantity = int.tryParse(json['quantity']?.toString() ?? '') ?? 0;
    final price = double.tryParse(json['price']?.toString() ?? '') ?? 0;
    final itemId = int.tryParse(json['item_id']?.toString() ?? '') ?? 0;
    final productNameAr = item?.itemsNameAr?.trim().isNotEmpty == true
        ? item!.itemsNameAr!.trim()
        : json['product_name']?.toString() ?? 'مادة';
    final productNameEn = item?.itemsNameEn?.trim().isNotEmpty == true
        ? item!.itemsNameEn!.trim()
        : json['product_name_en']?.toString() ?? '';
    final categoryId = item?.itemsCat?.trim() ?? '';
    final categoryName = categoryLookup[categoryId] ??
        (json['category_name']?.toString().trim().isNotEmpty == true
            ? json['category_name'].toString()
            : 'غير محدد');
    final stockLevel = json['stock_level']?.toString() ?? _resolveStatus(quantity);
    final rawMinimumStock = int.tryParse(json['minimum_stock']?.toString() ?? '');
    final minimumStock = rawMinimumStock ??
        minimumStockLookup[itemId] ??
        _defaultMinimumStock(quantity, stockLevel);

    return _InventoryRecord(
      itemId: itemId,
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
      variantId: int.tryParse(json['variant_id']?.toString() ?? ''),
      productNameAr: productNameAr,
      productNameEn: productNameEn,
      categoryId: categoryId,
      categoryName: categoryName,
      colorName: json['color_name']?.toString() ?? '-',
      colorHex: json['color_hex']?.toString(),
      sizeName: json['size_name']?.toString() ?? '-',
      quantity: quantity,
      price: price,
      minimumStock: minimumStock,
      statusKey: stockLevel,
      quantityStatusAr: json['quantity_status']?.toString() ?? _statusLabelAr(stockLevel),
      updatedLabel: _formatUpdatedLabel(item?.itemsDate),
      imageName: item?.itemsImage?.trim().isNotEmpty == true ? item!.itemsImage!.trim() : null,
      item: item,
    );
  }

  final int itemId;
  final int vendorId;
  final int? variantId;
  final String productNameAr;
  final String productNameEn;
  final String categoryId;
  final String categoryName;
  final String colorName;
  final String? colorHex;
  final String sizeName;
  final int quantity;
  final double price;
  final int minimumStock;
  final String statusKey;
  final String quantityStatusAr;
  final String updatedLabel;
  final String? imageName;
  final ItemsModel? item;

  String get unit => sizeName.trim().isNotEmpty && sizeName.trim() != '-'
      ? sizeName.trim()
      : 'قطعة';

  static int _defaultMinimumStock(int quantity, String stockLevel) {
    if (stockLevel == 'out') {
      return 3;
    }
    if (stockLevel == 'low') {
      return 10;
    }
    if (quantity >= 30) {
      return 20;
    }
    if (quantity >= 12) {
      return 5;
    }
    if (quantity >= 6) {
      return 8;
    }
    return 10;
  }
}

class _InventoryProductCell extends StatelessWidget {
  const _InventoryProductCell({required this.row});

  final _InventoryRecord row;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveItemImageUrl(row.imageName);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: kSurfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kStroke),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl == null
                ? Image.asset('assets/img/restaurant.png', fit: BoxFit.cover)
                : AppNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: 54,
                    height: 54,
                    borderRadius: BorderRadius.circular(14),
                    placeholderIcon: Icons.inventory_2_rounded,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  row.productNameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.productNameEn.isNotEmpty ? row.productNameEn : 'Inventory item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityCell extends StatelessWidget {
  const _QuantityCell({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    final color = quantity <= 0
        ? Colors.redAccent
        : quantity <= 5
            ? const Color(0xFFF59E0B)
            : kPrimary;

    return Text(
      quantity.toString(),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.row});

  final _InventoryRecord row;

  @override
  Widget build(BuildContext context) {
    final color = row.statusKey == 'out'
        ? Colors.redAccent
        : row.statusKey == 'low'
            ? const Color(0xFFF59E0B)
            : kPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        row.quantityStatusAr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onInfo,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.info_outline_rounded,
          tint: const Color(0xFF1D4ED8),
          onTap: onInfo,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.edit_outlined,
          tint: const Color(0xFFF59E0B),
          onTap: onEdit,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.delete_outline_rounded,
          tint: Colors.redAccent,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, size: 18, color: tint),
      ),
    );
  }
}

String _resolveStatus(int quantity) {
  if (quantity <= 0) return 'out';
  if (quantity <= 5) return 'low';
  return 'ok';
}

String _statusLabelAr(String statusKey) {
  switch (statusKey) {
    case 'out':
      return 'نفدت الكمية';
    case 'low':
      return 'كمية قليلة';
    default:
      return 'كمية كافية';
  }
}

String _formatUpdatedLabel(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) {
    return 'اليوم';
  }
  return value;
}

String? _resolveItemImageUrl(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  if (raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:')) {
    return raw;
  }
  return 'https://savir-technology.online/roaqv2/uploud/items/$raw';
}
