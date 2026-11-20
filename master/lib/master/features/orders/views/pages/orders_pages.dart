// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

void _navigateToMasterOrderSubPage(
  BuildContext context,
  String key, {
  required MasterSession session,
  required Future<void> Function() onLogout,
  required MasterAuthApiService api,
  required DateTime serverNow,
}) {
  if (key == 'all') {
    _navigateToMasterSection(
      context,
      key: 'orders',
      session: session,
      onLogout: onLogout,
      api: api,
      serverNow: serverNow,
    );
    return;
  }

  Widget? page;
  switch (key) {
    case 'statuses':
      page = MasterOrderStatusesPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
      );
      break;
    case 'scheduled':
      page = MasterScheduledOrdersPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
      );
      break;
    case 'pickup':
      page = MasterPickupOrdersPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
      );
      break;
    case 'printing':
      page = MasterPrintingInvoicesPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
      );
      break;
    case 'chats':
      page = MasterOrderChatsPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
      );
      break;
  }
  if (page != null) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
  }
}

class MasterOrdersPage extends StatefulWidget {
  const MasterOrdersPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final bool unifiedFrame;

  @override
  State<MasterOrdersPage> createState() => _MasterOrdersPageState();
}

class _MasterOrdersPageState extends State<MasterOrdersPage> {
  late Future<_MasterOrdersData> _ordersFuture;
  final TextEditingController _ordersSearchController = TextEditingController();
  bool _showNavigationSidebar = true;
  bool _showInsightsSidebar = true;
  String _paymentFilter = 'all';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  int _ordersPage = 1;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<_MasterOrdersData> _loadOrders() {
    return widget.api
        ._fetchOrdersPage(
          widget.session.token,
          page: _ordersPage,
          query: _ordersSearchController.text.trim(),
          payment: _paymentFilter,
          status: _statusFilter,
          type: _typeFilter,
        )
        .timeout(const Duration(seconds: 20));
  }

  void _reloadOrders() {
    setState(() {
      _ordersPage = 1;
      _ordersFuture = _loadOrders();
    });
  }

  void _goToOrdersPage(int page) {
    if (page < 1 || page == _ordersPage) {
      return;
    }
    setState(() {
      _ordersPage = page;
      _ordersFuture = _loadOrders();
    });
  }

  Future<void> _exportAllOrders(_MasterOrdersData current) async {
    try {
      final first = await widget.api._fetchOrdersPage(
        widget.session.token,
        page: 1,
        limit: 100,
        query: _ordersSearchController.text.trim(),
        payment: _paymentFilter,
        status: _statusFilter,
        type: _typeFilter,
      );
      final all = <_MasterOrderRowData>[...first.orders];
      final pages = (first.total / 100).ceil();
      for (var page = 2; page <= pages; page++) {
        final next = await widget.api._fetchOrdersPage(
          widget.session.token,
          page: page,
          limit: 100,
          query: _ordersSearchController.text.trim(),
          payment: _paymentFilter,
          status: _statusFilter,
          type: _typeFilter,
        );
        all.addAll(next.orders);
      }
      if (mounted) {
        _exportOrdersToClipboard(context, current, 'الطلبات', orders: all);
      }
    } catch (error) {
      if (mounted) _showMasterSnack(context, 'تعذر تصدير الطلبات: $error');
    }
  }

  void _setPaymentFilter(String value) {
    setState(() {
      _paymentFilter = value;
      _ordersPage = 1;
      _ordersFuture = _loadOrders();
    });
  }

