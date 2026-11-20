// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _OperationsActivitySidebar extends StatelessWidget {
  const _OperationsActivitySidebar({
    required this.activeSubSection,
    required this.displayName,
    required this.roleLabel,
    required this.notificationBadge,
    required this.messageBadge,
    required this.alertBadge,
    required this.onHomeTap,
    required this.onSubSectionTap,
    required this.onMenuTap,
    required this.onLogout,
  });

  final String activeSubSection;
  final String displayName;
  final String roleLabel;
  final int notificationBadge;
  final int messageBadge;
  final int alertBadge;
  final VoidCallback onHomeTap;
  final void Function(String sectionKey) onSubSectionTap;
  final ValueChanged<_OperationsSidebarTileData> onMenuTap;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final menuItems = <_OperationsSidebarTileData>[
      const _OperationsSidebarTileData(
        label: 'إدارة الطلبات',
        icon: Icons.receipt_long_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'التوصيل والوجستيات',
        icon: Icons.delivery_dining_outlined,
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
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
              selected: true,
              onTap: () => onSubSectionTap('overview'),
            ),
            const SizedBox(height: 10),
            _OperationsSubMenuCard(
              activeSubSection: activeSubSection,
              onTap: onSubSectionTap,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: menuItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _OperationsSidebarMenuItem(
                    data: item,
                    onTap: () => onMenuTap(item),
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

class _ActivitySidebarProfileCard extends StatelessWidget {
  const _ActivitySidebarProfileCard({
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAE6)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 52,
              height: 52,
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
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.6,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E232A),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleLabel,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6F7680),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(Icons.circle, size: 7, color: Color(0xFF1A8B4A)),
                      SizedBox(width: 5),
                      Text(
                        'متصل الآن',
                        style: TextStyle(
                          fontSize: 10.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A8B4A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF4E5660),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySidebarQuickActionsRow extends StatelessWidget {
  const _ActivitySidebarQuickActionsRow({
    required this.notificationBadge,
    required this.messageBadge,
    required this.alertBadge,
  });

  final int notificationBadge;
  final int messageBadge;
  final int alertBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActivitySidebarQuickAction(
            label: 'إشعارات',
            icon: Icons.notifications_none_rounded,
            badge: notificationBadge,
            accent: const Color(0xFF1A8B4A),
            background: const Color(0xFFEAF5ED),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActivitySidebarQuickAction(
            label: 'رسائل',
            icon: Icons.chat_bubble_outline_rounded,
            badge: messageBadge,
            accent: const Color(0xFF2563EB),
            background: const Color(0xFFEAF1FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActivitySidebarQuickAction(
            label: 'حرجة',
            icon: Icons.warning_amber_rounded,
            badge: alertBadge,
            accent: const Color(0xFFF59E0B),
            background: const Color(0xFFFFF4E4),
          ),
        ),
      ],
    );
  }
}

class _ActivitySidebarQuickAction extends StatelessWidget {
  const _ActivitySidebarQuickAction({
    required this.label,
    required this.icon,
    required this.badge,
    required this.accent,
    required this.background,
  });

  final String label;
  final IconData icon;
  final int badge;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAE6)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFD92C2C),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4E5660),
                    height: 1.0,
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

class _OperationsActivityTopBar extends StatelessWidget {
  const _OperationsActivityTopBar({
    required this.displayName,
    required this.roleLabel,
    required this.notificationBadge,
    required this.messageBadge,
    required this.serverNow,
    required this.statusLabel,
    required this.platformTitle,
    required this.platformSubtitle,
    required this.onLogout,
  });

  final String displayName;
  final String roleLabel;
  final int notificationBadge;
  final int messageBadge;
  final DateTime serverNow;
  final String statusLabel;
  final String platformTitle;
  final String platformSubtitle;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1320;
          final leftGroup = Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              const _MasterTopIconButton(icon: Icons.settings_outlined),
              const SizedBox(width: 8),
              const _MasterTopIconButton(icon: Icons.fullscreen_rounded),
              const SizedBox(width: 8),
              _MasterTopIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                badge: messageBadge > 0 ? messageBadge.toString() : null,
              ),
              const SizedBox(width: 8),
              _MasterTopIconButton(
                icon: Icons.notifications_none_rounded,
                badge: notificationBadge > 0
                    ? notificationBadge.toString()
                    : null,
              ),
              const SizedBox(width: 10),
              _MasterProfileChip(
                displayName: displayName,
                roleLabel: roleLabel,
                onLogout: onLogout,
              ),
            ],
          );

          final centerGroup = Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              const _ActivityLivePill(),
              const SizedBox(width: 10),
              _MasterDateBlock(serverNow: serverNow),
              const SizedBox(width: 10),
              _MasterStatusPill(label: statusLabel),
            ],
          );

          final rightGroup = Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    platformTitle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.6,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E232A),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    platformSubtitle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6F7680),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 34, color: const Color(0xFFF0F1F2)),
              const SizedBox(width: 12),
              MasterBrandMark(width: compact ? 82 : 92, height: 42),
            ],
          );

          if (compact) {
            return Wrap(
              textDirection: TextDirection.ltr,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [leftGroup, centerGroup, rightGroup],
            );
          }

          return Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(
                flex: 5,
                child: Align(alignment: Alignment.centerLeft, child: leftGroup),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: Center(child: centerGroup)),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: rightGroup,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityLivePill extends StatelessWidget {
  const _ActivityLivePill();

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
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7A3C),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'جاري بث مباشر',
            style: TextStyle(
              fontSize: 10.4,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A8B4A),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFooterBar extends StatelessWidget {
  const _ActivityFooterBar({required this.serverNow, required this.items});

  final DateTime serverNow;
  final List<_DashboardStatusItemData> items;

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatArabicTimeLabel(serverNow);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Text(
            'FOXA Platform v1.0.0',
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A6270),
              height: 1.0,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF4E5660),
              ),
              const SizedBox(width: 6),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B424A),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'آخر مزامنة',
                style: TextStyle(
                  fontSize: 10.6,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F7680),
                  height: 1.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          for (var index = 0; index < items.length; index++) ...[
            _MasterStatusChip(item: items[index]),
            if (index != items.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _OperationsActivityWorkspace extends StatelessWidget {
  const _OperationsActivityWorkspace({
    required this.serverNow,
    required this.sidebarWidth,
    required this.sidebar,
    required this.displayName,
    required this.roleLabel,
    required this.notificationBadge,
    required this.messageBadge,
    required this.statusLabel,
    required this.platformTitle,
    required this.platformSubtitle,
    required this.onLogout,
    required this.data,
    required this.activityViewFilter,
    required this.onActivityViewFilterChanged,
  });

  final DateTime serverNow;
  final double sidebarWidth;
  final Widget sidebar;
  final String displayName;
  final String roleLabel;
  final int notificationBadge;
  final int messageBadge;
  final String statusLabel;
  final String platformTitle;
  final String platformSubtitle;
  final Future<void> Function() onLogout;
  final _MasterOperationsData data;
  final String activityViewFilter;
  final ValueChanged<String> onActivityViewFilterChanged;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatArabicDateLabel(serverNow);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final summaryWidth = constraints.maxWidth >= 1500
            ? 250.0
            : constraints.maxWidth >= 1360
            ? 240.0
            : 228.0;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OperationsActivityTopBar(
              displayName: displayName,
              roleLabel: roleLabel,
              notificationBadge: notificationBadge,
              messageBadge: messageBadge,
              serverNow: serverNow,
              statusLabel: statusLabel,
              platformTitle: platformTitle,
              platformSubtitle: platformSubtitle,
              onLogout: onLogout,
            ),
            const SizedBox(height: 12),
            const _OperationsActivityHeader(),
            const SizedBox(height: 12),
            _OperationsStatSection(
              cards: data.activityStats
                  .map(
                    (card) => card.toWidget(
                      height: 108,
                      valueFontSize: 20,
                      showTrendIcon: false,
                    ),
                  )
                  .toList(),
              wideColumns: 3,
              mediumColumns: 3,
              cardHeight: 108,
            ),
            const SizedBox(height: 12),
            _OperationsActivityFiltersBar(
              dateLabel: dateLabel,
              viewFilter: activityViewFilter,
              onViewFilterChanged: onActivityViewFilterChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 580,
              child: _OperationsActivityAnalyticsPanel(
                stats: data.activityStats,
              ),
            ),
            const SizedBox(height: 14),
            if (isWide)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activityViewFilter != 'events')
                    SizedBox(
                      height: 560,
                      child: _OperationsActivityFeedPanel(
                        items: data.activityFeedItems,
                      ),
                    ),
                  if (activityViewFilter != 'events' &&
                      activityViewFilter != 'feed')
                    const SizedBox(height: 14),
                  if (activityViewFilter == 'events')
                    SizedBox(
                      height: 560,
                      child: _OperationsActivityEventsPanel(
                        items: data.activityEventItems,
                      ),
                    ),
                  if (activityViewFilter != 'feed' &&
                      activityViewFilter != 'events') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 390,
                      child: Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: summaryWidth,
                            child: _OperationsActivitySummaryPanel(
                              groups: data.activitySummaryGroups,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _OperationsActivityEventsPanel(
                              items: data.activityEventItems,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 610,
                    child: _OperationsActivitySummaryPanel(
                      groups: data.activitySummaryGroups,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activityViewFilter != 'events') ...[
                    SizedBox(
                      height: 760,
                      child: _OperationsActivityFeedPanel(
                        items: data.activityFeedItems,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (activityViewFilter != 'feed')
                    SizedBox(
                      height: 720,
                      child: _OperationsActivityEventsPanel(
                        items: data.activityEventItems,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            _ActivityFooterBar(
              serverNow: serverNow,
              items: data.activityFooterStatusItems,
            ),
          ],
        );

        if (isWide) {
          return Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: sidebarWidth, child: sidebar),
              const SizedBox(width: 12),
              Expanded(child: SingleChildScrollView(child: content)),
            ],
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: 12),
              SizedBox(height: 820, child: sidebar),
            ],
          ),
        );
      },
    );
  }
}

