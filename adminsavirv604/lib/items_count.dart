import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class InventoryAnalysis extends StatefulWidget {
  const InventoryAnalysis({super.key});

  @override
  State<InventoryAnalysis> createState() => _InventoryAnalysisState();
}

class _InventoryAnalysisState extends State<InventoryAnalysis> {
  final TextEditingController _searchController = TextEditingController();
  final List<_InventoryRow> _rows = [];

  bool _isLoading = true;
  String _filter = 'all';
  int _totalUnits = 0;
  int _outCount = 0;
  int _lowCount = 0;
  int _okCount = 0;

  @override
  void initState() {
    super.initState();
    fetchInventoryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchInventoryData() async {
    setState(() => _isLoading = true);
    try {
      final response = await DashboardApiClient.getUrl(
        'https://savir-technology.online/roaqv2/dash/items/count/items_count.php',
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      final parsedRows = <_InventoryRow>[];
      int totalUnits = 0;
      int outCount = 0;
      int lowCount = 0;
      int okCount = 0;

      if (decoded is Map && decoded['status'] == 'success') {
        final data = (decoded['data'] as List?) ?? [];
        for (final row in data) {
          final map = (row as Map).cast<String, dynamic>();
          final inventoryRow = _InventoryRow.fromJson(map);
          parsedRows.add(inventoryRow);
          totalUnits += inventoryRow.quantity;
          if (inventoryRow.level == 'out') outCount++;
          if (inventoryRow.level == 'low') lowCount++;
          if (inventoryRow.level == 'ok') okCount++;
        }
      } else if (decoded is List) {
        // Backward compatibility with the old endpoint format.
        for (final row in decoded) {
          final map = (row as Map).cast<String, dynamic>();
          final inventoryRow = _InventoryRow.fromLegacyJson(map);
          parsedRows.add(inventoryRow);
          totalUnits += inventoryRow.quantity;
          if (inventoryRow.level == 'out') outCount++;
          if (inventoryRow.level == 'low') lowCount++;
          if (inventoryRow.level == 'ok') okCount++;
        }
      }

      if (!mounted) return;
      setState(() {
        _rows
          ..clear()
          ..addAll(parsedRows);
        _totalUnits = totalUnits;
        _outCount = outCount;
        _lowCount = lowCount;
        _okCount = okCount;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل بيانات المخزون: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_InventoryRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    return _rows.where((row) {
      final passLevel = _filter == 'all' ? true : row.level == _filter;
      final haystack = [
        row.productName,
        row.colorName,
        row.sizeName,
        row.itemId.toString(),
        row.variantId?.toString() ?? '',
      ].join(' ').toLowerCase();
      final passQuery = query.isEmpty || haystack.contains(query);
      return passLevel && passQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final rows = _filteredRows;

    return DashboardPageShell(
      title: 'المخزون',
      subtitle: 'متابعة دقيقة لكل منتج حسب اللون والمقاس والكمية.',
      icon: Icons.inventory_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetchInventoryData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'إجمالي السطور',
          value: '${_rows.length}',
          icon: Icons.table_rows_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'إجمالي القطع',
          value: '$_totalUnits',
          icon: Icons.inventory_2_outlined,
          tint: kAccent,
        ),
        DashboardStatCard(
          label: 'نفد',
          value: '$_outCount',
          icon: Icons.warning_amber_rounded,
          tint: Colors.redAccent,
        ),
        DashboardStatCard(
          label: 'منخفض',
          value: '$_lowCount',
          icon: Icons.trending_down_rounded,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'جيد',
          value: '$_okCount',
          icon: Icons.check_circle_outline_rounded,
          tint: Colors.green,
        ),
      ],
      body: Column(
        children: [
          DashboardPanel(
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم المنتج، اللون، المقاس أو رقم المنتج',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _FilterChip(
                      label: 'نفد',
                      selected: _filter == 'out',
                      onTap: () => setState(() => _filter = 'out'),
                    ),
                    _FilterChip(
                      label: 'منخفض',
                      selected: _filter == 'low',
                      onTap: () => setState(() => _filter = 'low'),
                    ),
                    _FilterChip(
                      label: 'جيد',
                      selected: _filter == 'ok',
                      onTap: () => setState(() => _filter = 'ok'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          else if (rows.isEmpty)
            const DashboardEmptyState(
              title: 'لا توجد بيانات مطابقة',
              subtitle: 'جرب تغيير الفلتر أو عبارة البحث.',
              icon: Icons.inbox_rounded,
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _InventoryCard(row: rows[index]),
            )
          else
            DashboardPanel(
              padding: const EdgeInsets.all(0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateColor.resolveWith(
                    (states) => kSurface.withValues(alpha: 0.68),
                  ),
                  columns: const [
                    DataColumn(label: Text('المنتج')),
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('اللون')),
                    DataColumn(label: Text('المقاس')),
                    DataColumn(label: Text('الكمية')),
                    DataColumn(label: Text('السعر')),
                    DataColumn(label: Text('الحالة')),
                  ],
                  rows: rows.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row.productName)),
                        DataCell(Text(row.variantId?.toString() ??
                            row.itemId.toString())),
                        DataCell(_ColorNameCell(row: row)),
                        DataCell(Text(row.sizeName)),
                        DataCell(Text('${row.quantity}')),
                        DataCell(Text('${row.price.toStringAsFixed(0)} SAR')),
                        DataCell(_StatusPill(
                            level: row.level, label: row.levelLabelAr)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.row});

  final _InventoryRow row;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.productName,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: Text('اللون: ${row.colorName}',
                      style: const TextStyle(color: kTextSecondary))),
              Expanded(
                  child: Text('المقاس: ${row.sizeName}',
                      style: const TextStyle(color: kTextSecondary))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: Text('الكمية: ${row.quantity}',
                      style: const TextStyle(color: kTextSecondary))),
              Expanded(
                  child: Text('السعر: ${row.price.toStringAsFixed(0)} SAR',
                      style: const TextStyle(color: kTextSecondary))),
            ],
          ),
          const SizedBox(height: 10),
          _StatusPill(level: row.level, label: row.levelLabelAr),
        ],
      ),
    );
  }
}

class _ColorNameCell extends StatelessWidget {
  const _ColorNameCell({required this.row});

  final _InventoryRow row;

  @override
  Widget build(BuildContext context) {
    final color =
        row.colorHex != null ? _safeColorFromHex(row.colorHex!) : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: kStroke),
            ),
          ),
        if (color != null) const SizedBox(width: 6),
        Text(row.colorName),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.level,
    required this.label,
  });

  final String level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = level == 'out'
        ? Colors.redAccent
        : level == 'low'
            ? kSecondary
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _InventoryRow {
  const _InventoryRow({
    required this.itemId,
    required this.variantId,
    required this.productName,
    required this.colorName,
    required this.colorHex,
    required this.sizeName,
    required this.quantity,
    required this.price,
    required this.level,
    required this.levelLabelAr,
  });

  factory _InventoryRow.fromJson(Map<String, dynamic> json) {
    return _InventoryRow(
      itemId: int.tryParse(json['item_id']?.toString() ?? '') ?? 0,
      variantId: int.tryParse(json['variant_id']?.toString() ?? ''),
      productName: json['product_name']?.toString() ?? 'منتج',
      colorName: json['color_name']?.toString() ?? '-',
      colorHex: json['color_hex']?.toString(),
      sizeName: json['size_name']?.toString() ?? '-',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      level: json['stock_level']?.toString() ?? 'ok',
      levelLabelAr: json['quantity_status']?.toString() ?? 'كمية كافية',
    );
  }

  factory _InventoryRow.fromLegacyJson(Map<String, dynamic> json) {
    final quantity = int.tryParse(json['quantity']?.toString() ?? '') ?? 0;
    final status = json['quantity_status']?.toString() ?? '';
    final level = status.contains('نفدت')
        ? 'out'
        : status.contains('قليلة')
            ? 'low'
            : 'ok';
    return _InventoryRow(
      itemId: 0,
      variantId: null,
      productName: json['product_name']?.toString() ?? 'منتج',
      colorName: '-',
      colorHex: null,
      sizeName: '-',
      quantity: quantity,
      price: 0,
      level: level,
      levelLabelAr: status,
    );
  }

  final int itemId;
  final int? variantId;
  final String productName;
  final String colorName;
  final String? colorHex;
  final String sizeName;
  final int quantity;
  final double price;
  final String level;
  final String levelLabelAr;
}

Color? _safeColorFromHex(String hex) {
  var value = hex.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}