  void _setStatusFilter(String value) {
    setState(() {
      _statusFilter = value;
      _ordersPage = 1;
      _ordersFuture = _loadOrders();
    });
  }

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      _ordersPage = 1;
      _ordersFuture = _loadOrders();
    });
  }

  Future<void> _exportAllScheduled(_MasterOrdersData current) async {
    try {
      final first = await widget.api._fetchOrdersPage(
        widget.session.token,
        page: 1,
        limit: 100,
        query: _ordersSearchController.text.trim(),
        type: _typeFilter,
        scheduledOnly: true,
      );
      final all = <_MasterOrderRowData>[...first.orders];
      for (var page = 2; page <= (first.total / 100).ceil(); page++) {
        final next = await widget.api._fetchOrdersPage(
          widget.session.token,
          page: page,
          limit: 100,
          query: _ordersSearchController.text.trim(),
          type: _typeFilter,
          scheduledOnly: true,
        );
        all.addAll(next.orders);
      }
      if (mounted) {
        _exportOrdersToClipboard(
          context,
          current,
          'الطلبات المجدولة',
          orders: all,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, 'تعذر تصدير الطلبات المجدولة: $error');
      }
    }
  }

  void _openOrderSubPage(String key, DateTime serverNow) {
    if (key == 'all') {
      return;
    }
    Widget? page;
    switch (key) {
      case 'statuses':
        page = MasterOrderStatusesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'scheduled':
        page = MasterScheduledOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'pickup':
        page = MasterPickupOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'printing':
        page = MasterPrintingInvoicesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'chats':
        page = MasterOrderChatsPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
    }
    if (page != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
    }
  }

  @override
  void dispose() {
    _ordersSearchController.dispose();
    super.dispose();
  }

  void _openOrdersUnifiedSubPage(
    BuildContext context,
    String key,
    DateTime serverNow,
  ) {
    _navigateToMasterOrderSubPage(
      context,
      key,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      serverNow: serverNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedOrdersFrame(context);
    }
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState != ConnectionState.done) {
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

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadOrders,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final sidebarWidth = wide ? 258.0 : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _OrdersMainWorkspace(
                            data: data,
                            serverNow: serverNow,
                            onReload: _reloadOrders,
                            searchController: _ordersSearchController,
                            paymentFilter: _paymentFilter,
                            statusFilter: _statusFilter,
                            typeFilter: _typeFilter,
                            onSearchSubmitted: _reloadOrders,
                            onPaymentChanged: _setPaymentFilter,
                            onStatusChanged: _setStatusFilter,
                            onTypeChanged: _setTypeFilter,
                            showInsightsSidebar: _showInsightsSidebar,
                            showNavigationSidebar: _showNavigationSidebar,
                            onToggleInsightsSidebar: () {
                              setState(
                                () => _showInsightsSidebar =
                                    !_showInsightsSidebar,
                              );
                            },
                            onToggleNavigationSidebar: () {
                              setState(
                                () => _showNavigationSidebar =
                                    !_showNavigationSidebar,
                              );
                            },
                            onExport: () => _exportAllOrders(data),
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _OrdersRightSidebar(
                              activeSubPage: 'all',
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSubPageTap: (key) {
                                if (key == 'all') {
                                  return;
                                }
                                if (key == 'statuses') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderStatusesPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'scheduled') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterScheduledOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'pickup') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterPickupOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'printing') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MasterPrintingInvoicesPage(
                                            session: widget.session,
                                            onLogout: widget.onLogout,
                                            api: widget.api,
                                            serverNow: serverNow,
                                          ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'chats') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderChatsPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _showMasterSnack(
                                  context,
                                  'هذا القسم غير متاح لهذا الحساب',
                                );
                              },
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
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

  Widget _buildUnifiedOrdersFrame(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'orders',
        label: 'إدارة الطلبات',
        selected: true,
      ),
    ]);
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildMasterUnifiedShell(
            context: context,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            sidebarItems: sidebarItems,
            onSidebarItemTap: (key) => _navigateToMasterSection(
              context,
              key: key,
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: widget.serverNow,
            ),
            statusLabel: 'جميع الطلبات',
            platformTitle: 'إدارة الطلبات',
            platformSubtitle: 'مركز موحد لمتابعة وإدارة الطلبات',
            serverNow: widget.serverNow,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _buildMasterUnifiedShell(
            context: context,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            sidebarItems: sidebarItems,
            onSidebarItemTap: (key) => _navigateToMasterSection(
              context,
              key: key,
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: widget.serverNow,
            ),
            statusLabel: 'تعذر تحميل الطلبات',
            platformTitle: 'إدارة الطلبات',
            platformSubtitle: 'مركز موحد لمتابعة وإدارة الطلبات',
            serverNow: widget.serverNow,
            child: _OperationsDataErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadOrders,
            ),
          );
        }
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final effectiveNow =
            data.serverNow ?? widget.serverNow ?? DateTime.now();
        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: (key) => _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: effectiveNow,
          ),
          statusLabel: 'الطلبات متزامنة',
          platformTitle: 'إدارة الطلبات',
          platformSubtitle: 'مركز موحد لمتابعة وإدارة الطلبات',
          serverNow: effectiveNow,
          child: _OrdersMainWorkspace(
            data: data,
            serverNow: effectiveNow,
            onReload: _reloadOrders,
            searchController: _ordersSearchController,
            paymentFilter: _paymentFilter,
            statusFilter: _statusFilter,
            typeFilter: _typeFilter,
            onSearchSubmitted: _reloadOrders,
            onPaymentChanged: _setPaymentFilter,
            onStatusChanged: _setStatusFilter,
            onTypeChanged: _setTypeFilter,
            showInsightsSidebar: _showInsightsSidebar,
            showNavigationSidebar: false,
            onSubPageTap: (key) => _openOrderSubPage(key, effectiveNow),
            activeSubPage: 'all',
            onToggleInsightsSidebar: () {
              setState(() => _showInsightsSidebar = !_showInsightsSidebar);
            },
            onToggleNavigationSidebar: () {},
            onExport: () => _exportAllOrders(data),
          ),
        );
      },
    );
  }
}

