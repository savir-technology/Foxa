import 'package:admin_tks/AddCategoryPage.dart';
import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/model/categories_model.dart';
import 'package:admin_tks/remote/category_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<cat> categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();
  bool get _isMaster => _auth.isMaster;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final loaded = await CategoryData().getCategories();
      if (!mounted) return;
      setState(() {
        categories = loaded;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<cat> get _filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return categories;

    return categories.where((category) {
      final haystack = [
        category.categoriesNameAr ?? '',
        category.categoriesNameEn ?? '',
        category.categoriesId ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openAddCategory() async {
    if (!_isMaster) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddCategoryPage()),
    );
    await fetchCategories();
  }

  Future<void> _deleteCategory(String id, String name) async {
    if (!_isMaster) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceElevated,
        title: const Text('حذف القسم'),
        content: Text('هل تريد حذف "$name" نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await CategoryData().deleteCategory(id);
    if (!mounted) return;

    if (ok) {
      setState(() {
        categories.removeWhere((c) => c.categoriesId == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف القسم بنجاح')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف القسم')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return DashboardPageShell(
      title: _isMaster ? 'إدارة الأقسام' : 'الأقسام',
      subtitle: _isMaster
          ? 'تنظيم العروض والوجبات والمشاوي والمشروبات والحلويات من مكان واحد.'
          : 'استعرض الأقسام المتاحة واستخدمها عند إضافة أو تعديل المنتجات.',
      icon: Icons.category_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetchCategories,
          icon: const Icon(Icons.refresh_rounded),
        ),
        if (_isMaster)
          FilledButton.icon(
            onPressed: _openAddCategory,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة قسم'),
          ),
      ],
      stats: [
        DashboardStatCard(
          label: 'كل الأقسام',
          value: '${categories.length}',
          icon: Icons.grid_view_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'الظاهرة حالياً',
          value: '${filtered.length}',
          icon: Icons.visibility_rounded,
          tint: kAccent,
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
                        'بحث سريع',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const _CategoryCountBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم القسم أو الرقم التعريفي',
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          else if (filtered.isEmpty)
            const DashboardEmptyState(
              title: 'لا توجد أقسام مطابقة',
              subtitle: 'جرّب كلمة مختلفة أو أضف قسمًا جديدًا للقائمة.',
              icon: Icons.category_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final category = filtered[index];
                return _CategoryCard(
                  category: category,
                  canDelete: _isMaster,
                  onDelete: () => _deleteCategory(
                    category.categoriesId ?? '',
                    category.categoriesNameAr ??
                        category.categoriesNameEn ??
                        'قسم',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.canDelete,
    required this.onDelete,
  });

  final cat category;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 82,
              height: 82,
              color: const Color(0xFFF4F7FB),
              child: (category.categoriesImage != null &&
                      category.categoriesImage!.isNotEmpty)
                  ? AppNetworkImage(
                      imageUrl:
                          'https://savir-technology.online/roaqv2/uploud/categories/${category.categoriesImage!}',
                      fit: BoxFit.cover,
                      width: 82,
                      height: 82,
                    )
                  : const Icon(Icons.image_outlined, color: kTextSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoriesNameAr ?? 'قسم غير مسمى',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.categoriesNameEn ?? '',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ID ${category.categoriesId ?? '-'}',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (canDelete)
            IconButton(
              tooltip: 'حذف',
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F1),
                foregroundColor: Colors.redAccent,
              ),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}

class _CategoryCountBadge extends StatelessWidget {
  const _CategoryCountBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Live',
        style: TextStyle(
          color: kPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
