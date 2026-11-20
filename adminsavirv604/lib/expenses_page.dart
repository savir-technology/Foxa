import 'package:admin_tks/add_expense_page.dart';
import 'package:admin_tks/model/expense_model.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final AccountingData api = AccountingData();
  final TextEditingController _searchController = TextEditingController();

  List<ExpenseModel> rows = [];
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
    final res = await api.getExpenses();
    if (!mounted) return;
    setState(() {
      rows = res ?? [];
      loading = false;
    });
  }

  Future<void> _openAddExpense() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpensePage()),
    );
    if (updated == true) {
      fetch();
    }
  }

  Future<void> _showEditDialog(ExpenseModel expense) async {
    final titleController = TextEditingController(text: expense.expenseTitle);
    final amountController = TextEditingController(text: expense.amount);

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'عنوان المصروف'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
          ],
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
      ),
    );

    if (save != true) return;
    if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك املأ كل الحقول')),
      );
      return;
    }

    final success = await api.updateExpense(
      expense.expenseId ?? '',
      titleController.text.trim(),
      amountController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل المصروف')),
      );
      fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تعديل المصروف')),
      );
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('سيتم حذف مصروف "${expense.expenseTitle ?? ''}" نهائيًا.'),
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
      ),
    );

    if (confirm != true) return;
    final success = await api.deleteExpense(expense.expenseId ?? '');
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المصروف')),
      );
      fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل حذف المصروف')),
      );
    }
  }

  List<ExpenseModel> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return rows;
    return rows.where((r) {
      final haystack = [
        r.expenseId ?? '',
        r.expenseTitle ?? '',
        r.expenseDate ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRows;
    final totalAmount = filtered.fold<double>(
      0,
      (sum, row) => sum + (double.tryParse(row.amount ?? '0') ?? 0),
    );
    final isMobile = MediaQuery.of(context).size.width < 930;

    return DashboardPageShell(
      title: 'المصروفات',
      subtitle: 'إدارة المصروفات اليومية مع إمكانية التعديل والتحليل اللحظي.',
      icon: Icons.wallet_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetch,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton.filled(
          onPressed: _openAddExpense,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'عدد المصروفات',
          value: '${filtered.length}',
          icon: Icons.receipt_long_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'إجمالي المصروف',
          value: '${_money(totalAmount)} SAR',
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
                hintText: 'ابحث بعنوان المصروف أو التاريخ أو رقم السجل',
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
              title: 'لا توجد مصروفات',
              subtitle: 'ابدأ بإضافة أول مصروف ليظهر هنا.',
              icon: Icons.wallet_outlined,
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = filtered[index];
                return _ExpenseCard(
                  row: row,
                  onEdit: () => _showEditDialog(row),
                  onDelete: () => _deleteExpense(row),
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
                    DataColumn(label: Text('رقم')),
                    DataColumn(label: Text('العنوان')),
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('المبلغ')),
                    DataColumn(label: Text('إجراء')),
                  ],
                  rows: filtered.map((row) {
                    return DataRow(cells: [
                      DataCell(Text(row.expenseId ?? '-')),
                      DataCell(SizedBox(
                        width: 280,
                        child: Text(
                          row.expenseTitle ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(Text(row.expenseDate ?? '-')),
                      DataCell(Text('${_money(double.tryParse(row.amount ?? '0') ?? 0)} SAR')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _showEditDialog(row),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            onPressed: () => _deleteExpense(row),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          ),
                        ],
                      )),
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

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseModel row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(row.amount ?? '0') ?? 0;
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.expenseTitle ?? '-',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row.expenseDate ?? '-',
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            '${_money(amount)} SAR',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
