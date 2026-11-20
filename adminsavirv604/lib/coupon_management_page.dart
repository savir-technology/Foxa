import 'package:admin_tks/model/coupon_model.dart';
import 'package:admin_tks/remote/coupon_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CouponManagementPage extends StatefulWidget {
  const CouponManagementPage({super.key});

  @override
  State<CouponManagementPage> createState() => _CouponManagementPageState();
}

class _CouponManagementPageState extends State<CouponManagementPage> {
  final CouponData _data = CouponData();

  List<CouponModel> _coupons = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final coupons = await _data.fetchCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = coupons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    Get.snackbar(
      'Roaq',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.82),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _openEditor({CouponModel? coupon}) async {
    final codeCtrl = TextEditingController(text: coupon?.couponName ?? '');
    final discountCtrl =
        TextEditingController(text: coupon?.couponDiscount.toString() ?? '10');
    final countCtrl =
        TextEditingController(text: coupon?.couponCount.toString() ?? '100');
    DateTime selectedExpiry = coupon?.couponExpireDate ??
        DateTime.now().add(const Duration(days: 30));
    bool saving = false;

    Future<void> pickExpiry(StateSetter setModalState) async {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedExpiry,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      );
      if (date == null || !mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedExpiry),
      );
      if (time == null || !mounted) return;

      setModalState(() {
        selectedExpiry = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceElevated,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon == null ? 'إضافة كوبون' : 'تعديل كوبون',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رمز الكوبون',
                    prefixIcon: Icon(Icons.confirmation_number_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'نسبة الخصم %',
                          prefixIcon: Icon(Icons.percent_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: countCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد الاستخدامات',
                          prefixIcon: Icon(Icons.countertops_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => pickExpiry(setModalState),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.76),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kStroke),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded,
                            color: kPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تاريخ الانتهاء: ${_formatDateTime(selectedExpiry)}',
                            style: const TextStyle(color: kTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final code = codeCtrl.text.trim();
                            final discount =
                                int.tryParse(discountCtrl.text.trim()) ?? 0;
                            final count =
                                int.tryParse(countCtrl.text.trim()) ?? 0;
                            if (code.isEmpty || discount <= 0 || count <= 0) {
                              _showSnack('أكمل بيانات الكوبون بشكل صحيح');
                              return;
                            }
                            setModalState(() => saving = true);
                            final message = await _data.saveCoupon(
                              couponId: coupon?.couponId,
                              couponName: code,
                              couponCount: count,
                              couponExpireDate: selectedExpiry,
                              couponDiscount: discount,
                            );
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            _showSnack(message ?? 'تعذر حفظ الكوبون');
                            await _load();
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(saving ? 'جارٍ الحفظ' : 'حفظ الكوبون'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    codeCtrl.dispose();
    discountCtrl.dispose();
    countCtrl.dispose();
  }

  Future<void> _deleteCoupon(CouponModel coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكوبون'),
        content: Text('هل تريد حذف كوبون "${coupon.couponName}"؟'),
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

    final message = await _data.deleteCoupon(coupon.couponId);
    if (!mounted) return;
    _showSnack(message ?? 'تعذر حذف الكوبون');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _coupons.where((coupon) => coupon.isActive).length;
    final expiringSoon =
        _coupons.where((coupon) => coupon.isExpiringSoon).length;
    final totalRemaining = _coupons.fold<int>(
      0,
      (sum, coupon) => sum + coupon.couponCount,
    );

    return DashboardPageShell(
      title: 'العروض والكوبونات',
      subtitle: 'إدارة الكوبونات والخصومات من نفس الواجهة.',
      icon: Icons.local_offer_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة كوبون'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'كل الكوبونات',
          value: '${_coupons.length}',
          icon: Icons.confirmation_number_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'النشطة',
          value: '$activeCount',
          icon: Icons.verified_rounded,
          tint: kAccent,
        ),
        DashboardStatCard(
          label: 'قريبة الانتهاء',
          value: '$expiringSoon',
          icon: Icons.schedule_rounded,
          tint: const Color(0xFFF59E0B),
        ),
        DashboardStatCard(
          label: 'إجمالي الاستخدامات',
          value: '$totalRemaining',
          icon: Icons.countertops_rounded,
          tint: const Color(0xFF14B8A6),
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(
                child: CircularProgressIndicator(color: kPrimary),
              ),
            )
          : _error != null
              ? DashboardEmptyState(
                  title: 'تعذر تحميل الكوبونات',
                  subtitle: _error!,
                  icon: Icons.cloud_off_rounded,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardPanel(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ActionTile(
                            title: 'إضافة كوبون',
                            subtitle:
                                'خصم نسبة أو حملات محدودة أو أكواد موسمية',
                            icon: Icons.add_card_rounded,
                            color: kPrimary,
                            onTap: () => _openEditor(),
                          ),
                          _ActionTile(
                            title: 'تحديث البيانات',
                            subtitle: 'إعادة تحميل الكوبونات من الخادم',
                            icon: Icons.refresh_rounded,
                            color: const Color(0xFF14B8A6),
                            onTap: _load,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_coupons.isEmpty)
                      const DashboardEmptyState(
                        title: 'لا توجد كوبونات حتى الآن',
                        subtitle: 'أضف أول كوبون لتظهر العروض داخل التطبيق.',
                        icon: Icons.local_offer_outlined,
                      )
                    else
                      DashboardPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'قائمة الكوبونات',
                              style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._coupons.map(
                              (coupon) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CouponCard(
                                  coupon: coupon,
                                  onEdit: () => _openEditor(coupon: coupon),
                                  onDelete: () => _deleteCoupon(coupon),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  final CouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = coupon.isActive
        ? const Color(0xFF10B981)
        : coupon.isExpiringSoon
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_offer_rounded, color: kPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.couponName,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'خصم ${coupon.couponDiscount}% - ${coupon.couponCount} استخدام',
                  style: const TextStyle(color: kTextSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'ينتهي: ${coupon.expiryLabel}',
                  style: const TextStyle(color: kTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  coupon.statusLabelAr,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kStroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
