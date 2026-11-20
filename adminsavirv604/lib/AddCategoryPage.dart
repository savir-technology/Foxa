// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/model/AddSection_model.dart';
import 'package:admin_tks/remote/AddSection_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSaving = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nameArController.clear();
      _nameEnController.clear();
      _imageBytes = null;
      _imageName = null;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) {
      return;
    }

    setState(() {
      _imageBytes = file.bytes!;
      _imageName = file.name;
    });
  }

  Future<void> _saveCategory() async {
    if (_isSaving) return;
    if (!_auth.isMaster) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_imageBytes == null) {
      _showSnackBar('أضف صورة للقسم قبل الحفظ');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await SectionData().uploadSection(
        SectionModel(
          arabicName: _nameArController.text.trim(),
          englishName: _nameEnController.text.trim(),
          imageBase64: base64Encode(_imageBytes!),
        ),
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (success) {
        _showSnackBar('تمت إضافة القسم بنجاح');
        Navigator.pop(context, true);
      } else {
        _showSnackBar('تعذر حفظ القسم، حاول مرة أخرى');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('تعذر حفظ القسم، تحقق من الاتصال ثم أعد المحاولة');
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPreviewCard() {
    final hasImage = _imageBytes != null;

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'معاينة القسم',
            subtitle: 'تظهر هنا النتيجة النهائية قبل الحفظ.',
            icon: Icons.visibility_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: kSurfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kStroke),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : const _CategoryImagePlaceholder(),
          ),
          const SizedBox(height: 16),
          Text(
            _nameArController.text.trim().isEmpty
                ? 'اسم القسم بالعربية'
                : _nameArController.text.trim(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _nameEnController.text.trim().isEmpty
                ? 'Category name in English'
                : _nameEnController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              const _PreviewChip(
                icon: Icons.language_rounded,
                label: 'ثنائي اللغة',
              ),
              _PreviewChip(
                icon: Icons.image_rounded,
                label: hasImage ? 'صورة مرفقة' : 'لا توجد صورة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return DashboardPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'بيانات القسم',
              subtitle: 'أدخل الاسم العربي والإنجليزي ثم أرفق صورة واضحة.',
              icon: Icons.category_rounded,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 680;
                final fieldWidth = isWide
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _nameArController,
                        onChanged: (_) => setState(() {}),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'اسم القسم بالعربية مطلوب'
                                : null,
                        decoration: _fieldDecoration(
                          label: 'اسم القسم بالعربية',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _nameEnController,
                        onChanged: (_) => setState(() {}),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'اسم القسم بالإنجليزية مطلوب'
                                : null,
                        decoration: _fieldDecoration(
                          label: 'اسم القسم بالإنجليزية',
                          hintText: 'اختياري للمظهر ثنائي اللغة',
                          icon: Icons.translate_rounded,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _ImagePickerCard(
              imageBytes: _imageBytes,
              imageName: _imageName,
              onPick: _pickImage,
              onClear: () {
                setState(() {
                  _imageBytes = null;
                  _imageName = null;
                });
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('تفريغ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveCategory,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'جاري الحفظ' : 'حفظ القسم'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManageCategories = _auth.isMaster;
    final isReady = _nameArController.text.trim().isNotEmpty &&
        _nameEnController.text.trim().isNotEmpty &&
        _imageBytes != null;

    if (!canManageCategories) {
      return DashboardPageShell(
        title: 'إضافة قسم',
        subtitle: 'إدارة الأقسام متاحة للماستر فقط. يمكنك استعراض الأقسام من لوحة المطعم.',
        icon: Icons.lock_rounded,
        actions: const [],
        body: const DashboardEmptyState(
          title: 'هذه الصفحة محمية',
          subtitle:
              'إضافة الأقسام وحذفها متاحان فقط للماستر. لوحة المطعم هنا للعرض واختيار القسم الصحيح عند إضافة المنتج.',
          icon: Icons.admin_panel_settings_outlined,
        ),
      );
    }

    return DashboardPageShell(
      title: 'إضافة قسم',
      subtitle: 'أنشئ قسماً واضحاً ومنظماً يظهر مباشرة داخل قائمة المطعم.',
      icon: Icons.category_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _resetForm,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveCategory,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'جاري الحفظ' : 'حفظ القسم'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'الاسم العربي',
          value: _nameArController.text.trim().isEmpty ? 'فارغ' : 'مكتمل',
          icon: Icons.edit_note_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'الاسم الإنجليزي',
          value: _nameEnController.text.trim().isEmpty ? 'فارغ' : 'مكتمل',
          icon: Icons.translate_rounded,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'الصورة',
          value: _imageBytes == null ? 'غير مرفقة' : 'مرفقة',
          icon: Icons.image_rounded,
          tint: kAccent,
        ),
        DashboardStatCard(
          label: 'جاهزية الحفظ',
          value: isReady ? 'جاهز' : 'يحتاج بيانات',
          icon: Icons.task_alt_rounded,
          tint: isReady ? kAccent : const Color(0xFFF59E0B),
        ),
      ],
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildFormCard()),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: _buildPreviewCard()),
                  ],
                );
              }

              return Column(
                children: [
                  _buildPreviewCard(),
                  const SizedBox(height: 18),
                  _buildFormCard(),
                ],
              );
            },
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: kPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imageBytes,
    required this.imageName,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'صورة القسم',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_rounded),
                label: Text(hasImage ? 'تغيير الصورة' : 'اختيار صورة'),
              ),
              const SizedBox(width: 8),
              if (hasImage)
                TextButton(
                  onPressed: onClear,
                  child: const Text('إزالة'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 190,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kStroke),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : const _CategoryImagePlaceholder(),
          ),
          if (imageName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              imageName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryImagePlaceholder extends StatelessWidget {
  const _CategoryImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F7F3), Color(0xFFE8F2EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_rounded, size: 44, color: kPrimary),
          SizedBox(height: 10),
          Text(
            'ارفع صورة واضحة للقسم',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'تظهر الصورة داخل القائمة وفي التطبيق للمستخدم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
