import 'dart:math';

import 'package:admin_tks/EditItemPage.dart';
import 'package:admin_tks/controler/items_controller.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/model/categories_model.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/remote/category_data.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  static const int _rowsPerPage = 6;

  final ItemsController _itemsController = Get.isRegistered<ItemsController>()
      ? Get.find<ItemsController>()
      : Get.put(ItemsController());
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final List<cat> _categories = [];

  bool _loadingCategories = true;
  int _currentPage = 0;
  String _activeCategoryId = 'all';
  String _activeActionFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final loaded = await CategoryData().getCategories();
      if (!mounted) return;
      _categories
        ..clear()
        ..addAll(loaded);
    } catch (_) {
      // Keep the current list if the category request fails.
    } finally {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    _itemsController.fetchItems();
    await _loadCategories();
  }

  Future<void> _openAddProduct() async {
    await Get.toNamed(DashboardRoutes.addProduct);
    _itemsController.fetchItems();
  }

  Future<void> _openEditItem(ItemsModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditItemPage(item: item)),
    );
    _itemsController.fetchItems();
  }

  Future<void> _deleteItem(ItemsModel item) async {
    final itemName = _itemName(item);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل تريد حذف "$itemName" نهائيا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    _itemsController.deleteItem(item.itemsId ?? '', item.itemsImage ?? '');
  }

  Future<void> _toggleStatus(ItemsModel item) async {
    final updated = ItemsModel(
      itemsId: item.itemsId,
      itemsNameEn: item.itemsNameEn,
      itemsNameAr: item.itemsNameAr,
      itemsDescEn: item.itemsDescEn,
      itemsDescAr: item.itemsDescAr,
      itemsImage: item.itemsImage,
      itemsCount: item.itemsCount,
      itemsActive: _isItemAvailable(item) ? '0' : '1',
      itemsPrice: item.itemsPrice,
      itemsDiscount: item.itemsDiscount,
      itemsDate: item.itemsDate,
      itemsCat: item.itemsCat,
      vendorId: item.vendorId,
      vendorName: item.vendorName,
      storeName: item.storeName,
      storeSlug: item.storeSlug,
    );

    _itemsController.updateItem(updated);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _itemsController.fetchItems();
  }

  void _showDuplicateNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تكرار الصنف يحتاج endpoint مخصص. تم إبقاء الزر بصريا بدون إرسال بيانات للسيرفر.',
        ),
      ),
    );
  }

  Future<void> _duplicateItem(ItemsModel item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جارٍ تكرار الصنف: ${_itemName(item)}')),
    );
    final result = await ItemsData().duplicateItem(item.itemsId ?? '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result?['status'] == 'success'
            ? 'تم تكرار الصنف بنجاح'
            : (result?['message']?.toString() ?? 'تعذر تكرار الصنف')),
      ),
    );
    if (result?['status'] == 'success') _itemsController.fetchItems();
  }

  void _resetPaging() {
    setState(() => _currentPage = 0);
  }

  List<ItemsModel> _filteredItems(List<ItemsModel> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      final name = _itemName(item).toLowerCase();
      final description = _itemDescription(item).toLowerCase();
      final categoryName = _categoryNameFor(item).toLowerCase();
      final stock = int.tryParse(item.itemsCount ?? '0') ?? 0;
      final available = _isItemAvailable(item);

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          description.contains(query) ||
          categoryName.contains(query);

      final matchesCategory = _activeCategoryId == 'all' ||
          (item.itemsCat ?? '').trim() == _activeCategoryId;

      final matchesAction = switch (_activeActionFilter) {
        'available' => available,
        'hidden' => !available,
        'low_stock' => stock <= 12,
        _ => true,
      };

      return matchesQuery && matchesCategory && matchesAction;
    }).toList();
  }

  String _itemName(ItemsModel item) {
    final ar = item.itemsNameAr?.trim() ?? '';
    final en = item.itemsNameEn?.trim() ?? '';
    if (ar.isNotEmpty) return ar;
    if (en.isNotEmpty) return en;
    return 'صنف بدون اسم';
  }

  String _itemDescription(ItemsModel item) {
    final ar = item.itemsDescAr?.trim() ?? '';
    final en = item.itemsDescEn?.trim() ?? '';
    if (ar.isNotEmpty) return ar;
    if (en.isNotEmpty) return en;
    return 'بدون وصف';
  }

  String _categoryLabel(cat category) {
    final ar = category.categoriesNameAr?.trim() ?? '';
    final en = category.categoriesNameEn?.trim() ?? '';
    if (ar.isNotEmpty && ar.toLowerCase() != 'null') return ar;
    if (en.isNotEmpty && en.toLowerCase() != 'null') return en;
    return 'قسم';
  }

  String _categoryNameFor(ItemsModel item) {
    final categoryId = item.itemsCat?.trim();
    if (categoryId == null || categoryId.isEmpty) return 'غير مصنف';

    for (final category in _categories) {
      if ((category.categoriesId ?? '').trim() == categoryId) {
        return _categoryLabel(category);
      }
    }

    return 'غير مصنف';
  }

  bool _isItemAvailable(ItemsModel item) {
    return (item.itemsActive ?? '1') != '0';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _itemsController.itemsList.toList();
      final filteredItems = _filteredItems(items);
      final maxPage = filteredItems.isEmpty
          ? 0
          : ((filteredItems.length - 1) / _rowsPerPage).floor();
      final page = min(_currentPage, maxPage);
      final start = filteredItems.isEmpty ? 0 : page * _rowsPerPage;
      final end = min(start + _rowsPerPage, filteredItems.length);
      final pageItems = filteredItems.sublist(start, end);

      return DashboardPageShell(
        title: 'إدارة قائمة الطعام',
        subtitle: 'إدارة وإضافة وتعديل وحذف الأطباق والإضافات',
        icon: Icons.restaurant_menu_rounded,
        activeSidebarIndex: 5,
        onRefreshPressed: _refreshAll,
        topPadding: 14,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategoryTabs(
                categories: _categories,
                loading: _loadingCategories,
                activeCategoryId: _activeCategoryId,
                scrollController: _categoryScrollController,
                itemCountForCategory: (categoryId) => items
                    .where((item) => (item.itemsCat ?? '').trim() == categoryId)
                    .length,
                categoryLabel: _categoryLabel,
                onChanged: (categoryId) {
                  _activeCategoryId = categoryId;
                  _resetPaging();
                },
              ),
              const SizedBox(height: 18),
              _MenuToolbar(
                searchController: _searchController,
                activeActionFilter: _activeActionFilter,
                onSearchChanged: (_) => _resetPaging(),
                onActionFilterChanged: (value) {
                  _activeActionFilter = value;
                  _resetPaging();
                },
                onAddProduct: _openAddProduct,
              ),
              const SizedBox(height: 18),
              _MenuItemsTable(
                isLoading: _itemsController.isLoading.value,
                items: pageItems,
                totalItems: filteredItems.length,
                startIndex: start,
                endIndex: end,
                currentPage: page,
                totalPages: maxPage + 1,
                rowsPerPage: _rowsPerPage,
                itemName: _itemName,
                itemDescription: _itemDescription,
                categoryNameFor: _categoryNameFor,
                isAvailable: _isItemAvailable,
                onEdit: _openEditItem,
                onDelete: _deleteItem,
                onToggle: _toggleStatus,
                onDuplicate: _duplicateItem,
                onPageChanged: (newPage) {
                  setState(() => _currentPage = newPage.clamp(0, maxPage));
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.loading,
    required this.activeCategoryId,
    required this.scrollController,
    required this.itemCountForCategory,
    required this.categoryLabel,
    required this.onChanged,
  });

  final List<cat> categories;
  final bool loading;
  final String activeCategoryId;
  final ScrollController scrollController;
  final int Function(String categoryId) itemCountForCategory;
  final String Function(cat category) categoryLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((category) => (category.categoriesId ?? '').trim().isNotEmpty)
        .toList();

    return SizedBox(
      height: 60,
      child: loading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListView.separated(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  dragStartBehavior: DragStartBehavior.start,
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: visibleCategories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CategoryTabButton(
                        label: 'الكل',
                        selected: activeCategoryId == 'all',
                        onTap: () => onChanged('all'),
                      );
                    }

                    final category = visibleCategories[index - 1];
                    final id = category.categoriesId!.trim();
                    return _CategoryTabButton(
                      label: categoryLabel(category),
                      selected: activeCategoryId == id,
                      count: itemCountForCategory(id),
                      onTap: () => onChanged(id),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _CategoryTabButton extends StatelessWidget {
  const _CategoryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 166,
      height: 46,
      child: Material(
        color: selected ? kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: selected ? kPrimary : kStroke),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.86)
                          : kTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuToolbar extends StatelessWidget {
  const _MenuToolbar({
    required this.searchController,
    required this.activeActionFilter,
    required this.onSearchChanged,
    required this.onActionFilterChanged,
    required this.onAddProduct,
  });

  final TextEditingController searchController;
  final String activeActionFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onActionFilterChanged;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 920;

    final search = _SearchField(
      controller: searchController,
      onChanged: onSearchChanged,
    );
    final actions = _ActionsMenuButton(
      activeActionFilter: activeActionFilter,
      onChanged: onActionFilterChanged,
    );
    final addButton = _AddProductButton(onPressed: onAddProduct);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: actions),
              const SizedBox(width: 10),
              Expanded(child: addButton),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 14),
        SizedBox(width: 150, child: actions),
        const SizedBox(width: 14),
        SizedBox(width: 180, child: addButton),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'ابحث عن صنف...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.search_rounded, size: 22),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: kStroke),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: kStroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: kPrimary),
          ),
        ),
      ),
    );
  }
}