class MasterOrderStatusesPage extends StatefulWidget {
  const MasterOrderStatusesPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final bool unifiedFrame;

  @override
  State<MasterOrderStatusesPage> createState() =>
      _MasterOrderStatusesPageState();
}

class _MasterOrderStatusesPageState extends State<MasterOrderStatusesPage> {
  late Future<_MasterOrdersData> _ordersFuture;
  final TextEditingController _ordersSearchController = TextEditingController();
  bool _showNavigationSidebar = true;
  String _paymentFilter = 'all';
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<_MasterOrdersData> _loadOrders() {
    return widget.api
        ._fetchOrdersPage(
          widget.session.token,
          query: _ordersSearchController.text.trim(),
          payment: _paymentFilter,
          status: _statusFilter,
          type: _typeFilter,
        )
        .timeout(const Duration(seconds: 20));
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  void _setPaymentFilter(String value) {
    setState(() {
      _paymentFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  void _setStatusFilter(String value) {
    setState(() {
      _statusFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  @override
  void dispose() {
    _ordersSearchController.dispose();
    super.dispose();
  }

  void _openOrdersUnifiedSubPage(
    BuildContext context,
    String key,
    DateTime serverNow,
  ) {
    if (key == 'statuses') return;
    Widget? page;
    switch (key) {
      case 'all':
        page = MasterOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'scheduled':
        page = MasterScheduledOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'pickup':
        page = MasterPickupOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'printing':
        page = MasterPrintingInvoicesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'chats':
        page = MasterOrderChatsPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
    }
    if (page != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedStatusesFrame(context);
    }
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadOrders,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final sidebarWidth = wide ? 258.0 : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _OrderStatusesWorkspace(
                            data: data,
                            serverNow: serverNow,
                            onReload: _reloadOrders,
                            searchController: _ordersSearchController,
                            paymentFilter: _paymentFilter,
                            statusFilter: _statusFilter,
                            typeFilter: _typeFilter,
                            onSearchSubmitted: _reloadOrders,
                            onPaymentChanged: _setPaymentFilter,
                            onStatusChanged: _setStatusFilter,
                            onTypeChanged: _setTypeFilter,
                            showNavigationSidebar: _showNavigationSidebar,
                            onToggleNavigationSidebar: () {
                              setState(
                                () => _showNavigationSidebar =
                                    !_showNavigationSidebar,
                              );
                            },
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _OrdersRightSidebar(
                              activeSubPage: 'statuses',
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSubPageTap: (key) {
                                if (key == 'statuses') {
                                  return;
                                }
                                if (key == 'all') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'scheduled') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterScheduledOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'pickup') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterPickupOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'printing') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MasterPrintingInvoicesPage(
                                            session: widget.session,
                                            onLogout: widget.onLogout,
                                            api: widget.api,
                                            serverNow: serverNow,
                                          ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'chats') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderChatsPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _showMasterSnack(
                                  context,
                                  'هذا القسم غير متاح لهذا الحساب',
                                );
                              },
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
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

  Widget _buildUnifiedStatusesFrame(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'orders',
        label: 'إدارة الطلبات',
        selected: true,
      ),
    ]);
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        Widget body;
        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          body = _OperationsDataErrorState(
            message: snapshot.error.toString(),
            onRetry: _reloadOrders,
          );
        } else {
          body = Column(
            children: [
              _OrdersSectionTabs(
                activeKey: 'statuses',
                onTap: (key) =>
                    _openOrdersUnifiedSubPage(context, key, serverNow),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _OrderStatusesWorkspace(
                  data: data,
                  serverNow: serverNow,
                  onReload: _reloadOrders,
                  searchController: _ordersSearchController,
                  paymentFilter: _paymentFilter,
                  statusFilter: _statusFilter,
                  typeFilter: _typeFilter,
                  onSearchSubmitted: _reloadOrders,
                  onPaymentChanged: _setPaymentFilter,
                  onStatusChanged: _setStatusFilter,
                  onTypeChanged: _setTypeFilter,
                  showNavigationSidebar: false,
                  onToggleNavigationSidebar: () {},
                ),
              ),
            ],
          );
        }
        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: (key) => _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
          ),
          statusLabel: 'الطلبات متزامنة',
          platformTitle: 'إدارة الطلبات',
          platformSubtitle: 'حالات الطلبات والمتابعة التشغيلية',
          serverNow: serverNow,
          child: body,
        );
      },
    );
  }
}

class MasterScheduledOrdersPage extends StatefulWidget {
  const MasterScheduledOrdersPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final bool unifiedFrame;

  @override
  State<MasterScheduledOrdersPage> createState() =>
      _MasterScheduledOrdersPageState();
}

