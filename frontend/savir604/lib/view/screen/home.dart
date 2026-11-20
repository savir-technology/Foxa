import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:tks/controler/home/home_controller.dart';
import 'package:tks/controler/notification_con.dart';
import 'package:tks/controler/settings/settings_controller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/core/constant/imsgesassets.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/functions/app_image_urls.dart';
import 'package:tks/core/functions/app_video_urls.dart';
import 'package:tks/core/functions/category_image_assets.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';
import 'package:tks/view/widget/common/inline_ad_banner.dart';
import 'package:tks/data/datasource/model/aleppo_home_model.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/data/datasource/model/video_model.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/notification/notification_page.dart';
import 'package:tks/view/screen/profile_page.dart';
import 'package:tks/view/screen/video_feed_page.dart';
import 'package:video_player/video_player.dart';

class _ThemeTokens {
  const _ThemeTokens(this.theme);

  final ThemeData theme;

  bool get isDark => theme.brightness == Brightness.dark;
  Color get card => theme.cardColor;
  Color get border =>
      theme.dividerColor.withValues(alpha: isDark ? 0.86 : 0.72);
  Color get text => theme.colorScheme.onSurface;
  Color get textSoft =>
      theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.62);
  Color get surfaceSoft =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7);
  Color get surfaceMint =>
      isDark ? const Color(0xFF3A2419) : const Color(0xFFFFE8DC);
  Color get surfacePale =>
      isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5);
  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.22 : 0.05);
}

double _homeHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) return 12;
  if (width < 600) return 16;
  if (width < 900) return 24;
  return 32;
}

class _HomeSectionReveal extends StatefulWidget {
  const _HomeSectionReveal({
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<_HomeSectionReveal> createState() => _HomeSectionRevealState();
}

class _HomeSectionRevealState extends State<_HomeSectionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 0,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _start();
  }

