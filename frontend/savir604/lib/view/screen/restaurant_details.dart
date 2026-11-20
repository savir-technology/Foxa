import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:tks/controler/restaurants/restaurant_details_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/route_observer.dart';
import 'package:tks/data/datasource/model/restaurant_details_model.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class _ThemeTokens {
  const _ThemeTokens(this.theme);

  final ThemeData theme;

  bool get isDark => theme.brightness == Brightness.dark;
  Color get card => theme.cardColor;
  Color get border =>
      theme.dividerColor.withValues(alpha: isDark ? 0.88 : 0.72);
  Color get text => theme.colorScheme.onSurface;
  Color get textSoft =>
      theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.62);
  Color get surfaceSoft =>
      isDark ? const Color(0xFF1A201C) : const Color(0xFFF4F7F4);
  Color get surfaceMint =>
      isDark ? const Color(0xFF203027) : const Color(0xFFEAF5EE);
  Color get surfaceWarm =>
      isDark ? const Color(0xFF232A25) : const Color(0xFFF8F5F0);
  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.24 : 0.06);
}

class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({super.key});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen>
    with RouteAware {
  late final RestaurantDetailsController controller;
  final ScrollController _scrollController = ScrollController();
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<RestaurantDetailsController>()
        ? Get.find<RestaurantDetailsController>()
        : Get.put(RestaurantDetailsController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.fetchDetails(forceRefresh: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (!mounted) {
      return;
    }

    controller.fetchDetails(
      restaurantId: controller.loadedRestaurantId,
      forceRefresh: true,
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final theme = Theme.of(context);
    final overlayStyle = SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );

    return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          extendBody: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: GetBuilder<RestaurantDetailsController>(
              builder: (controller) {
                final restaurant = controller.details?.restaurant;
                final hasData = controller.details != null;

                if (controller.statusRequest == StatusRequest.loading &&
                    !hasData) {
                  return _RestaurantStatusState(
                    isArabic: isArabic,
                    isStore: controller.requestedStore,
                    kind: _RestaurantStatusKind.loading,
                    onRetry: controller.retryFetch,
                  );
                }

                if (restaurant == null) {
                  return _RestaurantStatusState(
                    isArabic: isArabic,
                    isStore: controller.requestedStore,
                    kind: _statusKindFromRequest(controller.statusRequest),
                    onRetry: controller.retryFetch,
                  );
                }

                final featuredItems =
                    controller.details?.menuItems.take(4).toList() ??
                        const <RestaurantMenuItemModel>[];
                final visibleItems = controller.visibleItems;
                final discountedCount =
                    visibleItems.where(_hasDiscountedPrice).length;

                return RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: controller.retryFetch,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _RestaurantHeroSection(
                        restaurant: restaurant,
                        isArabic: isArabic,
                        onBack: Get.back,
                        onShare: () => _showShareSheet(restaurant, isArabic),
                        onMore: () =>
                            _showMoreSheet(context, restaurant, isArabic),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: _RestaurantMainSheet(
                          controller: controller,
                          restaurant: restaurant,
                          featuredItems: featuredItems,
                          visibleItems: visibleItems,
                          discountedCount: discountedCount,
                          isArabic: isArabic,
                          onReviewsTap: () => Get.toNamed(
                            AppRoutes.ratingPage,
                            arguments: {
                              'vendor_id': restaurant.id,
                              'restaurant_name': restaurant.name,
                              'restaurant_logo': restaurant.logoUrl,
                              'restaurant_cover': restaurant.coverImageUrl,
                              'average_rating': restaurant.rating,
                              'reviews_count': restaurant.reviewsCount,
                            },
                          ),
                          onPromoTap: () =>
                              _showMoreSheet(context, restaurant, isArabic),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _RestaurantStatusKind { loading, offline, server, empty }

_RestaurantStatusKind _statusKindFromRequest(StatusRequest request) {
  switch (request) {
    case StatusRequest.offlinefailure:
      return _RestaurantStatusKind.offline;
    case StatusRequest.serverfailure:
    case StatusRequest.serverException:
      return _RestaurantStatusKind.server;
    case StatusRequest.failure:
    case StatusRequest.none:
    case StatusRequest.success:
      return _RestaurantStatusKind.empty;
    case StatusRequest.loading:
      return _RestaurantStatusKind.loading;
  }
}

class _RestaurantStatusState extends StatelessWidget {
  const _RestaurantStatusState({
    required this.isArabic,
    required this.isStore,
    required this.kind,
    required this.onRetry,
  });

  final bool isArabic;
  final bool isStore;
  final _RestaurantStatusKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entityAr = isStore
        ? '\u0627\u0644\u0645\u062a\u062c\u0631'
        : '\u0627\u0644\u0645\u0637\u0639\u0645';
    final entityEn = isStore ? 'store' : 'restaurant';
    final accent = switch (kind) {
      _RestaurantStatusKind.loading => const Color(0xFF1B7A3A),
      _RestaurantStatusKind.offline => const Color(0xFFFF6500),
      _RestaurantStatusKind.server => const Color(0xFFC2410C),
      _RestaurantStatusKind.empty => const Color(0xFF6B7280),
    };

    final title = switch (kind) {
      _RestaurantStatusKind.loading =>
        isArabic ? 'جارٍ تحميل بيانات $entityAr' : 'Loading $entityEn data',
      _RestaurantStatusKind.offline =>
        isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection',
      _RestaurantStatusKind.server =>
        isArabic ? 'تعذر تحميل البيانات الآن' : 'Unable to load data now',
      _RestaurantStatusKind.empty =>
        isArabic ? 'تعذر عرض تفاصيل $entityAr' : 'Unable to show $entityEn',
    };

    final message = switch (kind) {
      _RestaurantStatusKind.loading => isArabic
          ? 'لحظات بسيطة ونجهز لك الصفحة الكاملة.'
          : 'Please wait while we prepare the page.',
      _RestaurantStatusKind.offline => isArabic
          ? 'تحقق من الاتصال ثم حاول مرة أخرى.'
          : 'Please check your connection and try again.',
      _RestaurantStatusKind.server => isArabic
          ? 'هناك مشكلة مؤقتة في جلب البيانات.'
          : 'There is a temporary problem fetching the data.',
      _RestaurantStatusKind.empty => isArabic
          ? 'قد يكون الرابط غير مكتمل أو انتهت الجلسة. أعد المحاولة.'
          : 'The link may be incomplete or the session expired. Try again.',
    };

    final icon = switch (kind) {
      _RestaurantStatusKind.loading => Icons.hourglass_top_rounded,
      _RestaurantStatusKind.offline => Icons.wifi_off_rounded,
      _RestaurantStatusKind.server => Icons.cloud_off_rounded,
      _RestaurantStatusKind.empty => Icons.restaurant_menu_rounded,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.10),
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accent.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.18),
                          accent.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: kind == _RestaurantStatusKind.loading
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: accent,
                            ),
                          )
                        : Icon(icon, size: 38, color: accent),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.75),
                    ),
                  ),
                  if (kind != _RestaurantStatusKind.loading) ...[
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        isArabic ? 'إعادة المحاولة' : 'Retry',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantHeroSection extends StatelessWidget {
  const _RestaurantHeroSection({
    required this.restaurant,
    required this.isArabic,
    required this.onBack,
    required this.onShare,
    required this.onMore,
  });

  final RestaurantHeaderModel restaurant;
  final bool isArabic;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 292,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroBackground(url: restaurant.coverImageUrl),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.16),
                  Colors.black.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.12),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _HeaderActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderActionButton(
                  icon: Icons.share_outlined,
                  onTap: onShare,
                ),
                const SizedBox(width: 10),
                _HeaderActionButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: onMore,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.16),
                    theme.scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);

    if (url.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.surfaceWarm,
              palette.surfaceMint,
              palette.surfaceSoft,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text('🍔', style: TextStyle(fontSize: 72)),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.surfaceMint,
              palette.surfaceSoft,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.surfaceWarm,
              palette.surfaceMint,
              palette.surfaceSoft,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text('🍔', style: TextStyle(fontSize: 72)),
        ),
      ),
    );
  }
}

