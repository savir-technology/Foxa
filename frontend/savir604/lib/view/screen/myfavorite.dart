import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/favorite/myfavoritecontroller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';
import 'package:tks/view/widget/common/inline_ad_sections.dart';
import 'package:tks/view/widget/myfavorite/customlistfavoriteitems.dart';

class MyFavorite extends StatelessWidget {
  const MyFavorite({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MyFavoriteController());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: AppTopBanner(
                  title: 'favorites'.tr,
                  subtitle: 'favorites_subtitle'.tr,
                  leadingIcon: Icons.arrow_back_rounded,
                  onLeadingTap: Get.back,
                  trailingIcon: Icons.favorite_rounded,
                  onTrailingTap: () {},
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GetBuilder<MyFavoriteController>(
                    builder: (controller) => HandlingDataView(
                      statusRequest: controller.statusRequest,
                      widget: controller.data.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: theme.dividerColor
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite_border_rounded,
                                      size: 52,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'no_favorites_yet'.tr,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'favorites_empty_subtitle'.tr,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 24),
                              physics: const BouncingScrollPhysics(),
                              child: InlineAdListFeed(
                                items: controller.data,
                                placement: 'favorites_inline',
                                itemSpacing: 12,
                                adHeight: 118,
                                itemBuilder: (context, item, index) {
                                  return CustomListFavoriteItems(
                                    itemsModel: item,
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
