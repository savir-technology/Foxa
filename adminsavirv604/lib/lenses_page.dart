import 'package:admin_tks/model/lens_model.dart';
import 'package:admin_tks/remote/lenses_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';
import 'package:flutter/material.dart';

class LensesPage extends StatefulWidget {
  const LensesPage({super.key});

  @override
  State<LensesPage> createState() => _LensesPageState();
}

class _LensesPageState extends State<LensesPage> {
  final LensesData api = LensesData();
  List<LensModel> lenses = [];
  bool loading = true;

  static const List<Map<String, String>> _lensColors = [
    {'label': 'شفاف', 'value': 'clear'},
    {'label': 'أزرق', 'value': 'blue'},
    {'label': 'أخضر', 'value': 'green'},
    {'label': 'بني', 'value': 'brown'},
    {'label': 'رمادي', 'value': 'gray'},
    {'label': 'عسلي', 'value': 'hazel'},
    {'label': 'تركواز', 'value': 'turquoise'},
    {'label': 'بنفسجي', 'value': 'violet'},
  ];

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => loading = true);
    final result = await api.getLenses();
    if (!mounted) return;
    setState(() {
      lenses = result;
      loading = false;
    });
  }

  Future<void> _openLensDialog({LensModel? lens}) async {
    final code = TextEditingController(text: lens?.lensCode ?? '');
    final nameAr = TextEditingController(text: lens?.lensNameAr ?? '');
    final nameEn = TextEditingController(text: lens?.lensNameEn ?? '');
    final type = TextEditingController(text: lens?.lensType ?? '');
    final price = TextEditingController(text: lens?.lensPrice ?? '');
    final featuresAr = TextEditingController(text: lens?.lensFeaturesAr ?? '');
    final featuresEn = TextEditingController(text: lens?.lensFeaturesEn ?? '');
    final priorityLight =
        TextEditingController(text: lens?.priorityLight ?? '99');
    final priorityMedium =
        TextEditingController(text: lens?.priorityMedium ?? '99');
    final priorityHigh =
        TextEditingController(text: lens?.priorityHigh ?? '99');
    String selectedColor = _lensColors.any(
      (entry) => entry['value'] == lens?.lensColor,
    )
        ? lens!.lensColor!
        : _lensColors.first['value']!;
    bool isActive = lens?.isActive != '0';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(18),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lens == null ? 'إضافة عدسة جديدة' : 'تعديل العدسة',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أدخل بيانات العدسة بشكل منظم وحدد اللون بسهولة من القائمة.',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _field(code, 'الكود'),
                    _field(nameAr, 'الاسم بالعربي'),
                    _field(nameEn, 'الاسم بالإنجليزي'),
                    _field(type, 'النوع'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedColor,
                        decoration: const InputDecoration(
                          labelText: 'اللون',
                        ),
                        items: _lensColors.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry['value'],
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _colorPreview(entry['value']!),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(entry['label']!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedColor = value);
                        },
                      ),
                    ),
                    _field(price, 'السعر', TextInputType.number),
                    _field(featuresAr, 'التفاصيل بالعربي', TextInputType.multiline, 3),
                    _field(featuresEn, 'التفاصيل بالإنجليزي', TextInputType.multiline, 3),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            priorityLight,
                            'أولوية الخفيف',
                            TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            priorityMedium,
                            'أولوية المتوسط',
                            TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            priorityHigh,
                            'أولوية العالي',
                            TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kSurfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kStroke),
                      ),
                      child: SwitchListTile(
                        value: isActive,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: const Text(
                          'العدسة مفعلة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        onChanged: (value) => setLocalState(() => isActive = value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: saving ? null : () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (code.text.trim().isEmpty ||
                                      nameAr.text.trim().isEmpty ||
                                      price.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('املأ الكود والاسم والسعر'),
                                      ),
                                    );
                                    return;
                                  }

                                  setLocalState(() => saving = true);
                                  final payload = LensModel(
                                    lensId: lens?.lensId,
                                    lensCode: code.text.trim(),
                                    lensNameAr: nameAr.text.trim(),
                                    lensNameEn: nameEn.text.trim(),
                                    lensType: type.text.trim(),
                                    lensColor: selectedColor,
                                    lensPrice: price.text.trim(),
                                    lensFeaturesAr: featuresAr.text.trim(),
                                    lensFeaturesEn: featuresEn.text.trim(),
                                    priorityLight: priorityLight.text.trim(),
                                    priorityMedium: priorityMedium.text.trim(),
                                    priorityHigh: priorityHigh.text.trim(),
                                    isActive: isActive ? '1' : '0',
                                  );

                                  final success = lens == null
                                      ? await api.addLens(payload)
                                      : await api.updateLens(payload);
                                  if (!mounted) return;
                                  setLocalState(() => saving = false);

                                  if (success) {
                                    Navigator.pop(context);
                                    fetch();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('فشل حفظ العدسة'),
                                      ),
                                    );
                                  }
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
                              : Icon(lens == null ? Icons.add : Icons.save),
                          label: Text(lens == null ? 'إضافة العدسة' : 'حفظ التعديل'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, [
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  String _colorLabel(String? value) {
    for (final entry in _lensColors) {
      if (entry['value'] == value) return entry['label']!;
    }
    return value?.isNotEmpty == true ? value! : '-';
  }

  Color _colorPreview(String value) {
    switch (value) {
      case 'blue':
        return const Color(0xFF2563EB);
      case 'green':
        return const Color(0xFF16A34A);
      case 'brown':
        return const Color(0xFF8B5E3C);
      case 'gray':
        return const Color(0xFF6B7280);
      case 'hazel':
        return const Color(0xFFB7791F);
      case 'turquoise':
        return const Color(0xFF14B8A6);
      case 'violet':
        return const Color(0xFF7C3AED);
      case 'clear':
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Future<void> _deleteLens(LensModel lens) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف العدسة'),
            content: Text(
              'هل تريد حذف العدسة "${lens.lensNameAr ?? lens.lensCode ?? ''}"؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await api.deleteLens(lens.lensId ?? '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'تم حذف العدسة' : 'فشل حذف العدسة')),
    );
    if (success) fetch();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 760;

    return Scaffold(
      backgroundColor: kBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kSurface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: kStroke),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'إدارة العدسات',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kTextPrimary,
                                    fontSize: isPhone ? 20 : 24,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'إضافة وتنظيم أسعار وألوان وأنواع العدسات بسهولة أكبر.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: fetch,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                              IconButton(
                                onPressed: () => _openLensDialog(),
                                icon: const Icon(Icons.add_circle_outline_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _GlassesBanner(isCompact: isPhone),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricPill(
                            label: 'إجمالي العدسات',
                            value: lenses.length.toString(),
                          ),
                          _MetricPill(
                            label: 'العدسات المفعلة',
                            value: lenses.where((e) => e.isActive != '0').length.toString(),
                          ),
                          _MetricPill(
                            label: 'ألوان متاحة',
                            value: _lensColors.length.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimary),
                      )
                    : lenses.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              margin: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: kGlass,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: kStroke),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 42,
                                    color: kPrimary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'لا توجد عدسات مضافة حتى الآن',
                                    style: TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: lenses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final lens = lenses[index];
                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: kSurface.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: kStroke),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: isPhone
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _LensHeader(
                                            lens: lens,
                                            colorLabel: _colorLabel(lens.lensColor),
                                            colorPreview: _colorPreview(
                                              lens.lensColor ?? 'clear',
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          _LensMeta(lens: lens),
                                          const SizedBox(height: 14),
                                          _LensActions(
                                            lens: lens,
                                            onEdit: () => _openLensDialog(lens: lens),
                                            onDelete: () => _deleteLens(lens),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _LensHeader(
                                                  lens: lens,
                                                  colorLabel: _colorLabel(
                                                    lens.lensColor,
                                                  ),
                                                  colorPreview: _colorPreview(
                                                    lens.lensColor ?? 'clear',
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                _LensMeta(lens: lens),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          _LensActions(
                                            lens: lens,
                                            onEdit: () => _openLensDialog(lens: lens),
                                            onDelete: () => _deleteLens(lens),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassesBanner extends StatelessWidget {
  final bool isCompact;

  const _GlassesBanner({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? double.infinity : 360,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LensCircle(size: 42, color: Color(0xFFBFDBFE)),
          Container(
            width: 26,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const _LensCircle(size: 42, color: Color(0xFFBFDBFE)),
        ],
      ),
    );
  }
}

class _LensPreviewBadge extends StatelessWidget {
  final Color colorPreview;

  const _LensPreviewBadge({required this.colorPreview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LensCircle(size: 34, color: colorPreview),
          Container(
            width: 18,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          _LensCircle(size: 34, color: colorPreview),
        ],
      ),
    );
  }
}

class _LensCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _LensCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF64748B).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _LensHeader extends StatelessWidget {
  final LensModel lens;
  final String colorLabel;
  final Color colorPreview;

  const _LensHeader({
    required this.lens,
    required this.colorLabel,
    required this.colorPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LensPreviewBadge(colorPreview: colorPreview),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lens.lensNameAr ?? lens.lensCode ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lens.lensNameEn?.isNotEmpty == true ? lens.lensNameEn! : '-',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorPreview.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            colorLabel,
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: lens.isActive != '0'
                ? Colors.green.withValues(alpha: 0.12)
                : Colors.red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            lens.isActive != '0' ? 'مفعلة' : 'غير مفعلة',
            style: TextStyle(
              color: lens.isActive != '0' ? Colors.green : Colors.redAccent,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }
}

class _LensMeta extends StatelessWidget {
  final LensModel lens;

  const _LensMeta({required this.lens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الكود: ${lens.lensCode ?? '-'}  |  النوع: ${lens.lensType ?? '-'}',
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Light: ${lens.priorityLight ?? '99'}  |  Medium: ${lens.priorityMedium ?? '99'}  |  High: ${lens.priorityHigh ?? '99'}',
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          lens.lensFeaturesAr?.isNotEmpty == true
              ? lens.lensFeaturesAr!
              : (lens.lensFeaturesEn ?? ''),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 14,
            height: 1.45,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _LensActions extends StatelessWidget {
  final LensModel lens;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LensActions({
    required this.lens,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${lens.lensPrice ?? '0'} SAR',
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('تعديل'),
            ),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('حذف'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
