import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/items/items_controller.dart';
import 'package:tks/core/functions/translatefatabase.dart';
import 'package:tks/data/datasource/model/categoriesmodel.dart';

class ListCategoriesItems extends GetView<ItemsControllerImp> {
  const ListCategoriesItems({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Categories(
            i: index,
            categoriesModel:
                CategoriesModel.fromJson(controller.categories[index]),
          );
        },
      ),
    );
  }
}

class Categories extends GetView<ItemsControllerImp> {
  final CategoriesModel categoriesModel;
  final int? i;

  const Categories({
    super.key,
    required this.categoriesModel,
    required this.i,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        controller.changeCat(i!, categoriesModel.categoriesId!);
      },
      child: GetBuilder<ItemsControllerImp>(
        builder: (controller) {
          final active = controller.selectedCat == i;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? colors.primary.withValues(alpha: 0.12)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? colors.primary.withValues(alpha: 0.35)
                    : theme.dividerColor.withValues(alpha: 0.85),
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              translateDatabase(
                categoriesModel.categoriesNameAr,
                categoriesModel.categoriesNameEn,
              ),
              style: TextStyle(
                fontSize: 14,
                color: active
                    ? colors.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
