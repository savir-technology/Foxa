// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterDashboardPage extends StatefulWidget {
  const MasterDashboardPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;

  @override
  State<MasterDashboardPage> createState() => _MasterDashboardPageState();
}

class _MasterDashboardPageState extends State<MasterDashboardPage> {
  late Future<_MasterDashboardHomeData> _dashboardFuture;
  Timer? _dashboardRefreshTimer;
  _MasterDashboardHomeData? _lastDashboard;
  String _dashboardZone = 'all';
  String _dashboardPeriod = 'today';
  DateTime _dashboardDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardHome();
    _dashboardRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _reloadDashboard(),
    );
  }

  @override
  void dispose() {
    _dashboardRefreshTimer?.cancel();
    super.dispose();
  }

  void _reloadDashboard() {
    if (!mounted) return;
    setState(() {
      _dashboardFuture = _loadDashboardHome();
    });
  }

  Future<_MasterDashboardHomeData> _loadDashboardHome() {
    return widget.api
        ._fetchDashboardHome(
          widget.session.token,
          zone: _dashboardZone,
          period: _dashboardPeriod,
          date: _dashboardDate,
        )
        .timeout(const Duration(seconds: 20))
        .then((data) {
          _lastDashboard = data;
          return data;
        });
  }

  void _applyDashboardFilters({String? zone, String? period, DateTime? date}) {
    setState(() {
      if (zone != null) _dashboardZone = zone;
      if (period != null) _dashboardPeriod = period;
      if (date != null) _dashboardDate = date;
      _dashboardFuture = _loadDashboardHome();
    });
  }

  Widget _buildLoadingView() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFDFD), Color(0xFFF7F8FA), Color(0xFFF4F6F8)],
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.8),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFDFD), Color(0xFFF7F8FA), Color(0xFFF4F6F8)],
          ),
        ),
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7ECE8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: Color(0xFFD92C2C),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تعذر تحميل لوحة التحكم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E232A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7680),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _reloadDashboard,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _rememberMasterRuntime(widget.session, widget.onLogout, widget.api);
    return FutureBuilder<_MasterDashboardHomeData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final dashboard = snapshot.data ?? _lastDashboard;
        if (dashboard == null &&
            snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingView();
        }

        if (snapshot.hasError || dashboard == null) {
          return _buildErrorView(snapshot.error?.toString() ?? 'Unknown error');
        }

        final data = dashboard;
        /*
              serverNow: null,
              platformTitle: 'لوحة تحكم صاحب المنصة',
              platformSubtitle: 'Platform Control Center',
              displayName: widget.session.master.adminName,
              roleLabel: widget.session.master.role?.roleName ?? 'مدير المنصة',
              notificationBadge: 0,
              statusLabel: 'جميع الخدمات تعمل',
              alertCount: 0,
              alertMessage: 'لا توجد تنبيهات حالياً',
              sidebarItems: const [
                _DashboardMenuItemData(
                  iconKey: 'home',
                  label: 'الرئيسية',
                  selected: true,
                ),
                _DashboardMenuItemData(
                  iconKey: 'operations',
                  label: 'لوحة العمليات',
                  selected: false,
                ),
              ],
              stats: const [],
              sections: const [],
              statusItems: const [],
              footerVersion: 'FOXA Platform v1.0.0',
            );
        */

        final master = widget.session.master;
        final displayName = data.displayName.trim().isNotEmpty
            ? data.displayName.trim()
            : (master.adminName.trim().isNotEmpty
                  ? master.adminName.trim()
                  : (master.adminEmail.trim().isNotEmpty
                        ? master.adminEmail.trim()
                        : 'Admin #${master.adminId}'));
        // ignore: unused_local_variable
        final roleLabel = data.roleLabel.trim().isNotEmpty
            ? data.roleLabel.trim()
            : (master.role?.roleName.trim().isNotEmpty == true
                  ? master.role!.roleName
                  : 'مدير المنصة');
        final sidebarItems = _masterFilterSidebarItems(
          widget.session,
          data.sidebarItems,
        );
        final stats = data.stats;
        final sections = data.sections;
        final alertCount = data.alertCount;
        final alertMessage = data.alertMessage;
        final serverNow = data.serverNow;
        final statusLabel = data.statusLabel;
        final platformTitle = data.platformTitle;
        final platformSubtitle = data.platformSubtitle;
        final footerVersion = data.footerVersion;
        final notificationBadge = data.notificationBadge;
        final statusItems = data.statusItems;

        void openSidebarItem(String itemKey) {
          final key = _masterCanonicalModuleKey(itemKey);
          if (key == 'home') {
            return;
          }
          if (key == 'activity' || key == 'live_activity') {
            _navigateToMasterSection(
              context,
              key: 'operations',
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: serverNow,
              replace: false,
              operationsSubSection: 'activity',
            );
            return;
          }
          _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
            replace: false,
          );
        }

        void openSection(String sectionKey) {
          final key = _masterCanonicalModuleKey(sectionKey);
          if (key == 'activity' || key == 'live_activity') {
            _navigateToMasterSection(
              context,
              key: 'operations',
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: serverNow,
              replace: false,
              operationsSubSection: 'activity',
            );
            return;
          }
          _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
            replace: false,
          );
        }

        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: openSidebarItem,
          statusLabel: statusLabel,
          platformTitle: platformTitle,
          platformSubtitle: platformSubtitle,
          serverNow: serverNow,
          notificationBadge: notificationBadge,
          onNotificationsTap: () => _navigateToMasterSection(
            context,
            key: 'notifications',
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
            replace: false,
          ),
          child: _MasterDashboardContent(
            displayName: displayName,
            alertCount: alertCount,
            alertMessage: alertMessage,
            stats: stats,
            sections: sections,
            serverNow: serverNow,
            statusItems: statusItems,
            footerVersion: footerVersion,
            onSectionTap: openSection,
            selectedZone: _dashboardZone,
            selectedPeriod: _dashboardPeriod,
            selectedDate: _dashboardDate,
            onFiltersChanged: _applyDashboardFilters,
            availableZones: data.availableZones,
          ),
        );

        /* Legacy dashboard frame retained below for reference during migration.
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDFDFD),
                  Color(0xFFF7F8FA),
                  Color(0xFFF4F6F8),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wideLayout = constraints.maxWidth >= 1120;
                    final sidebarWidth = constraints.maxWidth >= 1450
                        ? 246.0
                        : 232.0;
                    final dashboardBodyHeight = constraints.maxHeight + 120.0;

                    return Column(
                      children: [
                        _MasterDashboardTopBar(
                          displayName: displayName,
                          roleLabel: roleLabel,
                          notificationBadge: notificationBadge,
                          serverNow: serverNow,
                          statusLabel: statusLabel,
                          platformTitle: platformTitle,
                          platformSubtitle: platformSubtitle,
                          onLogout: widget.onLogout,
                          onSupportChatTap: () =>
                              _openMasterSupportChats(context, serverNow: serverNow),
                          onNotificationsTap: () => _navigateToMasterSection(
                            context,
                            key: 'notifications',
                            session: widget.session,
                            onLogout: widget.onLogout,
                            api: widget.api,
                            serverNow: serverNow,
                            replace: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              height: dashboardBodyHeight,
                              child: wideLayout
                                  ? Row(
                                      textDirection: TextDirection.rtl,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          width: sidebarWidth,
                                          child: _MasterDashboardSidebar(
                                            items: sidebarItems,
                                            onItemTap: openSidebarItem,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _MasterDashboardContent(
                                            displayName: displayName,
                                            alertCount: alertCount,
                                            alertMessage: alertMessage,
                                            stats: stats,
                                            sections: sections,
                                            serverNow: serverNow,
                                            statusItems: statusItems,
                                            footerVersion: footerVersion,
                                            onSectionTap: openSection,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: _MasterDashboardContent(
                                            displayName: displayName,
                                            alertCount: alertCount,
                                            alertMessage: alertMessage,
                                            stats: stats,
                                            sections: sections,
                                            serverNow: serverNow,
                                            statusItems: statusItems,
                                            footerVersion: footerVersion,
                                            onSectionTap: openSection,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 260,
                                          child: _MasterDashboardSidebar(
                                            items: sidebarItems,
                                            onItemTap: openSidebarItem,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ); */
      },
    );
  }
}

