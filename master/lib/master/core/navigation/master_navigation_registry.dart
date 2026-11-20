part of '../../../../master_auth_app.dart';

final List<String> _masterRouteStack = <String>[];

class _MasterNavigatorObserver extends NavigatorObserver {
  void _remember(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || !name.startsWith('master:')) return;
    _masterRouteStack.remove(name);
    _masterRouteStack.add(name);
  }

  void _forget(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) _masterRouteStack.remove(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _remember(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _forget(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _forget(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _forget(oldRoute);
    _remember(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

final NavigatorObserver _masterNavigatorObserver = _MasterNavigatorObserver();

/// The single source of truth for the master dashboard's top-level modules.
///
/// Keeping the key and required permission here prevents each legacy workspace
/// from inventing a different sidebar or access rule.
class _MasterModuleDefinition {
  const _MasterModuleDefinition({
    required this.key,
    required this.label,
    required this.iconKey,
    this.permission,
  });

  final String key;
  final String label;
  final String iconKey;
  final String? permission;
}

const List<_MasterModuleDefinition> _masterModuleRegistry = [
  _MasterModuleDefinition(key: 'home', label: 'الرئيسية', iconKey: 'home'),
  _MasterModuleDefinition(
    key: 'operations',
    label: 'لوحة العمليات',
    iconKey: 'operations',
    permission: 'orders.view',
  ),
  _MasterModuleDefinition(
    key: 'orders',
    label: 'إدارة الطلبات',
    iconKey: 'orders',
    permission: 'orders.view',
  ),
  _MasterModuleDefinition(
    key: 'delivery',
    label: 'التوصيل واللوجستيات',
    iconKey: 'delivery',
    permission: 'drivers.view',
  ),
  _MasterModuleDefinition(
    key: 'restaurants',
    label: 'إدارة المطاعم',
    iconKey: 'restaurants',
    permission: 'restaurants.view',
  ),
  _MasterModuleDefinition(
    key: 'stores',
    label: 'إدارة المتاجر',
    iconKey: 'stores',
    permission: 'restaurants.view',
  ),
  _MasterModuleDefinition(
    key: 'users',
    label: 'العملاء',
    iconKey: 'users',
    permission: 'customers.view',
  ),
  _MasterModuleDefinition(
    key: 'finance',
    label: 'الإدارة المالية',
    iconKey: 'finance',
    permission: 'finance.view',
  ),
  _MasterModuleDefinition(
    key: 'marketing',
    label: 'التسويق والنمو',
    iconKey: 'marketing',
    permission: 'marketing.view',
  ),
  _MasterModuleDefinition(
    key: 'communication',
    label: 'مركز التواصل',
    iconKey: 'communication',
    permission: 'support.view',
  ),
  _MasterModuleDefinition(
    key: 'notifications',
    label: 'الإشعارات',
    iconKey: 'notifications',
    permission: 'notifications.view',
  ),
  _MasterModuleDefinition(
    key: 'reports',
    label: 'التقارير والتحليلات',
    iconKey: 'reports',
    permission: 'reports.view',
  ),
  _MasterModuleDefinition(
    key: 'settings',
    label: 'إعدادات المنصة',
    iconKey: 'settings',
    permission: 'settings.view',
  ),
  _MasterModuleDefinition(
    key: 'access',
    label: 'الإدارة والصلاحيات',
    iconKey: 'administration',
    permission: 'administration.view',
  ),
];

String _masterCanonicalModuleKey(String key) {
  switch (key) {
    case 'delivery_logistics':
    case 'logistics':
    case 'drivers':
      return 'delivery';
    case 'order':
    case 'order_management':
    case 'orders_management':
    case 'manage_orders':
      return 'orders';
    case 'customers':
      return 'users';
    case 'restaurant':
      return 'restaurants';
    case 'store':
      return 'stores';
    case 'administration':
    case 'governance':
      return 'access';
    case 'chat':
    case 'support':
    case 'quality':
      return 'communication';
    default:
      return key;
  }
}

bool _masterIsSuperAdmin(MasterSession session) {
  return session.master.adminRoleId == 1 ||
      session.master.role?.permissions.contains('super_admin') == true ||
      session.master.role?.permissions.contains('*') == true;
}

bool _masterSessionCanAccessModule(MasterSession session, String key) {
  final canonicalKey = _masterCanonicalModuleKey(key);
  if (canonicalKey == 'home' || _masterIsSuperAdmin(session)) {
    return true;
  }
  final module = _masterModuleRegistry
      .cast<_MasterModuleDefinition?>()
      .firstWhere((item) => item?.key == canonicalKey, orElse: () => null);
  final permission = module?.permission;
  if (permission == null) {
    return false;
  }
  return session.master.role?.permissions.contains(permission) == true;
}

void _navigateToMasterModuleSubPage(
  BuildContext context,
  String module,
  String subPage, {
  required MasterSession session,
  required Future<void> Function() onLogout,
  required MasterAuthApiService api,
  DateTime? serverNow,
}) {
  switch (module) {
    case 'restaurants':
      _navigateToMasterSection(
        context,
        key: 'restaurants',
        restaurantsSubPage: subPage,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'stores':
      _navigateToMasterSection(
        context,
        key: 'stores',
        restaurantsSubPage: subPage,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'users':
      _navigateToMasterSection(
        context,
        key: 'users',
        usersSubPage: subPage,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'finance':
      _navigateToMasterSection(
        context,
        key: 'finance',
        financeSubPage: subPage,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'marketing':
      _navigateToMasterSection(
        context,
        key: 'marketing',
        marketingSubPage: subPage,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'communication':
      _navigateToMasterSection(
        context,
        key: 'communication',
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
  }
}

List<_DashboardMenuItemData> _masterFilterSidebarItems(
  MasterSession session,
  List<_DashboardMenuItemData> source,
) {
  final selectedKeys = <String>{
    for (final item in source)
      if (item.selected) _masterCanonicalModuleKey(item.iconKey),
  };
  return [
    for (final module in _masterModuleRegistry)
      if (_masterSessionCanAccessModule(session, module.key))
        _DashboardMenuItemData(
          iconKey: module.iconKey,
          label: module.label,
          selected: selectedKeys.contains(module.key),
        ),
  ];
}

/// Shared frame used by every master module while legacy module internals are
/// migrated. A module supplies content only; header, navigation and responsive
/// behavior stay identical across the application.
// Used by the module migrations; keep it available while legacy screens are
// moved to the shared frame one module at a time.
// ignore: unused_element
Widget _buildMasterUnifiedShell({
  required BuildContext context,
  required MasterSession session,
  required Future<void> Function() onLogout,
  required MasterAuthApiService api,
  required List<_DashboardMenuItemData> sidebarItems,
  required ValueChanged<String> onSidebarItemTap,
  required Widget child,
  required String statusLabel,
  required String platformTitle,
  required String platformSubtitle,
  DateTime? serverNow,
  int notificationBadge = 0,
  VoidCallback? onNotificationsTap,
  String activeOrderSubPage = 'all',
  String activeDeliverySubPage = 'drivers',
  ValueChanged<String>? onDeliverySubPageTap,
  void Function(String module, String subPage)? onModuleSubPageTap,
}) {
  return _MasterResponsiveShell(
    session: session,
    api: api,
    onLogout: onLogout,
    sidebarItems: sidebarItems,
    onSidebarItemTap: onSidebarItemTap,
    statusLabel: statusLabel,
    platformTitle: platformTitle,
    platformSubtitle: platformSubtitle,
    serverNow: serverNow,
    notificationBadge: notificationBadge,
    onNotificationsTap: onNotificationsTap,
    activeOrderSubPage: activeOrderSubPage,
    activeDeliverySubPage: activeDeliverySubPage,
    onDeliverySubPageTap: onDeliverySubPageTap,
    onModuleSubPageTap: onModuleSubPageTap,
    child: child,
  );
}

class _MasterResponsiveShell extends StatefulWidget {
  const _MasterResponsiveShell({
    required this.session,
    required this.api,
    required this.onLogout,
    required this.sidebarItems,
    required this.onSidebarItemTap,
    required this.child,
    required this.statusLabel,
    required this.platformTitle,
    required this.platformSubtitle,
    required this.serverNow,
    required this.notificationBadge,
    required this.onNotificationsTap,
    required this.activeOrderSubPage,
    required this.activeDeliverySubPage,
    required this.onDeliverySubPageTap,
    required this.onModuleSubPageTap,
  });

  final MasterSession session;
  final MasterAuthApiService api;
  final Future<void> Function() onLogout;
  final List<_DashboardMenuItemData> sidebarItems;
  final ValueChanged<String> onSidebarItemTap;
  final Widget child;
  final String statusLabel;
  final String platformTitle;
  final String platformSubtitle;
  final DateTime? serverNow;
  final int notificationBadge;
  final VoidCallback? onNotificationsTap;
  final String activeOrderSubPage;
  final String activeDeliverySubPage;
  final ValueChanged<String>? onDeliverySubPageTap;
  final void Function(String module, String subPage)? onModuleSubPageTap;

  @override
  State<_MasterResponsiveShell> createState() => _MasterResponsiveShellState();
}

class _MasterResponsiveShellState extends State<_MasterResponsiveShell> {
  bool _sidebarHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Image.asset(
                  'assets/img/homeing.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wideLayout = constraints.maxWidth >= 1120;
                    final expandedWidth = constraints.maxWidth >= 1450
                        ? 292.0
                        : 270.0;
                    final sidebarWidth = wideLayout
                        ? (_sidebarHovered ? expandedWidth : 76.0)
                        : expandedWidth;
                    final sidebar = MouseRegion(
                      onEnter: (_) {
                        if (wideLayout) setState(() => _sidebarHovered = true);
                      },
                      onExit: (_) {
                        if (wideLayout) setState(() => _sidebarHovered = false);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: sidebarWidth,
                        child: _MasterDashboardSidebar(
                          items: widget.sidebarItems,
                          collapsed: wideLayout && !_sidebarHovered,
                          onItemTap: widget.onSidebarItemTap,
                          onOrderSubPageTap: (key) =>
                              _navigateToMasterOrderSubPage(
                                context,
                                key,
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: widget.serverNow ?? DateTime.now(),
                              ),
                          activeOrderSubPage: widget.activeOrderSubPage,
                          activeDeliverySubPage: widget.activeDeliverySubPage,
                          onDeliverySubPageTap:
                              widget.onDeliverySubPageTap ??
                              (key) => _navigateToDeliverySubPage(
                                context,
                                key: key,
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: widget.serverNow ?? DateTime.now(),
                              ),
                          onModuleSubPageTap:
                              widget.onModuleSubPageTap ??
                              (module, subPage) =>
                                  _navigateToMasterModuleSubPage(
                                    context,
                                    module,
                                    subPage,
                                    session: widget.session,
                                    onLogout: widget.onLogout,
                                    api: widget.api,
                                    serverNow: widget.serverNow,
                                  ),
                        ),
                      ),
                    );
                    final content = Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                      child: widget.child,
                    );

                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _MasterDashboardTopBar(
                            displayName: widget.session.master.adminName,
                            roleLabel:
                                widget.session.master.role?.roleName ?? '',
                            notificationBadge: widget.notificationBadge,
                            serverNow: widget.serverNow,
                            statusLabel: widget.statusLabel,
                            platformTitle: widget.platformTitle,
                            platformSubtitle: widget.platformSubtitle,
                            onLogout: widget.onLogout,
                            onSupportChatTap: () => _openMasterSupportChats(
                              context,
                              serverNow: widget.serverNow,
                            ),
                            onNotificationsTap: widget.onNotificationsTap,
                          ),
                        ),
                        Expanded(
                          child: wideLayout
                              ? Row(
                                  textDirection: TextDirection.rtl,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    sidebar,
                                    Expanded(child: content),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(child: content),
                                    SizedBox(height: 260, child: sidebar),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
