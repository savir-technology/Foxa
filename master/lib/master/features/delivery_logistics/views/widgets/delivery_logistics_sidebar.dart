// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _DeliveryLogisticsRightSidebar extends StatelessWidget {
  const _DeliveryLogisticsRightSidebar({
    required this.activeSubPage,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onOrdersTap,
    required this.onRestaurantsTap,
    required this.onUsersTap,
    this.onFinanceTap,
    this.onMarketingTap,
    required this.onCollapse,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onRestaurantsTap;
  final VoidCallback onUsersTap;
  final VoidCallback? onFinanceTap;
  final VoidCallback? onMarketingTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final menuItems = <_OperationsSidebarTileData>[
      const _OperationsSidebarTileData(
        label: 'إدارة المطاعم',
        icon: Icons.storefront_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'العملاء',
        icon: Icons.people_alt_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة المالية',
        icon: Icons.account_balance_wallet_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'التسويق والنمو',
        icon: Icons.campaign_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'مركز التواصل',
        icon: Icons.notifications_active_outlined,
      ),
      // 'الجودة وخدمة العملاء' removed per user request
      const _OperationsSidebarTileData(
        label: 'التقارير والتحليلات',
        icon: Icons.query_stats_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'إعدادات المنصة',
        icon: Icons.settings_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة والصلاحيات',
        icon: Icons.admin_panel_settings_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Expanded(
                    child: Text(
                      'التنقل',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OrdersSidebarToggleButton(
                    tooltip: 'إخفاء القائمة الجانبية',
                    icon: Icons.keyboard_double_arrow_right_rounded,
                    active: true,
                    onTap: onCollapse,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    _OperationsSidebarMainItem(
                      label: 'الرئيسية',
                      icon: Icons.home_rounded,
                      selected: false,
                      onTap: onHomeTap,
                    ),
                    const SizedBox(height: 10),
                    _OperationsSidebarMainItem(
                      label: 'لوحة العمليات',
                      icon: Icons.grid_view_rounded,
                      selected: false,
                      onTap: onOperationsTap,
                    ),
                    const SizedBox(height: 10),
                    _OperationsSidebarMainItem(
                      label: 'إدارة الطلبات',
                      icon: Icons.receipt_long_outlined,
                      selected: false,
                      onTap: onOrdersTap,
                    ),
                    const SizedBox(height: 10),
                    _OperationsSidebarMainItem(
                      label: 'التوصيل واللوجستيات',
                      icon: Icons.delivery_dining_outlined,
                      selected: true,
                      onTap: () => onSubPageTap('drivers'),
                    ),
                    const SizedBox(height: 10),
                    _DeliveryLogisticsSubMenu(
                      activeSubPage: activeSubPage,
                      onSubPageTap: onSubPageTap,
                    ),
                    const SizedBox(height: 12),
                    for (var index = 0; index < menuItems.length; index++) ...[
                      _OperationsSidebarMenuItem(
                        data: menuItems[index],
                        onTap: () {
                          switch (index) {
                            case 0:
                              onRestaurantsTap();
                              break;
                            case 1:
                              onUsersTap();
                              break;
                            case 2:
                              if (onFinanceTap != null) {
                                onFinanceTap!();
                              } else {
                                _navigateToRememberedMasterSection(
                                  context,
                                  'finance',
                                );
                              }
                              break;
                            case 3:
                              if (onMarketingTap != null) {
                                onMarketingTap!();
                              } else {
                                _navigateToRememberedMasterSection(
                                  context,
                                  'marketing',
                                );
                              }
                              break;
                            case 4:
                              _navigateToRememberedMasterSection(
                                context,
                                'communication',
                              );
                              break;
                            case 5:
                              _navigateToRememberedMasterSection(
                                context,
                                'reports',
                              );
                              break;
                            case 6:
                              _navigateToRememberedMasterSection(
                                context,
                                'settings',
                              );
                              break;
                            case 7:
                              _navigateToRememberedMasterSection(
                                context,
                                'access',
                              );
                              break;
                          }
                        },
                      ),
                      if (index != menuItems.length - 1)
                        const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
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

class _DeliveryLogisticsSubMenu extends StatelessWidget {
  const _DeliveryLogisticsSubMenu({
    required this.activeSubPage,
    required this.onSubPageTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('drivers', 'إدارة السائقين', Icons.manage_accounts_outlined),
      ('dispatch', 'توزيع الطلبات على السائقين', Icons.assignment_ind_outlined),
      ('tracking', 'التتبع المباشر', Icons.location_on_outlined),
      ('zones', 'مناطق الخدمة والتوصيل', Icons.map_outlined),
      ('emergency', 'طوارئ السائقين', Icons.emergency_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Builder(
              builder: (context) {
                final selected = activeSubPage == items[index].$1;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSubPageTap(items[index].$1),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF1F8F4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            items[index].$3,
                            size: 16,
                            color: selected
                                ? _kPrimaryGreen
                                : const Color(0xFF4E5660),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              items[index].$2,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.6,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected
                                    ? _kPrimaryGreen
                                    : const Color(0xFF4E5660),
                              ),
                            ),
                          ),
                          if (selected)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _kPrimaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (index != items.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
