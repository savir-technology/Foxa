import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ModifierGroupTypeOption {
  const ModifierGroupTypeOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
  });

  final String value;
  final String labelAr;
  final String labelEn;

  static const List<ModifierGroupTypeOption> defaults = [
    ModifierGroupTypeOption(
      value: 'modifier',
      labelAr: 'إضافات',
      labelEn: 'Modifiers',
    ),
    ModifierGroupTypeOption(
      value: 'ingredient',
      labelAr: 'مكونات أساسية',
      labelEn: 'Ingredients',
    ),
  ];
}

class ProductModifierOptionDraft {
  ProductModifierOptionDraft({
    String nameAr = '',
    String nameEn = '',
    String? imageName,
    String? imageUrl,
    Uint8List? imageBytes,
    double priceDelta = 0,
    bool isDefaultSelected = false,
    bool isRemovable = true,
    bool isActive = true,
  })  : imageName = imageName,
        imageUrl = imageUrl,
        imageBytes = imageBytes {
    nameArController.text = nameAr;
    nameEnController.text = nameEn;
    priceDeltaController.text = priceDelta == 0 ? '' : priceDelta.toString();
    this.isDefaultSelected = isDefaultSelected;
    this.isRemovable = isRemovable;
    this.isActive = isActive;
  }

  factory ProductModifierOptionDraft.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['image_url']?.toString().trim() ?? '';
    return ProductModifierOptionDraft(
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      imageName: imageUrl.isEmpty ? null : imageUrl.split('/').last,
      priceDelta: _parseDouble(json['price_delta']),
      isDefaultSelected: _parseBool(json['is_default_selected']),
      isRemovable: json['is_removable'] == null
          ? true
          : _parseBool(json['is_removable']),
      isActive:
          json['is_active'] == null ? true : _parseBool(json['is_active']),
    );
  }

  final TextEditingController nameArController = TextEditingController();
  final TextEditingController nameEnController = TextEditingController();
  final TextEditingController priceDeltaController = TextEditingController();

  String? imageName;
  String? imageUrl;
  Uint8List? imageBytes;
  bool isDefaultSelected = false;
  bool isRemovable = true;
  bool isActive = true;

  bool get hasContent =>
      nameArController.text.trim().isNotEmpty ||
      nameEnController.text.trim().isNotEmpty ||
      priceDeltaController.text.trim().isNotEmpty ||
      imageBytes != null ||
      (imageUrl?.trim().isNotEmpty == true);

  void dispose() {
    nameArController.dispose();
    nameEnController.dispose();
    priceDeltaController.dispose();
  }

  Map<String, dynamic>? toPayload({required int sortOrder}) {
    if (!hasContent) {
      return null;
    }

    final nameAr = nameArController.text.trim();
    final nameEn = nameEnController.text.trim();
    final payload = <String, dynamic>{
      'name_ar': nameAr,
      'name_en': nameEn,
      'price_delta': _parseDouble(priceDeltaController.text),
      'is_default_selected': isDefaultSelected,
      'is_removable': isRemovable,
      'sort_order': sortOrder,
      'is_active': isActive,
    };

    if (imageBytes != null) {
      payload['image'] = base64Encode(imageBytes!);
    } else if (imageUrl?.trim().isNotEmpty == true) {
      payload['image_url'] = imageUrl!.trim();
    }

    return payload;
  }
}

class ProductModifierGroupDraft {
  ProductModifierGroupDraft({
    String nameAr = '',
    String nameEn = '',
    String groupType = 'modifier',
    int minSelect = 0,
    int maxSelect = 1,
    bool isRequired = false,
    bool isActive = true,
    List<ProductModifierOptionDraft>? options,
  })  : groupType = _normalizeGroupType(groupType),
        isRequired = isRequired,
        isActive = isActive {
    nameArController.text = nameAr;
    nameEnController.text = nameEn;
    minSelectController.text = minSelect.toString();
    maxSelectController.text = maxSelect.toString();
    this.options = options ?? [ProductModifierOptionDraft()];
  }