class _DashboardMenuItemData {
  const _DashboardMenuItemData({
    required this.iconKey,
    required this.label,
    this.selected = false,
  });

  final String iconKey;
  final String label;
  final bool selected;

  IconData get icon => _iconFromKey(iconKey);

  factory _DashboardMenuItemData.fromJson(Map<String, dynamic> json) {
    return _DashboardMenuItemData(
      iconKey: (json['icon_key'] ?? json['icon'] ?? 'home').toString(),
      label: (json['label'] ?? '').toString(),
      selected: json['selected'] == true || json['selected'] == 1,
    );
  }
}

class _DashboardStatData {
  const _DashboardStatData({
    required this.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trendValue,
    required this.trendDirection,
    required this.iconKey,
    required this.accent,
    required this.iconBackground,
    this.valueSuffix,
  });

  final String key;
  final String title;
  final String value;
  final String subtitle;
  final String trendValue;
  final String trendDirection;
  final String iconKey;
  final Color accent;
  final Color iconBackground;
  final String? valueSuffix;

  IconData get icon => _iconFromKey(iconKey);

  bool get trendIsPositive => trendDirection.toLowerCase() != 'down';

  factory _DashboardStatData.fromJson(Map<String, dynamic> json) {
    return _DashboardStatData(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      trendValue: (json['trend_value'] ?? '0%').toString(),
      trendDirection: (json['trend_direction'] ?? 'up').toString(),
      iconKey: (json['icon_key'] ?? json['icon'] ?? 'finance').toString(),
      accent: _hexToColor((json['accent_hex'] ?? '#3B82F6').toString()),
      iconBackground: _hexToColor(
        (json['icon_background_hex'] ?? '#EEF2FF').toString(),
        fallback: const Color(0xFFF1F5FF),
      ),
      valueSuffix: _normalizeMasterCurrency(json['value_suffix']?.toString()),
    );
  }
}

String? _normalizeMasterCurrency(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  if (text.contains('ل.س') ||
      text.contains('د.س') ||
      text.contains('ليرة') ||
      text.toLowerCase().contains('syp')) {
    return '${MasterCurrency.symbol}';
  }
  return text;
}

class _DashboardSectionData {
  const _DashboardSectionData({
    required this.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.pagesCount,
    required this.actionLabel,
    required this.iconKey,
    required this.accent,
    required this.iconBackground,
    required this.actionColor,
    this.enabled = true,
  });

  final String key;
  final int index;
  final String title;
  final String subtitle;
  final String pagesCount;
  final String actionLabel;
  final String iconKey;
  final Color accent;
  final Color iconBackground;
  final Color actionColor;
  final bool enabled;

  IconData get actionIcon => _iconFromKey(iconKey);

  factory _DashboardSectionData.fromJson(Map<String, dynamic> json) {
    return _DashboardSectionData(
      key: (json['section_key'] ?? json['key'] ?? '').toString(),
      index: _toInt(json['index']),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      pagesCount: (json['pages_count'] ?? '').toString(),
      actionLabel: (json['action_label'] ?? '').toString(),
      iconKey: (json['icon_key'] ?? 'home').toString(),
      accent: _hexToColor((json['accent_hex'] ?? '#3B82F6').toString()),
      iconBackground: _hexToColor(
        (json['icon_background_hex'] ?? '#EEF2FF').toString(),
        fallback: const Color(0xFFF1F5FF),
      ),
      actionColor: _hexToColor(
        (json['action_color_hex'] ?? '#3B82F6').toString(),
      ),
      enabled: json['enabled'] == true || json['enabled'] == 1,
    );
  }
}

class _DashboardStatusItemData {
  const _DashboardStatusItemData({
    required this.label,
    required this.isHealthy,
    required this.dotHex,
  });

  final String label;
  final bool isHealthy;
  final String dotHex;

  Color get dotColor => _hexToColor(
    dotHex,
    fallback: isHealthy ? const Color(0xFF1A8B4A) : const Color(0xFFD92C2C),
  );

  factory _DashboardStatusItemData.fromJson(Map<String, dynamic> json) {
    return _DashboardStatusItemData(
      label: (json['label'] ?? '').toString(),
      isHealthy: json['is_healthy'] == true || json['is_healthy'] == 1,
      dotHex: (json['dot_hex'] ?? '#1A8B4A').toString(),
    );
  }
}

class _MasterDashboardTopBar extends StatelessWidget {
  const _MasterDashboardTopBar({
    required this.displayName,
    required this.roleLabel,
    required this.notificationBadge,
    required this.serverNow,
    required this.statusLabel,
    required this.platformTitle,
    required this.platformSubtitle,
    required this.onLogout,
    required this.onSupportChatTap,
    this.onNotificationsTap,
  });

  final String displayName;
  final String roleLabel;
  final int notificationBadge;
  final DateTime? serverNow;
  final String statusLabel;
  final String platformTitle;
  final String platformSubtitle;
  final Future<void> Function() onLogout;
  final VoidCallback onSupportChatTap;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE7ECE8))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            _MasterProfileChip(
              displayName: displayName,
              roleLabel: roleLabel,
              onLogout: onLogout,
            ),
            const SizedBox(width: 24),
            const SizedBox(width: 318, child: _MasterSearchField()),
            const SizedBox(width: 18),
            _MasterTopIconButton(
              icon: Icons.notifications_none_rounded,
              badge: notificationBadge > 0
                  ? notificationBadge.toString()
                  : null,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: 14),
            _MasterTopIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onSupportChatTap,
            ),
            const SizedBox(width: 14),
            _MasterDateBlock(serverNow: serverNow),
            const SizedBox(width: 18),
            _MasterStatusPill(label: statusLabel),
            const SizedBox(width: 28),
            _MasterPlatformTitle(
              title: platformTitle,
              subtitle: platformSubtitle,
            ),
            const SizedBox(width: 18),
            Container(width: 1, height: 36, color: const Color(0xFFF0F1F2)),
            const SizedBox(width: 18),
            const MasterBrandMark(width: 112, height: 48),
          ],
        ),
      ),
    );
  }
}