class _MasterScheduledOrdersPageState extends State<MasterScheduledOrdersPage> {
  late Future<_MasterOrdersData> _ordersFuture;
  final TextEditingController _ordersSearchController = TextEditingController();
  bool _showNavigationSidebar = true;
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<_MasterOrdersData> _loadOrders() {
    return widget.api
        ._fetchOrdersPage(
          widget.session.token,
          query: _ordersSearchController.text.trim(),
          type: _typeFilter,
          scheduledOnly: true,
        )
        .timeout(const Duration(seconds: 20));
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  Future<void> _exportAllScheduled(_MasterOrdersData current) async {
    try {
      final first = await widget.api._fetchOrdersPage(
        widget.session.token,
        page: 1,
        limit: 100,
        query: _ordersSearchController.text.trim(),
        type: _typeFilter,
        scheduledOnly: true,
      );
      final all = <_MasterOrderRowData>[...first.orders];
      final pages = (first.total / 100).ceil();
      for (var page = 2; page <= pages; page++) {
        final next = await widget.api._fetchOrdersPage(
          widget.session.token,
          page: page,
          limit: 100,
          query: _ordersSearchController.text.trim(),
          type: _typeFilter,
          scheduledOnly: true,
        );
        all.addAll(next.orders);
      }
      if (mounted) {
        _exportOrdersToClipboard(
          context,
          current,
          'الطلبات المجدولة',
          orders: all,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, 'تعذر تصدير الطلبات المجدولة: $error');
      }
    }
  }

  @override
  void dispose() {
    _ordersSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedScheduledFrame(context);
    }
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState != ConnectionState.done) {
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

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadOrders,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final sidebarWidth = wide ? 258.0 : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ScheduledOrdersWorkspace(
                            data: data,
                            serverNow: serverNow,
                            onReload: _reloadOrders,
                            searchController: _ordersSearchController,
                            typeFilter: _typeFilter,
                            onSearchSubmitted: _reloadOrders,
                            onTypeChanged: _setTypeFilter,
                            showNavigationSidebar: _showNavigationSidebar,
                            onToggleNavigationSidebar: () {
                              setState(
                                () => _showNavigationSidebar =
                                    !_showNavigationSidebar,
                              );
                            },
                            onExport: () => _exportAllScheduled(data),
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _OrdersRightSidebar(
                              activeSubPage: 'scheduled',
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSubPageTap: (key) {
                                if (key == 'scheduled') {
                                  return;
                                }
                                if (key == 'all') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'statuses') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderStatusesPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'pickup') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterPickupOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'printing') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MasterPrintingInvoicesPage(
                                            session: widget.session,
                                            onLogout: widget.onLogout,
                                            api: widget.api,
                                            serverNow: serverNow,
                                          ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'chats') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderChatsPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _showMasterSnack(
                                  context,
                                  'هذا القسم غير متاح لهذا الحساب',
                                );
                              },
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
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

  Widget _buildUnifiedScheduledFrame(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'orders',
        label: 'إدارة الطلبات',
        selected: true,
      ),
    ]);
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        final body = snapshot.hasError
            ? _OperationsDataErrorState(
                message: snapshot.error.toString(),
                onRetry: _reloadOrders,
              )
            : Column(
                children: [
                  _OrdersSectionTabs(
                    activeKey: 'scheduled',
                    onTap: (key) =>
                        _openScheduledSubPage(context, key, serverNow),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _ScheduledOrdersWorkspace(
                      data: data,
                      serverNow: serverNow,
                      onReload: _reloadOrders,
                      searchController: _ordersSearchController,
                      typeFilter: _typeFilter,
                      onSearchSubmitted: _reloadOrders,
                      onTypeChanged: _setTypeFilter,
                      showNavigationSidebar: false,
                      onToggleNavigationSidebar: () {},
                      onExport: () => _exportAllScheduled(data),
                    ),
                  ),
                ],
              );
        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: (key) => _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
          ),
          statusLabel: 'الطلبات متزامنة',
          platformTitle: 'إدارة الطلبات',
          platformSubtitle: 'إدارة الطلبات المجدولة',
          serverNow: serverNow,
          child: body,
        );
      },
    );
  }

  void _openScheduledSubPage(
    BuildContext context,
    String key,
    DateTime serverNow,
  ) {
    if (key == 'scheduled') return;
    Widget? page;
    switch (key) {
      case 'all':
        page = MasterOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'statuses':
        page = MasterOrderStatusesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'pickup':
        page = MasterPickupOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'printing':
        page = MasterPrintingInvoicesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'chats':
        page = MasterOrderChatsPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
    }
    if (page != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
    }
  }
}

class MasterPickupOrdersPage extends StatefulWidget {
  const MasterPickupOrdersPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final bool unifiedFrame;

  @override
  State<MasterPickupOrdersPage> createState() => _MasterPickupOrdersPageState();
}

class _MasterPickupOrdersPageState extends State<MasterPickupOrdersPage> {
  late Future<_MasterOrdersData> _ordersFuture;
  final TextEditingController _ordersSearchController = TextEditingController();
  bool _showNavigationSidebar = true;
  String _paymentFilter = 'all';
  String _statusFilter = 'all';

