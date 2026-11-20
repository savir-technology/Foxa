import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/controler/home/homescreen_controller.dart';

class CustomBottomAppBarHome extends StatelessWidget {
  const CustomBottomAppBarHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<HomeScreenControllerImp>(
      builder: (controller) {
        if (!Get.isRegistered<CartController>()) {
          Get.put(CartController());
        }

        return GetBuilder<CartController>(
          builder: (cartController) {
            return SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                height: 76,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.85)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children:
                      List.generate(controller.bottomappbar.length, (index) {
                    final item = controller.bottomappbar[index];
                    final isActive = controller.currentpage == index;
                    final title = '${item['title']}'.tr;
                    final icon = item['icon'] as IconData;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _BottomNavItem(
                          title: title,
                          icon: icon,
                          isActive: isActive,
                          isCartTab: index == 1,
                          cartCount: cartController.totalcountitems,
                          onTap: () => controller.changePage(index),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.isCartTab,
    required this.cartCount,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isActive;
  final bool isCartTab;
  final int cartCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isActive)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: const SizedBox.shrink(),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 23,
                      color: isActive
                          ? colors.onPrimary
                          : colors.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? colors.onPrimary
                            : colors.onSurface.withValues(alpha: 0.55),
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 10.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCartTab && cartCount > 0)
                Positioned(
                  top: 0,
                  right: 12,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
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
      ),
    );
  }
}
