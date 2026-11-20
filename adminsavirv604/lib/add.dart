// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:admin_tks/EditItemPage.dart';
import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/model/categories_model.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/remote/category_data.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:admin_tks/widgets/product_modifier_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _descArController = TextEditingController();
  final TextEditingController _descEnController = TextEditingController();
  final TextEditingController _priceController =
      TextEditingController(text: '');
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  final TextEditingController _stockController =
      TextEditingController(text: '1');
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _perfumeFamilyController = TextEditingController();
  final TextEditingController _perfumeBadgeController = TextEditingController();
  final TextEditingController _topNotesController = TextEditingController();
  final TextEditingController _middleNotesController = TextEditingController();
  final TextEditingController _baseNotesController = TextEditingController();
  final TextEditingController _seasonsController = TextEditingController();
  final TextEditingController _bestForController = TextEditingController();
  final TextEditingController _bottleSizesController = TextEditingController();
  final TextEditingController _bottleDesignController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();
  final TextEditingController _bodyHeightValuesController =
      TextEditingController(text: '150, 160, 165, 170, 175, 180, 185');
  final TextEditingController _bodyWeightValuesController =
      TextEditingController(text: '45, 50, 60, 70, 80, 90, 100');
  String _perfumeConcentration = 'Eau de Parfum';
  String _perfumeTarget = 'Unisex';
  double _perfumeLongevity = 8;
  double _perfumeSillage = 7;
  bool _includeBodyHeight = false;
  bool _includeBodyWeight = false;
  final Map<String, TextEditingController> _storeAttributeControllers = {};

  final List<cat> _categories = [];
  final List<_VendorRef> _vendors = [];
  final List<_PickedImage> _galleryImages = [];
  final List<ProductModifierGroupDraft> _modifierGroups = [];

  Uint8List? _coverImageBytes;
  String? _coverImageName;
  String? _categoryId;
  String? _vendorId;
  bool _isAvailable = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isMetaReloading = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  cat? get _selectedCategory {
    if (_categoryId == null) return null;
    for (final item in _categories) {
      if (item.categoriesId == _categoryId) return item;
    }
    return null;
  }

  _VendorRef? get _selectedVendor {
    if (_vendorId == null) return null;
    for (final item in _vendors) {
      if (item.id == _vendorId) return item;
    }
    return null;
  }

  Uint8List? get _primaryImageBytes {
    if (_coverImageBytes != null) return _coverImageBytes;
    if (_galleryImages.isNotEmpty) return _galleryImages.first.bytes;
    return null;
  }

  String? get _primaryImageName {
    if (_coverImageName?.trim().isNotEmpty == true) return _coverImageName;
    if (_galleryImages.isNotEmpty) return _galleryImages.first.name;
    return null;
  }

  double get _priceValue => _parseDouble(_priceController.text);
  double get _discountValue => _parseDouble(_discountController.text);
  int get _stockValue => _parseInt(_stockController.text, fallback: 1);
  double get _stockQuantityValue =>
      _parseDouble(_stockController.text, fallback: 1);
  String get _productType => _auth.isStore
      ? (_auth.storeCategory ?? 'general')
      : 'food';
  String get _stockUnit {
    switch (_productType) {
      case 'perfume':
        return 'ml';
      case 'fresh_food':
        return 'kg';
      case 'fashion':
      case 'shoes':
      case 'canned_food':
      case 'electronics':
      case 'toys':
        return 'piece';
      default:
        return 'piece';
    }
  }
  int get _imageCount =>
      _galleryImages.length + (_coverImageBytes == null ? 0 : 1);

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _capacityController.dispose();
    _perfumeFamilyController.dispose();
    _perfumeBadgeController.dispose();
    _topNotesController.dispose();
    _middleNotesController.dispose();
    _baseNotesController.dispose();
    _seasonsController.dispose();
    _bestForController.dispose();
    _bottleSizesController.dispose();
    _bottleDesignController.dispose();
    _packagingController.dispose();
    _bodyHeightValuesController.dispose();
    _bodyWeightValuesController.dispose();
    for (final controller in _storeAttributeControllers.values) {
      controller.dispose();
    }
    for (final group in _modifierGroups) {
      group.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeta() async {
    if (_isMetaReloading) return;

    setState(() {
      _isMetaReloading = true;
      _isLoading = true;
    });

    try {
      if (_auth.isMaster) {
        await _loadVendors();
        if (_vendorId == null && _vendors.isNotEmpty) {
          _vendorId = _vendors.first.id;
        }
      } else {
        _vendorId = _auth.vendorId > 0 ? _auth.vendorId.toString() : null;
      }

      await _loadCategories();
    } finally {
      if (mounted) {
        setState(() {
          _isMetaReloading = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVendors() async {
    try {
      final response = await DashboardApiClient.getUrl(
        'https://savir-technology.online/roaqv2/dash/master/vendors/get_vendors.php',
      );
      final decoded = _decodeJsonBody(response);
      final rows = _extractRows(decoded);
      _vendors
        ..clear()
        ..addAll(rows.map(_VendorRef.fromJson));
    } catch (_) {
      _vendors.clear();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await CategoryData().getCategories();
      _categories
        ..clear()
        ..addAll(result);

      if (_categoryId != null &&
          !_categories.any((item) => item.categoriesId == _categoryId)) {
        _categoryId = null;
      }

      if (_categoryId == null && _categories.isNotEmpty) {
        _categoryId = _categories.first.categoriesId;
      }
    } catch (_) {
      _categories.clear();
    }
  }

  dynamic _decodeJsonBody(dynamic response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _extractRows(dynamic decoded) {
    final raw = decoded is Map ? decoded['data'] : decoded;
    final list = raw is List ? raw : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) return;

    setState(() {
      _coverImageBytes = file.bytes!;
      _coverImageName = file.name;
    });
  }

  Future<void> _pickGalleryImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files
        .where((file) => file.bytes != null && file.bytes!.isNotEmpty)
        .map((file) => _PickedImage(name: file.name, bytes: file.bytes!))
        .toList();

    if (picked.isEmpty) return;

    if (_productType == 'fresh_food') {
      setState(() {
        _coverImageBytes = picked.first.bytes;
        _coverImageName = picked.first.name;
        _galleryImages.clear();
      });
      return;
    }

    setState(() {
      _galleryImages.addAll(picked);
      _coverImageBytes ??= _galleryImages.first.bytes;
      _coverImageName ??= _galleryImages.first.name;
    });
  }

  void _clearCoverImage() {
    setState(() {
      _coverImageBytes = null;
      _coverImageName = null;
    });
  }

  void _setGalleryAsCover(int index) {
    if (index < 0 || index >= _galleryImages.length) return;
    final image = _galleryImages[index];
    setState(() {
      _coverImageBytes = image.bytes;
      _coverImageName = image.name;
    });
  }

  void _removeGalleryImage(int index) {
    if (index < 0 || index >= _galleryImages.length) return;

    final removed = _galleryImages.removeAt(index);
    final shouldResetCover = _coverImageName == removed.name;
    setState(() {
      if (shouldResetCover) {
        if (_galleryImages.isNotEmpty) {
          _coverImageBytes = _galleryImages.first.bytes;
          _coverImageName = _galleryImages.first.name;
        } else {
          _coverImageBytes = null;
          _coverImageName = null;
        }
      }
    });
  }

  Future<void> _selectVendor(String? vendorId) async {
    if (_vendorId == vendorId) return;

    setState(() {
      _vendorId = vendorId;
    });
  }

  List<Map<String, dynamic>> _cleanPerfumeAttributesPayload() {
    final fields = <String, String>{
      'العائلة العطرية': _perfumeFamilyController.text,
      'التركيز': _perfumeConcentration,
      'الفئة المستهدفة': _perfumeTarget,
      'الشارة': _perfumeBadgeController.text,
      'تصميم الزجاجة': _bottleDesignController.text,
      'التغليف': _packagingController.text,
      'مقدمة العطر': _topNotesController.text,
      'قلب العطر': _middleNotesController.text,
      'قاعدة العطر': _baseNotesController.text,
      'المواسم': _seasonsController.text,
      'مناسب لـ': _bestForController.text,
      'أحجام الزجاجات (ml)': _bottleSizesController.text,
      'الثبات': _perfumeLongevity.round().toString(),
      'الفوحان': _perfumeSillage.round().toString(),
    };
    return fields.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => {
              'name_ar': entry.key,
              'name_en': entry.key,
              'values': (entry.key == 'أحجام الزجاجات (ml)'
                      ? entry.value.split(RegExp(r'[,،]'))
                      : [entry.value])
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .map((value) => {
                        'value_ar': value,
                        'value_en': value,
                      })
                  .toList(),
            })
        .toList();
  }

  TextEditingController _storeAttributeController(String key) {
    return _storeAttributeControllers.putIfAbsent(
      key,
      TextEditingController.new,
    );
  }

  List<Map<String, dynamic>> _storeAttributesPayload() {
    final attributes = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> bodyAttribute(
      String nameAr,
      String nameEn,
      String values,
    ) {
      final parsed = values
          .split(RegExp(r'[,،]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (parsed.isEmpty) return const [];
      return [
        {
          'name_ar': nameAr,
          'name_en': nameEn,
          'is_required': true,
          'values': parsed
              .map((value) => {'value_ar': value, 'value_en': value})
              .toList(),
        },
      ];
    }
    if (_productType == 'fashion') {
      if (_includeBodyHeight) {
        attributes.addAll(bodyAttribute(
          'الطول (سم)',
          'Height (cm)',
          _bodyHeightValuesController.text,
        ));
      }
      if (_includeBodyWeight) {
        attributes.addAll(bodyAttribute(
          'الوزن (كجم)',
          'Weight (kg)',
          _bodyWeightValuesController.text,
        ));
      }
    }
    final labels = <String, List<String>>{
      'fresh_food': ['خيارات البيع', 'بلد المنشأ', 'طريقة الحفظ'],
      'canned_food': ['نوع العبوة', 'الوزن أو الحجم', 'تاريخ الصلاحية'],
      'electronics': ['العلامة التجارية', 'الموديل', 'مدة الضمان'],
      'toys': ['الفئة العمرية', 'الخامة', 'محتويات العبوة'],
    }[_productType];
    if (labels == null) return attributes;
    attributes.addAll(labels
        .map((label) => MapEntry(label, _storeAttributeController(label).text))
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => {
              'name_ar': entry.key,
              'name_en': entry.key,
              'values': [
                {
                  'value_ar': entry.value.trim(),
                  'value_en': entry.value.trim(),
                },
              ],
            })
        .toList());
    return attributes;
  }

  Future<void> _saveProduct() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_categoryId == null || _categoryId!.trim().isEmpty) {
      _showSnackBar('اختر قسم المنتج قبل الحفظ');
      return;
    }

    if (_priceValue <= 0) {
      _showSnackBar('أدخل سعراً صحيحاً للمنتج');
      return;
    }

    if (_discountValue < 0) {
      _showSnackBar('قيمة الخصم لا يمكن أن تكون سالبة');
      return;
    }

    if (_discountValue > _priceValue) {
      _showSnackBar('الخصم لا يمكن أن يكون أكبر من السعر');
      return;
    }

    final primaryImage = _primaryImageBytes;
    if (primaryImage == null) {
      _showSnackBar('أضف صورة رئيسية واحدة على الأقل');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final modifierGroupsPayload = _modifierGroups
          .asMap()
          .entries
          .map((entry) => _modifierGroupPayload(
                entry.value,
                sortOrder: entry.key + 1,
              ))
          .whereType<Map<String, dynamic>>()
          .toList();

      final payload = <String, dynamic>{
        'items_name_ar': _nameArController.text.trim(),
        'items_name_en': _nameEnController.text.trim(),
        'items_desc_ar': _descArController.text.trim(),
        'items_desc_en': _descEnController.text.trim(),
        'items_price': _priceValue.toStringAsFixed(2),
        'items_discount': _discountValue.toStringAsFixed(2),
        'items_count': _stockValue.toString(),
        'items_cat': _categoryId,
        'items_active': _isAvailable ? '1' : '0',
        'items_image': base64Encode(primaryImage),
        'product_type': _productType,
        'stock_unit': _stockUnit,
        'stock_step': _stockUnit == 'piece' ? 1 : 0.001,
        if (_auth.isStore)
          'variants': _productType == 'fresh_food'
              ? [0.25, 0.5, 1.0, 2.0, 3.0]
                  .map((weight) => {
                        'price': _priceValue * weight,
                        'stock': _stockQuantityValue,
                        'stock_quantity': _stockQuantityValue,
                        'unit': 'kg',
                        'unit_quantity': weight,
                        'sku': '${weight.toStringAsFixed(weight == weight.roundToDouble() ? 0 : 2)} kg',
                      })
                  .toList()
              : [
                  {
                    'price': _priceValue,
                    'stock': _stockUnit == 'piece'
                        ? _stockValue
                        : _stockQuantityValue,
                    'stock_quantity': _stockQuantityValue,
                    'unit': _stockUnit,
                    'unit_quantity': 1,
                    if (_productType == 'perfume' &&
                        _capacityController.text.trim().isNotEmpty)
                      'sku': '${_capacityController.text.trim()} ml',
                  },
                ],
        'images': <Map<String, dynamic>>[
          {
            'name': _primaryImageName ?? 'product-cover',
            'data': base64Encode(primaryImage),
          },
          if (_productType != 'fresh_food') ..._galleryImages.map(
            (image) => {
              'name': image.name,
              'data': base64Encode(image.bytes),
            },
          ),
        ],
      };

      if (_vendorId != null && _vendorId!.trim().isNotEmpty) {
        payload['vendor_id'] = _vendorId;
      }

      if (_galleryImages.isNotEmpty && _productType != 'fresh_food') {
        payload['gallery_images'] = _galleryImages
            .map(
              (image) => {
                'name': image.name,
                'base64': base64Encode(image.bytes),
              },
            )
            .toList();
      }

      if (modifierGroupsPayload.isNotEmpty) {
        payload['modifier_groups'] = modifierGroupsPayload;
      }

      final result = await ItemsData().addItemPayload(payload);

      if (!mounted) return;

      setState(() => _isSaving = false);

      final success = result != null && result['status'] == 'success';
      if (success) {
        _showSnackBar('تمت إضافة المنتج بنجاح');
        final needsDimensions = _auth.isStore &&
            (_productType == 'fashion' || _productType == 'shoes');
        final createdItemId = result?['item_id']?.toString();
        if (_productType == 'perfume' && createdItemId != null) {
          await ItemsData().saveItemAttributes(
            createdItemId,
            _cleanPerfumeAttributesPayload(),
          );
        }
        if (_productType != 'perfume' && createdItemId != null) {
          final attributes = _storeAttributesPayload();
          if (attributes.isNotEmpty) {
            await ItemsData().saveItemAttributes(createdItemId, attributes);
          }
        }
        if (needsDimensions && createdItemId != null && mounted) {
          await Get.to(
            () => EditItemPage(
              item: ItemsModel(
                itemsId: createdItemId,
                productType: _productType,
                stockUnit: _stockUnit,
              ),
            ),
          );
        }
        Navigator.pop(context, true);
      } else {
        final message = result?['message']?.toString();
        _showSnackBar(
          message?.trim().isNotEmpty == true
              ? message!
              : 'تعذر حفظ المنتج، حاول مرة أخرى',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('تعذر حفظ المنتج، تحقق من الاتصال ثم أعد المحاولة');
    }
  }

  void _resetForm() {
    setState(() {
      _nameArController.clear();
      _nameEnController.clear();
      _descArController.clear();
      _descEnController.clear();
      _priceController.clear();
      _discountController.text = '0';
      _stockController.text = '1';
      _capacityController.clear();
      _perfumeFamilyController.clear();
      _perfumeBadgeController.clear();
      _topNotesController.clear();
      _middleNotesController.clear();
      _baseNotesController.clear();
      _seasonsController.clear();
      _bestForController.clear();
      _bottleSizesController.clear();
      _bottleDesignController.clear();
      _packagingController.clear();
      _perfumeConcentration = 'Eau de Parfum';
      _perfumeTarget = 'Unisex';
      _perfumeLongevity = 8;
      _perfumeSillage = 7;
      for (final controller in _storeAttributeControllers.values) {
        controller.clear();
      }
      _categoryId =
          _categories.isNotEmpty ? _categories.first.categoriesId : null;
      _isAvailable = true;
      _coverImageBytes = null;
      _coverImageName = null;
      _galleryImages.clear();
      for (final group in _modifierGroups) {
        group.dispose();
      }
      _modifierGroups.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _categoryLabel(cat value) {
    final arabic = value.categoriesNameAr?.trim() ?? '';
    final english = value.categoriesNameEn?.trim() ?? '';
    if (arabic.isNotEmpty && english.isNotEmpty) return '$arabic • $english';
    if (arabic.isNotEmpty) return arabic;
    if (english.isNotEmpty) return english;
    return 'قسم غير مسمى';
  }

  String _vendorLabel(_VendorRef value) {
    final label = value.label.trim();
    return label.isEmpty ? 'مورد غير معروف' : label;
  }

  int _parseInt(String value, {int fallback = 0}) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  double _parseDouble(String value, {double fallback = 0}) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  Map<String, dynamic>? _modifierGroupPayload(
    ProductModifierGroupDraft group, {
    required int sortOrder,
  }) {
    if (!group.hasContent) return null;

    final options = group.options
        .asMap()
        .entries
        .map((entry) => entry.value.toPayload(sortOrder: entry.key + 1))
        .whereType<Map<String, dynamic>>()
        .toList();

    return {
      'name_ar': group.nameArController.text.trim(),
      'name_en': group.nameEnController.text.trim(),
      'group_type': group.groupType,
      'min_select': _parseInt(group.minSelectController.text),
      'max_select': _parseInt(group.maxSelectController.text, fallback: 1),
      'is_required': group.isRequired,
      'is_active': group.isActive,
      'sort_order': sortOrder,
      'options': options,
    };
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int minLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final effectiveKeyboardType =
        textInputAction == TextInputAction.newline &&
                maxLines != 1 &&
                keyboardType == TextInputType.text
            ? TextInputType.multiline
            : keyboardType;

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: effectiveKeyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      decoration: _fieldDecoration(
        label: label,
        icon: icon,
        hintText: hintText,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kPrimary, size: 20),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildLoadingPanel() {
    return DashboardPanel(
      child: SizedBox(
        height: 380,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.8),
              ),
              const SizedBox(height: 14),
              Text(
                _isMetaReloading
                    ? 'جارٍ تجهيز بيانات المنتج'
                    : 'جارٍ تحميل الشاشة',
                style: const TextStyle(
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final heroBytes = _primaryImageBytes;
    final heroName = _primaryImageName;
    final selectedCategory = _selectedCategory;
    final selectedVendor = _selectedVendor;
    final finalPrice = (_priceValue - _discountValue).clamp(0, double.infinity);
    final categoryName = selectedCategory == null
        ? 'لم يتم اختيار قسم'
        : _categoryLabel(selectedCategory);
    final vendorName = selectedVendor == null
        ? (_auth.isMaster
            ? 'لا يوجد مورّد محدد'
            : (_auth.storeName.isNotEmpty ? _auth.storeName : 'مطعمك'))
        : _vendorLabel(selectedVendor);

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'المعاينة المباشرة',
            subtitle: 'كل تغيير يظهر هنا قبل الضغط على حفظ.',
            icon: Icons.visibility_rounded,
          ),
          const SizedBox(height: 14),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: kSurfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kStroke),
            ),
            clipBehavior: Clip.antiAlias,
            child: heroBytes == null
                ? const _EmptyProductPreview()
                : Image.memory(
                    heroBytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _nameArController.text.trim().isEmpty
                ? 'اسم المنتج بالعربية'
                : _nameArController.text.trim(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _nameEnController.text.trim().isEmpty
                ? 'Product name in English'
                : _nameEnController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _PreviewChip(
                icon: Icons.category_rounded,
                label: categoryName,
              ),
              _PreviewChip(
                icon: Icons.storefront_rounded,
                label: vendorName,
              ),
              _PreviewChip(
                icon: _isAvailable
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                label: _isAvailable ? 'متاح' : 'مخفي',
              ),
              _PreviewChip(
                icon: Icons.image_rounded,
                label: heroName?.trim().isNotEmpty == true
                    ? heroName!
                    : 'لا توجد صورة رئيسية',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kStroke),
            ),
            child: Column(
              children: [
                _PreviewLine(
                  label: 'السعر الحالي',
                  value: '${_priceValue.toStringAsFixed(2)} SAR',
                ),
              const SizedBox(height: 8),
                _PreviewLine(
                  label: 'الخصم',
                  value: '${_discountValue.toStringAsFixed(2)} SAR',
                ),
                const SizedBox(height: 10),
                _PreviewLine(
                  label: 'السعر بعد الخصم',
                  value: '${finalPrice.toStringAsFixed(2)} SAR',
                  valueColor: kPrimary,
                ),
                const SizedBox(height: 10),
                _PreviewLine(
                  label: 'المخزون',
                  value: '$_stockValue',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'عدد الصور المضافة: $_imageCount | مجموع مجموعات الإضافات: ${_modifierGroups.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    final vendorDropDown = _auth.isMaster
        ? _vendors.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kStroke),
                ),
                child: const Text(
                  'لم يتم العثور على مورّدين متاحين حالياً',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : DropdownButtonFormField<String>(
                initialValue: _vendorId,
                isExpanded: true,
                decoration: _fieldDecoration(
                  label: 'المورّد',
                  icon: Icons.store_rounded,
                ),
                validator: (value) => (_auth.isMaster &&
                        _vendors.isNotEmpty &&
                        (value == null || value.trim().isEmpty))
                    ? 'اختر مورّد المنتج'
                    : null,
                items: _vendors
                    .map(
                      (vendor) => DropdownMenuItem<String>(
                        value: vendor.id,
                        child: Text(_vendorLabel(vendor)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  unawaited(_selectVendor(value));
                },
              )
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kStroke),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, color: kPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _auth.storeName.isNotEmpty
                        ? _auth.storeName
                        : 'المطعم الحالي',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _TinyChip(label: 'ثابت'),
              ],
            ),
          );

    final categoryDropDown = _categories.isEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kStroke),
            ),
            child: const Text(
              'لا توجد أقسام متاحة حالياً، جرّب تحديث الصفحة',
              style: TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : DropdownButtonFormField<String>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: _fieldDecoration(
              label: 'قسم المنتج',
              icon: Icons.category_rounded,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'اختر قسم المنتج'
                : null,
            items: _categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.categoriesId,
                    child: Text(_categoryLabel(category)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _categoryId = value);
            },
          );

    return _buildSectionCard(
      title: 'الهوية الأساسية',
      subtitle: 'الاسم، القسم، والمورّد المرتبط بالمنتج.',
      icon: Icons.badge_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final fieldWidth =
              isWide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _nameArController,
                  label: 'اسم المنتج بالعربية',
                  icon: Icons.edit_note_rounded,
                  hintText: 'مثال: شاورما دجاج',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم المنتج بالعربية مطلوب'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _nameEnController,
                  label: 'اسم المنتج بالإنجليزية',
                  icon: Icons.translate_rounded,
                  hintText: 'Optional',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: fieldWidth, child: vendorDropDown),
              SizedBox(width: fieldWidth, child: categoryDropDown),
              SizedBox(
                width: fieldWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kSurfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kStroke),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isAvailable,
                    onChanged: (value) => setState(() => _isAvailable = value),
                    title: const Text(
                      'حالة التوفر',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _isAvailable
                          ? 'المنتج ظاهر في التطبيق'
                          : 'المنتج مخفي مؤقتاً',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPricingSection() {
    return _buildSectionCard(
      title: 'التسعير والمخزون',
      subtitle: 'التحكم بالسعر والخصم والكمية من مكان واحد.',
      icon: Icons.payments_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final fieldWidth =
              isWide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _priceController,
                  label: 'السعر',
                  icon: Icons.price_check_rounded,
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) {
                    final price = _parseDouble(value ?? '');
                    if (price <= 0) return 'أدخل سعراً صحيحاً';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _discountController,
                  label: 'الخصم',
                  icon: Icons.local_offer_rounded,
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _stockController,
                  label: 'المخزون',
                  icon: Icons.inventory_2_rounded,
                  hintText: '1',
                  keyboardType: _stockUnit == 'piece'
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    _stockUnit == 'piece'
                        ? FilteringTextInputFormatter.digitsOnly
                        : FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) {
                    final stock = _stockUnit == 'piece'
                        ? _parseInt(value ?? '', fallback: -1)
                        : _parseDouble(value ?? '', fallback: -1);
                    if (stock < 0) return 'أدخل كمية صحيحة';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_productType == 'perfume')
                SizedBox(
                  width: fieldWidth,
                  child: _textField(
                    controller: _capacityController,
                    label: 'السعة (ملليلتر)',
                    icon: Icons.opacity_rounded,
                    hintText: 'مثال: 50',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (_productType != 'perfume') return null;
                      return _parseDouble(value ?? '') <= 0
                          ? 'أدخل السعة بالملليلتر'
                          : null;
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildSectionCard(
      title: 'الوصف',
      subtitle: 'أضف وصفاً يساعد العميل على فهم المنتج بسرعة.',
      icon: Icons.notes_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final fieldWidth =
              isWide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _descArController,
                  label: 'الوصف بالعربية',
                  icon: Icons.subject_rounded,
                  hintText: 'مثال: شاورما دجاج طازجة مع صوص خاص',
                  maxLines: 4,
                  minLines: 4,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _textField(
                  controller: _descEnController,
                  label: 'الوصف بالإنجليزية',
                  icon: Icons.language_rounded,
                  hintText: 'Optional',
                  maxLines: 4,
                  minLines: 4,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMediaSection() {
    final galleryCount = _galleryImages.length;

    return _buildSectionCard(
      title: 'الصور',
      subtitle: 'الصورة الرئيسية ضرورية، ويمكنك إضافة صور إضافية أيضاً.',
      icon: Icons.image_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverImageCard(
            imageBytes: _coverImageBytes,
            imageName: _coverImageName,
            onPick: _pickCoverImage,
            onClear: _clearCoverImage,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _productType == 'fresh_food' ? null : _pickGalleryImages,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('إضافة صور أخرى'),
                ),
              ),
              const SizedBox(width: 12),
              _TinyChip(label: '$_imageCount صورة'),
            ],
          ),
          const SizedBox(height: 12),
          if (_productType != 'fresh_food')
            _GalleryStrip(
            images: _galleryImages,
            coverName: _coverImageName,
            onAdd: _pickGalleryImages,
            onSetCover: _setGalleryAsCover,
            onRemove: _removeGalleryImage,
          ),
          if (galleryCount > 0) ...[
            const SizedBox(height: 10),
            const Text(
              'يمكنك استخدام أي صورة من القائمة كصورة رئيسية بسرعة.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModifiersSection() {
    return _buildSectionCard(
      title: 'الإضافات والمكونات',
      subtitle: 'أضف الإضافات أو المكونات الأساسية الخاصة بكل منتج.',
      icon: Icons.tune_rounded,
      child: ProductModifierGroupsEditor(
        groups: _modifierGroups,
        decorationBuilder: (label) => InputDecoration(labelText: label),
        onChanged: () => setState(() {}),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('تفريغ النموذج'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveProduct,
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
              label: Text(_isSaving ? '\u062c\u0627\u0631\u064a \u0627\u0644\u062d\u0641\u0638' : ((_productType == 'fashion' || _productType == 'shoes') ? '\u062d\u0641\u0638 \u0648\u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0623\u0644\u0648\u0627\u0646 \u0648\u0627\u0644\u0645\u0642\u0627\u0633\u0627\u062a' : '\u062d\u0641\u0638 \u0627\u0644\u0645\u0646\u062a\u062c')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return DashboardPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIdentitySection(),
            const SizedBox(height: 18),
            _buildPricingSection(),
            const SizedBox(height: 18),
            _buildDescriptionSection(),
            const SizedBox(height: 18),
            _buildMediaSection(),
            const SizedBox(height: 18),
            if (_auth.isStore) ...[
              _buildStoreCatalogRulesSection(),
              const SizedBox(height: 18),
              if (_productType == 'perfume') ...[
                _buildPerfumeDetailsSection(),
                const SizedBox(height: 18),
              ],
              if (_productType == 'fashion') ...[
                _buildClothingFitOptionsSection(),
                const SizedBox(height: 18),
              ],
              if (_productType != 'perfume' &&
                  _productType != 'fashion' &&
                  _productType != 'shoes') ...[
                _buildStoreDetailsSection(),
                const SizedBox(height: 18),
              ],
            ],
            if (!_auth.isStore) _buildModifiersSection(),
            const SizedBox(height: 18),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCatalogRulesSection() {
    final isDimensions = _productType == 'fashion' || _productType == 'shoes';
    final rule = isDimensions
        ? '\u0633\u064a\u062a\u0645 \u0625\u0638\u0647\u0627\u0631 \u0645\u062d\u0631\u0631 \u0627\u0644\u0623\u0644\u0648\u0627\u0646 \u0648\u0627\u0644\u0645\u0642\u0627\u0633\u0627\u062a \u0645\u0628\u0627\u0634\u0631\u0629 \u0628\u0639\u062f \u062d\u0641\u0638 \u0627\u0644\u0645\u0646\u062a\u062c.'
        : _productType == 'perfume'
            ? '\u0627\u0644\u0643\u0645\u064a\u0629 \u0628\u0627\u0644\u0645\u0644\u0644\u064a\u0644\u062a\u0631 (ml).'
            : _productType == 'fresh_food'
                ? '\u0627\u0644\u0643\u0645\u064a\u0629 \u0628\u0627\u0644\u0643\u064a\u0644\u0648 \u0648\u0623\u062c\u0632\u0627\u0626\u0647.'
                : _productType == 'canned_food'
                    ? '\u0627\u0644\u0643\u0645\u064a\u0629 \u0628\u0627\u0644\u0639\u0628\u0648\u0629 \u0623\u0648 \u0627\u0644\u0642\u0637\u0639\u0629.'
                    : '\u0627\u0644\u0643\u0645\u064a\u0629 \u0628\u0627\u0644\u0642\u0637\u0639\u0629.';
    return _buildSectionCard(
      title: '\u062a\u0647\u064a\u0626\u0629 \u0627\u0644\u0645\u0646\u062a\u062c \u062d\u0633\u0628 \u062a\u062e\u0635\u0635 \u0627\u0644\u0645\u062a\u062c\u0631',
      subtitle: '\u0627\u0644\u0646\u0648\u0639: $_productType  |  \u0648\u062d\u062f\u0629 \u0627\u0644\u0645\u062e\u0632\u0648\u0646: $_stockUnit',
      icon: isDimensions ? Icons.checkroom_rounded : Icons.straighten_rounded,
      child: Text(rule, textAlign: TextAlign.right),
    );
  }

  Widget _buildClothingFitOptionsSection() {
    return _buildSectionCard(
      title: 'Clothing fit options',
      subtitle: 'Enable the measurements that the customer must choose.',
      icon: Icons.accessibility_new_rounded,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ask for height / الطول'),
            value: _includeBodyHeight,
            onChanged: (value) => setState(() => _includeBodyHeight = value),
          ),
          if (_includeBodyHeight)
            _textField(
              controller: _bodyHeightValuesController,
              label: 'Height values in cm',
              icon: Icons.height_rounded,
              hintText: 'Example: 160, 165, 170, 175',
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ask for weight / الوزن'),
            value: _includeBodyWeight,
            onChanged: (value) => setState(() => _includeBodyWeight = value),
          ),
          if (_includeBodyWeight)
            _textField(
              controller: _bodyWeightValuesController,
              label: 'Weight values in kg',
              icon: Icons.monitor_weight_outlined,
              hintText: 'Example: 50, 60, 70, 80',
            ),
        ],
      ),
    );
  }

  Widget _buildPerfumeDetailsSection() {
    DropdownButtonFormField<String> selectField({
      required String label,
      required IconData icon,
      required String value,
      required List<String> values,
      required ValueChanged<String?> onChanged,
    }) {
      return DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        decoration: _fieldDecoration(label: label, icon: icon),
        items: values
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      );
    }

    Widget scoreField({
      required String label,
      required double value,
      required ValueChanged<double> onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$label: ${value.round()}/10'),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      );
    }

    return _buildSectionCard(
      title: 'الهوية العطرية',
      subtitle: 'أضف تفاصيل العطر التي سيحتاجها العميل قبل الشراء.',
      icon: Icons.auto_awesome_rounded,
      child: Column(
        children: [
          _textField(
            controller: _perfumeFamilyController,
            label: 'العائلة العطرية',
            icon: Icons.spa_outlined,
            hintText: 'مثال: شرقي، خشبي، زهري',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: selectField(
                      label: 'التركيز',
                      icon: Icons.water_drop_outlined,
                      value: _perfumeConcentration,
                      values: const [
                        'Eau de Parfum',
                        'Eau de Toilette',
                        'Parfum',
                        'Body Mist',
                      ],
                      onChanged: (value) => setState(() {
                        _perfumeConcentration = value ?? 'Eau de Parfum';
                      }),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: selectField(
                      label: 'الفئة المستهدفة',
                      icon: Icons.person_outline,
                      value: _perfumeTarget,
                      values: const ['Unisex', 'رجالي', 'نسائي'],
                      onChanged: (value) => setState(() {
                        _perfumeTarget = value ?? 'Unisex';
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _perfumeBadgeController,
            label: 'الشارة',
            icon: Icons.sell_outlined,
            hintText: 'مثال: جديد أو الأكثر مبيعًا',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _topNotesController,
            label: 'مقدمة العطر (Top Notes)',
            icon: Icons.notes_rounded,
            maxLines: 2,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _middleNotesController,
            label: 'قلب العطر (Middle Notes)',
            icon: Icons.notes_rounded,
            maxLines: 2,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _baseNotesController,
            label: 'قاعدة العطر (Base Notes)',
            icon: Icons.notes_rounded,
            maxLines: 2,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _seasonsController,
            label: 'المواسم المناسبة',
            icon: Icons.calendar_month_outlined,
            hintText: 'مثال: الصيف، الشتاء',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _bestForController,
            label: 'مناسب لـ',
            icon: Icons.event_available_outlined,
            hintText: 'مثال: العمل، السهرات، الاستخدام اليومي',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _bottleSizesController,
            label: 'أحجام الزجاجات المتاحة (ml)',
            icon: Icons.local_drink_outlined,
            hintText: 'مثال: 30, 50, 100',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _bottleDesignController,
            label: 'تصميم الزجاجة',
            icon: Icons.style_outlined,
            hintText: 'مثال: شفاف، مطفي، فاخر',
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _packagingController,
            label: 'خيارات التغليف',
            icon: Icons.card_giftcard_outlined,
            hintText: 'مثال: عادي، فاخر، هدية',
          ),
          const SizedBox(height: 10),
          scoreField(
            label: 'الثبات',
            value: _perfumeLongevity,
            onChanged: (value) => setState(() => _perfumeLongevity = value),
          ),
          scoreField(
            label: 'الفوحان',
            value: _perfumeSillage,
            onChanged: (value) => setState(() => _perfumeSillage = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreDetailsSection() {
    final fields = <String, List<String>>{
      'fresh_food': ['خيارات البيع', 'بلد المنشأ', 'طريقة الحفظ'],
      'canned_food': ['نوع العبوة', 'الوزن أو الحجم', 'تاريخ الصلاحية'],
      'electronics': ['العلامة التجارية', 'الموديل', 'مدة الضمان'],
      'toys': ['الفئة العمرية', 'الخامة', 'محتويات العبوة'],
    }[_productType];
    if (fields == null) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'تفاصيل المنتج حسب التخصص',
      subtitle: 'أضف المعلومات الخاصة بهذا النوع من المتاجر.',
      icon: Icons.tune_rounded,
      child: Column(
        children: fields
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _textField(
                  controller: _storeAttributeController(label),
                  label: label,
                  icon: Icons.edit_note_rounded,
                  maxLines: label == 'محتويات العبوة' ? 2 : 1,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readyForSave = _nameArController.text.trim().isNotEmpty &&
        _categoryId != null &&
        _priceValue > 0 &&
        _primaryImageBytes != null;

    return DashboardPageShell(
      title: 'إضافة صنف جديد',
      subtitle: 'إضافة أو تعديل صنف مع الصور والإضافات والخصائص.',
      icon: _auth.isStore ? Icons.shopping_bag_outlined : Icons.fastfood_rounded,
      activeSidebarIndex: 5,
      actions: [
        IconButton.filledTonal(
          onPressed: _isMetaReloading ? null : () => _loadMeta(),
          icon: _isMetaReloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProduct,
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
              label: Text(_isSaving ? '\u062c\u0627\u0631\u064a \u0627\u0644\u062d\u0641\u0638' : ((_productType == 'fashion' || _productType == 'shoes') ? '\u062d\u0641\u0638 \u0648\u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0623\u0644\u0648\u0627\u0646 \u0648\u0627\u0644\u0645\u0642\u0627\u0633\u0627\u062a' : '\u062d\u0641\u0638 \u0627\u0644\u0645\u0646\u062a\u062c')),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'القسم',
          value: _selectedCategory == null
              ? 'غير محدد'
              : _categoryLabel(_selectedCategory!),
          icon: Icons.category_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'الصور',
          value: '$_imageCount',
          icon: Icons.image_rounded,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'الحالة',
          value: _isAvailable ? 'متاح' : 'مخفي',
          icon: _isAvailable
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          tint: _isAvailable ? kAccent : const Color(0xFFEF4444),
        ),
        DashboardStatCard(
          label: 'الجاهزية',
          value: readyForSave ? 'جاهز' : 'يحتاج بيانات',
          icon: Icons.task_alt_rounded,
          tint: readyForSave ? kAccent : const Color(0xFFF59E0B),
        ),
      ],
      onRefreshPressed: () => _loadMeta(),
      body: _isLoading
          ? _buildLoadingPanel()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.offNamed(DashboardRoutes.menu),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('العودة إلى القائمة'),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1100;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildFormPanel()),
                          const SizedBox(width: 18),
                          Expanded(flex: 2, child: _buildPreviewPanel()),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildPreviewPanel(),
                        const SizedBox(height: 18),
                        _buildFormPanel(),
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
                  fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.label,
    required this.value,
    this.valueColor = kTextPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
              fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyProductPreview extends StatelessWidget {
  const _EmptyProductPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Icon(Icons.restaurant_rounded, size: 36, color: kPrimary),
          SizedBox(height: 10),
          Text(
            'أضف صورة رئيسية واضحة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'الصورة الجيدة ترفع من جودة الواجهة داخل تطبيق المستخدم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImageCard extends StatelessWidget {
  const _CoverImageCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'الصورة الرئيسية',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_rounded),
                label: Text(hasImage ? 'تغيير' : 'اختيار'),
              ),
              const SizedBox(width: 8),
              if (hasImage)
                TextButton(
                  onPressed: onClear,
                  child: const Text('إزالة'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kStroke),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : const _CoverPlaceholder(),
          ),
          if (imageName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              imageName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7FAF7), Color(0xFFE8F2EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded, size: 34, color: kPrimary),
          SizedBox(height: 10),
          Text(
            'اختر صورة رئيسية للمنتج',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'تظهر في بطاقة المنتج داخل التطبيق.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({
    required this.images,
    required this.coverName,
    required this.onAdd,
    required this.onSetCover,
    required this.onRemove,
  });

  final List<_PickedImage> images;
  final String? coverName;
  final VoidCallback onAdd;
  final ValueChanged<int> onSetCover;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kStroke),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'لم تضف صوراً إضافية بعد',
                style: TextStyle(
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('إضافة'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = images[index];
          final isCover = coverName == image.name;

          return _GalleryTile(
            image: image,
            isCover: isCover,
            onSetCover: () => onSetCover(index),
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.image,
    required this.isCover,
    required this.onSetCover,
    required this.onRemove,
  });

  final _PickedImage image;
  final bool isCover;
  final VoidCallback onSetCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCover ? kPrimary : kStroke, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(image.bytes, fit: BoxFit.cover),
            Positioned(
              left: 8,
              top: 8,
              child: _TinyChip(label: isCover ? 'رئيسية' : 'صورة'),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: PopupMenuButton<String>(
                tooltip: 'خيارات الصورة',
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: kSurface,
                onSelected: (value) {
                  if (value == 'cover') onSetCover();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'cover',
                    child: Text('تعيين كصورة رئيسية'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Text('إزالة'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                image.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedImage {
  _PickedImage({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

class _VendorRef {
  _VendorRef({
    required this.id,
    required this.label,
  });

  factory _VendorRef.fromJson(Map<String, dynamic> json) {
    final storeName = json['store_name']?.toString().trim() ?? '';
    final vendorName = json['vendor_name']?.toString().trim() ?? '';
    final label = [
      if (storeName.isNotEmpty) storeName,
      if (vendorName.isNotEmpty) vendorName,
    ].join(' • ');

    return _VendorRef(
      id: json['vendor_id']?.toString() ?? '',
      label: label.isEmpty ? 'مورد غير معروف' : label,
    );
  }

  final String id;
  final String label;
}
