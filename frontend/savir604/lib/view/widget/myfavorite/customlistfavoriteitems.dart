import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/controler/favorite/myfavoritecontroller.dart';
import 'package:tks/core/functions/app_image_urls.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/core/functions/translatefatabase.dart';
import 'package:tks/data/datasource/model/favoritemodel.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';

class CustomListFavoriteItems extends GetView<MyFavoriteController> {
  final MyFavoriteModel itemsModel;

  const CustomListFavoriteItems({super.key, required this.itemsModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final itemsModelData = ItemsModel(
      itemsId: itemsModel.itemsId?.toString(),
      itemsNameEn: itemsModel.itemsNameEn,
      itemsNameAr: itemsModel.itemsNameAr,
      itemsDescEn: itemsModel.itemsDescEn,
      itemsDescAr: itemsModel.itemsDescAr,
      itemsImage: itemsModel.itemsImage,
      itemsPrice: itemsModel.itemsPrice?.toString(),
      itemsDiscount: itemsModel.itemsDiscount?.toString(),
      itemsCount: itemsModel.itemsCount?.toString(),
      itemsActive: itemsModel.itemsActive?.toString(),
      itemsCat: itemsModel.itemsCat?.toString(),
      favorite: '1',
      averageRating: '0',
      ratingsCount: '0',
      ratingPercentage: '0',
    );
    final itemId = itemsModelData.itemsId?.toString() ?? '';

    return InkWell(
      onTap: () {
        if (itemId.isEmpty) {
          return;
        }
        unawaited(
          CommerceAccessGuard.openProduct(
            itemId: itemId,
            arguments: {
              'item_id': itemsModelData.itemsId,
              'itemsmodel': itemsModelData,
            },
            parameters: {
              'item_id': itemId,
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
              child: FallbackNetworkImage(
                imageUrls: AppImageUrls.item(itemsModel.itemsImage),
                width: 118,
                height: 150,
                fit: BoxFit.cover,
                placeholder: Container(
                  width: 118,
                  height: 150,
                  color: colors.primary.withValues(alpha: 0.08),
                ),
                errorWidget: Container(
                  width: 118,
                  height: 150,
                  color: colors.primary.withValues(alpha: 0.08),
                  child: Icon(Icons.broken_image_outlined, color: colors.primary),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'saved_item'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      translateDatabase(
                        itemsModel.itemsNameAr,
                        itemsModel.itemsNameEn,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translateDatabase(
                            itemsModel.itemsDescAr,
                            itemsModel.itemsDescEn,
                          ) ??
                          '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${itemsModel.itemsPrice?.toStringAsFixed(2) ?? '0.00'} ${AppCurrency.code}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'فتح الصنف',
                          onPressed: () {
                            if (itemId.isEmpty) {
                              return;
                            }
                            unawaited(
                              CommerceAccessGuard.openProduct(
                                itemId: itemId,
                                arguments: {
                                  'item_id': itemsModelData.itemsId,
                                  'itemsmodel': itemsModelData,
                                },
                                parameters: {
                                  'item_id': itemId,
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                        ),
                        IconButton(
                          onPressed: itemsModel.itemsId == null
                              ? null
                              : () {
                                  final cartController =
                                      Get.isRegistered<CartController>()
                                          ? Get.find<CartController>()
                                          : Get.put(CartController());
                                  cartController.add(itemsModel.itemsId.toString());
                                },
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                        ),
                        IconButton(
                          onPressed:
                              itemsModel.favoriteId == null ||
                                      controller.deletingIds.contains(
                                        itemsModel.favoriteId!.toString(),
                                      )
                                  ? null
                                  : () {
                                      controller.deleteFromFavorite(itemsModel);
                                    },
                          icon:
                              itemsModel.favoriteId != null &&
                                      controller.deletingIds.contains(
                                        itemsModel.favoriteId!.toString(),
                                      )
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFFE53935),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFE53935),
                                    ),
                        ),
                      ],
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