class _MasterProfileChip extends StatelessWidget {
  const _MasterProfileChip({
    required this.displayName,
    required this.roleLabel,
    required this.onLogout,
  });

  final String displayName;
  final String roleLabel;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'الملف الشخصي',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: 8),
              Text('تسجيل الخروج'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          textDirection: TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A8B4A), Color(0xFF0F6A3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5F2E9), width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20242A),
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F9D51),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 9.6,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF66707A),
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF525A64),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterSearchField extends StatelessWidget {
  const _MasterSearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E8E5)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          const Icon(Icons.search_rounded, size: 16, color: Color(0xFF6B737D)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'بحث شامل...',
              style: TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
                color: Color(0xFF98A0A8),
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE5E8E5)),
            ),
            child: const Text(
              '⌘ K',
              style: TextStyle(
                fontSize: 9.6,
                fontWeight: FontWeight.w700,
                color: Color(0xFF707781),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterTopIconButton extends StatelessWidget {
  const _MasterTopIconButton({required this.icon, this.badge, this.onTap});

  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = _masterTopIconLabel(icon);
    return Tooltip(
      message: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E8E5)),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF4E5660)),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFD92C2C),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _masterTopIconLabel(IconData icon) {
  if (icon == Icons.notifications_none_rounded ||
      icon == Icons.notifications_active_outlined) {
    return 'الإشعارات';
  }
  if (icon == Icons.chat_bubble_outline_rounded) {
    return 'الرسائل';
  }
  if (icon == Icons.settings_outlined) {
    return 'الإعدادات';
  }
  if (icon == Icons.fullscreen_rounded) {
    return 'ملء الشاشة';
  }
  return 'الأداة';
}

class _MasterDateBlock extends StatelessWidget {
  const _MasterDateBlock({required this.serverNow});

  final DateTime? serverNow;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatArabicDateLabel(serverNow);
    final timeLabel = _formatArabicTimeLabel(serverNow);

    return Tooltip(
      message: _formatArabicDateTime(serverNow),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Color(0xFF4E5660),
          ),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 10.9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B424A),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6D7580),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasterStatusPill extends StatelessWidget {
  const _MasterStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9EBDD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Color(0xFF1A8B4A),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              color: _kPrimaryGreen,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterPlatformTitle extends StatelessWidget {
  const _MasterPlatformTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 16.2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E232A),
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 9.8,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6D7580),
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MasterDashboardSidebar extends StatelessWidget {
  const _MasterDashboardSidebar({
    required this.items,
    this.onItemTap,
    this.onOrderSubPageTap,
    this.activeOrderSubPage = 'all',
    this.onDeliverySubPageTap,
    this.activeDeliverySubPage = 'drivers',
    this.onModuleSubPageTap,
    this.collapsed = false,
  });

  final List<_DashboardMenuItemData> items;
  final void Function(String itemKey)? onItemTap;
  final void Function(String subPageKey)? onOrderSubPageTap;
  final String activeOrderSubPage;
  final ValueChanged<String>? onDeliverySubPageTap;
  final String activeDeliverySubPage;
  final void Function(String module, String subPage)? onModuleSubPageTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: Color(0xFFE7ECE8))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final tile = _MasterSidebarTile(
                    item: item,
                    collapsed: collapsed,
                    onTap: onItemTap == null
                        ? null
                        : () => onItemTap!(item.iconKey),
                  );
                  if (item.iconKey != 'orders' ||
                      !item.selected ||
                      collapsed ||
                      onOrderSubPageTap == null) {
                    if (item.iconKey != 'delivery' ||
                        !item.selected ||
                        collapsed ||
                        onDeliverySubPageTap == null) {
                      final submenu = _masterModuleSubmenu(item.iconKey);
                      if (!item.selected ||
                          submenu.isEmpty ||
                          onModuleSubPageTap == null ||
                          collapsed) {
                        return tile;
                      }
                      return Column(
                        children: [
                          tile,
                          const SizedBox(height: 6),
                          _MasterGenericSidebarSubmenu(
                            items: submenu,
                            onTap: (key) =>
                                onModuleSubPageTap!(item.iconKey, key),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        tile,
                        const SizedBox(height: 6),
                        _MasterDeliverySidebarSubmenu(
                          activeSubPage: activeDeliverySubPage,
                          onTap: onDeliverySubPageTap!,
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      tile,
                      const SizedBox(height: 6),
                      _MasterOrdersSidebarSubmenu(
                        activeSubPage: activeOrderSubPage,
                        onTap: onOrderSubPageTap!,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _MasterOrdersSidebarSubmenu extends StatelessWidget {
  const _MasterOrdersSidebarSubmenu({
    required this.activeSubPage,
    required this.onTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const items = <(String, String, IconData)>[
      ('all', 'جميع الطلبات', Icons.radio_button_checked_rounded),
      ('statuses', 'حالات الطلبات', Icons.flag_outlined),
      ('scheduled', 'الطلبات المجدولة', Icons.event_note_outlined),
      ('pickup', 'طلبات الاستلام الذاتي', Icons.store_mall_directory_outlined),
      ('printing', 'الطباعة والفواتير', Icons.print_outlined),
      ('chats', 'محادثات الطلبات', Icons.chat_bubble_outline_rounded),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECE8)),
      ),
      child: Column(
        children: [
          for (final item in items)
            InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onTap(item.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      item.$3,
                      size: 15,
                      color: activeSubPage == item.$1
                          ? _kDeepGreen
                          : const Color(0xFF607069),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.$2,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.2,
                          color: activeSubPage == item.$1
                              ? _kDeepGreen
                              : Color(0xFF4E5A53),
                          fontWeight: activeSubPage == item.$1
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MasterDeliverySidebarSubmenu extends StatelessWidget {
  const _MasterDeliverySidebarSubmenu({
    required this.activeSubPage,
    required this.onTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const items = <(String, String, IconData)>[
      ('drivers', 'إدارة السائقين', Icons.manage_accounts_outlined),
      ('dispatch', 'توزيع الطلبات', Icons.assignment_ind_outlined),
      ('tracking', 'التتبع المباشر', Icons.location_on_outlined),
      ('zones', 'مناطق التوصيل', Icons.map_outlined),
      ('emergency', 'طوارئ السائقين', Icons.emergency_outlined),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECE8)),
      ),
      child: Column(
        children: [
          for (final item in items)
            InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onTap(item.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      item.$3,
                      size: 15,
                      color: activeSubPage == item.$1
                          ? _kDeepGreen
                          : const Color(0xFF607069),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.$2,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.2,
                          color: activeSubPage == item.$1
                              ? _kDeepGreen
                              : const Color(0xFF4E5A53),
                          fontWeight: activeSubPage == item.$1
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<(String, String, IconData)> _masterModuleSubmenu(String module) {
  switch (module) {
    case 'restaurants':
    case 'stores':
      return const [
        ('all', 'المطاعم والمتاجر', Icons.storefront_outlined),
        ('products', 'المنتجات والقائمة', Icons.inventory_2_outlined),
        ('categories', 'الأقسام والتصنيفات', Icons.category_outlined),
        ('offers', 'العروض والكوبونات', Icons.local_offer_outlined),
      ];
    case 'users':
      return const [
        ('users', 'كل العملاء', Icons.people_outline),
        ('wallets', 'محافظ العملاء', Icons.account_balance_wallet_outlined),
        ('addresses', 'العناوين', Icons.location_on_outlined),
        ('orders', 'طلبات العملاء', Icons.receipt_long_outlined),
      ];
    case 'finance':
      return const [
        ('wallets', 'المحفظة المالية', Icons.account_balance_wallet_outlined),
        ('accounting', 'المحاسبة والقيود', Icons.menu_book_outlined),
        ('fees', 'الرسوم والعمولات', Icons.payments_outlined),
        ('discounts', 'الخصومات والكوبونات', Icons.discount_outlined),
        ('refunds', 'الاستردادات', Icons.currency_exchange_outlined),
      ];
    case 'marketing':
      return const [
        ('offers', 'العروض', Icons.local_offer_outlined),
        ('campaigns', 'الحملات التسويقية', Icons.campaign_outlined),
        ('coupons', 'الكوبونات', Icons.confirmation_number_outlined),
        ('notifications', 'الإشعارات التسويقية', Icons.notifications_outlined),
      ];
    case 'communication':
      return const [
        ('support', 'مركز التواصل', Icons.support_agent_outlined),
        ('chats', 'محادثات العملاء', Icons.chat_bubble_outline_rounded),
      ];
    default:
      return const [];
  }
}

class _MasterGenericSidebarSubmenu extends StatelessWidget {
  const _MasterGenericSidebarSubmenu({
    required this.items,
    required this.onTap,
  });

  final List<(String, String, IconData)> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECE8)),
      ),
      child: Column(
        children: [
          for (final item in items)
            InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onTap(item.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(item.$3, size: 15, color: const Color(0xFF607069)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.$2,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.2,
                          color: Color(0xFF4E5A53),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MasterSidebarTile extends StatelessWidget {
  const _MasterSidebarTile({
    required this.item,
    this.onTap,
    this.collapsed = false,
  });

  final _DashboardMenuItemData item;
  final VoidCallback? onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSelected = item.selected;
        final compact = collapsed || constraints.maxWidth < 150;
        final child = Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? _kDeepGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE6EAE6),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _kDeepGreen.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: compact
              ? Center(
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF4F5862),
                  ),
                )
              : Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      item.icon,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4F5862),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4E5660),
                          height: 1.0,
                        ),
                      ),
                    ),
                    if (!isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: Color(0xFFB1B7BD),
                        ),
                      )
                    else
                      const SizedBox(width: 10),
                  ],
                ),
        );

        if (onTap == null) {
          return child;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: child,
          ),
        );
      },
    );
  }
}

class _MasterDashboardContent extends StatelessWidget {
  const _MasterDashboardContent({
    required this.displayName,
    required this.alertCount,
    required this.alertMessage,
    required this.stats,
    required this.sections,
    required this.serverNow,
    required this.statusItems,
    required this.footerVersion,
    required this.onSectionTap,
    required this.selectedZone,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onFiltersChanged,
    required this.availableZones,
  });

  final String displayName;
  final int alertCount;
  final String alertMessage;
  final List<_DashboardStatData> stats;
  final List<_DashboardSectionData> sections;
  final DateTime? serverNow;
  final List<_DashboardStatusItemData> statusItems;
  final String footerVersion;
  final void Function(String sectionKey) onSectionTap;
  final String selectedZone;
  final String selectedPeriod;
  final DateTime selectedDate;
  final void Function({String? zone, String? period, DateTime? date})
  onFiltersChanged;
  final List<_DashboardZoneData> availableZones;

  @override
  Widget build(BuildContext context) {
    final metricCards = _masterHomeMetricCards(stats, sections, alertCount);
    final liveItems = _masterHomeLiveItems(stats, sections, alertMessage);
    final alertCards = _masterHomeAlertCards(
      sections,
      alertCount,
      alertMessage,
    );
    final performanceItems = _masterHomePerformanceItems(stats);
    final mapMarkers = _masterHomeMapMarkers(stats);

    return LayoutBuilder(
      builder: (context, constraints) {
        final main = _MasterHomeMainColumn(
          metricCards: metricCards,
          performanceItems: performanceItems,
          alertCards: alertCards,
          mapMarkers: mapMarkers,
          statusItems: statusItems,
          footerVersion: footerVersion,
          serverNow: serverNow,
          onSectionTap: onSectionTap,
          selectedZone: selectedZone,
          selectedPeriod: selectedPeriod,
          selectedDate: selectedDate,
          onFiltersChanged: onFiltersChanged,
          liveItems: liveItems,
          availableZones: availableZones,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 22),
          child: Directionality(textDirection: TextDirection.rtl, child: main),
        );
      },
    );
  }
}