  Future<void> _exportAllPickup(_MasterOrdersData current) async {
    try {
      final first = await widget.api._fetchOrdersPage(
        widget.session.token,
        page: 1,
        limit: 100,
        query: _ordersSearchController.text.trim(),
        payment: _paymentFilter,
        status: _statusFilter,
        type: 'pickup',
      );
      final all = <_MasterOrderRowData>[...first.orders];
      for (var page = 2; page <= (first.total / 100).ceil(); page++) {
        final next = await widget.api._fetchOrdersPage(
          widget.session.token,
          page: page,
          limit: 100,
          query: _ordersSearchController.text.trim(),
          payment: _paymentFilter,
          status: _statusFilter,
          type: 'pickup',
        );
        all.addAll(next.orders);
      }
      if (mounted) {
        _exportOrdersToClipboard(context, current, 'طلبات Pickup', orders: all);
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, 'تعذر تصدير طلبات الاستلام: $error');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<_MasterOrdersData> _loadOrders() {
    return widget.api
        ._fetchOrdersPage(
          widget.session.token,
          query: _ordersSearchController.text.trim(),
          payment: _paymentFilter,
          status: _statusFilter,
          type: 'pickup',
        )
        .timeout(const Duration(seconds: 20));
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  void _setPaymentFilter(String value) {
    setState(() {
      _paymentFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  void _setStatusFilter(String value) {
    setState(() {
      _statusFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  @override
  void dispose() {
    _ordersSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedPickupFrame(context);
    }
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState != ConnectionState.done) {
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

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadOrders,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final sidebarWidth = wide ? 258.0 : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PickupOrdersWorkspace(
                            data: data,
                            serverNow: serverNow,
                            onReload: _reloadOrders,
                            searchController: _ordersSearchController,
                            paymentFilter: _paymentFilter,
                            statusFilter: _statusFilter,
                            onSearchSubmitted: _reloadOrders,
                            onPaymentChanged: _setPaymentFilter,
                            onStatusChanged: _setStatusFilter,
                            showNavigationSidebar: _showNavigationSidebar,
                            onToggleNavigationSidebar: () {
                              setState(
                                () => _showNavigationSidebar =
                                    !_showNavigationSidebar,
                              );
                            },
                            onExport: () => _exportAllPickup(data),
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _OrdersRightSidebar(
                              activeSubPage: 'pickup',
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSubPageTap: (key) {
                                if (key == 'pickup') {
                                  return;
                                }
                                if (key == 'all') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'statuses') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderStatusesPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'scheduled') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterScheduledOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'printing') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MasterPrintingInvoicesPage(
                                            session: widget.session,
                                            onLogout: widget.onLogout,
                                            api: widget.api,
                                            serverNow: serverNow,
                                          ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'chats') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderChatsPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _showMasterSnack(
                                  context,
                                  'هذا القسم غير متاح لهذا الحساب',
                                );
                              },
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
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

  Widget _buildUnifiedPickupFrame(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'orders',
        label: 'إدارة الطلبات',
        selected: true,
      ),
    ]);
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        final body = snapshot.hasError
            ? _OperationsDataErrorState(
                message: snapshot.error.toString(),
                onRetry: _reloadOrders,
              )
            : Column(
                children: [
                  _OrdersSectionTabs(
                    activeKey: 'pickup',
                    onTap: (key) => _openPickupSubPage(context, key, serverNow),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _PickupOrdersWorkspace(
                      data: data,
                      serverNow: serverNow,
                      onReload: _reloadOrders,
                      searchController: _ordersSearchController,
                      paymentFilter: _paymentFilter,
                      statusFilter: _statusFilter,
                      onSearchSubmitted: _reloadOrders,
                      onPaymentChanged: _setPaymentFilter,
                      onStatusChanged: _setStatusFilter,
                      showNavigationSidebar: false,
                      onToggleNavigationSidebar: () {},
                      onExport: () => _exportAllPickup(data),
                    ),
                  ),
                ],
              );
        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: (key) => _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
          ),
          statusLabel: 'الطلبات متزامنة',
          platformTitle: 'إدارة الطلبات',
          platformSubtitle: 'طلبات الاستلام من المتجر',
          serverNow: serverNow,
          child: body,
        );
      },
    );
  }

  void _openPickupSubPage(
    BuildContext context,
    String key,
    DateTime serverNow,
  ) {
    if (key == 'pickup') return;
    Widget? page;
    switch (key) {
      case 'all':
        page = MasterOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'statuses':
        page = MasterOrderStatusesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'scheduled':
        page = MasterScheduledOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'printing':
        page = MasterPrintingInvoicesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'chats':
        page = MasterOrderChatsPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
    }
    if (page != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
    }
  }
}

class MasterPrintingInvoicesPage extends StatefulWidget {
  const MasterPrintingInvoicesPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final bool unifiedFrame;