class _ActionsMenuButton extends StatelessWidget {
  const _ActionsMenuButton({
    required this.activeActionFilter,
    required this.onChanged,
  });

  final String activeActionFilter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 44),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'all', child: Text('كل الأصناف')),
        PopupMenuItem(value: 'available', child: Text('المتاحة فقط')),
        PopupMenuItem(value: 'hidden', child: Text('المخفية فقط')),
        PopupMenuItem(value: 'low_stock', child: Text('مخزون منخفض')),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: kStroke),
        ),
        child: const Row(
          children: [
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: kTextSecondary),
            Spacer(),
            Text(
              'إجراءات',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 23),
        label: const Text('إضافة صنف'),
        style: FilledButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}

class _MenuItemsTable extends StatelessWidget {
  const _MenuItemsTable({
    required this.isLoading,
    required this.items,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.itemName,
    required this.itemDescription,
    required this.categoryNameFor,
    required this.isAvailable,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onDuplicate,
    required this.onPageChanged,
  });

  final bool isLoading;
  final List<ItemsModel> items;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final String Function(ItemsModel item) itemName;
  final String Function(ItemsModel item) itemDescription;
  final String Function(ItemsModel item) categoryNameFor;
  final bool Function(ItemsModel item) isAvailable;
  final ValueChanged<ItemsModel> onEdit;
  final ValueChanged<ItemsModel> onDelete;
  final ValueChanged<ItemsModel> onToggle;
  final ValueChanged<ItemsModel> onDuplicate;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(
              width: max(MediaQuery.sizeOf(context).width - 320, 980),
              child: Column(
                children: [
                  const _MenuTableHeader(),
                  if (isLoading)
                    const SizedBox(
                      height: 460,
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimary),
                      ),
                    )
                  else if (items.isEmpty)
                    const SizedBox(
                      height: 430,
                      child: Center(
                        child: DashboardEmptyState(
                          title: 'لا توجد أصناف مطابقة',
                          subtitle:
                              'غيّر البحث أو الفلتر، أو أضف صنفا جديدا من الزر بالأعلى.',
                          icon: Icons.restaurant_menu_rounded,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      _MenuTableRow(
                        item: items[i],
                        itemName: itemName(items[i]),
                        itemDescription: itemDescription(items[i]),
                        categoryName: categoryNameFor(items[i]),
                        isAvailable: isAvailable(items[i]),
                        onEdit: () => onEdit(items[i]),
                        onDelete: () => onDelete(items[i]),
                        onToggle: () => onToggle(items[i]),
                        onDuplicate: () => onDuplicate(items[i]),
                      ),
                      if (i != items.length - 1) const Divider(height: 1),
                    ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _MenuTableFooter(
            rowsPerPage: rowsPerPage,
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: totalItems,
            startIndex: startIndex,
            endIndex: endIndex,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

class _MenuTableHeader extends StatelessWidget {
  const _MenuTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kStroke)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 32, child: _HeaderLabel('الصنف')),
          Expanded(flex: 34, child: _HeaderLabel('الوصف')),
          Expanded(flex: 16, child: _HeaderLabel('السعر')),
          Expanded(flex: 16, child: _HeaderLabel('الحالة')),
          Expanded(flex: 24, child: _HeaderLabel('الإجراءات')),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: kTextPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MenuTableRow extends StatelessWidget {
  const _MenuTableRow({
    required this.item,
    required this.itemName,
    required this.itemDescription,
    required this.categoryName,
    required this.isAvailable,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onDuplicate,
  });

  final ItemsModel item;
  final String itemName;
  final String itemDescription;
  final String categoryName;
  final bool isAvailable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(item.itemsPrice ?? '0') ?? 0;

    return SizedBox(
      height: 92,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 32,
              child: _ProductIdentityCell(
                item: item,
                name: itemName,
                categoryName: categoryName,
              ),
            ),
            Expanded(
              flex: 34,
              child: Text(
                itemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
            ),
            Expanded(
              flex: 16,
              child: Text(
                '${_formatMenuMoney(price)} SAR',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              flex: 16,
              child: _AvailabilitySwitch(
                value: isAvailable,
                onChanged: onToggle,
              ),
            ),
            Expanded(
              flex: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RowActionButton(
                    label: 'تكرار',
                    icon: Icons.copy_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: onDuplicate,
                  ),
                  const SizedBox(width: 8),
                  _RowActionButton(
                    label: 'تعديل',
                    icon: Icons.edit_rounded,
                    color: const Color(0xFFF97316),
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _RowActionButton(
                    label: 'حذف',
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductIdentityCell extends StatelessWidget {
  const _ProductIdentityCell({
    required this.item,
    required this.name,
    required this.categoryName,
  });

  final ItemsModel item;
  final String name;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final imageName = item.itemsImage?.trim() ?? '';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 76,
            height: 56,
            color: const Color(0xFFF4F7FB),
            child: imageName.isEmpty || imageName.toLowerCase() == 'null'
                ? const Icon(
                    Icons.restaurant_menu_rounded,
                    color: kTextSecondary,
                    size: 26,
                  )
                : AppNetworkImage(
                    imageUrl:
                        'https://savir-technology.online/roaqv2/uploud/items/$imageName',
                    width: 76,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.restaurant_menu_rounded,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  const _AvailabilitySwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.scale(
          scale: 0.76,
          child: Switch(
            value: value,
            onChanged: (_) => onChanged(),
          ),
        ),
        Text(
          value ? 'متوفر' : 'مخفي',
          style: TextStyle(
            color: value ? kPrimary : const Color(0xFFDC2626),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RowActionButton extends StatelessWidget {
  const _RowActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: kStroke),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTableFooter extends StatelessWidget {
  const _MenuTableFooter({
    required this.rowsPerPage,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.onPageChanged,
  });

  final int rowsPerPage;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pages = List<int>.generate(min(totalPages, 4), (index) => index);
    final firstDisplay = totalItems == 0 ? 0 : startIndex + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                enabled: currentPage > 0,
                onTap: () => onPageChanged(0),
              ),
              const SizedBox(width: 6),
              _PageButton(
                icon: Icons.keyboard_arrow_right_rounded,
                enabled: currentPage > 0,
                onTap: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 8),
              for (final page in pages) ...[
                _NumberPageButton(
                  label: '${page + 1}',
                  selected: currentPage == page,
                  onTap: () => onPageChanged(page),
                ),
                const SizedBox(width: 6),
              ],
              _PageButton(
                icon: Icons.keyboard_arrow_left_rounded,
                enabled: currentPage < totalPages - 1,
                onTap: () => onPageChanged(currentPage + 1),
              ),
              const SizedBox(width: 6),
              _PageButton(
                icon: Icons.keyboard_double_arrow_left_rounded,
                enabled: currentPage < totalPages - 1,
                onTap: () => onPageChanged(totalPages - 1),
              ),
            ],
          );

          final rowsLabel = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FooterBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: kTextPrimary),
                    const SizedBox(width: 8),
                    Text(
                      '$rowsPerPage',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'لكل صفحة',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

          final rangeLabel = Text(
            'عرض $firstDisplay - $endIndex من $totalItems صنف',
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [rowsLabel, rangeLabel],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: controls,
                ),
              ],
            );
          }

          return Row(
            textDirection: TextDirection.ltr,
            children: [
              rowsLabel,
              const Spacer(),
              controls,
              const Spacer(),
              rangeLabel,
            ],
          );
        },
      ),
    );
    /*
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Row(
            children: [
              _FooterBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: kTextPrimary),
                    const SizedBox(width: 8),
                    Text(
                      '$rowsPerPage',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'لكل صفحة',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                enabled: currentPage > 0,
                onTap: () => onPageChanged(0),
              ),
              const SizedBox(width: 6),
              _PageButton(
                icon: Icons.keyboard_arrow_right_rounded,
                enabled: currentPage > 0,
                onTap: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 8),
              for (final page in pages) ...[
                _NumberPageButton(
                  label: '${page + 1}',
                  selected: currentPage == page,
                  onTap: () => onPageChanged(page),
                ),
                const SizedBox(width: 6),
              ],
              _PageButton(
                icon: Icons.keyboard_arrow_left_rounded,
                enabled: currentPage < totalPages - 1,
                onTap: () => onPageChanged(currentPage + 1),
              ),
              const SizedBox(width: 6),
              _PageButton(
                icon: Icons.keyboard_double_arrow_left_rounded,
                enabled: currentPage < totalPages - 1,
                onTap: () => onPageChanged(totalPages - 1),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'عرض $firstDisplay - $endIndex من $totalItems صنف',
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );*/
  }
}

class _FooterBox extends StatelessWidget {
  const _FooterBox({
    required this.child,
    this.width = 42,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: kStroke),
      ),
      child: child,
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: _FooterBox(
          child: Icon(icon, size: 18, color: kTextPrimary),
        ),
      ),
    );
  }
}

class _NumberPageButton extends StatelessWidget {
  const _NumberPageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? kPrimary : kStroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String _formatMenuMoney(double value) {
  final number = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < number.length; i++) {
    final reversedIndex = number.length - i;
    buffer.write(number[i]);
    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