  factory ProductModifierGroupDraft.fromJson(Map<String, dynamic> json) {
    final options = ((json['options'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (entry) => ProductModifierOptionDraft.fromJson(
              Map<String, dynamic>.from(entry)),
        )
        .toList();

    return ProductModifierGroupDraft(
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      groupType: json['group_type']?.toString() ?? 'modifier',
      minSelect: _parseInt(json['min_select']),
      maxSelect: _parseInt(json['max_select'], fallback: 1),
      isRequired: _parseBool(json['is_required']),
      isActive:
          json['is_active'] == null ? true : _parseBool(json['is_active']),
      options: options.isEmpty ? [ProductModifierOptionDraft()] : options,
    );
  }

  final TextEditingController nameArController = TextEditingController();
  final TextEditingController nameEnController = TextEditingController();
  final TextEditingController minSelectController =
      TextEditingController(text: '0');
  final TextEditingController maxSelectController =
      TextEditingController(text: '1');

  String groupType;
  bool isRequired = false;
  bool isActive = true;
  List<ProductModifierOptionDraft> options = [];

  bool get hasContent =>
      nameArController.text.trim().isNotEmpty ||
      nameEnController.text.trim().isNotEmpty ||
      options.any((option) => option.hasContent);

  String get groupLabel => nameArController.text.trim().isNotEmpty
      ? nameArController.text.trim()
      : nameEnController.text.trim();

  void dispose() {
    nameArController.dispose();
    nameEnController.dispose();
    minSelectController.dispose();
    maxSelectController.dispose();
    for (final option in options) {
      option.dispose();
    }
  }

  static String _normalizeGroupType(String value) {
    return value.trim().toLowerCase() == 'ingredient'
        ? 'ingredient'
        : 'modifier';
  }
}

class ProductModifierGroupsEditor extends StatefulWidget {
  const ProductModifierGroupsEditor({
    super.key,
    required this.groups,
    required this.decorationBuilder,
    required this.onChanged,
    this.groupTypes = ModifierGroupTypeOption.defaults,
  });

  final List<ProductModifierGroupDraft> groups;
  final List<ModifierGroupTypeOption> groupTypes;
  final InputDecoration Function(String label) decorationBuilder;
  final VoidCallback onChanged;

  @override
  State<ProductModifierGroupsEditor> createState() =>
      _ProductModifierGroupsEditorState();
}

class _ProductModifierGroupsEditorState
    extends State<ProductModifierGroupsEditor> {
  List<ModifierGroupTypeOption> get _groupTypes => widget.groupTypes.isEmpty
      ? ModifierGroupTypeOption.defaults
      : widget.groupTypes;

  void _notifyChanged() {
    widget.onChanged();
  }

  void _addGroup() {
    setState(() {
      widget.groups.add(ProductModifierGroupDraft());
    });
    _notifyChanged();
  }

  void _removeGroup(int index) {
    final group = widget.groups.removeAt(index);
    group.dispose();
    setState(() {});
    _notifyChanged();
  }

  void _addOption(ProductModifierGroupDraft group) {
    setState(() {
      group.options.add(ProductModifierOptionDraft());
    });
    _notifyChanged();
  }

  void _removeOption(ProductModifierGroupDraft group, int index) {
    final option = group.options.removeAt(index);
    option.dispose();
    setState(() {});
    _notifyChanged();
  }

  Future<void> _pickOptionImage(ProductModifierOptionDraft option) async {
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
      option.imageBytes = file.bytes!;
      option.imageName = file.name;
      option.imageUrl = null;
    });
    _notifyChanged();
  }

  String _groupTypeLabel(String value) {
    final match = _groupTypes.where((type) => type.value == value).toList();
    return match.isEmpty ? value : match.first.labelAr;
  }

