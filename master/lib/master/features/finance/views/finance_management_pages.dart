// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterFinancePage extends StatefulWidget {
  const MasterFinancePage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.initialSubPage = 'wallets',
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final String initialSubPage;
  final bool unifiedFrame;

  @override
  State<MasterFinancePage> createState() => _MasterFinancePageState();
}

class _MasterFinancePageState extends State<MasterFinancePage> {
  late String _activeSubPage;
  bool _showNavigationSidebar = true;
  String _financeStatusFilter = 'all';
  String _financeTypeFilter = 'all';
  String _financeSourceFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  late Future<Map<String, dynamic>> _financeOverviewFuture;

  int _selectedWalletIndex = 0;
  int _selectedCommissionIndex = 0;
  int _selectedFeeIndex = 0;
  int _selectedCouponIndex = 0;
  int _selectedRecordIndex = 0;
  int _selectedRefundIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeSubPage = widget.initialSubPage;
    _financeOverviewFuture = widget.api._fetchMasterFinanceOverviewRaw(
      widget.session.token,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedFinanceFrame(context);
    }
    final serverNow = widget.serverNow ?? DateTime.now();
    return FutureBuilder<Map<String, dynamic>>(
      future: _financeOverviewFuture,
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
                        Icons.error_outline,
                        size: 34,
                        color: Color(0xFFD92C2C),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر تحميل البيانات المالية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error?.toString() ?? 'حدث خطأ غير متوقع',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.6,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6F7680),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _financeOverviewFuture = widget.api
                                ._fetchMasterFinanceOverviewRaw(
                                  widget.session.token,
                                );
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? const <String, dynamic>{};
        final liveWallets = _buildFinanceWalletsFromRaw(
          _asMapList(data['wallets']),
        );
        final liveCommissions = _buildCommissionRulesFromRaw(
          _asMapList(data['commissions']),
        );
        final liveFees = _buildFeeZonesFromRaw(_asMapList(data['fees']));
        final liveCoupons = _buildFinanceCouponsFromRaw(
          _asMapList(data['coupons']),
        );
        final liveDiscounts = _buildFinanceDiscountsFromRaw(
          _asMapList(data['discounts']),
        );
        final liveRecords = _buildFinanceRecordsFromRaw(
          _asMapList(data['records']),
        );
        final liveRefundOrders = _buildFinanceRefundOrdersFromRaw(
          _asMapList(data['refund_candidates']),
        );
        final effectiveWallets = _filterFinanceWallets(liveWallets);
        final effectiveCommissions = _filterFinanceCommissions(liveCommissions);
        final effectiveFees = _filterFinanceFees(liveFees);
        final effectiveCoupons = _filterFinanceCoupons(liveCoupons);
        final effectiveDiscounts = _filterFinanceDiscounts(liveDiscounts);
        final effectiveRecords = _filterFinanceRecords(liveRecords);
        final effectiveRefundOrders = _filterFinanceRefundOrders(
          liveRefundOrders,
        );

        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sidebarWidth = constraints.maxWidth >= 1280
                        ? 258.0
                        : 230.0;

                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _OrdersHeaderBar(
                                serverNow: serverNow,
                                onReload: _reload,
                                showInsightsSidebar: true,
                                showNavigationSidebar: _showNavigationSidebar,
                                onToggleInsightsSidebar: () {},
                                onToggleNavigationSidebar: () {
                                  setState(() {
                                    _showNavigationSidebar =
                                        !_showNavigationSidebar;
                                  });
                                },
                                title: _financePageTitle(_activeSubPage),
                                subtitle: _financePageSubtitle(_activeSubPage),
                                icon: _financePageIcon(_activeSubPage),
                              ),
                              const SizedBox(height: 10),
                              _OrdersStatsStrip(
                                cards: _buildLiveFinanceStatCards(
                                  _activeSubPage,
                                  wallets: effectiveWallets,
                                  commissions: effectiveCommissions,
                                  fees: effectiveFees,
                                  coupons: effectiveCoupons,
                                  discounts: effectiveDiscounts,
                                  records: effectiveRecords,
                                  refundOrders: effectiveRefundOrders,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _FinanceFiltersBar(
                                activeSubPage: _activeSubPage,
                                searchController: _searchController,
                                onSubmitted: _reload,
                                onSearchChanged: _setFinanceSearch,
                                statusFilter: _financeStatusFilter,
                                typeFilter: _financeTypeFilter,
                                sourceFilter: _financeSourceFilter,
                                onStatusChanged: _setFinanceStatusFilter,
                                onTypeChanged: _setFinanceTypeFilter,
                                onSourceChanged: _setFinanceSourceFilter,
                                onAddPressed: () {
                                  if (_activeSubPage == 'discounts') {
                                    setState(
                                      () => _activeSubPage = 'discount_builder',
                                    );
                                  } else if (_activeSubPage == 'refunds') {
                                    _refundCancelledOrderFromFinance();
                                  } else if (_activeSubPage == 'fees') {
                                    _showNewFinanceFeeEditor();
                                  } else if (_activeSubPage == 'accounting') {
                                    _showAccountingAccountEditor();
                                  } else {
                                    _showMasterSnack(
                                      context,
                                      _financePrimaryActionLabel(
                                        _activeSubPage,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: _buildFinanceWorkspace(
                                  wallets: effectiveWallets,
                                  commissions: effectiveCommissions,
                                  fees: effectiveFees,
                                  coupons: effectiveCoupons,
                                  discounts: effectiveDiscounts,
                                  records: effectiveRecords,
                                  refundOrders: effectiveRefundOrders,
                                  accounting: _asMapList(
                                    data['accounting_accounts'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _FinanceRightSidebar(
                              activeSubPage: _activeSubPage,
                              restrictedToEmployeePortal:
                                  widget.session.portal != null,
                              onSubPageTap: (value) {
                                if (value == 'wallets') {
                                  setState(() => _activeSubPage = 'wallets');
                                }
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
                              onOrdersTap: () => _navigateToMasterSection(
                                context,
                                key: 'orders',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
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
                              onMarketingTap: () => _navigateToMasterSection(
                                context,
                                key: 'marketing',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSupportTap: () => _navigateToMasterSection(
                                context,
                                key: 'communication',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onReportsTap: () => _navigateToMasterSection(
                                context,
                                key: 'reports',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onSettingsTap: () => _navigateToMasterSection(
                                context,
                                key: 'settings',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onAccessTap: () => _navigateToMasterSection(
                                context,
                                key: 'access',
                                accessSubPage: 'approvals',
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

  Widget _buildUnifiedFinanceFrame(BuildContext context) {
    final serverNow = widget.serverNow ?? DateTime.now();
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'finance',
        label: 'الإدارة المالية',
        selected: true,
      ),
    ]);
    return _buildMasterUnifiedShell(
      context: context,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      sidebarItems: sidebarItems,
      onSidebarItemTap: (itemKey) {
        final key = _masterCanonicalModuleKey(itemKey);
        if (key == 'finance') return;
        _navigateToMasterSection(
          context,
          key: key,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
      },
      statusLabel: 'الإدارة المالية',
      platformTitle: 'الإدارة المالية',
      platformSubtitle: 'المحافظ والرسوم والاستردادات والتسويات',
      serverNow: serverNow,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _financeOverviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: _UsersPlaceholderWorkspace(
                title: 'تعذر تحميل البيانات المالية',
                description: snapshot.error?.toString() ?? 'حدث خطأ غير متوقع',
                icon: Icons.error_outline_rounded,
              ),
            );
          }
          final data = snapshot.data!;
          final wallets = _filterFinanceWallets(
            _buildFinanceWalletsFromRaw(_asMapList(data['wallets'])),
          );
          final commissions = _filterFinanceCommissions(
            _buildCommissionRulesFromRaw(_asMapList(data['commissions'])),
          );
          final fees = _filterFinanceFees(
            _buildFeeZonesFromRaw(_asMapList(data['fees'])),
          );
          final coupons = _filterFinanceCoupons(
            _buildFinanceCouponsFromRaw(_asMapList(data['coupons'])),
          );
          final discounts = _filterFinanceDiscounts(
            _buildFinanceDiscountsFromRaw(_asMapList(data['discounts'])),
          );
          final records = _filterFinanceRecords(
            _buildFinanceRecordsFromRaw(_asMapList(data['records'])),
          );
          final refunds = _filterFinanceRefundOrders(
            _buildFinanceRefundOrdersFromRaw(
              _asMapList(data['refund_candidates']),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final item in const <MapEntry<String, String>>[
                    MapEntry('wallets', 'المحافظ'),
                    MapEntry('commissions', 'العمولات'),
                    MapEntry('fees', 'رسوم التوصيل'),
                    MapEntry('discounts', 'الخصومات'),
                    MapEntry('records', 'السجلات'),
                    MapEntry('refunds', 'الاستردادات'),
                  ])
                    ChoiceChip(
                      selected: _activeSubPage == item.key,
                      label: Text(item.value),
                      onSelected: (_) =>
                          setState(() => _activeSubPage = item.key),
                    ),
                  ChoiceChip(
                    selected: _activeSubPage == 'accounting',
                    label: const Text('Accounting'),
                    onSelected: (_) =>
                        setState(() => _activeSubPage = 'accounting'),
                  ),
                  FilledButton.icon(
                    onPressed: _activeSubPage == 'discounts'
                        ? () => setState(
                            () => _activeSubPage = 'discount_builder',
                          )
                        : _activeSubPage == 'refunds'
                        ? _refundCancelledOrderFromFinance
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إجراء مالي'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OrdersStatsStrip(
                cards: _buildLiveFinanceStatCards(
                  _activeSubPage,
                  wallets: wallets,
                  commissions: commissions,
                  fees: fees,
                  coupons: coupons,
                  discounts: discounts,
                  records: records,
                  refundOrders: refunds,
                ),
              ),
              const SizedBox(height: 12),
              _FinanceFiltersBar(
                activeSubPage: _activeSubPage,
                searchController: _searchController,
                onSubmitted: _reload,
                onSearchChanged: _setFinanceSearch,
                statusFilter: _financeStatusFilter,
                typeFilter: _financeTypeFilter,
                sourceFilter: _financeSourceFilter,
                onStatusChanged: _setFinanceStatusFilter,
                onTypeChanged: _setFinanceTypeFilter,
                onSourceChanged: _setFinanceSourceFilter,
                onAddPressed: _activeSubPage == 'discounts'
                    ? () => setState(() => _activeSubPage = 'discount_builder')
                    : _activeSubPage == 'refunds'
                    ? _refundCancelledOrderFromFinance
                    : () => _showMasterSnack(
                        context,
                        _financePrimaryActionLabel(_activeSubPage),
                      ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildFinanceWorkspace(
                  wallets: wallets,
                  commissions: commissions,
                  fees: fees,
                  coupons: coupons,
                  discounts: discounts,
                  records: records,
                  refundOrders: refunds,
                  accounting: _asMapList(data['accounting_accounts']),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _financeOverviewFuture = widget.api._fetchMasterFinanceOverviewRaw(
        widget.session.token,
      );
    });
  }

  void _resetFinanceSelections() {
    _selectedWalletIndex = 0;
    _selectedCommissionIndex = 0;
    _selectedFeeIndex = 0;
    _selectedCouponIndex = 0;
    _selectedRecordIndex = 0;
    _selectedRefundIndex = 0;
  }

  void _setFinanceStatusFilter(String value) {
    setState(() {
      _financeStatusFilter = value;
      _resetFinanceSelections();
    });
  }

  void _setFinanceTypeFilter(String value) {
    setState(() {
      _financeTypeFilter = value;
      _resetFinanceSelections();
    });
  }

  void _setFinanceSourceFilter(String value) {
    setState(() {
      _financeSourceFilter = value;
      _resetFinanceSelections();
    });
  }

  void _setFinanceSearch(String value) {
    setState(_resetFinanceSelections);
  }

  bool _financeMatchesQuery(String corpus) {
    final query = _searchController.text.trim().toLowerCase();
    return query.isEmpty || corpus.toLowerCase().contains(query);
  }

  bool _financeMatchesStatus(String status) {
    final value = status.toLowerCase();
    switch (_financeStatusFilter) {
      case 'active':
        return value.contains('active') ||
            value.contains('نشط') ||
            value.contains('مفعل');
      case 'stopped':
        return value.contains('stop') ||
            value.contains('disable') ||
            value.contains('inactive') ||
            value.contains('متوقف') ||
            value.contains('معطل') ||
            value.contains('معلق');
      case 'ended':
        return value.contains('end') ||
            value.contains('expire') ||
            value.contains('finish') ||
            value.contains('منتهي') ||
            value.contains('مكتمل') ||
            value.contains('ملغي');
      default:
        return true;
    }
  }

  bool _financeMatchesType(String corpus) {
    final value = corpus.toLowerCase();
    switch (_financeTypeFilter) {
      case 'wallet':
        return value.contains('wallet') ||
            value.contains('محفظ') ||
            value.contains('مكاف');
      case 'fees':
        return value.contains('fee') ||
            value.contains('رسوم') ||
            value.contains('توصيل') ||
            value.contains('خدمة');
      case 'discounts':
        return value.contains('discount') ||
            value.contains('coupon') ||
            value.contains('خصم') ||
            value.contains('كوبون') ||
            value.contains('ترويج');
      default:
        return true;
    }
  }

  bool _financeMatchesSource(String corpus) {
    final value = corpus.toLowerCase();
    switch (_financeSourceFilter) {
      case 'platform':
        return value.contains('platform') || value.contains('منصة');
      case 'restaurant':
        return value.contains('restaurant') || value.contains('مطعم');
      case 'promo':
        return value.contains('promo') ||
            value.contains('ترويج') ||
            value.contains('خصم') ||
            value.contains('كوبون');
      default:
        return true;
    }
  }

  List<_FinanceWalletRecord> _filterFinanceWallets(
    List<_FinanceWalletRecord> rows,
  ) {
    return rows
        .where((row) {
          final corpus =
              '${row.walletId} ${row.userName} ${row.userId} ${row.typeLabel} ${row.status} ${row.phone}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.status) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  List<_CommissionRuleRecord> _filterFinanceCommissions(
    List<_CommissionRuleRecord> rows,
  ) {
    return rows
        .where((row) {
          final corpus =
              '${row.name} ${row.description} ${row.typeLabel} ${row.appliesTo} ${row.source} ${row.status}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.status) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  List<_FeeZoneRecord> _filterFinanceFees(List<_FeeZoneRecord> rows) {
    return rows
        .where((row) {
          final corpus =
              '${row.zoneName} ${row.city} ${row.fixedFee} ${row.extraKmFee} ${row.serviceFee} ${row.deliveryMethods} ${row.status}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.status) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  List<_FinanceCouponRecord> _filterFinanceCoupons(
    List<_FinanceCouponRecord> rows,
  ) {
    return rows
        .where((row) {
          final corpus =
              '${row.code} ${row.restaurant} ${row.typeLabel} ${row.valueLabel} ${row.status}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.status) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  List<_FinanceDiscountRecord> _filterFinanceDiscounts(
    List<_FinanceDiscountRecord> rows,
  ) {
    return rows
        .where((row) {
          final corpus =
              '${row.name} ${row.code} ${row.source} ${row.typeLabel} ${row.valueLabel} ${row.status}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.status) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  List<_FinanceRecordEntry> _filterFinanceRecords(
    List<_FinanceRecordEntry> rows,
  ) {
    return rows
        .where((row) {
          final corpus =
              '${row.reference} ${row.datetime} ${row.description} ${row.account} ${row.typeLabel} ${row.paymentMethod} ${row.amount} ${row.status}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.status) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  List<_FinanceRefundOrderRecord> _filterFinanceRefundOrders(
    List<_FinanceRefundOrderRecord> rows,
  ) {
    return rows
        .where((row) {
          final corpus =
              '${row.orderId} ${row.customerName} ${row.customerPhone} ${row.statusLabel} ${row.paymentMethod} ${row.paymentReference} ${row.refundStatusLabel}';
          return _financeMatchesQuery(corpus) &&
              _financeMatchesStatus(row.refundStatusLabel) &&
              _financeMatchesType(corpus) &&
              _financeMatchesSource(corpus);
        })
        .toList(growable: false);
  }

  Future<void> _refundCancelledOrderToWallet(
    _FinanceWalletRecord wallet,
  ) async {
    final request = await _showWalletRefundDialog(context, wallet);
    if (request == null || !mounted) {
      return;
    }

    try {
      await widget.api._refundCancelledOrderToWallet(
        widget.session.token,
        orderId: request.orderId,
        note: request.note,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, 'تم رد قيمة الطلب كنقاط قابلة للدفع');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, error.toString());
    }
  }

  Future<void> _refundCancelledOrderFromFinance([
    _FinanceRefundOrderRecord? order,
  ]) async {
    if (order != null && order.isRefunded) {
      _showMasterSnack(context, 'تم رد نقاط هذا الطلب من قبل');
      return;
    }
    final request = await _showWalletRefundDialog(
      context,
      null,
      initialOrderId: order?.orderId,
      title: order == null
          ? 'استرداد طلب مدفوع إلكترونيا'
          : 'طلب #${order.orderId} - ${order.customerName}',
    );
    if (request == null || !mounted) {
      return;
    }

    try {
      await widget.api._refundCancelledOrderToWallet(
        widget.session.token,
        orderId: request.orderId,
        note: request.note,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, 'تم رد قيمة الطلب كنقاط في محفظة العميل');
      _reload();
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    }
  }

  Future<void> _runFinanceAction({
    required String entity,
    required String action,
    int? id,
    Map<String, dynamic>? data,
    required String successMessage,
  }) async {
    try {
      await widget.api._runMasterFinanceAction(
        widget.session.token,
        entity: entity,
        action: action,
        id: id,
        data: data,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, successMessage);
      _reload();
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    }
  }

  Future<void> _showWalletAdjustmentDialog(_FinanceWalletRecord wallet) async {
    final amountController = TextEditingController();
    final pointsController = TextEditingController();
    final noteController = TextEditingController(text: 'Master adjustment');
    var action = 'credit';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'تعديل محفظة ${wallet.userName}',
                textAlign: TextAlign.right,
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: action,
                      items: const [
                        DropdownMenuItem(
                          value: 'credit',
                          child: Text('إضافة رصيد'),
                        ),
                        DropdownMenuItem(
                          value: 'debit',
                          child: Text('خصم رصيد'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => action = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'نوع العملية',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pointsController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'النقاط',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة القيد',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.start,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('تنفيذ'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == true && mounted) {
      await _runFinanceAction(
        entity: 'wallet',
        action: action,
        id: int.tryParse(wallet.userId),
        successMessage: action == 'credit'
            ? 'تمت إضافة الرصيد للمحفظة'
            : 'تم خصم الرصيد من المحفظة',
        data: {
          'amount': double.tryParse(amountController.text.trim()) ?? 0,
          'points': int.tryParse(pointsController.text.trim()) ?? 0,
          'note': noteController.text.trim(),
        },
      );
    }
    amountController.dispose();
    pointsController.dispose();
    noteController.dispose();
  }

  Future<void> _toggleWalletStatus(_FinanceWalletRecord wallet) async {
    final active = _masterStatusIsActive(wallet.status);
    await _runFinanceAction(
      entity: 'wallet',
      action: active ? 'disable' : 'activate',
      id: int.tryParse(wallet.userId),
      successMessage: active
          ? 'تم تعطيل المستخدم المرتبط'
          : 'تم تفعيل المستخدم المرتبط',
    );
  }

  Future<void> _showFinanceCouponEditor([_FinanceCouponRecord? coupon]) async {
    final codeController = TextEditingController(text: coupon?.code ?? '');
    final discountController = TextEditingController(
      text: coupon == null
          ? '10'
          : coupon.valueLabel.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final countController = TextEditingController(
      text: coupon == null
          ? '100'
          : coupon.usageLabel.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final endDateController = TextEditingController(
      text: coupon?.endDate ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            coupon == null ? 'إضافة كوبون' : 'تعديل الكوبون',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'كود الكوبون',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: discountController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'نسبة الخصم',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'عدد الاستخدامات',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: endDateController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الانتهاء',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (saved == true && mounted) {
      await _runFinanceAction(
        entity: 'coupon',
        action: 'save',
        id: coupon?.id,
        successMessage: 'تم حفظ الكوبون',
        data: {
          'code': codeController.text.trim(),
          'discount': int.tryParse(discountController.text.trim()) ?? 10,
          'count': int.tryParse(countController.text.trim()) ?? 100,
          if (endDateController.text.trim().isNotEmpty)
            'end_date': endDateController.text.trim(),
        },
      );
    }
    codeController.dispose();
    discountController.dispose();
    countController.dispose();
    endDateController.dispose();
  }

  Future<void> _toggleFinanceCoupon(_FinanceCouponRecord coupon) async {
    final active = _masterStatusIsActive(coupon.status);
    await _runFinanceAction(
      entity: 'coupon',
      action: active ? 'disable' : 'activate',
      id: coupon.id,
      successMessage: active ? 'تم إيقاف الكوبون' : 'تم تفعيل الكوبون',
    );
  }

  Future<void> _deleteFinanceCoupon(_FinanceCouponRecord coupon) async {
    await _runFinanceAction(
      entity: 'coupon',
      action: 'delete',
      id: coupon.id,
      successMessage: 'تم تعطيل الكوبون بأمان',
    );
  }

  _FinanceCouponRecord _couponFromDiscount(_FinanceDiscountRecord discount) {
    return _FinanceCouponRecord(
      id: discount.id,
      code: discount.code,
      restaurant: discount.source,
      typeLabel: discount.typeLabel,
      valueLabel: discount.valueLabel,
      minOrder: '0 ${MasterCurrency.symbol}',
      usageLabel: discount.usageLabel,
      status: discount.status,
      endDate: discount.endDate,
      imageUrl: '',
    );
  }

  Future<void> _showFinanceDiscountEditor(
    _FinanceDiscountRecord discount,
  ) async {
    await _showFinanceCouponEditor(_couponFromDiscount(discount));
  }

  Future<void> _toggleFinanceDiscount(_FinanceDiscountRecord discount) async {
    await _toggleFinanceCoupon(_couponFromDiscount(discount));
  }

  Future<void> _deleteFinanceDiscount(_FinanceDiscountRecord discount) async {
    await _deleteFinanceCoupon(_couponFromDiscount(discount));
  }

  double _financeNumberFromLabel(String value, [double fallback = 0]) {
    final normalized = value.replaceAll(',', '.');
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(normalized);
    return match == null
        ? fallback
        : double.tryParse(match.group(0)!) ?? fallback;
  }

  Future<void> _showNewFinanceFeeEditor() async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final deliveryFeeController = TextEditingController(text: '0');
    final perKmController = TextEditingController(text: '2.5');
    final coverageController = TextEditingController(text: '5');
    final minimumOrderController = TextEditingController(text: '0');
    var pricingMode = 'fixed';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text(
            'إضافة إعداد رسوم توصيل',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنطقة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deliveryFeeController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'رسوم التوصيل الثابتة (${MasterCurrency.symbol})',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: pricingMode,
                  decoration: const InputDecoration(
                    labelText: 'طريقة احتساب التوصيل',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('سعر توصيل ثابت'),
                    ),
                    DropdownMenuItem(
                      value: 'per_km',
                      child: Text('حسب الكيلومتر'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => pricingMode = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: perKmController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'سعر الكيلومتر (${MasterCurrency.symbol})',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coverageController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نطاق التغطية بالكيلومتر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minimumOrderController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الحد الأدنى للطلب (${MasterCurrency.symbol})',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _showMasterSnack(context, 'اسم المنطقة مطلوب');
      } else {
        try {
          await widget.api._saveDeliveryZone(
            widget.session.token,
            data: {
              'name': name,
              'city': cityController.text.trim(),
              'delivery_fee': _financeNumberFromLabel(
                deliveryFeeController.text,
              ),
              'pricing_mode': pricingMode,
              'delivery_base_fee': pricingMode == 'fixed'
                  ? _financeNumberFromLabel(deliveryFeeController.text)
                  : 0,
              'delivery_cost_per_km': pricingMode == 'per_km'
                  ? _financeNumberFromLabel(perKmController.text, 2.5)
                  : 0,
              'coverage_km': _financeNumberFromLabel(
                coverageController.text,
                5,
              ),
              'minimum_order': _financeNumberFromLabel(
                minimumOrderController.text,
              ),
              'is_active': 1,
            },
          );
          if (mounted) {
            _showMasterSnack(context, 'تمت إضافة إعداد رسوم التوصيل');
            _reload();
          }
        } on MasterApiException catch (error) {
          if (mounted) _showMasterSnack(context, error.message);
        } catch (_) {
          if (mounted) _showMasterSnack(context, 'تعذر حفظ إعداد الرسوم');
        }
      }
    }
    nameController.dispose();
    cityController.dispose();
    deliveryFeeController.dispose();
    perKmController.dispose();
    coverageController.dispose();
    minimumOrderController.dispose();
  }

  Future<void> _showAccountingAccountEditor([
    Map<String, dynamic>? existing,
  ]) async {
    final nameController = TextEditingController(
      text: (existing?['account_name'] ?? '').toString(),
    );
    var type = (existing?['account_type'] ?? 'asset').toString();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'إضافة حساب محاسبي' : 'تعديل حساب محاسبي',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'اسم الحساب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'نوع الحساب',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'asset', child: Text('أصول')),
                    DropdownMenuItem(
                      value: 'liability',
                      child: Text('التزامات'),
                    ),
                    DropdownMenuItem(
                      value: 'equity',
                      child: Text('حقوق ملكية'),
                    ),
                    DropdownMenuItem(value: 'revenue', child: Text('إيرادات')),
                    DropdownMenuItem(value: 'expense', child: Text('مصروفات')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _showMasterSnack(context, 'اسم الحساب مطلوب');
      } else {
        try {
          await widget.api._saveAccountingAccount(
            widget.session.token,
            accountId: _toInt(existing?['account_id']),
            name: name,
            type: type,
          );
          if (mounted) {
            _showMasterSnack(context, 'تم حفظ الحساب المحاسبي');
            _reload();
          }
        } on MasterApiException catch (error) {
          if (mounted) _showMasterSnack(context, error.message);
        } catch (_) {
          if (mounted) _showMasterSnack(context, 'تعذر حفظ الحساب المحاسبي');
        }
      }
    }
    nameController.dispose();
  }

  Future<void> _deleteAccountingAccount(Map<String, dynamic> account) async {
    final id = _toInt(account['account_id']);
    if (id <= 0) return;
    try {
      await widget.api._deleteAccountingAccount(widget.session.token, id);
      if (mounted) {
        _showMasterSnack(context, 'تم حذف الحساب المحاسبي');
        _reload();
      }
    } on MasterApiException catch (error) {
      if (mounted) _showMasterSnack(context, error.message);
    } catch (_) {
      if (mounted) _showMasterSnack(context, 'تعذر حذف الحساب المحاسبي');
    }
  }

  Future<void> _showFinanceFeeEditor(_FeeZoneRecord fee) async {
    final deliveryFeeController = TextEditingController(
      text: _financeNumberFromLabel(fee.fixedFee).toStringAsFixed(0),
    );
    final coverageController = TextEditingController(
      text: _financeNumberFromLabel(fee.extraKmFee, 5).toString(),
    );
    final minimumOrderController = TextEditingController(
      text: _financeNumberFromLabel(fee.minimumOrder).toStringAsFixed(0),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fee.zoneName, textAlign: TextAlign.right),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deliveryFeeController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رسوم التوصيل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: coverageController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'نطاق التغطية / كم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: minimumOrderController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الحد الأدنى للطلب',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      await widget.api._saveDeliveryZone(
        widget.session.token,
        zoneId: fee.zoneId,
        data: {
          'name': fee.zoneName,
          'city': fee.city,
          'delivery_fee': _financeNumberFromLabel(deliveryFeeController.text),
          'coverage_km': _financeNumberFromLabel(coverageController.text, 5),
          'minimum_order': _financeNumberFromLabel(minimumOrderController.text),
          'is_open': _masterStatusIsActive(fee.status) ? 1 : 0,
        },
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, 'تم حفظ رسوم التوصيل');
      _reload();
    }
    deliveryFeeController.dispose();
    coverageController.dispose();
    minimumOrderController.dispose();
  }

  Future<void> _toggleFinanceFee(_FeeZoneRecord fee) async {
    await widget.api._saveDeliveryZone(
      widget.session.token,
      zoneId: fee.zoneId,
      data: {
        'name': fee.zoneName,
        'city': fee.city,
        'delivery_fee': _financeNumberFromLabel(fee.fixedFee),
        'coverage_km': _financeNumberFromLabel(fee.extraKmFee, 5),
        'minimum_order': _financeNumberFromLabel(fee.minimumOrder),
        'is_open': _masterStatusIsActive(fee.status) ? 0 : 1,
      },
    );
    if (!mounted) {
      return;
    }
    _showMasterSnack(context, 'تم تحديث حالة رسوم المنطقة');
    _reload();
  }

  Future<void> _deleteFinanceFee(_FeeZoneRecord fee) async {
    await widget.api._saveDeliveryZone(
      widget.session.token,
      zoneId: fee.zoneId,
      data: {
        'name': fee.zoneName,
        'city': fee.city,
        'delivery_fee': 0,
        'coverage_km': _financeNumberFromLabel(fee.extraKmFee, 5),
        'minimum_order': _financeNumberFromLabel(fee.minimumOrder),
        'is_open': 0,
      },
    );
    if (!mounted) {
      return;
    }
    _showMasterSnack(context, 'تم تعطيل رسوم المنطقة بأمان');
    _reload();
  }

  Widget _buildFinanceWorkspace({
    required List<_FinanceWalletRecord> wallets,
    required List<_CommissionRuleRecord> commissions,
    required List<_FeeZoneRecord> fees,
    required List<_FinanceCouponRecord> coupons,
    required List<_FinanceDiscountRecord> discounts,
    required List<_FinanceRecordEntry> records,
    required List<_FinanceRefundOrderRecord> refundOrders,
    List<Map<String, dynamic>> accounting = const <Map<String, dynamic>>[],
  }) {
    switch (_activeSubPage) {
      case 'accounting':
        return _FinanceAccountingWorkspace(
          accounts: accounting,
          onEdit: _showAccountingAccountEditor,
          onDelete: _deleteAccountingAccount,
        );
      case 'wallets':
        if (wallets.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final walletIndex = wallets.isEmpty
            ? 0
            : math.min(_selectedWalletIndex, wallets.length - 1);
        return _FinanceWalletsWorkspace(
          wallets: wallets,
          selectedIndex: walletIndex,
          onSelected: (value) => setState(() => _selectedWalletIndex = value),
          onRefundCancelledOrder: _refundCancelledOrderToWallet,
          onAdjustWallet: _showWalletAdjustmentDialog,
          onToggleWallet: _toggleWalletStatus,
        );
      case 'commissions':
        if (commissions.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final commissionIndex = commissions.isEmpty
            ? 0
            : math.min(_selectedCommissionIndex, commissions.length - 1);
        return _FinanceCommissionsWorkspace(
          rules: commissions,
          selectedIndex: commissionIndex,
          onSelected: (value) =>
              setState(() => _selectedCommissionIndex = value),
        );
      case 'fees':
        if (fees.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final feeIndex = fees.isEmpty
            ? 0
            : math.min(_selectedFeeIndex, fees.length - 1);
        return _FinanceFeesWorkspace(
          fees: fees,
          selectedIndex: feeIndex,
          onSelected: (value) => setState(() => _selectedFeeIndex = value),
          onEditFee: _showFinanceFeeEditor,
          onToggleFee: _toggleFinanceFee,
          onDeleteFee: _deleteFinanceFee,
        );
      case 'discount_builder':
        return _FinanceDiscountBuilderWorkspace(
          discounts: discounts,
          onBackToCoupons: () => setState(() => _activeSubPage = 'discounts'),
          onEditDiscount: _showFinanceDiscountEditor,
          onToggleDiscount: _toggleFinanceDiscount,
          onDeleteDiscount: _deleteFinanceDiscount,
        );
      case 'records':
        if (records.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final recordIndex = records.isEmpty
            ? 0
            : math.min(_selectedRecordIndex, records.length - 1);
        return _FinanceRecordsWorkspace(
          records: records,
          title: _financePageTitle(_activeSubPage),
          selectedIndex: recordIndex,
          onSelected: (value) => setState(() => _selectedRecordIndex = value),
        );
      case 'discounts':
        if (coupons.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final couponIndex = coupons.isEmpty
            ? 0
            : math.min(_selectedCouponIndex, coupons.length - 1);
        return _FinanceDiscountsWorkspace(
          coupons: coupons,
          selectedCouponIndex: couponIndex,
          onCouponSelected: (value) =>
              setState(() => _selectedCouponIndex = value),
          onOpenBuilder: () =>
              setState(() => _activeSubPage = 'discount_builder'),
          onAddCoupon: () => _showFinanceCouponEditor(),
          onEditCoupon: _showFinanceCouponEditor,
          onToggleCoupon: _toggleFinanceCoupon,
          onDeleteCoupon: _deleteFinanceCoupon,
        );
      case 'payment_ops':
        final paymentRecords = records
            .where((record) => !_financeRecordIsRefund(record))
            .toList();
        if (paymentRecords.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final paymentRecordIndex = math.min(
          _selectedRecordIndex,
          paymentRecords.length - 1,
        );
        return _FinanceRecordsWorkspace(
          records: paymentRecords,
          title: _financePageTitle(_activeSubPage),
          selectedIndex: paymentRecordIndex,
          onSelected: (value) => setState(() => _selectedRecordIndex = value),
        );
      case 'refunds':
        final refundRecords = records.where(_financeRecordIsRefund).toList();
        if (refundOrders.isEmpty && refundRecords.isEmpty) {
          return _financeEmptyWorkspace(_activeSubPage);
        }
        final refundIndex = refundOrders.isEmpty
            ? 0
            : math.min(_selectedRefundIndex, refundOrders.length - 1);
        return _FinanceRefundsWorkspace(
          orders: refundOrders,
          records: refundRecords,
          selectedIndex: refundIndex,
          onSelected: (value) => setState(() => _selectedRefundIndex = value),
          onRefundOrder: _refundCancelledOrderFromFinance,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _financeEmptyWorkspace(String key) {
    return _UsersPlaceholderWorkspace(
      title: _financePageTitle(key),
      description:
          'لا توجد بيانات حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
      icon: _financePageIcon(key),
    );
  }
}

bool _financeRecordIsRefund(_FinanceRecordEntry record) {
  final type = record.typeLabel.trim();
  final description = record.description.trim().toLowerCase();
  final paymentMethod = record.paymentMethod.trim().toLowerCase();
  return type.contains('استرداد') ||
      description.contains('refund') ||
      description.contains('refunded') ||
      description.contains('استرداد') ||
      description.contains('رد نقاط') ||
      paymentMethod.contains('refund') ||
      paymentMethod.contains('نقاط المحفظة');
}

String _financeOrderStatusLabel(String status) {
  final value = status.trim().toLowerCase();
  if (value.contains('returned') ||
      value.contains('refunded') ||
      value == 'return' ||
      value == 'refund') {
    return 'مردود';
  }
  if (value.contains('reject')) {
    return 'مرفوض';
  }
  if (value.contains('cancel') || value == '-1' || value == '5') {
    return 'ملغي';
  }
  if (value.contains('failed')) {
    return 'فشل الدفع';
  }
  return status.isEmpty ? 'مؤهل' : status;
}

String _financePageTitle(String key) {
  switch (key) {
    case 'wallets':
      return 'المحافظ';
    case 'payment_ops':
      return 'عمليات الدفع';
    case 'refunds':
      return 'الاستردادات';
    case 'commissions':
      return 'العمولات';
    case 'fees':
      return 'رسوم التوصيل والخدمة';
    case 'discount_builder':
      return 'إدارة الخصومات';
    case 'discounts':
      return 'الخصومات والكوبونات';
    case 'records':
      return 'السجلات المالية';
    default:
      return 'الإدارة المالية';
  }
}

String _financePageSubtitle(String key) {
  switch (key) {
    case 'wallets':
      return 'إدارة جميع محافظ المنصة';
    case 'payment_ops':
      return 'متابعة عمليات الدفع والتحصيل عبر المنصة';
    case 'refunds':
      return 'إدارة طلبات الاسترداد والتسويات';
    case 'commissions':
      return 'إدارة العمولات المضافة فوق سعر أي منتج في المنصة';
    case 'fees':
      return 'إدارة كافة رسوم التوصيل ورسوم الخدمة في المنصة';
    case 'discount_builder':
      return 'إنشاء وإدارة جميع الخصومات العامة والترويجية في المنصة';
    case 'discounts':
      return 'إدارة جميع الكوبونات والخصومات والتسعيرات في المنصة';
    case 'records':
      return 'جميع الحركات المالية والتعاقدات في المنصة';
    default:
      return 'لوحة التحكم المالية للمنصة';
  }
}

IconData _financePageIcon(String key) {
  switch (key) {
    case 'wallets':
      return Icons.account_balance_wallet_outlined;
    case 'payment_ops':
      return Icons.payments_outlined;
    case 'refunds':
      return Icons.restart_alt_rounded;
    case 'commissions':
      return Icons.percent_rounded;
    case 'fees':
      return Icons.local_shipping_outlined;
    case 'discount_builder':
    case 'discounts':
      return Icons.discount_outlined;
    case 'records':
      return Icons.receipt_long_outlined;
    default:
      return Icons.account_balance_wallet_outlined;
  }
}

String _financePrimaryActionLabel(String key) {
  switch (key) {
    case 'wallets':
      return 'إضافة محفظة';
    case 'commissions':
      return 'إضافة قاعدة عمولة';
    case 'fees':
      return 'إضافة إعداد جديد';
    case 'records':
      return 'تسجيل حركة جديدة';
    case 'refunds':
      return 'رد نقاط طلب';
    case 'discounts':
      return 'إضافة كوبون / خصم';
    case 'discount_builder':
      return 'حفظ الخصم';
    default:
      return 'إضافة جديدة';
  }
}

List<_OperationsStatCardData> _buildFinanceStatCards(
  String key, {
  List<_FinanceWalletRecord> wallets = const <_FinanceWalletRecord>[],
}) {
  if (key != 'wallets') {
    return const <_OperationsStatCardData>[];
  }

  final totalBalance = wallets.fold<double>(
    0,
    (sum, wallet) => sum + _numericUserValue(wallet.currentBalance),
  );
  final totalUsed = wallets.fold<double>(
    0,
    (sum, wallet) => sum + _numericUserValue(wallet.usedAmount),
  );
  final totalLocked = wallets.fold<double>(
    0,
    (sum, wallet) => sum + _numericUserValue(wallet.lockedAmount),
  );
  final activeWallets = wallets
      .where((wallet) => _masterStatusIsActive(wallet.status))
      .length;
  final lockedWallets = wallets.length - activeWallets;

  return [
    _OperationsStatCardData(
      title: 'إجمالي الرصيد الكلي',
      value: _formatUserWholeNumber(totalBalance),
      icon: Icons.account_balance_wallet_outlined,
      accent: const Color(0xFF16A34A),
      background: const Color(0xFFEAF7EE),
      detailLine: '${MasterCurrency.symbol}',
      trendLabel: '${wallets.length}',
      trendCaption: 'محفظة',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'إجمالي المبالغ المستخدمة',
      value: _formatUserWholeNumber(totalUsed),
      icon: Icons.add_circle_outline,
      accent: const Color(0xFF22C55E),
      background: const Color(0xFFEAF7EE),
      detailLine: '${MasterCurrency.symbol}',
      trendLabel: '$activeWallets',
      trendCaption: 'نشطة',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'عدد المستخدمين المرتبطين',
      value: '${wallets.length}',
      icon: Icons.sync_alt_rounded,
      accent: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF3DF),
      detailLine: 'محفظة',
      trendLabel: '$activeWallets',
      trendCaption: 'نشطة',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'عدد المحافظ النشطة',
      value: '$activeWallets',
      icon: Icons.check_circle_outline,
      accent: const Color(0xFF22C55E),
      background: const Color(0xFFEAF7EE),
      detailLine: 'محفظة',
      trendLabel: '${wallets.length}',
      trendCaption: 'الإجمالي',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'المحافظ المقفلة',
      value: '$lockedWallets',
      icon: Icons.lock_outline_rounded,
      accent: const Color(0xFF16A34A),
      background: const Color(0xFFEAF7EE),
      detailLine: 'محفظة',
      trendLabel: '${wallets.length}',
      trendCaption: 'الإجمالي',
      trendPositive: false,
    ),
    _OperationsStatCardData(
      title: 'إجمالي المبالغ المقفلة',
      value: _formatUserWholeNumber(totalLocked),
      icon: Icons.person_off_outlined,
      accent: const Color(0xFFEF4444),
      background: const Color(0xFFFDECEC),
      detailLine: '${MasterCurrency.symbol}',
      trendLabel: '$lockedWallets',
      trendCaption: 'محفظة',
      trendPositive: false,
    ),
  ];
}

List<_OperationsStatCardData> _buildLiveFinanceStatCards(
  String key, {
  List<_FinanceWalletRecord> wallets = const <_FinanceWalletRecord>[],
  List<_CommissionRuleRecord> commissions = const <_CommissionRuleRecord>[],
  List<_FeeZoneRecord> fees = const <_FeeZoneRecord>[],
  List<_FinanceCouponRecord> coupons = const <_FinanceCouponRecord>[],
  List<_FinanceDiscountRecord> discounts = const <_FinanceDiscountRecord>[],
  List<_FinanceRecordEntry> records = const <_FinanceRecordEntry>[],
  List<_FinanceRefundOrderRecord> refundOrders =
      const <_FinanceRefundOrderRecord>[],
}) {
  if (key == 'wallets') {
    return _buildFinanceStatCards(key, wallets: wallets);
  }

  if (key == 'commissions') {
    final activeRules = commissions
        .where((rule) => rule.status == 'نشطة')
        .length;
    final aggregateValue = commissions.fold<double>(
      0,
      (sum, rule) => sum + _numericUserValue(rule.valueLabel),
    );
    final restaurantRules = commissions
        .where((rule) => rule.source == 'مطعم')
        .length;
    return [
      _OperationsStatCardData(
        title: 'إجمالي العمولات الحالية',
        value: commissions.isEmpty
            ? '0%'
            : '${aggregateValue.toStringAsFixed(2)}%',
        icon: Icons.percent_rounded,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: 'متوسط النسبة',
        trendLabel: '$activeRules',
        trendCaption: 'قاعدة نشطة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي العمولات المحسوبة',
        value:
            '${_formatUserWholeNumber(aggregateValue)} ${MasterCurrency.symbol}',
        icon: Icons.stacked_line_chart_rounded,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'إجمالي البيانات الحالية',
        trendLabel: '${commissions.length}',
        trendCaption: 'قاعدة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عدد القواعد النشطة',
        value: '$activeRules',
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'قاعدة',
        trendLabel: '$restaurantRules',
        trendCaption: 'مطعم',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'تطبيق على المطاعم',
        value: '$restaurantRules',
        icon: Icons.storefront_outlined,
        accent: const Color(0xFF0EA5E9),
        background: const Color(0xFFEAF3FF),
        detailLine: 'مطعم',
        trendLabel: '${commissions.length}',
        trendCaption: 'سجل',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'تأثير العمولات',
        value:
            '${_formatUserWholeNumber(aggregateValue)} ${MasterCurrency.symbol}',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: 'من البيانات الحالية',
        trendLabel: '$activeRules',
        trendCaption: 'نشط الآن',
        trendPositive: true,
      ),
      const _OperationsStatCardData(
        title: 'مصدر البيانات',
        value: 'DB',
        icon: Icons.storage_rounded,
        accent: Color(0xFF16A34A),
        background: Color(0xFFEAF7EE),
        detailLine: 'vendors + vendor_orders',
        trendLabel: 'live',
        trendCaption: 'backend',
        trendPositive: true,
      ),
    ];
  }

  if (key == 'fees') {
    final totalDeliveryFees = fees.fold<double>(
      0,
      (sum, fee) => sum + _numericUserValue(fee.fixedFee),
    );
    final totalServiceFees = fees.fold<double>(
      0,
      (sum, fee) => sum + _numericUserValue(fee.serviceFee),
    );
    final avgDeliveryFee = fees.isEmpty ? 0 : totalDeliveryFees / fees.length;
    final avgServiceFee = fees.isEmpty ? 0 : totalServiceFees / fees.length;
    final openFees = fees.where((fee) => fee.status == 'نشطة').length;
    return [
      _OperationsStatCardData(
        title: 'إجمالي رسوم التوصيل',
        value: _formatUserWholeNumber(totalDeliveryFees),
        icon: Icons.delivery_dining_outlined,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '${fees.length}',
        trendCaption: 'منطقة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي رسوم الخدمة',
        value: _formatUserWholeNumber(totalServiceFees),
        icon: Icons.stacked_line_chart_outlined,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '$openFees',
        trendCaption: 'نشط',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'متوسط رسوم التوصيل',
        value: avgDeliveryFee.toStringAsFixed(2),
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF86EFAC),
        background: const Color(0xFFEAF7EE),
        detailLine: 'لكل منطقة',
        trendLabel: avgServiceFee.toStringAsFixed(2),
        trendCaption: 'متوسط الخدمة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'متوسط رسوم الخدمة',
        value: avgServiceFee.toStringAsFixed(2),
        icon: Icons.ssid_chart_rounded,
        accent: const Color(0xFF86EFAC),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '$openFees',
        trendCaption: 'منطقة نشطة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'المناطق النشطة',
        value: '$openFees',
        icon: Icons.location_on_outlined,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'حالة مفتوحة',
        trendLabel: '${fees.length}',
        trendCaption: 'إجمالي المناطق',
        trendPositive: true,
      ),
      const _OperationsStatCardData(
        title: 'مصدر البيانات',
        value: 'DB',
        icon: Icons.storage_rounded,
        accent: Color(0xFF22C55E),
        background: Color(0xFFEAF7EE),
        detailLine: 'branches + settings',
        trendLabel: 'live',
        trendCaption: 'backend',
        trendPositive: true,
      ),
    ];
  }

  if (key == 'discounts' || key == 'discount_builder') {
    final activeCoupons = coupons
        .where((coupon) => _masterStatusIsActive(coupon.status))
        .length;
    final activeDiscounts = discounts
        .where((discount) => _masterStatusIsActive(discount.status))
        .length;
    final totalUsage = coupons.fold<double>(
      0,
      (sum, coupon) => sum + _numericUserValue(coupon.usageLabel),
    );
    final avgDiscount = coupons.isEmpty
        ? 0
        : coupons.fold<double>(
                0,
                (sum, coupon) => sum + _numericUserValue(coupon.valueLabel),
              ) /
              coupons.length;
    return [
      _OperationsStatCardData(
        title: 'إجمالي الكوبونات',
        value: '${coupons.length}',
        icon: Icons.confirmation_number_outlined,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'كوبون',
        trendLabel: '$activeCoupons',
        trendCaption: 'نشط',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي الخصومات',
        value: '${discounts.length}',
        icon: Icons.discount_outlined,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: 'خصم',
        trendLabel: '$activeDiscounts',
        trendCaption: 'نشط',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي الاستخدام',
        value: _formatUserWholeNumber(totalUsage),
        icon: Icons.wallet_giftcard_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF3DF),
        detailLine: 'من السجلات الحية',
        trendLabel: '${coupons.length}',
        trendCaption: 'سجل',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'قيمة الخصومات',
        value: _formatUserWholeNumber(totalUsage),
        icon: Icons.payments_outlined,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '$activeDiscounts',
        trendCaption: 'مفعّل',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'متوسط التخفيض',
        value: '${avgDiscount.toStringAsFixed(2)}%',
        icon: Icons.auto_graph_rounded,
        accent: const Color(0xFF60A5FA),
        background: const Color(0xFFEAF3FF),
        detailLine: 'لكل كوبون',
        trendLabel: '$activeCoupons',
        trendCaption: 'نشط',
        trendPositive: true,
      ),
      const _OperationsStatCardData(
        title: 'مصدر البيانات',
        value: 'DB',
        icon: Icons.storage_rounded,
        accent: Color(0xFFA78BFA),
        background: Color(0xFFF5EAFE),
        detailLine: 'coupon table',
        trendLabel: 'live',
        trendCaption: 'backend',
        trendPositive: true,
      ),
    ];
  }

  if (key == 'refunds') {
    final pending = refundOrders.where((order) => !order.isRefunded).length;
    final completed = refundOrders.where((order) => order.isRefunded).length;
    final totalRefunds = refundOrders.fold<double>(
      0,
      (sum, order) => sum + _numericUserValue(order.refundAmountLabel),
    );
    final totalPoints = refundOrders.fold<double>(
      0,
      (sum, order) => sum + _numericUserValue(order.refundPointsLabel),
    );
    final recordsCount = records.where(_financeRecordIsRefund).length;
    return [
      _OperationsStatCardData(
        title: 'طلبات بانتظار الرد',
        value: '$pending',
        icon: Icons.pending_actions_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF3DF),
        detailLine: 'طلب مدفوع إلكترونيا',
        trendLabel: '${refundOrders.length}',
        trendCaption: 'إجمالي مؤهل',
        trendPositive: pending == 0,
      ),
      _OperationsStatCardData(
        title: 'استردادات مكتملة',
        value: '$completed',
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'تحولت لنقاط',
        trendLabel: '$recordsCount',
        trendCaption: 'سجل مالي',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي قيمة الاسترداد',
        value: _formatUserWholeNumber(totalRefunds),
        icon: Icons.restart_alt_rounded,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '$completed',
        trendCaption: 'مكتمل',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي النقاط',
        value: _formatUserWholeNumber(totalPoints),
        icon: Icons.stars_outlined,
        accent: const Color(0xFF60A5FA),
        background: const Color(0xFFEAF3FF),
        detailLine: 'نقطة محفظة',
        trendLabel: '$pending',
        trendCaption: 'بانتظار',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عمليات مالية مرتبطة',
        value: '$recordsCount',
        icon: Icons.receipt_long_outlined,
        accent: const Color(0xFF8B5CF6),
        background: const Color(0xFFF5EAFE),
        detailLine: 'من السجل المالي',
        trendLabel: '${records.length}',
        trendCaption: 'كل السجلات',
        trendPositive: true,
      ),
      const _OperationsStatCardData(
        title: 'مصدر البيانات',
        value: 'DB',
        icon: Icons.storage_rounded,
        accent: Color(0xFF64748B),
        background: Color(0xFFF1F5F9),
        detailLine: 'orders + wallet_refund_logs',
        trendLabel: 'live',
        trendCaption: 'backend',
        trendPositive: true,
      ),
    ];
  }

  if (key == 'records' || key == 'payment_ops') {
    final revenues = records.fold<double>(
      0,
      (sum, record) =>
          sum +
          (record.typeLabel == 'إيراد' ? _numericUserValue(record.amount) : 0),
    );
    final expenses = records.fold<double>(
      0,
      (sum, record) =>
          sum +
          (record.typeLabel == 'مصروف' || record.typeLabel == 'استرداد'
              ? _numericUserValue(record.amount).abs()
              : 0),
    );
    final refunds = records.fold<double>(
      0,
      (sum, record) =>
          sum +
          (_financeRecordIsRefund(record)
              ? _numericUserValue(record.amount).abs()
              : 0),
    );
    final transactions = records.length;
    final averageValue = transactions == 0
        ? 0
        : (revenues + expenses) / transactions;
    final isRefundsPage = key == 'refunds';
    return [
      _OperationsStatCardData(
        title: isRefundsPage ? 'إجمالي الاستردادات' : 'إجمالي الإيرادات',
        value: _formatUserWholeNumber(isRefundsPage ? refunds : revenues),
        icon: isRefundsPage
            ? Icons.restart_alt_rounded
            : Icons.request_quote_outlined,
        accent: isRefundsPage
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E),
        background: isRefundsPage
            ? const Color(0xFFFFF3DF)
            : const Color(0xFFEAF7EE),
        detailLine: isRefundsPage ? 'نقاط محفظة' : 'من السجلات الحالية',
        trendLabel: '$transactions',
        trendCaption: isRefundsPage ? 'حركة مالية' : 'معاملة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي المصروفات',
        value: _formatUserWholeNumber(expenses),
        icon: Icons.money_off_csred_outlined,
        accent: const Color(0xFFEF4444),
        background: const Color(0xFFFDECEC),
        detailLine: 'من السجلات الحالية',
        trendLabel: '$transactions',
        trendCaption: 'معاملة',
        trendPositive: false,
      ),
      _OperationsStatCardData(
        title: 'صافي الربح',
        value: _formatUserWholeNumber(revenues - expenses),
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '$transactions',
        trendCaption: 'إجمالي السجل',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عدد المعاملات',
        value: '$transactions',
        icon: Icons.folder_shared_outlined,
        accent: const Color(0xFF60A5FA),
        background: const Color(0xFFEAF3FF),
        detailLine: 'سجل حي',
        trendLabel: '$transactions',
        trendCaption: 'في الصفحة',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'متوسط قيمة المعاملة',
        value: '${averageValue.toStringAsFixed(2)} ${MasterCurrency.symbol}',
        icon: Icons.account_balance_outlined,
        accent: const Color(0xFF8B5CF6),
        background: const Color(0xFFEAF7EE),
        detailLine: 'محسوب من السجل',
        trendLabel: '$transactions',
        trendCaption: 'معاملة',
        trendPositive: true,
      ),
      const _OperationsStatCardData(
        title: 'مصدر البيانات',
        value: 'DB',
        icon: Icons.storage_rounded,
        accent: Color(0xFF60A5FA),
        background: Color(0xFFEAF3FF),
        detailLine: 'accounting_entries',
        trendLabel: 'live',
        trendCaption: 'backend',
        trendPositive: true,
      ),
    ];
  }

  return _buildFinanceStatCards(key, wallets: wallets);
}

class _FinanceWalletRecord {
  const _FinanceWalletRecord({
    required this.walletId,
    required this.userName,
    required this.userId,
    required this.typeLabel,
    required this.currentBalance,
    required this.pointsLabel,
    required this.usedAmount,
    required this.lockedAmount,
    required this.status,
    required this.lastSettlement,
    required this.phone,
    required this.avatarUrl,
    required this.transactionsCount,
  });

  final String walletId;
  final String userName;
  final String userId;
  final String typeLabel;
  final String currentBalance;
  final String pointsLabel;
  final String usedAmount;
  final String lockedAmount;
  final String status;
  final String lastSettlement;
  final String phone;
  final String avatarUrl;
  final int transactionsCount;
}

class _CommissionRuleRecord {
  const _CommissionRuleRecord({
    required this.vendorId,
    required this.name,
    required this.description,
    required this.typeLabel,
    required this.valueLabel,
    required this.appliesTo,
    required this.source,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  final int vendorId;
  final String name;
  final String description;
  final String typeLabel;
  final String valueLabel;
  final String appliesTo;
  final String source;
  final String status;
  final int priority;
  final String createdAt;
  final String updatedAt;
}

class _FeeZoneRecord {
  const _FeeZoneRecord({
    required this.zoneId,
    required this.zoneName,
    required this.city,
    required this.fixedFee,
    required this.extraKmFee,
    required this.serviceFee,
    required this.minimumOrder,
    required this.deliveryMethods,
    required this.status,
    required this.revenueLabel,
  });

  final int zoneId;
  final String zoneName;
  final String city;
  final String fixedFee;
  final String extraKmFee;
  final String serviceFee;
  final String minimumOrder;
  final String deliveryMethods;
  final String status;
  final String revenueLabel;
}

class _FinanceCouponRecord {
  const _FinanceCouponRecord({
    required this.id,
    required this.code,
    required this.restaurant,
    required this.typeLabel,
    required this.valueLabel,
    required this.minOrder,
    required this.usageLabel,
    required this.status,
    required this.endDate,
    required this.imageUrl,
  });

  final int id;
  final String code;
  final String restaurant;
  final String typeLabel;
  final String valueLabel;
  final String minOrder;
  final String usageLabel;
  final String status;
  final String endDate;
  final String imageUrl;
}

class _FinanceDiscountRecord {
  const _FinanceDiscountRecord({
    required this.id,
    required this.name,
    required this.code,
    required this.source,
    required this.typeLabel,
    required this.valueLabel,
    required this.maxValueLabel,
    required this.usageLabel,
    required this.status,
    required this.endDate,
  });

  final int id;
  final String name;
  final String code;
  final String source;
  final String typeLabel;
  final String valueLabel;
  final String maxValueLabel;
  final String usageLabel;
  final String status;
  final String endDate;
}

class _FinanceRecordEntry {
  const _FinanceRecordEntry({
    required this.reference,
    required this.datetime,
    required this.description,
    required this.account,
    required this.typeLabel,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.balanceAfter,
  });

  final String reference;
  final String datetime;
  final String description;
  final String account;
  final String typeLabel;
  final String paymentMethod;
  final String amount;
  final String status;
  final String balanceAfter;
}

class _FinanceRefundOrderRecord {
  const _FinanceRefundOrderRecord({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.orderDatetime,
    required this.statusLabel,
    required this.paymentMethod,
    required this.paymentReference,
    required this.orderTotalLabel,
    required this.paidAmountLabel,
    required this.refundAmountLabel,
    required this.refundPointsLabel,
    required this.refundStatusLabel,
    required this.refundedAt,
    required this.note,
    required this.isRefunded,
  });

  final int orderId;
  final int userId;
  final String customerName;
  final String customerPhone;
  final String orderDatetime;
  final String statusLabel;
  final String paymentMethod;
  final String paymentReference;
  final String orderTotalLabel;
  final String paidAmountLabel;
  final String refundAmountLabel;
  final String refundPointsLabel;
  final String refundStatusLabel;
  final String refundedAt;
  final String note;
  final bool isRefunded;
}

List<_FinanceWalletRecord> _buildFinanceWalletsFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    final userId = (row['user_id'] ?? '').toString();
    final balance = _toDouble(row['wallet_balance']);
    final spend = _toDouble(row['total_spend']);
    // The wallet balance is the user's spendable points. `refund_points`
    // is only an audit total and must not replace the live wallet balance.
    final points = _toDouble(row['wallet_points']);
    final lockedAmount = _toDouble(row['locked_amount']);
    return _FinanceWalletRecord(
      walletId: _firstText([row['wallet_id'], 'WAL-$userId']),
      userName: _normalizeUtf8Text(_firstText([row['user_name'], 'مستخدم'])),
      userId: userId,
      pointsLabel: '${_formatUserWholeNumber(points)} نقطة',
      typeLabel: points > 0 ? 'مكافآت' : 'أساسية',
      currentBalance:
          '${_formatUserWholeNumber(balance)} ${MasterCurrency.symbol}',
      usedAmount: '${_formatUserWholeNumber(spend)} ${MasterCurrency.symbol}',
      lockedAmount:
          '${_formatUserWholeNumber(lockedAmount)} ${MasterCurrency.symbol}',
      status: _normalizeUtf8Text(_firstText([row['status'], 'نشطة'])),
      lastSettlement: _firstText([
        row['last_activity'],
        row['created_at'],
        '-',
      ]),
      phone: _firstText([row['phone'], '-']),
      avatarUrl: (row['avatar_url'] ?? '').toString(),
      transactionsCount: _toInt(row['orders_count']),
    );
  }).toList();
}

List<_CommissionRuleRecord> _buildCommissionRulesFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    return _CommissionRuleRecord(
      vendorId: _toInt(row['vendor_id']),
      name: _normalizeUtf8Text(_firstText([row['rule_name'], 'قاعدة عمولة'])),
      description: _normalizeUtf8Text(
        _firstText([row['description'], 'عمولة مستخرجة من البيانات الحالية']),
      ),
      typeLabel: _normalizeUtf8Text(
        _firstText([row['type_label'], 'نسبة مئوية']),
      ),
      valueLabel: _firstText([row['value_label'], '0%']),
      appliesTo: _normalizeUtf8Text(_firstText([row['applies_to'], '-'])),
      source: _normalizeUtf8Text(_firstText([row['source'], 'المنصة'])),
      status: _normalizeUtf8Text(_firstText([row['status'], 'نشطة'])),
      priority: _toInt(row['priority'], 1),
      createdAt: _firstText([row['created_at'], '-']),
      updatedAt: _firstText([row['updated_at'], row['created_at'], '-']),
    );
  }).toList();
}

List<_FeeZoneRecord> _buildFeeZonesFromRaw(List<Map<String, dynamic>> rows) {
  return rows.map((row) {
    return _FeeZoneRecord(
      zoneId: _toInt(row['zone_id'] ?? row['vendor_id']),
      zoneName: _normalizeUtf8Text(_firstText([row['zone_name'], 'منطقة'])),
      city: _normalizeUtf8Text(_firstText([row['city'], 'غير محدد'])),
      fixedFee:
          '${_formatUserWholeNumber(_toDouble(row['fixed_fee']))} ${MasterCurrency.symbol}',
      extraKmFee:
          '${_formatUserWholeNumber(_toDouble(row['extra_km_fee']))} ${MasterCurrency.symbol}',
      serviceFee:
          '${_formatUserWholeNumber(_toDouble(row['service_fee']))} ${MasterCurrency.symbol}',
      minimumOrder:
          '${_formatUserWholeNumber(_toDouble(row['minimum_order']))} ${MasterCurrency.symbol}',
      deliveryMethods: _normalizeUtf8Text(
        _firstText([row['delivery_methods'], 'دراجة / سيارة']),
      ),
      status: _normalizeUtf8Text(_firstText([row['status'], 'نشطة'])),
      revenueLabel: _normalizeUtf8Text(_firstText([row['revenue_label'], '-'])),
    );
  }).toList();
}

List<_FinanceCouponRecord> _buildFinanceCouponsFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    return _FinanceCouponRecord(
      id: _toInt(row['coupon_id'] ?? row['id']),
      code: _normalizeUtf8Text(_firstText([row['code'], '-'])),
      restaurant: _normalizeUtf8Text(_firstText([row['restaurant'], 'المنصة'])),
      typeLabel: _normalizeUtf8Text(
        _firstText([row['type_label'], 'نسبة مئوية']),
      ),
      valueLabel: _firstText([row['value_label'], '0%']),
      minOrder: _normalizeUtf8Text(
        _firstText([row['min_order'], '0 ${MasterCurrency.symbol}']),
      ),
      usageLabel: _normalizeUtf8Text(_firstText([row['usage_label'], '0'])),
      status: _normalizeUtf8Text(_firstText([row['status'], 'نشط'])),
      endDate: _firstText([row['end_date'], '-']),
      imageUrl: (row['image_url'] ?? '').toString(),
    );
  }).toList();
}

List<_FinanceDiscountRecord> _buildFinanceDiscountsFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    return _FinanceDiscountRecord(
      id: _toInt(row['coupon_id'] ?? row['id']),
      name: _normalizeUtf8Text(_firstText([row['name'], 'خصم'])),
      code: _normalizeUtf8Text(_firstText([row['code'], '-'])),
      source: _normalizeUtf8Text(_firstText([row['source'], 'ترويجي'])),
      typeLabel: _normalizeUtf8Text(
        _firstText([row['type_label'], 'نسبة مئوية']),
      ),
      valueLabel: _firstText([row['value_label'], '0%']),
      maxValueLabel: _normalizeUtf8Text(
        _firstText([row['max_value_label'], 'غير محدد']),
      ),
      usageLabel: _normalizeUtf8Text(_firstText([row['usage_label'], '0'])),
      status: _normalizeUtf8Text(_firstText([row['status'], 'نشط'])),
      endDate: _firstText([row['end_date'], '-']),
    );
  }).toList();
}

List<_FinanceRecordEntry> _buildFinanceRecordsFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    final amount = _toDouble(row['amount']);
    return _FinanceRecordEntry(
      reference: _normalizeUtf8Text(_firstText([row['reference'], '-'])),
      datetime: _firstText([row['datetime'], '-']),
      description: _normalizeUtf8Text(_firstText([row['description'], '-'])),
      account: _normalizeUtf8Text(_firstText([row['account'], '-'])),
      typeLabel: _normalizeUtf8Text(_firstText([row['type_label'], 'حركة'])),
      paymentMethod: _normalizeUtf8Text(
        _firstText([row['payment_method'], 'حساب داخلي']),
      ),
      amount:
          '${amount >= 0 ? '+ ' : '- '}${_formatUserWholeNumber(amount.abs())}',
      status: _normalizeUtf8Text(_firstText([row['status'], 'مكتملة'])),
      balanceAfter:
          '${_formatUserWholeNumber(_toDouble(row['balance_after']))} ${MasterCurrency.symbol}',
    );
  }).toList();
}

List<_FinanceRefundOrderRecord> _buildFinanceRefundOrdersFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    final orderId = _toInt(row['order_id']);
    final status = _normalizeUtf8Text(_firstText([row['status'], 'مؤهل']));
    final paymentMethod = _normalizeUtf8Text(
      _firstText([row['payment_method'], 'دفع إلكتروني']),
    );
    final refundStatus = (row['refund_status'] ?? '').toString();
    final isRefunded =
        refundStatus == 'refunded' ||
        row['refund_status'] == true ||
        row['refund_status'] == 1;
    final refundAmount = _toDouble(row['refund_amount']);
    return _FinanceRefundOrderRecord(
      orderId: orderId,
      userId: _toInt(row['user_id']),
      customerName: _normalizeUtf8Text(
        _firstText([row['customer_name'], 'عميل']),
      ),
      customerPhone: _firstText([row['customer_phone'], '-']),
      orderDatetime: _firstText([row['order_datetime'], '-']),
      statusLabel: _financeOrderStatusLabel(status),
      paymentMethod: paymentMethod.isEmpty ? 'دفع إلكتروني' : paymentMethod,
      paymentReference: _firstText([row['payment_reference'], '-']),
      orderTotalLabel:
          '${_formatUserWholeNumber(_toDouble(row['order_total']))} ${MasterCurrency.symbol}',
      paidAmountLabel:
          '${_formatUserWholeNumber(_toDouble(row['paid_amount']))} ${MasterCurrency.symbol}',
      refundAmountLabel:
          '${_formatUserWholeNumber(refundAmount)} ${MasterCurrency.symbol}',
      refundPointsLabel:
          '${_formatUserWholeNumber(_toDouble(row['refund_points']))} نقطة',
      refundStatusLabel: isRefunded ? 'مكتملة' : 'بانتظار الرد',
      refundedAt: _firstText([row['refunded_at'], '-']),
      note: _normalizeUtf8Text(_firstText([row['refund_note'], '-'])),
      isRefunded: isRefunded,
    );
  }).toList();
}

class _FinanceFiltersBar extends StatelessWidget {
  const _FinanceFiltersBar({
    required this.activeSubPage,
    required this.searchController,
    required this.onSubmitted,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.typeFilter,
    required this.sourceFilter,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onSourceChanged,
    required this.onAddPressed,
  });

  final String activeSubPage;
  final TextEditingController searchController;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onSearchChanged;
  final String statusFilter;
  final String typeFilter;
  final String sourceFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(_financePrimaryActionLabel(activeSubPage)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _activeActionColor(activeSubPage),
              foregroundColor: Colors.white,
              minimumSize: const Size(152, 44),
            ),
          ),
          const SizedBox(width: 10),
          _OrdersFilterButton(
            label: 'جميع الحالات',
            options: const {
              'all': 'جميع الحالات',
              'active': 'نشط',
              'stopped': 'متوقف',
              'ended': 'منتهي',
            },
            selectedKey: statusFilter,
            onChanged: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: 'جميع الأنواع',
            options: const {
              'all': 'جميع الأنواع',
              'wallet': 'محافظ',
              'fees': 'رسوم',
              'discounts': 'خصومات',
            },
            selectedKey: typeFilter,
            onChanged: onTypeChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: 'جميع المصادر',
            options: const {
              'all': 'جميع المصادر',
              'platform': 'المنصة',
              'restaurant': 'مطعم',
              'promo': 'ترويجي',
            },
            selectedKey: sourceFilter,
            onChanged: onSourceChanged,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: OutlinedButton.icon(
              onPressed: () => _showMasterSnack(context, 'تحديد الفترة'),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text('الفترة الحالية'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DeliverySearchBox(
              controller: searchController,
              hint: _financeSearchHint(activeSubPage),
              onChanged: onSearchChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }

  String _financeSearchHint(String key) {
    switch (key) {
      case 'commissions':
        return 'ابحث عن اسم القاعدة أو المصدر...';
      case 'fees':
        return 'ابحث عن مدينة أو منطقة أو محل...';
      case 'discounts':
      case 'discount_builder':
        return 'ابحث عن اسم الخصم أو الكود...';
      case 'records':
        return 'ابحث عن وصف، مرجع، أو رقم معاملة...';
      default:
        return 'ابحث برقم المحفظة أو اسم المستخدم...';
    }
  }

  Color _activeActionColor(String key) {
    switch (key) {
      case 'commissions':
      case 'wallets':
        return const Color(0xFF0F8A4A);
      case 'discounts':
      case 'discount_builder':
        return const Color(0xFF0F8A4A);
      default:
        return const Color(0xFF0F8A4A);
    }
  }
}

class _FinanceAccountingWorkspace extends StatelessWidget {
  const _FinanceAccountingWorkspace({
    required this.accounts,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> accounts;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Center(child: Text('لا توجد حسابات محاسبية مسجلة'));
    }
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'دليل الحسابات المحاسبية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: accounts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final row = accounts[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text((row['account_name'] ?? '').toString()),
                    subtitle: Text((row['account_type'] ?? '').toString()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ID ${row['account_id'] ?? ''}'),
                        IconButton(
                          tooltip: 'تعديل',
                          onPressed: () => onEdit(row),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => onDelete(row),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceWalletsWorkspace extends StatelessWidget {
  const _FinanceWalletsWorkspace({
    required this.wallets,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRefundCancelledOrder,
    required this.onAdjustWallet,
    required this.onToggleWallet,
  });

  final List<_FinanceWalletRecord> wallets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<_FinanceWalletRecord> onRefundCancelledOrder;
  final ValueChanged<_FinanceWalletRecord> onAdjustWallet;
  final ValueChanged<_FinanceWalletRecord> onToggleWallet;

  @override
  Widget build(BuildContext context) {
    final selected = wallets[selectedIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة المحافظ (${wallets.length})',
      detail: _FinanceWalletDetailsPanel(
        wallet: selected,
        onRefundCancelledOrder: onRefundCancelledOrder,
        onAdjustWallet: onAdjustWallet,
        onToggleWallet: onToggleWallet,
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (14, 'المحفظة'),
              (14, 'المستخدم'),
              (12, 'نوع المحفظة'),
              (12, 'الرصيد الحالي'),
              (12, 'المبالغ المستخدمة'),
              (10, 'المبالغ مقفلة'),
              (10, 'الحالة'),
              (8, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: wallets.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = wallets[index];
                final isSelected = index == selectedIndex;
                return InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    height: 66,
                    color: isSelected
                        ? const Color(0xFFF1F8F4)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 14,
                          child: _OrdersTwoLine(
                            title: item.walletId,
                            subtitle: item.status,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _AvatarThumb(
                                url: item.avatarUrl,
                                name: item.userName,
                                size: 34,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OrdersTwoLine(
                                  title: item.userName,
                                  subtitle: 'ID: ${item.userId}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _statusPill(item.typeLabel),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.currentBalance,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.usedAmount,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            item.lockedAmount,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(item.status),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: Icons.account_balance_wallet_outlined,
                                tooltip: 'تعديل الرصيد',
                                onTap: () => onAdjustWallet(item),
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: _masterStatusIsActive(item.status)
                                    ? Icons.block_outlined
                                    : Icons.check_circle_outline,
                                tooltip: _masterStatusIsActive(item.status)
                                    ? 'تعطيل'
                                    : 'تفعيل',
                                onTap: () => onToggleWallet(item),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceCommissionsWorkspace extends StatelessWidget {
  const _FinanceCommissionsWorkspace({
    required this.rules,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_CommissionRuleRecord> rules;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = rules[selectedIndex];
    return _MasterDetailTableLayout(
      title: 'تفاريغ العمولات',
      detail: _CommissionDetailsPanel(rule: selected),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (18, 'القاعدة'),
              (12, 'النوع'),
              (12, 'القيمة'),
              (16, 'تطبيق على'),
              (10, 'المصدر'),
              (10, 'الحالة'),
              (10, 'تاريخ الإنشاء'),
              (6, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = rules[index];
                final isSelected = index == selectedIndex;
                return InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    height: 64,
                    color: isSelected
                        ? const Color(0xFFF1F8F4)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 18,
                          child: _OrdersTwoLine(
                            title: item.name,
                            subtitle: item.description,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _statusPill(item.typeLabel),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.valueLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 16,
                          child: Text(
                            item.appliesTo,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(item.source, textAlign: TextAlign.center),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(item.status),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            item.createdAt,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: null,
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'حذف',
                                onTap: null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceFeesWorkspace extends StatelessWidget {
  const _FinanceFeesWorkspace({
    required this.fees,
    required this.selectedIndex,
    required this.onSelected,
    required this.onEditFee,
    required this.onToggleFee,
    required this.onDeleteFee,
  });

  final List<_FeeZoneRecord> fees;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<_FeeZoneRecord> onEditFee;
  final ValueChanged<_FeeZoneRecord> onToggleFee;
  final ValueChanged<_FeeZoneRecord> onDeleteFee;

  @override
  Widget build(BuildContext context) {
    final selected = fees[selectedIndex];
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'رسوم التوصيل حسب المناطق',
            child: Column(
              children: [
                const _RestaurantTableHeader(
                  columns: [
                    (18, 'المنطقة'),
                    (10, 'المدينة'),
                    (10, 'رسوم ثابت'),
                    (10, 'لكل كم إضافي'),
                    (10, 'رسوم الخدمة'),
                    (10, 'الحد الأدنى'),
                    (12, 'طرق التوصيل'),
                    (10, 'الحالة'),
                    (6, 'الإجراءات'),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: fees.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = fees[index];
                      final selectedRow = index == selectedIndex;
                      return InkWell(
                        onTap: () => onSelected(index),
                        child: Container(
                          height: 64,
                          color: selectedRow
                              ? const Color(0xFFF1F8F4)
                              : Colors.transparent,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _OrdersTableCell(
                                flex: 18,
                                child: Text(
                                  item.zoneName,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.city,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.fixedFee,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.extraKmFee,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.serviceFee,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.minimumOrder,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 12,
                                child: Text(
                                  item.deliveryMethods,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: _statusPill(item.status),
                              ),
                              _OrdersTableCell(
                                flex: 6,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _MiniIconButton(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'تعديل',
                                      onTap: () => onEditFee(item),
                                    ),
                                    const SizedBox(width: 4),
                                    _MiniIconButton(
                                      icon: Icons.delete_outline,
                                      tooltip: 'حذف',
                                      onTap: () => onDeleteFee(item),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 356,
          child: _FeesDetailsPanel(
            zone: selected,
            channels: const [
              _OrdersChannelData(
                label: 'رسوم التوصيل',
                value: 84950,
                percent: 58,
              ),
              _OrdersChannelData(
                label: 'رسوم الخدمة',
                value: 62430,
                percent: 42,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinanceDiscountsWorkspace extends StatelessWidget {
  const _FinanceDiscountsWorkspace({
    required this.coupons,
    required this.selectedCouponIndex,
    required this.onCouponSelected,
    required this.onOpenBuilder,
    required this.onAddCoupon,
    required this.onEditCoupon,
    required this.onToggleCoupon,
    required this.onDeleteCoupon,
  });

  final List<_FinanceCouponRecord> coupons;
  final int selectedCouponIndex;
  final ValueChanged<int> onCouponSelected;
  final VoidCallback onOpenBuilder;
  final VoidCallback onAddCoupon;
  final ValueChanged<_FinanceCouponRecord> onEditCoupon;
  final ValueChanged<_FinanceCouponRecord> onToggleCoupon;
  final ValueChanged<_FinanceCouponRecord> onDeleteCoupon;

  @override
  Widget build(BuildContext context) {
    final selected = coupons[selectedCouponIndex];
    return _MasterDetailTableLayout(
      title: 'الكوبونات (68)',
      detail: _FinanceCouponDetailsPanel(
        coupon: selected,
        onEditCoupon: () => onEditCoupon(selected),
        onToggleCoupon: () => onToggleCoupon(selected),
        onDeleteCoupon: () => onDeleteCoupon(selected),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7ECE8))),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      _FinanceMiniTab(
                        label: 'الكوبونات (68)',
                        active: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _FinanceMiniTab(
                        label: 'الخصومات (24)',
                        active: false,
                        onTap: onOpenBuilder,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onAddCoupon,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('إضافة خصم جديد'),
                ),
              ],
            ),
          ),
          const _RestaurantTableHeader(
            columns: [
              (14, 'الكوبون'),
              (14, 'النوع'),
              (12, 'قيمة التخفيض'),
              (12, 'الحد الأدنى'),
              (14, 'الاستخدام'),
              (12, 'الحالة'),
              (14, 'تاريخ الانتهاء'),
              (8, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: coupons.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = coupons[index];
                final isSelected = index == selectedCouponIndex;
                return InkWell(
                  onTap: () => onCouponSelected(index),
                  child: Container(
                    height: 66,
                    color: isSelected
                        ? const Color(0xFFF1F8F4)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 14,
                          child: _OrdersTwoLine(
                            title: item.code,
                            subtitle: item.restaurant,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: _statusPill(item.typeLabel),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.valueLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.minOrder,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Text(
                            item.usageLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _statusPill(item.status),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Text(
                            item.endDate,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => onEditCoupon(item),
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: _masterStatusIsActive(item.status)
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                tooltip: _masterStatusIsActive(item.status)
                                    ? 'إيقاف'
                                    : 'تفعيل',
                                onTap: () => onToggleCoupon(item),
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'حذف آمن',
                                onTap: () => onDeleteCoupon(item),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceDiscountBuilderWorkspace extends StatelessWidget {
  const _FinanceDiscountBuilderWorkspace({
    required this.discounts,
    required this.onBackToCoupons,
    required this.onEditDiscount,
    required this.onToggleDiscount,
    required this.onDeleteDiscount,
  });

  final List<_FinanceDiscountRecord> discounts;
  final VoidCallback onBackToCoupons;
  final ValueChanged<_FinanceDiscountRecord> onEditDiscount;
  final ValueChanged<_FinanceDiscountRecord> onToggleDiscount;
  final ValueChanged<_FinanceDiscountRecord> onDeleteDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _RestaurantShellCard(
                  title: 'الخصومات (24)',
                  child: Column(
                    children: [
                      const _RestaurantTableHeader(
                        columns: [
                          (18, 'اسم الخصم'),
                          (12, 'المصدر'),
                          (10, 'النوع'),
                          (10, 'قيمة الخصم'),
                          (10, 'قيمة الأقصى'),
                          (12, 'الاستخدام'),
                          (10, 'الحالة'),
                          (12, 'تاريخ الانتهاء'),
                          (6, 'الإجراءات'),
                        ],
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: discounts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = discounts[index];
                            return SizedBox(
                              height: 62,
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  _OrdersTableCell(
                                    flex: 18,
                                    child: _OrdersTwoLine(
                                      title: item.name,
                                      subtitle: item.code,
                                    ),
                                  ),
                                  _OrdersTableCell(
                                    flex: 12,
                                    child: Text(
                                      item.source,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  _OrdersTableCell(
                                    flex: 10,
                                    child: _statusPill(item.typeLabel),
                                  ),
                                  _OrdersTableCell(
                                    flex: 10,
                                    child: Text(
                                      item.valueLabel,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  _OrdersTableCell(
                                    flex: 10,
                                    child: Text(
                                      item.maxValueLabel,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  _OrdersTableCell(
                                    flex: 12,
                                    child: Text(
                                      item.usageLabel,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  _OrdersTableCell(
                                    flex: 10,
                                    child: _statusPill(item.status),
                                  ),
                                  _OrdersTableCell(
                                    flex: 12,
                                    child: Text(
                                      item.endDate,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  _OrdersTableCell(
                                    flex: 6,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _MiniIconButton(
                                          icon: Icons.edit_outlined,
                                          tooltip: 'تعديل',
                                          onTap: () => onEditDiscount(item),
                                        ),
                                        const SizedBox(width: 4),
                                        _MiniIconButton(
                                          icon: Icons.delete_outline,
                                          tooltip: 'حذف',
                                          onTap: () => onDeleteDiscount(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: _RestaurantShellCard(
                  title: 'شروط استخدام الخصم',
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: _detailMetricCard('المطاعم', 'جميع المطاعم'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _detailMetricCard(
                            'الحد الأدنى للطلب',
                            '50 ${MasterCurrency.symbol}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _detailMetricCard(
                            'الحد الأقصى للاستخدام',
                            '3 مرات',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _detailMetricCard('النطاق', 'جميع المناطق'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 380,
          child: _FinanceDiscountFormPanel(onBackToCoupons: onBackToCoupons),
        ),
      ],
    );
  }
}

class _FinanceRecordsWorkspace extends StatelessWidget {
  const _FinanceRecordsWorkspace({
    required this.records,
    required this.title,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_FinanceRecordEntry> records;
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: '$title (${records.length})',
            child: Column(
              children: [
                const _RestaurantTableHeader(
                  columns: [
                    (12, 'رقم المعاملة'),
                    (14, 'التاريخ والوقت'),
                    (18, 'الوصف'),
                    (12, 'النوع'),
                    (14, 'الحساب'),
                    (10, 'طريقة الدفع'),
                    (10, 'الحالة'),
                    (12, 'الرصيد بعد الحركة'),
                    (6, 'إجراءات'),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = records[index];
                      final isSelected = index == selectedIndex;
                      return InkWell(
                        onTap: () => onSelected(index),
                        child: Container(
                          height: 68,
                          color: isSelected
                              ? const Color(0xFFF1F8F4)
                              : Colors.transparent,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _OrdersTableCell(
                                flex: 12,
                                child: Text(
                                  item.reference,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 14,
                                child: Text(
                                  item.datetime,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 18,
                                child: Text(
                                  item.description,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 12,
                                child: _statusPill(item.typeLabel),
                              ),
                              _OrdersTableCell(
                                flex: 14,
                                child: Text(
                                  item.account,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.paymentMethod,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: _statusPill(item.status),
                              ),
                              _OrdersTableCell(
                                flex: 12,
                                child: Text(
                                  item.balanceAfter,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 6,
                                child: Center(
                                  child: _MiniIconButton(
                                    icon: Icons.visibility_outlined,
                                    tooltip: 'عرض',
                                    onTap: () =>
                                        _showFinanceRecordReport(context, item),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 352,
          child: _FinanceRecordsSummaryPanel(record: records[selectedIndex]),
        ),
      ],
    );
  }
}

class _FinanceRefundsWorkspace extends StatelessWidget {
  const _FinanceRefundsWorkspace({
    required this.orders,
    required this.records,
    required this.selectedIndex,
    required this.onSelected,
    required this.onRefundOrder,
  });

  final List<_FinanceRefundOrderRecord> orders;
  final List<_FinanceRecordEntry> records;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<_FinanceRefundOrderRecord> onRefundOrder;

  @override
  Widget build(BuildContext context) {
    final selected = orders.isEmpty ? null : orders[selectedIndex];
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'طلبات الاسترداد المؤهلة (${orders.length})',
            child: Column(
              children: [
                const _RestaurantTableHeader(
                  columns: [
                    (10, 'الطلب'),
                    (16, 'العميل'),
                    (12, 'قيمة الرد'),
                    (12, 'النقاط'),
                    (14, 'طريقة الدفع'),
                    (10, 'حالة الطلب'),
                    (12, 'حالة الرد'),
                    (8, 'إجراء'),
                  ],
                ),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد طلبات مدفوعة إلكترونيا بانتظار الاسترداد',
                          ),
                        )
                      : ListView.separated(
                          itemCount: orders.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = orders[index];
                            final isSelected = index == selectedIndex;
                            return InkWell(
                              onTap: () => onSelected(index),
                              child: Container(
                                height: 66,
                                color: isSelected
                                    ? const Color(0xFFF1F8F4)
                                    : Colors.transparent,
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    _OrdersTableCell(
                                      flex: 10,
                                      child: _OrdersTwoLine(
                                        title: '#${item.orderId}',
                                        subtitle: item.orderDatetime,
                                      ),
                                    ),
                                    _OrdersTableCell(
                                      flex: 16,
                                      child: _OrdersTwoLine(
                                        title: item.customerName,
                                        subtitle: item.customerPhone,
                                      ),
                                    ),
                                    _OrdersTableCell(
                                      flex: 12,
                                      child: Text(
                                        item.refundAmountLabel,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _OrdersTableCell(
                                      flex: 12,
                                      child: Text(
                                        item.refundPointsLabel,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _OrdersTableCell(
                                      flex: 14,
                                      child: Text(
                                        item.paymentMethod,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _OrdersTableCell(
                                      flex: 10,
                                      child: _statusPill(item.statusLabel),
                                    ),
                                    _OrdersTableCell(
                                      flex: 12,
                                      child: _statusPill(
                                        item.refundStatusLabel,
                                      ),
                                    ),
                                    _OrdersTableCell(
                                      flex: 8,
                                      child: Center(
                                        child: _MiniIconButton(
                                          icon: item.isRefunded
                                              ? Icons.check_circle_outline
                                              : Icons.restart_alt_rounded,
                                          tooltip: item.isRefunded
                                              ? 'تم الرد'
                                              : 'رد النقاط',
                                          onTap: item.isRefunded
                                              ? null
                                              : () => onRefundOrder(item),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 360,
          child: _FinanceRefundDetailsPanel(
            order: selected,
            records: records,
            onRefundOrder: selected == null || selected.isRefunded
                ? null
                : () => onRefundOrder(selected),
          ),
        ),
      ],
    );
  }
}

class _FinanceRefundDetailsPanel extends StatelessWidget {
  const _FinanceRefundDetailsPanel({
    required this.order,
    required this.records,
    required this.onRefundOrder,
  });

  final _FinanceRefundOrderRecord? order;
  final List<_FinanceRecordEntry> records;
  final VoidCallback? onRefundOrder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'تفاصيل الاسترداد',
            child: order == null
                ? const Center(child: Text('اختر طلبا لعرض التفاصيل'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: _statusPill(order!.refundStatusLabel),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'طلب #${order!.orderId}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order!.customerName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Color(0xFF6F7680)),
                        ),
                        const SizedBox(height: 12),
                        _detailMetricCard(
                          'قيمة الرد',
                          order!.refundAmountLabel,
                        ),
                        const SizedBox(height: 8),
                        _detailMetricCard(
                          'النقاط التي ستضاف',
                          order!.refundPointsLabel,
                        ),
                        const SizedBox(height: 12),
                        if (onRefundOrder != null)
                          SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: onRefundOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(
                                Icons.assignment_return_outlined,
                                size: 18,
                              ),
                              label: const Text('رد القيمة كنقاط'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _detailLine(
                          Icons.payments_outlined,
                          'طريقة الدفع',
                          order!.paymentMethod,
                        ),
                        _detailLine(
                          Icons.confirmation_number_outlined,
                          'مرجع الدفع',
                          order!.paymentReference,
                        ),
                        _detailLine(
                          Icons.request_quote_outlined,
                          'إجمالي الطلب',
                          order!.orderTotalLabel,
                        ),
                        _detailLine(
                          Icons.verified_outlined,
                          'المبلغ المدفوع',
                          order!.paidAmountLabel,
                        ),
                        _detailLine(
                          Icons.update_outlined,
                          'تاريخ الرد',
                          order!.refundedAt,
                        ),
                        _detailLine(
                          Icons.notes_outlined,
                          'ملاحظة',
                          order!.note,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 230,
          child: _RestaurantShellCard(
            title: 'آخر سجلات الاسترداد',
            child: records.isEmpty
                ? const Center(child: Text('لا توجد سجلات استرداد بعد'))
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: math.min(records.length, 5),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          record.reference,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          record.description,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Text(record.amount),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _WalletRefundRequest {
  const _WalletRefundRequest({required this.orderId, required this.note});

  final int orderId;
  final String note;
}

bool get _showLegacyWalletActions => false;

Future<_WalletRefundRequest?> _showWalletRefundDialog(
  BuildContext context,
  _FinanceWalletRecord? wallet, {
  int? initialOrderId,
  String? title,
}) async {
  final orderController = TextEditingController(
    text: initialOrderId == null ? '' : '$initialOrderId',
  );
  final noteController = TextEditingController(
    text: 'رد نقاط لطلب ملغي مدفوع إلكترونيا',
  );
  String? errorText;

  final result = await showDialog<_WalletRefundRequest>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('رد نقاط طلب ملغي'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title ?? wallet?.userName ?? 'استرداد طلب مدفوع إلكترونيا',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'رقم الطلب الملغي',
                      hintText: 'مثال: 5489',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    textAlign: TextAlign.right,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة إدارية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'سيتم التحقق من أن الطلب ملغي ومدفوع إلكترونيا، ثم تضاف قيمته كنقاط قابلة للدفع في محفظة العميل.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final orderId = int.tryParse(orderController.text.trim());
                  if (orderId == null || orderId <= 0) {
                    setDialogState(() {
                      errorText = 'أدخل رقم طلب صحيح';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    _WalletRefundRequest(
                      orderId: orderId,
                      note: noteController.text.trim(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('رد النقاط'),
              ),
            ],
          );
        },
      );
    },
  );

  orderController.dispose();
  noteController.dispose();
  return result;
}

class _FinanceWalletDetailsPanel extends StatelessWidget {
  const _FinanceWalletDetailsPanel({
    required this.wallet,
    required this.onRefundCancelledOrder,
    required this.onAdjustWallet,
    required this.onToggleWallet,
  });

  final _FinanceWalletRecord wallet;
  final ValueChanged<_FinanceWalletRecord> onRefundCancelledOrder;
  final ValueChanged<_FinanceWalletRecord> onAdjustWallet;
  final ValueChanged<_FinanceWalletRecord> onToggleWallet;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المحفظة',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(wallet.status),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEAF7EE),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _kPrimaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        wallet.walletId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wallet.typeLabel,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              wallet.currentBalance,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wallet.userName,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => onRefundCancelledOrder(wallet),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('رد نقاط طلب ملغي مدفوع إلكترونيا'),
              ),
            ),
            const SizedBox(height: 8),
            _detailMetricCard('النقاط التعويضية الحالية', wallet.pointsLabel),
            if (_showLegacyWalletActions) ...[
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _detailMetricCard(
                      'إجمالي المبالغ المستخدمة',
                      wallet.usedAmount,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailMetricCard(
                      'إجمالي المبالغ المضافة',
                      wallet.currentBalance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _detailMetricCard(
                      'إجمالي الاستردادات',
                      wallet.lockedAmount,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailMetricCard(
                      'عدد المعاملات',
                      '${wallet.transactionsCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAdjustWallet(wallet),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: _kPrimaryGreen,
                      ),
                      label: const Text('إضافة مبلغ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAdjustWallet(wallet),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFF2563EB),
                      ),
                      label: const Text(
                        'خصم مبلغ',
                        style: TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onRefundCancelledOrder(wallet),
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      label: const Text(
                        'استرداد',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAdjustWallet(wallet),
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: _kPrimaryGreen,
                      ),
                      label: const Text('تحويل'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _detailLine(
              Icons.calendar_today_outlined,
              'تاريخ الإنشاء',
              wallet.lastSettlement.isEmpty ? '-' : wallet.lastSettlement,
            ),
            _detailLine(
              Icons.update_outlined,
              'آخر معاملة',
              wallet.lastSettlement,
            ),
            _detailLine(
              Icons.category_outlined,
              'نوع المحفظة',
              wallet.typeLabel,
            ),
            _detailLine(Icons.person_outline, 'المستخدم', wallet.userName),
            _detailLine(Icons.call_outlined, 'رقم الهاتف', wallet.phone),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onToggleWallet(wallet),
              icon: const Icon(Icons.block_outlined, color: Color(0xFFDC2626)),
              label: const Text(
                'حظر المحفظة',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionDetailsPanel extends StatelessWidget {
  const _CommissionDetailsPanel({required this.rule});

  final _CommissionRuleRecord rule;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل قاعدة العمولة',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(rule.status),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFEAF7EE),
              child: const Icon(
                Icons.percent_rounded,
                size: 34,
                color: _kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              rule.name,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              rule.description,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF6F7680)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('النوع', rule.typeLabel),
                _detailMetricCard('القيمة', rule.valueLabel),
                _detailMetricCard('تطبيق على', rule.appliesTo),
                _detailMetricCard('المصدر', rule.source),
              ],
            ),
            const SizedBox(height: 14),
            _detailLine(Icons.flag_outlined, 'الأولوية', '${rule.priority}'),
            _detailLine(
              Icons.calendar_today_outlined,
              'تاريخ الإنشاء',
              rule.createdAt,
            ),
            _detailLine(Icons.update_outlined, 'آخر تحديث', rule.updatedAt),
            const Spacer(),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showMasterSnack(
                      context,
                      'قواعد العمولة هنا محسوبة من مبيعات المطاعم الحية',
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showMasterSnack(
                      context,
                      'قواعد العمولة هنا محسوبة من مبيعات المطاعم الحية',
                    ),
                    icon: const Icon(
                      Icons.pause_circle_outline,
                      color: Color(0xFFF59E0B),
                    ),
                    label: const Text(
                      'إلغاء تفعيل',
                      style: TextStyle(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'الحذف غير متاح',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeesDetailsPanel extends StatelessWidget {
  const _FeesDetailsPanel({required this.zone, required this.channels});

  final _FeeZoneRecord zone;
  final List<_OrdersChannelData> channels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'تفاصيل المنطقة',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _statusPill(zone.status),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    zone.zoneName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    zone.city,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Color(0xFF6F7680)),
                  ),
                  const SizedBox(height: 12),
                  _detailLine(
                    Icons.delivery_dining_outlined,
                    'رسوم التوصيل (ثابت)',
                    zone.fixedFee,
                  ),
                  _detailLine(
                    Icons.route_outlined,
                    'رسوم لكل كم إضافي',
                    zone.extraKmFee,
                  ),
                  _detailLine(
                    Icons.percent_rounded,
                    'رسوم الخدمة',
                    zone.serviceFee,
                  ),
                  _detailLine(
                    Icons.shopping_cart_outlined,
                    'الحد الأدنى للطلب',
                    zone.minimumOrder,
                  ),
                  _detailLine(
                    Icons.local_shipping_outlined,
                    'طرق التوصيل المتاحة',
                    zone.deliveryMethods,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showMasterSnack(context, 'اختبار الحساب'),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('اختبار الحساب'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: _RestaurantShellCard(
            title: 'توزيع الرسوم',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _OrdersChannelsDonut(channels: channels),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: _RestaurantShellCard(
            title: 'أفضل 5 مناطق من حيث الإيرادات',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _OrdersMetricLine(
                    label: '1. شارع الملك فهد',
                    value: '18,230',
                  ),
                  _OrdersMetricLine(label: '2. الروضة', value: '15,780'),
                  _OrdersMetricLine(label: '3. النخيل', value: '12,650'),
                  _OrdersMetricLine(label: '4. العزيزية', value: '11,420'),
                  _OrdersMetricLine(label: '5. الأندلس', value: '9,890'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceCouponDetailsPanel extends StatelessWidget {
  const _FinanceCouponDetailsPanel({
    required this.coupon,
    required this.onEditCoupon,
    required this.onToggleCoupon,
    required this.onDeleteCoupon,
  });

  final _FinanceCouponRecord coupon;
  final VoidCallback onEditCoupon;
  final VoidCallback onToggleCoupon;
  final VoidCallback onDeleteCoupon;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل الكوبون',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(coupon.status),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD6B8FF)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          coupon.code,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0B8F4D),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'انسخ الكود',
                              style: TextStyle(
                                color: Color(0xFF0B8F4D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.copy_outlined,
                              size: 18,
                              color: Color(0xFF0B8F4D),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ImageThumb(url: coupon.imageUrl, size: 92),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${coupon.valueLabel} خصم على جميع الطلبات',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'استمتع بخصم ينطبق على جميع أصناف المنصة',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF6F7680)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('النوع', coupon.typeLabel),
                _detailMetricCard('قيمة الخصم', coupon.valueLabel),
                _detailMetricCard('الحد الأدنى', coupon.minOrder),
                _detailMetricCard('عدد الاستخدامات', coupon.usageLabel),
                _detailMetricCard('النطاق', coupon.restaurant),
                _detailMetricCard('تاريخ الانتهاء', coupon.endDate),
              ],
            ),
            const Spacer(),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditCoupon,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل الكوبون'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleCoupon,
                    icon: Icon(
                      _masterStatusIsActive(coupon.status)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    label: Text(
                      _masterStatusIsActive(coupon.status) ? 'إيقاف' : 'تفعيل',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeleteCoupon,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceDiscountFormPanel extends StatelessWidget {
  const _FinanceDiscountFormPanel({required this.onBackToCoupons});

  final VoidCallback onBackToCoupons;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'إضافة خصم جديد',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'بيانات الخصم',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _FinanceField(
                label: 'اسم الخصم',
                value: 'مثال: خصم 20% على الطلبات',
              ),
              const SizedBox(height: 10),
              const Text(
                'نوع الخصم',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                children: const [
                  Expanded(
                    child: _FinanceChoiceChip(
                      label: 'نسبة مئوية',
                      active: true,
                      icon: Icons.percent_rounded,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _FinanceChoiceChip(
                      label: 'مبلغ ثابت',
                      active: false,
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FinanceField(label: 'قيمة الخصم', value: '20'),
              const SizedBox(height: 10),
              _FinanceField(
                label: 'الحد الأقصى للخصم (اختياري)',
                value: '50 ${MasterCurrency.symbol}',
              ),
              const SizedBox(height: 10),
              _FinanceField(label: 'كود الخصم (اختياري)', value: 'EATS20'),
              const SizedBox(height: 10),
              _FinanceField(label: 'المصدر', value: 'ترويجي'),
              const SizedBox(height: 10),
              _FinanceField(
                label: 'وصف الخصم (اختياري)',
                value: 'وصف مختصر عن هذا الخصم',
              ),
              const SizedBox(height: 12),
              const Text(
                'شروط استخدام الخصم',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _FinanceField(
                      label: 'الحد الأدنى للطلب',
                      value: '50 ${MasterCurrency.symbol}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FinanceField(
                      label: 'الحد الأقصى لعدد الاستخدام',
                      value: '3 مرات',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _FinanceField(
                      label: 'المطاعم',
                      value: 'جميع المطاعم',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FinanceField(label: 'جميع المناطق', value: 'نعم'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _FinanceField(label: 'تاريخ البدء', value: '-'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FinanceField(label: 'تاريخ الانتهاء', value: '-'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8EEDD)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.toggle_on_rounded,
                      color: _kPrimaryGreen,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text('الحالة'),
                    Spacer(),
                    Text(
                      'نشط',
                      style: TextStyle(
                        color: _kPrimaryGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBackToCoupons,
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () =>
                          _showMasterSnack(context, 'تم حفظ الخصم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryGreen,
                      ),
                      child: const Text('حفظ الخصم'),
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

void _showFinanceRecordReport(
  BuildContext context,
  _FinanceRecordEntry record,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تقرير السجل المالي', textAlign: TextAlign.right),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersMetricLine(label: 'المرجع', value: record.reference),
              _OrdersMetricLine(label: 'التاريخ', value: record.datetime),
              _OrdersMetricLine(label: 'الوصف', value: record.description),
              _OrdersMetricLine(label: 'الحساب', value: record.account),
              _OrdersMetricLine(label: 'النوع', value: record.typeLabel),
              _OrdersMetricLine(
                label: 'طريقة الدفع',
                value: record.paymentMethod,
              ),
              _OrdersMetricLine(label: 'القيمة', value: record.amount),
              _OrdersMetricLine(label: 'الحالة', value: record.status),
              _OrdersMetricLine(
                label: 'الرصيد بعد الحركة',
                value: record.balanceAfter,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}

void _downloadFinanceRecordCsv(_FinanceRecordEntry record) {
  final rows = <String>[
    'reference,datetime,description,account,type,payment_method,amount,status,balance_after',
    [
      record.reference,
      record.datetime,
      record.description,
      record.account,
      record.typeLabel,
      record.paymentMethod,
      record.amount,
      record.status,
      record.balanceAfter,
    ].map((value) => '"${value.replaceAll('"', '""')}"').join(','),
  ].join('\n');
  final blob = html.Blob([rows], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = 'finance-${record.reference}.csv'
    ..click();
  html.Url.revokeObjectUrl(url);
}

class _FinanceRecordsSummaryPanel extends StatelessWidget {
  const _FinanceRecordsSummaryPanel({required this.record});

  final _FinanceRecordEntry record;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'ملخص الفترة المحددة',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _OrdersMetricLine(
                    label: 'إجمالي الإيرادات',
                    value: '1,245,680.00',
                  ),
                  _OrdersMetricLine(
                    label: 'إجمالي المصروفات',
                    value: '623,450.00',
                  ),
                  _OrdersMetricLine(label: 'صافي الربح', value: '622,230.00'),
                  _OrdersMetricLine(label: 'عدد المعاملات', value: '12,458'),
                  _OrdersMetricLine(
                    label: 'متوسط قيمة المعاملة',
                    value: '99.92 ${MasterCurrency.symbol}',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: _RestaurantShellCard(
            title: 'توزيع الأنواع',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _OrdersChannelsDonut(
                channels: const [
                  _OrdersChannelData(
                    label: 'إيرادات',
                    value: 1245680,
                    percent: 65,
                  ),
                  _OrdersChannelData(
                    label: 'مصروفات',
                    value: 623450,
                    percent: 25,
                  ),
                  _OrdersChannelData(
                    label: 'تحويلات',
                    value: 156800,
                    percent: 8,
                  ),
                  _OrdersChannelData(label: 'تسويات', value: 32100, percent: 2),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: _RestaurantShellCard(
            title: 'أدوات سريعة',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _OrdersMetricLine(
                    label: 'مرجع محدد',
                    value: record.reference,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showFinanceRecordReport(context, record),
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('تقرير الأستاذ العام'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadFinanceRecordCsv(record),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('تصدير السجلات'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showFinanceRecordReport(context, record),
                          icon: const Icon(Icons.balance_outlined),
                          label: const Text('إعداد موازنة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showFinanceRecordReport(context, record),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('تسوية الحسابات'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceRightSidebar extends StatelessWidget {
  const _FinanceRightSidebar({
    required this.activeSubPage,
    required this.restrictedToEmployeePortal,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onOrdersTap,
    required this.onLogisticsTap,
    required this.onRestaurantsTap,
    required this.onUsersTap,
    required this.onMarketingTap,
    required this.onSupportTap,
    required this.onReportsTap,
    required this.onSettingsTap,
    required this.onAccessTap,
    required this.onCollapse,
  });

  final String activeSubPage;
  final bool restrictedToEmployeePortal;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLogisticsTap;
  final VoidCallback onRestaurantsTap;
  final VoidCallback onUsersTap;
  final VoidCallback onMarketingTap;
  final VoidCallback onSupportTap;
  final VoidCallback onReportsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onAccessTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('wallets', 'المحافظ', Icons.account_balance_wallet_outlined),
    ];
    if (restrictedToEmployeePortal) {
      return _buildEmployeePortalSidebar(context, items);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Expanded(
                    child: Text(
                      'التنقل',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.2,
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
              const SizedBox(height: 12),
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
                selected: false,
                onTap: onLogisticsTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'إدارة المطاعم',
                icon: Icons.storefront_outlined,
                selected: false,
                onTap: onRestaurantsTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'إدارة العملاء والمستخدمين',
                icon: Icons.people_alt_outlined,
                selected: false,
                onTap: onUsersTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'الإدارة المالية',
                icon: Icons.account_balance_wallet_outlined,
                selected: true,
                onTap: () => onSubPageTap('wallets'),
              ),
              const SizedBox(height: 10),
              Container(
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
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onSubPageTap(items[index].$1),
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
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
                          );
                        },
                      ),
                      if (index != items.length - 1) const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _OperationsSidebarMenuItem(
                data: const _OperationsSidebarTileData(
                  label: 'التسويق والنمو',
                  icon: Icons.campaign_outlined,
                ),
                onTap: onMarketingTap,
              ),
              const SizedBox(height: 8),
              for (final item in const [
                _OperationsSidebarTileData(
                  label: 'مركز التواصل',
                  icon: Icons.notifications_active_outlined,
                ),
                // 'الجودة وخدمة العملاء' removed per user request
                _OperationsSidebarTileData(
                  label: 'التقارير والتحليلات',
                  icon: Icons.query_stats_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'إعدادات المنصة',
                  icon: Icons.settings_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'الإدارة والصلاحيات',
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ]) ...[
                _OperationsSidebarMenuItem(
                  data: item,
                  onTap: () {
                    if (item.icon == Icons.notifications_active_outlined) {
                      onSupportTap();
                    } else if (item.icon == Icons.query_stats_outlined) {
                      _navigateToRememberedMasterSection(context, 'reports');
                    } else if (item.icon == Icons.settings_outlined) {
                      _navigateToRememberedMasterSection(context, 'settings');
                    } else if (item.icon ==
                        Icons.admin_panel_settings_outlined) {
                      _navigateToRememberedMasterSection(context, 'access');
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeePortalSidebar(
    BuildContext context,
    List<(String, String, IconData)> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Expanded(
                child: Text(
                  'التنقل',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13.2, fontWeight: FontWeight.w900),
                ),
              ),
              _OrdersSidebarToggleButton(
                tooltip: 'إخفاء القائمة الجانبية',
                icon: Icons.keyboard_double_arrow_right_rounded,
                active: true,
                onTap: onCollapse,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OperationsSidebarMainItem(
            label: 'الرئيسية',
            icon: Icons.home_rounded,
            selected: false,
            onTap: onHomeTap,
          ),
          const SizedBox(height: 10),
          _OperationsSidebarMainItem(
            label: 'الإدارة المالية',
            icon: Icons.account_balance_wallet_outlined,
            selected: true,
            onTap: () => onSubPageTap('wallets'),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            _OperationsSidebarMenuItem(
              data: _OperationsSidebarTileData(label: item.$2, icon: item.$3),
              onTap: () => onSubPageTap(item.$1),
            ),
        ],
      ),
    );
  }
}

class _FinanceMiniTab extends StatelessWidget {
  const _FinanceMiniTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF7EE) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFFD8EEDD) : const Color(0xFFE7ECE8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w800,
            color: onTap == null
                ? const Color(0xFFADB5BF)
                : active
                ? _kPrimaryGreen
                : const Color(0xFF6F7680),
          ),
        ),
      ),
    );
  }
}

class _FinanceField extends StatelessWidget {
  const _FinanceField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10.2,
                    color: Color(0xFF6F7680),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceChoiceChip extends StatelessWidget {
  const _FinanceChoiceChip({
    required this.label,
    required this.active,
    required this.icon,
  });

  final String label;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF7EE) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0xFFCAE9D2) : const Color(0xFFE7ECE8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? _kPrimaryGreen : const Color(0xFF6F7680),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? _kPrimaryGreen : const Color(0xFF6F7680),
            ),
          ),
        ],
      ),
    );
  }
}
