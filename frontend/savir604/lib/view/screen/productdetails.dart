import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/productdetails/productdetails_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/functions/app_image_urls.dart';
import 'package:tks/data/datasource/model/product_variant_model.dart';
import 'package:tks/data/datasource/model/ratingmodel.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';
import 'package:tks/view/widget/productdetails/fullscreen_gallery.dart';

class ProductDetails extends StatelessWidget {
  const ProductDetails({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProductDetailsControllerImp());
    final isArabic = Get.locale?.languageCode == 'ar';
    final isReviewMode =
        (Get.parameters['mode'] ?? '').toString().toLowerCase() == 'review';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: isReviewMode
            ? AppBar(
                title: Text(isArabic
                    ? 'تقييم المنتج والمطعم'
                    : 'Product & restaurant review'),
                centerTitle: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              )
            : null,
        bottomNavigationBar: isReviewMode
            ? null
            : GetBuilder<ProductDetailsControllerImp>(
                builder: (controller) => SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _BottomActionsPanel(
                      controller: controller,
                      isArabic: isArabic,
                    ),
                  ),
                ),
              ),
        body: GetBuilder<ProductDetailsControllerImp>(
          builder: (controller) {
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            final item = controller.itemsModel;
            final title =
                isArabic ? item.itemsNameAr ?? '' : item.itemsNameEn ?? '';
            final description =
                isArabic ? item.itemsDescAr ?? '' : item.itemsDescEn ?? '';
            final isPerfumeProduct = controller.isPerfumeProduct;
            final productSubtitle = isReviewMode
                ? (isArabic
                    ? 'هذه الصفحة مخصصة لتقييم المنتج بعد استلام الطلب'
                    : 'This page is dedicated to product reviews after delivery')
                : isPerfumeProduct
                    ? (isArabic
                        ? 'عطر مختار حسب ذوقك وتفاصيله واضحة قبل الشراء'
                        : 'Fragrance details and options ready for your selection')
                    : controller.isFreshFoodProduct
                        ? (isArabic
                            ? '\u0645\u0646\u062a\u062c \u0637\u0627\u0632\u062c \u0645\u0628\u0627\u0634\u0631\u0629 \u0645\u0646 \u0627\u0644\u0645\u062a\u062c\u0631'
                            : 'Fresh produce selected by weight')
                        : controller.isStoreProduct
                            ? (isArabic
                                ? 'منتج متجر جاهز للاختيار'
                                : 'Store product ready for your selection')
                            : (isArabic
                                ? 'منتج مطعم جاهز لاختيارك'
                                : 'Restaurant product ready for your selection');
            final isOutOfStock = controller.hasVariants
                ? controller.isSelectedVariantOutOfStock
                : (int.tryParse(item.itemsCount ?? '0') ?? 0) <= 0;

            if (isReviewMode) {
              final restaurantName =
                  (item.storeName ?? item.vendorName ?? '').trim();
              return HandlingDataView(
                statusRequest: controller.statusRequest,
                widget: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (restaurantName.isNotEmpty) ...[
                      Text(
                        restaurantName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _RatingsSection(
                      controller: controller,
                      isArabic: isArabic,
                    ),
                  ],
                ),
              );
            }

            return HandlingDataView(
              statusRequest: controller.statusRequest,
              widget: Container(
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
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 420,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      leading: _topButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: Get.back,
                      ),
                      actions: [
                        _topButton(
                          icon: controller.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: controller.toggleFavorite,
                        ),
                        const SizedBox(width: 8),
                        _topButton(
                          icon: Icons.share_outlined,
                          onTap: controller.share,
                        ),
                        const SizedBox(width: 14),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _AmazonStyleGalleryHeader(
                          controller: controller,
                          itemImage: controller.selectedImage,
                          isOutOfStock: isOutOfStock,
                          isArabic: isArabic,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isPerfumeProduct)
                                    _PerfumeIdentity(
                                      controller: controller,
                                      title: title,
                                      isArabic: isArabic,
                                    )
                                  else ...[
                                    Text(title,
                                        style: theme.textTheme.headlineMedium),
                                    const SizedBox(height: 10),
                                    Text(
                                      productSubtitle,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  if (isPerfumeProduct)
                                    _PerfumePriceLine(
                                      controller: controller,
                                      isArabic: isArabic,
                                    ),
                                  if (controller.isFreshFoodProduct)
                                    _FreshPriceLine(
                                      controller: controller,
                                      isArabic: isArabic,
                                    ),
                                  if (!isPerfumeProduct &&
                                      !controller.isFreshFoodProduct)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InfoChip(
                                            icon: Icons.payments_outlined,
                                            label: isArabic
                                                ? 'السعر الحالي'
                                                : 'Current price',
                                            value:
                                                '${(controller.isFreshFoodProduct ? (double.tryParse(item.itemsPrice ?? '0') ?? controller.selectedPrice) : controller.selectedPrice).toStringAsFixed(2)} ${controller.isFreshFoodProduct ? (isArabic ? AppCurrency.symbol : '${AppCurrency.code} / kg') : AppCurrency.code}',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoChip(
                                            icon: Icons.inventory_2_outlined,
                                            label: isArabic
                                                ? 'حالة المخزون'
                                                : 'Stock status',
                                            value: isOutOfStock
                                                ? (isArabic
                                                    ? 'غير متاح'
                                                    : 'Out of stock')
                                                : (isArabic
                                                    ? 'متاح الآن'
                                                    : 'Available now'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (isReviewMode) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        isArabic
                                            ? 'صفحة التقييم مخصصة لتقييم المنتج بعد استلام الطلب.'
                                            : 'This page is dedicated to rating the product after delivery.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  _RatingSnapshot(
                                    averageRating: controller.averageRating,
                                    ratingsCount: controller.ratingsCount,
                                    ratingPercentage:
                                        controller.ratingPercentage,
                                    isArabic: isArabic,
                                  ),
                                ],
                              ),
                            ),
                            if (!isReviewMode) ...[
                              const SizedBox(height: 16),
                              _StoreProductTemplate(
                                controller: controller,
                                isArabic: isArabic,
                              ),
                            ],
                            const SizedBox(height: 16),
                            controller.isFreshFoodProduct
                                ? _FreshDescriptionCard(
                                    description: description,
                                    isArabic: isArabic,
                                  )
                                : isPerfumeProduct
                                    ? _PerfumeAboutCard(
                                        description: description,
                                        isArabic: isArabic,
                                      )
                                    : _SectionCard(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isArabic
                                                  ? 'وصف المنتج'
                                                  : 'Product description',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                      color: colors.primary),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(description,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(height: 1.7)),
                                          ],
                                        ),
                                      ),
                            const SizedBox(height: 16),
                            _RatingsSection(
                              controller: controller,
                              isArabic: isArabic,
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
        ),
      ),
    );
  }

  Widget _topButton({required IconData icon, required VoidCallback onTap}) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

