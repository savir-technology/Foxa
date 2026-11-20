import 'package:admin_tks/model/waste_model.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class WasteLedgerPage extends StatefulWidget {
  const WasteLedgerPage({super.key});

  @override
  State<WasteLedgerPage> createState() => _WasteLedgerPageState();
}

class _WasteLedgerPageState extends State<WasteLedgerPage> {
  final AccountingData api = AccountingData();
  final TextEditingController _searchController = TextEditingController();

  List<WasteRecord> rows = [];
  WasteSummary summary = WasteSummary(rowsCount: 0, totalQuantity: 0, totalCost: 0);
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    setState(() => loading = true);
    final res = await api.getWasteLedger();
    if (!mounted) return;
    setState(() {
      rows = res?.rows ?? [];
      summary = res?.summary ?? WasteSummary(rowsCount: 0, totalQuantity: 0, totalCost: 0);
      loading = false;
    });
  }

  Future<void> _deleteWaste(WasteRecord row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سجل هالك'),
        content: const Text('سيتم حذف السجل وإرجاع الكمية للمخزون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final ok = await api.deleteWasteEntry(row.wasteId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف سجل الهالك')),
      );
      fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل حذف سجل الهالك')),
      );
    }
  }

  Future<void> _openAddDialog() async {
    final options = await api.getInventoryVariantsForWaste();
    if (!mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد متغيرات مخزون متاحة للتسجيل')),
      );
      return;
    }

    InventoryVariantOption selected = options.first;
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController(text: selected.price.toStringAsFixed(2));
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('إضافة هالك'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selected.variantId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'المنتج / اللون / المقاس'),
                      items: options.map((option) {
                        final label =
                            '${option.productName} - ${option.colorName} - ${option.sizeName} (متاح: ${option.availableQuantity})';
                        return DropdownMenuItem<int>(
                          value: option.variantId,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final option = options.firstWhere((e) => e.variantId == value);
                        setLocalState(() {
                          selected = option;
                          costController.text = option.price.toStringAsFixed(2);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الكمية',
                        helperText: 'المتاح: ${selected.availableQuantity}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'تكلفة الوحدة'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'سبب الهالك'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setLocalState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(
                        'تاريخ الهالك: ${_date(selectedDate)}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final qty = int.tryParse(quantityController.text.trim()) ?? 0;
    final cost = double.tryParse(costController.text.trim()) ?? 0;
    final reason = reasonController.text.trim();

    if (qty <= 0 || cost <= 0 || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بيانات صحيحة')),
      );
      return;
    }

    if (qty > selected.availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الكمية أكبر من المتاح (${selected.availableQuantity})'),
        ),
      );
      return;
    }

    final ok = await api.addWasteEntry(
      itemId: selected.itemId,
      variantId: selected.variantId,
      quantity: qty,
      costPerUnit: cost,
      reason: reason,
      notes: notesController.text.trim(),
      wasteDate: _date(selectedDate),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الهالك')),
      );
      fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تسجيل الهالك')),
      );
    }
  }

  List<WasteRecord> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return rows;
    return rows.where((row) {
      final haystack = [
        row.productName,
        row.colorName,
        row.sizeName,
        row.reason,
        row.wasteDate,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final isMobile = MediaQuery.of(context).size.width < 980;

    return DashboardPageShell(
      title: 'دفتر الهالك',
      subtitle: 'سجل الهالك مرتبط بالمخزون ويؤثر مباشرة على الربحية.',
      icon: Icons.delete_sweep_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetch,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton.filled(
          onPressed: _openAddDialog,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'عدد السجلات',
          value: '${summary.rowsCount}',
          icon: Icons.receipt_long_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'إجمالي الكمية',
          value: '${summary.totalQuantity}',
          icon: Icons.production_quantity_limits_rounded,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'إجمالي التكلفة',
          value: '${_money(summary.totalCost)} SAR',
          icon: Icons.money_off_csred_rounded,
          tint: Colors.redAccent,
        ),
      ],
      body: Column(
        children: [
          DashboardPanel(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث بالمنتج أو اللون أو المقاس أو السبب أو التاريخ',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: CircularProgressIndicator(color: kPrimary),
            )
          else if (filtered.isEmpty)
            const DashboardEmptyState(
              title: 'لا توجد سجلات هالك',
              subtitle: 'ابدأ بإضافة سجل هالك لتتبع الفاقد بدقة.',
              icon: Icons.delete_outline_rounded,
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = filtered[index];
                return DashboardPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.productName,
                              style: const TextStyle(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteWaste(row),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      Text(
                        '${row.colorName} - ${row.sizeName}',
                        style: const TextStyle(color: kTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text('الكمية: ${row.quantity}'),
                      Text('تكلفة الوحدة: ${_money(row.costPerUnit)} SAR'),
                      Text('الإجمالي: ${_money(row.totalCost)} SAR'),
                      const SizedBox(height: 6),
                      Text('السبب: ${row.reason}'),
                      if (row.notes.trim().isNotEmpty) Text('ملاحظات: ${row.notes}'),
                      const SizedBox(height: 6),
                      Text(
                        row.wasteDate,
                        style: const TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            DashboardPanel(
              padding: const EdgeInsets.all(0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('المنتج')),
                    DataColumn(label: Text('اللون')),
                    DataColumn(label: Text('المقاس')),
                    DataColumn(label: Text('الكمية')),
                    DataColumn(label: Text('تكلفة الوحدة')),
                    DataColumn(label: Text('الإجمالي')),
                    DataColumn(label: Text('السبب')),
                    DataColumn(label: Text('إجراء')),
                  ],
                  rows: filtered.map((row) {
                    return DataRow(cells: [
                      DataCell(Text(row.wasteDate)),
                      DataCell(Text(row.productName)),
                      DataCell(Text(row.colorName)),
                      DataCell(Text(row.sizeName)),
                      DataCell(Text('${row.quantity}')),
                      DataCell(Text('${_money(row.costPerUnit)} SAR')),
                      DataCell(Text('${_money(row.totalCost)} SAR')),
                      DataCell(SizedBox(
                        width: 200,
                        child: Text(
                          row.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(
                        IconButton(
                          onPressed: () => _deleteWaste(row),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _money(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _date(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