class _RestaurantLogoCard extends StatelessWidget {
  const _RestaurantLogoCard({
    required this.logoUrl,
    required this.restaurantName,
    required this.fallbackIcon,
  });

  final String logoUrl;
  final String restaurantName;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Container(
      width: 106,
      height: 106,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: logoUrl.trim().isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(fallbackIcon,
                    color: theme.colorScheme.onSurface, size: 38),
                const SizedBox(height: 4),
                Text(
                  restaurantName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              errorWidget: (_, __, ___) => Icon(
                fallbackIcon,
                color: theme.colorScheme.onSurface,
                size: 38,
              ),
            ),
    );
  }
}

class _RestaurantMainSheet extends StatelessWidget {
  const _RestaurantMainSheet({
    required this.controller,
    required this.restaurant,
    required this.featuredItems,
    required this.visibleItems,
    required this.discountedCount,
    required this.isArabic,
    required this.onReviewsTap,
    required this.onPromoTap,
  });

  final RestaurantDetailsController controller;
  final RestaurantHeaderModel restaurant;
  final List<RestaurantMenuItemModel> featuredItems;
  final List<RestaurantMenuItemModel> visibleItems;
  final int discountedCount;
  final bool isArabic;
  final VoidCallback onReviewsTap;
  final VoidCallback onPromoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final isStore = restaurant.vendorType.toLowerCase() == 'store';
    final entityAr = isStore
        ? '\u0627\u0644\u0645\u062a\u062c\u0631'
        : '\u0627\u0644\u0645\u0637\u0639\u0645';
    final entityEn = isStore ? 'store' : 'restaurant';
    final metaText = _restaurantMetaText(restaurant, isArabic);
    final reviewsCountText = restaurant.reviewsCount > 0
        ? '(${_formatCount(restaurant.reviewsCount)} ${isArabic ? 'تقييم' : 'reviews'})'
        : '';
    final hasPromo = restaurant.supportsPickup || discountedCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 28,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _OpenStatusPill(
                      isOpen: restaurant.isOpen,
                      isArabic: isArabic,
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    restaurant.name,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  textDirection: ui.TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _RatingPill(
                      rating: restaurant.rating,
                      isArabic: isArabic,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        textDirection: ui.TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textSoft,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          children: [
                            if (metaText.isNotEmpty) TextSpan(text: metaText),
                            if (metaText.isNotEmpty &&
                                reviewsCountText.isNotEmpty)
                              const TextSpan(text: ' • '),
                            if (reviewsCountText.isNotEmpty)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: onReviewsTap,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      reviewsCountText,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: palette.textSoft,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                        decorationColor: palette.textSoft,
                                      ),
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
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: palette.border.withValues(alpha: 0.58),
                ),
                const SizedBox(height: 14),
                _RestaurantStatsRow(
                  restaurant: restaurant,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                _RestaurantOrderModesCard(
                  controller: controller,
                  restaurant: restaurant,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                _DeliveryBanner(
                  restaurant: restaurant,
                  isArabic: isArabic,
                ),
                if (hasPromo) ...[
                  const SizedBox(height: 12),
                  _RestaurantPromoCard(
                    restaurant: restaurant,
                    discountedCount: discountedCount,
                    isArabic: isArabic,
                    onTap: onPromoTap,
                  ),
                ],
                const SizedBox(height: 18),
                _CategoryTabs(
                  controller: controller,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: isArabic
                      ? 'الأكثر طلبًا'
                      : (isStore ? 'Popular products' : 'Most ordered'),
                ),
                const SizedBox(height: 12),
                if (featuredItems.isNotEmpty)
                  _FeaturedItemsStrip(
                    items: featuredItems,
                    isArabic: isArabic,
                    onTapItem: controller.openFoodItem,
                  )
                else
                  const SizedBox.shrink(),
                if (featuredItems.isNotEmpty) const SizedBox(height: 18),
                _SectionTitle(
                  title: _menuSectionTitle(
                    controller,
                    isArabic,
                    entityAr: entityAr,
                    entityEn: entityEn,
                  ),
                ),
                const SizedBox(height: 12),
                if (visibleItems.isEmpty)
                  _EmptyMenuState(isArabic: isArabic)
                else
                  ...visibleItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MenuItemCard(
                        item: item,
                        isArabic: isArabic,
                        onTap: () => controller.openFoodItem(item),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -20,
          right: 18,
          child: _RestaurantLogoCard(
            logoUrl: restaurant.logoUrl,
            restaurantName: restaurant.name,
            fallbackIcon: Icons.storefront_rounded,
          ),
        ),
      ],
    );
  }
}

