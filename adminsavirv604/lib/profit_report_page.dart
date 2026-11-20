import 'package:admin_tks/model/report_models.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class ProfitReportPage extends StatefulWidget {
  const ProfitReportPage({super.key});

  @override
  State<ProfitReportPage> createState() => _ProfitReportPageState();
}

class _ProfitReportPageState extends State<ProfitReportPage> {
  final AccountingData api = AccountingData();
  ProfitReport? report;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => loading = true);
    final res = await api.getProfitReport();
    if (!mounted) return;
    setState(() {
      report = res;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = report;
    final netColor = (r?.netProfit ?? 0) >= 0 ? Colors.green : Colors.redAccent;

    return DashboardPageShell(
      title: 'الأرباح والخسائر',
      subtitle: 'تحليل مالي احترافي يشمل الإيراد والمصروفات والهالك والمخزون.',
      icon: Icons.pie_chart_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetch,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'إجمالي الإيراد',
          value: '${_money(r?.totalRevenue ?? 0)} SAR',
          icon: Icons.trending_up_rounded,
          tint: Colors.green,
        ),
        DashboardStatCard(
          label: 'إجمالي المصروفات',
          value: '${_money(r?.totalExpenses ?? 0)} SAR',
          icon: Icons.trending_down_rounded,
          tint: Colors.redAccent,
        ),
        DashboardStatCard(
          label: 'تكلفة الهالك',
          value: '${_money(r?.totalWasteCost ?? 0)} SAR',
          icon: Icons.delete_sweep_rounded,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'صافي الربح',
          value: '${_money(r?.netProfit ?? 0)} SAR',
          icon: Icons.account_balance_wallet_rounded,
          tint: netColor,
        ),
      ],
      body: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: CircularProgressIndicator(color: kPrimary),
            )
          : r == null
              ? const DashboardEmptyState(
                  title: 'لا توجد بيانات مالية',
                  subtitle: 'تأكد من وجود قيود ومبيعات ومصروفات لعرض التقرير.',
                  icon: Icons.assessment_outlined,
                )
              : Column(
                  children: [
                    DashboardPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الملخص المالي',
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _FinancialLine(
                            title: 'إجمالي الإيراد',
                            amount: r.totalRevenue,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _FinancialLine(
                            title: 'إجمالي المصروفات',
                            amount: r.totalExpenses,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 8),
                          _FinancialLine(
                            title: 'تكلفة الهالك',
                            amount: r.totalWasteCost,
                            color: kSecondary,
                          ),
                          const Divider(height: 24),
                          _FinancialLine(
                            title: 'صافي الربح',
                            amount: r.netProfit,
                            color: netColor,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DashboardPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'وضع المخزون الحالي',
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _InventoryMetric(
                                  title: 'إجمالي الوحدات',
                                  value: '${r.inventoryUnits}',
                                  icon: Icons.inventory_2_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InventoryMetric(
                                  title: 'قيمة المخزون',
                                  value: '${_money(r.inventoryValue)} SAR',
                                  icon: Icons.savings_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FinancialLine extends StatelessWidget {
  const _FinancialLine({
    required this.title,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String title;
  final double amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${_money(amount)} SAR',
          style: TextStyle(
            color: color,
            fontSize: bold ? 18 : 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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

String _money(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
