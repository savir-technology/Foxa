import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/controler/restaurants/food_item_details_controller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/data/datasource/model/food_item_details_model.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/core/class/StatusRequest.dart' as status_request;

class _FoodThemeTokens {
  const _FoodThemeTokens(this.theme);

  final ThemeData theme;

  bool get isDark => theme.brightness == Brightness.dark;
  Color get card => theme.cardColor;
  Color get border =>
      theme.dividerColor.withValues(alpha: isDark ? 0.86 : 0.72);
  Color get text => theme.colorScheme.onSurface;
  Color get textSoft =>
      theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.62);
  Color get surfaceSoft =>
      isDark ? const Color(0xFF171D18) : const Color(0xFFE9E9E9);
  Color get surfacePale =>
      isDark ? const Color(0xFF202620) : const Color(0xFFF6F6F6);
  Color get primary => theme.colorScheme.primary;
  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.24 : 0.08);
}

class FoodItemDetailsScreen extends StatefulWidget {
  const FoodItemDetailsScreen({super.key});

  @override
  State<FoodItemDetailsScreen> createState() => _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends State<FoodItemDetailsScreen> {
  late final FoodItemDetailsController controller;
  late final PageController _pageController;
  String? _precachedItemId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FoodItemDetailsController());
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (Get.isRegistered<FoodItemDetailsController>()) {
      Get.delete<FoodItemDetailsController>();
    }
    super.dispose();
  }

  void _precacheImages(
    BuildContext context,
    String itemId,
    List<String> urls,
  ) {
    if (_precachedItemId == itemId || urls.isEmpty) {
      return;
    }

    _precachedItemId = itemId;
    for (final raw in urls) {
      final normalized = AppLink.normalizeUrl(raw);
      if (normalized.trim().isEmpty) {
        continue;
      }
      precacheImage(CachedNetworkImageProvider(normalized), context)
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final theme = Theme.of(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: GetBuilder<FoodItemDetailsController>(
          builder: (controller) {
            final item = controller.item;
            if (item == null) {
              return const SizedBox.shrink();
            }
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _BottomActionBar(
                  isArabic: isArabic,
                  totalPrice: controller.totalPrice,
                  quantity: controller.quantity,
                  isAdding: controller.isAdding,
                  onTap: controller.addToCart,
                ),
              ),
            );
          },
        ),
        body: SafeArea(
          bottom: false,
          child: GetBuilder<FoodItemDetailsController>(
            builder: (controller) {
              final item = controller.item;
              final effectiveStatus = item == null &&
                      controller.statusRequest ==
                          status_request.StatusRequest.success
                  ? status_request.StatusRequest.failure
                  : controller.statusRequest;

              return HandlingDataView(
                statusRequest: effectiveStatus,
                widget: item == null
                    ? const SizedBox.shrink()
                    : Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Builder(
                                  builder: (context) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!mounted || controller.item == null) {
                                        return;
                                      }
                                      _precacheImages(
                                        context,
                                        controller.item!.id,
                                        controller.galleryImages,
                                      );
                                    });
                                    return const SizedBox.shrink();
                                  },
                                ),
                                _FoodHero(
                                  isArabic: isArabic,
                                  images: controller.galleryImages,
                                  currentIndex: controller.currentImageIndex,
                                  pageController: _pageController,
                                  isFavorite: controller.isFavorite,
                                  onBack: Get.back,
                                  onShare: controller.shareItem,
                                  onFavorite: controller.toggleFavorite,
                                  onPageChanged:
                                      controller.setCurrentImageIndex,
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -26),
                                  child: _FoodDetailsSheet(
                                    controller: controller,
                                    isArabic: isArabic,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FoodHero extends StatelessWidget {
  const _FoodHero({
    required this.isArabic,
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.isFavorite,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
    required this.onPageChanged,
  });

  final bool isArabic;
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    const heroHeight = 320.0;
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            _HeroPlaceholder()
          else if (images.length == 1)
            _HeroImage(url: images.first)
          else
            PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return _HeroImage(url: images[index]);
              },
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _TopActionButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: onBack,
                    ),
                    const Spacer(),
                    _TopActionButton(
                      icon: Icons.share_outlined,
                      onTap: onShare,
                    ),
                    const SizedBox(width: 10),
                    _TopActionButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onTap: onFavorite,
                      iconColor:
                          isFavorite ? const Color(0xFFE04B4B) : palette.text,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (images.isNotEmpty)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final active = index == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF175E34)
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    final normalized = AppLink.normalizeUrl(url);
    return CachedNetworkImage(
      imageUrl: normalized,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(
        color: palette.surfaceSoft,
      ),
      errorWidget: (context, _, __) => Container(
        color: palette.surfaceSoft,
        child: Center(
          child: Icon(
            Icons.fastfood_rounded,
            size: 56,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return Container(
      color: palette.surfaceSoft,
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _FoodDetailsSheet extends StatelessWidget {
  const _FoodDetailsSheet({
    required this.controller,
    required this.isArabic,
  });

  final FoodItemDetailsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final item = controller.item!;
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    final title = isArabic ? item.nameAr : item.nameEn;
    final description = isArabic ? item.descriptionAr : item.descriptionEn;
    final ratingCount = _formatReviewCount(controller.reviewsCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageDots(
            currentIndex: controller.currentImageIndex,
            totalCount: controller.galleryImages.isEmpty
                ? 1
                : controller.galleryImages.length,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatMoney(item.price)} ${AppCurrency.code}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.text,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '($ratingCount)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.displayTags
                          .map(
                            (tag) => _TagChip(
                              label: isArabic ? tag.labelAr : tag.labelEn,
                              icon: _tagIcon(tag.iconKey),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'الوصف' : 'Description',
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSoft,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 20),
          if (controller.ingredientGroups.isNotEmpty) ...[
            _SectionHeader(
              title: isArabic ? 'مكونات الوجبة' : 'Meal ingredients',
              subtitle: isArabic
                  ? 'يمكنك إلغاء تحديد أي مكوّن لا تريده.'
                  : 'Remove any ingredient you do not want.',
            ),
            const SizedBox(height: 12),
            ...controller.ingredientGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModifierGroupCard(
                  group: group,
                  controller: controller,
                  isArabic: isArabic,
                ),
              ),
            ),
          ],
          if (controller.extraGroups.isNotEmpty) ...[
            const SizedBox(height: 6),
            _SectionHeader(
              title: isArabic ? 'الإضافات الاختيارية' : 'Optional add-ons',
              subtitle: isArabic
                  ? 'اختر ما تريد إضافته إلى الوجبة.'
                  : 'Pick the extras you want with the meal.',
            ),
            const SizedBox(height: 12),
            ...controller.extraGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModifierGroupCard(
                  group: group,
                  controller: controller,
                  isArabic: isArabic,
                ),
              ),
            ),
          ],
          if (controller.groups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surfacePale,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                isArabic
                    ? 'لا توجد مكونات أو إضافات متاحة لهذا الصنف حاليًا.'
                    : 'No ingredients or add-ons are available for this item right now.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSoft,
                ),
              ),
            ),
          if (controller.groups.isNotEmpty) const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.surfacePale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: palette.textSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'يمكن أن تختلف الإضافات حسب توفرها في المطعم'
                        : 'Toppings may vary depending on restaurant availability',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSoft,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'ملاحظات' : 'Notes',
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.noteController,
            minLines: 2,
            maxLines: 4,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: isArabic
                  ? 'اكتب ملاحظاتك هنا (اختياري)'
                  : 'Write your notes here (optional)',
              hintTextDirection:
                  isArabic ? TextDirection.rtl : TextDirection.ltr,
              filled: true,
              fillColor: palette.surfacePale,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              _NoteChip(
                label: isArabic ? 'بدون ثوم' : 'No garlic',
                onTap: () =>
                    controller.appendNote(isArabic ? 'بدون ثوم' : 'No garlic'),
              ),
              _NoteChip(
                label: isArabic ? 'بدون مخلل' : 'No pickles',
                onTap: () => controller
                    .appendNote(isArabic ? 'بدون مخلل' : 'No pickles'),
              ),
              _NoteChip(
                label: isArabic ? 'زيادة صوص' : 'Extra sauce',
                onTap: () => controller
                    .appendNote(isArabic ? 'زيادة صوص' : 'Extra sauce'),
              ),
              _NoteChip(
                label: isArabic ? 'خبز محمص' : 'Toasted bread',
                onTap: () => controller
                    .appendNote(isArabic ? 'خبز محمص' : 'Toasted bread'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الكمية' : 'Quantity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuantityStepper(
                      quantity: controller.quantity,
                      onMinus: controller.decrementQuantity,
                      onPlus: controller.incrementQuantity,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isArabic ? 'السعر' : 'Price',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.textSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_formatMoney(controller.unitPrice)} ${AppCurrency.code}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfacePale,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSoft,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierGroupCard extends StatelessWidget {
  const _ModifierGroupCard({
    required this.group,
    required this.controller,
    required this.isArabic,
  });

  final FoodModifierGroupModel group;
  final FoodItemDetailsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? group.nameAr : group.nameEn,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _GroupBadge(
                label: group.isRequired
                    ? (isArabic ? 'إجباري' : 'Required')
                    : (isArabic ? 'اختياري' : 'Optional'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...group.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModifierOptionTile(
                group: group,
                option: option,
                controller: controller,
                isArabic: isArabic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierOptionTile extends StatelessWidget {
  const _ModifierOptionTile({
    required this.group,
    required this.option,
    required this.controller,
    required this.isArabic,
  });

  final FoodModifierGroupModel group;
  final FoodModifierOptionModel option;
  final FoodItemDetailsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    final selected = controller.isSelected(group.id, option.id);
    final locked = !option.isRemovable;
    final title = isArabic ? option.nameAr : option.nameEn;
    final priceLabel = option.priceDelta <= 0
        ? (isArabic ? 'مجانا' : 'Free')
        : '+${_formatMoney(option.priceDelta)} ${AppCurrency.code}';

    return InkWell(
      onTap: locked ? null : () => controller.toggleOption(group, option),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10)
              : palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : palette.border,
          ),
        ),
        child: Row(
          children: [
            _OptionCheckBox(
              selected: selected,
              locked: locked,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    priceLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _OptionThumb(imageUrl: option.imageUrl, fallbackLabel: title),
          ],
        ),
      ),
    );
  }
}

class _OptionThumb extends StatelessWidget {
  const _OptionThumb({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    final normalized = AppLink.normalizeUrl(imageUrl);
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: normalized.trim().isEmpty
          ? Container(
              color: palette.surfaceSoft,
              child: Icon(
                Icons.lunch_dining_rounded,
                color: theme.colorScheme.primary,
              ),
            )
          : CachedNetworkImage(
              imageUrl: normalized,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(
                color: palette.surfaceSoft,
              ),
              errorWidget: (context, _, __) => Container(
                color: palette.surfaceSoft,
                child: Icon(
                  Icons.lunch_dining_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
    );
  }
}

class _OptionCheckBox extends StatelessWidget {
  const _OptionCheckBox({
    required this.selected,
    required this.locked,
  });

  final bool selected;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    final color = locked
        ? theme.colorScheme.primary
        : selected
            ? theme.colorScheme.primary
            : palette.border;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected || locked
            ? color.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.20 : 0.12,
              )
            : palette.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.3),
      ),
      child: Icon(
        locked
            ? Icons.lock_rounded
            : selected
                ? Icons.check_rounded
                : Icons.circle_outlined,
        size: locked ? 13 : 15,
        color: color,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfacePale,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: palette.border),
        backgroundColor: palette.card,
        foregroundColor: palette.text,
      ),
      child: Text(label),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surfacePale,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: onMinus,
            filled: false,
          ),
          Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.text,
                ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onPlus,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? theme.colorScheme.primary : palette.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: filled ? theme.colorScheme.primary : palette.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : palette.text,
        ),
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.currentIndex,
    required this.totalCount,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary : palette.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _FoodThemeTokens(theme);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.card,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? palette.text),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isArabic,
    required this.totalPrice,
    required this.quantity,
    required this.isAdding,
    required this.onTap,
  });

  final bool isArabic;
  final double totalPrice;
  final int quantity;
  final bool isAdding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isAdding ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.86)
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D6B3C),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$quantity',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_formatMoney(totalPrice)} ${AppCurrency.code}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? 'إضافة إلى السلة' : 'Add to cart',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _tagIcon(String key) {
  switch (key.toLowerCase()) {
    case 'category':
      return Icons.restaurant_menu_rounded;
    case 'toppings':
      return Icons.tapas_rounded;
    case 'ingredient':
      return Icons.lunch_dining_rounded;
    case 'discount':
      return Icons.local_offer_rounded;
    case 'available':
      return Icons.verified_rounded;
    case 'unavailable':
      return Icons.block_rounded;
    case 'ready':
      return Icons.local_fire_department_rounded;
    default:
      return Icons.local_dining_rounded;
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

String _formatReviewCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return '$count';
}