  @override
  State<MasterPrintingInvoicesPage> createState() =>
      _MasterPrintingInvoicesPageState();
}

class _MasterPrintingInvoicesPageState
    extends State<MasterPrintingInvoicesPage> {
  late Future<_MasterOrdersData> _ordersFuture;
  final TextEditingController _ordersSearchController = TextEditingController();
  bool _showNavigationSidebar = true;
  String _paymentFilter = 'all';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String? _selectedOrderKey;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<_MasterOrdersData> _loadOrders() {
    return widget.api
        ._fetchOrdersPage(
          widget.session.token,
          query: _ordersSearchController.text.trim(),
          payment: _paymentFilter,
          status: _statusFilter,
          type: _typeFilter,
        )
        .timeout(const Duration(seconds: 20));
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  void _selectOrder(_MasterOrderRowData order) {
    setState(() {
      _selectedOrderKey = _orderSelectionKey(order);
    });
  }

  void _setPaymentFilter(String value) {
    setState(() {
      _paymentFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  void _setStatusFilter(String value) {
    setState(() {
      _statusFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      _ordersFuture = _loadOrders();
    });
  }

  Future<void> _savePrintingSettings(int copies, bool printLogo) async {
    await widget.api.updateMasterPrintSettings(
      widget.session.token,
      invoiceCopies: copies,
      printLogo: printLogo,
    );
    if (mounted) {
      _showMasterSnack(context, 'تم حفظ إعدادات الطباعة');
    }
  }

  @override
  void dispose() {
    _ordersSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedPrintingFrame(context);
    }
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadOrders,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final sidebarWidth = wide ? 258.0 : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PrintingInvoicesWorkspace(
                            data: data,
                            serverNow: serverNow,
                            onReload: _reloadOrders,
                            searchController: _ordersSearchController,
                            paymentFilter: _paymentFilter,
                            statusFilter: _statusFilter,
                            typeFilter: _typeFilter,
                            onSearchSubmitted: _reloadOrders,
                            onPaymentChanged: _setPaymentFilter,
                            onStatusChanged: _setStatusFilter,
                            onTypeChanged: _setTypeFilter,
                            selectedOrderKey: _selectedOrderKey,
                            onOrderSelected: _selectOrder,
                            showNavigationSidebar: _showNavigationSidebar,
                            onToggleNavigationSidebar: () {
                              setState(
                                () => _showNavigationSidebar =
                                    !_showNavigationSidebar,
                              );
                            },
                            onSavePrintingSettings: _savePrintingSettings,
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _OrdersRightSidebar(
                              activeSubPage: 'printing',
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSubPageTap: (key) {
                                if (key == 'printing') {
                                  return;
                                }
                                if (key == 'all') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'statuses') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderStatusesPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'scheduled') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterScheduledOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'pickup') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterPickupOrdersPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (key == 'chats') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => MasterOrderChatsPage(
                                        session: widget.session,
                                        onLogout: widget.onLogout,
                                        api: widget.api,
                                        serverNow: serverNow,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _showMasterSnack(
                                  context,
                                  'هذا القسم غير متاح لهذا الحساب',
                                );
                              },
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
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

  Widget _buildUnifiedPrintingFrame(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'orders',
        label: 'إدارة الطلبات',
        selected: true,
      ),
    ]);
    return FutureBuilder<_MasterOrdersData>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrdersData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        final body = snapshot.hasError
            ? _OperationsDataErrorState(
                message: snapshot.error.toString(),
                onRetry: _reloadOrders,
              )
            : Column(
                children: [
                  _OrdersSectionTabs(
                    activeKey: 'printing',
                    onTap: (key) =>
                        _openPrintingSubPage(context, key, serverNow),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _PrintingInvoicesWorkspace(
                      data: data,
                      serverNow: serverNow,
                      onReload: _reloadOrders,
                      searchController: _ordersSearchController,
                      paymentFilter: _paymentFilter,
                      statusFilter: _statusFilter,
                      typeFilter: _typeFilter,
                      onSearchSubmitted: _reloadOrders,
                      onPaymentChanged: _setPaymentFilter,
                      onStatusChanged: _setStatusFilter,
                      onTypeChanged: _setTypeFilter,
                      selectedOrderKey: _selectedOrderKey,
                      onOrderSelected: _selectOrder,
                      showNavigationSidebar: false,
                      onToggleNavigationSidebar: () {},
                      onSavePrintingSettings: _savePrintingSettings,
                    ),
                  ),
                ],
              );
        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: (key) => _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
          ),
          statusLabel: 'الطلبات متزامنة',
          platformTitle: 'إدارة الطلبات',
          platformSubtitle: 'الفواتير والطباعة',
          serverNow: serverNow,
          child: body,
        );
      },
    );
  }

  void _openPrintingSubPage(
    BuildContext context,
    String key,
    DateTime serverNow,
  ) {
    if (key == 'printing') return;
    Widget? page;
    switch (key) {
      case 'all':
        page = MasterOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'statuses':
        page = MasterOrderStatusesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'scheduled':
        page = MasterScheduledOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'pickup':
        page = MasterPickupOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'chats':
        page = MasterOrderChatsPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
    }
    if (page != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
    }
  }
}

