import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/data/datasource/model/cartmodel.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/widget/cart/custom_bottom_navgationbar_cart.dart';
import 'package:tks/view/widget/cart/customitemscartlist.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';

class Cart extends StatelessWidget {
  Cart({super.key});

  final CartController controller = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
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
          child: GetBuilder<CartController>(
            builder: (controller) {
              final groups = controller.vendorGroups;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: _CartHeroHeader(
                      isArabic: isArabic,
                      itemCount: controller.totalcountitems,
                      restaurantCount: controller.restaurantCount,
                      total: controller.getFinalTotal(),
                      onBack: Get.back,
                    ),
                  ),
                  Expanded(
                    child: HandlingDataView(
                      statusRequest: controller.statusRequest,
                      widget: controller.data.isEmpty
                          ? _EmptyCartState(
                              isArabic: isArabic,
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 120),
                              children: [
                                _MultiRestaurantNotice(
                                  isArabic: isArabic,
                                  restaurantCount: controller.restaurantCount,
                                ),
                                const SizedBox(height: 12),
                                ...groups.map(
                                  (group) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _RestaurantGroupCard(
                                      group: group,
                                      isArabic: isArabic,
                                      controller: controller,
                                    ),
                                  ),
                                ),
                                _CartSummaryCard(
                                  controller: controller,
                                  isArabic: isArabic,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: GetBuilder<CartController>(
        builder: (controller) => BottomNavgationBarCart(
          totalprice: controller.getFinalTotal().toStringAsFixed(2),
          restaurantCount: controller.restaurantCount,
        ),
      ),
    );
  }
}

class _CompactCartHeader extends StatelessWidget {
  const _CompactCartHeader({
    required this.isArabic,
    required this.itemCount,
    required this.restaurantCount,
    required this.total,
    required this.onBack,
  });

  final bool isArabic;
  final int itemCount;
  final int restaurantCount;
  final double total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          _HeaderActionButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? '\u0627\u0644\u0633\u0644\u0629' : 'Cart',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$itemCount ${isArabic ? '\u0645\u0646\u062a\u062c\u0627\u062a' : 'items'} • $restaurantCount ${isArabic ? '\u0645\u062a\u0627\u062c\u0631' : 'stores'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} ${AppCurrency.code}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.shopping_bag_outlined, color: colors.primary),
        ],
      ),
    );
  }
}

class _CartHeroHeader extends StatelessWidget {
  const _CartHeroHeader({
    required this.isArabic,
    required this.itemCount,
    required this.restaurantCount,
    required this.total,
    required this.onBack,
  });

  final bool isArabic;
  final int itemCount;
  final int restaurantCount;
  final double total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _CompactCartHeader(
      isArabic: isArabic,
      itemCount: itemCount,
      restaurantCount: restaurantCount,
      total: total,
      onBack: onBack,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.98),
            const Color(0xFF16774D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeaderActionButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
              const Spacer(),
              _HeaderActionButton(
                icon: Icons.shopping_bag_outlined,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            isArabic ? 'السلة' : 'Cart',
            textAlign: TextAlign.start,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'كل منتجاتك في مكان واحد، حتى لو كانت من أكثر من مطعم.'
                : 'All of your items in one place, even if they come from multiple restaurants.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CartMetricTile(
                  isArabic: isArabic,
                  icon: Icons.shopping_basket_outlined,
                  label: isArabic ? 'منتجات' : 'Items',
                  value: itemCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CartMetricTile(
                  isArabic: isArabic,
                  icon: Icons.storefront_outlined,
                  label: isArabic ? 'مطاعم' : 'Restaurants',
                  value: restaurantCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CartMetricTile(
                  isArabic: isArabic,
                  icon: Icons.payments_outlined,
                  label: isArabic ? 'الإجمالي' : 'Total',
                  value: '${total.toStringAsFixed(2)} ${AppCurrency.code}',
                  compact: true,
                ),
              ),
            ],
          ),
          if (restaurantCount > 1) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.call_split_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'سيتم تقسيم الطلب تلقائيًا بين $restaurantCount مطاعم عند الدفع.'
                          : 'This order will be split automatically across $restaurantCount restaurants at checkout.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CartMetricTile extends StatelessWidget {
  const _CartMetricTile({
    required this.isArabic,
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final bool isArabic;
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 14 : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.10),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 38,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'سلتك فارغة' : 'Your cart is empty',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'أضف منتجات من أي مطعم، ويمكنك أيضًا الجمع بين أكثر من مطعم في نفس الطلب.'
                          : 'Add items from any restaurant. You can also mix items from multiple restaurants in the same order.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.75),
                      ),
                    ),
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

