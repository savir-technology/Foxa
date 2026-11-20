import 'package:delvery/controllers/home_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/screens/current_order_screen.dart';
import 'package:delvery/screens/dashboard_tab.dart';
import 'package:delvery/screens/help_screen.dart';
import 'package:delvery/screens/notifications_screen.dart';
import 'package:delvery/screens/profile_screen.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle _cairo(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.0,
  double letterSpacing = 0,
}) {
  return GoogleFonts.cairo(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final HomeController _controller = Get.find<HomeController>();
  int? _initialTab;
  bool _initialTabApplied = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _initialTab = int.tryParse('${args['tab'] ?? ''}');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialTabApplied) {
        return;
      }
      _controller.onPageReady(_initialTab);
      _initialTabApplied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardTab(),
      const HelpScreen(embedInShell: true),
      const CurrentOrderScreen(embedInShell: true),
      const NotificationsScreen(embedInShell: true),
      const ProfileScreen(embedInShell: true),
    ];
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      final selectedIndex = _controller.tabIndex.value
          .clamp(0, pages.length - 1)
          .toInt();

      return Scaffold(
        extendBody: true,
        backgroundColor: DriverUi.backgroundAdaptive,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<int>(selectedIndex),
            child: pages[selectedIndex],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _HomeBottomNavigation(
            selectedIndex: selectedIndex,
            onSelected: _controller.setTab,
          ),
        ),
      );
    });
  }
}

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <_HomeNavItemData>[
      _HomeNavItemData(
        pageIndex: 4,
        label: t('المزيد', 'More'),
        icon: Icons.more_horiz_rounded,
        inactiveIcon: Icons.more_horiz_rounded,
      ),
      _HomeNavItemData(
        pageIndex: 3,
        label: t('الإشعارات', 'Notifications'),
        icon: Icons.notifications_rounded,
        inactiveIcon: Icons.notifications_none_rounded,
      ),
      _HomeNavItemData(
        pageIndex: 2,
        label: t('الطلبات', 'Orders'),
        icon: Icons.work_rounded,
        inactiveIcon: Icons.work_outline_rounded,
        center: true,
      ),
      _HomeNavItemData(
        pageIndex: 1,
        label: t('المساعدة', 'Support'),
        icon: Icons.headset_mic_rounded,
        inactiveIcon: Icons.headset_mic_outlined,
      ),
      _HomeNavItemData(
        pageIndex: 0,
        label: t('الرئيسية', 'Home'),
        icon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
    ];

    return Container(
      width: double.infinity,
      height: 82,
      decoration: BoxDecoration(
        color: DriverUi.surfaceAdaptive,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: DriverUi.lineAdaptive)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final item in items)
              Expanded(
                child: _HomeNavItem(
                  data: item,
                  selected: selectedIndex == item.pageIndex,
                  onTap: () => onSelected(item.pageIndex),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavItemData {
  const _HomeNavItemData({
    required this.pageIndex,
    required this.label,
    required this.icon,
    required this.inactiveIcon,
    this.center = false,
  });

  final int pageIndex;
  final String label;
  final IconData icon;
  final IconData inactiveIcon;
  final bool center;
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _HomeNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? DriverUi.primary : DriverUi.mutedTextAdaptive;
    final iconColor = selected ? DriverUi.primary : DriverUi.mutedTextAdaptive;

    if (data.center) {
      return SizedBox(
        height: 82,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Transform.translate(
                offset: const Offset(0, -10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected ? DriverUi.primary : DriverUi.surfaceAdaptive,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    selected ? data.icon : data.inactiveIcon,
                    color: selected ? Colors.white : DriverUi.mutedTextAdaptive,
                    size: 24,
                  ),
                ),
              ),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: _cairo(13, FontWeight.w600, labelColor),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              selected ? data.icon : data.inactiveIcon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: _cairo(
                13,
                selected ? FontWeight.w600 : FontWeight.w400,
                labelColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

