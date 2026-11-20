import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/favorite/favorite_controler.dart';
import 'package:tks/controler/items/items_controller.dart'
    show ItemsControllerImp;
import 'package:tks/core/constant/color.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/functions/translatefatabase.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/view/widget/common/product_card_image_slider.dart';

class CustomListItems extends GetView<ItemsControllerImp> {
  final ItemsModel itemsModel;

  const CustomListItems({super.key, required this.itemsModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final discount = int.tryParse(itemsModel.itemsDiscount ?? '0') ?? 0;
    final isOutOfStock = (int.tryParse(itemsModel.itemsCount ?? '0') ?? 0) <= 0;
    final title =
        translateDatabase(itemsModel.itemsNameAr, itemsModel.itemsNameEn);
    final description =
        translateDatabase(itemsModel.itemsDescAr, itemsModel.itemsDescEn) ?? '';
    final finalPrice = _formattedPrice(
      itemsModel.itemsPrice,
      itemsModel.itemsDiscount,
      itemsModel.itemsDiscountPrice,
    );
    final originalPrice = _originalPrice(itemsModel.itemsPrice);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 190;
        final isVeryCompact = cardWidth < 155;

        return InkWell(
          onTap: () => controller.goToPageProductDetails(itemsModel),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isVeryCompact ? 11 : 12,
                  child: Container(
                    margin: EdgeInsets.all(isVeryCompact ? 7 : 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.10),
                          colors.primary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Hero(
                      tag: '${itemsModel.itemsId}',
                      child: ProductCardImageSlider(
                        imagePaths: itemsModel.galleryImagePaths,
                        label: title,
                        topLeft: GetBuilder<FavoriteController>(
                          builder: (favController) => GestureDetector(
                            onTap: () async {
                              if (favController
                                      .isFavorite[itemsModel.itemsId] ==
                                  '1') {
                                favController.setFavorite(
                                    itemsModel.itemsId, '0');
                                favController
                                    .removeFavorite(itemsModel.itemsId!);
                              } else {
                                favController.setFavorite(
                                    itemsModel.itemsId, '1');
                                favController.addFavorite(itemsModel.itemsId!);
                              }
                            },
                            child: Container(
                              width: isVeryCompact ? 34 : 38,
                              height: isVeryCompact ? 34 : 38,
                              decoration: BoxDecoration(
                                color: theme.cardColor.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                favController.isFavorite[itemsModel.itemsId] ==
                                        '1'
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: favController
                                            .isFavorite[itemsModel.itemsId] ==
                                        '1'
                                    ? ColorApp.praimaryColor
                                    : colors.onSurface.withValues(alpha: 0.6),
                                size: isVeryCompact ? 18 : 20,
                              ),
                            ),
                          ),
                        ),
                        topRight: discount > 0
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVeryCompact ? 8 : 10,
                                  vertical: isVeryCompact ? 5 : 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB93535),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$discount% OFF',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isVeryCompact ? 10 : null,
                                  ),
                                ),
                              )
                            : null,
                        bottomOverlay: isOutOfStock
                            ? Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'out_of_stock'.tr,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isVeryCompact ? 11 : null,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: isVeryCompact ? 9 : 8,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isVeryCompact ? 10 : 12,
                      isVeryCompact ? 6 : 8,
                      isVeryCompact ? 10 : 12,
                      isVeryCompact ? 10 : 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: isVeryCompact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: (isCompact
                                        ? theme.textTheme.titleSmall
                                        : theme.textTheme.titleMedium)
                                    ?.copyWith(
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: _ProductRatingLine(
                                itemsModel: itemsModel,
                                compact: isCompact,
                              ),
                            ),
                          ],
                        ),
                        if (!isVeryCompact) ...[
                          const SizedBox(height: 3),
                          Text(
                            description.trim().isEmpty
                                ? 'see_product_details'.tr
                                : description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (isCompact
                                    ? theme.textTheme.labelMedium
                                    : theme.textTheme.bodySmall)
                                ?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                        SizedBox(height: isVeryCompact ? 4 : 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  finalPrice,
                                  maxLines: 1,
                                  style: (isCompact
                                          ? theme.textTheme.titleMedium
                                          : theme.textTheme.titleLarge)
                                      ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            if (discount > 0) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    originalPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface
                                          .withValues(alpha: 0.45),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: isVeryCompact
                              ? FilledButton(
                                  onPressed: isOutOfStock
                                          ? null
                                      : () => controller
                                          .goToPageProductDetails(itemsModel),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(36),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: colors.primary,
                                    disabledBackgroundColor: colors.onSurface
                                        .withValues(alpha: 0.10),
                                    foregroundColor: colors.onPrimary,
                                    disabledForegroundColor: colors.onSurface
                                        .withValues(alpha: 0.45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? 'out_of_stock'.tr
                                        : (Get.locale?.languageCode == 'ar'
                                            ? 'إضافة'
                                            : 'Add'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: isOutOfStock
                                          ? null
                                      : () => controller
                                          .goToPageProductDetails(itemsModel),
                                  icon: Icon(
                                    isOutOfStock
                                        ? Icons.remove_shopping_cart_outlined
                                        : Icons.shopping_cart_checkout_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isOutOfStock
                                        ? 'out_of_stock'.tr
                                        : (Get.locale?.languageCode == 'ar'
                                            ? 'إضافة'
                                            : 'Add'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: colors.primary,
                                    disabledBackgroundColor: colors.onSurface
                                        .withValues(alpha: 0.10),
                                    foregroundColor: colors.onPrimary,
                                    disabledForegroundColor: colors.onSurface
                                        .withValues(alpha: 0.45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formattedPrice(
    String? priceStr,
    String? discountStr,
    String? backendDiscountedPrice,
  ) {
    final backendValue = double.tryParse(backendDiscountedPrice ?? '');
    if (backendValue != null && backendValue > 0) {
      return '${backendValue.toStringAsFixed(2)} ${AppCurrency.code}';
    }
    final price = double.tryParse(priceStr ?? '0') ?? 0.0;
    final discount = double.tryParse(discountStr ?? '0') ?? 0.0;
    final finalPrice = price * (1 - discount / 100);
    return '${finalPrice.toStringAsFixed(2)} ${AppCurrency.code}';
  }

  String _originalPrice(String? priceStr) {
    final price = double.tryParse(priceStr ?? '0') ?? 0.0;
    return '${price.toStringAsFixed(2)} ${AppCurrency.code}';
  }
}

class _ProductRatingLine extends StatelessWidget {
  final ItemsModel itemsModel;
  final bool compact;

  const _ProductRatingLine({
    required this.itemsModel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = itemsModel.ratingsCountValue;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: compact ? 13 : 15,
            color: const Color(0xFFF4B400),
          ),
          const SizedBox(width: 4),
          Text(
            itemsModel.averageRatingValue.toStringAsFixed(1),
            style: (compact
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              count > 0 ? '($count)' : 'No reviews',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (itemsModel.isTopRatedValue) ...[
              const SizedBox(width: 6),
              Text(
                'Top',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