class _MultiRestaurantNotice extends StatelessWidget {
  const _MultiRestaurantNotice({
    required this.isArabic,
    required this.restaurantCount,
  });

  final bool isArabic;
  final int restaurantCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title = restaurantCount > 1
        ? (isArabic ? 'سلة متعددة المطاعم' : 'Multi-restaurant cart')
        : (isArabic ? 'سلة من مطعم واحد' : 'Single-restaurant cart');

    final message = restaurantCount > 1
        ? (isArabic
            ? 'لن تحتاج لفصل الطلب يدويًا. سنقسمه تلقائيًا حسب كل مطعم عند الدفع.'
            : 'No need to split the order manually. We separate it automatically by restaurant at checkout.')
        : (isArabic
            ? 'كل ما في السلة تابع لمطعم واحد فقط.'
            : 'Everything in this cart belongs to one restaurant only.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call_split_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.75,
                    ),
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

class _RestaurantGroupCard extends StatelessWidget {
  const _RestaurantGroupCard({
    required this.group,
    required this.isArabic,
    required this.controller,
  });

  final CartVendorGroup group;
  final bool isArabic;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RestaurantLogoAvatar(
                  logoUrl: group.vendorLogo,
                  name: group.displayName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        group.subtitle.isNotEmpty
                            ? group.subtitle
                            : (isArabic
                                ? 'منتجات هذا المطعم'
                                : 'Items from this restaurant'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.72,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RestaurantChip(
                            icon: Icons.shopping_bag_outlined,
                            label: isArabic ? 'العدد' : 'Items',
                            value: group.itemCount.toString(),
                            accent: colors.primary,
                          ),
                          _RestaurantChip(
                            icon: Icons.payments_outlined,
                            label: isArabic ? 'مجموع المطعم' : 'Subtotal',
                            value: '${group.subtotal.toStringAsFixed(2)} ${AppCurrency.code}',
                            accent: colors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (group.items.isNotEmpty) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              children: [
                for (var index = 0; index < group.items.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == group.items.length - 1 ? 0 : 12,
                    ),
                    child: CustomItemsCartList(
                      onAdd: () async {
                        final item = group.items[index];
                        await controller.add(
                          item.itemsId!,
                          cartid: item.cartId,
                          weightStep:
                              item.stockUnit?.trim().toLowerCase() == 'kg'
                                  ? 0.25
                                  : null,
                        );
                      },
                      onRemove: () async {
                        final item = group.items[index];
                        await controller.delete(
                          cartid: item.cartId,
                          itemsid: item.itemsId,
                          weightStep:
                              item.stockUnit?.trim().toLowerCase() == 'kg'
                                  ? 0.25
                                  : null,
                        );
                      },
                      imagename: group.items[index].itemsImage ?? '',
                      name: group.items[index].itemsNameAr ??
                          group.items[index].itemsNameEn ??
                          '',
                      subtitle: _buildItemSubtitle(
                        context,
                        group.items[index],
                        isArabic,
                      ),
                      price:
                          '${_lineTotal(group.items[index]).toStringAsFixed(2)} ${AppCurrency.code}',
                      count: _cartQuantityLabel(group.items[index], isArabic),
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

class _RestaurantLogoAvatar extends StatelessWidget {
  const _RestaurantLogoAvatar({
    required this.logoUrl,
    required this.name,
  });

  final String logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final resolved = AppLink.resolveUrl(logoUrl);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolved.isEmpty
          ? Icon(
              Icons.storefront_rounded,
              color: colors.primary,
              size: 30,
            )
          : FallbackNetworkImage(
              imageUrls: [resolved],
              label: name,
              fit: BoxFit.cover,
              placeholder: Container(
                color: colors.primary.withValues(alpha: 0.08),
              ),
              errorWidget: Container(
                color: colors.primary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.storefront_rounded,
                  color: colors.primary,
                ),
              ),
            ),
    );
  }
}

class _RestaurantChip extends StatelessWidget {
  const _RestaurantChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.72,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({
    required this.controller,
    required this.isArabic,
  });

  final CartController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            title: isArabic ? 'المجموع الفرعي' : 'Subtotal',
            value: '${controller.getSubtotal().toStringAsFixed(2)} ${AppCurrency.code}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            title: isArabic ? 'خصم العناصر' : 'Item discounts',
            value:
                '${controller.getTotalItemsDiscountAmount().toStringAsFixed(2)} ${AppCurrency.code}',
            valueColor: colors.error,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            title: isArabic ? 'خصم الكوبون' : 'Coupon discount',
            value:
                '${controller.getCouponDiscountAmount().toStringAsFixed(2)} ${AppCurrency.code}',
            valueColor: colors.error,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _SummaryRow(
            title: isArabic ? 'الإجمالي النهائي' : 'Final total',
            value: '${controller.getFinalTotal().toStringAsFixed(2)} ${AppCurrency.code}',
            valueColor: colors.primary,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String title;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String? _buildItemSubtitle(
  BuildContext context,
  CartModel item,
  bool isArabic,
) {
  final details = <String>[];

  if (item.stockUnit?.trim().toLowerCase() == 'kg' &&
      (item.weightQuantity ?? '').trim().isNotEmpty &&
      (item.cartItemSize ?? '').trim().isEmpty) {
    details.add(
      '${isArabic ? '\u0627\u0644\u0648\u0632\u0646' : 'Weight'}: ${_cartQuantityLabel(item, isArabic)}',
    );
  }

  if ((item.cartItemColor ?? '').trim().isNotEmpty) {
    details.add('${isArabic ? 'اللون' : 'Color'}: ${item.cartItemColor}');
  }

  if ((item.cartItemSize ?? '').trim().isNotEmpty) {
    details.add(item.stockUnit == 'kg'
        ? '${isArabic ? 'الوزن' : 'Weight'}: ${item.cartItemSize}'
        : '${isArabic ? 'المقاس' : 'Size'}: ${item.cartItemSize}');
  }

  if (item.stockUnit == 'kg' &&
      (item.weightQuantity ?? '').trim().isNotEmpty &&
      (item.cartItemSize ?? '').trim().isNotEmpty) {
    details.add(
        '${isArabic ? 'الإجمالي' : 'Total'}: ${item.weightQuantity} ${isArabic ? 'كجم' : 'kg'}');
  }

  if ((item.cartLensName ?? '').trim().isNotEmpty) {
    details.add('${isArabic ? 'العدسة' : 'Lens'}: ${item.cartLensName}');
  }

  if ((item.cartPrescriptionSummary ?? '').trim().isNotEmpty) {
    details.add(item.cartPrescriptionSummary!.trim());
  }

  if ((item.cartMenuOptionsSummary ?? '').trim().isNotEmpty) {
    details.add(
      '${isArabic ? 'الإضافات' : 'Extras'}: ${item.cartMenuOptionsSummary}',
    );
  }

  if ((item.cartItemNote ?? '').trim().isNotEmpty) {
    details.add('${isArabic ? 'ملاحظة' : 'Note'}: ${item.cartItemNote}');
  }

  return details.isEmpty ? null : details.join('\n');
}

double _lineTotal(CartModel item) {
  return double.tryParse(item.lineTotal ?? '0') ?? 0.0;
}

String _cartQuantityLabel(CartModel item, bool isArabic) {
  if (item.stockUnit?.trim().toLowerCase() == 'kg' &&
      (item.weightQuantity ?? '').trim().isNotEmpty) {
    final weight = double.tryParse(item.weightQuantity!.trim());
    final value = weight == null
        ? item.weightQuantity!.trim()
        : (weight == weight.roundToDouble()
            ? weight.toStringAsFixed(0)
            : weight.toStringAsFixed(2));
    return '$value ${isArabic ? '\u0643\u062c\u0645' : 'kg'}';
  }

  final count = int.tryParse(item.countitems ?? '') ?? 1;
  if (!isArabic) {
    return '$count ${count == 1 ? 'item' : 'items'}';
  }

  if (count == 1) return '\u0639\u0646\u0635\u0631 \u0648\u0627\u062d\u062f';
  if (count == 2) return '\u0639\u0646\u0635\u0631\u0627\u0646';
  return '$count \u0639\u0646\u0627\u0635\u0631';
}
