import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/favorite/favorite_controler.dart';
import 'package:tks/controler/items/items_controller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/view/widget/CustomAppBar.dart';
import 'package:tks/view/widget/common/inline_ad_sections.dart';
import 'package:tks/view/widget/items/customlistitems.dart';
import 'package:tks/view/widget/items/listcategoirseitems.dart';

class Items extends StatelessWidget {
  const Items({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsController = Get.put(ItemsControllerImp());
    final favoriteController = Get.put(FavoriteController());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = Get.locale?.languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: GetBuilder<ItemsControllerImp>(
            builder: (controller) {
              final itemCount = controller.data.length;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'المطعم' : 'Restaurant',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic ? 'تصفح جميع الأصناف' : 'Browse all dishes',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'اعثر على الأطباق أسرع، وتصفح الأقسام بسهولة، وتحقق من الأسعار بوضوح أكبر.'
                                : 'Find dishes faster, browse categories easily, and check prices more clearly.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          CustomAppBar(
                            mycontroller: itemsController.search!,
                            titleappbar:
                                isArabic ? 'ابحث عن صنف' : 'Find dish',
                            onPressedSearch: itemsController.onSearchItems,
                            onPressedIconFavorite: () {
                              Get.toNamed(AppRoutes.myfavroite);
                            },
                          ),
                          const SizedBox(height: 18),
                          const ListCategoriesItems(),
                          const SizedBox(height: 18),
                          _CollectionSummary(
                            itemCount: itemCount,
                            isArabic: isArabic,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverToBoxAdapter(
                      child: HandlingDataView(
                        statusRequest: controller.statusRequest,
                        widget: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final items = controller.data
                                .map((e) => ItemsModel.fromJson(e))
                                .toList();

                            int itemsPerRow = 2;
                            double childAspectRatio = 0.44;

                            if (width >= 1180) {
                              itemsPerRow = 4;
                              childAspectRatio = 0.56;
                            } else if (width >= 840) {
                              itemsPerRow = 3;
                              childAspectRatio = 0.52;
                            } else if (width >= 520) {
                              itemsPerRow = 2;
                              childAspectRatio = 0.49;
                            } else if (width >= 390) {
                              itemsPerRow = 2;
                              childAspectRatio = 0.45;
                            }

                            return InlineAdProductFeed<ItemsModel>(
                              items: items,
                              placement: 'items_inline',
                              adHeight: 120,
                              rowSpacing: 14,
                              itemsPerRow: itemsPerRow,
                              childAspectRatio: childAspectRatio,
                              itemBuilder: (context, item, index) {
                                final itemId =
                                    controller.data[index]['items_id'];
                                final isFavorite =
                                    controller.data[index]['favorite'];
                                favoriteController.isFavorite[itemId] =
                                    isFavorite;

                                return CustomListItems(itemsModel: item);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  final int itemCount;
  final bool isArabic;

  const _CollectionSummary({
    required this.itemCount,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.grid_view_rounded, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount ${isArabic ? 'أصناف متاحة' : 'dishes available'}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'الأصناف مصنفة بوضوح لتسهيل استعراض الأسعار والخصومات.'
                      : 'Dishes are grouped clearly so prices and discounts are easier to scan.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