class _OperationsActivityHeader extends StatelessWidget {
  const _OperationsActivityHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لوحة العمليات',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A8088),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  const Text(
                    'سجل النشاطات',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E232A),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5ED),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFD7EBDD)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monitor_heart_rounded,
                          size: 12,
                          color: Color(0xFF1A8B4A),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A8B4A),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'متابعة جميع عمليات المنصة لحظة بلحظة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6F7680),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OperationsActivityFiltersBar extends StatelessWidget {
  const _OperationsActivityFiltersBar({
    required this.dateLabel,
    required this.viewFilter,
    required this.onViewFilterChanged,
    this.employeeFilter = 'all',
    this.periodFilter = 'today',
    this.entityFilter = 'all',
    this.searchQuery = '',
    this.autoRefresh = true,
    this.onEmployeeFilterChanged,
    this.onPeriodFilterChanged,
    this.onEntityFilterChanged,
    this.onSearchChanged,
    this.onAutoRefreshChanged,
  });

  final String dateLabel;
  final String viewFilter;
  final ValueChanged<String> onViewFilterChanged;
  final String employeeFilter;
  final String periodFilter;
  final String entityFilter;
  final String searchQuery;
  final bool autoRefresh;
  final ValueChanged<String>? onEmployeeFilterChanged;
  final ValueChanged<String>? onPeriodFilterChanged;
  final ValueChanged<String>? onEntityFilterChanged;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<bool>? onAutoRefreshChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1140;

        final chipChildren = <Widget>[
          _OperationsPopupFilterChip(
            label:
                const {
                  'all': 'جميع الموظفين',
                  'admins': 'مشرفو النظام',
                  'support': 'فريق الدعم',
                }[employeeFilter] ??
                'جميع الموظفين',
            icon: Icons.person_outline_rounded,
            options: const {
              'all': 'جميع الموظفين',
              'admins': 'مشرفو النظام',
              'support': 'فريق الدعم',
            },
            value: employeeFilter,
            onChanged: onEmployeeFilterChanged ?? (_) {},
          ),
          _OperationsPopupFilterChip(
            label:
                const {
                  'today': 'اليوم',
                  'week': 'هذا الأسبوع',
                  'month': 'هذا الشهر',
                }[periodFilter] ??
                'اليوم',
            icon: Icons.calendar_month_rounded,
            value: periodFilter,
            options: const {
              'today': 'اليوم',
              'week': 'هذا الأسبوع',
              'month': 'هذا الشهر',
            },
            onChanged: onPeriodFilterChanged ?? (_) {},
          ),
          _OperationsPopupFilterChip(
            label: _activityViewFilterLabel(viewFilter),
            icon: Icons.layers_rounded,
            value: viewFilter,
            options: const {
              'all': 'جميع الأنشطة',
              'feed': 'الأنشطة المباشرة',
              'events': 'الأحداث الحساسة',
            },
            onChanged: onViewFilterChanged,
          ),
          _OperationsPopupFilterChip(
            label:
                const {
                  'all': 'جميع الكيانات',
                  'orders': 'الطلبات',
                  'restaurants': 'المطاعم',
                  'drivers': 'السائقون',
                  'finance': 'المالية',
                }[entityFilter] ??
                'جميع الكيانات',
            icon: Icons.dashboard_customize_outlined,
            value: entityFilter,
            options: const {
              'all': 'جميع الكيانات',
              'orders': 'الطلبات',
              'restaurants': 'المطاعم',
              'drivers': 'السائقون',
              'finance': 'المالية',
            },
            onChanged: onEntityFilterChanged ?? (_) {},
          ),
        ];

        final searchField = _ActivitySearchField(
          hintText: 'ابحث برقم الطلب أو اسم العميل أو المطعم أو الموظف...',
          value: searchQuery,
          onChanged: onSearchChanged,
        );

        if (isWide) {
          return Row(
            textDirection: TextDirection.ltr,
            children: [
              _ActivityRefreshPill(
                enabled: autoRefresh,
                onChanged: onAutoRefreshChanged,
              ),
              const SizedBox(width: 10),
              for (var index = 0; index < chipChildren.length; index++) ...[
                chipChildren[index],
                if (index != chipChildren.length - 1) const SizedBox(width: 8),
              ],
              const SizedBox(width: 10),
              Expanded(child: searchField),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActivityRefreshPill(
                  enabled: autoRefresh,
                  onChanged: onAutoRefreshChanged,
                ),
                ...chipChildren,
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OperationsActivityAnalyticsPanel extends StatelessWidget {
  const _OperationsActivityAnalyticsPanel({required this.stats});

  final List<_OperationsStatCardData> stats;

  int _valueAt(int index) {
    if (index >= stats.length) return 0;
    return int.tryParse(stats[index].value.replaceAll(',', '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final total = _valueAt(0);
    final items = <({String label, int value, Color color, IconData icon})>[
      (
        label: 'الطلبات النشطة',
        value: _valueAt(1),
        color: const Color(0xFF2563EB),
        icon: Icons.receipt_long_rounded,
      ),
      (
        label: 'المطاعم المفتوحة',
        value: _valueAt(2),
        color: const Color(0xFFF59E0B),
        icon: Icons.storefront_rounded,
      ),
      (
        label: 'السائقون المتصلون',
        value: _valueAt(3),
        color: const Color(0xFF7C3AED),
        icon: Icons.delivery_dining_rounded,
      ),
      (
        label: 'العمليات المالية',
        value: _valueAt(4),
        color: const Color(0xFF1A8B4A),
        icon: Icons.account_balance_wallet_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E9E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 19,
                  color: Color(0xFF1A8B4A),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل نشاط المنصة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17231E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'توزيع الأنشطة الحالية حسب المصدر',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7A8580),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$total نشاط',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B5B49),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'حجم النشاط حسب النوع',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF53615A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final item in items) ...[
                              Expanded(
                                child: _ActivityChartBar(
                                  label: item.label,
                                  value: item.value,
                                  total: total,
                                  color: item.color,
                                ),
                              ),
                              if (item != items.last) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final item in items) ...[
                        _ActivityRatioRow(
                          label: item.label,
                          value: item.value,
                          total: total,
                          color: item.color,
                          icon: item.icon,
                        ),
                        if (item != items.last) const SizedBox(height: 10),
                      ],
                    ],
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

class _ActivityChartBar extends StatelessWidget {
  const _ActivityChartBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0.0 : value / total;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF25312A),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: percentage.clamp(0.03, 1.0),
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF69756E)),
        ),
      ],
    );
  }
}

