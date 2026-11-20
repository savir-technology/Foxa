part of '../../../../master_auth_app.dart';

/// Unified operations workspace. It reuses the existing live operational
/// panels, but owns one shared frame and one navigation contract.
class MasterOperationsUnifiedPage extends StatefulWidget {
  const MasterOperationsUnifiedPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.initialSubSection = 'tracking',
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final String initialSubSection;

  @override
  State<MasterOperationsUnifiedPage> createState() =>
      _MasterOperationsUnifiedPageState();
}

class _MasterOperationsUnifiedPageState
    extends State<MasterOperationsUnifiedPage> {
  late String _subSection;
  late Future<_MasterOperationsData> _future;
  String _trackingFilter = 'all';
  DateTime? _trackingDate;
  bool _trackingAutoRefresh = true;
  int _trackingRefreshSeconds = 30;
  String _trackingOrderType = 'all';
  Timer? _trackingRefreshTimer;
  String _activityFilter = 'all';
  String _activityEmployeeFilter = 'all';
  String _activityPeriodFilter = 'today';
  String _activityEntityFilter = 'all';
  String _activitySearch = '';
  bool _activityAutoRefresh = true;

  @override
  void initState() {
    super.initState();
    _subSection = widget.initialSubSection;
    _future = _load();
    _configureTrackingRefresh();
  }

  void _configureTrackingRefresh() {
    _trackingRefreshTimer?.cancel();
    if (!_trackingAutoRefresh) return;
    _trackingRefreshTimer = Timer.periodic(
      Duration(seconds: _trackingRefreshSeconds),
      (_) {
        if (!mounted ||
            _subSection != 'tracking' ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        setState(() => _future = _load());
      },
    );
  }

  Future<_MasterOperationsData> _load() {
    return widget.api
        ._fetchOperationsSummary(widget.session.token)
        .timeout(const Duration(seconds: 20));
  }

  bool _matchesActivityText(Iterable<String> values) {
    final query = _activitySearch.trim().toLowerCase();
    if (query.isEmpty) return true;
    return values.any((value) => value.toLowerCase().contains(query));
  }

  bool _matchesActivityScope({
    required String iconKey,
    required String text,
    required String relativeLabel,
  }) {
    final normalized = text.toLowerCase();
    if (_activityEntityFilter != 'all') {
      final entityMatches = switch (_activityEntityFilter) {
        'orders' => iconKey == 'orders' || normalized.contains('طلب'),
        'restaurants' => iconKey == 'store' || normalized.contains('مطعم'),
        'drivers' => iconKey == 'delivery' || normalized.contains('سائق'),
        'finance' => iconKey == 'finance' || normalized.contains('مال'),
        _ => true,
      };
      if (!entityMatches) return false;
    }
    if (_activityEmployeeFilter == 'admins' &&
        !normalized.contains('نظام') &&
        !normalized.contains('مشرف')) {
      return false;
    }
    if (_activityEmployeeFilter == 'support' && !normalized.contains('دعم')) {
      return false;
    }
    // The activity API currently returns a display-relative label rather than
    // a machine-readable event date. Keep the default view inclusive so an
    // old relative label cannot hide valid activity records.
    return true;
  }

  List<_ActivityFeedItemData> _filteredActivityFeed(
    _MasterOperationsData data,
  ) {
    return data.activityFeedItems.where((item) {
      return _matchesActivityText([
            item.title,
            item.subtitle,
            item.detail,
            item.pillLabel,
          ]) &&
          _matchesActivityScope(
            iconKey: item.icon == Icons.store
                ? 'store'
                : item.icon == Icons.delivery_dining
                ? 'delivery'
                : 'orders',
            text: '${item.title} ${item.subtitle} ${item.detail}',
            relativeLabel: item.relativeLabel,
          );
    }).toList();
  }

  List<_ActivityEventItemData> _filteredActivityEvents(
    _MasterOperationsData data,
  ) {
    return data.activityEventItems.where((item) {
      return _matchesActivityText([
            item.title,
            item.reference,
            item.role,
            item.note,
          ]) &&
          _matchesActivityScope(
            iconKey: item.icon == Icons.store
                ? 'store'
                : item.icon == Icons.delivery_dining
                ? 'delivery'
                : 'orders',
            text: '${item.title} ${item.reference} ${item.role} ${item.note}',
            relativeLabel: item.timeLabel,
          );
    }).toList();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  void dispose() {
    _trackingRefreshTimer?.cancel();
    super.dispose();
  }

  void _openSidebarItem(String itemKey) {
    final key = _masterCanonicalModuleKey(itemKey);
    if (key == 'operations') return;
    _navigateToMasterSection(
      context,
      key: key,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      serverNow: widget.serverNow,
    );
  }

  Widget _tab(String key, String label, IconData icon) {
    final selected = _subSection == key;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onSelected: (_) => setState(() => _subSection = key),
      selectedColor: _kDeepGreen,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _kDeepGreen : const Color(0xFFE0E7E2)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF44505B),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildActivityContent(_MasterOperationsData data) {
    final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
    final filteredFeed = _filteredActivityFeed(data);
    final filteredEvents = _filteredActivityEvents(data);
    final activityPanel = _activityFilter == 'events'
        ? _OperationsActivityEventsPanel(items: filteredEvents)
        : _OperationsActivityFeedPanel(items: filteredFeed);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            dateLabel: _formatArabicDateLabel(serverNow),
            viewFilter: _activityFilter,
            employeeFilter: _activityEmployeeFilter,
            periodFilter: _activityPeriodFilter,
            entityFilter: _activityEntityFilter,
            searchQuery: _activitySearch,
            autoRefresh: _activityAutoRefresh,
            onViewFilterChanged: (value) =>
                setState(() => _activityFilter = value),
            onEmployeeFilterChanged: (value) =>
                setState(() => _activityEmployeeFilter = value),
            onPeriodFilterChanged: (value) =>
                setState(() => _activityPeriodFilter = value),
            onEntityFilterChanged: (value) =>
                setState(() => _activityEntityFilter = value),
            onSearchChanged: (value) => setState(() => _activitySearch = value),
            onAutoRefreshChanged: (value) {
              setState(() => _activityAutoRefresh = value);
              if (value) _reload();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 580,
            child: _OperationsActivityAnalyticsPanel(stats: data.activityStats),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 700, child: activityPanel),
        ],
      ),
    );
  }

  Widget _buildContent(_MasterOperationsData data) {
    if (_subSection == 'activity') {
      return _buildActivityContent(data);
    }
    final tracking = _subSection == 'tracking';
    final main = tracking
        ? _OperationsTrackingCenterPanel(
            serverNow: data.serverNow ?? widget.serverNow ?? DateTime.now(),
            mapMarkers: _filterTrackingMarkers(
              data.trackingMapMarkers,
              _trackingFilter,
            ),
            routes: data.trackingRoutes,
            statusFilter: _trackingFilter,
            selectedDate: _trackingDate,
            onDateChanged: (value) => setState(() => _trackingDate = value),
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
            onStatusFilterChanged: (value) =>
                setState(() => _trackingFilter = value),
            onSuperTrackingPressed: () => _showSuperTrackingMap(
              context,
              markers: data.trackingMapMarkers,
              routes: data.trackingRoutes,
              api: widget.api,
              token: widget.session.token,
              reload: _load,
            ),
            showHeaderControls: false,
          )
        : _OperationsMainArea(
            serverNow: data.serverNow ?? widget.serverNow ?? DateTime.now(),
            statCards: data.overviewStatCards,
            mapMarkers: data.overviewMapMarkers,
            performanceCards: data.performanceCards,
            alertCards: data.alertCards,
            onRefresh: _reload,
          );
    final side = tracking
        ? _OperationsTrackingOrdersPanel(
            items: _filterTrackingOrders(
              data.trackingOrders,
              _trackingFilter,
              date: _trackingDate,
              orderType: _trackingOrderType,
            ),
            selectedFilter: _trackingFilter,
            onFilterChanged: (value) => setState(() => _trackingFilter = value),
            onOrderTap: (order) => _showTrackingOrderDetails(context, order),
          )
        : _OperationsLivePanel(items: data.overviewLiveItems);
    return Column(
      children: [
        if (tracking)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EAE5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _tab('activity', 'سجل النشاط', Icons.bolt_outlined),
                _tab('tracking', 'التتبع المباشر', Icons.map_outlined),
                _tab('overview', 'نظرة العمليات', Icons.dashboard_outlined),
                Container(width: 1, height: 28, color: const Color(0xFFE1E7E2)),
                _InteractiveTrackingHeaderFilters(
                  dateLabel: _formatArabicDateLabel(
                    data.serverNow ?? widget.serverNow ?? DateTime.now(),
                  ),
                  selectedDate: _trackingDate,
                  onDateChanged: (value) =>
                      setState(() => _trackingDate = value),
                  statusFilter: _trackingFilter,
                  onStatusFilterChanged: (value) =>
                      setState(() => _trackingFilter = value),
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
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _tab('activity', 'سجل النشاط', Icons.bolt_outlined),
              _tab('tracking', 'التتبع المباشر', Icons.map_outlined),
              _tab('overview', 'نظرة العمليات', Icons.dashboard_outlined),
            ],
          ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              final children = [
                Expanded(child: main),
                const SizedBox(width: 12),
                SizedBox(width: 320, child: side),
              ];
              return stacked
                  ? Column(
                      children: [
                        Expanded(child: main),
                        const SizedBox(height: 12),
                        SizedBox(height: 520, child: side),
                      ],
                    )
                  : Row(children: children);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _rememberMasterRuntime(widget.session, widget.onLogout, widget.api);
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'operations',
        label: 'لوحة العمليات',
        selected: true,
      ),
    ]);
    return _buildMasterUnifiedShell(
      context: context,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      sidebarItems: sidebarItems,
      onSidebarItemTap: _openSidebarItem,
      statusLabel: 'العمليات تعمل',
      platformTitle: 'لوحة العمليات',
      platformSubtitle: 'التتبع المباشر وإدارة التشغيل',
      serverNow: widget.serverNow,
      child: FutureBuilder<_MasterOperationsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: _OperationsDataErrorState(
                message:
                    snapshot.error?.toString() ?? 'تعذر تحميل بيانات العمليات',
                onRetry: _reload,
              ),
            );
          }
          return _buildContent(snapshot.data!);
        },
      ),
    );
  }
}