class MasterOrderChatsPage extends StatefulWidget {
  const MasterOrderChatsPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    required this.serverNow,
    this.initialOrderId,
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime serverNow;
  final int? initialOrderId;
  final bool unifiedFrame;

  @override
  State<MasterOrderChatsPage> createState() => _MasterOrderChatsPageState();
}

class _MasterOrderChatsPageState extends State<MasterOrderChatsPage> {
  late Future<_MasterOrderChatsData> _chatsFuture;
  final TextEditingController _ordersSearchController = TextEditingController();
  String _statusFilter = 'all';
  String _chatStateFilter = 'all';
  int? _selectedOrderId;
  bool _showNavigationSidebar = true;
  Timer? _chatPollTimer;
  bool _chatReloading = false;

  @override
  void initState() {
    super.initState();
    _selectedOrderId = widget.initialOrderId;
    _chatsFuture = _loadChats();
    _chatPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _reloadChats(silent: true);
    });
  }

  @override
  void dispose() {
    _chatPollTimer?.cancel();
    _ordersSearchController.dispose();
    super.dispose();
  }

  Future<_MasterOrderChatsData> _loadChats() {
    return widget.api
        ._fetchMasterOrderChats(
          widget.session.token,
          query: _ordersSearchController.text.trim(),
          status: _statusFilter,
          state: _chatStateFilter,
          orderId: _selectedOrderId,
        )
        .timeout(const Duration(seconds: 18));
  }

  void _reloadChats({bool silent = false}) {
    if (_chatReloading) return;
    _chatReloading = true;
    final future = _loadChats();
    future.whenComplete(() => _chatReloading = false);
    setState(() {
      _chatsFuture = future;
    });
  }

  void _setStatusFilter(String value) {
    setState(() => _statusFilter = value);
    _reloadChats();
  }

  void _setChatStateFilter(String value) {
    setState(() => _chatStateFilter = value);
    _reloadChats();
  }

  void _selectConversation(_OrderChatConversationData conversation) {
    setState(() {
      _selectedOrderId = conversation.orderId;
      _chatsFuture = _loadChats();
    });
  }

  Future<void> _sendAdminMessage(String message) async {
    final orderId = _selectedOrderId;
    if (orderId == null || orderId <= 0) {
      _showMasterSnack(context, 'اختر محادثة أولا');
      return;
    }
    await widget.api._sendMasterOrderChatMessage(
      widget.session.token,
      orderId: orderId,
      message: message,
    );
    _reloadChats();
  }

  Future<void> _sendAdminMedia(html.File file, String message) async {
    final orderId = _selectedOrderId;
    if (orderId == null || orderId <= 0) {
      _showMasterSnack(context, 'اختر محادثة أولا');
      return;
    }
    await widget.api._uploadMasterOrderChatMedia(
      widget.session.token,
      orderId: orderId,
      file: file,
      message: message,
    );
    _reloadChats();
  }

  Future<void> _sendCustomerNotification(
    _OrderChatConversationData conversation,
  ) async {
    await widget.api._sendMasterOrderChatMessage(
      widget.session.token,
      orderId: conversation.orderId,
      message: 'تنبيه من الدعم: نتابع طلبك ${conversation.orderNo} الآن.',
    );
    if (mounted) {
      _showMasterSnack(context, 'تم إرسال الإشعار وحفظه في محادثة الطلب');
    }
    _reloadChats();
  }

  Future<void> _cancelOrderFromChat(
    _OrderChatConversationData conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: Text('هل تريد إلغاء الطلب ${conversation.orderNo}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.api._runMasterOrderAction(
      widget.session.token,
      orderId: conversation.orderId,
      action: 'cancel',
      note: 'Canceled from master order chat',
    );
    if (mounted) {
      _showMasterSnack(context, 'تم إلغاء الطلب وتحديث قاعدة البيانات');
    }
    _reloadChats();
  }

  void _openSubPage(String key, DateTime serverNow) {
    if (key == 'chats') {
      return;
    }
    Widget? page;
    if (key == 'all') {
      page = MasterOrdersPage(
        session: widget.session,
        onLogout: widget.onLogout,
        api: widget.api,
        serverNow: serverNow,
      );
    } else if (key == 'statuses') {
      page = MasterOrderStatusesPage(
        session: widget.session,
        onLogout: widget.onLogout,
        api: widget.api,
        serverNow: serverNow,
      );
    } else if (key == 'scheduled') {
      page = MasterScheduledOrdersPage(
        session: widget.session,
        onLogout: widget.onLogout,
        api: widget.api,
        serverNow: serverNow,
      );
    } else if (key == 'pickup') {
      page = MasterPickupOrdersPage(
        session: widget.session,
        onLogout: widget.onLogout,
        api: widget.api,
        serverNow: serverNow,
      );
    } else if (key == 'printing') {
      page = MasterPrintingInvoicesPage(
        session: widget.session,
        onLogout: widget.onLogout,
        api: widget.api,
        serverNow: serverNow,
      );
    }
    if (page == null) {
      _showMasterSnack(context, 'هذا القسم غير متاح لهذا الحساب');
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedChatsFrame(context);
    }
    return FutureBuilder<_MasterOrderChatsData>(
      future: _chatsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrderChatsData.empty();
        final serverNow = data.serverNow ?? widget.serverNow;

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: _OperationsDataErrorState(
                message: snapshot.error.toString(),
                onRetry: _reloadChats,
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final sidebarWidth = wide ? 258.0 : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _OrderChatsWorkspace(
                            data: data,
                            serverNow: serverNow,
                            onReload: _reloadChats,
                            searchController: _ordersSearchController,
                            statusFilter: _statusFilter,
                            chatStateFilter: _chatStateFilter,
                            onSearchSubmitted: _reloadChats,
                            onStatusChanged: _setStatusFilter,
                            onChatStateChanged: _setChatStateFilter,
                            selectedOrderId: _selectedOrderId,
                            onConversationSelected: _selectConversation,
                            onSendAdminMessage: _sendAdminMessage,
                            onSendAdminMedia: _sendAdminMedia,
                            onNotifyCustomer: _sendCustomerNotification,
                            onCancelOrder: _cancelOrderFromChat,
                            showNavigationSidebar: _showNavigationSidebar,
                            onToggleNavigationSidebar: () {
                              setState(
                                () => _showNavigationSidebar =
                                    !_showNavigationSidebar,
                              );
                            },
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _OrdersRightSidebar(
                              activeSubPage: 'chats',
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSubPageTap: (key) =>
                                  _openSubPage(key, serverNow),
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
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

  Widget _buildUnifiedChatsFrame(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'orders',
        label: 'إدارة الطلبات',
        selected: true,
      ),
    ]);
    return FutureBuilder<_MasterOrderChatsData>(
      future: _chatsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterOrderChatsData.empty();
        final serverNow = data.serverNow ?? widget.serverNow;
        final body = snapshot.hasError && !snapshot.hasData
            ? _OperationsDataErrorState(
                message: snapshot.error.toString(),
                onRetry: _reloadChats,
              )
            : Column(
                children: [
                  _OrdersSectionTabs(
                    activeKey: 'chats',
                    onTap: (key) => _openChatsSubPage(context, key, serverNow),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _OrderChatsWorkspace(
                      data: data,
                      serverNow: serverNow,
                      onReload: _reloadChats,
                      searchController: _ordersSearchController,
                      statusFilter: _statusFilter,
                      chatStateFilter: _chatStateFilter,
                      onSearchSubmitted: _reloadChats,
                      onStatusChanged: _setStatusFilter,
                      onChatStateChanged: _setChatStateFilter,
                      selectedOrderId: _selectedOrderId,
                      onConversationSelected: _selectConversation,
                      onSendAdminMessage: _sendAdminMessage,
                      onSendAdminMedia: _sendAdminMedia,
                      onNotifyCustomer: _sendCustomerNotification,
                      onCancelOrder: _cancelOrderFromChat,
                      showNavigationSidebar: false,
                      onToggleNavigationSidebar: () {},
                    ),
                  ),
                ],
              );
        return _buildMasterUnifiedShell(
          context: context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          sidebarItems: sidebarItems,
          onSidebarItemTap: (key) => _navigateToMasterSection(
            context,
            key: key,
            session: widget.session,
            onLogout: widget.onLogout,
            api: widget.api,
            serverNow: serverNow,
          ),
          statusLabel: 'المحادثات متزامنة',
          platformTitle: 'إدارة الطلبات',
          platformSubtitle: 'محادثات الطلبات ومتابعة العملاء والسائقين',
          serverNow: serverNow,
          child: body,
        );
      },
    );
  }

  void _openChatsSubPage(BuildContext context, String key, DateTime serverNow) {
    if (key == 'chats') return;
    Widget? page;
    switch (key) {
      case 'all':
        page = MasterOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'statuses':
        page = MasterOrderStatusesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'scheduled':
        page = MasterScheduledOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
      case 'pickup':
        page = MasterPickupOrdersPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
        break;
      case 'printing':
        page = MasterPrintingInvoicesPage(
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          unifiedFrame: true,
          serverNow: serverNow,
        );
        break;
    }
    if (page != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
    }
  }
}
