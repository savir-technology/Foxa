import 'package:admin_tks/add.dart';
import 'package:admin_tks/EditItemPage.dart';
import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/controler/items_controller.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemsController itemsController = Get.put(ItemsController());
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all';

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditPage(ItemsModel item) async {
    final bool? updated = await Get.to(() => EditItemPage(item: item));
    if (updated == true) {
      itemsController.fetchItems();
    }
  }

  Future<void> _openAddProduct() async {
    final bool? added = await Get.to(() => const AddProductPage());
    if (added == true) {
      itemsController.fetchItems();
    }
  }

  void _confirmDelete(ItemsModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceElevated,
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to remove "${item.itemsNameEn ?? item.itemsNameAr ?? 'this product'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              itemsController.deleteItem(item.itemsId ?? '', '');
              Get.back();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<ItemsModel> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    final items = itemsController.itemsList;
    return items.where((item) {
      final haystack = [
        item.itemsNameAr ?? '',
        item.itemsNameEn ?? '',
        item.itemsDescAr ?? '',
        item.itemsDescEn ?? '',
        item.itemsId ?? '',
        item.itemsCat ?? '',
      ].join(' ').toLowerCase();

      final stock = int.tryParse(item.itemsCount ?? '0') ?? 0;
      final isActive = (item.itemsActive ?? '1') != '0';

      final matchesQuery = query.isEmpty || haystack.contains(query);
      final matchesFilter = switch (_activeFilter) {
        'active' => isActive,
        'hidden' => !isActive,
        'low_stock' => stock <= 12,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1450
        ? 4
        : screenWidth >= 1100
            ? 3
            : screenWidth >= 760
                ? 2
                : 1;

    return Obx(() {
      final allItems = itemsController.itemsList;
      final activeCount =
          allItems.where((item) => (item.itemsActive ?? '1') != '0').length;
      final hiddenCount = allItems.length - activeCount;
      final totalStock = allItems.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse(item.itemsCount ?? '0') ?? 0),
      );
      final filteredItems = _filteredItems;
      final lowStockCount = allItems
          .where((item) => (int.tryParse(item.itemsCount ?? '0') ?? 0) <= 12)
          .length;

      return DashboardPageShell(
        title: 'إدارة المنتجات',
        subtitle: 'الصور، الفيديو، الأسعار، المخزون، والحالة من شاشة واحدة.',
        icon: Icons.shopping_bag_rounded,
        actions: [
          IconButton.filledTonal(
            onPressed: itemsController.fetchItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
          FilledButton.icon(
            onPressed: _openAddProduct,
            icon: const Icon(Icons.add_rounded),
            label: const Text('منتج جديد'),
          ),
        ],
        stats: [
          DashboardStatCard(
            label: 'كل المنتجات',
            value: '${allItems.length}',
            icon: Icons.inventory_2_outlined,
            tint: kPrimary,
          ),
          DashboardStatCard(
            label: 'المنتجات النشطة',
            value: '$activeCount',
            icon: Icons.verified_rounded,
            tint: kAccent,
          ),
          DashboardStatCard(
            label: 'إجمالي المخزون',
            value: '$totalStock',
            icon: Icons.layers_outlined,
            tint: kSecondary,
          ),
          DashboardStatCard(
            label: 'مخزون منخفض',
            value: '$lowStockCount',
            icon: Icons.warning_amber_rounded,
            tint: const Color(0xFFF59E0B),
          ),
          DashboardStatCard(
            label: 'مخفية',
            value: '$hiddenCount',
            icon: Icons.visibility_off_rounded,
            tint: const Color(0xFFEF4444),
          ),
        ],
        body: Column(
          children: [
            DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'بحث وفلترة',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const _ItemsBadge(label: 'Live', tint: Color(0xFF14B8A6)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو الوصف أو الرقم أو القسم',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: _activeFilter == 'all',
                        onTap: () => setState(() => _activeFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'نشط',
                        selected: _activeFilter == 'active',
                        onTap: () => setState(() => _activeFilter = 'active'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'مخفي',
                        selected: _activeFilter == 'hidden',
                        onTap: () => setState(() => _activeFilter = 'hidden'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'مخزون منخفض',
                        selected: _activeFilter == 'low_stock',
                        onTap: () => setState(() => _activeFilter = 'low_stock'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${filteredItems.length} منتج ظاهر',
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (itemsController.isLoading.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child:
                    Center(child: CircularProgressIndicator(color: kPrimary)),
              )
            else if (filteredItems.isEmpty)
              const DashboardEmptyState(
                title: 'لا توجد منتجات مطابقة',
                subtitle: 'جرّب كلمة مختلفة أو أضف منتجًا جديدًا إلى الكتالوج.',
                icon: Icons.shopping_bag_outlined,
              )
            else
              GridView.builder(
                itemCount: filteredItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 310,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _ProductCard(
                    item: item,
                    isMaster: _auth.isMaster,
                    onEdit: () => _openEditPage(item),
                    onDelete: () => _confirmDelete(item),
                  );
                },
              ),
          ],
        ),
      );
    });
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.isMaster,
    required this.onEdit,
    required this.onDelete,
  });

  final ItemsModel item;
  final bool isMaster;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stock = int.tryParse(item.itemsCount ?? '0') ?? 0;
    final price = double.tryParse(item.itemsPrice ?? '0') ?? 0;
    final discount = int.tryParse(item.itemsDiscount ?? '0') ?? 0;
    final isActive = (item.itemsActive ?? '1') != '0';

    return DashboardPanel(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF4F7FB),
                  child: item.itemsImage != null && item.itemsImage!.isNotEmpty
                      ? AppNetworkImage(
                          imageUrl:
                              'https://savir-technology.online/roaqv2/uploud/items/${item.itemsImage}',
                          fit: BoxFit.contain,
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: kTextSecondary,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProductChip(
                  label: isActive ? 'Active' : 'Inactive',
                  tint: isActive ? kAccent : Colors.redAccent,
                ),
                _ProductChip(
                  label: 'Stock $stock',
                  tint: stock > 0 ? kPrimary : kSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.itemsNameAr?.trim().isNotEmpty == true
                  ? item.itemsNameAr!
                  : (item.itemsNameEn ?? 'Unnamed Product'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (isMaster &&
                (item.storeName?.isNotEmpty == true ||
                    item.vendorName?.isNotEmpty == true)) ...[
              const SizedBox(height: 4),
              Text(
                item.storeName?.isNotEmpty == true
                    ? item.storeName!
                    : (item.vendorName ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              item.itemsDescAr?.trim().isNotEmpty == true
                  ? item.itemsDescAr!
                  : (item.itemsDescEn ?? ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${price.toStringAsFixed(0)} SAR',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (discount > 0)
                  Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: kSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDelete,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F1),
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: kPrimary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? kPrimary : kTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? kPrimary : kStroke),
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _ItemsBadge extends StatelessWidget {
  const _ItemsBadge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