class _MasterHomeMainColumn extends StatelessWidget {
  const _MasterHomeMainColumn({
    required this.metricCards,
    required this.performanceItems,
    required this.alertCards,
    required this.mapMarkers,
    required this.statusItems,
    required this.footerVersion,
    required this.serverNow,
    required this.onSectionTap,
    required this.selectedZone,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onFiltersChanged,
    required this.liveItems,
    required this.availableZones,
  });

  final List<_DashboardStatData> metricCards;
  final List<_MasterHomeInfoItem> performanceItems;
  final List<_MasterHomeInfoItem> alertCards;
  final List<_OperationsMapMarkerData> mapMarkers;
  final List<_DashboardStatusItemData> statusItems;
  final String footerVersion;
  final DateTime? serverNow;
  final void Function(String sectionKey) onSectionTap;
  final String selectedZone;
  final String selectedPeriod;
  final DateTime selectedDate;
  final void Function({String? zone, String? period, DateTime? date})
  onFiltersChanged;
  final List<_MasterHomeInfoItem> liveItems;
  final List<_DashboardZoneData> availableZones;

  @override
  Widget build(BuildContext context) {
    final primaryCards = _masterHomePrimaryCards(metricCards);
    final secondaryCards = metricCards
        .where((card) => !primaryCards.contains(card))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 145,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _MasterHomeExecutiveBanner()),
              Positioned(
                top: 12,
                right: 14,
                child: _MasterHomeFiltersBar(
                  serverNow: serverNow,
                  selectedZone: selectedZone,
                  selectedPeriod: selectedPeriod,
                  selectedDate: selectedDate,
                  onFiltersChanged: onFiltersChanged,
                  availableZones: availableZones,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (const bool.fromEnvironment('showDashboardHeading'))
          const _MasterHomeSectionHeading(
            title: 'نبض المنصة',
            subtitle: 'الصورة الكاملة للعمليات والأداء في لحظة واحدة',
          ),
        const SizedBox(height: 10),
        _MasterHomeMetricGrid(cards: primaryCards, onCardTap: onSectionTap),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 820) {
              return Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MasterHomeInfoPanel(
                      title: 'التنبيهات العاجلة',
                      items: alertCards,
                      columns: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MasterHomeCompactOperations(mapMarkers: mapMarkers),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _MasterHomeInfoPanel(
                  title: 'التنبيهات العاجلة',
                  items: alertCards,
                  columns: 1,
                ),
                const SizedBox(height: 12),
                _MasterHomeCompactOperations(mapMarkers: mapMarkers),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 820) {
              return Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MasterHomeLiveActivityPanel(
                      items: liveItems,
                      onViewAll: () => onSectionTap('activity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 365,
                    child: _MasterHomeStatusChart(stats: metricCards),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _MasterHomeLiveActivityPanel(
                  items: liveItems,
                  onViewAll: () => onSectionTap('activity'),
                ),
                const SizedBox(height: 12),
                _MasterHomeStatusChart(stats: metricCards),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        if (secondaryCards.isNotEmpty)
          _MasterHomeSecondaryMetrics(
            cards: secondaryCards,
            onCardTap: onSectionTap,
          ),
        const SizedBox(height: 14),
        _MasterBottomStatusBar(
          items: statusItems,
          footerVersion: footerVersion,
        ),
      ],
    );
  }
}

class _MasterHomeExecutiveBanner extends StatelessWidget {
  const _MasterHomeExecutiveBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 145,
      child: Image.asset(
        'assets/img/delivery_banner.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: Color(0xFF9AA3AA),
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyBanner(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF0B5B49), Color(0xFF07372D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4B3D).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage(_kBackgroundAsset),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Offstage(
        offstage: true,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Color(0xFFB7F34A),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'مركز القيادة التنفيذي',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تابع أداء المنصة واتخذ القرار من شاشة واحدة',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFFD2E5DF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFB7F34A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF0B5B49)),
                  SizedBox(width: 6),
                  Text(
                    'النظام يعمل الآن',
                    style: TextStyle(
                      color: Color(0xFF07372D),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterHomeSectionHeading extends StatelessWidget {
  const _MasterHomeSectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF17231E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A8580),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 34,
          decoration: BoxDecoration(
            color: _kPrimaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}

class _MasterHomeCompactOperations extends StatelessWidget {
  const _MasterHomeCompactOperations({required this.mapMarkers});

  final List<_OperationsMapMarkerData> mapMarkers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EBE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الخريطة التشغيلية',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'متابعة التوزيع والحركة في الوقت الحالي',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A8580),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F6EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'مباشر',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _kPrimaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _LiveOperationsMap(
                markers: mapMarkers,
                showWeatherBadge: false,
                showLayerPanel: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterHomeSecondaryMetrics extends StatelessWidget {
  const _MasterHomeSecondaryMetrics({required this.cards, this.onCardTap});

  final List<_DashboardStatData> cards;
  final void Function(String sectionKey)? onCardTap;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      title: const Text(
        'كل المؤشرات',
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
      ),
      subtitle: const Text(
        'افتح لعرض التفاصيل الإضافية',
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 10, color: Color(0xFF7A8580)),
      ),
      children: [_MasterHomeMetricGrid(cards: cards, onCardTap: onCardTap)],
    );
  }
}

class _MasterHomeFiltersBar extends StatefulWidget {
  const _MasterHomeFiltersBar({
    required this.serverNow,
    required this.selectedZone,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onFiltersChanged,
    required this.availableZones,
  });

  final DateTime? serverNow;
  final String selectedZone;
  final String selectedPeriod;
  final DateTime selectedDate;
  final List<_DashboardZoneData> availableZones;
  final void Function({String? zone, String? period, DateTime? date})
  onFiltersChanged;

  @override
  State<_MasterHomeFiltersBar> createState() => _MasterHomeFiltersBarState();
}

class _MasterHomeFiltersBarState extends State<_MasterHomeFiltersBar> {
  Future<void> _pickZone() async {
    final options = <(String, String)>[
      ('all', 'جميع المناطق'),
      for (final zone in widget.availableZones)
        (
          zone.id,
          '${zone.label}${zone.city.isEmpty ? '' : ' - ${zone.city}'}'
              '${zone.vendorCount + zone.driverCount > 0 ? ' (${zone.vendorCount + zone.driverCount})' : ''}',
        ),
    ];
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _MasterFilterDialog<String>(
        title: 'اختيار المنطقة',
        selectedValue: widget.selectedZone,
        options: options,
      ),
    );
    if (value != null) widget.onFiltersChanged(zone: value);
  }

  Future<void> _pickPeriod() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _MasterFilterDialog<String>(
        title: 'الفترة الزمنية',
        selectedValue: widget.selectedPeriod,
        options: const [
          ('today', 'اليوم'),
          ('yesterday', 'أمس'),
          ('week', 'آخر 7 أيام'),
          ('month', 'هذا الشهر'),
        ],
      ),
    );
    if (value != null) widget.onFiltersChanged(period: value);
  }

  Future<void> _pickDate() async {
    final value = await showDialog<DateTime>(
      context: context,
      builder: (context) =>
          _MasterDatePickerDialog(initialDate: widget.selectedDate),
    );
    if (value != null) widget.onFiltersChanged(date: value);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatArabicDateLabel(widget.selectedDate);
    final legacyZoneLabel = switch (widget.selectedZone) {
      'north' => 'المنطقة الشمالية',
      'center' => 'المنطقة الوسطى',
      'south' => 'المنطقة الجنوبية',
      _ => 'جميع المناطق',
    };
    final selectedZone = widget.availableZones.firstWhere(
      (zone) => zone.id == widget.selectedZone,
      orElse: () => const _DashboardZoneData(id: '', label: ''),
    );
    final zoneLabel = selectedZone.label.isNotEmpty
        ? selectedZone.label
        : legacyZoneLabel;
    final periodLabel = switch (widget.selectedPeriod) {
      'yesterday' => 'أمس',
      'week' => 'آخر 7 أيام',
      'month' => 'هذا الشهر',
      _ => 'اليوم',
    };

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        _MasterHomeFilterButton(
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          onTap: () {
            widget.onFiltersChanged();
            _showMasterSnack(context, 'تم تحديث بيانات اللوحة');
          },
        ),
        _MasterHomeFilterButton(
          label: zoneLabel,
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: _pickZone,
        ),
        _MasterHomeFilterButton(
          label: dateLabel,
          icon: Icons.calendar_today_outlined,
          onTap: _pickDate,
        ),
        _MasterHomeFilterButton(
          label: periodLabel,
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: _pickPeriod,
        ),
      ],
    );
  }
}