class _RestaurantStatsRow extends StatelessWidget {
  const _RestaurantStatsRow({
    required this.restaurant,
    required this.isArabic,
  });

  final RestaurantHeaderModel restaurant;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border.withValues(alpha: 0.42)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.location_on_outlined,
              label: isArabic ? 'المسافة' : 'Distance',
              value: restaurant.distanceKm == null
                  ? (isArabic ? '-- كم' : '-- km')
                  : '${_formatDistance(restaurant.distanceKm!)} km',
            ),
          ),
          _VerticalStatDivider(),
          Expanded(
            child: _StatTile(
              icon: Icons.payments_outlined,
              label: isArabic ? 'رسوم التوصيل' : 'Delivery fee',
              value: restaurant.deliveryFee <= 0
                  ? (isArabic ? 'مجاني' : 'Free')
                  : '${_formatMoney(restaurant.deliveryFee)} ${AppCurrency.code}',
            ),
          ),
          _VerticalStatDivider(),
          Expanded(
            child: _StatTile(
              icon: Icons.delivery_dining_rounded,
              label: isArabic ? 'وقت التوصيل' : 'Delivery time',
              value: _deliveryTimeLabel(restaurant, isArabic),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = _ThemeTokens(Theme.of(context));
    return Container(
      width: 1,
      height: 62,
      color: palette.border.withValues(alpha: 0.52),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 23, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner({
    required this.restaurant,
    required this.isArabic,
  });

  final RestaurantHeaderModel restaurant;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final label = restaurant.deliveryFee <= 0
        ? (isArabic
            ? 'توصيل مجاني لهذا ${restaurant.vendorType.toLowerCase() == 'store' ? 'المتجر' : 'المطعم'}'
            : 'Free delivery for this ${restaurant.vendorType.toLowerCase() == 'store' ? 'store' : 'restaurant'}')
        : (isArabic
            ? 'رسوم التوصيل ${_formatMoney(restaurant.deliveryFee)} ريال'
            : 'Delivery fee ${_formatMoney(restaurant.deliveryFee)} ${AppCurrency.code}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surfaceMint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isArabic) ...[
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF1B7A3A),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.delivery_dining_rounded,
              color: Color(0xFF1B7A3A),
              size: 24,
            ),
          ] else ...[
            const Icon(
              Icons.delivery_dining_rounded,
              color: Color(0xFF1B7A3A),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF1B7A3A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestaurantOrderModesCard extends StatelessWidget {
  const _RestaurantOrderModesCard({
    required this.controller,
    required this.restaurant,
    required this.isArabic,
  });

  final RestaurantDetailsController controller;
  final RestaurantHeaderModel restaurant;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final modes = controller.orderModes;

    if (modes == null || !controller.hasOrderModeOptions) {
      return const SizedBox.shrink();
    }

    final accent =
        restaurant.isOpen ? theme.colorScheme.primary : const Color(0xFFC2410C);
    final activeMode = controller.selectedOrderMode;
    final activeSlots = controller.slotsForMode(activeMode);
    final selectedSlot = _selectedSlotForValue(
          activeSlots,
          controller.selectedSlotValue,
        ) ??
        (activeSlots.isNotEmpty ? activeSlots.first : null);
    final nextAvailableSlot =
        restaurant.isOpen ? null : _nextAvailableSlot(controller);
    final showRepeatedTimingSummary = _showRepeatedTimingSummary();
    final isStore = restaurant.vendorType.toLowerCase() == 'store';
    final entityAr = isStore ? 'المتجر' : 'المطعم';
    final entityEn = isStore ? 'store' : 'restaurant';

    final title = restaurant.isOpen
        ? (isArabic ? 'موعد الطلب' : 'Order timing')
        : (isArabic
            ? '$entityAr مغلق الآن'
            : (isStore ? 'Store closed now' : 'Restaurant closed now'));
    final subtitle = restaurant.isOpen
        ? (isArabic
            ? 'يمكنك الطلب فورًا أو حفظ وقت محدد ليظهر في صفحة الدفع.'
            : 'Order now or reserve a specific time that will appear in checkout.')
        : (nextAvailableSlot != null
            ? (isArabic
                ? 'أول موعد متاح: ${_slotDisplayLabel(nextAvailableSlot, isArabic)}'
                : 'First available time: ${_slotDisplayLabel(nextAvailableSlot, isArabic)}')
            : (isArabic
                ? 'اختر وقتًا من الخيارات المتاحة بعد إعادة الافتتاح.'
                : 'Choose from the available times once the $entityEn reopens.'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment:
            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SelectionBadge(
                icon: restaurant.isOpen
                    ? Icons.storefront_rounded
                    : Icons.lock_clock_rounded,
                label: restaurant.isOpen
                    ? (isArabic ? 'متاح' : 'Open')
                    : (isArabic ? 'مغلق' : 'Closed'),
                accent: accent,
                selected: true,
              ),
            ],
          ),
          if (showRepeatedTimingSummary &&
              !restaurant.isOpen &&
              nextAvailableSlot != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'أول موعد متاح: ${_slotDisplayLabel(nextAvailableSlot, isArabic)}'
                          : 'First available time: ${_slotDisplayLabel(nextAvailableSlot, isArabic)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showRepeatedTimingSummary) const SizedBox(height: 12),
          if (showRepeatedTimingSummary)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SelectionBadge(
                  icon: _modeIcon(activeMode),
                  label: _modeTitle(modes, activeMode, isArabic),
                  accent: accent,
                  selected: true,
                ),
                if (selectedSlot != null && activeMode != 'asap')
                  _SelectionBadge(
                    icon: Icons.event_rounded,
                    label: _slotDisplayLabel(selectedSlot, isArabic),
                    accent: accent,
                    selected: true,
                  ),
                _SelectionBadge(
                  icon: Icons.verified_rounded,
                  label: isArabic ? 'يُحفظ تلقائيًا' : 'Saved automatically',
                  accent: accent,
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OrderModeTile(
                  title: _modeTitle(modes, 'asap', isArabic),
                  subtitle: _modeSubtitle('asap', isArabic, restaurant.isOpen),
                  icon: Icons.flash_on_rounded,
                  selected: activeMode == 'asap',
                  enabled: controller.canSelectMode('asap'),
                  accent: accent,
                  onTap: () => controller.selectOrderMode('asap'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OrderModeTile(
                  title: _modeTitle(modes, 'scheduled', isArabic),
                  subtitle:
                      _modeSubtitle('scheduled', isArabic, restaurant.isOpen),
                  icon: Icons.event_available_rounded,
                  selected: activeMode == 'scheduled',
                  enabled: controller.canSelectMode('scheduled'),
                  accent: accent,
                  onTap: () => controller.selectOrderMode('scheduled'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OrderModeTile(
                  title: _modeTitle(modes, 'preorder', isArabic),
                  subtitle:
                      _modeSubtitle('preorder', isArabic, restaurant.isOpen),
                  icon: Icons.lock_clock_rounded,
                  selected: activeMode == 'preorder',
                  enabled: controller.canSelectMode('preorder'),
                  accent: accent,
                  onTap: () => controller.selectOrderMode('preorder'),
                ),
              ),
            ],
          ),
          if (activeMode != 'asap' && activeSlots.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              isArabic ? 'اختر الوقت' : 'Choose a time',
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: theme.textTheme.titleSmall?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: activeSlots
                  .map(
                    (slot) => _ScheduleSlotChip(
                      label: _slotDisplayLabel(slot, isArabic),
                      selected: controller.selectedSlotValue == slot.value,
                      accent: accent,
                      enabled: true,
                      onTap: () => controller.selectSlot(slot.value),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (showRepeatedTimingSummary) const SizedBox(height: 14),
          if (showRepeatedTimingSummary)
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 16, color: palette.textSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'اختيارك يثبت تلقائيًا ويظهر في صفحة الدفع.'
                        : 'Your selection is saved automatically and appears in checkout.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSoft,
                      height: 1.35,
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

bool _showRepeatedTimingSummary() => false;

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({
    required this.icon,
    required this.label,
    required this.accent,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final background = selected
        ? accent.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10)
        : theme.cardColor;
    final borderColor = selected
        ? accent.withValues(alpha: 0.35)
        : palette.border.withValues(alpha: 0.42);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderModeTile extends StatelessWidget {
  const _OrderModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final background = selected
        ? accent.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10)
        : theme.cardColor;
    final borderColor = selected
        ? accent.withValues(alpha: 0.45)
        : palette.border.withValues(alpha: 0.35);

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: SizedBox(
              height: 84,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: accent),
                      const Spacer(),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: selected ? accent : palette.textSoft,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textSoft,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleSlotChip extends StatelessWidget {
  const _ScheduleSlotChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final background = selected
        ? accent.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10)
        : theme.cardColor;
    final borderColor = selected
        ? accent.withValues(alpha: 0.45)
        : palette.border.withValues(alpha: 0.35);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantPromoCard extends StatelessWidget {
  const _RestaurantPromoCard({
    required this.restaurant,
    required this.discountedCount,
    required this.isArabic,
    required this.onTap,
  });

  final RestaurantHeaderModel restaurant;
  final int discountedCount;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final isStore = restaurant.vendorType.toLowerCase() == 'store';
    final entityAr = isStore
        ? '\u0627\u0644\u0645\u062a\u062c\u0631'
        : '\u0627\u0644\u0645\u0637\u0639\u0645';
    final entityEn = isStore ? 'store' : 'restaurant';
    final title = restaurant.supportsPickup
        ? (isArabic ? 'الاستلام من $entityAr متاح' : 'Pickup available')
        : (discountedCount > 0
            ? (isArabic ? 'عروض خاصة على بعض الأصناف' : 'Special item offers')
            : (isArabic
                ? 'تفاصيل إضافية عن $entityAr'
                : 'More $entityEn details'));
    final subtitle = restaurant.supportsPickup
        ? (isArabic
            ? 'يمكنك استلام الطلب مباشرة من $entityAr.'
            : 'You can pick up your order from the $entityEn.')
        : (discountedCount > 0
            ? (isArabic
                ? 'يوجد $discountedCount صنف بسعر مخفّض.'
                : '$discountedCount discounted items are available.')
            : (isArabic
                ? 'اعرض تفاصيل $entityAr والخيارات المتاحة.'
                : 'View $entityEn details and available options.'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.surfaceWarm,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.50)),
      ),
      child: Row(
        textDirection: ui.TextDirection.ltr,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: palette.surfaceMint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Lottie.asset(
                'assets/lottie/Groovy gift.json',
                width: 62,
                height: 62,
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppPillButton(
            label: isArabic ? 'عرض' : 'View',
            onPressed: onTap,
            height: 44,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.controller,
    required this.isArabic,
  });

  final RestaurantDetailsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final categories = controller.menuCategories;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isArabic,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryTab(
              label: isArabic ? 'الأكثر طلبًا' : 'Most ordered',
              isSelected: controller.selectedCategoryId == 'all',
              onTap: () => controller.selectCategory('all'),
            );
          }

          final category = categories[index - 1];
          return _CategoryTab(
            label: isArabic ? category.nameAr : category.nameEn,
            isSelected: controller.selectedCategoryId == category.id,
            onTap: () => controller.selectCategory(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = _ThemeTokens(theme);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isSelected ? colors.primary : palette.textSoft,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Text(
      title,
      textAlign: TextAlign.start,
      style: theme.textTheme.titleLarge?.copyWith(
        color: palette.text,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
  }
}

class _FeaturedItemsStrip extends StatelessWidget {
  const _FeaturedItemsStrip({
    required this.items,
    required this.isArabic,
    required this.onTapItem,
  });

  final List<RestaurantMenuItemModel> items;
  final bool isArabic;
  final void Function(RestaurantMenuItemModel item) onTapItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isArabic,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _FeaturedItemCard(
            item: item,
            isArabic: isArabic,
            onTap: () => onTapItem(item),
          );
        },
      ),
    );
  }
}

class _FeaturedItemCard extends StatelessWidget {
  const _FeaturedItemCard({
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  final RestaurantMenuItemModel item;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final name = isArabic ? item.nameAr : item.nameEn;
    final price = _formatMoney(item.price);
    final compare = item.comparePrice;
    final hasDiscount = _hasDiscountedPrice(item);

    return SizedBox(
      width: 158,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border.withValues(alpha: 0.62)),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _MenuImage(url: item.imageUrl),
                          if (hasDiscount)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isArabic ? 'عرض' : 'Sale',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.shadow,
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$price ${AppCurrency.code}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (hasDiscount &&
                          compare != null &&
                          compare > item.price) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatMoney(compare)} ${AppCurrency.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.textSoft,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  final RestaurantMenuItemModel item;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    final name = isArabic ? item.nameAr : item.nameEn;
    final description = isArabic ? item.descriptionAr : item.descriptionEn;
    final hasDiscount = _hasDiscountedPrice(item);
    final isAvailable = item.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Opacity(
            opacity: isAvailable ? 1 : 0.72,
            child: Row(
              textDirection: ui.TextDirection.ltr,
              children: [
                _MenuActionButton(
                  onTap: onTap,
                  enabled: isAvailable,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textSoft,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: isArabic
                            ? ui.TextDirection.rtl
                            : ui.TextDirection.ltr,
                        children: [
                          Text(
                              '${_formatMoney(item.price)} ${AppCurrency.code}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (hasDiscount && item.comparePrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${_formatMoney(item.comparePrice!)} ${AppCurrency.code}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textSoft,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          if (!isAvailable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isArabic ? 'غير متاح' : 'Unavailable',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: _MenuImage(url: item.imageUrl),
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

class _MenuActionButton extends StatelessWidget {
  const _MenuActionButton({
    required this.onTap,
    required this.enabled,
  });

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled ? const Color(0xFF1B7A3A) : theme.dividerColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    if (url.trim().isEmpty) {
      return Container(
        color: palette.surfaceSoft,
        child: Icon(
          Icons.fastfood_rounded,
          color: palette.text,
          size: 34,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => Container(color: palette.surfaceSoft),
      errorWidget: (_, __, ___) => Container(
        color: palette.surfaceSoft,
        child: Icon(
          Icons.fastfood_rounded,
          color: palette.text,
          size: 30,
        ),
      ),
    );
  }
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withValues(alpha: 0.55)),
      ),
      child: Text(
        isArabic
            ? 'لا توجد عناصر متاحة في هذا القسم حاليًا.'
            : 'No menu items are available in this section right now.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: palette.textSoft,
          height: 1.4,
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.98),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _OpenStatusPill extends StatelessWidget {
  const _OpenStatusPill({
    required this.isOpen,
    required this.isArabic,
  });

  final bool isOpen;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = isOpen ? colors.primary : const Color(0xFFC2410C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isOpen
                ? (isArabic ? 'مفتوح الآن' : 'Open now')
                : (isArabic ? 'مغلق الآن' : 'Closed now'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({
    required this.rating,
    required this.isArabic,
  });

  final double rating;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.star_rounded,
            size: 18,
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

Future<void> _showShareSheet(
  RestaurantHeaderModel restaurant,
  bool isArabic,
) async {
  await Clipboard.setData(
    ClipboardData(text: restaurant.name),
  );

  Get.snackbar(
    isArabic ? 'تم النسخ' : 'Copied',
    isArabic
        ? 'تم نسخ اسم المطعم إلى الحافظة.'
        : 'Restaurant name copied to clipboard.',
    snackPosition: SnackPosition.BOTTOM,
  );
}

void _showMoreSheet(
  BuildContext context,
  RestaurantHeaderModel restaurant,
  bool isArabic,
) {
  final badges = isArabic ? restaurant.badgesAr : restaurant.badgesEn;
  final theme = Theme.of(context);
  final palette = _ThemeTokens(theme);

  Get.bottomSheet(
    SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'تفاصيل المطعم' : 'Restaurant details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _SheetInfoRow(
              label: isArabic ? 'الحالة' : 'Status',
              value: restaurant.isOpen
                  ? (isArabic ? 'مفتوح' : 'Open')
                  : (isArabic ? 'مغلق' : 'Closed'),
            ),
            _SheetInfoRow(
              label: isArabic ? 'المسافة' : 'Distance',
              value: restaurant.distanceKm == null
                  ? (isArabic ? '-- كم' : '-- km')
                  : '${_formatDistance(restaurant.distanceKm!)} km',
            ),
            _SheetInfoRow(
              label: isArabic ? 'رسوم التوصيل' : 'Delivery fee',
              value: restaurant.deliveryFee <= 0
                  ? (isArabic ? 'مجاني' : 'Free')
                  : '${_formatMoney(restaurant.deliveryFee)} ${AppCurrency.code}',
            ),
            _SheetInfoRow(
              label: isArabic ? 'وقت التوصيل' : 'Delivery time',
              value: _deliveryTimeLabel(restaurant, isArabic),
            ),
            if (restaurant.supportsPickup || restaurant.supportsScheduledOrders)
              _SheetInfoRow(
                label: isArabic ? 'الخيارات' : 'Options',
                value: [
                  if (restaurant.supportsPickup)
                    (isArabic ? 'استلام متاح' : 'Pickup'),
                  if (restaurant.supportsScheduledOrders)
                    (isArabic ? 'حجز مسبق' : 'Scheduled'),
                ].join(' · '),
              ),
            if (badges.isNotEmpty)
              _SheetInfoRow(
                label: isArabic ? 'الوسوم' : 'Badges',
                value: badges.join(' · '),
              ),
            const SizedBox(height: 14),
            AppPillButton(
              label: isArabic ? 'إغلاق' : 'Close',
              onPressed: Get.back,
              expanded: true,
              height: 52,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _SheetInfoRow extends StatelessWidget {
  const _SheetInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ThemeTokens(theme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _restaurantMetaText(
  RestaurantHeaderModel restaurant,
  bool isArabic,
) {
  return _restaurantDescriptorText(restaurant, isArabic);
}

String _restaurantDescriptorText(
  RestaurantHeaderModel restaurant,
  bool isArabic,
) {
  final description = _normalizeDescriptorText(restaurant.vendorDescription);
  if (description.isNotEmpty) {
    return description;
  }

  final tagline = _normalizeDescriptorText(
    isArabic ? restaurant.taglineAr : restaurant.taglineEn,
  );
  if (tagline.isNotEmpty) {
    return tagline;
  }

  return '';
}

String _normalizeDescriptorText(String value) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return '';
  }

  final cleaned = raw.replaceAll(RegExp(r'\s*([.,،•|/])\s*'), ' • ');
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _menuSectionTitle(
  RestaurantDetailsController controller,
  bool isArabic, {
  required String entityAr,
  required String entityEn,
}) {
  if (controller.selectedCategoryId != 'all') {
    return _selectedCategoryLabel(
      controller,
      controller.selectedCategoryId,
      isArabic,
    );
  }

  if (controller.menuCategories.isNotEmpty) {
    return isArabic
        ? controller.menuCategories.first.nameAr
        : controller.menuCategories.first.nameEn;
  }

  return isArabic
      ? (entityAr == '\u0627\u0644\u0645\u062a\u062c\u0631'
          ? '\u0627\u0644\u0645\u0646\u062a\u062c\u0627\u062a'
          : '\u0627\u0644\u0642\u0627\u0626\u0645\u0629')
      : (entityEn == 'store' ? 'Products' : 'Menu');
}

String _selectedCategoryLabel(
  RestaurantDetailsController controller,
  String categoryId,
  bool isArabic,
) {
  for (final item in controller.menuCategories) {
    if (item.id == categoryId) {
      return isArabic ? item.nameAr : item.nameEn;
    }
  }
  return isArabic ? 'القائمة' : 'Menu';
}

String _deliveryTimeLabel(RestaurantHeaderModel restaurant, bool isArabic) {
  final min = restaurant.estimatedMinMinutes;
  final max = restaurant.estimatedMaxMinutes;
  if (min <= 0 && max <= 0) {
    return isArabic ? 'قريبًا' : 'Soon';
  }
  if (min > 0 && max > 0 && min != max) {
    return isArabic ? '$min-$max د' : '$min-$max min';
  }
  final value = max > 0 ? max : min;
  return isArabic ? '$value د' : '$value min';
}

RestaurantOrderSlotModel? _selectedSlotForValue(
  List<RestaurantOrderSlotModel> slots,
  String? value,
) {
  final target = value?.trim() ?? '';
  if (target.isEmpty) {
    return null;
  }

  for (final slot in slots) {
    if (slot.value.trim() == target) {
      return slot;
    }
  }
  return null;
}

RestaurantOrderSlotModel? _nextAvailableSlot(
  RestaurantDetailsController controller,
) {
  final modes = controller.orderModes;
  if (modes == null) {
    return null;
  }

  final activeSlots = controller.slotsForMode(controller.selectedOrderMode);
  if (activeSlots.isNotEmpty) {
    return _selectedSlotForValue(activeSlots, controller.selectedSlotValue) ??
        activeSlots.first;
  }

  if (modes.scheduledSlots.isNotEmpty) {
    return modes.scheduledSlots.first;
  }

  if (modes.preorderSlots.isNotEmpty) {
    return modes.preorderSlots.first;
  }

  return null;
}

String _slotDisplayLabel(RestaurantOrderSlotModel slot, bool isArabic) {
  final label = (isArabic ? slot.labelAr : slot.labelEn).trim();
  if (label.isNotEmpty) {
    return label;
  }

  final parsed = DateTime.tryParse(slot.value);
  if (parsed != null) {
    final locale = isArabic ? 'ar' : 'en';
    return DateFormat('yyyy/MM/dd h:mm a', locale).format(parsed);
  }

  return slot.value;
}

String _modeTitle(
  RestaurantOrderModesModel modes,
  String mode,
  bool isArabic,
) {
  switch (mode) {
    case 'asap':
      final label = isArabic ? modes.asapLabelAr : modes.asapLabelEn;
      if (label.trim().isNotEmpty) {
        return label;
      }
      return isArabic ? 'فوري' : 'ASAP';
    case 'scheduled':
      return isArabic ? 'مجدول' : 'Scheduled';
    case 'preorder':
      return isArabic ? 'طلب مسبق' : 'Preorder';
    default:
      return isArabic ? 'فوري' : 'ASAP';
  }
}

String _modeSubtitle(String mode, bool isArabic, bool isOpen) {
  switch (mode) {
    case 'asap':
      return isOpen
          ? (isArabic ? 'أسرع وقت متاح' : 'Soonest available')
          : (isArabic ? 'غير متاح الآن' : 'Unavailable while closed');
    case 'scheduled':
      return isArabic
          ? 'وقت محدد داخل ساعات العمل'
          : 'Pick a time inside working hours';
    case 'preorder':
      return isArabic
          ? 'احجز للوقت المتاح التالي'
          : 'Reserve the next available opening';
    default:
      return '';
  }
}

IconData _modeIcon(String mode) {
  switch (mode) {
    case 'scheduled':
      return Icons.event_available_rounded;
    case 'preorder':
      return Icons.lock_clock_rounded;
    default:
      return Icons.flash_on_rounded;
  }
}

bool _hasDiscountedPrice(RestaurantMenuItemModel item) {
  final compare = item.comparePrice;
  if (item.hasDiscount) {
    return true;
  }
  return compare != null && compare > item.price;
}

String _formatMoney(num value) {
  return NumberFormat('#,##0', 'en_US').format(value);
}

String _formatDistance(num value) {
  return value % 1 == 0
      ? NumberFormat('#,##0', 'en_US').format(value)
      : NumberFormat('#,##0.#', 'en_US').format(value);
}

String _formatCount(num value) {
  return NumberFormat('#,##0', 'en_US').format(value);
}
