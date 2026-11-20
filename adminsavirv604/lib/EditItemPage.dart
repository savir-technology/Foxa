// ignore_for_file: file_names, use_build_context_synchronously, unused_element

import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/model/categories_model.dart';
import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/remote/category_data.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:admin_tks/widgets/product_modifier_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditItemPage extends StatefulWidget {
  const EditItemPage({required this.item, super.key});

  final ItemsModel item;

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _descAr = TextEditingController();
  final _descEn = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _bodyHeightValues =
      TextEditingController(text: '150, 160, 165, 170, 175, 180, 185');
  final _bodyWeightValues =
      TextEditingController(text: '45, 50, 60, 70, 80, 90, 100');

  final List<cat> _categories = [];
  final List<_ColorRef> _colors = [];
  final List<_SizeRef> _sizes = [];
  final List<_EditableImage> _galleryImages = [];
  final List<_VariantDraft> _variants = [];
  final List<ProductModifierGroupDraft> _modifierGroups = [];
  final List<_AttributeDraft> _attributes = [];

  List<_SizeRef> get _sizesForProduct {
    if (_productType == 'shoes') {
      // Keep compatibility with older API responses that do not yet include
      // product_type on sizes, but already return numeric shoe sizes.
      return _sizes
          .where((size) =>
              size.productType == 'shoes' ||
              (int.tryParse(size.name) != null &&
                  int.parse(size.name) >= 20 &&
                  int.parse(size.name) <= 60))
          .toList();
    }
    return _sizes.where((size) => size.productType == 'fashion').toList();
  }

  String? _categoryId;
  String _productType = 'food';
  String _stockUnit = 'piece';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _includeBodyHeight = false;
  bool _includeBodyWeight = false;

  double get _totalStock => _variants.fold<double>(
        0,
        (sum, item) => sum + (double.tryParse(item.stockController.text) ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _seedFromItem();
    _loadEditData();
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _descAr.dispose();
    _descEn.dispose();
    _price.dispose();
    _discount.dispose();
    _bodyHeightValues.dispose();
    _bodyWeightValues.dispose();
    for (final entry in _variants.asMap().entries) {
      final variant = entry.value;
      variant.dispose();
    }
    for (final group in _modifierGroups) {
      group.dispose();
    }
    for (final attribute in _attributes) {
      attribute.dispose();
    }
    super.dispose();
  }

  void _seedFromItem() {
    _nameAr.text = widget.item.itemsNameAr ?? '';
    _nameEn.text = widget.item.itemsNameEn ?? '';
    _descAr.text = widget.item.itemsDescAr ?? '';
    _descEn.text = widget.item.itemsDescEn ?? '';
    _price.text = widget.item.itemsPrice ?? '';
    _discount.text = widget.item.itemsDiscount ?? '0';
    _categoryId = widget.item.itemsCat;
    _productType = widget.item.productType ?? _productType;
    _stockUnit = widget.item.stockUnit ?? _stockUnit;
    if ((widget.item.productType ?? '').trim().isEmpty &&
        Get.isRegistered<DashboardAuthController>()) {
      final auth = Get.find<DashboardAuthController>();
      if (auth.isStore && auth.storeCategory != null) {
        _productType = auth.storeCategory!;
        _stockUnit = _defaultUnitForCategory(auth.storeCategory!);
      }
    }
  }

  String _defaultUnitForCategory(String category) {
    switch (category) {
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

  Future<void> _loadEditData() async {
    try {
      final itemId = widget.item.itemsId;
      if (itemId == null || itemId.isEmpty) {
        _showToast('رقم المنتج غير صالح');
        return;
      }

      final responses = await Future.wait([
        CategoryData().getCategories(),
        ItemsData().getItemEditData(itemId),
      ]);

      final categories = responses[0] as List<cat>;
      final editData = responses[1] as Map<String, dynamic>?;

      _categories
        ..clear()
        ..addAll(categories);

      if (editData != null && editData['status'] == 'success') {
        final itemData = editData['item'] as Map<String, dynamic>? ?? {};
        final imagesData = (editData['images'] as List?) ?? [];
        final variantsData = (editData['variants'] as List?) ?? [];
        final modifierGroupsData = (editData['modifier_groups'] as List?) ?? [];
        final attributesData = (editData['attributes'] as List?) ?? [];
        final colorsData = (editData['colors'] as List?) ?? [];
        final sizesData = (editData['sizes'] as List?) ?? [];

        _nameAr.text = itemData['items_name_ar']?.toString() ?? _nameAr.text;
        _nameEn.text = itemData['items_name_en']?.toString() ?? _nameEn.text;
        _descAr.text = itemData['items_desc_ar']?.toString() ?? _descAr.text;
        _descEn.text = itemData['items_desc_en']?.toString() ?? _descEn.text;
        _price.text = itemData['items_price']?.toString() ?? _price.text;
        _discount.text =
            itemData['items_discount']?.toString() ?? _discount.text;
        _categoryId = itemData['items_cat']?.toString() ?? _categoryId;
        _productType = itemData['product_type']?.toString() ?? _productType;
        _stockUnit = itemData['stock_unit']?.toString() ?? _stockUnit;

        _colors
          ..clear()
          ..addAll(
            colorsData.map(
              (e) => _ColorRef.fromJson((e as Map).cast<String, dynamic>()),
            ),
          );
        _sizes
          ..clear()
          ..addAll(
            sizesData.map(
              (e) => _SizeRef.fromJson((e as Map).cast<String, dynamic>()),
            ),
          );

        _galleryImages.clear();
        for (final raw in imagesData) {
          final map = (raw as Map).cast<String, dynamic>();
          final path = map['img_path']?.toString() ?? '';
          if (path.isEmpty) continue;
          _galleryImages.add(
            _EditableImage.remote(
              url: _resolveItemImageUrl(path),
              name: path.split('/').last,
              colorId: map['color_id']?.toString(),
              imgType: map['img_type']?.toString() ?? 'normal',
            ),
          );
          if (_productType == 'fresh_food') break;
        }

        if (_galleryImages.isEmpty &&
            widget.item.itemsImage != null &&
            widget.item.itemsImage!.isNotEmpty) {
          _galleryImages.add(
            _EditableImage.remote(
              url: _resolveItemImageUrl(widget.item.itemsImage!),
              name: widget.item.itemsImage!,
            ),
          );
        }

        _variants.clear();
        for (final raw in variantsData) {
          final map = (raw as Map).cast<String, dynamic>();
          final draft = _VariantDraft(
            map['color_id']?.toString(),
            map['size_id']?.toString(),
          );
          draft.priceController.text = map['price']?.toString() ?? '';
          draft.stockController.text = map['stock']?.toString() ?? '0';
          draft.skuController.text = map['sku']?.toString() ?? '';
          draft.unitQuantityController.text = map['unit_quantity']?.toString() ?? '1';
          draft.imageUrl = map['image_url']?.toString();
          _variants.add(draft);
        }

        // A shoe may have been created before colour/size variants were
        // enabled. Give its existing generic variant valid defaults so the
        // dropdowns are usable and the product can be saved normally.
        if (_productType == 'shoes' && _variants.isNotEmpty &&
            _colors.isNotEmpty && _sizesForProduct.isNotEmpty) {
          for (final variant in _variants) {
            variant.colorId ??= _colors.first.id;
            variant.sizeId ??= _sizesForProduct.first.id;
          }
        }

        if (_variants.isEmpty && _colors.isNotEmpty && _sizes.isNotEmpty) {
          _variants.add(_VariantDraft(_colors.first.id, _sizes.first.id));
        }

        _modifierGroups
          ..clear()
          ..addAll(
            modifierGroupsData
                .whereType<Map>()
                .map(
                  (e) => ProductModifierGroupDraft.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(),
          );
        _attributes
          ..clear()
          ..addAll(attributesData.whereType<Map>().map((raw) =>
              _AttributeDraft.fromJson(Map<String, dynamic>.from(raw))));
        for (final attribute in _attributes) {
          final name = attribute.nameArController.text.trim();
          final values = attribute.valuesController.text.trim();
          if (name.contains('الطول') || name.toLowerCase().contains('height')) {
            _includeBodyHeight = true;
            _bodyHeightValues.text = values;
          }
          if (name.contains('الوزن') || name.toLowerCase().contains('weight')) {
            _includeBodyWeight = true;
            _bodyWeightValues.text = values;
          }
        }
      }

      if (_categoryId != null &&
          !_categories
              .any((category) => category.categoriesId == _categoryId)) {
        _categoryId = null;
      }
    } catch (_) {
      _showToast('تعذر تحميل بيانات التعديل');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickGalleryImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    if (result == null) return;

    final picked = result.files
        .where((file) => file.bytes != null && file.bytes!.isNotEmpty)
        .map(
            (file) => _EditableImage.local(name: file.name, bytes: file.bytes!))
        .toList();

    if (picked.isEmpty) return;
    if (_productType == 'fresh_food') {
      setState(() {
        _galleryImages
          ..clear()
          ..add(picked.first);
      });
      return;
    }
    setState(() => _galleryImages.addAll(picked));
  }

  Future<void> _pickVariantImage(_VariantDraft variant) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      variant.imageName = result.files.single.name;
      variant.imageBytes = result.files.single.bytes!;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final itemId = widget.item.itemsId;
    if (itemId == null || itemId.isEmpty) return;

    if (Get.isRegistered<DashboardAuthController>()) {
      final auth = Get.find<DashboardAuthController>();
      if (auth.isStore && auth.storeCategory != null &&
          _productType != auth.storeCategory) {
        _showToast('Product type must match the store specialization');
        return;
      }
    }

    final basicValues = [
      _nameAr.text,
      _nameEn.text,
      _descAr.text,
      _descEn.text,
      _price.text,
      _discount.text,
    ];

    if (basicValues.any((v) => v.trim().isEmpty) || _categoryId == null) {
      _showToast('أكمل بيانات المنتج الأساسية أولًا');
      return;
    }
    if (_galleryImages.isEmpty) {
      _showToast('أضف صور معرض المنتج أولًا');
      return;
    }
    if (_variants.isEmpty && _productType == 'food') {
      _showToast('أضف Variant واحد على الأقل');
      return;
    }

    final itemPrice = double.tryParse(_price.text.trim());
    final itemDiscount = int.tryParse(_discount.text.trim());
    if (itemPrice == null || itemDiscount == null) {
      _showToast('راجع السعر أو الخصم');
      return;
    }

    final keys = <String>{};
    final variantsPayload = <Map<String, dynamic>>[];

    for (final entry in _variants.asMap().entries) {
      final index = entry.key;
      final variant = entry.value;
      final price = double.tryParse(variant.priceController.text.trim());
      final stock = double.tryParse(variant.stockController.text.trim());
      final needsLegacyDimensions = _productType == 'food' ||
          _productType == 'fashion' ||
          _productType == 'shoes';
      if ((needsLegacyDimensions &&
              (variant.colorId == null || variant.sizeId == null)) ||
          price == null ||
          stock == null) {
        _showToast('راجع بيانات الـ Variants');
        return;
      }

      final key = needsLegacyDimensions
          ? '${variant.colorId}-${variant.sizeId}'
          : 'generic-$index';
      if (!keys.add(key)) {
        _showToast('لا يمكن تكرار نفس اللون والمقاس');
        return;
      }

      final variantMap = <String, dynamic>{
        if (variant.colorId != null) 'color_id': int.tryParse(variant.colorId!),
        if (variant.sizeId != null) 'size_id': int.tryParse(variant.sizeId!),
        'price': price,
        'stock': stock.floor(),
        'stock_quantity': stock,
        'unit': _stockUnit,
        'unit_quantity': double.tryParse(variant.unitQuantityController.text.trim()) ?? 1,
      };
      if (variant.skuController.text.trim().isNotEmpty) {
        variantMap['sku'] = variant.skuController.text.trim();
      }
      if (variant.imageBytes != null) {
        variantMap['image'] = base64Encode(variant.imageBytes!);
      } else if (variant.imageUrl != null && variant.imageUrl!.isNotEmpty) {
        variantMap['image_url'] = variant.imageUrl;
      }
      variantsPayload.add(variantMap);
    }
    if (variantsPayload.isEmpty && _productType != 'food') {
      variantsPayload.add({
        'price': itemPrice,
        'stock': int.tryParse(widget.item.itemsCount ?? '0') ?? 0,
        'unit': _stockUnit,
      });
    }

    final modifierGroupsPayload = <Map<String, dynamic>>[];
    for (final group in _modifierGroups) {
      if (!group.hasContent) {
        continue;
      }

      final groupNameAr = group.nameArController.text.trim();
      final groupNameEn = group.nameEnController.text.trim();
      if (groupNameAr.isEmpty && groupNameEn.isEmpty) {
        _showToast('أدخل اسم مجموعة التخصيص قبل الحفظ');
        return;
      }

      final optionPayloads = <Map<String, dynamic>>[];
      for (final option in group.options) {
        if (!option.hasContent) {
          continue;
        }

        final optionNameAr = option.nameArController.text.trim();
        final optionNameEn = option.nameEnController.text.trim();
        if (optionNameAr.isEmpty && optionNameEn.isEmpty) {
          _showToast('أدخل اسم كل خيار داخل مجموعة "${group.groupLabel}"');
          return;
        }

        final optionPayload =
            option.toPayload(sortOrder: optionPayloads.length);
        if (optionPayload != null) {
          optionPayloads.add(optionPayload);
        }
      }

      if (optionPayloads.isEmpty) {
        _showToast(
            'أضف خيارًا واحدًا على الأقل داخل مجموعة "${group.groupLabel}"');
        return;
      }

      final minSelect =
          int.tryParse(group.minSelectController.text.trim()) ?? 0;
      final maxSelect =
          int.tryParse(group.maxSelectController.text.trim()) ?? 1;
      final normalizedMin = minSelect < 0 ? 0 : minSelect;
      final normalizedMax = maxSelect < 1
          ? 1
          : (maxSelect < normalizedMin ? normalizedMin : maxSelect);

      modifierGroupsPayload.add({
        'name_ar': groupNameAr,
        'name_en': groupNameEn,
        'group_type': group.groupType,
        'min_select': normalizedMin,
        'max_select': normalizedMax,
        'is_required': group.isRequired,
        'sort_order': modifierGroupsPayload.length,
        'is_active': group.isActive,
        'options': optionPayloads,
      });
    }

    final imagesPayload = (_productType == 'fresh_food'
            ? _galleryImages.take(1)
            : _galleryImages)
        .map((image) {
      if (image.bytes != null) {
        return <String, dynamic>{
          'data': base64Encode(image.bytes!),
          'color_id':
              image.colorId == null ? null : int.tryParse(image.colorId!),
          'img_type': image.imgType,
        };
      }

      return <String, dynamic>{
        'url': image.url,
        'color_id': image.colorId == null ? null : int.tryParse(image.colorId!),
        'img_type': image.imgType,
      };
    }).toList();

    setState(() => _isSaving = true);
    final response = await ItemsData().updateItemPayload({
      'items_id': int.parse(itemId),
      'items_name_ar': _nameAr.text.trim(),
      'items_name_en': _nameEn.text.trim(),
      'items_desc_ar': _descAr.text.trim(),
      'items_desc_en': _descEn.text.trim(),
      'items_price': itemPrice,
      'items_discount': itemDiscount,
      'items_cat': int.parse(_categoryId!),
      'items_active': int.tryParse(widget.item.itemsActive ?? '1') ?? 1,
      'images': imagesPayload,
      'variants': variantsPayload,
      'modifier_groups': modifierGroupsPayload,
      'product_type': _productType,
      'stock_unit': _stockUnit,
      'stock_step': _stockUnit == 'piece' ? 1 : 0.001,
    });

    if (mounted) {
      setState(() => _isSaving = false);
    }

    if (response != null && response['status'] == 'success') {
      _showToast('تم تحديث المنتج بنجاح');
      await ItemsData().saveItemAttributes(itemId, _effectiveAttributesPayload());
      Navigator.pop(context, true);
    } else {
      _showToast(response?['message']?.toString() ?? 'فشل تحديث المنتج');
    }
  }

  List<Map<String, dynamic>> _effectiveAttributesPayload() {
    final payload = _attributes
        .where((attribute) {
          final name = attribute.nameArController.text.trim().toLowerCase();
          return !name.contains('الطول') &&
              !name.contains('الوزن') &&
              !name.contains('height') &&
              !name.contains('weight');
        })
        .map((attribute) => attribute.toPayload())
        .toList();

    List<Map<String, dynamic>> measurement(String nameAr, String nameEn, String raw) {
      final values = raw
          .split(RegExp(r'[,،]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (values.isEmpty) return const [];
      return [
        {
          'name_ar': nameAr,
          'name_en': nameEn,
          'is_required': true,
          'values': values
              .map((value) => {'value_ar': value, 'value_en': value})
              .toList(),
        },
      ];
    }
    if (_productType == 'fashion') {
      if (_includeBodyHeight) {
        payload.addAll(measurement(
          'الطول (سم)', 'Height (cm)', _bodyHeightValues.text));
      }
      if (_includeBodyWeight) {
        payload.addAll(measurement(
          'الوزن (كجم)', 'Weight (kg)', _bodyWeightValues.text));
      }
    }
    return payload;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF9FBFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kStroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardPageShell(
      title: 'تعديل المنتج',
      subtitle: 'حدث كل صور المنتج ونسخه القابلة للبيع من نفس الشاشة.',
      icon: Icons.edit_rounded,
      stats: [
        DashboardStatCard(
          label: 'المنتج',
          value: widget.item.itemsId ?? '-',
          icon: Icons.badge_outlined,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'صور المعرض',
          value: '${_galleryImages.length}',
          icon: Icons.photo_library_outlined,
          tint: kAccent,
        ),
        DashboardStatCard(
          label: 'الخيارات',
          value: '${_variants.length}',
          icon: Icons.widgets_outlined,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'مجموعات التخصيص',
          value: '${_modifierGroups.length}',
          icon: Icons.layers_outlined,
          tint: const Color(0xFF8B5CF6),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(
              children: [
                _buildInfoSection(),
                _buildGallerySection(),
                _buildVariantsSection(),
                if (_productType == 'fashion') _buildClothingFitOptionsSection(),
                _buildAttributesSection(),
                if (!Get.find<DashboardAuthController>().isStore)
                  _buildModifiersSection(),
                DashboardPanel(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined),
                                SizedBox(width: 10),
                                Text('حفظ التعديلات'),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoSection() {
    return _SectionShell(
      title: 'بيانات المنتج',
      subtitle: 'عدل الاسم والوصف والسعر والقسم والخصم.',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          TextField(
            controller: _nameAr,
            decoration: _fieldDecoration('اسم المنتج بالعربية'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameEn,
            decoration: _fieldDecoration('اسم المنتج بالإنجليزية'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descAr,
            maxLines: 3,
            decoration: _fieldDecoration('وصف المنتج بالعربية'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descEn,
            maxLines: 3,
            decoration: _fieldDecoration('وصف المنتج بالإنجليزية'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('السعر الأساسي'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('الخصم %'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categories
                    .any((category) => category.categoriesId == _categoryId)
                ? _categoryId
                : null,
            decoration: _fieldDecoration('القسم'),
            items: _categories
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.categoriesId,
                    child: Text(
                        item.categoriesNameAr ?? item.categoriesNameEn ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: const [
                    'food',
                    'fashion',
                    'shoes',
                    'perfume',
                    'grocery',
                    'fresh_food',
                    'canned_food',
                    'electronics',
                    'toys',
                  ].contains(_productType)
                      ? _productType
                      : null,
                  decoration: _fieldDecoration('نوع المنتج'),
                  items: const [
                    DropdownMenuItem(
                        value: 'food', child: Text('مطاعم / أطعمة')),
                    DropdownMenuItem(value: 'fashion', child: Text('ملابس')),
                    DropdownMenuItem(value: 'shoes', child: Text('أحذية')),
                    DropdownMenuItem(value: 'perfume', child: Text('عطور')),
                    DropdownMenuItem(value: 'grocery', child: Text('بقالة')),
                                        DropdownMenuItem(value: 'fresh_food', child: Text('Fresh food')),
                    DropdownMenuItem(value: 'canned_food', child: Text('Canned food')),
                    DropdownMenuItem(
                        value: 'electronics', child: Text('إلكترونيات')),
                                        DropdownMenuItem(value: 'toys', child: Text('Toys')),
                  ],
                  onChanged: (value) => setState(() {
                    _productType = value ?? 'general';
                    _stockUnit = _defaultUnitForCategory(_productType);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _stockUnit,
                  decoration: _fieldDecoration('وحدة المخزون'),
                  items: const [
                    DropdownMenuItem(value: 'piece', child: Text('قطعة')),
                    DropdownMenuItem(value: 'kg', child: Text('كيلو')),
                    DropdownMenuItem(value: 'g', child: Text('جرام')),
                    DropdownMenuItem(value: 'l', child: Text('لتر')),
                    DropdownMenuItem(value: 'ml', child: Text('مل')),
                    DropdownMenuItem(value: 'pack', child: Text('عبوة')),
                  ],
                  onChanged: (value) =>
                      setState(() => _stockUnit = value ?? 'piece'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return _SectionShell(
      title: 'معرض الصور',
      subtitle: 'أضف أو احذف الصور كما في صفحة الإضافة.',
      icon: Icons.photo_library_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'أول صورة في الترتيب ستكون الصورة الرئيسية.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _productType == 'fresh_food' ? null : _pickGalleryImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('إضافة صور'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_galleryImages.isEmpty)
            const _EmptyPanel(
              title: 'لا توجد صور بعد',
              subtitle: 'أضف صور المنتج من زوايا مختلفة لإكمال التعديل.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _galleryImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return _GalleryTile(
                  image: image,
                  tag: index == 0 ? 'الصورة الرئيسية' : 'صورة معرض',
                  highlighted: index == 0,
                  onDelete: () =>
                      setState(() => _galleryImages.removeAt(index)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection() {
    return _SectionShell(
      title: 'خصائص المتجر',
      subtitle:
          'أضف مثلًا السعة أو الوزن أو الرائحة. اكتب القيم مفصولة بفاصلة.',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          ..._attributes.asMap().entries.map((entry) {
            final attribute = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: attribute.nameArController,
                        decoration: _fieldDecoration('اسم الخاصية'))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: attribute.valuesController,
                        decoration:
                            _fieldDecoration('القيم: 30ml, 50ml, 100ml'))),
                IconButton(
                    onPressed: () => setState(() {
                          attribute.dispose();
                          _attributes.removeAt(entry.key);
                        }),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent)),
              ]),
            );
          }),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _attributes.add(_AttributeDraft())),
              icon: const Icon(Icons.add),
              label: const Text('إضافة خاصية'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingFitOptionsSection() {
    return _SectionShell(
      title: 'Clothing fit options',
      subtitle: 'Enable optional customer measurements for this clothing item.',
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
            TextField(
              controller: _bodyHeightValues,
              decoration: _fieldDecoration('Height values in cm'),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ask for weight / الوزن'),
            value: _includeBodyWeight,
            onChanged: (value) => setState(() => _includeBodyWeight = value),
          ),
          if (_includeBodyWeight)
            TextField(
              controller: _bodyWeightValues,
              decoration: _fieldDecoration('Weight values in kg'),
            ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    return _SectionShell(
      title: 'النسخ الجاهزة للبيع',
      subtitle: 'لون + مقاس + سعر + مخزون + صورة اختيارية.',
      icon: Icons.widgets_outlined,
      accented: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'عدد النسخ الحالي: ${_variants.length} | إجمالي المخزون: $_totalStock',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_productType == 'food' &&
                        (_colors.isEmpty || _sizes.isEmpty))
                    ? null
                    : () => setState(
                          () => _variants.add(_VariantDraft(
                            _colors.isEmpty ? null : _colors.first.id,
                            _sizes.isEmpty ? null : _sizes.first.id,
                          )),
                        ),
                icon: const Icon(Icons.add),
                label: const Text('إضافة Variant'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_variants.isEmpty)
            const _EmptyPanel(
              title: 'لا توجد Variants بعد',
              subtitle: 'أضف على الأقل Variant واحد لإتمام التعديل.',
            )
          else
            ..._variants.asMap().entries.map((entry) {
              final index = entry.key;
              final variant = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _VariantCard(
                  index: index + 1,
                  variant: variant,
                  colors: _colors,
                  sizes: _sizesForProduct,
                  showDimensions: _productType == 'food' ||
                      _productType == 'fashion' ||
                      _productType == 'shoes',
                  stockUnit: _stockUnit,
                  showUnitQuantity: _productType == 'fresh_food',
                  onChanged: () => setState(() {}),
                  onDelete: _variants.length == 1
                      ? null
                      : () {
                          variant.dispose();
                          setState(() => _variants.removeAt(index));
                        },
                  onPickImage: () => _pickVariantImage(variant),
                  decorationBuilder: _fieldDecoration,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildModifiersSection() {
    return _SectionShell(
      title: 'مجموعات التخصيص',
      subtitle:
          'أضف الإضافات أو المكونات الأساسية التي تظهر داخل صفحة تفاصيل المنتج في تطبيق المستخدم.',
      icon: Icons.tune_rounded,
      accented: true,
      child: ProductModifierGroupsEditor(
        groups: _modifierGroups,
        decorationBuilder: _fieldDecoration,
        onChanged: () => setState(() {}),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.accented = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DashboardPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accented ? kAccent : kPrimary,
                        (accented ? kAccent : kPrimary).withValues(alpha: 0.62),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: kTextSecondary.withValues(alpha: 0.8), size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.image,
    required this.tag,
    required this.onDelete,
    required this.highlighted,
  });

  final _EditableImage image;
  final String tag;
  final VoidCallback onDelete;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted ? kPrimary.withValues(alpha: 0.32) : kStroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: image.bytes != null
                  ? Image.memory(image.bytes!, fit: BoxFit.cover)
                  : AppNetworkImage(
                      imageUrl: _resolveItemImageUrl(image.url ?? image.name),
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.image_not_supported_outlined,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tag,
            style: TextStyle(
              color: highlighted ? kPrimary : kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            image.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F1),
                foregroundColor: Colors.redAccent,
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.index,
    required this.variant,
    required this.colors,
    required this.sizes,
    required this.showDimensions,
    required this.stockUnit,
    required this.showUnitQuantity,
    required this.onChanged,
    required this.onDelete,
    required this.onPickImage,
    required this.decorationBuilder,
  });

  final int index;
  final _VariantDraft variant;
  final List<_ColorRef> colors;
  final List<_SizeRef> sizes;
  final bool showDimensions;
  final String stockUnit;
  final bool showUnitQuantity;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;
  final VoidCallback onPickImage;
  final InputDecoration Function(String label) decorationBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStroke),
      ),
      child: Column(
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
                  'Variant $index',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
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
          const SizedBox(height: 12),
          if (showDimensions)
            Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: variant.colorId,
                  decoration: decorationBuilder('اللون'),
                  items: colors
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    variant.colorId = value;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: variant.sizeId,
                  decoration: decorationBuilder('المقاس'),
                  items: sizes
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    variant.sizeId = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          if (!showDimensions) ...[
            const SizedBox(height: 12),
            TextField(
              controller: variant.skuController,
              decoration: decorationBuilder(
                stockUnit == 'ml' ? 'السعة أو الحجم (ml)' : 'العبوة أو الخيار',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
          if (showUnitQuantity) ...[
            const SizedBox(height: 12),
            TextField(
              controller: variant.unitQuantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: decorationBuilder('كمية البيع (كجم)'),
              onChanged: (_) => onChanged(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: variant.priceController,
                  keyboardType: TextInputType.number,
                  decoration: decorationBuilder('السعر'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: variant.stockController,
                  keyboardType: TextInputType.number,
                  decoration: decorationBuilder('المخزون'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kStroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    variant.imageName ??
                        (variant.imageUrl?.isNotEmpty == true
                            ? variant.imageUrl!.split('/').last
                            : 'صورة اختيارية لهذا الـ Variant'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kTextSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onPickImage,
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
}

class _EditableImage {
  _EditableImage.local({
    required this.name,
    required this.bytes,
  })  : url = null,
        colorId = null,
        imgType = 'normal';

  _EditableImage.remote({
    required this.url,
    required this.name,
    this.colorId,
    this.imgType = 'normal',
  }) : bytes = null;

  final String name;
  final Uint8List? bytes;
  final String? url;
  final String? colorId;
  final String imgType;
}

class _VariantDraft {
  _VariantDraft(this.colorId, this.sizeId);

  String? colorId;
  String? sizeId;
  String? imageName;
  Uint8List? imageBytes;
  String? imageUrl;
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController =
      TextEditingController(text: '0');
  final TextEditingController skuController = TextEditingController();
  final TextEditingController unitQuantityController =
      TextEditingController(text: '1');

  void dispose() {
    priceController.dispose();
    stockController.dispose();
    skuController.dispose();
    unitQuantityController.dispose();
  }
}

class _AttributeDraft {
  _AttributeDraft();

  factory _AttributeDraft.fromJson(Map<String, dynamic> json) {
    final draft = _AttributeDraft();
    draft.nameArController.text =
        json['name_ar']?.toString() ?? json['name_en']?.toString() ?? '';
    draft.valuesController.text = ((json['values'] as List?) ?? const [])
        .whereType<Map>()
        .map((value) =>
            value['value_ar']?.toString() ??
            value['value_en']?.toString() ??
            '')
        .where((value) => value.isNotEmpty)
        .join(', ');
    return draft;
  }

  final nameArController = TextEditingController();
  final valuesController = TextEditingController();

  Map<String, dynamic> toPayload() => {
        'name_ar': nameArController.text.trim(),
        'name_en': nameArController.text.trim(),
        'values': valuesController.text
            .split(',')
            .map(
                (value) => {'value_ar': value.trim(), 'value_en': value.trim()})
            .where((value) => (value['value_ar'] as String).isNotEmpty)
            .toList(),
      };

  void dispose() {
    nameArController.dispose();
    valuesController.dispose();
  }
}

class _ColorRef {
  _ColorRef({required this.id, required this.name});

  factory _ColorRef.fromJson(Map<String, dynamic> json) {
    return _ColorRef(
      id: json['color_id'].toString(),
      name: json['color_name']?.toString() ?? 'Color',
    );
  }

  final String id;
  final String name;
}

class _SizeRef {
  _SizeRef({required this.id, required this.name, required this.productType});

  factory _SizeRef.fromJson(Map<String, dynamic> json) {
    return _SizeRef(
      id: json['size_id'].toString(),
      name: json['size_name']?.toString() ?? 'Size',
      productType: json['product_type']?.toString() ?? 'fashion',
    );
  }

  final String id;
  final String name;
  final String productType;
}

String _resolveItemImageUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return value;
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return Uri.encodeFull(value);
  }

  var normalized = value.replaceAll('\\', '/');
  if (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }

  if (normalized.startsWith('savir604/') || normalized.startsWith('zahra/')) {
    return Uri.encodeFull('https://savir-technology.online/roaqv2/$normalized');
  }

  if (normalized.contains('/')) {
    return Uri.encodeFull('https://savir-technology.online/roaqv2/$normalized');
  }

  return Uri.encodeFull(
      'https://savir-technology.online/roaqv2/uploud/items/$normalized');
}
