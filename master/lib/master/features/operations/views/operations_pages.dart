// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterOperationsPage extends StatefulWidget {
  const MasterOperationsPage({
    super.key,
    required this.session,
    required this.onLogout,
    this.api,
    this.serverNow,
    this.initialSubSection = 'tracking',
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService? api;
  final DateTime? serverNow;
  final String initialSubSection;

  @override
  State<MasterOperationsPage> createState() => _MasterOperationsPageState();
}

class _MasterOperationsPageState extends State<MasterOperationsPage> {
  late String _activeSubSection;
  late Future<_MasterOperationsData> _operationsFuture;
  String _trackingStatusFilter = 'all';
  DateTime? _trackingDate;
  bool _trackingAutoRefresh = true;
  int _trackingRefreshSeconds = 30;
  String _trackingOrderType = 'all';
  Timer? _trackingRefreshTimer;
  String _activityViewFilter = 'all';

  @override
  void initState() {
    super.initState();
    _activeSubSection = widget.initialSubSection;
    _operationsFuture = _loadOperationsData();
    _configureTrackingRefresh();
  }

  void _configureTrackingRefresh() {
    _trackingRefreshTimer?.cancel();
    if (!_trackingAutoRefresh) return;
    _trackingRefreshTimer = Timer.periodic(
      Duration(seconds: _trackingRefreshSeconds),
      (_) {
        if (!mounted || _activeSubSection != 'tracking') return;
        setState(() => _operationsFuture = _loadOperationsData());
      },
    );
  }

  Future<_MasterOperationsData> _loadOperationsData() {
    final api = widget.api;
    if (api == null) {
      return Future.value(
        _MasterOperationsData.empty(serverNow: widget.serverNow),
      );
    }
    return api
        ._fetchOperationsSummary(widget.session.token)
        .timeout(const Duration(seconds: 20));
  }

  void _retryOperationsData() {
    setState(() {
      _operationsFuture = _loadOperationsData();
    });
  }

  @override
  void dispose() {
    _trackingRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MasterOperationsData>(
      future: _operationsFuture,
      builder: (context, snapshot) {
        final operationsData =
            snapshot.data ??
            _MasterOperationsData.empty(serverNow: widget.serverNow);
        final serverNow =
            operationsData.serverNow ?? widget.serverNow ?? DateTime.now();
        final displayName = widget.session.master.adminName.trim().isNotEmpty
            ? widget.session.master.adminName.trim()
            : (widget.session.master.adminEmail.trim().isNotEmpty
                  ? widget.session.master.adminEmail.trim()
                  : 'Admin #${widget.session.master.adminId}');
        final roleLabel = _masterRoleArabicLabel(
          widget.session.master.adminRoleId,
          fallback: widget.session.master.role?.roleName,
        );
        final isActivityMode = _activeSubSection == 'activity';

        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _retryOperationsData,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: isActivityMode ? Colors.white : null,
              gradient: isActivityMode
                  ? null
                  : const LinearGradient(
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
                    final activityMode = _activeSubSection == 'activity';
                    final trackingMode = _activeSubSection == 'tracking';
                    final wideLayout =
                        constraints.maxWidth >= (trackingMode ? 1180 : 1080);
                    final sidebarWidth = (activityMode || trackingMode)
                        ? (constraints.maxWidth >= 1500
                              ? 250.0
                              : constraints.maxWidth >= 1200
                              ? 232.0
                              : 210.0)
                        : (constraints.maxWidth >= 1500
                              ? 250.0
                              : constraints.maxWidth >= 1200
                              ? 236.0
                              : 224.0);
                    final activityWidth = trackingMode
                        ? (constraints.maxWidth >= 1500
                              ? 320.0
                              : constraints.maxWidth >= 1200
                              ? 288.0
                              : 252.0)
                        : (constraints.maxWidth >= 1500
                              ? 310.0
                              : constraints.maxWidth >= 1200
                              ? 296.0
                              : 280.0);
                    final filterWidth = trackingMode
                        ? (constraints.maxWidth >= 1500
                              ? 288.0
                              : constraints.maxWidth >= 1200
                              ? 250.0
                              : 220.0)
                        : 0.0;
                    final trackingBottomHeight = trackingMode
                        ? (constraints.maxWidth >= 1500
                              ? 320.0
                              : constraints.maxWidth >= 1280
                              ? 320.0
                              : constraints.maxWidth >= 1020
                              ? 324.0
                              : 620.0)
                        : 0.0;
                    final operationsBodyHeight =
                        constraints.maxHeight + (trackingMode ? 420.0 : 160.0);

                    final mainArea = trackingMode
                        ? _OperationsTrackingCenterPanel(
                            serverNow: serverNow,
                            mapMarkers: _filterTrackingMarkers(
                              operationsData.trackingMapMarkers,
                              _trackingStatusFilter,
                            ),
                            statusFilter: _trackingStatusFilter,
                            selectedDate: _trackingDate,
                            onDateChanged: (value) =>
                                setState(() => _trackingDate = value),
                            autoRefresh: _trackingAutoRefresh,
                            refreshSeconds: _trackingRefreshSeconds,
                            orderType: _trackingOrderType,
                            onAutoRefreshChanged: (value) {
                              setState(() => _trackingAutoRefresh = value);
                              _configureTrackingRefresh();
                            },
                            onRefreshSecondsChanged: (value) {
                              setState(() => _trackingRefreshSeconds = value);
                              _configureTrackingRefresh();
                            },
                            onOrderTypeChanged: (value) =>
                                setState(() => _trackingOrderType = value),
                            onStatusFilterChanged: (value) {
                              setState(() => _trackingStatusFilter = value);
                            },
                          )
                        : _OperationsMainArea(
                            serverNow: serverNow,
                            statCards: operationsData.overviewStatCards,
                            mapMarkers: operationsData.overviewMapMarkers,
                            performanceCards: operationsData.performanceCards,
                            alertCards: operationsData.alertCards,
                            onRefresh: _retryOperationsData,
                          );
                    final livePanel = trackingMode
                        ? _OperationsTrackingOrdersPanel(
                            items: _filterTrackingOrders(
                              operationsData.trackingOrders,
                              _trackingStatusFilter,
                              date: _trackingDate,
                              orderType: _trackingOrderType,
                            ),
                            selectedFilter: _trackingStatusFilter,
                            onFilterChanged: (value) {
                              setState(() => _trackingStatusFilter = value);
                            },
                          )
                        : _OperationsLivePanel(
                            items: operationsData.overviewLiveItems,
                          );
                    final filterPanel = trackingMode
                        ? _OperationsTrackingFilterSidebar(
                            drivers: operationsData.trackingDrivers,
                            restaurants: operationsData.trackingRestaurants,
                          )
                        : null;
                    final operationsSidebar = _OperationsNavigationSidebar(
                      activeSubSection: _activeSubSection,
                      onHomeTap: () => _navigateToMasterSection(
                        context,
                        key: 'home',
                        session: widget.session,
                        onLogout: widget.onLogout,
                        api: widget.api ?? MasterAuthApiService(),
                        serverNow: serverNow,
                      ),
                      onSubSectionTap: (sectionKey) {
                        setState(() => _activeSubSection = sectionKey);
                      },
                      onMenuTap: (item) {
                        String? target;
                        var accessSubPage = 'overview';
                        if (item.icon == Icons.receipt_long_outlined) {
                          target = 'orders';
                        } else if (item.icon ==
                            Icons.delivery_dining_outlined) {
                          target = 'delivery';
                        } else if (item.icon == Icons.storefront_outlined) {
                          target = 'restaurants';
                        } else if (item.icon == Icons.people_alt_outlined) {
                          target = 'users';
                        } else if (item.icon ==
                            Icons.account_balance_wallet_outlined) {
                          target = 'finance';
                        } else if (item.icon == Icons.campaign_outlined) {
                          target = 'marketing';
                        } else if (item.icon ==
                            Icons.notifications_active_outlined) {
                          target = 'communication';
                        } else if (item.icon == Icons.query_stats_outlined) {
                          target = 'reports';
                        } else if (item.icon == Icons.settings_outlined) {
                          target = 'access';
                          accessSubPage = 'settings';
                        } else if (item.icon ==
                            Icons.admin_panel_settings_outlined) {
                          target = 'access';
                          accessSubPage = 'approvals';
                        }
                        if (target == null) {
                          _showMasterSnack(
                            context,
                            '${item.label} سيتم تشغيلها لاحقاً',
                          );
                          return;
                        }
                        _navigateToMasterSection(
                          context,
                          key: target,
                          session: widget.session,
                          onLogout: widget.onLogout,
                          api: widget.api ?? MasterAuthApiService(),
                          serverNow: serverNow,
                          accessSubPage: accessSubPage,
                          replace: false,
                        );
                      },
                    );
                    final activitySidebar = _OperationsActivitySidebar(
                      activeSubSection: _activeSubSection,
                      displayName: displayName,
                      roleLabel: roleLabel,
                      notificationBadge: operationsData.notificationBadge,
                      messageBadge: operationsData.messageBadge,
                      alertBadge: operationsData.alertBadge,
                      onHomeTap: () => _navigateToMasterSection(
                        context,
                        key: 'home',
                        session: widget.session,
                        onLogout: widget.onLogout,
                        api: widget.api ?? MasterAuthApiService(),
                        serverNow: serverNow,
                      ),
                      onSubSectionTap: (sectionKey) {
                        setState(() => _activeSubSection = sectionKey);
                      },
                      onMenuTap: (item) {
                        String? target;
                        var accessSubPage = 'overview';
                        if (item.icon == Icons.receipt_long_outlined) {
                          target = 'orders';
                        } else if (item.icon ==
                            Icons.delivery_dining_outlined) {
                          target = 'delivery';
                        } else if (item.icon == Icons.storefront_outlined) {
                          target = 'restaurants';
                        } else if (item.icon == Icons.people_alt_outlined) {
                          target = 'users';
                        } else if (item.icon ==
                            Icons.account_balance_wallet_outlined) {
                          target = 'finance';
                        } else if (item.icon == Icons.campaign_outlined) {
                          target = 'marketing';
                        } else if (item.icon ==
                            Icons.notifications_active_outlined) {
                          target = 'communication';
                        } else if (item.icon == Icons.query_stats_outlined) {
                          target = 'reports';
                        } else if (item.icon == Icons.settings_outlined) {
                          target = 'access';
                          accessSubPage = 'settings';
                        } else if (item.icon ==
                            Icons.admin_panel_settings_outlined) {
                          target = 'access';
                          accessSubPage = 'approvals';
                        }
                        if (target == null) {
                          _showMasterSnack(
                            context,
                            '${item.label} سيتم تشغيلها لاحقاً',
                          );
                          return;
                        }
                        _navigateToMasterSection(
                          context,
                          key: target,
                          session: widget.session,
                          onLogout: widget.onLogout,
                          api: widget.api ?? MasterAuthApiService(),
                          serverNow: serverNow,
                          accessSubPage: accessSubPage,
                          replace: false,
                        );
                      },
                      onLogout: widget.onLogout,
                    );

                    if (activityMode) {
                      return SizedBox(
                        height: constraints.maxHeight,
                        child: _OperationsActivityWorkspace(
                          serverNow: serverNow,
                          sidebarWidth: sidebarWidth,
                          sidebar: activitySidebar,
                          displayName: displayName,
                          roleLabel: roleLabel,
                          notificationBadge: operationsData.notificationBadge,
                          messageBadge: operationsData.messageBadge,
                          statusLabel: 'العمليات تعمل الآن',
                          platformTitle: 'لوحة العمليات',
                          platformSubtitle: 'متابعة العمليات والتغييرات',
                          onLogout: widget.onLogout,
                          data: operationsData,
                          activityViewFilter: _activityViewFilter,
                          onActivityViewFilterChanged: (value) {
                            setState(() => _activityViewFilter = value);
                          },
                        ),
                      );
                    }

                    return Column(
                      children: [
                        _MasterOperationsTopBar(
                          displayName: displayName,
                          roleLabel: roleLabel,
                          notificationBadge: operationsData.notificationBadge,
                          messageBadge: operationsData.messageBadge,
                          serverNow: serverNow,
                          statusLabel: 'جميع الخدمات تعمل',
                          platformTitle: 'لوحة تحكم صاحب المنصة',
                          platformSubtitle: 'مركز العمليات والتحكم',
                          onLogout: widget.onLogout,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: wideLayout
                                ? SizedBox(
                                    height: operationsBodyHeight,
                                    child: trackingMode
                                        ? Row(
                                            textDirection: TextDirection.ltr,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          SizedBox(
                                                            width: filterWidth,
                                                            child: filterPanel,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              textDirection:
                                                                  TextDirection
                                                                      .ltr,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      mainArea,
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      activityWidth,
                                                                  child:
                                                                      livePanel,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    SizedBox(
                                                      height:
                                                          trackingBottomHeight,
                                                      child: _OperationsTrackingBottomStrip(
                                                        momentMetrics:
                                                            operationsData
                                                                .trackingMomentMetrics,
                                                        pressureAreas:
                                                            operationsData
                                                                .trackingPressureAreas,
                                                        shortageAreas:
                                                            operationsData
                                                                .trackingShortageAreas,
                                                        liveStats: operationsData
                                                            .trackingLiveStats,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: sidebarWidth,
                                                child: operationsSidebar,
                                              ),
                                            ],
                                          )
                                        : Row(
                                            textDirection: TextDirection.ltr,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(child: mainArea),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: activityWidth,
                                                child: livePanel,
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: sidebarWidth,
                                                child: operationsSidebar,
                                              ),
                                            ],
                                          ),
                                  )
                                : Column(
                                    children: [
                                      if (trackingMode) ...[
                                        SizedBox(
                                          height: 760,
                                          child: filterPanel,
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 820,
                                          child: Row(
                                            textDirection: TextDirection.ltr,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(child: mainArea),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: activityWidth,
                                                child: livePanel,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: trackingBottomHeight,
                                          child: _OperationsTrackingBottomStrip(
                                            momentMetrics: operationsData
                                                .trackingMomentMetrics,
                                            pressureAreas: operationsData
                                                .trackingPressureAreas,
                                            shortageAreas: operationsData
                                                .trackingShortageAreas,
                                            liveStats: operationsData
                                                .trackingLiveStats,
                                          ),
                                        ),
                                      ] else ...[
                                        SizedBox(height: 1680, child: mainArea),
                                        const SizedBox(height: 12),
                                        SizedBox(height: 620, child: livePanel),
                                      ],
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 720,
                                        child: operationsSidebar,
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
          ),
        );
      },
    );
  }
}

List<_OperationsMapMarkerData> _filterTrackingMarkers(
  List<_OperationsMapMarkerData> markers,
  String filter,
) {
  if (filter == 'all') {
    return markers;
  }

  return markers.where((marker) {
    final status = '${marker.statusKey} ${marker.subtitle}'.toLowerCase();
    if (filter == 'with_driver') {
      return marker.type == 'driver' ||
          status.contains('assigned') ||
          status.contains('\u0645\u0639 \u0627\u0644\u0633\u0627\u0626\u0642');
    }
    if (filter == 'ready') {
      return marker.type == 'restaurant' ||
          status.contains('ready') ||
          status.contains('\u062c\u0627\u0647\u0632');
    }
    if (filter == 'on_way') {
      return marker.type == 'driver' ||
          <String>{
            'picked_up',
            'heading_to_customer',
            'on_the_way',
            'arrived_at_customer',
          }.any(status.contains) ||
          status.contains(
            '\u0639\u0644\u0649 \u0627\u0644\u0637\u0631\u064a\u0642',
          );
    }
    return false;
  }).toList();
}

List<_TrackingOrderData> _filterTrackingOrders(
  List<_TrackingOrderData> orders,
  String filter, {
  DateTime? date,
  String orderType = 'all',
}) {
  return orders.where((order) {
    if (date != null && order.dateKey.isNotEmpty) {
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (order.dateKey != key) return false;
    }
    if (orderType != 'all' && order.orderType != orderType) return false;
    if (filter == 'all') return true;
    final status = '${order.statusKey} ${order.statusLabel}'.toLowerCase();
    if (filter == 'on_way') {
      return <String>{
            'picked_up',
            'heading_to_customer',
            'on_the_way',
            'arrived_at_customer',
          }.any(status.contains) ||
          status.contains(
            '\u0639\u0644\u0649 \u0627\u0644\u0637\u0631\u064a\u0642',
          );
    }
    if (filter == 'with_driver') {
      return <String>{'assigned', 'accepted'}.any(status.contains) ||
          status.contains(
            '\u0645\u0639 \u0627\u0644\u0633\u0627\u0626\u0642',
          ) ||
          status.contains('\u0633\u0627\u0626\u0642');
    }
    if (filter == 'ready') {
      return <String>{'ready', 'arrived_at_restaurant'}.any(status.contains) ||
          status.contains('\u062c\u0627\u0647\u0632');
    }
    return false;
  }).toList();
}

bool _matchesTrackingFilterText(String text, String filter) {
  if (filter == 'on_way') {
    return text.contains('on_way') ||
        text.contains('out_for_delivery') ||
        text.contains('في الطريق') ||
        text.contains('على الطريق') ||
        text.contains('طريق');
  }
  if (filter == 'with_driver') {
    return text.contains('with_driver') ||
        text.contains('driver') ||
        text.contains('مع السائق') ||
        text.contains('سائق');
  }
  if (filter == 'ready') {
    return text.contains('ready') ||
        text.contains('جاهز') ||
        text.contains('جاهزة') ||
        text.contains('restaurant');
  }
  return true;
}

String _activityViewFilterLabel(String value) {
  switch (value) {
    case 'feed':
      return 'التغذية المباشرة';
    case 'events':
      return 'الأحداث الحساسة';
    default:
      return 'جميع الأنشطة';
  }
}