class _ActivityRatioRow extends StatelessWidget {
  const _ActivityRatioRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
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
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF46534B),
                      ),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF0F3F1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivitySearchField extends StatelessWidget {
  const _ActivitySearchField({
    required this.hintText,
    this.value = '',
    this.onChanged,
  });

  final String hintText;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EAE6)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6F7680)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              textAlign: TextAlign.right,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11.4,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4E5660),
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 11.4,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9AA1AA),
                  height: 1.0,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRefreshPill extends StatelessWidget {
  const _ActivityRefreshPill({this.enabled = true, this.onChanged});

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onChanged == null ? null : () => onChanged!(!enabled),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6EAE6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.refresh_rounded, size: 17, color: _kPrimaryGreen),
            const SizedBox(width: 8),
            const Text(
              'تحديث تلقائي',
              style: TextStyle(
                fontSize: 11.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5660),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: enabled ? _kPrimaryGreen : const Color(0xFFB9C2BC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: enabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsActivitySummaryPanel extends StatelessWidget {
  const _OperationsActivitySummaryPanel({required this.groups});

  final List<_ActivitySummaryGroupData> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _OperationsSectionHeader(
              title: 'ملخص النشاط الآن',
              subtitle: 'قراءة مباشرة من النظام',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    for (var index = 0; index < groups.length; index++) ...[
                      _ActivitySummaryGroupCard(group: groups[index]),
                      if (index != groups.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showActivitySummarySheet(
                  context,
                  title: 'جميع الملخصات',
                  groups: groups,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  side: const BorderSide(color: Color(0xFFE5E8E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'عرض جميع الملخصات',
                  style: TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4E5660),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySummaryGroupCard extends StatelessWidget {
  const _ActivitySummaryGroupCard({required this.group});

  final _ActivitySummaryGroupData group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: group.headerAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < group.items.length; index++) ...[
            _ActivitySummaryRow(item: group.items[index]),
            if (index != group.items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Divider(height: 1, thickness: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivitySummaryRow extends StatelessWidget {
  const _ActivitySummaryRow({required this.item});

  final _ActivitySummaryRowData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: item.background,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 10, color: item.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.3,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E5660),
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 11.3,
            fontWeight: FontWeight.w800,
            color: item.valueColor ?? item.accent,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _OperationsActivityFeedPanel extends StatelessWidget {
  const _OperationsActivityFeedPanel({required this.items});

  final List<_ActivityFeedItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _OperationsSectionHeader(
              title: 'آخر الأنشطة',
              subtitle: 'أحدث العمليات المسجلة على النظام',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _ActivityFeedRow(item: items[index]),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showActivityFeedSheet(
                  context,
                  title: 'المزيد من الأنشطة',
                  items: items,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  side: const BorderSide(color: Color(0xFFE5E8E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'عرض المزيد من الأنشطة',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4E5660),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeedRow extends StatelessWidget {
  const _ActivityFeedRow({required this.item});

  final _ActivityFeedItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.timeLabel,
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.relativeLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A8088),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.background,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 16, color: item.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E232A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TrackingStatusPill(
                      label: item.pillLabel,
                      color: item.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4E5660),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.4,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A8088),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            tooltip: 'إجراءات النشاط',
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: Color(0xFFB1B7BD),
            ),
            onSelected: (value) {
              final message = switch (value) {
                'details' => 'تم اختيار تفاصيل النشاط: ${item.title}',
                'copy' => 'تم نسخ مرجع النشاط',
                'follow' => 'تم تفعيل متابعة النشاط',
                _ => 'إجراء غير معروف',
              };
              _showMasterSnack(context, message);
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'details',
                child: Text('عرض التفاصيل'),
              ),
              PopupMenuItem<String>(value: 'copy', child: Text('نسخ المرجع')),
              PopupMenuItem<String>(
                value: 'follow',
                child: Text('متابعة النشاط'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationsActivityEventsPanel extends StatelessWidget {
  const _OperationsActivityEventsPanel({required this.items});

  final List<_ActivityEventItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Expanded(
                  child: Text(
                    'الأحداث المباشرة',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E232A),
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEEEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 10,
                    color: Color(0xFFD92C2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _ActivityEventCard(item: items[index]),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showActivityEventsSheet(
                  context,
                  title: 'جميع الأحداث',
                  items: items,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  side: const BorderSide(color: Color(0xFFE5E8E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'عرض جميع الأحداث',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4E5660),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEventCard extends StatelessWidget {
  const _ActivityEventCard({required this.item});

  final _ActivityEventItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 16, color: item.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.6,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E232A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reference,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E5660),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.role,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.2,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A8088),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.timeLabel,
                style: const TextStyle(
                  fontSize: 9.3,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A919A),
                  height: 1.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(
                child: Text(
                  item.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.3,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A919A),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () =>
                      _showActivityEventDetailsSheet(context, item),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: item.accent.withValues(alpha: 0.24),
                    ),
                    foregroundColor: item.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    item.buttonLabel,
                    style: TextStyle(
                      fontSize: 10.4,
                      fontWeight: FontWeight.w700,
                      color: item.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
