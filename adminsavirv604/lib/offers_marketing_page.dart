import 'package:admin_tks/model/coupon_model.dart';
import 'package:admin_tks/remote/coupon_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OffersMarketingPage extends StatefulWidget {
  const OffersMarketingPage({super.key});

  @override
  State<OffersMarketingPage> createState() => _OffersMarketingPageState();
}

class _OffersMarketingPageState extends State<OffersMarketingPage> {
  final CouponData _data = CouponData();

  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '20');
  final TextEditingController _usesCtrl = TextEditingController(text: '100');
  final TextEditingController _minimumOrderCtrl =
      TextEditingController(text: '20000');
  final TextEditingController _conditionsCtrl = TextEditingController(
    text: 'يسري العرض على جميع الطلبات عبر التطبيق.',
  );

  List<CouponModel> _coupons = const [];
  bool _loading = true;
  bool _saving = false;
  String _offerType = 'percent';
  String _applicableOn = 'all';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  CouponModel? _editing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _usesCtrl.dispose();
    _minimumOrderCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final coupons = await _data.fetchCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = coupons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل العروض: $e')),
      );
    }
  }

  void _fillFromCoupon(CouponModel coupon) {
    setState(() {
      _editing = coupon;
      _codeCtrl.text = coupon.couponName;
      _discountCtrl.text = coupon.couponDiscount.toString();
      _usesCtrl.text = coupon.couponCount.toString();
      _startDate = DateTime.now();
      _endDate = coupon.couponExpireDate;
      _offerType = 'percent';
      _applicableOn = 'all';
    });
  }

  void _resetForm() {
    setState(() {
      _editing = null;
      _codeCtrl.clear();
      _discountCtrl.text = '20';
      _usesCtrl.text = '100';
      _minimumOrderCtrl.text = '20000';
      _conditionsCtrl.text = 'يسري العرض على جميع الطلبات عبر التطبيق.';
      _offerType = 'percent';
      _applicableOn = 'all';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 14));
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 14));
        }
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(days: 14));
        }
      }
    });
  }

  Future<void> _saveCoupon() async {
    if (_saving) return;

    final code = _codeCtrl.text.trim();
    final discount = int.tryParse(_discountCtrl.text.trim()) ?? 0;
    final uses = int.tryParse(_usesCtrl.text.trim()) ?? 0;
    if (code.isEmpty || discount <= 0 || uses <= 0) {
      Get.snackbar(
        'العروض والتسويق',
        'أكمل بيانات العرض بشكل صحيح أولًا.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _saving = true);
    final message = await _data.saveCoupon(
      couponId: _editing?.couponId,
      couponName: code,
      couponCount: uses,
      couponExpireDate: _endDate,
      couponDiscount: discount,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Get.snackbar(
      'العروض والتسويق',
      message ?? 'تعذر حفظ العرض',
      snackPosition: SnackPosition.BOTTOM,
    );

    _resetForm();
    await _load();
  }

  Future<void> _deleteCoupon(CouponModel coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العرض'),
        content: Text('هل تريد حذف "${coupon.couponName}"؟'),
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
    Get.snackbar(
      'العروض والتسويق',
      message ?? 'تعذر حذف العرض',
      snackPosition: SnackPosition.BOTTOM,
    );
    await _load();
  }

  double get _averageDiscount {
    if (_coupons.isEmpty) return 0;
    return _coupons.fold<double>(0, (sum, item) => sum + item.couponDiscount) /
        _coupons.length;
  }

  int get _activeCount => _coupons.where((item) => item.isActive).length;

  int get _expiringSoon => _coupons.where((item) => item.isExpiringSoon).length;

  int get _remainingUses =>
      _coupons.fold<int>(0, (sum, item) => sum + item.couponCount);

  @override
  Widget build(BuildContext context) {
    final previewCode = _codeCtrl.text.trim().isEmpty
        ? 'RAMADAN20'
        : _codeCtrl.text.trim();
    final previewDiscount = _discountCtrl.text.trim().isEmpty
        ? '20'
        : _discountCtrl.text.trim();
    final previewUses = int.tryParse(_usesCtrl.text.trim()) ?? 0;

    return DashboardPageShell(
      title: 'العروض والتسويق',
      subtitle: 'إنشاء وإدارة العروض والكوبونات من شاشة واحدة.',
      icon: Icons.local_offer_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _saveCoupon,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'جاري الحفظ' : 'حفظ العرض'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'كل العروض',
          value: '${_coupons.length}',
          icon: Icons.local_offer_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'النشطة',
          value: '$_activeCount',
          icon: Icons.verified_rounded,
          tint: const Color(0xFF16A34A),
        ),
        DashboardStatCard(
          label: 'قريبة الانتهاء',
          value: '$_expiringSoon',
          icon: Icons.schedule_rounded,
          tint: const Color(0xFFF59E0B),
        ),
        DashboardStatCard(
          label: 'متوسط الخصم',
          value: '${_averageDiscount.toStringAsFixed(0)}%',
          icon: Icons.percent_rounded,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;

                    final formPanel = DashboardPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: _editing == null ? 'إضافة عرض جديد' : 'تعديل العرض',
                            subtitle:
                                'استخدم الحقول الأساسية للحفظ في قاعدة البيانات مع معاينة إضافية على اليمين.',
                            icon: Icons.edit_note_rounded,
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            initialValue: _offerType,
                            decoration: const InputDecoration(
                              labelText: 'نوع العرض',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'percent',
                                child: Text('خصم نسبة'),
                              ),
                              DropdownMenuItem(
                                value: 'free_delivery',
                                child: Text('توصيل مجاني'),
                              ),
                              DropdownMenuItem(
                                value: 'bundle',
                                child: Text('اشترِ 2 واحصل على 1'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _offerType = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _discountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'نسبة الخصم',
                                    suffixIcon: Icon(Icons.percent_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _minimumOrderCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'الحد الأدنى للشراء',
                                    suffixText: 'SAR',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _usesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'عدد مرات الاستخدام',
                                    prefixIcon: Icon(Icons.replay_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _applicableOn,
                                  decoration: const InputDecoration(
                                    labelText: 'احصل على',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('مجاني'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Text('طلبات جديدة'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'vip',
                                      child: Text('عملاء مميزون'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _applicableOn = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رمز الكوبون',
                              prefixIcon: Icon(Icons.confirmation_number_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: 'تاريخ البداية',
                                  value: _shortDate(_startDate),
                                  onTap: () => _pickDate(isStart: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateField(
                                  label: 'تاريخ النهاية',
                                  value: _shortDate(_endDate),
                                  onTap: () => _pickDate(isStart: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _conditionsCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'شروط العرض',
                              hintText: 'مثال: يسري العرض على جميع الطلبات عبر التطبيق',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _resetForm,
                                  child: const Text('إلغاء'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _saving ? null : _saveCoupon,
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text('حفظ العرض'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final previewPanel = DashboardPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'معاينة العرض',
                            subtitle: 'كيف سيظهر العرض داخل التطبيق للعملاء.',
                            icon: Icons.visibility_rounded,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F7A3D), Color(0xFF165A31)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'خصم ${previewDiscount}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _offerType == 'free_delivery'
                                      ? 'توصيل مجاني على جميع الطلبات'
                                      : _offerType == 'bundle'
                                          ? 'اشترِ 2 واحصل على 1 مجاناً'
                                          : 'على جميع الطلبات',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.24),
                                    ),
                                  ),
                                  child: Text(
                                    previewCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _PreviewRow(
                            label: 'تاريخ البداية',
                            value: _shortDate(_startDate),
                          ),
                          _PreviewRow(
                            label: 'تاريخ النهاية',
                            value: _shortDate(_endDate),
                          ),
                          _PreviewRow(
                            label: 'الحد الأدنى للشراء',
                            value: '${_minimumOrderCtrl.text.trim()} SAR',
                          ),
                          _PreviewRow(
                            label: 'مرات الاستخدام',
                            value: previewUses.toString(),
                          ),
                          _PreviewRow(
                            label: 'الحالة',
                            value: _editing?.statusLabelAr ?? 'نشط',
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF7EB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.18)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: Color(0xFFD97706)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'الحفظ الفعلي يعتمد على رمز العرض والنسبة وعدد الاستخدامات وتاريخ الانتهاء.',
                                    style: TextStyle(
                                      color: kTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          previewPanel,
                          const SizedBox(height: 16),
                          formPanel,
                          const SizedBox(height: 16),
                          _CouponsList(
                            coupons: _coupons,
                            onEdit: _fillFromCoupon,
                            onDelete: _deleteCoupon,
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: formPanel),
                            const SizedBox(width: 16),
                            Expanded(child: previewPanel),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _CouponsList(
                          coupons: _coupons,
                          onEdit: _fillFromCoupon,
                          onDelete: _deleteCoupon,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _CouponsList extends StatelessWidget {
  const _CouponsList({
    required this.coupons,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CouponModel> coupons;
  final ValueChanged<CouponModel> onEdit;
  final ValueChanged<CouponModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return const DashboardEmptyState(
        title: 'لا توجد عروض حتى الآن',
        subtitle: 'أضف أول عرض ليظهر هنا داخل الجدول.',
        icon: Icons.local_offer_outlined,
      );
    }

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'قائمة العروض',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateColor.resolveWith(
                (states) => kSurfaceElevated,
              ),
              columns: const [
                DataColumn(label: Text('العرض')),
                DataColumn(label: Text('الكوبون')),
                DataColumn(label: Text('الخصم')),
                DataColumn(label: Text('الاستخدامات')),
                DataColumn(label: Text('الانتهاء')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: coupons.map((coupon) {
                final statusColor = coupon.isActive
                    ? const Color(0xFF16A34A)
                    : coupon.isExpiringSoon
                        ? const Color(0xFFF59E0B)
                        : Colors.redAccent;
                return DataRow(
                  cells: [
                    DataCell(Text(_offerLabel(coupon))),
                    DataCell(Text(coupon.couponName)),
                    DataCell(Text('${coupon.couponDiscount}%')),
                    DataCell(Text(coupon.couponCount.toString())),
                    DataCell(Text(_formatCouponDate(coupon.couponExpireDate))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          coupon.statusLabelAr,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => onEdit(coupon),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            onPressed: () => onDelete(coupon),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
              fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: kTextSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.date_range_rounded),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _shortDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year/$month/$day';
}

String _formatCouponDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _offerLabel(CouponModel coupon) {
  if (coupon.couponDiscount >= 100) {
    return 'هدية مجانية';
  }
  if (coupon.couponDiscount >= 20) {
    return 'خصم ${coupon.couponDiscount}% على جميع الطلبات';
  }
  return 'عرض خاص';
}