class _MasterDatePickerDialog extends StatefulWidget {
  const _MasterDatePickerDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_MasterDatePickerDialog> createState() =>
      _MasterDatePickerDialogState();
}

class _MasterDatePickerDialogState extends State<_MasterDatePickerDialog> {
  late DateTime _selected;
  late DateTime _visibleMonth;

  static const _weekdays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leading = firstDay.weekday % 7;
    final cells = <Widget>[];
    for (var index = 0; index < leading; index++) {
      cells.add(const SizedBox(height: 42));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final isSelected =
          date.year == _selected.year &&
          date.month == _selected.month &&
          date.day == _selected.day;
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selected = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 42,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kPrimaryGreen
                  : isToday
                  ? const Color(0xFFEAF6ED)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: const Color(0xFF9BD2AA))
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w900
                      : FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF35423A),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 430,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2EBE5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6ED),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: _kPrimaryGreen,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'اختيار تاريخ البيانات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17231E),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'حدد اليوم الذي تريد عرض مؤشرات الأداء له',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF89948E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF7A8580),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE5ECE7)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: _kPrimaryGreen,
                    ),
                    Expanded(
                      child: Text(
                        '${_arabicMonthName(_visibleMonth.month)} ${_visibleMonth.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2C24),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: _kPrimaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final day in _weekdays)
                    Expanded(
                      child: Text(
                        day.substring(0, 1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF829087),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                childAspectRatio: 1.12,
                children: cells,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('تطبيق التاريخ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _arabicMonthName(int month) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return months[month - 1];
}

class _MasterFilterDialog<T> extends StatelessWidget {
  const _MasterFilterDialog({
    required this.title,
    required this.selectedValue,
    required this.options,
  });

  final String title;
  final T selectedValue;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 360,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4EBE6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: _kPrimaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17231E),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 19),
                    color: const Color(0xFF7A8580),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر القيمة التي تريد تطبيقها على اللوحة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF89948E),
                ),
              ),
              const SizedBox(height: 12),
              for (final option in options) ...[
                _MasterFilterOption<T>(
                  label: option.$2,
                  selected: option.$1 == selectedValue,
                  onTap: () => Navigator.of(context).pop(option.$1),
                ),
                const SizedBox(height: 7),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterFilterOption<T> extends StatelessWidget {
  const _MasterFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF6ED) : const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9BD2AA)
                  : const Color(0xFFE8EDE9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _kPrimaryGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _kPrimaryGreen : const Color(0xFFB9C4BD),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: selected
                        ? const Color(0xFF0B5B49)
                        : const Color(0xFF3D4942),
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

class _MasterHomeFilterButton extends StatelessWidget {
  const _MasterHomeFilterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 38,
        constraints: const BoxConstraints(minWidth: 104),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.3,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E5660),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 15, color: const Color(0xFF4E5660)),
          ],
        ),
      ),
    );
  }
}

