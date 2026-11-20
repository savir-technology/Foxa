import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final AccountingData api = AccountingData();
  bool submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => submitting = true);
    final ok = await api.addExpense(_title.text.trim(), _amount.text.trim());
    if (!mounted) return;
    setState(() => submitting = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إضافة المصروف')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardPageShell(
      title: 'إضافة مصروف',
      subtitle: 'تسجيل مصروف جديد ليظهر مباشرة في التقارير المالية.',
      icon: Icons.add_card_rounded,
      body: DashboardPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'بيانات المصروف',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'عنوان المصروف',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'العنوان مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                  final amount = double.tryParse(v.trim());
                  if (amount == null || amount <= 0) {
                    return 'أدخل مبلغًا صحيحًا';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(submitting ? 'جارٍ الحفظ...' : 'حفظ المصروف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