  String _groupHelperText(String value) {
    return value == 'ingredient'
        ? 'يتم استخدام هذه المجموعة كمكونات أساسية، وغالبًا تُحدد تلقائيًا داخل التطبيق.'
        : 'يتم استخدامها كإضافات أو اختيارات إضافية للمنتج.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'مجموعات التخصيص',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addGroup,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مجموعة'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'أضف المكونات الأساسية أو الإضافات التي تظهر في صفحة تفاصيل المنتج داخل تطبيق المستخدم.',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.groups.isEmpty)
          _EditorEmptyState(
            title: 'لا توجد مجموعات تخصيص بعد',
            subtitle:
                'يمكنك الآن إضافة مجموعة مثل "إضافات" أو "مكونات أساسية" مع خياراتها وصورتها إن أردت.',
            icon: Icons.tune_rounded,
          )
        else
          ...widget.groups.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _GroupCard(
                    index: entry.key + 1,
                    group: entry.value,
                    groupTypes: _groupTypes,
                    decorationBuilder: widget.decorationBuilder,
                    groupTypeLabel: _groupTypeLabel(entry.value.groupType),
                    helperText: _groupHelperText(entry.value.groupType),
                    onDelete: () => _removeGroup(entry.key),
                    onAddOption: () => _addOption(entry.value),
                    onRemoveOption: (optionIndex) =>
                        _removeOption(entry.value, optionIndex),
                    onPickOptionImage: _pickOptionImage,
                    onChanged: _notifyChanged,
                  ),
                ),
              ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.index,
    required this.group,
    required this.groupTypes,
    required this.decorationBuilder,
    required this.groupTypeLabel,
    required this.helperText,
    required this.onDelete,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onPickOptionImage,
    required this.onChanged,
  });

  final int index;
  final ProductModifierGroupDraft group;
  final List<ModifierGroupTypeOption> groupTypes;
  final InputDecoration Function(String label) decorationBuilder;
  final String groupTypeLabel;
  final String helperText;
  final VoidCallback onDelete;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final Future<void> Function(ProductModifierOptionDraft option)
      onPickOptionImage;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'مجموعة $index',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: group.groupType == 'ingredient'
                      ? kAccent.withValues(alpha: 0.12)
                      : kSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  groupTypeLabel,
                  style: TextStyle(
                    color:
                        group.groupType == 'ingredient' ? kAccent : kSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: group.nameArController,
                  onChanged: (_) => onChanged(),
                  decoration: decorationBuilder('اسم المجموعة بالعربية'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: group.nameEnController,
                  onChanged: (_) => onChanged(),
                  decoration: decorationBuilder('Group name in English'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _groupTypeValue(group.groupType, groupTypes),
                  decoration: decorationBuilder('نوع المجموعة'),
                  items: groupTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type.value,
                          child: Text(type.labelAr),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    group.groupType = value ?? 'modifier';
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: group.minSelectController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: decorationBuilder('الحد الأدنى'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: group.maxSelectController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: decorationBuilder('الحد الأقصى'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SwitchTile(
                  title: 'إجباري',
                  subtitle: 'يجب على العميل اختيار عنصر واحد على الأقل.',
                  value: group.isRequired,
                  onChanged: (value) {
                    group.isRequired = value;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SwitchTile(
                  title: 'نشط',
                  subtitle: 'إخفاء المجموعة دون حذفها.',
                  value: group.isActive,
                  onChanged: (value) {
                    group.isActive = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'الخيارات',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddOption,
                icon: const Icon(Icons.add),
                label: const Text('إضافة خيار'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (group.options.isEmpty)
            const _EditorEmptyState(
              title: 'لا توجد خيارات داخل هذه المجموعة',
              subtitle:
                  'أضف خيارًا واحدًا على الأقل حتى تظهر للمستخدم داخل التطبيق.',
              icon: Icons.layers_outlined,
            )
          else
            ...group.options.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionCard(
                      index: entry.key + 1,
                      option: entry.value,
                      decorationBuilder: decorationBuilder,
                      onDelete: group.options.length == 1
                          ? null
                          : () => onRemoveOption(entry.key),
                      onPickImage: onPickOptionImage,
                      onChanged: onChanged,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.index,
    required this.option,
    required this.decorationBuilder,
    required this.onDelete,
    required this.onPickImage,
    required this.onChanged,
  });

  final int index;
  final ProductModifierOptionDraft option;
  final InputDecoration Function(String label) decorationBuilder;
  final VoidCallback? onDelete;
  final Future<void> Function(ProductModifierOptionDraft option) onPickImage;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImagePreview(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: kSecondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'خيار $index',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: option.nameArController,
                  onChanged: (_) => onChanged(),
                  decoration: decorationBuilder('اسم الخيار بالعربية'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: option.nameEnController,
                  onChanged: (_) => onChanged(),
                  decoration: decorationBuilder('Option name in English'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: option.priceDeltaController,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: decorationBuilder('فرق السعر'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SwitchTile(
                  title: 'افتراضي',
                  subtitle: 'يتم اختياره مبدئيًا عند فتح المنتج.',
                  value: option.isDefaultSelected,
                  onChanged: (value) {
                    option.isDefaultSelected = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SwitchTile(
                  title: 'يمكن إزالته',
                  subtitle: 'إذا أُوقف الخيار سيبقى مطلوبًا.',
                  value: option.isRemovable,
                  onChanged: (value) {
                    option.isRemovable = value;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SwitchTile(
                  title: 'نشط',
                  subtitle: 'تعطيل الخيار مؤقتًا.',
                  value: option.isActive,
                  onChanged: (value) {
                    option.isActive = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kStroke),
            ),
            child: Row(
              children: [
                imageWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.imageName ??
                        (option.imageUrl?.isNotEmpty == true
                            ? option.imageUrl!.split('/').last
                            : 'صورة اختيارية لهذا الخيار'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => onPickImage(option),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('اختيار صورة'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final imageUrl = option.imageUrl?.trim() ?? '';
    if (option.imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          option.imageBytes!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackThumb(),
        ),
      );
    }

    return _fallbackThumb();
  }

  Widget _fallbackThumb() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.lunch_dining_outlined, color: kPrimary),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _EditorEmptyState extends StatelessWidget {
  const _EditorEmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        children: [
          Icon(icon, color: kTextSecondary.withValues(alpha: 0.9), size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _groupTypeValue(
  String value,
  List<ModifierGroupTypeOption> groupTypes,
) {
  final normalized = value.trim().toLowerCase();
  if (groupTypes.any((type) => type.value == normalized)) {
    return normalized;
  }
  return groupTypes.isEmpty ? 'modifier' : groupTypes.first.value;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse('${value ?? ''}') ?? fallback;
}

double _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse('${value ?? ''}') ?? 0.0;
}

bool _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  final normalized = '${value ?? ''}'.toLowerCase().trim();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
