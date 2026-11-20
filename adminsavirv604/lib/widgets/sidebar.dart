import 'package:admin_tks/theme.dart';
import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onItemTap,
    required this.isCollapsed,
    this.isStore = false,
    this.onAddPressed,
    this.onLogoutPressed,
  });

  final List<Map<String, dynamic>> items;
  final int activeIndex;
  final ValueChanged<int> onItemTap;
  final bool isCollapsed;
  final bool isStore;
  final VoidCallback? onAddPressed;
  final VoidCallback? onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 76 : 248,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 8 : 12,
        12,
        isCollapsed ? 8 : 12,
        12,
      ),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarBrand(isCollapsed: isCollapsed, isStore: isStore),
          if (!isCollapsed) ...[
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '\u0627\u0644\u0623\u0642\u0633\u0627\u0645',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                return _SidebarItem(
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  active: index == activeIndex,
                  collapsed: isCollapsed,
                  onTap: () => onItemTap(index),
                );
              },
            ),
          ),
          if (onLogoutPressed != null) ...[
            const SizedBox(height: 10),
            _SidebarLogoutButton(
              collapsed: isCollapsed,
              onTap: onLogoutPressed!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarLogoutButton extends StatelessWidget {
  const _SidebarLogoutButton({
    required this.collapsed,
    required this.onTap,
  });

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 7 : 12,
            vertical: collapsed ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5CACA)),
          ),
          child: collapsed
              ? const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 17,
                    color: Color(0xFFB42318),
                  ),
                )
              : const Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFB42318),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return collapsed
        ? Tooltip(
            message:
                '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c',
            child: button)
        : button;
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.isCollapsed, required this.isStore});

  final bool isCollapsed;
  final bool isStore;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFFF8F3),
          border: Border.all(color: kStroke),
        ),
        child: Center(
          child: Icon(
            isStore ? Icons.shopping_basket_rounded : Icons.restaurant_rounded,
            color: kPrimary,
            size: 28,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        children: [
          Icon(
            isStore ? Icons.shopping_basket_rounded : Icons.restaurant_rounded,
            color: kPrimary,
            size: 56,
          ),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Roaq ',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: '',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isStore
                ? '\u0644\u0648\u062d\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0645\u062a\u062c\u0631'
                : '\u0644\u0648\u062d\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0645\u0637\u0639\u0645',
            style: TextStyle(
              color: kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isStore
                ? '\u0644\u0648\u062d\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0645\u062a\u062c\u0631'
                : '\u0644\u0648\u062d\u0629 \u062a\u062d\u0643\u0645 \u0627\u0644\u0645\u0637\u0639\u0645',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeGradient = LinearGradient(
      colors: [
        kPrimary,
        kSecondary.withValues(alpha: 0.98),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 7 : 12,
            vertical: collapsed ? 8 : 10,
          ),
          decoration: BoxDecoration(
            gradient: active ? activeGradient : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: collapsed
              ? Center(
                  child: Icon(
                    icon,
                    size: 17,
                    color: active ? Colors.white : kTextSecondary,
                  ),
                )
              : Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.14)
                            : const Color(0xFFFFF8F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: active ? Colors.white : kTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: active ? Colors.white : kTextPrimary,
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
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
