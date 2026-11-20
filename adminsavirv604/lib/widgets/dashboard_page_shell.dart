import 'dart:convert';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';
import 'package:admin_tks/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPageShell extends StatelessWidget {
  const DashboardPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.body,
    this.actions = const [],
    this.stats = const [],
    this.topPadding = 16,
    this.statusLabel,
    this.statusTint = kPrimary,
    this.dateLabel,
    this.showSidebar = true,
    this.sidebarItems,
    this.activeSidebarIndex,
    this.onSidebarItemTap,
    this.onRefreshPressed,
    this.profileName,
    this.profileSubtitle,
    this.profileAvatarUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget body;
  final List<Widget> actions;
  final List<Widget> stats;
  final double topPadding;
  final String? statusLabel;
  final Color statusTint;
  final String? dateLabel;
  final bool showSidebar;
  final List<Map<String, dynamic>>? sidebarItems;
  final int? activeSidebarIndex;
  final ValueChanged<int>? onSidebarItemTap;
  final VoidCallback? onRefreshPressed;
  final String? profileName;
  final String? profileSubtitle;
  final String? profileAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 880;
    final isCollapsedSidebar = width < 1280;
    final routeArgs = Get.arguments;
    final routeArgsMap = routeArgs is Map
        ? routeArgs.cast<dynamic, dynamic>()
        : const <dynamic, dynamic>{};
    final resolvedTitle = _repairMojibake(
      (routeArgsMap['shellTitle'] as String?)?.trim().isNotEmpty == true
          ? routeArgsMap['shellTitle'].toString()
          : title,
    );
    final resolvedHeaderSubtitle = _repairMojibake(
      (routeArgsMap['shellSubtitle'] as String?)?.trim().isNotEmpty == true
          ? routeArgsMap['shellSubtitle'].toString()
          : subtitle,
    );
    final activeIndex = activeSidebarIndex ??
        (routeArgsMap['sidebarIndex'] is int
            ? routeArgsMap['sidebarIndex'] as int
            : null) ??
        _inferSidebarIndex(resolvedTitle, resolvedHeaderSubtitle, icon);
    final auth = _maybeAuth();
    final defaultItems =
        auth?.isMaster == true ? _masterSidebarItems : _defaultSidebarItems;
    final contextualItems = sidebarItems ??
        defaultItems.map((item) {
          if (auth?.isStore != true) return item;
          final copy = Map<String, dynamic>.from(item);
          if (copy['route'] == DashboardRoutes.menu) {
            copy['title'] = '\u0627\u0644\u0645\u0646\u062a\u062c\u0627\u062a';
          } else if (copy['route'] == DashboardRoutes.inventory) {
            copy['title'] = '\u0627\u0644\u0645\u062e\u0632\u0648\u0646';
          } else if (copy['route'] == DashboardRoutes.settings) {
            copy['title'] =
                '\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u0645\u062a\u062c\u0631';
          }
          return copy;
        }).toList();
    final items = _filteredSidebarItems(contextualItems);
    final resolvedName =
        profileName ?? auth?.displayName ?? auth?.storeName ?? 'Roaq';
    final session = auth?.session.value;
    final vendorDescription = auth?.vendorDescription.trim() ?? '';
    final resolvedProfileSubtitle = profileSubtitle ??
        (vendorDescription.isNotEmpty
            ? vendorDescription
            : (auth?.isStore == true
                ? '\u0644\u0648\u062d\u0629 \u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0645\u062a\u062c\u0631'
                : '\u0644\u0648\u062d\u0629 \u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0645\u0637\u0639\u0645'));
    final resolvedAvatar = profileAvatarUrl ?? session?.logo;
    final resolvedDateLabel = dateLabel ?? _formatArabicDate(DateTime.now());

    Future<void> handleLogout() async {
      if (auth == null) return;
      await auth.logout();
      if (context.mounted) {
        Get.offAllNamed('/');
      }
    }

    void handleSidebarTap(int index, {required bool closeDrawer}) {
      if (index < 0 || index >= items.length) {
        return;
      }

      final item = items[index];
      final route = item['route']?.toString().trim() ?? '';
      final arguments = item['arguments'];

      if (closeDrawer && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (route.isNotEmpty) {
        Get.offNamed(
          route,
          arguments: arguments,
          preventDuplicates: false,
        );
        return;
      }

      if (onSidebarItemTap != null) {
        onSidebarItemTap!(index);
      }
    }

    return Scaffold(
      backgroundColor: kBackground,
      drawer: isMobile && showSidebar
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: SafeArea(
                child: _SidebarHost(
                  items: items,
                  activeIndex: activeIndex,
                  isCollapsed: false,
                  isStore: auth?.isStore == true,
                  onItemTap: (index) =>
                      handleSidebarTap(index, closeDrawer: true),
                ),
              ),
            )
          : null,
      body: DashboardBackground(
        child: SafeArea(
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Builder(
                  builder: (scaffoldContext) => SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 16,
                      12,
                      isMobile ? 14 : 12,
                      18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardHeaderCard(
                          title: resolvedTitle,
                          subtitle: resolvedHeaderSubtitle,
                          icon: icon,
                          actions: actions,
                          dateLabel: resolvedDateLabel,
                          profileName: resolvedName,
                          profileSubtitle: resolvedProfileSubtitle,
                          profileAvatarUrl: resolvedAvatar,
                          onRefreshPressed: onRefreshPressed,
                          onLogoutPressed: auth == null ? null : handleLogout,
                          isMobile: isMobile,
                          showMenuButton: isMobile && showSidebar,
                          onMenuPressed: showSidebar
                              ? () => Scaffold.of(scaffoldContext).openDrawer()
                              : null,
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _StatusPill(
                              label: statusLabel!,
                              tint: statusTint,
                            ),
                          ),
                        ],
                        if (stats.isNotEmpty) ...[
                          SizedBox(height: topPadding),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: stats,
                          ),
                        ],
                        SizedBox(height: topPadding),
                        body,
                      ],
                    ),
                  ),
                ),
              ),
              if (showSidebar && !isMobile) ...[
                const SizedBox(width: 10),
                _SidebarHost(
                  items: items,
                  activeIndex: activeIndex,
                  isCollapsed: isCollapsedSidebar,
                  isStore: auth?.isStore == true,
                  onItemTap: (index) =>
                      handleSidebarTap(index, closeDrawer: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.valueLabel,
    this.tint = kPrimary,
    this.width = 240,
  });

  final String label;
  final String value;
  final String? valueLabel;
  final IconData? icon;
  final String? subtitle;
  final Color tint;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              if (icon != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: tint, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 9,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (valueLabel != null && valueLabel!.trim().isNotEmpty)
                      Column(
                        children: [
                          Text(
                            value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            valueLabel!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: kTextSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHost extends StatelessWidget {
  const _SidebarHost({
    required this.items,
    required this.activeIndex,
    required this.isCollapsed,
    required this.onItemTap,
    required this.isStore,
  });

  final List<Map<String, dynamic>> items;
  final int activeIndex;
  final bool isCollapsed;
  final ValueChanged<int> onItemTap;
  final bool isStore;

  @override
  Widget build(BuildContext context) {
    return AdminSidebar(
      items: items,
      activeIndex: activeIndex,
      isCollapsed: isCollapsed,
      isStore: isStore,
      onItemTap: onItemTap,
    );
  }
}

class _DashboardHeaderCard extends StatelessWidget {
  const _DashboardHeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actions,
    required this.dateLabel,
    required this.profileName,
    required this.profileSubtitle,
    required this.profileAvatarUrl,
    required this.onRefreshPressed,
    required this.onLogoutPressed,
    required this.isMobile,
    required this.showMenuButton,
    required this.onMenuPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;
  final String dateLabel;
  final String profileName;
  final String profileSubtitle;
  final String? profileAvatarUrl;
  final VoidCallback? onRefreshPressed;
  final VoidCallback? onLogoutPressed;
  final bool isMobile;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final headerActions = <Widget>[...actions];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (showMenuButton)
                        IconButton(
                          onPressed: onMenuPressed,
                          icon: const Icon(Icons.menu_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: kSurfaceElevated,
                            foregroundColor: kTextPrimary,
                          ),
                        ),
                      if (showMenuButton) const SizedBox(width: 10),
                      Expanded(
                        child: _HeaderTitleBlock(
                          title: title,
                          subtitle: subtitle,
                          icon: icon,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _HeaderProfileBlock(
                        name: profileName,
                        subtitle: profileSubtitle,
                        avatarUrl: profileAvatarUrl,
                        onRefreshPressed: onRefreshPressed,
                        onLogoutPressed: onLogoutPressed,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HeaderDateChip(label: dateLabel),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.start,
                    children: headerActions,
                  ),
                ],
              )
            : Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.start,
                children: [
                  _HeaderTitleBlock(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                  ),
                  _HeaderDateChip(label: dateLabel),
                  ...headerActions,
                  _HeaderProfileBlock(
                    name: profileName,
                    subtitle: profileSubtitle,
                    avatarUrl: profileAvatarUrl,
                    onRefreshPressed: onRefreshPressed,
                    onLogoutPressed: onLogoutPressed,
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  const _HeaderTitleBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: kPrimary, size: 22),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderDateChip extends StatelessWidget {
  const _HeaderDateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month_rounded,
              size: 15, color: kTextPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderProfileBlock extends StatelessWidget {
  const _HeaderProfileBlock({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    this.onRefreshPressed,
    this.onLogoutPressed,
    this.compact = false,
  });

  final String name;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onRefreshPressed;
  final VoidCallback? onLogoutPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 36.0 : 42.0;

    return PopupMenuButton<_HeaderProfileAction>(
      tooltip:
          '\u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062e\u0635\u064a',
      offset: const Offset(0, 12),
      color: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kStroke),
      ),
      onSelected: (action) {
        switch (action) {
          case _HeaderProfileAction.refresh:
            if (onRefreshPressed != null) {
              onRefreshPressed!();
            } else if (Get.currentRoute.isNotEmpty) {
              Get.offNamed(
                Get.currentRoute,
                arguments: Get.arguments,
                preventDuplicates: false,
              );
            }
            break;
          case _HeaderProfileAction.settings:
            Get.offNamed(
              DashboardRoutes.settings,
              preventDuplicates: false,
            );
            break;
          case _HeaderProfileAction.logout:
            onLogoutPressed?.call();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<_HeaderProfileAction>(
          value: _HeaderProfileAction.refresh,
          child: _PopupMenuActionTile(
            icon: Icons.refresh_rounded,
            label:
                '\u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a',
          ),
        ),
        PopupMenuItem<_HeaderProfileAction>(
          value: _HeaderProfileAction.settings,
          child: _PopupMenuActionTile(
            icon: Icons.settings_rounded,
            label:
                '\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u062d\u0633\u0627\u0628',
          ),
        ),
        PopupMenuItem<_HeaderProfileAction>(
          value: _HeaderProfileAction.logout,
          child: _PopupMenuActionTile(
            icon: Icons.logout_rounded,
            label:
                '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c',
            color: Color(0xFFB42318),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: kTextSecondary, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ProfileAvatar(size: avatarSize, url: avatarUrl),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.size,
    this.url,
  });

  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F2),
        shape: BoxShape.circle,
        border: Border.all(color: kStroke),
      ),
      child: hasUrl
          ? ClipOval(
              child: AppNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholderIcon: Icons.person_rounded,
              ),
            )
          : Icon(Icons.person_rounded,
              color: kTextSecondary, size: size * 0.55),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kStroke),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
      ),
    );
  }
}

enum _HeaderProfileAction {
  refresh,
  settings,
  logout,
}

class _PopupMenuActionTile extends StatelessWidget {
  const _PopupMenuActionTile({
    required this.icon,
    required this.label,
    this.color = kTextPrimary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

DashboardAuthController? _maybeAuth() {
  if (!Get.isRegistered<DashboardAuthController>()) {
    return null;
  }
  return Get.find<DashboardAuthController>();
}

String _formatArabicDate(DateTime date) {
  const months = [
    '\u064a\u0646\u0627\u064a\u0631',
    '\u0641\u0628\u0631\u0627\u064a\u0631',
    '\u0645\u0627\u0631\u0633',
    '\u0623\u0628\u0631\u064a\u0644',
    '\u0645\u0627\u064a\u0648',
    '\u064a\u0648\u0646\u064a\u0648',
    '\u064a\u0648\u0644\u064a\u0648',
    '\u0623\u063a\u0633\u0637\u0633',
    '\u0633\u0628\u062a\u0645\u0628\u0631',
    '\u0623\u0643\u062a\u0648\u0628\u0631',
    '\u0646\u0648\u0641\u0645\u0628\u0631',
    '\u062f\u064a\u0633\u0645\u0628\u0631',
  ];

  return '\u0627\u0644\u064a\u0648\u0645 ${date.day} ${months[date.month - 1]} ${date.year}';
}

int _inferSidebarIndex(String title, String subtitle, IconData icon) {
  final text = '$title $subtitle ${icon.codePoint}'.toLowerCase();
  if (_containsAny(
      text, ['home', 'dashboard', '\u0627\u0644\u0631\u0626\u064a\u0633']))
    return 0;
  if (_containsAny(text, ['scheduled', '\u0645\u062c\u062f\u0648\u0644']))
    return 2;
  if (_containsAny(
      text, ['states', 'status', '\u062d\u0627\u0644\u0627\u062a'])) return 3;
  if (_containsAny(text, ['delivery', '\u062a\u0633\u0644\u064a\u0645']))
    return 4;
  if (_containsAny(
      text, ['menu', 'item', 'product', '\u0645\u0646\u062a\u062c'])) return 5;
  if (_containsAny(text, ['coupon', 'discount', '\u0639\u0631\u0648\u0636']))
    return 6;
  if (_containsAny(text, ['hours', '\u0623\u0648\u0642\u0627\u062a'])) return 7;
  if (_containsAny(
      text, ['reviews', 'ratings', '\u062a\u0642\u064a\u064a\u0645'])) return 8;
  if (_containsAny(text, [
    'analytics',
    'profit',
    'sales',
    'ledger',
    '\u062a\u0642\u0627\u0631\u064a\u0631'
  ])) return 9;
  if (_containsAny(
      text, ['settings', 'profile', '\u0625\u0639\u062f\u0627\u062f']))
    return 11;
  if (_containsAny(text, ['order', '\u0637\u0644\u0628'])) return 1;
  return 0;
}

bool _containsAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle)) return true;
  }
  return false;
}

List<Map<String, dynamic>> _filteredSidebarItems(
  List<Map<String, dynamic>> source,
) {
  final filtered = <Map<String, dynamic>>[];

  for (final item in source) {
    final copy = Map<String, dynamic>.from(item);
    if (copy['title'] is String) {
      copy['title'] = _repairMojibake(copy['title'] as String);
    }
    final arguments = copy['arguments'];
    final argumentsMap = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : <String, dynamic>{};
    argumentsMap['sidebarIndex'] = filtered.length;
    copy['arguments'] = argumentsMap;
    filtered.add(copy);
  }

  return filtered;
}

String _repairMojibake(String value) {
  var repaired = value;
  for (var attempt = 0; attempt < 3; attempt++) {
    final looksCorrupted = repaired.contains('\u00d8') ||
        repaired.contains('\u00d9') ||
        repaired.contains('\u00c3');
    if (!looksCorrupted) break;
    try {
      repaired = utf8.decode(latin1.encode(repaired));
    } catch (_) {
      break;
    }
  }
  return repaired;
}

const List<Map<String, dynamic>> _defaultSidebarItems = [
  {
    'title':
        '\u0627\u0644\u0635\u0641\u062d\u0629 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
    'icon': Icons.home_rounded,
    'route': DashboardRoutes.home,
    'arguments': {'sidebarIndex': 0}
  },
  {
    'title':
        '\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0637\u0644\u0628\u0627\u062a',
    'icon': Icons.receipt_long_rounded,
    'route': DashboardRoutes.orders,
    'arguments': {
      'sidebarIndex': 1,
      'shellTitle':
          '\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0637\u0644\u0628\u0627\u062a',
      'shellSubtitle':
          '\u0639\u0631\u0636 \u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u062c\u062f\u064a\u062f\u0629 \u0648\u0627\u0644\u062c\u0627\u0631\u064a\u0629 \u0648\u0627\u0644\u0645\u0643\u062a\u0645\u0644\u0629 \u0645\u0646 \u0645\u0643\u0627\u0646 \u0648\u0627\u062d\u062f.',
      'initialBucket': 'all'
    }
  },
  {
    'title':
        '\u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u062c\u062f\u0648\u0644\u0629',
    'icon': Icons.event_note_rounded,
    'route': DashboardRoutes.orders,
    'arguments': {
      'sidebarIndex': 2,
      'shellTitle':
          '\u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u062c\u062f\u0648\u0644\u0629',
      'shellSubtitle':
          '\u0627\u0633\u062a\u0639\u0631\u0636 \u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u062c\u062f\u0648\u0644\u0629 \u0641\u0642\u0637 \u0645\u0639 \u0645\u062a\u0627\u0628\u0639\u0629 \u062a\u0646\u0641\u064a\u0630\u0647\u0627.',
      'initialBucket': 'scheduled'
    }
  },
  {
    'title': '\u062d\u0627\u0644\u0627\u062a \u0627\u0644\u0637\u0644\u0628',
    'icon': Icons.layers_rounded,
    'route': DashboardRoutes.orderStatuses,
    'arguments': {
      'sidebarIndex': 3,
      'shellTitle':
          '\u062d\u0627\u0644\u0627\u062a \u0627\u0644\u0637\u0644\u0628',
      'shellSubtitle':
          '\u0627\u0633\u062a\u0639\u0631\u0636 \u0627\u0644\u0637\u0644\u0628\u0627\u062a \u062d\u0633\u0628 \u062d\u0627\u0644\u062a\u0647\u0627 \u0648\u062d\u062f\u0651\u062b \u0627\u0644\u062d\u0627\u0644\u0629 \u0645\u0628\u0627\u0634\u0631\u0629.',
      'initialBucket': 'all'
    }
  },
  {
    'title':
        '\u0627\u0644\u062a\u0633\u0644\u064a\u0645 \u0648\u0627\u0644\u0627\u0633\u062a\u0644\u0627\u0645',
    'icon': Icons.delivery_dining_rounded,
    'route': DashboardRoutes.deliveryOperations,
    'arguments': {'sidebarIndex': 4}
  },
  {
    'title':
        '\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0637\u0639\u0627\u0645',
    'icon': Icons.restaurant_menu_rounded,
    'route': DashboardRoutes.menu,
    'arguments': {'sidebarIndex': 5}
  },
  {
    'title': '\u0627\u0644\u0645\u062e\u0632\u0648\u0646',
    'icon': Icons.warehouse_rounded,
    'route': DashboardRoutes.inventory,
    'arguments': {'sidebarIndex': 10}
  },
  {
    'title':
        '\u0627\u0644\u0639\u0631\u0648\u0636 \u0648\u0627\u0644\u062a\u0633\u0648\u064a\u0642',
    'icon': Icons.local_offer_rounded,
    'route': DashboardRoutes.coupons,
    'arguments': {'sidebarIndex': 6}
  },
  {
    'title': '\u0623\u0648\u0642\u0627\u062a \u0627\u0644\u0639\u0645\u0644',
    'icon': Icons.schedule_rounded,
    'route': DashboardRoutes.hours,
    'arguments': {'sidebarIndex': 7}
  },
  {
    'title':
        '\u0627\u0644\u062a\u0642\u064a\u064a\u0645\u0627\u062a \u0648\u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0627\u062a',
    'icon': Icons.star_outline_rounded,
    'route': DashboardRoutes.reviews,
    'arguments': {'sidebarIndex': 8}
  },
  {
    'title':
        '\u0627\u0644\u062a\u0642\u0627\u0631\u064a\u0631 \u0648\u0627\u0644\u062a\u062d\u0644\u064a\u0644\u0627\u062a',
    'icon': Icons.query_stats_rounded,
    'route': DashboardRoutes.analytics,
    'arguments': {'sidebarIndex': 9}
  },
  {
    'title': '\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a',
    'icon': Icons.settings_rounded,
    'route': DashboardRoutes.settings,
    'arguments': {'sidebarIndex': 11}
  },
];

const List<Map<String, dynamic>> _masterSidebarItems = [
  {
    'title': '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
    'icon': Icons.home_rounded,
    'route': DashboardRoutes.home,
    'arguments': {'sidebarIndex': 0}
  },
  {
    'title':
        '\u0627\u0644\u0645\u0637\u0627\u0639\u0645 \u0648\u0627\u0644\u0645\u062a\u0627\u062c\u0631',
    'icon': Icons.storefront_rounded,
    'route': DashboardRoutes.masterVendors,
    'arguments': {'sidebarIndex': 1}
  },
  {
    'title': '\u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u0648\u0646',
    'icon': Icons.people_alt_rounded,
    'route': DashboardRoutes.masterUsers,
    'arguments': {'sidebarIndex': 2}
  },
  {
    'title': '\u0627\u0644\u0625\u0639\u0644\u0627\u0646\u0627\u062a',
    'icon': Icons.campaign_rounded,
    'route': DashboardRoutes.masterAds,
    'arguments': {'sidebarIndex': 3}
  },
  {
    'title': '\u0627\u0644\u0642\u0635\u0635',
    'icon': Icons.auto_stories_rounded,
    'route': DashboardRoutes.masterStories,
    'arguments': {'sidebarIndex': 4}
  },
  {
    'title': '\u0627\u0644\u0623\u0642\u0633\u0627\u0645',
    'icon': Icons.category_rounded,
    'route': DashboardRoutes.categories,
    'arguments': {'sidebarIndex': 5}
  },
  {
    'title': '\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a',
    'icon': Icons.settings_rounded,
    'route': DashboardRoutes.settings,
    'arguments': {'sidebarIndex': 11}
  },
];
