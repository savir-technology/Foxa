import 'package:admin_tks/model/accounting_entry.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final AccountingData api = AccountingData();
  final TextEditingController _searchController = TextEditingController();

  List<AccountingEntry> entries = [];
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
    final res = await api.getLedger();
    if (!mounted) return;
    setState(() {
      entries = res ?? [];
      loading = false;
    });
  }

  Future<void> _deleteEntry(AccountingEntry entry) async {
    final ok = await api.deleteAccountingEntry(entry.entryId ?? '');
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف القيد بنجاح')),
      );
      fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل حذف القيد')),
      );
    }
  }

  List<AccountingEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return entries;
    return entries.where((e) {
      final haystack = [
        e.entryId ?? '',
        e.entryType ?? '',
        e.description ?? '',
        e.entryDate ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;
    final totalDebit = filtered.fold<double>(
      0,
      (sum, e) => sum + (double.tryParse(e.debit ?? '0') ?? 0),
    );
    final totalCredit = filtered.fold<double>(
      0,
      (sum, e) => sum + (double.tryParse(e.credit ?? '0') ?? 0),
    );
    final isMobile = MediaQuery.of(context).size.width < 930;

    return DashboardPageShell(
      title: 'دفتر القيود اليومية',
      subtitle: 'تتبع كامل لكل حركة مدينة/دائنة مع بحث سريع في القيود.',
      icon: Icons.menu_book_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetch,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'عدد القيود',
          value: '${filtered.length}',
          icon: Icons.receipt_long_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'إجمالي المدين',
          value: '${_money(totalDebit)} SAR',
          icon: Icons.south_west_rounded,
          tint: Colors.redAccent,
        ),
        DashboardStatCard(
          label: 'إجمالي الدائن',
          value: '${_money(totalCredit)} SAR',
          icon: Icons.north_east_rounded,
          tint: Colors.green,
        ),
      ],
      body: Column(
        children: [
          DashboardPanel(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث بالوصف أو التاريخ أو رقم القيد أو نوع الحركة',
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
              title: 'لا توجد قيود',
              subtitle: 'سيظهر هنا كل قيد محاسبي بمجرد تسجيل الحركات.',
              icon: Icons.inbox_rounded,
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = filtered[index];
                return _LedgerCard(
                  entry: e,
                  onDelete: () => _confirmDelete(e),
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
                    DataColumn(label: Text('رقم القيد')),
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('النوع')),
                    DataColumn(label: Text('الوصف')),
                    DataColumn(label: Text('مدين')),
                    DataColumn(label: Text('دائن')),
                    DataColumn(label: Text('إجراء')),
                  ],
                  rows: filtered.map((e) {
                    return DataRow(cells: [
                      DataCell(Text(e.entryId ?? '-')),
                      DataCell(Text(e.entryDate ?? '-')),
                      DataCell(Text(_entryTypeLabel(e.entryType ?? ''))),
                      DataCell(SizedBox(
                        width: 320,
                        child: Text(
                          (e.description ?? '-').trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(Text('${_money(double.tryParse(e.debit ?? '0') ?? 0)} SAR')),
                      DataCell(Text('${_money(double.tryParse(e.credit ?? '0') ?? 0)} SAR')),
                      DataCell(
                        IconButton(
                          tooltip: 'حذف القيد',
                          onPressed: () => _confirmDelete(e),
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

  Future<void> _confirmDelete(AccountingEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد حذف القيد'),
          content: Text('سيتم حذف القيد رقم ${entry.entryId ?? '-'} نهائيًا. هل تريد المتابعة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteEntry(entry);
    }
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.entry,
    required this.onDelete,
  });

  final AccountingEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final debit = double.tryParse(entry.debit ?? '0') ?? 0;
    final credit = double.tryParse(entry.credit ?? '0') ?? 0;
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'قيد #${entry.entryId ?? '-'}',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _entryTypeLabel(entry.entryType ?? ''),
            style: const TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            entry.description?.trim().isNotEmpty == true ? entry.description!.trim() : '-',
            style: const TextStyle(color: kTextPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            entry.entryDate ?? '-',
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'مدين: ${_money(debit)} SAR',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  'دائن: ${_money(credit)} SAR',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _entryTypeLabel(String type) {
  switch (type) {
    case 'sale':
      return 'مبيعات';
    case 'payment':
      return 'تحصيل';
    case 'refund':
    case 'sales_return':
      return 'مرتجع';
    case 'expense':
      return 'مصروف';
    case 'wallet_add':
      return 'إضافة محفظة';
    case 'wallet_use':
      return 'استخدام محفظة';
    default:
      return type.isEmpty ? '-' : type;
  }
}

String _money(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
