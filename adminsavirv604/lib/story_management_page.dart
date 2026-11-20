import 'dart:async';
import 'dart:typed_data';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/remote/story_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoryManagementPage extends StatefulWidget {
  const StoryManagementPage({super.key});

  @override
  State<StoryManagementPage> createState() => _StoryManagementPageState();
}

class _StoryManagementPageState extends State<StoryManagementPage> {
  final StoryData _data = StoryData();

  final _vendorIdCtrl = TextEditingController();
  final _titleArCtrl = TextEditingController();
  final _titleEnCtrl = TextEditingController();
  final _ctaLabelArCtrl = TextEditingController();
  final _ctaLabelEnCtrl = TextEditingController();
  final _targetIdCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');
  final _startsAtCtrl = TextEditingController();
  final _endsAtCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _stories = [];
  final List<_VendorChoice> _vendors = [];

  Uint8List? _selectedMediaBytes;
  String? _selectedMediaName;
  String _mediaType = 'image';
  String _targetType = 'restaurant';
  String _searchQuery = '';
  String? _editingId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isActive = true;
  bool _isMaster = false;
  String? _errorMessage;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  bool get _showVendorSelector => _isMaster;

  _VendorChoice? get _selectedVendor {
    final vendorId = _vendorIdCtrl.text.trim();
    if (vendorId.isEmpty) {
      return null;
    }
    for (final vendor in _vendors) {
      if (vendor.id == vendorId) {
        return vendor;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _filteredStories {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _stories;
    }

    return _stories.where((story) {
      final id = story['id']?.toString().toLowerCase() ?? '';
      final titleAr = story['title_ar']?.toString().toLowerCase() ?? '';
      final titleEn = story['title_en']?.toString().toLowerCase() ?? '';
      final vendorName = story['vendor_name']?.toString().toLowerCase() ?? '';
      final storeName = story['store_name']?.toString().toLowerCase() ?? '';
      final targetType = story['target_type']?.toString().toLowerCase() ?? '';
      final targetId = story['target_id']?.toString().toLowerCase() ?? '';
      return id.contains(query) ||
          titleAr.contains(query) ||
          titleEn.contains(query) ||
          vendorName.contains(query) ||
          storeName.contains(query) ||
          targetType.contains(query) ||
          targetId.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _vendorIdCtrl.dispose();
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _ctaLabelArCtrl.dispose();
    _ctaLabelEnCtrl.dispose();
    _targetIdCtrl.dispose();
    _sortOrderCtrl.dispose();
    _startsAtCtrl.dispose();
    _endsAtCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _isMaster = _auth.isMaster;
    if (_showVendorSelector) {
      await _loadVendors();
      if (_vendorIdCtrl.text.trim().isEmpty && _vendors.isNotEmpty) {
        _vendorIdCtrl.text = _vendors.first.id;
      }
    } else {
      _vendorIdCtrl.text = _auth.vendorId > 0 ? _auth.vendorId.toString() : '';
    }

    await _loadStories();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadVendors() async {
    final rows = await _data.getVendors();
    _vendors
      ..clear()
      ..addAll(rows.map(_VendorChoice.fromJson));
  }

  Future<void> _loadStories() async {
    final vendorId = int.tryParse(_vendorIdCtrl.text.trim()) ?? 0;
    final stories = await _data.getStories(
      vendorId: _showVendorSelector ? vendorId : null,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _stories
        ..clear()
        ..addAll(stories);
      _errorMessage = null;
    });
  }

  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingId = null;
      _titleArCtrl.clear();
      _titleEnCtrl.clear();
      _ctaLabelArCtrl.clear();
      _ctaLabelEnCtrl.clear();
      _targetIdCtrl.clear();
      _sortOrderCtrl.text = '0';
      _startsAtCtrl.clear();
      _endsAtCtrl.clear();
      _selectedMediaBytes = null;
      _selectedMediaName = null;
      _mediaType = 'image';
      _targetType = 'restaurant';
      _isActive = true;
    });
  }

  void _startEditing(Map<String, dynamic> story) {
    setState(() {
      _isEditing = true;
      _editingId = story['id']?.toString();
      _vendorIdCtrl.text = story['vendor_id']?.toString() ??
          (_auth.vendorId > 0 ? _auth.vendorId.toString() : '');
      _titleArCtrl.text = story['title_ar']?.toString() ?? '';
      _titleEnCtrl.text = story['title_en']?.toString() ?? '';
      _ctaLabelArCtrl.text = story['cta_label_ar']?.toString() ?? '';
      _ctaLabelEnCtrl.text = story['cta_label_en']?.toString() ?? '';
      _targetIdCtrl.text = story['target_id']?.toString() ?? '';
      _sortOrderCtrl.text = story['sort_order']?.toString() ?? '0';
      _startsAtCtrl.text = story['starts_at']?.toString() ?? '';
      _endsAtCtrl.text = story['ends_at']?.toString() ?? '';
      _mediaType =
          story['media_type']?.toString().trim().toLowerCase() == 'video'
              ? 'video'
              : 'image';
      final rawTargetType =
          story['target_type']?.toString().trim().toLowerCase() ?? '';
      _targetType = rawTargetType == 'product' ? 'product' : 'restaurant';
      _isActive = story['is_active']?.toString() == '1';
      _selectedMediaBytes = null;
      _selectedMediaName = null;
    });
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: _mediaType == 'video' ? FileType.video : FileType.image,
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
      _selectedMediaBytes = file.bytes!;
      _selectedMediaName = file.name;
    });
  }

  Future<void> _submitStory() async {
    if (_isSaving) return;

    final vendorId = int.tryParse(_vendorIdCtrl.text.trim()) ?? 0;
    final targetId = int.tryParse(_targetIdCtrl.text.trim()) ?? 0;
    final sortOrder = _sortOrderCtrl.text.trim().isEmpty
        ? '0'
        : _sortOrderCtrl.text.trim();
    final mediaBytes = _selectedMediaBytes;

    if (vendorId <= 0) {
      _showSnack('اختر المتجر المرتبط بالقصة');
      return;
    }

    if (_titleArCtrl.text.trim().isEmpty) {
      _showSnack('أدخل عنوان القصة بالعربية');
      return;
    }

    if (targetId <= 0) {
      _showSnack('أدخل رقم التوجيه');
      return;
    }

    if (_showVendorSelector && _selectedVendor == null) {
      _showSnack('اختر متجرًا صحيحًا');
      return;
    }

    final creating = !_isEditing;
    if (creating && mediaBytes == null) {
      _showSnack(_mediaType == 'video'
          ? 'اختر فيديو القصة أولًا'
          : 'اختر صورة القصة أولًا');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = _isEditing
          ? await _data.updateStory(
              storyId: _editingId ?? '',
              vendorId: vendorId.toString(),
              titleAr: _titleArCtrl.text.trim(),
              titleEn: _titleEnCtrl.text.trim(),
              mediaType: _mediaType,
              targetType: _targetType,
              targetId: targetId,
              ctaLabelAr: _ctaLabelArCtrl.text.trim(),
              ctaLabelEn: _ctaLabelEnCtrl.text.trim(),
              sortOrder: sortOrder,
              isActive: _isActive,
              startsAt: _startsAtCtrl.text.trim().isEmpty
                  ? null
                  : _startsAtCtrl.text.trim(),
              endsAt: _endsAtCtrl.text.trim().isEmpty
                  ? null
                  : _endsAtCtrl.text.trim(),
              mediaBytes: mediaBytes,
              mediaName: _selectedMediaName,
            )
          : await _data.addStory(
              vendorId: vendorId.toString(),
              titleAr: _titleArCtrl.text.trim(),
              titleEn: _titleEnCtrl.text.trim(),
              mediaType: _mediaType,
              targetType: _targetType,
              targetId: targetId,
              ctaLabelAr: _ctaLabelArCtrl.text.trim(),
              ctaLabelEn: _ctaLabelEnCtrl.text.trim(),
              sortOrder: sortOrder,
              isActive: _isActive,
              startsAt: _startsAtCtrl.text.trim().isEmpty
                  ? null
                  : _startsAtCtrl.text.trim(),
              endsAt: _endsAtCtrl.text.trim().isEmpty
                  ? null
                  : _endsAtCtrl.text.trim(),
              mediaBytes: mediaBytes,
              mediaName: _selectedMediaName,
            );

      if (!mounted) return;

      if (result == null || result['status'] != 'success') {
        _showSnack('تعذر حفظ القصة، حاول مرة أخرى');
        return;
      }

      _showSnack(_isEditing ? 'تم تحديث القصة بنجاح' : 'تمت إضافة القصة بنجاح');
      _resetForm();
      await _loadStories();
    } catch (error) {
      if (!mounted) return;
      _showSnack('فشلت العملية: $error');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteStory(Map<String, dynamic> story) async {
    final storyId = story['id']?.toString() ?? '';
    if (storyId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القصة'),
        content: const Text('هل أنت متأكد من حذف هذه القصة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final success = await _data.deleteStory(storyId);
    if (!mounted) return;

    if (!success) {
      _showSnack('تعذر حذف القصة');
      return;
    }

    if (_editingId == storyId) {
      _resetForm();
    }

    _showSnack('تم حذف القصة بنجاح');
    await _loadStories();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _vendorLabel(_VendorChoice vendor) {
    final label = vendor.label.trim();
    return label.isEmpty ? 'متجر غير معروف' : label;
  }

  String _targetLabel(Map<String, dynamic> story) {
    final targetType = story['target_type']?.toString().toLowerCase() ?? '';
    final targetId = story['target_id']?.toString() ?? '';
    if (targetId.isEmpty) {
      return 'لا توجد وجهة';
    }

    if (targetType == 'product') {
      return 'منتج #$targetId';
    }

    return 'مطعم #$targetId';
  }

  String _mediaLabel(Map<String, dynamic> story) {
    final mediaType = story['media_type']?.toString().toLowerCase() ?? 'image';
    if (mediaType == 'video') {
      return 'فيديو';
    }
    return 'صورة';
  }

  Widget _buildEditorCard() {
    final selectedVendor = _selectedVendor;

    final vendorField = _showVendorSelector
        ? DropdownButtonFormField<String>(
            value: _vendorIdCtrl.text.trim().isEmpty ? null : _vendorIdCtrl.text.trim(),
            decoration: const InputDecoration(
              labelText: 'المتجر',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            items: _vendors
                .map(
                  (vendor) => DropdownMenuItem<String>(
                    value: vendor.id,
                    child: Text(_vendorLabel(vendor)),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() => _vendorIdCtrl.text = value ?? '');
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _resetForm();
                    unawaited(_loadStories());
                  },
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: Color(0xFF1F7A3A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _auth.storeName.isNotEmpty ? _auth.storeName : 'المتجر الحالي',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'تعديل قصة' : 'إضافة قصة جديدة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'التوجيه داخل التطبيق فقط: إلى مطعم محدد أو منتج محدد.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(width: 320, child: vendorField),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _mediaType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوسائط',
                      prefixIcon: Icon(Icons.movie_creation_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'image',
                        child: Text('صورة'),
                      ),
                      DropdownMenuItem(
                        value: 'video',
                        child: Text('فيديو'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _mediaType = value;
                              _selectedMediaBytes = null;
                              _selectedMediaName = null;
                            });
                          },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _targetType,
                    decoration: const InputDecoration(
                      labelText: 'نوع التوجيه',
                      prefixIcon: Icon(Icons.how_to_reg_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'restaurant',
                        child: Text('مطعم'),
                      ),
                      DropdownMenuItem(
                        value: 'product',
                        child: Text('منتج'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _targetType = value);
                          },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _targetIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'رقم التوجيه',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _sortOrderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ترتيب العرض',
                      prefixIcon: Icon(Icons.sort_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isActive = value),
                    title: const Text('نشطة'),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _titleArCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان بالعربية',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _titleEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان بالإنجليزية',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _ctaLabelArCtrl,
                    decoration: const InputDecoration(
                      labelText: 'نص الزر بالعربية',
                      prefixIcon: Icon(Icons.touch_app_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _ctaLabelEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'CTA label in English',
                      prefixIcon: Icon(Icons.touch_app_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _startsAtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'بداية العرض',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      prefixIcon: Icon(Icons.schedule_outlined),
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _endsAtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'نهاية العرض',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      prefixIcon: Icon(Icons.event_busy_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _pickMedia,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _mediaType == 'video' ? 'اختيار فيديو' : 'اختيار صورة',
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedMediaName != null)
                  Expanded(
                    child: Text(
                      _selectedMediaName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'يمكنك ترك الملف فارغًا إذا لم ترغب في تغييره'
                          : 'اختر ملف الوسائط المطلوب للقصة',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitStory,
                  icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(_isEditing ? 'حفظ التعديل' : 'إضافة القصة'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _resetForm,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('إعادة الضبط'),
                ),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _isSaving ? null : _resetForm,
                    icon: const Icon(Icons.close_outlined),
                    label: const Text('إلغاء التعديل'),
                  ),
              ],
            ),
            if (_isSaving) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (selectedVendor != null) ...[
              const SizedBox(height: 10),
              Text(
                'المتجر الحالي: ${_vendorLabel(selectedVendor)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'ابحث بالعنوان أو رقم التوجيه',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _loadStories,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تحديث'),
        ),
      ],
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final imageUrl = story['image_url']?.toString() ?? '';
    final videoUrl = story['video_url']?.toString() ?? '';
    final titleAr = story['title_ar']?.toString() ?? '';
    final titleEn = story['title_en']?.toString() ?? '';
    final vendorName = story['vendor_name']?.toString() ?? '';
    final storeName = story['store_name']?.toString() ?? '';
    final mediaLabel = _mediaLabel(story);
    final targetLabel = _targetLabel(story);
    final isActive = story['is_active']?.toString() == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.trim().isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                    : videoUrl.trim().isNotEmpty
                        ? const Center(
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              size: 36,
                              color: Color(0xFF1F7A3A),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 34),
                          ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleAr.isNotEmpty ? titleAr : (titleEn.isNotEmpty ? titleEn : 'Story'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showVendorSelector
                          ? '${vendorName.isNotEmpty ? vendorName : storeName} • $mediaLabel • ${isActive ? 'نشطة' : 'متوقفة'}'
                          : '$mediaLabel • ${isActive ? 'نشطة' : 'متوقفة'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      targetLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F7A3A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => _startEditing(story),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل'),
              ),
              TextButton.icon(
                onPressed: () => _deleteStory(story),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('حذف'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = _filteredStories;

    return DashboardPageShell(
      title: 'إدارة القصص',
      subtitle: 'رفع القصص الداخلية وتحديد التوجيه إلى مطعم أو منتج داخل التطبيق.',
      icon: Icons.auto_stories_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _isLoading ? null : _bootstrap,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'القصص',
          value: '${_stories.length}',
          icon: Icons.auto_stories_rounded,
          tint: const Color(0xFF1F7A3A),
          width: 180,
        ),
        DashboardStatCard(
          label: 'المرئية',
          value: '${_stories.where((story) => story['is_active']?.toString() == '1').length}',
          icon: Icons.visibility_rounded,
          tint: const Color(0xFF3B82F6),
          width: 180,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEditorCard(),
          const SizedBox(height: 18),
          _buildToolbar(),
          const SizedBox(height: 18),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 42),
                    const SizedBox(height: 10),
                    Text(_errorMessage!),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _bootstrap,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          else if (stories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.image_not_supported_outlined, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      _stories.isEmpty
                          ? 'لا توجد قصص حتى الآن.'
                          : 'لا توجد نتائج مطابقة.',
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loadStories,
                      child: const Text('تحديث'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...stories.map(_buildStoryCard),
        ],
      ),
    );
  }
}

class _VendorChoice {
  _VendorChoice({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  factory _VendorChoice.fromJson(Map<String, dynamic> json) {
    final vendorName = json['vendor_name']?.toString().trim() ?? '';
    final storeName = json['store_name']?.toString().trim() ?? '';
    final label = [
      if (storeName.isNotEmpty) storeName,
      if (vendorName.isNotEmpty && vendorName != storeName) vendorName,
    ].join(' • ');

    return _VendorChoice(
      id: json['vendor_id']?.toString() ?? '',
      label: label.isNotEmpty ? label : 'متجر غير معروف',
    );
  }
}
