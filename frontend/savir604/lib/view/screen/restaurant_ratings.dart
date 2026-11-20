import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/restaurants/restaurant_ratings_controller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/data/datasource/model/ratingmodel.dart';
import 'package:tks/linkapi/linkapi.dart';

class RestaurantRatingsScreen extends StatelessWidget {
  const RestaurantRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: GetBuilder<RestaurantRatingsController>(
            init: RestaurantRatingsController(),
            global: false,
            builder: (controller) {
              return HandlingDataView(
                statusRequest: controller.statusRequest,
                widget: RefreshIndicator(
                  onRefresh: controller.retryFetch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _RestaurantRatingsHeader(
                        controller: controller,
                        isArabic: isArabic,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -42),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _RatingSummaryCard(
                                controller: controller,
                                isArabic: isArabic,
                              ),
                              const SizedBox(height: 16),
                              if (controller.ratings.isEmpty)
                                _EmptyRatingsState(isArabic: isArabic)
                              else
                                Column(
                                  children: controller.ratings
                                      .map(
                                        (rating) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _VendorRatingTile(
                                            rating: rating,
                                            isArabic: isArabic,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 20),
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
      ),
    );
  }
}

class _RestaurantRatingsHeader extends StatelessWidget {
  const _RestaurantRatingsHeader({
    required this.controller,
    required this.isArabic,
  });

  final RestaurantRatingsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = AppLink.normalizeUrl(controller.restaurantCover);

    return SizedBox(
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: cover.trim().isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.22),
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          theme.scaffoldBackgroundColor,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.28),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.05),
                    theme.scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 14,
            start: 16,
            child: _CircleActionButton(
              icon: Icons.arrow_back_rounded,
              onTap: Get.back,
            ),
          ),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: -34,
            child: _RestaurantHeaderCard(
              controller: controller,
              isArabic: isArabic,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantHeaderCard extends StatelessWidget {
  const _RestaurantHeaderCard({
    required this.controller,
    required this.isArabic,
  });

  final RestaurantRatingsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logo = AppLink.normalizeUrl(controller.restaurantLogo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: logo.trim().isEmpty
                ? Icon(
                    Icons.restaurant_rounded,
                    color: theme.colorScheme.primary,
                  )
                : CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.restaurant_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  controller.restaurantName.isNotEmpty
                      ? controller.restaurantName
                      : (isArabic ? 'تقييمات المطعم' : 'Restaurant reviews'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'شاهد تقييمات العملاء حسب كل منتج داخل المطعم'
                      : 'Browse customer reviews for items from this restaurant',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                    height: 1.4,
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

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.controller,
    required this.isArabic,
  });

  final RestaurantRatingsController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.averageRating.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              _StarsRow(value: controller.averageRating),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إجمالي التقييمات' : 'Total reviews',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.ratingsCount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isArabic
                      ? '${controller.ratingPercentage}% رضا تقريبًا'
                      : '${controller.ratingPercentage}% satisfaction',
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

class _EmptyRatingsState extends StatelessWidget {
  const _EmptyRatingsState({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
      ),
      child: Text(
        isArabic
            ? 'لا توجد تقييمات لهذا المطعم حتى الآن.'
            : 'There are no reviews for this restaurant yet.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78),
          height: 1.5,
        ),
      ),
    );
  }
}

class _VendorRatingTile extends StatelessWidget {
  const _VendorRatingTile({
    required this.rating,
    required this.isArabic,
  });

  final RatingModel rating;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                rating.createdAt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (rating.itemName.trim().isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                rating.itemName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
  const _StarsRow({required this.value});

  final double value;

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
          size: 18,
          color: const Color(0xFFF4B400),
        );
      }),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
