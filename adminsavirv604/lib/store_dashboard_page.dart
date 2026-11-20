import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Store-specific dashboard entry point. Shared order, delivery and account
/// services remain available through the same routes, while catalogue actions
/// use store terminology and capabilities.
class StoreDashboardPage extends StatelessWidget {
  const StoreDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <_StoreAction>[
      const _StoreAction(
        title: 'Products',
        subtitle: 'Manage products, units and variants',
        icon: Icons.inventory_2_rounded,
        route: DashboardRoutes.menu,
      ),
      const _StoreAction(
        title: 'Inventory',
        subtitle: 'Track stock and low-stock products',
        icon: Icons.warehouse_rounded,
        route: DashboardRoutes.inventory,
      ),
      const _StoreAction(
        title: 'Orders',
        subtitle: 'Review and process customer orders',
        icon: Icons.receipt_long_rounded,
        route: DashboardRoutes.orders,
      ),
      const _StoreAction(
        title: 'Store settings',
        subtitle: 'Opening hours, delivery and profile',
        icon: Icons.storefront_rounded,
        route: DashboardRoutes.settings,
      ),
    ];

    return DashboardPageShell(
      title: 'Store dashboard',
      subtitle: 'Manage your store and catalogue',
      icon: Icons.storefront_rounded,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: columns == 2 ? 2.4 : 3.2,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Get.toNamed(action.route),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kSurfaceElevated),
                  ),
                  child: Row(
                    children: [
                      Icon(action.icon, color: kPrimary, size: 34),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(action.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(action.subtitle, style: const TextStyle(color: kTextSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kTextSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StoreAction {
  const _StoreAction({required this.title, required this.subtitle, required this.icon, required this.route});

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