class _MasterHomeMetricGrid extends StatelessWidget {
  const _MasterHomeMetricGrid({required this.cards, this.onCardTap});

  final List<_DashboardStatData> cards;
  final void Function(String sectionKey)? onCardTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 6
            : constraints.maxWidth >= 760
            ? 3
            : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _MasterHomeMetricCard(
                  stat: card,
                  onTap: onCardTap == null
                      ? null
                      : () => onCardTap!(_masterMetricTargetKey(card)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MasterHomeMetricCard extends StatelessWidget {
  const _MasterHomeMetricCard({required this.stat, this.onTap});

  final _DashboardStatData stat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trendColor = stat.trendIsPositive
        ? _kPrimaryGreen
        : const Color(0xFFD92C2C);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE8ECE8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.018),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: stat.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(stat.icon, size: 18, color: stat.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.4,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: stat.value,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E232A),
                            ),
                          ),
                          if ((stat.valueSuffix ?? '').isNotEmpty)
                            TextSpan(
                              text: ' ${stat.valueSuffix}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6F7680),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          stat.trendIsPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 11,
                          color: trendColor,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            stat.trendValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: trendColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            stat.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8.8,
                              color: Color(0xFF7A8088),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterHomeStatusChart extends StatelessWidget {
  const _MasterHomeStatusChart({required this.stats});

  final List<_DashboardStatData> stats;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String key, Color color})>[
      (
        label: 'قيد التحضير',
        key: 'orders_preparing',
        color: const Color(0xFF7C3AED),
      ),
      (
        label: 'جاهزة للاستلام',
        key: 'orders_ready_for_pickup',
        color: const Color(0xFF2563EB),
      ),
      (
        label: 'على الطريق',
        key: 'orders_on_route',
        color: const Color(0xFF14B8A6),
      ),
      (
        label: 'مكتملة اليوم',
        key: 'orders_completed_today',
        color: const Color(0xFF1E7D3F),
      ),
    ];
    final values = [for (final row in rows) _chartStatValue(stats, row.key)];
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'توزيع الطلبات',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            total == 0
                ? 'لا توجد بيانات كافية للرسم'
                : 'من إجمالي $total طلب حالي',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8580),
            ),
          ),
          const SizedBox(height: 15),
          for (var index = 0; index < rows.length; index++) ...[
            _MasterHomeChartRow(
              label: rows[index].label,
              value: values[index],
              percentage: total == 0
                  ? 0
                  : (values[index] / total * 100).round(),
              progress: maxValue == 0 ? 0 : values[index] / maxValue,
              color: rows[index].color,
            ),
            if (index != rows.length - 1) const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }
}

class _MasterHomeChartRow extends StatelessWidget {
  const _MasterHomeChartRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.progress,
    required this.color,
  });

  final String label;
  final int value;
  final int percentage;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$percentage%',
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF7A8580)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