/// The store catalogue is intentionally dispatched by product type. Each
/// branch owns its own selling rules while the page shell keeps navigation,
/// gallery, ratings and cart actions shared.
class _FreshPriceLine extends StatelessWidget {
  const _FreshPriceLine({required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = controller.itemsModel.itemsPrice == null
        ? controller.selectedPrice
        : double.tryParse(controller.itemsModel.itemsPrice!) ??
            controller.selectedPrice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          price.toStringAsFixed(2),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            isArabic
                ? '\u062c\u0646\u064a\u0647 / \u0643\u062c\u0645'
                : '${AppCurrency.code} / kg',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PerfumePriceLine extends StatelessWidget {
  const _PerfumePriceLine({required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          controller.selectedPrice.toStringAsFixed(2),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            isArabic ? AppCurrency.nameAr : AppCurrency.code,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PerfumeIdentity extends StatelessWidget {
  const _PerfumeIdentity({
    required this.controller,
    required this.title,
    required this.isArabic,
  });

  final ProductDetailsControllerImp controller;
  final String title;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final audience = controller.attributeText(
      ['gender', 'target', 'audience', 'for', '\u0645\u0646\u0627\u0633\u0628'],
      fallback: isArabic ? '\u0644\u0644\u062c\u0645\u064a\u0639' : 'Unisex',
    );
    final format = controller.attributeText(
      ['format', 'type', 'concentration', 'eau'],
      fallback: isArabic
          ? '\u0639\u0637\u0631 \u0645\u062a\u0631\u0643\u0632'
          : 'Eau de Parfum',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(audience,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 5),
        Text(title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            )),
        const SizedBox(height: 5),
        Text(format,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: .72),
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _PerfumeAboutCard extends StatelessWidget {
  const _PerfumeAboutCard({required this.description, required this.isArabic});

  final String description;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? '\u0639\u0646 \u0627\u0644\u0639\u0637\u0631'
                : 'About this fragrance',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description.trim().isEmpty
                ? (isArabic
                    ? '\u0639\u0637\u0631 \u0645\u0645\u064a\u0632 \u0628\u062a\u0631\u0643\u064a\u0628\u0629 \u0645\u062a\u0648\u0627\u0632\u0646\u0629 \u0648\u062b\u0628\u0627\u062a \u062f\u0642\u064a\u0642\u0629.'
                    : 'A distinctive fragrance with a balanced composition and lasting performance.')
                : description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _PerfumeProductTemplate extends StatelessWidget {
  const _PerfumeProductTemplate(
      {required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PerfumeOptionsCard(controller: controller, isArabic: isArabic),
        const SizedBox(height: 14),
        _PerfumeDetailsCard(controller: controller, isArabic: isArabic),
      ],
    );
  }
}

class _StoreProductTemplate extends StatelessWidget {
  const _StoreProductTemplate(
      {required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    // Some legacy products are stored with product_type=food while their
    // fragrance attributes identify them as perfume. Always prefer the
    // controller's normalized product classification here.
    if (controller.isPerfumeProduct) {
      return _PerfumeProductTemplate(
        controller: controller,
        isArabic: isArabic,
      );
    }

    final productType =
        (controller.itemsModel.productType ?? 'general').trim().toLowerCase();
    final isDimensionProduct = productType == 'fashion' ||
        productType == 'shoes' ||
        controller.availableColors.isNotEmpty ||
        controller.availableSizes.isNotEmpty;

    // Keep clothing and shoes on their color/size selector even if an old
    // record is missing its product_type or has stale store metadata.
    if (isDimensionProduct) {
      return _DimensionProductTemplate(
        controller: controller,
        isArabic: isArabic,
      );
    }

    if (controller.isFreshFoodProduct) {
      return Column(
        children: [
          _FreshQuantityCard(controller: controller, isArabic: isArabic),
          const SizedBox(height: 12),
          _FreshFactsCard(controller: controller, isArabic: isArabic),
        ],
      );
    }

    switch (productType) {
      case 'canned_food':
        return _PackagedProductTemplate(
            controller: controller, isArabic: isArabic);
      case 'electronics':
      case 'toys':
      case 'grocery':
      case 'general':
        return _CatalogInfoTemplate(controller: controller, isArabic: isArabic);
      case 'fashion':
      case 'shoes':
        return _DimensionProductTemplate(
            controller: controller, isArabic: isArabic);
      default:
        return _CatalogInfoTemplate(controller: controller, isArabic: isArabic);
    }
  }
}

class _PackagedProductTemplate extends StatelessWidget {
  const _PackagedProductTemplate(
      {required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => _StoreDataCard(
        controller: controller,
        isArabic: isArabic,
        title: isArabic
            ? '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0645\u0646\u062a\u062c'
            : 'Product information',
        subtitle: isArabic
            ? '\u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0645\u0639\u0631\u0648\u0636\u0629 \u0644\u0644\u0645\u0639\u0631\u0641\u0629 \u0641\u0642\u0637.'
            : 'Package, weight and expiry details.',
      );
}

class _CatalogInfoTemplate extends StatelessWidget {
  const _CatalogInfoTemplate(
      {required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => _StoreDataCard(
        controller: controller,
        isArabic: isArabic,
        title: isArabic
            ? '\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u0645\u0646\u062a\u062c'
            : 'Product information',
        subtitle: isArabic
            ? '\u062a\u0641\u0627\u0635\u064a\u0644 \u0627\u0644\u0645\u0646\u062a\u062c \u0644\u0644\u0639\u0631\u0636 \u0641\u0642\u0637.'
            : 'Product details shown for reference.',
      );
}

class _StoreDataCard extends StatelessWidget {
  const _StoreDataCard({
    required this.controller,
    required this.isArabic,
    required this.title,
    required this.subtitle,
  });

  final ProductDetailsControllerImp controller;
  final bool isArabic;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = controller.attributes
        .where((attribute) => attribute.values.isNotEmpty)
        .map((attribute) => (
              attribute.displayName(isArabic),
              attribute.values
                  .map((value) => value.displayName(isArabic))
                  .join(', '),
            ))
        .toList();
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            Text(isArabic
                ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u062a\u0641\u0627\u0635\u064a\u0644 \u0625\u0636\u0627\u0641\u064a\u0629.'
                : 'No additional details available.')
          else
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(row.$1,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800))),
                      const SizedBox(width: 12),
                      Flexible(
                          child: Text(row.$2,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _DimensionProductTemplate extends StatelessWidget {
  const _DimensionProductTemplate(
      {required this.controller, required this.isArabic});
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _VariantsCard(controller: controller, isArabic: isArabic),
          const SizedBox(height: 16),
          _SelectionSummaryCard(controller: controller, isArabic: isArabic),
          _StoreQuantityCard(controller: controller, isArabic: isArabic),
        ],
      );
}

class _GenericStoreProductTemplate extends StatelessWidget {
  const _GenericStoreProductTemplate(
      {required this.controller, required this.isArabic});
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _VariantsCard(controller: controller, isArabic: isArabic),
          const SizedBox(height: 16),
          _SelectionSummaryCard(controller: controller, isArabic: isArabic),
          _StoreQuantityCard(controller: controller, isArabic: isArabic),
        ],
      );
}

class _BottomActionsPanel extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  const _BottomActionsPanel({
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = controller.hasVariants
        ? controller.isSelectedVariantOutOfStock
        : (int.tryParse(controller.itemsModel.itemsCount ?? '0') ?? 0) <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!controller.isStoreProduct)
            _CartEstimateBar(controller: controller, isArabic: isArabic),
          if (isOutOfStock)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                isArabic
                    ? 'الاختيار الحالي غير متاح. اختر لوناً أو مقاساً آخر.'
                    : 'The current selection is unavailable. Choose another color or size.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.cart),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(isArabic ? 'عرض السلة' : 'View cart'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isAddingSelectedVariant || isOutOfStock
                      ? null
                      : controller.addSelectedVariantToCart,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: controller.isAddingSelectedVariant
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(
                    isArabic ? 'أضف للسلة' : 'Add to cart',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ignore: unused_element
class _GalleryHeader extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final String? itemImage;
  final bool isOutOfStock;
  final bool isArabic;

  const _GalleryHeader({
    required this.controller,
    required this.itemImage,
    required this.isOutOfStock,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final galleryImages = controller.images;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 70, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.10),
            colors.primary.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (galleryImages.isEmpty)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FallbackNetworkImage(
                  imageUrls: AppImageUrls.item(itemImage),
                  label: isArabic ? 'صورة المنتج' : 'Product image',
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Positioned.fill(
              child: PageView.builder(
                controller: controller.imagesPageController,
                itemCount: galleryImages.length,
                onPageChanged: (i) {
                  controller.currentImageIndex = i;
                  controller.update();
                },
                itemBuilder: (context, index) {
                  final img = galleryImages[index];
                  return GestureDetector(
                    onTap: () => Get.to(
                      () => FullscreenGallery(
                        images: galleryImages,
                        initialIndex: index,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FallbackNetworkImage(
                        imageUrls: AppImageUrls.item(img.imgPath),
                        label: isArabic ? 'صورة المنتج' : 'Product image',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (controller.hasMultipleImages)
            Positioned(
              top: 18,
              right: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${controller.currentImageIndex + 1}/${galleryImages.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (controller.hasMultipleImages)
            Positioned(
              right: 18,
              left: 18,
              bottom: 64,
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final image = galleryImages[index];
                    final isSelected = controller.currentImageIndex == index;
                    return GestureDetector(
                      onTap: () => controller.selectImageAt(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 64,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : theme.dividerColor.withValues(alpha: 0.75),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: FallbackNetworkImage(
                            imageUrls: AppImageUrls.item(image.imgPath),
                            label: isArabic ? 'صورة مصغرة' : 'Thumbnail image',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isOutOfStock
                    ? 'out_of_stock'.tr
                    : (controller.isFreshFoodProduct
                        ? (isArabic ? 'طازج اليوم  🍃' : 'Fresh today  🍃')
                        : 'available_now_badge'.tr),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOutOfStock ? colors.error : colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmazonStyleGalleryHeader extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final String? itemImage;
  final bool isOutOfStock;
  final bool isArabic;

  const _AmazonStyleGalleryHeader({
    required this.controller,
    required this.itemImage,
    required this.isOutOfStock,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final galleryImages = controller.images;
    final showSideThumbnails = galleryImages.length > 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 70, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.10),
            colors.primary.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: galleryImages.isEmpty
                            ? FallbackNetworkImage(
                                imageUrls: AppImageUrls.item(itemImage),
                                label:
                                    isArabic ? 'صورة المنتج' : 'Product image',
                                fit: BoxFit.contain,
                              )
                            : PageView.builder(
                                controller: controller.imagesPageController,
                                itemCount: galleryImages.length,
                                onPageChanged: controller.onImagePageChanged,
                                itemBuilder: (context, index) {
                                  final img = galleryImages[index];
                                  return GestureDetector(
                                    onTap: () => Get.to(
                                      () => FullscreenGallery(
                                        images: galleryImages,
                                        initialIndex: index,
                                      ),
                                    ),
                                    child: FallbackNetworkImage(
                                      imageUrls: AppImageUrls.item(img.imgPath),
                                      label: isArabic
                                          ? 'صورة المنتج'
                                          : 'Product image',
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    if (showSideThumbnails) ...[
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 76,
                        child: ListView.separated(
                          controller: controller.thumbnailsScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: galleryImages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final image = galleryImages[index];
                            final isSelected =
                                controller.currentImageIndex == index;
                            return MouseRegion(
                              onEnter: (_) => controller.selectImageAt(index),
                              child: GestureDetector(
                                onTap: () => controller.selectImageAt(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 76,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.cardColor.withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.primary
                                          : theme.dividerColor
                                              .withValues(alpha: 0.75),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.shadowColor
                                            .withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: FallbackNetworkImage(
                                      imageUrls:
                                          AppImageUrls.item(image.imgPath),
                                      label: isArabic
                                          ? 'صورة مصغرة'
                                          : 'Thumbnail image',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (showSideThumbnails)
            Positioned(
              top: 18,
              right: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${controller.currentImageIndex + 1}/${galleryImages.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isOutOfStock
                    ? 'out_of_stock'.tr
                    : (controller.isFreshFoodProduct
                        ? (isArabic ? 'طازج اليوم  🍃' : 'Fresh today  🍃')
                        : 'available_now_badge'.tr),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOutOfStock ? colors.error : colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantsCard extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  const _VariantsCard({
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (!controller.hasVariants) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? controller.variantSectionTitle
                  : controller.variantSectionTitleEn,
              style:
                  theme.textTheme.titleLarge?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'هذا المنتج لا يحتوي حالياً على متغيرات مقاس أو لون، وسيتم إضافته بالسعر الأساسي.'
                  : 'This product currently has no size or color variants and will be added with the base price.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? controller.variantSectionTitle
                : controller.variantSectionTitleEn,
            style: theme.textTheme.titleLarge?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'حدد اللون أولاً ثم اختر المقاس المناسب لك. السعر والمخزون يتغيران حسب الاختيار.'
                : 'Select the color first, then choose your size. Price and stock update based on your selection.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (controller.isFreshFoodProduct) ...[
            Text(
              isArabic
                  ? '\u0627\u062e\u062a\u0631 \u0627\u0644\u0648\u0632\u0646'
                  : 'Choose quantity',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.variants.map((variant) {
                final selected =
                    controller.selectedVariant?.variantId == variant.variantId;
                return ChoiceChip(
                  label: Text(variant.sku.isNotEmpty
                      ? variant.sku
                      : '${variant.unitQuantity} ${variant.unit}'),
                  selected: selected,
                  onSelected: variant.inStock
                      ? (_) => controller.selectVariant(variant.variantId)
                      : null,
                );
              }).toList(),
            ),
          ],
          if (controller.hasGenericAttributes) ...[
            ...controller.attributes.map(
              (attribute) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: attribute.displayName(isArabic),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  value: controller.selectedAttributeValues[attribute.id],
                  items: attribute.values
                      .map((value) => DropdownMenuItem<String>(
                            value: value.id,
                            child: Text(value.displayName(isArabic)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null)
                      controller.selectAttributeValue(attribute.id, value);
                  },
                ),
              ),
            ),
          ],
          if (controller.availableColors.isNotEmpty) ...[
            Text(
              isArabic ? 'الألوان' : 'Colors',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.availableColors
                  .map(
                    (color) => _ColorChip(
                      option: color,
                      isArabic: isArabic,
                      selected: controller.selectedColorId == color.id,
                      enabled: controller.isColorSelectable(color.id),
                      onTap: () async => controller.selectColor(color.id),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (controller.availableSizes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              isArabic ? 'المقاسات' : 'Sizes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.availableSizes
                  .map(
                    (size) => _SizeChip(
                      option: size,
                      isArabic: isArabic,
                      selected: controller.selectedSizeId == size.id,
                      enabled: controller.isSizeSelectable(size.id),
                      onTap: () async => controller.selectSize(size.id),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FreshDescriptionCard extends StatelessWidget {
  const _FreshDescriptionCard(
      {required this.description, required this.isArabic});

  final String description;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(isArabic ? 'عن المنتج' : 'About the product',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshFactsCard extends StatelessWidget {
  const _FreshFactsCard({required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = <Map<String, String>>[
      {
        'label': isArabic ? 'يباع بـ' : 'Sold by',
        'value': controller.attributeText(
          ['sale', 'unit', 'بيع'],
          fallback: controller.attributeValueAt(0,
              fallback: isArabic ? 'الكيلو' : 'Kilogram'),
        ),
        'icon': 'scale'
      },
      {
        'label': isArabic ? 'بلد المنشأ' : 'Origin',
        'value': controller.attributeText(
          ['origin', 'country', 'منشأ', 'بلد'],
          fallback: controller.attributeValueAt(1,
              fallback: isArabic ? 'مصر' : 'Egypt'),
        ),
        'icon': 'origin'
      },
      {
        'label': isArabic ? 'الحفظ' : 'Storage',
        'value': controller.attributeText(
          ['storage', 'حفظ'],
          fallback: controller.attributeValueAt(2,
              fallback: isArabic ? 'يحفظ في الثلاجة' : 'Keep refrigerated'),
        ),
        'icon': 'cold'
      },
    ];
    return Row(
      children: facts
          .map((fact) => Expanded(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: .055),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    Icon(
                        fact['icon'] == 'cold'
                            ? Icons.ac_unit
                            : fact['icon'] == 'origin'
                                ? Icons.location_on_outlined
                                : Icons.scale_outlined,
                        color: theme.colorScheme.primary,
                        size: 24),
                    const SizedBox(height: 6),
                    Text(fact['label']!,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(fact['value']!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall),
                  ]),
                ),
              ))
          .toList(),
    );
  }
}

class _FreshQuantityCard extends StatelessWidget {
  const _FreshQuantityCard({required this.controller, required this.isArabic});

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantity = controller.selectedFreshWeight;
    final quantityText = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(2);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isArabic ? '\u0627\u0644\u0643\u0645\u064a\u0629' : 'Quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundAction(context, Icons.remove, () {
                controller.changeFreshWeight(-0.25);
              }),
              Container(
                width: 112,
                padding: const EdgeInsets.symmetric(vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Text(quantityText,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text(isArabic ? 'كجم' : 'kg'),
                ]),
              ),
              _roundAction(context, Icons.add, () {
                controller.changeFreshWeight(0.25);
              }),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [0.25, 0.5, 1.0, 2.0, 3.0, 5.0]
                .map((weight) => ChoiceChip(
                      label: Text('$weight kg'),
                      selected: controller.selectedFreshWeight == weight,
                      onSelected: (_) => controller.setFreshWeight(weight),
                    ))
                .toList(),
          ),
          ...[
            const SizedBox(height: 12),
            Text(
              '${isArabic ? 'الإجمالي' : 'Total'}: ${(controller.selectedPrice * controller.selectedFreshWeight).toStringAsFixed(2)} ${isArabic ? AppCurrency.symbol : AppCurrency.code}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roundAction(BuildContext context, IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed:
          icon == Icons.remove && controller.selectedFreshWeight <= 0.25 ||
                  icon == Icons.add && controller.selectedFreshWeight >= 1000
              ? null
              : onTap,
      icon: Icon(icon),
      color: Theme.of(context).colorScheme.primary,
      style: IconButton.styleFrom(
          side: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .5))),
    );
  }
}

class _PerfumeOptionsCard extends StatelessWidget {
  const _PerfumeOptionsCard({
    required this.controller,
    required this.isArabic,
  });

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectableAttributes = controller.attributes.where((attribute) {
      if (attribute.values.isEmpty) return false;
      final name = '${attribute.nameAr} ${attribute.nameEn}'.toLowerCase();
      final isDescriptionOnly = name.contains('longevity') ||
          name.contains('sillage') ||
          name.contains('top notes') ||
          name.contains('middle notes') ||
          name.contains('base notes') ||
          name.contains('seasons') ||
          name.contains('best for') ||
          name.contains('الثبات') ||
          name.contains('الفوحان') ||
          name.contains('مقدمة العطر') ||
          name.contains('قلب العطر') ||
          name.contains('قاعدة العطر') ||
          name.contains('المواسم') ||
          name.contains('مناسب');
      return !isDescriptionOnly;
    });
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'اختيارات العطر' : 'Fragrance options',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'اختر من الخيارات الظاهرة مباشرة قبل إضافة المنتج للسلة.'
                : 'Choose from the available options before adding to cart.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ...selectableAttributes.map(
            (attribute) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attribute.displayName(isArabic),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: attribute.values
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value.displayName(isArabic)),
                            selected: controller
                                    .selectedAttributeValues[attribute.id] ==
                                value.id,
                            onSelected: (_) => controller.selectAttributeValue(
                              attribute.id,
                              value.id,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfumeDetailsCard extends StatelessWidget {
  const _PerfumeDetailsCard({
    required this.controller,
    required this.isArabic,
  });

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  String _value(List<String> names) {
    for (final attribute in controller.attributes) {
      if (names.contains(attribute.nameAr) ||
          names.contains(attribute.nameEn)) {
        final values = attribute.values
            .map((value) => value.displayName(isArabic))
            .where((value) => value.trim().isNotEmpty)
            .join(', ');
        if (values.isNotEmpty) return values;
      }
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final performance = [
      ('الثبات', 'Longevity', Icons.schedule_rounded),
      ('الفوحان', 'Sillage', Icons.air_rounded),
    ];
    final details = [
      ('العائلة العطرية', 'Fragrance family', Icons.spa_outlined),
      ('المواسم', 'Seasons', Icons.calendar_month_outlined),
      ('مناسب لـ', 'Best for', Icons.event_available_outlined),
      ('مقدمة العطر', 'Top Notes', Icons.notes_rounded),
      ('قلب العطر', 'Middle Notes', Icons.notes_rounded),
      ('قاعدة العطر', 'Base Notes', Icons.notes_rounded),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تفاصيل العطر' : 'Fragrance details',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Row(
            children: performance
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: _PerfumeMetricCard(
                        icon: item.$3,
                        label: isArabic ? item.$1 : item.$2,
                        rawValue: _value([item.$1, item.$2]),
                        isArabic: isArabic,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          ...details.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InfoChip(
                icon: item.$3,
                label: isArabic ? item.$1 : item.$2,
                value: _value([item.$1, item.$2]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfumeMetricCard extends StatelessWidget {
  const _PerfumeMetricCard({
    required this.icon,
    required this.label,
    required this.rawValue,
    required this.isArabic,
  });

  final IconData icon;
  final String label;
  final String rawValue;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = double.tryParse(rawValue.replaceAll(',', '.'));
    final score = value == null ? 0 : value.clamp(0, 10).round();
    final description = value == null
        ? rawValue
        : score >= 8
            ? (isArabic ? '\u0642\u0648\u064a' : 'Strong')
            : score >= 5
                ? (isArabic ? '\u0645\u062a\u0648\u0633\u0637' : 'Moderate')
                : (isArabic ? '\u062e\u0641\u064a\u0641' : 'Light');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 25),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(10, (index) {
                    final active = index < score;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 10 + (index * 2.5),
                          decoration: BoxDecoration(
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.18,
                                  ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value == null ? '—' : '$score/10',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreQuantityCard extends StatelessWidget {
  const _StoreQuantityCard({
    required this.controller,
    required this.isArabic,
  });

  final ProductDetailsControllerImp controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant = controller.selectedVariant;
    final quantity = variant?.stockQuantity ??
        double.tryParse(controller.itemsModel.itemsCount ?? '0') ??
        0;
    return _SectionCard(
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined,
              color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArabic
                  ? '\u0627\u0644\u0643\u0645\u064a\u0629: ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} ${controller.stockUnitLabel(true)}'
                  : 'Quantity: ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} ${controller.stockUnitLabel(false)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  const _SelectionSummaryCard({
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final variant = controller.selectedVariant;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'ملخص الاختيار' : 'Selection summary',
            style: theme.textTheme.titleLarge?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 12),
          if (variant == null && controller.hasVariants)
            Text(
              isArabic
                  ? 'اختر اللون والمقاس لعرض تفاصيل القطعة المختارة.'
                  : 'Choose color and size to preview the selected item details.',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.palette_outlined,
                    label: isArabic ? 'اللون' : 'Color',
                    value: variant?.colorName(isArabic) ??
                        (isArabic ? 'الافتراضي' : 'Default'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.straighten_outlined,
                    label: isArabic ? 'المقاس' : 'Size',
                    value: variant?.sizeName(isArabic) ??
                        (isArabic ? 'عام' : 'General'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                isArabic
                    ? 'السعر النهائي لهذا الاختيار: ${controller.selectedPrice.toStringAsFixed(2)} ريال'
                    : 'Final price for this selection: ${controller.selectedPrice.toStringAsFixed(2)} ${AppCurrency.code}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSnapshot extends StatelessWidget {
  final double averageRating;
  final int ratingsCount;
  final int ratingPercentage;
  final bool isArabic;

  const _RatingSnapshot({
    required this.averageRating,
    required this.ratingsCount,
    required this.ratingPercentage,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StarsRow(
                  value: averageRating,
                  iconSize: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? '$ratingsCount تقييم • $ratingPercentage% رضا'
                      : '$ratingsCount reviews • $ratingPercentage% satisfaction',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingsSection extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  const _RatingsSection({
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'التقييمات السابقة' : 'Previous reviews',
            style: theme.textTheme.titleLarge?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            isArabic
                ? 'اكتب تقييمك الجديد للمنتج والمطعم في الأسفل، ثم راجع التقييمات السابقة.'
                : 'Write your new review for the product and restaurant below, then browse previous reviews.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (controller.currentUserId <= 0)
            _RatingGateNotice(
              message: isArabic
                  ? 'سجل الدخول أولاً حتى تتمكن من تقييم المنتج.'
                  : 'Login first to rate this product and restaurant.',
            )
          else if (!controller.canSubmitRating)
            _RatingGateNotice(
              message: isArabic
                  ? 'يمكنك تقييم المنتج والمطعم بعد استلام الطلب فقط.'
                  : 'You can only rate this product and restaurant after your order is delivered.',
            )
          else
            _RatingComposer(controller: controller, isArabic: isArabic),
          const SizedBox(height: 18),
          if (controller.ratingsStatus == StatusRequest.loading)
            const Center(child: CircularProgressIndicator())
          else if (controller.ratings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isArabic
                    ? 'لا توجد تقييمات بعد. كن أول من يشارك رأيه.'
                    : 'No reviews yet. Be the first to share your opinion.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            Column(
              children: controller.ratings
                  .map(
                    (rating) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RatingTile(
                        rating: rating,
                        isArabic: isArabic,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RatingGateNotice extends StatelessWidget {
  final String message;

  const _RatingGateNotice({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingComposer extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  const _RatingComposer({
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.hasUserRating
                ? (isArabic ? 'تقييمك الحالي' : 'Your current review')
                : (isArabic ? 'أضف تقييمك' : 'Add your review'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => controller.setUserRating(index + 1.0),
                icon: Icon(
                  index < controller.selectedUserRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF4B400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.ratingCommentController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: isArabic
                  ? 'اكتب رأيك في المنتج والمطعم بعد الاستلام...'
                  : 'Share your opinion about the product and restaurant after delivery...',
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isSubmittingRating
                      ? null
                      : controller.submitRating,
                  icon: controller.isSubmittingRating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rate_review_outlined),
                  label: Text(
                    controller.hasUserRating
                        ? (isArabic ? 'تحديث التقييم' : 'Update review')
                        : (isArabic ? 'إرسال التقييم' : 'Submit review'),
                  ),
                ),
              ),
              if (controller.hasUserRating) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: controller.isSubmittingRating
                      ? null
                      : controller.deleteUserRating,
                  child: Text(isArabic ? 'حذف' : 'Delete'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  final RatingModel rating;
  final bool isArabic;

  const _RatingTile({
    required this.rating,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rating.usersName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                rating.createdAt,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StarsRow(value: rating.rating),
          if (rating.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final double value;
  final double iconSize;

  const _StarsRow({
    required this.value,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = value >= index + 1;
        final half = !filled && value > index && value < index + 1;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded,
          size: iconSize,
          color: const Color(0xFFF4B400),
        );
      }),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final VariantColorOption option;
  final bool isArabic;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ColorChip({
    required this.option,
    required this.isArabic,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final swatch = Color(
      int.tryParse(option.hex.replaceFirst('#', '0xFF')) ?? 0xFFD1D5DB,
    );

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: !enabled
              ? theme.disabledColor.withValues(alpha: 0.08)
              : selected
                  ? colors.primary.withValues(alpha: 0.10)
                  : theme.cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: !enabled
                ? theme.disabledColor.withValues(alpha: 0.25)
                : selected
                    ? colors.primary
                    : theme.dividerColor.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              option.displayName(isArabic),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: !enabled
                    ? theme.disabledColor
                    : selected
                        ? colors.primary
                        : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final VariantSizeOption option;
  final bool isArabic;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SizeChip({
    required this.option,
    required this.isArabic,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: !enabled
              ? theme.disabledColor.withValues(alpha: 0.08)
              : selected
                  ? colors.primary
                  : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: !enabled
                ? theme.disabledColor.withValues(alpha: 0.25)
                : selected
                    ? colors.primary
                    : theme.dividerColor.withValues(alpha: 0.75),
          ),
        ),
        child: Text(
          option.displayName(isArabic),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: !enabled
                ? theme.disabledColor
                : selected
                    ? colors.onPrimary
                    : colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CartEstimateBar extends StatelessWidget {
  final ProductDetailsControllerImp controller;
  final bool isArabic;

  const _CartEstimateBar({
    required this.controller,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final variant = controller.selectedVariant;
    final summary = variant == null
        ? (isArabic ? 'السعر الأساسي' : 'Base price')
        : '${variant.colorName(isArabic)} - ${variant.sizeName(isArabic)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'الإجمالي المتوقع: ${controller.selectedPrice.toStringAsFixed(2)} ريال'
                : 'Estimated total: ${controller.selectedPrice.toStringAsFixed(2)} ${AppCurrency.code}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