  void _start() {
    if (_started) return;
    _started = true;
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _commerceMode = 'all';

  bool _isStoreItem(ItemsModel item) =>
      item.vendorType?.toLowerCase() == 'store' ||
      (item.productType?.trim().isNotEmpty == true &&
          item.productType != 'food');

  List<AleppoRestaurantSectionModel> _visibleRestaurantSections(
    List<AleppoRestaurantSectionModel> sections,
  ) {
    if (_commerceMode == 'all') return sections;
    final wantStore = _commerceMode == 'stores';
    return sections
        .map(
          (section) => AleppoRestaurantSectionModel(
            key: section.key,
            titleAr: section.titleAr,
            titleEn: section.titleEn,
            restaurants: section.restaurants
                .where((restaurant) =>
                    restaurant.vendorType.toLowerCase() ==
                    (wantStore ? 'store' : 'restaurant'))
                .toList(),
          ),
        )
        .where((section) => section.restaurants.isNotEmpty)
        .toList();
  }

  List<AleppoProductSectionModel> _visibleProductSections(
    List<AleppoProductSectionModel> sections,
  ) {
    final wantStore = _commerceMode == 'stores';
    return sections
        .map(
          (section) => AleppoProductSectionModel(
            key: section.key,
            titleAr: section.titleAr,
            titleEn: section.titleEn,
            items: _uniqueProductItems(section.items)
                .where(
                  (item) =>
                      _commerceMode == 'all' || _isStoreItem(item) == wantStore,
                )
                .toList(),
          ),
        )
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  List<ItemsModel> _uniqueProductItems(List<ItemsModel> items) {
    final seen = <String>{};
    return items.where((item) {
      final itemId = (item.itemsId ?? '').trim();
      final vendorId = (item.vendorId ?? '').trim();
      final fallback = [
        vendorId,
        (item.itemsNameAr ?? item.itemsNameEn ?? '').trim().toLowerCase(),
        (item.itemsPrice ?? '').trim(),
      ].join('|');
      final key = itemId.isNotEmpty ? '$vendorId|$itemId' : fallback;
      return key.isNotEmpty && seen.add(key);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeControllerImp>(
      builder: (controller) {
        final visibleRestaurantSections =
            _visibleRestaurantSections(controller.restaurantSections);
        final visibleProductSections =
            _visibleProductSections(controller.productSections);
        final mostOrderedSection =
            _sectionByKey(visibleRestaurantSections, 'most_ordered');
        final openNowSection =
            _sectionByKey(visibleRestaurantSections, 'open_now');
        final mostOrderedProductsSection = _productSectionByKey(
          visibleProductSections,
          'most_ordered_products',
        );
        final personalizedProductsSection = _productSectionByKey(
          visibleProductSections,
          'recommended_for_you',
        );
        final visibleCategories = _commerceMode == 'all'
            ? [
                ...controller.restaurantCategories,
                ...controller.storeCategories,
              ]
            : _commerceMode == 'stores'
                ? controller.storeCategories
                : controller.restaurantCategories;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final horizontalPadding = _homeHorizontalPadding(context);
        Widget reveal(Widget child, int index) {
          return _HomeSectionReveal(
            delay: Duration(milliseconds: index > 6 ? 270 : 45 * index),
            child: child,
          );
        }

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0B0B0B) : const Color(0xFFFAFAFA),
          body: SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.secondary,
              onRefresh: controller.refreshHome,
              child: HandlingDataView(
                statusRequest: controller.statusRequest,
                widget: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: reveal(
                        Column(
                          children: [
                            _TopHeader(controller: controller),
                            _CommerceHomeTabs(
                              mode: _commerceMode,
                              isArabic: controller.isArabic,
                              onChanged: (mode) =>
                                  setState(() => _commerceMode = mode),
                            ),
                          ],
                        ),
                        0,
                      ),
                    ),
                    if (visibleCategories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: reveal(
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              12,
                              horizontalPadding,
                              0,
                            ),
                            child: _CategoryShelf(
                              controller: controller,
                              categories: visibleCategories,
                            ),
                          ),
                          1,
                        ),
                      ),
                    if (controller.homeVideos.isNotEmpty)
                      SliverToBoxAdapter(
                        child: reveal(
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              16,
                              horizontalPadding,
                              0,
                            ),
                            child: _HomeVideosStrip(controller: controller),
                          ),
                          2,
                        ),
                      ),
                    if (mostOrderedSection != null &&
                        mostOrderedSection.restaurants.isNotEmpty)
                      SliverToBoxAdapter(
                        child: reveal(
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              22,
                              horizontalPadding,
                              0,
                            ),
                            child: _MostOrderedSection(
                              section: mostOrderedSection,
                              isArabic: controller.isArabic,
                              onTapRestaurant: controller.openRestaurant,
                              onTapViewAll: () {
                                final restaurants = _collectAllRestaurants(
                                    visibleRestaurantSections);
                                Get.to(
                                  () => _AllRestaurantsPage(
                                    restaurants: restaurants,
                                    isArabic: controller.isArabic,
                                    isStore: _commerceMode == 'stores',
                                    onTapRestaurant: controller.openRestaurant,
                                  ),
                                );
                              },
                            ),
                          ),
                          3,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: reveal(
                        InlineAdBanner(
                          placement: 'home_middle',
                          height: (MediaQuery.of(context).size.width * 0.42)
                              .clamp(175.0, 225.0),
                          margin: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            18,
                            horizontalPadding,
                            0,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          enableAutoRotate: true,
                          showIndicators: true,
                        ),
                        4,
                      ),
                    ),
                    if (openNowSection != null &&
                        openNowSection.restaurants.isNotEmpty)
                      SliverToBoxAdapter(
                        child: reveal(
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              22,
                              horizontalPadding,
                              0,
                            ),
                            child: _OpenNowSection(
                              section: openNowSection,
                              isArabic: controller.isArabic,
                              isStore: _commerceMode == 'stores',
                              onTapRestaurant: controller.openRestaurant,
                            ),
                          ),
                          5,
                        ),
                      ),
                    if (mostOrderedProductsSection != null &&
                        mostOrderedProductsSection.items.isNotEmpty)
                      SliverToBoxAdapter(
                        child: reveal(
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              0,
                            ),
                            child: _ProductSectionBlock(
                              title: controller.isArabic
                                  ? 'المنتجات الأكثر طلباً'
                                  : 'Most ordered products',
                              subtitle: controller.isArabic
                                  ? 'أشهر المنتجات التي يتم طلبها كثيراً'
                                  : 'Popular items ordered the most',
                              items: mostOrderedProductsSection.items,
                              isArabic: controller.isArabic,
                              onTapItem: (item) =>
                                  controller.goToPageProductDetails(item),
                            ),
                          ),
                          6,
                        ),
                      ),
                    if (personalizedProductsSection != null &&
                        personalizedProductsSection.items.isNotEmpty)
                      SliverToBoxAdapter(
                        child: reveal(
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              10,
                              horizontalPadding,
                              0,
                            ),
                            child: _ProductSectionBlock(
                              title: controller.isArabic
                                  ? 'المنتجات المخصصة لك'
                                  : 'Recommended for you',
                              subtitle: controller.isArabic
                                  ? 'منتجات مبنية على طلباتك السابقة'
                                  : 'Picked from your previous orders',
                              items: personalizedProductsSection.items,
                              isArabic: controller.isArabic,
                              onTapItem: (item) =>
                                  controller.goToPageProductDetails(item),
                            ),
                          ),
                          7,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommerceHomeTabs extends StatelessWidget {
  const _CommerceHomeTabs({
    required this.mode,
    required this.isArabic,
    required this.onChanged,
  });

  final String mode;
  final bool isArabic;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      ('all', isArabic ? 'الرئيسية' : 'Home', '⌂'),
      ('restaurants', isArabic ? 'مطاعم  و متاجر' : 'Food & Restaurants', '🍔'),
      ('stores', isArabic ? 'متاجر' : 'Shops', '🛒'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((option) {
            final selected = mode == option.$1;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: selected,
                showCheckmark: false,
                avatar: Text(
                  option.$1 == 'all' ? '🏠' : option.$3,
                  style: const TextStyle(fontSize: 18),
                ),
                label: Text(option.$2),
                onSelected: (_) => onChanged(option.$1),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.cardColor,
                side: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.7),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                labelStyle: TextStyle(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.controller});

  final HomeControllerImp controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = Get.find<MyServices>();
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    final notifications = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    final storedImage = services.sharedPreferences.getString('users_image');
    final dynamic profileImage = settings.userData?['users_image'];
    final imageName = ((profileImage ?? storedImage) ?? '').toString().trim();
    final imageUrl = imageName.isEmpty
        ? null
        : AppLink.normalizeUrl(
            '${AppLink.server}/uploads/users/img/$imageName',
          );

    final username = (controller.username ?? '').trim();
    final displayName = username.isEmpty
        ? (controller.isArabic ? 'ضيفنا العزيز' : 'Guest')
        : username;
    final isArabic = controller.isArabic;
    final horizontalPadding = _homeHorizontalPadding(context);
    final heroHeight =
        (MediaQuery.of(context).size.width * 0.60).clamp(220.0, 290.0);
    final addressTitle = isArabic ? 'عنوان التوصيل' : 'Delivery address';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InlineAdBanner(
            placement: 'home',
            height: heroHeight,
            borderRadius: BorderRadius.zero,
            showFrame: false,
            overlayIndicators: true,
            blendWithBackground: true,
            backgroundBlendColor: theme.scaffoldBackgroundColor,
            fallbackToGeneralAds: true,
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
            child: _FeatureCardStrip(isArabic: isArabic),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
            child: _LocationCard(
              isArabic: isArabic,
              title: addressTitle,
              subtitle: controller.deliveryPrompt,
              imageUrl: imageUrl,
              displayName: displayName,
              notificationCount: notifications.unreadCount,
              onNotificationTap: () => Get.to(() => const NotificationPage()),
              onTap: controller.openAddressView,
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
            child: _HomeSearchBar(
              controller: controller,
              suggestions: _productSearchSuggestions(controller),
              onFilterTap: () => _showHomeFilters(context, controller),
              onSearchTap: () => _showHomeSearchSheet(context, controller),
              onSuggestionTap: controller.goToPageProductDetails,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatefulWidget {
  const _HomeSearchBar({
    required this.controller,
    required this.suggestions,
    required this.onFilterTap,
    required this.onSearchTap,
    required this.onSuggestionTap,
  });

  final HomeControllerImp controller;
  final List<ItemsModel> suggestions;
  final VoidCallback onFilterTap;
  final VoidCallback onSearchTap;
  final void Function(ItemsModel item) onSuggestionTap;

  @override
  State<_HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<_HomeSearchBar> {
  Timer? _suggestionTimer;
  int _suggestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSuggestionRotation();
  }

  @override
  void didUpdateWidget(covariant _HomeSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameSuggestions(oldWidget.suggestions, widget.suggestions)) {
      _suggestionIndex = 0;
      _startSuggestionRotation();
    }
  }

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void _startSuggestionRotation() {
    _suggestionTimer?.cancel();
    if (widget.suggestions.length < 2) return;

    _suggestionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.suggestions.length < 2) return;
      setState(() {
        _suggestionIndex = (_suggestionIndex + 1) % widget.suggestions.length;
      });
    });
  }

  bool _sameSuggestions(List<ItemsModel> first, List<ItemsModel> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].itemsId != second[index].itemsId) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final suggestions = widget.suggestions;
    final item = suggestions.isEmpty
        ? null
        : suggestions[_suggestionIndex % suggestions.length];
    final isArabic = widget.controller.isArabic;
    final itemName = item == null
        ? ''
        : _localized(
            item.itemsNameAr ?? '',
            item.itemsNameEn ?? '',
            isArabic,
          );
    final itemDescription = item == null
        ? ''
        : _shortSearchDescription(
            _localized(
              item.itemsDescAr ?? '',
              item.itemsDescEn ?? '',
              isArabic,
            ),
          );
    final suggestionLabel =
        itemDescription.isEmpty ? itemName : '$itemDescription، $itemName';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onSearchTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _SearchActionButton(
                icon: Icons.tune_rounded,
                onTap: widget.onFilterTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSearchTap,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: item == null
                        ? Text(
                            widget.controller.isArabic
                                ? 'ابحث عن مطاعم، أطباق، تصنيفات...'
                                : 'Search restaurants, dishes, categories...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF9B9B9B),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            children: [
                              Text(
                                isArabic ? 'ابحث عن 🛒' : 'Search for 🛒',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF9B9B9B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 138),
                                child: ClipRect(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 420),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.8),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                    child: Text(
                                      suggestionLabel,
                                      key: ValueKey(item.itemsId),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      textDirection: isArabic
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: const Color(0xFF9B9B9B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.search_rounded,
                color: palette.text,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAppBarCard extends StatelessWidget {
  const _HeroAppBarCard({
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final primary = theme.colorScheme.primary;
    final heroHeight = MediaQuery.of(context).size.width * 0.62;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Container(
          color: palette.card,
          child: SizedBox(
            height: heroHeight.clamp(248.0, 330.0),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette.isDark
                              ? const Color(0xFF1A2A20)
                              : const Color(0xFFFDFDFB),
                          palette.isDark
                              ? const Color(0xFF263C2D)
                              : const Color(0xFFEAF4E7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 14,
                  start: 16,
                  child: Text(
                    '11:52',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: palette.text,
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  end: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.signal_cellular_alt_rounded,
                          size: 18, color: palette.text),
                      const SizedBox(width: 4),
                      Icon(Icons.wifi_rounded, size: 18, color: palette.text),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_full_rounded,
                          size: 20, color: palette.text),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: 54,
                  start: 20,
                  child: SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'FOXA' : 'FOXA',
                          maxLines: 1,
                          textAlign: TextAlign.start,
                          style: theme.textTheme.displaySmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w900,
                                height: 0.88,
                                fontSize: 52,
                              ) ??
                              TextStyle(
                                color: primary,
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isArabic
                              ? 'توصيل سريع خلال دقائق'
                              : 'Fast delivery in minutes',
                          maxLines: 2,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              isArabic ? 'حمل التطبيق الآن' : 'Download now',
                              style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 20,
                  end: 0,
                  child: SizedBox(
                    width: 230,
                    height: 240,
                    child: Image.asset(
                      AppImageAsset.driverPromo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAdsSlider extends StatefulWidget {
  const _HomeAdsSlider({
    required this.banners,
    required this.isArabic,
    required this.onTapBanner,
  });

  final List<AleppoHomeBannerModel> banners;
  final bool isArabic;
  final void Function(AleppoHomeBannerModel banner) onTapBanner;

  @override
  State<_HomeAdsSlider> createState() => _HomeAdsSliderState();
}

class _HomeAdsSliderState extends State<_HomeAdsSlider> {
  final PageController _pageController = PageController();
  Timer? _rotationTimer;
  int _currentIndex = 0;

  List<AleppoHomeBannerModel> get _slides {
    final banners = widget.banners;
    if (banners.isNotEmpty) {
      return banners;
    }
    return const <AleppoHomeBannerModel>[];
  }

  @override
  void didUpdateWidget(covariant _HomeAdsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _currentIndex = 0;
      _scheduleRotation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleRotation() {
    _rotationTimer?.cancel();
    if (_slides.length <= 1) return;

    final seconds = 5;
    _rotationTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1)
        return;
      final nextIndex = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = MediaQuery.of(context).size.width * 0.78;
    final bannerHeight = height.clamp(280.0, 340.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rotationTimer == null) {
        _scheduleRotation();
      }
    });

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              height: bannerHeight,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  if (!mounted) return;
                  setState(() => _currentIndex = index);
                  _scheduleRotation();
                },
                itemBuilder: (context, index) {
                  final banner = slides[index];
                  final imageUrl = AppLink.normalizeUrl(banner.imageUrl);
                  final fallbackColor = _parseHexColor(
                    banner.backgroundColor,
                    fallback: const Color(0xFFF3F5F0),
                  );

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onTapBanner(banner),
                      child: Container(
                        width: double.infinity,
                        color: fallbackColor,
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (_, __) => Container(
                                  color: fallbackColor,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: fallbackColor,
                                ),
                              )
                            : _FallbackBannerSurface(
                                banner: banner,
                                isArabic: widget.isArabic,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (slides.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) {
                final active = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1B6E2F)
                        : Colors.grey.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _FallbackBannerSurface extends StatelessWidget {
  const _FallbackBannerSurface({
    required this.banner,
    required this.isArabic,
  });

  final AleppoHomeBannerModel banner;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final title = isArabic ? banner.titleAr : banner.titleEn;
    final subtitle = isArabic ? banner.subtitleAr : banner.subtitleEn;
    final ctaLabel = isArabic ? banner.ctaLabelAr : banner.ctaLabelEn;
    final bg = _parseHexColor(
      banner.backgroundColor,
      fallback: const Color(0xFFFFF3EC),
    );
    final fg = _parseHexColor(
      banner.textColor,
      fallback: const Color(0xFFFF6500),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        gradient: LinearGradient(
          colors: [
            bg,
            bg.withValues(alpha: 0.82),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          if (banner.imageUrl.trim().isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.98,
                child: CachedNetworkImage(
                  imageUrl: AppLink.normalizeUrl(banner.imageUrl),
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          PositionedDirectional(
            top: 28,
            start: 18,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.trim().isNotEmpty)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w900,
                            height: 0.9,
                            fontSize: 46,
                          ),
                    ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                    ),
                  ],
                  if (ctaLabel.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: fg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ctaLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardStrip extends StatelessWidget {
  const _FeatureCardStrip({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final features = <_FeatureTileData>[
      _FeatureTileData(
        icon: Icons.delivery_dining_outlined,
        labelAr: 'توصيل سريع',
        labelEn: 'Fast delivery',
      ),
      _FeatureTileData(
        icon: Icons.verified_outlined,
        labelAr: 'دفع آمن',
        labelEn: 'Secure pay',
      ),
      _FeatureTileData(
        icon: Icons.star_border_rounded,
        labelAr: 'أفضل المطاعم',
        labelEn: 'Top restaurants',
      ),
      _FeatureTileData(
        icon: Icons.location_on_outlined,
        labelAr: 'حدد موقعك',
        labelEn: 'Set location',
      ),
    ];

    final items = features;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: palette.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == items.length - 1 ? 0 : 6,
              ),
              child: Container(
                width: 266,
                decoration: BoxDecoration(
                  border: index == 0
                      ? null
                      : BorderDirectional(
                          start: BorderSide(color: palette.border),
                        ),
                ),
                padding: const EdgeInsetsDirectional.only(start: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isArabic ? item.labelAr : item.labelEn,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FeatureTileData {
  const _FeatureTileData({
    required this.icon,
    required this.labelAr,
    required this.labelEn,
  });

  final IconData icon;
  final String labelAr;
  final String labelEn;
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.isArabic,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.displayName,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onTap,
  });

  final bool isArabic;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String displayName;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            _ProfileAvatar(
              imageUrl: imageUrl,
              name: displayName,
              size: 40,
              onTap: onTap,
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: palette.textSoft,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.location_on_rounded,
              size: 25,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            _NotificationButton(
              count: notificationCount,
              onTap: onNotificationTap,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}

List<AleppoHomeBannerModel> _homeBanners(HomeControllerImp controller) {
  final banners = <AleppoHomeBannerModel>[
    ...controller.banners,
  ];
  final notificationBanner = controller.notificationBanner;
  if (notificationBanner != null &&
      banners.every((banner) => banner.id != notificationBanner.id)) {
    banners.insert(0, notificationBanner);
  }
  return banners;
}

List<ItemsModel> _productSearchSuggestions(HomeControllerImp controller) {
  final seen = <String>{};
  final suggestions = <ItemsModel>[];

  for (final section in controller.productSections) {
    for (final item in section.items) {
      final name = _localized(
        item.itemsNameAr ?? '',
        item.itemsNameEn ?? '',
        controller.isArabic,
      );
      final identity = (item.itemsId ?? name).trim();
      if (name.trim().isEmpty || identity.isEmpty || !seen.add(identity)) {
        continue;
      }
      suggestions.add(item);
      if (suggestions.length == 12) return suggestions;
    }
  }

  return suggestions;
}

String _shortSearchDescription(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 38) return normalized;
  return '${normalized.substring(0, 38).trim()}...';
}

Color _parseHexColor(String value, {required Color fallback}) {
  final normalized = value.trim();
  if (normalized.isEmpty) return fallback;
  final hex = normalized.replaceFirst('#', '');
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

void _showHomeSearchSheet(BuildContext context, HomeControllerImp controller) {
  final unique = <String, ItemsModel>{};
  for (final section in controller.productSections) {
    for (final item in section.items) {
      final key = (item.itemsId ?? item.itemsNameEn ?? item.itemsNameAr ?? '')
          .toString()
          .trim();
      if (key.isNotEmpty) unique[key] = item;
    }
  }

  final products = unique.values.toList()
    ..sort((a, b) => (int.tryParse(b.itemsDiscount ?? '0') ?? 0)
        .compareTo(int.tryParse(a.itemsDiscount ?? '0') ?? 0));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HomeSearchSheet(
      products: products,
      isArabic: controller.isArabic,
      onProductTap: (item) {
        Get.back();
        controller.goToPageProductDetails(item);
      },
    ),
  );
}

class _HomeSearchSheet extends StatefulWidget {
  const _HomeSearchSheet({
    required this.products,
    required this.isArabic,
    required this.onProductTap,
  });

  final List<ItemsModel> products;
  final bool isArabic;
  final ValueChanged<ItemsModel> onProductTap;

  @override
  State<_HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends State<_HomeSearchSheet> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((item) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return [
        item.itemsNameAr,
        item.itemsNameEn,
        item.storeName,
        item.vendorName
      ].whereType<String>().join(' ').toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D8DE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: widget.isArabic
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Text(
                widget.isArabic ? 'ابحث عن منتج' : 'Search products',
                style: const TextStyle(
                  color: Color(0xFFFF6500),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _queryController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              textDirection:
                  widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F6F2),
                hintText: widget.isArabic
                    ? 'اكتب اسم المنتج أو المتجر'
                    : 'Type a product or store name',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF667085)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: widget.isArabic
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Text(
                widget.isArabic ? 'أعلى الخصومات' : 'Top discounts',
                style: const TextStyle(
                  color: Color(0xFF243233),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(widget.isArabic
                          ? 'لا توجد منتجات مطابقة'
                          : 'No matching products'),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final discount =
                            int.tryParse(item.itemsDiscount ?? '0') ?? 0;
                        final name = _localized(
                          item.itemsNameAr ?? '',
                          item.itemsNameEn ?? '',
                          widget.isArabic,
                          fallbackAr: 'منتج',
                          fallbackEn: 'Product',
                        );
                        return ListTile(
                          onTap: () => widget.onProductTap(item),
                          tileColor: const Color(0xFFF8F9F6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: SizedBox(
                            width: 58,
                            height: 58,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FallbackNetworkImage(
                                imageUrls: _productImageUrls(item),
                                label: name,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: const Color(0xFFE8EEE7),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_outlined,
                                      color: Color(0xFF7B8A86)),
                                ),
                                errorWidget: Container(
                                  color: const Color(0xFFE8EEE7),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.fastfood_outlined,
                                      color: Color(0xFFFF6500)),
                                ),
                              ),
                            ),
                          ),
                          title: Text(name,
                              textDirection: widget.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: const TextStyle(
                                  color: Color(0xFF243233),
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(widget.isArabic ? 'عروض' : 'Offers',
                              style: const TextStyle(
                                  color: Color(0xFFFF6500),
                                  fontWeight: FontWeight.w700)),
                          trailing: discount > 0
                              ? Text('-$discount%',
                                  style: const TextStyle(
                                      color: Color(0xFFFF6500),
                                      fontWeight: FontWeight.w800))
                              : const Icon(Icons.chevron_right,
                                  color: Color(0xFF667085)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  const _SearchActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);

    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            color: palette.text,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _BrandHeroBanner extends StatelessWidget {
  const _BrandHeroBanner({
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final primary = theme.colorScheme.primary;
    final background =
        palette.isDark ? const Color(0xFF10261A) : const Color(0xFFF4FAF5);
    final backgroundEnd =
        palette.isDark ? const Color(0xFF1C5A31) : const Color(0xFFDDEFE2);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        constraints: const BoxConstraints(minHeight: 210),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [background, backgroundEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: palette.isDark ? 0.16 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'FOXA' : 'FOXA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: theme.textTheme.displaySmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                          fontSize: 46,
                        ) ??
                        TextStyle(
                          color: primary,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isArabic
                        ? 'توصيل سريع خلال دقائق'
                        : 'Fast delivery in minutes',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        isArabic ? 'حمل التطبيق الآن' : 'Download now',
                        style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 148,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            primary.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          radius: 0.86,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    AppImageAsset.driverPromo,
                    fit: BoxFit.contain,
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

Future<void> _showHomeFilters(
  BuildContext context,
  HomeControllerImp controller,
) async {
  final theme = Theme.of(context);
  final isArabic = controller.isArabic;

  await Get.bottomSheet<void>(
    SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'فلاتر سريعة' : 'Quick filters',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF161616),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'اختر بسرعة قبل استعراض الأقسام أو العروض.'
                  : 'Jump straight to a section with one tap.',
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B6B6B),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: isArabic ? WrapAlignment.end : WrapAlignment.start,
              children: [
                ActionChip(
                  label: Text(isArabic ? 'الأقسام' : 'Categories'),
                  onPressed: () {
                    Get.back();
                    controller.openSearchPage();
                  },
                ),
                ActionChip(
                  label: Text(isArabic ? 'العروض' : 'Offers'),
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.offers);
                  },
                ),
                ActionChip(
                  label: Text(isArabic ? 'العنوان' : 'Address'),
                  onPressed: () {
                    Get.back();
                    controller.openAddressView();
                  },
                ),
                ActionChip(
                  label: Text(isArabic ? 'بحث سريع' : 'Quick search'),
                  onPressed: () {
                    Get.back();
                    controller.openSearchPage();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Get.back();
                  controller.openSearchPage();
                },
                child: Text(
                  isArabic ? 'استعرض المطاعم' : 'Browse restaurants',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _HomeVideosStrip extends StatelessWidget {
  const _HomeVideosStrip({required this.controller});

  final HomeControllerImp controller;

  @override
  Widget build(BuildContext context) {
    final videos = controller.homeVideos;
    final isArabic = controller.isArabic;

    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeaderRow(
          title: 'reels_stories'.tr,
          actionLabel: 'view_all'.tr,
          onTap: () => Get.to(() => const VideoFeedPage()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: isArabic,
            padding: EdgeInsets.zero,
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final video = videos[index];
              return _HomeVideoCard(
                key: ValueKey('home_video_${video.videoId}'),
                video: video,
                label: _videoStoryLabel(video, isArabic),
                previewUrls: _videoPreviewUrls(video),
                onTap: () => Get.to(() => VideoFeedPage(initialIndex: index)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeVideoCard extends StatefulWidget {
  const _HomeVideoCard({
    super.key,
    required this.video,
    required this.label,
    required this.previewUrls,
    required this.onTap,
  });

  final VideoModel video;
  final String label;
  final List<String> previewUrls;
  final VoidCallback onTap;

  @override
  State<_HomeVideoCard> createState() => _HomeVideoCardState();
}

class _HomeVideoCardState extends State<_HomeVideoCard> {
  VideoPlayerController? _previewController;
  bool _previewLoading = true;
  bool _previewFailed = false;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _initPreview() async {
    final candidates = AppVideoUrls.candidates(widget.video.videoUrl);
    for (final candidate in candidates) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(candidate));
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();

        if (!mounted) {
          await controller.dispose();
          return;
        }

        setState(() {
          _previewController = controller;
          _previewLoading = false;
          _previewFailed = false;
        });
        return;
      } catch (_) {
        await controller.dispose();
      }
    }

    if (!mounted) return;
    setState(() {
      _previewLoading = false;
      _previewFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final ringColor = theme.colorScheme.primary;

    return SizedBox(
      width: 78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 92,
                padding: const EdgeInsets.all(2.2),
                decoration: BoxDecoration(
                  color: ringColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ringColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPreview(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F1E8), Color(0xFFE3F0E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );

    final imagePreview = widget.previewUrls.isEmpty
        ? fallback
        : FallbackNetworkImage(
            imageUrls: widget.previewUrls,
            label: widget.label,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
            placeholder: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF7F3EC), Color(0xFFE8F3EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: fallback,
          );

    final videoPreview = _previewController != null &&
            _previewController!.value.isInitialized &&
            !_previewFailed &&
            _previewController!.value.size.width > 0 &&
            _previewController!.value.size.height > 0
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _previewController!.value.size.width,
              height: _previewController!.value.size.height,
              child: VideoPlayer(_previewController!),
            ),
          )
        : imagePreview;

    return Stack(
      fit: StackFit.expand,
      children: [
        videoPreview,
        if (_previewLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.10),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

String _videoStoryLabel(VideoModel video, bool isArabic) {
  final title = video.videoTitle?.trim() ?? '';
  if (title.isNotEmpty) {
    return title;
  }

  final uploader = video.uploaderName?.trim() ?? '';
  if (uploader.isNotEmpty) {
    return uploader;
  }

  final productName = video.productNameAr?.trim() ?? '';
  if (productName.isNotEmpty) {
    return productName;
  }

  return isArabic ? 'فيديو' : 'Video';
}

List<String> _videoPreviewUrls(VideoModel video) {
  final urls = <String>[];
  final thumbnail = video.videoThumbnail?.trim() ?? '';
  if (thumbnail.isNotEmpty) {
    final normalized = AppLink.normalizeUrl(thumbnail);
    urls.add(normalized);
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      urls.add(
          '${AppLink.server}/${normalized.replaceAll(RegExp(r'^/+'), '')}');
    }
  }
  urls.addAll(AppImageUrls.item(video.productImage));
  return urls.where((url) => url.trim().isNotEmpty).toList();
}

// ignore: unused_element
class _PromoRail extends StatelessWidget {
  const _PromoRail({required this.controller});

  final HomeControllerImp controller;

  @override
  Widget build(BuildContext context) {
    final cards = _promoCards(controller);

    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        reverse: controller.isArabic,
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _PromoCard(
            data: cards[index],
          );
        },
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.data});

  final _PromoCardData data;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final background = data.backgroundColor;
    final foreground = data.textColor;
    final title = _localized(data.titleAr, data.titleEn, isArabic);
    final subtitle = _localized(data.subtitleAr, data.subtitleEn, isArabic);
    final imageIsLeft = data.imageSide == _PromoImageSide.left;
    final hasSubtitle = subtitle.trim().isNotEmpty;

    Widget buildTextBlock() {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    fontSize: data.titleFontSize,
                  ),
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.82),
                      height: 1.1,
                      fontSize: data.subtitleFontSize,
                    ),
              ),
            ],
          ],
        ),
      );
    }

    Widget buildImage() {
      return Align(
        alignment: Alignment.center,
        child: Transform.scale(
          scale: data.imageScale,
          child: SizedBox(
            width: data.imageWidth,
            height: data.imageHeight,
            child: _PromoImage(
              source: data.imageSource,
              fallbackAsset: data.fallbackAsset,
              fit: data.imageFit,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 166,
        height: 132,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: imageIsLeft
                    ? [
                        buildImage(),
                        const SizedBox(width: 8),
                        Expanded(child: buildTextBlock()),
                      ]
                    : [
                        Expanded(child: buildTextBlock()),
                        const SizedBox(width: 8),
                        buildImage(),
                      ],
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: _PromoArrowButton(
                onTap: data.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoArrowButton extends StatelessWidget {
  const _PromoArrowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Material(
      color: palette.card,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: palette.card,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: palette.text,
          ),
        ),
      ),
    );
  }
}

class _PromoCardData {
  const _PromoCardData({
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.imageSource,
    required this.fallbackAsset,
    required this.backgroundColor,
    required this.textColor,
    required this.imageSide,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageFit,
    required this.imageScale,
    required this.textStart,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.onTap,
  });

  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String imageSource;
  final String fallbackAsset;
  final Color backgroundColor;
  final Color textColor;
  final _PromoImageSide imageSide;
  final double imageWidth;
  final double imageHeight;
  final BoxFit imageFit;
  final double imageScale;
  final double textStart;
  final double titleFontSize;
  final double subtitleFontSize;
  final VoidCallback onTap;
}

List<_PromoCardData> _promoCards(HomeControllerImp controller) {
  return <_PromoCardData>[
    _PromoCardData(
      titleAr: 'خصم 20%',
      titleEn: '20% off',
      subtitleAr: 'توصيل مجاني',
      subtitleEn: 'Free delivery',
      imageSource: AppImageAsset.shawarmaPromo,
      fallbackAsset: AppImageAsset.shawarmaPromo,
      backgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF2E4E34),
      imageSide: _PromoImageSide.left,
      imageWidth: 82,
      imageHeight: 108,
      imageFit: BoxFit.cover,
      imageScale: 1.0,
      textStart: 90,
      titleFontSize: 14.5,
      subtitleFontSize: 10.5,
      onTap: () => Get.toNamed(AppRoutes.offers),
    ),
    _PromoCardData(
      titleAr: 'عروض رمضان',
      titleEn: 'Ramadan offers',
      subtitleAr: '',
      subtitleEn: '',
      imageSource: AppImageAsset.ramadanLantern,
      fallbackAsset: AppImageAsset.ramadanLantern,
      backgroundColor: const Color(0xFF154F28),
      textColor: Colors.white,
      imageSide: _PromoImageSide.left,
      imageWidth: 66,
      imageHeight: 118,
      imageFit: BoxFit.contain,
      imageScale: 1.36,
      textStart: 92,
      titleFontSize: 14.5,
      subtitleFontSize: 11,
      onTap: () => Get.toNamed(AppRoutes.offers),
    ),
    _PromoCardData(
      titleAr: 'عروض المطاعم',
      titleEn: 'Restaurant offers',
      subtitleAr: '',
      subtitleEn: '',
      imageSource: AppImageAsset.burgerPromo,
      fallbackAsset: AppImageAsset.burgerPromo,
      backgroundColor: const Color(0xFFF2E7D9),
      textColor: const Color(0xFF1E1E1E),
      imageSide: _PromoImageSide.right,
      imageWidth: 74,
      imageHeight: 88,
      imageFit: BoxFit.cover,
      imageScale: 1.0,
      textStart: 14,
      titleFontSize: 14.2,
      subtitleFontSize: 11,
      onTap: () => Get.toNamed(AppRoutes.offers),
    ),
    _PromoCardData(
      titleAr: 'توصيل مجاني',
      titleEn: 'Free delivery',
      subtitleAr: 'لأول طلب',
      subtitleEn: 'First order',
      imageSource: AppImageAsset.driverPromo,
      fallbackAsset: AppImageAsset.driverPromo,
      backgroundColor: const Color(0xFFDDEBEA),
      textColor: const Color(0xFF1F1F1F),
      imageSide: _PromoImageSide.right,
      imageWidth: 72,
      imageHeight: 88,
      imageFit: BoxFit.contain,
      imageScale: 1.0,
      textStart: 14,
      titleFontSize: 14.2,
      subtitleFontSize: 10.5,
      onTap: () => Get.toNamed(AppRoutes.orderTracking),
    ),
  ];
}

class _CategoryShelf extends StatefulWidget {
  const _CategoryShelf({required this.controller, required this.categories});

  final HomeControllerImp controller;
  final List<AleppoFoodCategoryModel> categories;

  @override
  State<_CategoryShelf> createState() => _CategoryShelfState();
}

class _CategoryShelfState extends State<_CategoryShelf> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.controller.isArabic;
    final categories = widget.categories;
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final perPage = MediaQuery.of(context).size.width >= 430 ? 5 : 4;
    final pages = <List<AleppoFoodCategoryModel>>[];

    for (var index = 0; index < categories.length; index += perPage) {
      final end = index + perPage > categories.length
          ? categories.length
          : index + perPage;
      pages.add(categories.sublist(index, end));
    }

    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 104,
          child: PageView.builder(
            controller: _pageController,
            reverse: isArabic,
            itemCount: pages.length,
            onPageChanged: (index) {
              if (!mounted) {
                return;
              }
              setState(() {
                _pageIndex = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final page = pages[pageIndex];
              return Row(
                children: List.generate(page.length, (index) {
                  final category = page[index];
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: index == page.length - 1 ? 0 : 8,
                    ),
                    child: SizedBox(
                      width: 78,
                      child: _CategoryTile(
                        title: _localized(
                          category.nameAr,
                          category.nameEn,
                          isArabic,
                        ),
                        imageUrl: category.imageUrl,
                        categoryNameAr: category.nameAr,
                        categoryNameEn: category.nameEn,
                        fallbackIcon: _categoryIconFor(index),
                        onTap: () => widget.controller.openCategory(category),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _pageIndex ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _pageIndex
                      ? theme.colorScheme.primary
                      : palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.imageUrl,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.fallbackIcon,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final String categoryNameAr;
  final String categoryNameEn;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: palette.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.20),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: FallbackNetworkImage(
                  imageUrls: AppImageUrls.category(
                    imageUrl,
                    nameEn: categoryNameEn,
                    nameAr: categoryNameAr,
                  ),
                  label: title,
                  fit: BoxFit.contain,
                  errorWidget: Image.asset(
                    categoryFallbackAsset(
                      nameAr: categoryNameAr,
                      nameEn: categoryNameEn,
                      imageUrl: imageUrl,
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      fallbackIcon,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MostOrderedSection extends StatefulWidget {
  const _MostOrderedSection({
    required this.section,
    required this.isArabic,
    required this.onTapRestaurant,
    required this.onTapViewAll,
  });

  final AleppoRestaurantSectionModel section;
  final bool isArabic;
  final void Function(AleppoRestaurantModel restaurant) onTapRestaurant;
  final VoidCallback onTapViewAll;

  @override
  State<_MostOrderedSection> createState() => _MostOrderedSectionState();
}

class _MostOrderedSectionState extends State<_MostOrderedSection> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 5000,
      viewportFraction: 0.78,
    );
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final currentPage = _pageController.page?.round() ?? 5000;
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeInOutSine,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = widget.section.restaurants.take(4).toList();
    final isArabic = widget.isArabic;

    return Column(
      crossAxisAlignment:
          widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _SectionHeaderRow(
          title: isArabic ? 'الأكثر طلبًا' : 'Most ordered',
          actionLabel: isArabic ? 'عرض الكل' : 'View all',
          onTap: widget.onTapViewAll,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 248,
          child: PageView.builder(
            controller: _pageController,
            reverse: widget.isArabic,
            itemCount: restaurants.length * 10000,
            padEnds: true,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index % restaurants.length];
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _MostOrderedCard(
                    restaurant: restaurant,
                    isArabic: widget.isArabic,
                    onTap: () => widget.onTapRestaurant(restaurant),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MostOrderedCard extends StatelessWidget {
  const _MostOrderedCard({
    required this.restaurant,
    required this.isArabic,
    required this.onTap,
  });

  final AleppoRestaurantModel restaurant;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final title = restaurant.name.trim().isEmpty
        ? (isArabic ? 'مطعم' : 'Restaurant')
        : restaurant.name;
    final rating =
        restaurant.rating <= 0 ? '0.0' : restaurant.rating.toStringAsFixed(1);
    final distance = restaurant.distanceKm == null
        ? null
        : _formatDistance(restaurant.distanceKm!);
    final eta = _formatEta(
      restaurant.estimatedMinMinutes,
      restaurant.estimatedMaxMinutes,
      isArabic,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 266,
        constraints: const BoxConstraints(minHeight: 214),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 134,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: palette.surfaceSoft,
                        padding: const EdgeInsets.all(10),
                        child: restaurant.coverImageUrl.trim().isEmpty
                            ? Icon(
                                restaurant.vendorType == 'store'
                                    ? Icons.storefront_rounded
                                    : Icons.restaurant_menu_rounded,
                                color: palette.text,
                                size: 32,
                              )
                            : CachedNetworkImage(
                                imageUrl: restaurant.coverImageUrl,
                                fit: BoxFit.contain,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (_, __) => Container(
                                  color: palette.surfaceSoft,
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  restaurant.vendorType == 'store'
                                      ? Icons.storefront_rounded
                                      : Icons.restaurant_menu_rounded,
                                  color: palette.text,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (restaurant.isOpen)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isArabic ? 'مفتوح الآن' : 'Open now',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.5,
                                  ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    bottom: 10,
                    start: 10,
                    child: _MostOrderedRatingBadge(
                      icon: Icons.star_rounded,
                      label: rating,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.text,
                    fontSize: 14.5,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: 6),
            _RestaurantMetaSlider(
              isArabic: isArabic,
              height: 30,
              items: [
                _MetaSlideData(icon: Icons.star_rounded, label: rating),
                _MetaSlideData(icon: Icons.schedule_rounded, label: eta),
                _MetaSlideData(
                  icon: Icons.location_on_outlined,
                  label: distance ?? '-- km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MostOrderedRatingBadge extends StatelessWidget {
  const _MostOrderedRatingBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final orange = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: orange.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: orange),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: orange,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

enum _OpenNowFilter {
  nearest,
  freeDelivery,
  topRated,
  fastDelivery,
}

class _OpenNowSection extends StatefulWidget {
  const _OpenNowSection({
    required this.section,
    required this.isArabic,
    required this.isStore,
    required this.onTapRestaurant,
  });

  final AleppoRestaurantSectionModel section;
  final bool isArabic;
  final bool isStore;
  final void Function(AleppoRestaurantModel restaurant) onTapRestaurant;

  @override
  State<_OpenNowSection> createState() => _OpenNowSectionState();
}

class _OpenNowSectionState extends State<_OpenNowSection> {
  _OpenNowFilter _selectedFilter = _OpenNowFilter.nearest;

  List<AleppoRestaurantModel> _sortedRestaurants() {
    final restaurants = widget.section.restaurants
        .where((restaurant) => restaurant.isOpen)
        .toList();

    restaurants.sort((a, b) {
      switch (_selectedFilter) {
        case _OpenNowFilter.nearest:
          return _distanceValue(a).compareTo(_distanceValue(b));
        case _OpenNowFilter.freeDelivery:
          final aFree = a.deliveryFee <= 0;
          final bFree = b.deliveryFee <= 0;
          if (aFree != bFree) {
            return aFree ? -1 : 1;
          }
          final feeCompare = a.deliveryFee.compareTo(b.deliveryFee);
          if (feeCompare != 0) {
            return feeCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
        case _OpenNowFilter.topRated:
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) {
            return ratingCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
        case _OpenNowFilter.fastDelivery:
          final etaCompare =
              _deliveryTimeValue(a).compareTo(_deliveryTimeValue(b));
          if (etaCompare != 0) {
            return etaCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
      }
    });

    return restaurants;
  }

  double _distanceValue(AleppoRestaurantModel restaurant) {
    return restaurant.distanceKm ?? double.infinity;
  }

  int _deliveryTimeValue(AleppoRestaurantModel restaurant) {
    if (restaurant.estimatedMaxMinutes > 0) {
      return restaurant.estimatedMaxMinutes;
    }
    return restaurant.estimatedMinMinutes > 0
        ? restaurant.estimatedMinMinutes
        : 9999;
  }

  String _filterLabel(_OpenNowFilter filter) {
    switch (filter) {
      case _OpenNowFilter.nearest:
        return widget.isArabic ? 'الأقرب إليك' : 'Nearest';
      case _OpenNowFilter.freeDelivery:
        return widget.isArabic ? 'توصيل مجاني' : 'Free delivery';
      case _OpenNowFilter.topRated:
        return widget.isArabic ? 'الأعلى تقييماً' : 'Top rated';
      case _OpenNowFilter.fastDelivery:
        return widget.isArabic ? 'سريع التوصيل' : 'Fast delivery';
    }
  }

  void _selectFilter(_OpenNowFilter filter) {
    if (_selectedFilter == filter) {
      Get.snackbar(
        widget.isArabic ? 'المطاعم المفتوحة الآن' : 'Open now',
        widget.isArabic
            ? 'تم تفعيل ${_filterLabel(filter)}'
            : '${_filterLabel(filter)} is already active',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _selectedFilter = filter;
    });

    Get.snackbar(
      widget.isArabic ? 'المطاعم المفتوحة الآن' : 'Open now',
      widget.isArabic
          ? 'تم الفرز حسب ${_filterLabel(filter)}'
          : 'Sorted by ${_filterLabel(filter)}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showMoreFilters() {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic ? 'خيارات إضافية' : 'More filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: palette.text,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isArabic
                    ? 'اختر طريقة العرض التي تناسبك.'
                    : 'Choose the view that fits you best.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSoft,
                    ),
              ),
              const SizedBox(height: 14),
              _BottomFilterOption(
                label: _filterLabel(_OpenNowFilter.nearest),
                selected: _selectedFilter == _OpenNowFilter.nearest,
                onTap: () {
                  _selectFilter(_OpenNowFilter.nearest);
                  Get.back();
                },
              ),
              _BottomFilterOption(
                label: _filterLabel(_OpenNowFilter.freeDelivery),
                selected: _selectedFilter == _OpenNowFilter.freeDelivery,
                onTap: () {
                  _selectFilter(_OpenNowFilter.freeDelivery);
                  Get.back();
                },
              ),
              _BottomFilterOption(
                label: _filterLabel(_OpenNowFilter.topRated),
                selected: _selectedFilter == _OpenNowFilter.topRated,
                onTap: () {
                  _selectFilter(_OpenNowFilter.topRated);
                  Get.back();
                },
              ),
              _BottomFilterOption(
                label: _filterLabel(_OpenNowFilter.fastDelivery),
                selected: _selectedFilter == _OpenNowFilter.fastDelivery,
                onTap: () {
                  _selectFilter(_OpenNowFilter.fastDelivery);
                  Get.back();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _selectFilter(_OpenNowFilter.nearest);
                  Get.back();
                },
                child: Text(
                  widget.isArabic ? 'إعادة الضبط' : 'Reset to nearest',
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _sortedRestaurants().take(2).toList();

    return Column(
      crossAxisAlignment:
          widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _SectionHeaderRow(
          title: widget.isStore
              ? (widget.isArabic ? 'المتاجر المفتوحة الآن' : 'Stores open now')
              : (widget.isArabic
                  ? 'المطاعم المفتوحة الآن'
                  : 'Restaurants open now'),
          actionLabel: widget.isArabic ? 'عرض الكل' : 'View all',
          onTap: _showMoreFilters,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: widget.isArabic,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _FilterPill(
                  label: _filterLabel(_OpenNowFilter.nearest),
                  active: _selectedFilter == _OpenNowFilter.nearest,
                  onTap: () => _selectFilter(_OpenNowFilter.nearest),
                ),
                const SizedBox(width: 12),
                _FilterPill(
                  label: _filterLabel(_OpenNowFilter.freeDelivery),
                  active: _selectedFilter == _OpenNowFilter.freeDelivery,
                  onTap: () => _selectFilter(_OpenNowFilter.freeDelivery),
                ),
                const SizedBox(width: 12),
                _FilterPill(
                  label: _filterLabel(_OpenNowFilter.topRated),
                  active: _selectedFilter == _OpenNowFilter.topRated,
                  onTap: () => _selectFilter(_OpenNowFilter.topRated),
                ),
                const SizedBox(width: 12),
                _FilterPill(
                  label: _filterLabel(_OpenNowFilter.fastDelivery),
                  active: _selectedFilter == _OpenNowFilter.fastDelivery,
                  onTap: () => _selectFilter(_OpenNowFilter.fastDelivery),
                ),
                const SizedBox(width: 12),
                _FilterButton(
                  onTap: _showMoreFilters,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: restaurants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return _OpenNowCard(
              restaurant: restaurant,
              isArabic: widget.isArabic,
              onTap: () => widget.onTapRestaurant(restaurant),
            );
          },
        ),
      ],
    );
  }
}

class _BottomFilterOption extends StatelessWidget {
  const _BottomFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.20 : 0.12,
              )
            : palette.card,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(
            selected ? Icons.check_circle_rounded : Icons.tune_rounded,
            color: selected ? theme.colorScheme.primary : palette.textSoft,
          ),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          trailing: selected
              ? Icon(Icons.done_rounded, color: theme.colorScheme.primary)
              : null,
        ),
      ),
    );
  }
}

class _LegacyOpenNowCard extends StatelessWidget {
  const _LegacyOpenNowCard({
    required this.restaurant,
    required this.isArabic,
    required this.onTap,
  });

  final AleppoRestaurantModel restaurant;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final title = restaurant.name.trim().isEmpty
        ? (isArabic ? 'مطعم' : 'Restaurant')
        : restaurant.name;
    final rating =
        restaurant.rating <= 0 ? '0.0' : restaurant.rating.toStringAsFixed(1);
    final reviews = _compactCount(restaurant.reviewsCount);
    final distance = restaurant.distanceKm == null
        ? (isArabic ? '-- كم' : '-- km')
        : _formatDistance(restaurant.distanceKm!);
    final eta = _formatEta(
      restaurant.estimatedMinMinutes,
      restaurant.estimatedMaxMinutes,
      isArabic,
    );
    final discount = _localized(
      restaurant.discountLabelAr,
      restaurant.discountLabelEn,
      isArabic,
      fallbackAr: 'خصم خاص',
      fallbackEn: 'Special deal',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.08,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _DiscountBox(
                    title: discount,
                    subtitle: isArabic ? 'على أول طلب' : 'On first order',
                  ),
                  const SizedBox(height: 10),
                  _RestaurantMetaSlider(
                    isArabic: isArabic,
                    items: [
                      _MetaSlideData(
                        icon: Icons.star_rounded,
                        label: '$rating ($reviews)',
                      ),
                      _MetaSlideData(icon: Icons.schedule_rounded, label: eta),
                      _MetaSlideData(
                        icon: Icons.location_on_outlined,
                        label: distance,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RestaurantImage(
              imageUrl: restaurant.coverImageUrl,
              isArabic: isArabic,
              open: restaurant.isOpen,
              showAvailabilityLabel: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyOpenNowCardV2 extends StatelessWidget {
  const _LegacyOpenNowCardV2({
    required this.restaurant,
    required this.isArabic,
    required this.onTap,
  });

  final AleppoRestaurantModel restaurant;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final title = restaurant.name.trim().isEmpty
        ? (isArabic ? 'مطعم' : 'Restaurant')
        : restaurant.name;
    final isStore = restaurant.vendorType.toLowerCase() == 'store';
    final entityAr = isStore ? 'المتجر' : 'المطعم';
    final entityEn = isStore ? 'Store' : 'Restaurant';
    final category = _localized(
      restaurant.taglineAr,
      restaurant.taglineEn,
      isArabic,
    );
    final rating =
        restaurant.rating <= 0 ? '0.0' : restaurant.rating.toStringAsFixed(1);
    final reviews = _compactCount(restaurant.reviewsCount);
    final distance = restaurant.distanceKm == null
        ? (isArabic ? '-- كم' : '-- km')
        : '${restaurant.distanceKm!.toStringAsFixed(restaurant.distanceKm! % 1 == 0 ? 0 : 1)} ${isArabic ? 'كم' : 'km'}';
    final minMinutes = restaurant.estimatedMinMinutes <= 0
        ? 0
        : restaurant.estimatedMinMinutes;
    final maxMinutes = restaurant.estimatedMaxMinutes <= 0
        ? minMinutes
        : restaurant.estimatedMaxMinutes;
    final eta = isArabic
        ? '$minMinutes-$maxMinutes دقيقة'
        : '$minMinutes-$maxMinutes min';
    final discount = _localized(
      restaurant.discountLabelAr,
      restaurant.discountLabelEn,
      isArabic,
      fallbackAr: 'خصم خاص',
      fallbackEn: 'Special deal',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final logoSize = constraints.maxWidth < 380 ? 108.0 : 124.0;
          return Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(24),
                topEnd: const Radius.circular(24),
                bottomStart: const Radius.circular(24),
                bottomEnd: const Radius.circular(24),
              ),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection:
                            isArabic ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CircleIconButton(
                            icon: Icons.favorite_border_rounded,
                            iconColor: palette.text,
                            backgroundColor: palette.surfaceSoft,
                          ),
                        ],
                      ),
                      if (category.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        textDirection:
                            isArabic ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF3A51B),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rating ($reviews)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: restaurant.isOpen
                                  ? palette.surfaceMint
                                  : palette.surfacePale,
                              borderRadius: BorderRadiusDirectional.only(
                                topStart: const Radius.circular(999),
                                topEnd: const Radius.circular(999),
                                bottomStart: const Radius.circular(999),
                                bottomEnd: const Radius.circular(999),
                              ),
                            ),
                            child: Text(
                              restaurant.isOpen
                                  ? (isArabic ? 'مفتوح الآن' : 'Open now')
                                  : (isArabic ? 'مغلق الآن' : 'Closed now'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: restaurant.isOpen
                                    ? const Color(0xFF1E7A44)
                                    : palette.textSoft,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _DiscountBox(
                        title: discount,
                        subtitle: isArabic ? 'على أول طلب' : 'On first order',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _MiniMeta(
                            icon: Icons.location_on_outlined,
                            label: distance,
                          ),
                          _MiniMeta(
                            icon: Icons.schedule_rounded,
                            label: eta,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusDirectional.only(
                                topStart: const Radius.circular(12),
                                topEnd: const Radius.circular(12),
                                bottomStart: const Radius.circular(12),
                                bottomEnd: const Radius.circular(12),
                              ),
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          child: Text(
                            isArabic ? 'فتح $entityAr' : 'Open $entityEn',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadiusDirectional.only(
                            topStart: const Radius.circular(20),
                            topEnd: const Radius.circular(20),
                            bottomStart: const Radius.circular(20),
                            bottomEnd: const Radius.circular(20),
                          ),
                          child: restaurant.coverImageUrl.trim().isEmpty
                              ? Container(
                                  color: palette.surfaceSoft,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: palette.text,
                                    size: 36,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: restaurant.coverImageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholder: (_, __) => Container(
                                    color: palette.surfaceSoft,
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: palette.surfaceSoft,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: palette.text,
                                      size: 36,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 8,
                        start: 8,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadiusDirectional.only(
                              topStart: const Radius.circular(999),
                              topEnd: const Radius.circular(999),
                              bottomStart: const Radius.circular(999),
                              bottomEnd: const Radius.circular(999),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'مفتوح' : 'Open',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OpenNowCard extends StatelessWidget {
  const _OpenNowCard({
    required this.restaurant,
    required this.isArabic,
    required this.onTap,
  });

  final AleppoRestaurantModel restaurant;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final title = restaurant.name.trim().isEmpty
        ? (isArabic ? 'مطعم' : 'Restaurant')
        : restaurant.name;
    final category = _localized(
      restaurant.taglineAr,
      restaurant.taglineEn,
      isArabic,
      fallbackAr: 'مطعم',
      fallbackEn: 'Restaurant',
    );
    final rating =
        restaurant.rating <= 0 ? '0.0' : restaurant.rating.toStringAsFixed(1);
    final reviews = _compactCount(restaurant.reviewsCount);
    final distance = restaurant.distanceKm == null
        ? (isArabic ? '-- كم' : '-- km')
        : '${restaurant.distanceKm!.toStringAsFixed(restaurant.distanceKm! % 1 == 0 ? 0 : 1)} ${isArabic ? 'كم' : 'km'}';
    final minMinutes = restaurant.estimatedMinMinutes <= 0
        ? 0
        : restaurant.estimatedMinMinutes;
    final maxMinutes = restaurant.estimatedMaxMinutes <= 0
        ? minMinutes
        : restaurant.estimatedMaxMinutes;
    final eta = isArabic
        ? '$minMinutes-$maxMinutes دقيقة'
        : '$minMinutes-$maxMinutes min';
    final deal = _localized(
      restaurant.discountLabelAr,
      restaurant.discountLabelEn,
      isArabic,
      fallbackAr: 'خصم خاص',
      fallbackEn: 'Special deal',
    );
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final compact = MediaQuery.sizeOf(context).width < 500;
    final logoColumnWidth = compact ? 94.0 : 132.0;
    final logoSize = compact ? 82.0 : 118.0;
    final dealWidth = compact ? 82.0 : 104.0;
    final columnGap = compact ? 6.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(24),
              topEnd: const Radius.circular(24),
              bottomStart: const Radius.circular(24),
              bottomEnd: const Radius.circular(24),
            ),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                textDirection: direction,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: logoColumnWidth,
                    child: Column(
                      children: [
                        SizedBox(
                          width: logoSize,
                          height: compact ? 86 : 112,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: restaurant.coverImageUrl.trim().isEmpty
                                      ? Container(
                                          color: palette.surfaceSoft,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.restaurant_menu_rounded,
                                            color: palette.text,
                                            size: 34,
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: restaurant.coverImageUrl,
                                          fit: BoxFit.contain,
                                          fadeInDuration: Duration.zero,
                                          fadeOutDuration: Duration.zero,
                                          placeholder: (_, __) => Container(
                                            color: palette.surfaceSoft,
                                            alignment: Alignment.center,
                                            child: const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            color: palette.surfaceSoft,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.restaurant_menu_rounded,
                                              color: palette.text,
                                              size: 34,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              PositionedDirectional(
                                top: 5,
                                end: 5,
                                child: _CircleIconButton(
                                  icon: Icons.favorite_border_rounded,
                                  iconColor: palette.text,
                                  backgroundColor: palette.card,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          width: logoColumnWidth,
                          height: 34,
                          child: FilledButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.chevron_right_rounded,
                                size: 16),
                            label: Text(
                              isArabic ? 'فتح المطعم' : 'Open now',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: columnGap),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 18 : 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            textDirection: direction,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF3A51B),
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$rating ($reviews)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.textSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            textDirection: direction,
                            children: [
                              Icon(
                                Icons.circle,
                                color: restaurant.isOpen
                                    ? theme.colorScheme.primary
                                    : palette.textSoft,
                                size: 9,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                restaurant.isOpen
                                    ? (isArabic ? 'مفتوح الآن' : 'Open now')
                                    : (isArabic ? 'مغلق الآن' : 'Closed now'),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: restaurant.isOpen
                                      ? theme.colorScheme.primary
                                      : palette.textSoft,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: columnGap),
                  SizedBox(
                    width: dealWidth,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 94),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 9,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMint,
                        borderRadius: BorderRadiusDirectional.only(
                          topStart: const Radius.circular(20),
                          topEnd: const Radius.circular(20),
                          bottomStart: const Radius.circular(20),
                          bottomEnd: const Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_rounded,
                            color: theme.colorScheme.primary,
                            size: 21,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            deal,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic ? 'على أول طلب' : 'On first order',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.textSoft,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Container(
                height: 42,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: palette.surfacePale,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(13),
                    topEnd: const Radius.circular(13),
                    bottomStart: const Radius.circular(13),
                    bottomEnd: const Radius.circular(13),
                  ),
                ),
                child: Row(
                  textDirection: direction,
                  children: [
                    Expanded(
                      child: _OpenNowMeta(
                        icon: Icons.delivery_dining_rounded,
                        label: isArabic ? 'توصيل مجاني' : 'Free delivery',
                        palette: palette,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      indent: 10,
                      endIndent: 10,
                      color: palette.border,
                    ),
                    Expanded(
                      child: _OpenNowMeta(
                        icon: Icons.schedule_rounded,
                        label: eta,
                        palette: palette,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      indent: 10,
                      endIndent: 10,
                      color: palette.border,
                    ),
                    Expanded(
                      child: _OpenNowMeta(
                        icon: Icons.location_on_outlined,
                        label: distance,
                        palette: palette,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenNowMeta extends StatelessWidget {
  const _OpenNowMeta({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _ThemeTokens palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: palette.textSoft, size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _ProductSectionBlock extends StatefulWidget {
  const _ProductSectionBlock({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isArabic,
    required this.onTapItem,
  });

  final String title;
  final String subtitle;
  final List<ItemsModel> items;
  final bool isArabic;
  final void Function(ItemsModel item) onTapItem;

  @override
  State<_ProductSectionBlock> createState() => _ProductSectionBlockState();
}

class _ProductSectionBlockState extends State<_ProductSectionBlock> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    final enableAutoScroll = widget.items.length > 3;
    _pageController = PageController(
      initialPage: enableAutoScroll ? 5000 : 0,
      viewportFraction: 0.78,
    );
    if (enableAutoScroll) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final currentPage = _pageController.page?.round() ?? 5000;
        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 950),
          curve: Curves.easeInOutSine,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final cards = widget.items.take(6).toList();
    final isArabic = widget.isArabic;

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSoft,
                height: 1.3,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 252,
          child: PageView.builder(
            controller: _pageController,
            reverse: isArabic,
            itemCount: cards.length > 3 ? cards.length * 10000 : cards.length,
            padEnds: true,
            itemBuilder: (context, index) {
              final item = cards[index % cards.length];
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _ProductCard(
                    item: item,
                    isArabic: isArabic,
                    onTap: () => widget.onTapItem(item),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  final ItemsModel item;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final title = _localized(
      item.itemsNameAr ?? '',
      item.itemsNameEn ?? '',
      isArabic,
      fallbackAr: 'منتج',
      fallbackEn: 'Item',
    );
    final storeName = _localized(
      item.storeName ?? '',
      item.vendorName ?? '',
      isArabic,
      fallbackAr: 'المتجر',
      fallbackEn: 'Store',
    );
    final currentPrice = item.itemsPriceDiscount;
    final originalPrice = double.tryParse(item.itemsPrice ?? '') ?? 0;
    final discount = int.tryParse(item.itemsDiscount ?? '0') ?? 0;
    final rating = item.averageRatingValue <= 0
        ? '0.0'
        : item.averageRatingValue.toStringAsFixed(1);
    final reviewCount = _compactCount(item.ratingsCountValue);

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 266,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Container(
                          color: palette.surfaceSoft,
                          padding: const EdgeInsets.all(10),
                          child: FallbackNetworkImage(
                            imageUrls: _productImageUrls(item),
                            label: title,
                            fit: BoxFit.contain,
                            placeholder: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF6F1E8),
                                    Color(0xFFFFE8DC),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF6F1E8),
                                    Color(0xFFFFE8DC),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.fastfood_rounded,
                                color: palette.textSoft,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.18),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    if (discount > 0)
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: _ProductAccentBadge(
                          icon: Icons.local_offer_rounded,
                          label: '-$discount%',
                        ),
                      )
                    else if (item.isTopRatedValue)
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: _ProductAccentBadge(
                          icon: Icons.star_rounded,
                          label: isArabic ? 'الأفضل' : 'Top',
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                  height: 1.08,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textSoft,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isArabic
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatProductPrice(
                                    currentPrice,
                                    isArabic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isArabic
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                      ),
                                ),
                                if (discount > 0 &&
                                    originalPrice > currentPrice)
                                  Text(
                                    _formatProductOriginalPrice(
                                      originalPrice,
                                      isArabic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: isArabic
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: palette.textSoft,
                                          fontSize: 10,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ProductRatingBadge(
                            icon: Icons.star_rounded,
                            label: '$rating ($reviewCount)',
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
      ),
    );
  }
}

class _ProductAccentBadge extends StatelessWidget {
  const _ProductAccentBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final orange = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProductRatingBadge extends StatelessWidget {
  const _ProductRatingBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final orange = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: orange.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: orange,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.imageUrl,
    required this.isArabic,
    required this.open,
    this.showAvailabilityLabel = false,
  });

  final String imageUrl;
  final bool isArabic;
  final bool open;
  final bool showAvailabilityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageUrl.trim().isEmpty
                ? Container(
                    color: palette.surfaceSoft,
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: palette.text,
                      size: 34,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 116,
                    height: 116,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) => Container(
                      color: palette.surfaceSoft,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: palette.surfaceSoft,
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: palette.text,
                        size: 34,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _CircleIconButton(
              icon: Icons.favorite_border_rounded,
              iconColor: palette.text,
              backgroundColor: palette.card,
            ),
          ),
          if (showAvailabilityLabel || open)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: open
                      ? const Color(0xFF1E7A44).withValues(alpha: 0.92)
                      : const Color(0xFF7A3C3C).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  open
                      ? (isArabic ? 'مفتوح الآن' : 'Open now')
                      : (isArabic ? 'مغلق الآن' : 'Closed now'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscountBox extends StatelessWidget {
  const _DiscountBox({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceMint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1E7A44),
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textSoft,
                  fontSize: 10,
                  height: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfacePale,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.textSoft),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetaSlideData {
  const _MetaSlideData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _RestaurantMetaSlider extends StatefulWidget {
  const _RestaurantMetaSlider({
    required this.items,
    required this.isArabic,
    this.height = 34,
  });

  final List<_MetaSlideData> items;
  final bool isArabic;
  final double height;

  @override
  State<_RestaurantMetaSlider> createState() => _RestaurantMetaSliderState();
}

class _RestaurantMetaSliderState extends State<_RestaurantMetaSlider> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _autoSlide());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _autoSlide() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max <= 2) return;

    final nextOffset = _forward ? max : 0.0;
    _forward = !_forward;
    _controller.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        reverse: widget.isArabic,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < widget.items.length; index++) ...[
              _MiniMeta(
                icon: widget.items[index].icon,
                label: widget.items[index].label,
              ),
              if (index != widget.items.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 16,
        color: iconColor,
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.tune_rounded,
            size: 19,
            color: palette.text,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Material(
      color: active ? theme.colorScheme.primary : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: active ? theme.colorScheme.primary : palette.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active ? Colors.white : palette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.name,
    required this.onTap,
    this.size = 52,
  });

  final String? imageUrl;
  final String name;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Semantics(
        label: name,
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surfacePale,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: imageUrl == null
              ? Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: palette.textSoft,
                    size: size * 0.52,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, __) => Center(
                    child: SizedBox(
                      width: size * 0.36,
                      height: size * 0.36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.textSoft,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: palette.textSoft,
                      size: size * 0.52,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.count,
    required this.onTap,
    this.size = 52,
  });

  final int count;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: palette.card,
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: palette.text,
                size: size * 0.5,
              ),
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.card, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllRestaurantsPage extends StatefulWidget {
  const _AllRestaurantsPage({
    required this.restaurants,
    required this.isArabic,
    required this.isStore,
    required this.onTapRestaurant,
  });

  final List<AleppoRestaurantModel> restaurants;
  final bool isArabic;
  final bool isStore;
  final void Function(AleppoRestaurantModel restaurant) onTapRestaurant;

  @override
  State<_AllRestaurantsPage> createState() => _AllRestaurantsPageState();
}

enum _RestaurantBrowseFilter {
  all,
  openNow,
  topRated,
  fastDelivery,
  nearest,
}

class _AllRestaurantsPageState extends State<_AllRestaurantsPage> {
  final TextEditingController _searchController = TextEditingController();
  _RestaurantBrowseFilter _selectedFilter = _RestaurantBrowseFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _distanceValue(AleppoRestaurantModel restaurant) {
    return restaurant.distanceKm ?? double.infinity;
  }

  int _deliveryTimeValue(AleppoRestaurantModel restaurant) {
    if (restaurant.estimatedMaxMinutes > 0) {
      return restaurant.estimatedMaxMinutes;
    }
    return restaurant.estimatedMinMinutes > 0
        ? restaurant.estimatedMinMinutes
        : 9999;
  }

  List<AleppoRestaurantModel> _deduplicatedRestaurants() {
    final seenIds = <int>{};
    final unique = <AleppoRestaurantModel>[];
    for (final restaurant in widget.restaurants) {
      if (seenIds.add(restaurant.id)) {
        unique.add(restaurant);
      }
    }
    return unique;
  }

  String _searchableText(AleppoRestaurantModel restaurant) {
    return <String>[
      restaurant.name,
      restaurant.slug,
      restaurant.taglineAr,
      restaurant.taglineEn,
      restaurant.discountLabelAr,
      restaurant.discountLabelEn,
      ...restaurant.badgesAr,
      ...restaurant.badgesEn,
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  List<AleppoRestaurantModel> _filteredRestaurants() {
    final query = _searchController.text.trim().toLowerCase();
    var items = _deduplicatedRestaurants();

    if (query.isNotEmpty) {
      items = items
          .where((restaurant) => _searchableText(restaurant).contains(query))
          .toList();
    }

    switch (_selectedFilter) {
      case _RestaurantBrowseFilter.all:
        items.sort((a, b) {
          final openCompare = (b.isOpen ? 1 : 0).compareTo(a.isOpen ? 1 : 0);
          if (openCompare != 0) {
            return openCompare;
          }
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) {
            return ratingCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
        });
        break;
      case _RestaurantBrowseFilter.openNow:
        items = items.where((restaurant) => restaurant.isOpen).toList();
        items.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) {
            return ratingCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
        });
        break;
      case _RestaurantBrowseFilter.topRated:
        items.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) {
            return ratingCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
        });
        break;
      case _RestaurantBrowseFilter.fastDelivery:
        items.sort((a, b) {
          final etaCompare =
              _deliveryTimeValue(a).compareTo(_deliveryTimeValue(b));
          if (etaCompare != 0) {
            return etaCompare;
          }
          return _distanceValue(a).compareTo(_distanceValue(b));
        });
        break;
      case _RestaurantBrowseFilter.nearest:
        items.sort((a, b) => _distanceValue(a).compareTo(_distanceValue(b)));
        break;
    }

    return items;
  }

  String _filterLabel(_RestaurantBrowseFilter filter) {
    switch (filter) {
      case _RestaurantBrowseFilter.all:
        return widget.isArabic ? 'الكل' : 'All';
      case _RestaurantBrowseFilter.openNow:
        return widget.isArabic ? 'مفتوحة الآن' : 'Open now';
      case _RestaurantBrowseFilter.topRated:
        return widget.isArabic ? 'الأعلى تقييمًا' : 'Top rated';
      case _RestaurantBrowseFilter.fastDelivery:
        return widget.isArabic ? 'الأسرع توصيلًا' : 'Fast delivery';
      case _RestaurantBrowseFilter.nearest:
        return widget.isArabic ? 'الأقرب إليك' : 'Nearest';
    }
  }

  IconData _filterIcon(_RestaurantBrowseFilter filter) {
    switch (filter) {
      case _RestaurantBrowseFilter.all:
        return Icons.grid_view_rounded;
      case _RestaurantBrowseFilter.openNow:
        return Icons.storefront_rounded;
      case _RestaurantBrowseFilter.topRated:
        return Icons.star_rounded;
      case _RestaurantBrowseFilter.fastDelivery:
        return Icons.local_shipping_rounded;
      case _RestaurantBrowseFilter.nearest:
        return Icons.location_on_rounded;
    }
  }

  Widget _buildHeader(BuildContext context, _ThemeTokens palette) {
    final isArabic = widget.isArabic;
    final title = widget.isStore
        ? (isArabic ? 'كل المتاجر' : 'All stores')
        : (isArabic ? 'كل المطاعم' : 'All restaurants');
    final subtitle = isArabic
        ? 'استعرض المطاعم المتاحة وابدأ من المكان الذي يناسبك.'
        : (widget.isStore
            ? 'Browse every available store in one polished view.'
            : 'Browse every available restaurant in one polished view.');
    final count = _filteredRestaurants().length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            palette.surfaceMint,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSoft,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              isArabic ? '$count مطعم' : '$count stores',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, _ThemeTokens palette) {
    final isArabic = widget.isArabic;
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        hintText: isArabic
            ? 'ابحث عن مطعم أو اسم طبق...'
            : 'Search a restaurant or dish...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, _ThemeTokens palette) {
    const filters = _RestaurantBrowseFilter.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: widget.isArabic,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            _BrowseFilterChip(
              label: _filterLabel(filters[index]),
              icon: _filterIcon(filters[index]),
              active: _selectedFilter == filters[index],
              onTap: () {
                setState(() {
                  _selectedFilter = filters[index];
                });
              },
            ),
            if (index != filters.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ThemeTokens(Theme.of(context));
    final restaurants = _filteredRestaurants();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildHeader(context, palette),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _buildSearch(context, palette),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _buildFilters(context, palette),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isArabic
                            ? 'النتائج المتاحة'
                            : (widget.isStore
                                ? 'Available stores'
                                : 'Available restaurants'),
                        textAlign:
                            widget.isArabic ? TextAlign.right : TextAlign.left,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                    Text(
                      widget.isArabic
                          ? '${restaurants.length} نتيجة'
                          : '${restaurants.length} results',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: palette.textSoft,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (restaurants.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: palette.textSoft,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isArabic
                              ? 'لا توجد مطاعم مطابقة الآن'
                              : 'No matching restaurants found',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.isArabic
                              ? 'جرّب فلترًا مختلفًا أو امسح البحث.'
                              : 'Try another filter or clear the search.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: palette.textSoft,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final restaurant = restaurants[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == restaurants.length - 1 ? 0 : 14,
                        ),
                        child: _RestaurantBrowseCard(
                          restaurant: restaurant,
                          isArabic: widget.isArabic,
                          onTap: () => widget.onTapRestaurant(restaurant),
                        ),
                      );
                    },
                    childCount: restaurants.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrowseFilterChip extends StatelessWidget {
  const _BrowseFilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Material(
      color: active ? theme.colorScheme.primary : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: active ? theme.colorScheme.primary : palette.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : palette.textSoft,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? Colors.white : palette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantBrowseCard extends StatelessWidget {
  const _RestaurantBrowseCard({
    required this.restaurant,
    required this.isArabic,
    required this.onTap,
  });

  final AleppoRestaurantModel restaurant;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final title = restaurant.name.trim().isEmpty
        ? (isArabic ? 'مطعم' : 'Restaurant')
        : restaurant.name;
    final tagline = _localized(
      restaurant.taglineAr,
      restaurant.taglineEn,
      isArabic,
    );
    final rating =
        restaurant.rating <= 0 ? '0.0' : restaurant.rating.toStringAsFixed(1);
    final reviews = _compactCount(restaurant.reviewsCount);
    final distance = restaurant.distanceKm == null
        ? '-- km'
        : _formatDistance(restaurant.distanceKm!);
    final eta = _formatEta(
      restaurant.estimatedMinMinutes,
      restaurant.estimatedMaxMinutes,
      isArabic,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RestaurantImage(
              imageUrl: restaurant.coverImageUrl,
              isArabic: isArabic,
              open: restaurant.isOpen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.08,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (tagline.trim().isNotEmpty)
                    Text(
                      tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textSoft,
                            height: 1.2,
                            fontSize: 10.5,
                          ),
                    ),
                  const SizedBox(height: 8),
                  _RestaurantMetaSlider(
                    isArabic: isArabic,
                    items: [
                      _MetaSlideData(
                        icon: Icons.star_rounded,
                        label: '$rating ($reviews)',
                      ),
                      _MetaSlideData(icon: Icons.schedule_rounded, label: eta),
                      _MetaSlideData(
                        icon: Icons.location_on_outlined,
                        label: distance,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isArabic
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: palette.textSoft,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoImage extends StatelessWidget {
  const _PromoImage({
    required this.source,
    required this.fallbackAsset,
    required this.fit,
  });

  final String source;
  final String fallbackAsset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = source.trim();
    if (value.isNotEmpty) {
      if (value.startsWith('assets/')) {
        return Image.asset(
          value,
          fit: fit,
          errorBuilder: (_, __, ___) => Image.asset(
            fallbackAsset,
            fit: fit,
          ),
        );
      }
      return CachedNetworkImage(
        imageUrl: AppLink.normalizeUrl(value),
        fit: fit,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => Image.asset(
          fallbackAsset,
          fit: fit,
        ),
        errorWidget: (_, __, ___) => Image.asset(
          fallbackAsset,
          fit: fit,
        ),
      );
    }
    return Image.asset(
      fallbackAsset,
      fit: fit,
    );
  }
}

enum _PromoImageSide { left, right }

IconData _categoryIconFor(int index) {
  const icons = <IconData>[
    Icons.local_pizza_rounded,
    Icons.fastfood_rounded,
    Icons.ramen_dining_rounded,
    Icons.coffee_rounded,
    Icons.cake_rounded,
    Icons.lunch_dining_rounded,
    Icons.emoji_food_beverage_rounded,
    Icons.kebab_dining_rounded,
  ];
  return icons[index % icons.length];
}

AleppoRestaurantSectionModel? _sectionByKey(
  List<AleppoRestaurantSectionModel> sections,
  String key,
) {
  for (final section in sections) {
    if (section.key == key) {
      return section;
    }
  }
  return null;
}

AleppoProductSectionModel? _productSectionByKey(
  List<AleppoProductSectionModel> sections,
  String key,
) {
  for (final section in sections) {
    if (section.key == key) {
      return section;
    }
  }
  return null;
}

List<AleppoRestaurantModel> _collectAllRestaurants(
  List<AleppoRestaurantSectionModel> sections,
) {
  final seenIds = <int>{};
  final restaurants = <AleppoRestaurantModel>[];

  for (final section in sections) {
    for (final restaurant in section.restaurants) {
      if (seenIds.add(restaurant.id)) {
        restaurants.add(restaurant);
      }
    }
  }

  return restaurants;
}

List<String> _productImageUrls(ItemsModel item) {
  final candidates = <String>{};
  for (final path in AppImageUrls.item(item.itemsImage)) {
    candidates.add(path);
  }
  for (final path in item.galleryImagePaths) {
    for (final candidate in AppImageUrls.item(path)) {
      candidates.add(candidate);
    }
  }
  return candidates.toList();
}

String _formatProductPrice(double value, bool isArabic) {
  final formatted = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  return isArabic ? '$formatted ${AppCurrency.symbol}' : '${AppCurrency.code} $formatted';
}

String _formatProductOriginalPrice(double value, bool isArabic) {
  final formatted = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  return isArabic ? '$formatted ${AppCurrency.symbol}' : '${AppCurrency.code} $formatted';
}

String _localized(
  String ar,
  String en,
  bool isArabic, {
  String fallbackAr = '',
  String fallbackEn = '',
}) {
  final primary = isArabic ? ar.trim() : en.trim();
  final secondary = isArabic ? en.trim() : ar.trim();
  if (primary.isNotEmpty) {
    return primary;
  }
  if (secondary.isNotEmpty) {
    return secondary;
  }
  return isArabic ? fallbackAr : fallbackEn;
}

String _formatDistance(double value) {
  final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  return '$text كم';
}

String _formatEta(int minMinutes, int maxMinutes, bool isArabic) {
  final minText = minMinutes <= 0 ? '0' : '$minMinutes';
  final maxText = maxMinutes <= 0 ? minText : '$maxMinutes';
  return isArabic ? '$minText-$maxText د' : '$minText-$maxText min';
}

String _compactCount(int value) {
  if (value < 1000) {
    return '$value';
  }
  final thousands = value / 1000;
  if (thousands >= 10) {
    return '${thousands.toStringAsFixed(0)}K';
  }
  return '${thousands.toStringAsFixed(1)}K';
}