int _chartStatValue(List<_DashboardStatData> stats, String key) {
  for (final stat in stats) {
    if (stat.key == key) {
      return int.tryParse(stat.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
  }
  return 0;
}

class _MasterHomeLiveActivityPanel extends StatelessWidget {
  const _MasterHomeLiveActivityPanel({
    required this.items,
    required this.onViewAll,
  });

  final List<_MasterHomeInfoItem> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Expanded(
                child: Text(
                  'النشاط المباشر',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: _kPrimaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _MasterHomeLiveItem(item: items[index]),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onViewAll,
              child: const Text('عرض كل النشاط'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterHomeLiveItem extends StatelessWidget {
  const _MasterHomeLiveItem({required this.item});

  final _MasterHomeInfoItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.background,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 9.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7680),
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

class _MasterHomeInfoPanel extends StatelessWidget {
  const _MasterHomeInfoPanel({
    required this.title,
    required this.items,
    required this.columns,
  });

  final String title;
  final List<_MasterHomeInfoItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12.6, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth < 420 ? 1 : columns;
              final spacing = 8.0;
              final width =
                  (constraints.maxWidth - spacing * (count - 1)) / count;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _MasterHomeInfoTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MasterHomeInfoTile extends StatelessWidget {
  const _MasterHomeInfoTile({required this.item});

  final _MasterHomeInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.background,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 15, color: item.color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9.2,
                    fontWeight: FontWeight.w700,
                    color: item.color,
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

class _MasterHomeInfoItem {
  const _MasterHomeInfoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
}

List<_DashboardStatData> _masterHomeMetricCards(
  List<_DashboardStatData> stats,
  List<_DashboardSectionData> sections,
  int alertCount,
) {
  final cards = <_DashboardStatData>[];
  final byKey = {for (final stat in stats) stat.key: stat};
  void add(_DashboardStatData stat) => cards.add(stat);

  add(
    byKey['orders_today'] ??
        _homeStat(
          'طلبات جديدة',
          '0',
          Icons.receipt_long_outlined,
          _kPrimaryGreen,
        ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['orders_waiting_restaurant', 'orders_pending_acceptance'],
      _homeStat(
        'بانتظار قبول المطعم',
        '0',
        Icons.hourglass_empty_rounded,
        const Color(0xFFF59E0B),
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['orders_preparing', 'orders_in_preparation'],
      _homeStat(
        'قيد التحضير',
        '0',
        Icons.shopping_bag_outlined,
        const Color(0xFF7C3AED),
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['orders_ready_for_pickup', 'orders_ready'],
      _homeStat(
        'جاهزة للاستلام',
        '0',
        Icons.delivery_dining_outlined,
        const Color(0xFF2563EB),
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['orders_on_route', 'orders_on_delivery'],
      _homeStat(
        'على الطريق',
        '0',
        Icons.route_outlined,
        const Color(0xFF14B8A6),
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['orders_completed_today', 'completed_today'],
      _homeStat(
        'مكتملة اليوم',
        '0',
        Icons.check_circle_outline_rounded,
        const Color(0xFF1E7D3F),
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['orders_cancelled_today', 'cancelled_today'],
      _homeStat(
        'ملغاة اليوم',
        '0',
        Icons.cancel_outlined,
        const Color(0xFFD92C2C),
        positive: false,
      ),
    ),
  );
  add(
    byKey['restaurants_open'] ??
        _homeStat(
          'المطاعم المفتوحة',
          '0',
          Icons.storefront_outlined,
          const Color(0xFFF59E0B),
        ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['restaurants_closed'],
      _homeStat(
        'المطاعم المغلقة',
        '0',
        Icons.store_mall_directory_outlined,
        const Color(0xFF64748B),
      ),
    ),
  );
  add(
    byKey['drivers_online'] ??
        _homeStat(
          'سائقون متاحون',
          '0',
          Icons.person_outline_rounded,
          _kPrimaryGreen,
        ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['drivers_busy', 'drivers_on_delivery'],
      _homeStat(
        'سائقون مشغولون',
        '0',
        Icons.person_search_outlined,
        const Color(0xFFF59E0B),
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['drivers_late', 'late_drivers'],
      _homeStat(
        'سائقون متأخرون',
        '0',
        Icons.person_off_outlined,
        const Color(0xFFD92C2C),
        positive: false,
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['users_new_today', 'customers_new_today'],
      _homeStat(
        'مستخدمون جدد',
        '0',
        Icons.groups_outlined,
        const Color(0xFF7C3AED),
      ),
    ),
  );
  add(
    byKey['revenue_today'] ??
        _homeStat(
          'مبيعات اليوم',
          '0',
          Icons.account_balance_wallet_outlined,
          _kPrimaryGreen,
          suffix: '${MasterCurrency.symbol}',
        ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['platform_commission_today', 'commission_today'],
      _homeStat(
        'عمولة المنصة',
        '0',
        Icons.percent_rounded,
        _kPrimaryGreen,
        suffix: '${MasterCurrency.symbol}',
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['delivery_fees_today', 'delivery_revenue_today'],
      _homeStat(
        'رسوم التوصيل',
        '0',
        Icons.delivery_dining_outlined,
        const Color(0xFF2563EB),
        suffix: '${MasterCurrency.symbol}',
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['refunds_due', 'compensations_due'],
      _homeStat(
        'التعويضات المستحقة',
        '0',
        Icons.local_offer_outlined,
        const Color(0xFFF97316),
        suffix: '${MasterCurrency.symbol}',
      ),
    ),
  );
  add(
    _dashboardStatOrFallback(
      byKey,
      const ['wallet_balances', 'wallet_balance'],
      _homeStat(
        'أرصدة المحفظة',
        '0',
        Icons.account_balance_wallet_outlined,
        const Color(0xFF7C3AED),
        suffix: '${MasterCurrency.symbol}',
      ),
    ),
  );

  return cards.take(18).toList();
}

List<_DashboardStatData> _masterHomePrimaryCards(
  List<_DashboardStatData> cards,
) {
  const preferredKeys = [
    'revenue_today',
    'orders_today',
    'orders_preparing',
    'restaurants_open',
    'drivers_online',
    'active_stores',
  ];
  final selected = <_DashboardStatData>[];
  for (final key in preferredKeys) {
    _DashboardStatData? match;
    for (final card in cards) {
      if (card.key == key) {
        match = card;
        break;
      }
    }
    if (match != null && !selected.contains(match)) selected.add(match);
  }
  for (final title in [
    'مبيعات اليوم',
    'إجمالي الإيرادات',
    'طلبات جديدة',
    'إجمالي الطلبات',
    'قيد التحضير',
    'المطاعم المفتوحة',
    'سائقون متاحون',
    'المتاجر النشطة',
  ]) {
    _DashboardStatData? match;
    for (final card in cards) {
      if (card.title == title) {
        match = card;
        break;
      }
    }
    if (match != null && !selected.contains(match)) selected.add(match);
  }
  for (final card in cards) {
    if (selected.length >= 6) break;
    if (!selected.contains(card)) selected.add(card);
  }
  return selected.take(6).toList();
}

_DashboardStatData _dashboardStatOrFallback(
  Map<String, _DashboardStatData> byKey,
  List<String> keys,
  _DashboardStatData fallback,
) {
  for (final key in keys) {
    final stat = byKey[key];
    if (stat != null) return stat;
  }
  return fallback;
}

String _masterMetricTargetKey(_DashboardStatData stat) {
  switch (stat.key) {
    case 'restaurants_open':
    case 'restaurants_closed':
    case 'بانتظار قبول المطعم':
    case 'المطاعم المفتوحة':
    case 'المطاعم المغلقة':
      return 'restaurants';
    case 'drivers_online':
    case 'سائقون متاحون':
    case 'سائقون مشغولون':
    case 'سائقون متأخرون':
    case 'على الطريق':
      return 'delivery';
    case 'revenue_today':
    case 'مبيعات اليوم':
    case 'عمولة المنصة':
    case 'رسوم التوصيل':
    case 'التعويضات المستحقة':
    case 'أرصدة المحفظة':
      return 'finance';
    case 'users_new_today':
    case 'مستخدمون جدد':
      return 'customers';
    default:
      return 'orders';
  }
}

_DashboardStatData _homeStat(
  String title,
  String value,
  IconData icon,
  Color color, {
  bool positive = true,
  String? suffix,
}) {
  return _DashboardStatData(
    key: title,
    title: title,
    value: value,
    subtitle: 'عن أمس',
    trendValue: value == '0' ? '0%' : '+0%',
    trendDirection: positive ? 'up' : 'down',
    iconKey: 'home',
    accent: color,
    iconBackground: color.withValues(alpha: 0.11),
    valueSuffix: suffix == null ? null : '\u062C.\u0645',
  );
}

String _sectionNumber(List<_DashboardSectionData> sections, String key) {
  final match = sections.where((section) => section.key == key).toList();
  if (match.isEmpty) {
    return '0';
  }
  final text = match.first.actionLabel;
  final matchNumber = RegExp(r'\d+').firstMatch(text);
  return matchNumber?.group(0) ?? '0';
}

List<_MasterHomeInfoItem> _masterHomeLiveItems(
  List<_DashboardStatData> stats,
  List<_DashboardSectionData> sections,
  String alertMessage,
) {
  final items = <_MasterHomeInfoItem>[
    _MasterHomeInfoItem(
      title: 'طلب جديد',
      subtitle: _statLabel(stats, 'orders_today'),
      icon: Icons.add_box_outlined,
      color: _kPrimaryGreen,
      background: const Color(0xFFEAF5ED),
    ),
    _MasterHomeInfoItem(
      title: 'السائقون المتاحون',
      subtitle: _statLabel(stats, 'drivers_online'),
      icon: Icons.delivery_dining_outlined,
      color: const Color(0xFF2563EB),
      background: const Color(0xFFEAF1FF),
    ),
    _MasterHomeInfoItem(
      title: 'تنبيه يحتاج متابعة',
      subtitle: alertMessage,
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFD92C2C),
      background: const Color(0xFFFDEEEF),
    ),
    for (final section in sections.take(4))
      _MasterHomeInfoItem(
        title: section.title,
        subtitle: section.actionLabel,
        icon: section.actionIcon,
        color: section.actionColor,
        background: section.iconBackground,
      ),
  ];
  return items.take(8).toList();
}

String _statLabel(List<_DashboardStatData> stats, String key) {
  for (final stat in stats) {
    if (stat.key == key) {
      return [
        stat.value,
        if ((stat.valueSuffix ?? '').isNotEmpty) stat.valueSuffix,
      ].join(' ');
    }
  }
  return '0';
}

List<_MasterHomeInfoItem> _masterHomeAlertCards(
  List<_DashboardSectionData> sections,
  int alertCount,
  String alertMessage,
) {
  return [
    _MasterHomeInfoItem(
      title: 'طلبات متأخرة',
      subtitle: alertMessage,
      icon: Icons.timer_outlined,
      color: const Color(0xFFD92C2C),
      background: const Color(0xFFFDEEEF),
    ),
    _MasterHomeInfoItem(
      title: 'مطاعم متأخرة',
      subtitle: _sectionAction(sections, 'restaurants'),
      icon: Icons.storefront_outlined,
      color: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF4E4),
    ),
    _MasterHomeInfoItem(
      title: 'سائقون متأخرون',
      subtitle: _sectionAction(sections, 'delivery'),
      icon: Icons.person_off_outlined,
      color: const Color(0xFFD92C2C),
      background: const Color(0xFFFDEEEF),
    ),
    _MasterHomeInfoItem(
      title: 'تنبيهات نشطة',
      subtitle: '$alertCount تنبيه',
      icon: Icons.star_border_rounded,
      color: const Color(0xFF7C3AED),
      background: const Color(0xFFF1ECFF),
    ),
  ];
}

List<_MasterHomeInfoItem> _masterHomePerformanceItems(
  List<_DashboardStatData> stats,
) {
  return [
    _MasterHomeInfoItem(
      title: 'متوسط وقت التوصيل',
      subtitle: '32:25 دقيقة',
      icon: Icons.access_time_rounded,
      color: const Color(0xFF7C3AED),
      background: const Color(0xFFF1ECFF),
    ),
    _MasterHomeInfoItem(
      title: 'متوسط وقت التحضير',
      subtitle: '18:40 دقيقة',
      icon: Icons.timer_outlined,
      color: const Color(0xFFD92C2C),
      background: const Color(0xFFFDEEEF),
    ),
    _MasterHomeInfoItem(
      title: 'متوسط قبول الطلب',
      subtitle: '2:15 دقيقة',
      icon: Icons.schedule_rounded,
      color: _kPrimaryGreen,
      background: const Color(0xFFEAF5ED),
    ),
  ];
}

String _sectionAction(List<_DashboardSectionData> sections, String key) {
  for (final section in sections) {
    if (section.key == key) {
      return section.actionLabel;
    }
  }
  return 'لا توجد بيانات';
}

List<_OperationsMapMarkerData> _masterHomeMapMarkers(
  List<_DashboardStatData> stats,
) {
  final orders =
      int.tryParse(
        _statLabel(stats, 'orders_today').replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;
  final drivers =
      int.tryParse(
        _statLabel(stats, 'drivers_online').replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;
  final restaurants =
      int.tryParse(
        _statLabel(stats, 'restaurants_open').replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;
  return [
    _OperationsMapMarkerData(
      type: 'restaurant',
      label: 'مطعم مفتوح',
      subtitle: '$restaurants مطعم',
      point: const LatLng(30.0444, 31.2357),
      icon: Icons.storefront_outlined,
      color: const Color(0xFFF59E0B),
    ),
    _OperationsMapMarkerData(
      type: 'driver',
      label: 'سائق متاح',
      subtitle: '$drivers سائق',
      point: const LatLng(33.5138, 36.2765),
      icon: Icons.delivery_dining_outlined,
      color: _kPrimaryGreen,
    ),
    _OperationsMapMarkerData(
      type: 'order',
      label: 'طلب نشط',
      subtitle: '$orders طلب',
      point: const LatLng(31.7683, 35.2137),
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFF2563EB),
    ),
  ];
}

class _MasterWelcomeBlock extends StatelessWidget {
  const _MasterWelcomeBlock({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'مرحباً $displayName 👋',
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E232A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'إليك نظرة سريعة على أداء المنصة اليوم',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12.4,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6F7680),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MasterAlertCard extends StatelessWidget {
  const _MasterAlertCard({required this.alertCount, required this.message});

  final int alertCount;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D6DA)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFFD92C2C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alertCount > 0 ? message : 'لا توجد تنبيهات حالياً',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD92C2C),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterStatCard extends StatelessWidget {
  const _MasterStatCard({required this.stat});

  final _DashboardStatData stat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: stat.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(stat.icon, size: 20, color: stat.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF69717B),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: stat.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E232A),
                            height: 1.0,
                          ),
                        ),
                        if (stat.valueSuffix != null)
                          TextSpan(
                            text: ' ${stat.valueSuffix}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5E6670),
                              height: 1.0,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stat.trendIsPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: stat.trendIsPositive
                            ? _kPrimaryGreen
                            : const Color(0xFFD92C2C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stat.trendValue,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: stat.trendIsPositive
                              ? _kPrimaryGreen
                              : const Color(0xFFD92C2C),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'مقارنة باليوم السابق',
                        style: TextStyle(
                          fontSize: 10.4,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7A8088),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterSectionCard extends StatelessWidget {
  // ignore: unused_element_parameter
  const _MasterSectionCard({required this.section, this.onTap});

  final _DashboardSectionData section;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.014),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: section.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  section.actionIcon,
                  size: 13,
                  color: section.accent,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${section.index}. ${section.title}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E232A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      section.subtitle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F7680),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      section.pagesCount,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A919A),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 23,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECE8)),
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 12,
                  color: Color(0xFF4E5660),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        section.actionIcon,
                        size: 10,
                        color: section.actionColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          section.actionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10.1,
                            fontWeight: FontWeight.w600,
                            color: section.actionColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _MasterBottomStatusBar extends StatelessWidget {
  const _MasterBottomStatusBar({
    required this.items,
    required this.footerVersion,
  });

  final List<_DashboardStatusItemData> items;
  final String footerVersion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD1E8D9)),
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 12,
              color: _kPrimaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          for (var index = 0; index < items.length; index++) ...[
            _MasterStatusChip(item: items[index]),
            if (index != items.length - 1) const SizedBox(width: 18),
          ],
          const Spacer(),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'الإصدار ',
                  style: TextStyle(
                    fontSize: 11.1,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7680),
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: footerVersion,
                  style: const TextStyle(
                    fontSize: 11.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A6270),
                    height: 1.0,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MasterStatusChip extends StatelessWidget {
  const _MasterStatusChip({required this.item});

  final _DashboardStatusItemData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: item.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 10.4,
            fontWeight: FontWeight.w600,
            color: Color(0xFF394048),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
