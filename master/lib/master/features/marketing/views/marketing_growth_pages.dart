// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterMarketingPage extends StatefulWidget {
  const MasterMarketingPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.initialSubPage = 'offers',
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final String initialSubPage;
  final bool unifiedFrame;

  @override
  State<MasterMarketingPage> createState() => _MasterMarketingPageState();
}

class _MasterMarketingPageState extends State<MasterMarketingPage> {
  late String _activeSubPage;
  bool _showNavigationSidebar = true;
  final TextEditingController _searchController = TextEditingController();
  late List<_MarketingOfferRecord> _offers;
  Map<String, List<_MarketingCatalogRecord>> _catalogs =
      const <String, List<_MarketingCatalogRecord>>{};
  List<_MarketingTargetChoice> _restaurantTargetChoices =
      const <_MarketingTargetChoice>[];
  List<_MarketingTargetChoice> _productTargetChoices =
      const <_MarketingTargetChoice>[];
  String _marketingStatusFilter = 'all';
  int _couponCount = 0;
  int _selectedOfferIndex = 0;
  int _selectedCatalogIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeSubPage = _normalizeMarketingSubPage(widget.initialSubPage);
    _offers = const <_MarketingOfferRecord>[];
    _loadLiveMarketingData();
    _loadMarketingTargetChoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedMarketingFrame(context);
    }
    final serverNow = widget.serverNow ?? DateTime.now();
    final activeSubPage = _normalizeMarketingSubPage(_activeSubPage);
    final visibleOffers = _filterMarketingOffers(_offers);
    final visibleCatalogs = _filterMarketingCatalogs(_catalogs);
    final effectiveOffers = visibleOffers;
    final effectiveCatalogs = visibleCatalogs;
    final effectiveCouponCount = _couponCount;
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
                            title: 'التسويق والنمو',
                            subtitle:
                                'إدارة جميع الحملات التسويقية ومحتوى التطبيق لنمو المنصة',
                            icon: Icons.campaign_outlined,
                          ),
                          const SizedBox(height: 10),
                          _OrdersStatsStrip(
                            cards: _buildMarketingLiveStatCards(
                              offers: effectiveOffers,
                              couponCount: effectiveCouponCount,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MarketingTabsBar(
                            activeSubPage: activeSubPage,
                            onTabTap: (value) {
                              setState(() {
                                _activeSubPage = value;
                                _selectedCatalogIndex = 0;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: activeSubPage == 'offers'
                                ? _MarketingOffersWorkspace(
                                    offers: effectiveOffers,
                                    selectedIndex: effectiveOffers.isEmpty
                                        ? 0
                                        : math.min(
                                            _selectedOfferIndex,
                                            effectiveOffers.length - 1,
                                          ),
                                    onSelected: (value) => setState(
                                      () => _selectedOfferIndex = value,
                                    ),
                                    onAdd: () => _showMarketingOfferEditor(),
                                    onFilter: _showMarketingFilterDialog,
                                    onEdit: (offer) =>
                                        _showMarketingOfferEditor(
                                          offer.id <= 0 ? null : offer,
                                        ),
                                    onToggle: (offer) {
                                      if (offer.id <= 0) {
                                        _showMasterSnack(
                                          context,
                                          'أضف العرض أولاً ثم يمكنك تفعيل/إيقافه',
                                        );
                                        return;
                                      }
                                      _toggleMarketingOffer(offer);
                                    },
                                    onDelete: (offer) {
                                      if (offer.id <= 0) {
                                        _showMasterSnack(
                                          context,
                                          'هذا الصف نموذجي فقط، أنشئ عرضًا حقيقيًا لحذفه',
                                        );
                                        return;
                                      }
                                      _deleteMarketingOffer(offer);
                                    },
                                    onAddCoupon: () =>
                                        _openMarketingCatalogEditor('coupons'),
                                  )
                                : _MarketingCatalogWorkspace(
                                    title: _marketingDisplayTitle(
                                      activeSubPage,
                                    ),
                                    records:
                                        effectiveCatalogs[activeSubPage] ??
                                        const <_MarketingCatalogRecord>[],
                                    selectedIndex: math.min(
                                      _selectedCatalogIndex,
                                      math.max(
                                        0,
                                        (effectiveCatalogs[activeSubPage] ??
                                                    const <
                                                      _MarketingCatalogRecord
                                                    >[])
                                                .length -
                                            1,
                                      ),
                                    ),
                                    onSelected: (value) => setState(
                                      () => _selectedCatalogIndex = value,
                                    ),
                                    onFilter: _showMarketingFilterDialog,
                                    onAdd: () => _showMarketingCatalogEditor(
                                      activeSubPage,
                                    ),
                                    onEdit: (record) =>
                                        _showMarketingCatalogEditor(
                                          activeSubPage,
                                          record: record.id <= 0
                                              ? null
                                              : record,
                                        ),
                                    onToggle: (record) {
                                      if (record.id <= 0) {
                                        _showMasterSnack(
                                          context,
                                          'أضف عنصرًا حقيقيًا أولاً ثم يمكنك تغييره',
                                        );
                                        return;
                                      }
                                      _toggleMarketingCatalog(
                                        activeSubPage,
                                        record,
                                      );
                                    },
                                    onDelete: (record) {
                                      if (record.id <= 0) {
                                        _showMasterSnack(
                                          context,
                                          'هذا الصف نموذجي فقط، أنشئ عنصرًا حقيقيًا لحذفه',
                                        );
                                        return;
                                      }
                                      _deleteMarketingCatalog(
                                        activeSubPage,
                                        record,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (_showNavigationSidebar) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: sidebarWidth,
                        child: _MarketingRightSidebar(
                          activeSubPage: _activeSubPage,
                          onSubPageTap: (value) {
                            setState(() {
                              _activeSubPage = value;
                              _selectedCatalogIndex = 0;
                            });
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
                          onFinanceTap: () => _navigateToMasterSection(
                            context,
                            key: 'finance',
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
  }

  Widget _buildUnifiedMarketingFrame(BuildContext context) {
    final serverNow = widget.serverNow ?? DateTime.now();
    final activeSubPage = _normalizeMarketingSubPage(_activeSubPage);
    final offers = _filterMarketingOffers(_offers);
    final catalogs = _filterMarketingCatalogs(_catalogs);
    final catalogRows =
        catalogs[activeSubPage] ?? const <_MarketingCatalogRecord>[];
    final workspace = activeSubPage == 'offers'
        ? _MarketingOffersWorkspace(
            offers: offers,
            selectedIndex: offers.isEmpty
                ? 0
                : math.min(_selectedOfferIndex, offers.length - 1),
            onSelected: (value) => setState(() => _selectedOfferIndex = value),
            onAdd: () => _showMarketingOfferEditor(),
            onFilter: _showMarketingFilterDialog,
            onEdit: (offer) =>
                _showMarketingOfferEditor(offer.id <= 0 ? null : offer),
            onToggle: (offer) => offer.id <= 0
                ? _showMasterSnack(context, 'أضف عرضًا حقيقيًا أولًا')
                : _toggleMarketingOffer(offer),
            onDelete: (offer) => offer.id <= 0
                ? _showMasterSnack(context, 'لا يمكن حذف السجل النموذجي')
                : _deleteMarketingOffer(offer),
            onAddCoupon: () => _openMarketingCatalogEditor('coupons'),
          )
        : _MarketingCatalogWorkspace(
            title: _marketingDisplayTitle(activeSubPage),
            records: catalogRows,
            selectedIndex: catalogRows.isEmpty
                ? 0
                : math.min(_selectedCatalogIndex, catalogRows.length - 1),
            onSelected: (value) =>
                setState(() => _selectedCatalogIndex = value),
            onFilter: _showMarketingFilterDialog,
            onAdd: () => _showMarketingCatalogEditor(activeSubPage),
            onEdit: (record) => _showMarketingCatalogEditor(
              activeSubPage,
              record: record.id <= 0 ? null : record,
            ),
            onToggle: (record) => record.id <= 0
                ? _showMasterSnack(context, 'أضف عنصرًا حقيقيًا أولًا')
                : _toggleMarketingCatalog(activeSubPage, record),
            onDelete: (record) => record.id <= 0
                ? _showMasterSnack(context, 'لا يمكن حذف السجل النموذجي')
                : _deleteMarketingCatalog(activeSubPage, record),
          );
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'marketing',
        label: 'التسويق والنمو',
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
        if (key == 'marketing') return;
        _navigateToMasterSection(
          context,
          key: key,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
      },
      statusLabel: 'التسويق والنمو',
      platformTitle: 'التسويق والنمو',
      platformSubtitle: 'العروض والحملات والمحتوى التسويقي',
      serverNow: serverNow,
      child: SingleChildScrollView(
        primary: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MarketingTabsBar(
                activeSubPage: activeSubPage,
                onTabTap: (value) => setState(() {
                  _activeSubPage = value;
                  _selectedCatalogIndex = 0;
                }),
              ),
              const SizedBox(height: 12),
              _OrdersStatsStrip(
                cards: _buildMarketingLiveStatCards(
                  offers: offers,
                  couponCount: _couponCount,
                ),
              ),
              const SizedBox(height: 12),
              workspace,
            ],
          ),
        ),
      ),
    );
  }

  void _reload() {
    _loadLiveMarketingData();
  }

  bool _marketingStatusVisible(String status) {
    switch (_marketingStatusFilter) {
      case 'active':
        return _masterStatusIsActive(status);
      case 'inactive':
        return !_masterStatusIsActive(status);
      default:
        return true;
    }
  }

  List<_MarketingOfferRecord> _filterMarketingOffers(
    List<_MarketingOfferRecord> rows,
  ) {
    return rows
        .where((row) => _marketingStatusVisible(row.status))
        .toList(growable: false);
  }

  List<_MarketingOfferRecord> _buildMarketingFallbackOffers() {
    return const [
      _MarketingOfferRecord(
        id: 0,
        name: 'خصم 25% على الطلبات',
        typeLabel: 'عرض مطعم',
        goal: 'الصفحة الرئيسية',
        startDate: '—',
        endDate: '—',
        views: 1280,
        clicks: 420,
        orders: 86,
        status: 'نشط',
        badgeText: '25%',
        badgeColor: Color(0xFF16A34A),
        targetType: 'restaurant',
        targetId: 0,
        placement: 'home',
        displaySeconds: 8,
      ),
      _MarketingOfferRecord(
        id: 0,
        name: 'توصيل مجاني اليوم',
        typeLabel: 'عرض منتج',
        goal: 'الصفحة الرئيسية',
        startDate: '—',
        endDate: '—',
        views: 980,
        clicks: 330,
        orders: 54,
        status: 'نشط',
        badgeText: 'FREE',
        badgeColor: Color(0xFF2563EB),
        targetType: 'product',
        targetId: 0,
        placement: 'home',
        displaySeconds: 8,
      ),
      _MarketingOfferRecord(
        id: 0,
        name: 'وجبة عائلية مميزة',
        typeLabel: 'عرض مطعم',
        goal: 'السلايدر الأول',
        startDate: '—',
        endDate: '—',
        views: 720,
        clicks: 210,
        orders: 31,
        status: 'متوقف',
        badgeText: 'NEW',
        badgeColor: Color(0xFFF97316),
        targetType: 'restaurant',
        targetId: 0,
        placement: 'slider',
        displaySeconds: 8,
      ),
    ];
  }

  Map<String, List<_MarketingCatalogRecord>> _buildMarketingFallbackCatalogs(
    Map<String, List<_MarketingCatalogRecord>> liveCatalogs,
  ) {
    final fallback = <String, List<_MarketingCatalogRecord>>{
      'coupons': [
        _marketingFallbackCatalog(
          id: 0,
          title: 'WELCOME20',
          subtitle: 'خصم 20%',
          typeLabel: 'كوبون',
          placement: 'التطبيق',
          metricLabel: 'الاستعمال المتبقي',
          metricValue: '120',
          status: 'نشط',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF7C3AED),
        ),
        _marketingFallbackCatalog(
          id: 0,
          title: 'RAMADAN15',
          subtitle: 'خصم 15%',
          typeLabel: 'كوبون',
          placement: 'التطبيق',
          metricLabel: 'الاستعمال المتبقي',
          metricValue: '90',
          status: 'نشط',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF7C3AED),
        ),
      ],
      'slider_primary': [
        _marketingFallbackCatalog(
          id: 0,
          title: 'السلايدر الأول',
          subtitle: 'عرض مميز',
          typeLabel: 'بنر',
          placement: 'home',
          metricLabel: 'الترتيب',
          metricValue: '1',
          status: 'نشطة',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF16A34A),
        ),
        _marketingFallbackCatalog(
          id: 0,
          title: 'السلايدر الأول - 2',
          subtitle: 'عرض موسمي',
          typeLabel: 'بنر',
          placement: 'home',
          metricLabel: 'الترتيب',
          metricValue: '2',
          status: 'نشطة',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFFF59E0B),
        ),
      ],
      'slider_secondary': [
        _marketingFallbackCatalog(
          id: 0,
          title: 'السلايدر الثاني',
          subtitle: 'عرض متوسط',
          typeLabel: 'بنر',
          placement: 'home_middle',
          metricLabel: 'الترتيب',
          metricValue: '1',
          status: 'نشطة',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF3B82F6),
        ),
      ],
      'featured': [
        _marketingFallbackCatalog(
          id: 0,
          title: 'الأقسام المميزة',
          subtitle: 'أقسام جاهزة للعرض',
          typeLabel: 'قسم مميز',
          placement: 'الصفحة الرئيسية',
          metricLabel: 'عدد المنتجات',
          metricValue: '3',
          status: 'نشطة',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF16A34A),
        ),
        _marketingFallbackCatalog(
          id: 0,
          title: 'وجبات سريعة',
          subtitle: 'أقسام مرئية',
          typeLabel: 'قسم مميز',
          placement: 'الصفحة الرئيسية',
          metricLabel: 'عدد المنتجات',
          metricValue: '6',
          status: 'نشطة',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF16A34A),
        ),
      ],
      'notifications': [
        _marketingFallbackCatalog(
          id: 0,
          title: 'حملة جديدة',
          subtitle: 'تم إطلاق حملة تسويقية جديدة داخل المنصة.',
          typeLabel: 'marketing',
          placement: 'المستخدمون',
          metricLabel: 'حالة القراءة',
          metricValue: '0',
          status: 'مرسل',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF2563EB),
        ),
        _marketingFallbackCatalog(
          id: 0,
          title: 'تنبيه فريق التسويق',
          subtitle: 'يوجد محتوى جديد جاهز للمراجعة والنشر.',
          typeLabel: 'marketing',
          placement: 'المستخدمون',
          metricLabel: 'حالة القراءة',
          metricValue: '0',
          status: 'مرسل',
          startDate: '—',
          endDate: '—',
          imageUrl: '',
          accent: const Color(0xFF2563EB),
        ),
      ],
    };

    final merged = <String, List<_MarketingCatalogRecord>>{
      for (final entry in fallback.entries) entry.key: entry.value,
    };

    for (final entry in liveCatalogs.entries) {
      if (entry.value.isNotEmpty) {
        merged[entry.key] = entry.value;
      } else {
        merged[entry.key] =
            fallback[entry.key] ?? const <_MarketingCatalogRecord>[];
      }
    }

    return merged;
  }

  _MarketingCatalogRecord _marketingFallbackCatalog({
    required int id,
    required String title,
    required String subtitle,
    required String typeLabel,
    required String placement,
    required String metricLabel,
    required String metricValue,
    required String status,
    required String startDate,
    required String endDate,
    required String imageUrl,
    required Color accent,
    String targetType = '',
  }) {
    return _MarketingCatalogRecord(
      id: id,
      title: title,
      subtitle: subtitle,
      typeLabel: typeLabel,
      placement: placement,
      metricLabel: metricLabel,
      metricValue: metricValue,
      status: status,
      startDate: startDate,
      endDate: endDate,
      imageUrl: imageUrl,
      accent: accent,
      targetType: targetType,
    );
  }

  Map<String, List<_MarketingCatalogRecord>> _filterMarketingCatalogs(
    Map<String, List<_MarketingCatalogRecord>> rows,
  ) {
    return rows.map(
      (key, value) => MapEntry(
        key,
        value
            .where((row) => _marketingStatusVisible(row.status))
            .toList(growable: false),
      ),
    );
  }

  Future<void> _showMarketingFilterDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('تصفية الحالة', textAlign: TextAlign.right),
        children: [
          ListTile(
            leading: Icon(
              _marketingStatusFilter == 'all'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: const Text('كل العناصر', textAlign: TextAlign.right),
            onTap: () => Navigator.of(dialogContext).pop('all'),
          ),
          ListTile(
            leading: Icon(
              _marketingStatusFilter == 'active'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: const Text('النشطة فقط', textAlign: TextAlign.right),
            onTap: () => Navigator.of(dialogContext).pop('active'),
          ),
          ListTile(
            leading: Icon(
              _marketingStatusFilter == 'inactive'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: const Text('المتوقفة فقط', textAlign: TextAlign.right),
            onTap: () => Navigator.of(dialogContext).pop('inactive'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _marketingStatusFilter = selected;
      _selectedOfferIndex = 0;
      _selectedCatalogIndex = 0;
    });
  }

  Future<void> _openMarketingCatalogEditor(String key) async {
    setState(() {
      _activeSubPage = key;
      _selectedCatalogIndex = 0;
    });
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    await _showMarketingCatalogEditor(key);
  }

  Future<void> _loadLiveMarketingData() async {
    try {
      final primary = await widget.api._fetchMasterMarketingOffersRaw(
        widget.session.token,
      );
      final primaryOffers = _buildMarketingOffersFromRaw(
        _asMapList(primary['offers']),
      );
      final sliderRows = _buildMarketingCatalogFromRaw(
        _asMapList(primary['sliders']),
      );
      final secondarySliderRows = _filterMarketingAdsByPlacement(
        sliderRows,
        'home_middle',
      );
      final primaryCatalogs = <String, List<_MarketingCatalogRecord>>{
        'coupons': _buildMarketingCatalogFromRaw(
          _asMapList(primary['coupons']),
        ),
        'slider_primary': _filterMarketingAdsByPlacement(sliderRows, 'home'),
        // Some existing ads were created before the second-slider placement
        // was introduced and are stored as `home`. Keep the page usable by
        // showing those records when no dedicated second-slider records exist.
        'slider_secondary': secondarySliderRows.isNotEmpty
            ? secondarySliderRows
            : sliderRows,
        'stories': _buildMarketingCatalogFromRaw(
          _asMapList(primary['stories']),
        ),
        'featured': _buildMarketingCatalogFromRaw(
          _asMapList(primary['featured']),
        ),
        'notifications': _buildMarketingCatalogFromRaw(
          _asMapList(primary['notifications']),
        ),
      };
      final fallback = await _loadMarketingFallbackBundle();
      final liveOffers = primaryOffers.isNotEmpty
          ? primaryOffers
          : fallback.offers;
      final liveCatalogs = <String, List<_MarketingCatalogRecord>>{};
      for (final key in const [
        'coupons',
        'slider_primary',
        'slider_secondary',
        'stories',
        'featured',
        'notifications',
      ]) {
        final primaryRows =
            primaryCatalogs[key] ?? const <_MarketingCatalogRecord>[];
        final fallbackRows =
            fallback.catalogs[key] ?? const <_MarketingCatalogRecord>[];
        liveCatalogs[key] = primaryRows.isNotEmpty ? primaryRows : fallbackRows;
      }
      final couponCount = _toInt(primary['coupon_count'], fallback.couponCount);
      if (!mounted) {
        return;
      }
      setState(() {
        _offers = liveOffers;
        _catalogs = liveCatalogs;
        if (_selectedOfferIndex >= _offers.length) {
          _selectedOfferIndex = math.max(0, _offers.length - 1);
        }
        final activeCatalog =
            liveCatalogs[_activeSubPage] ?? const <_MarketingCatalogRecord>[];
        if (_selectedCatalogIndex >= activeCatalog.length) {
          _selectedCatalogIndex = math.max(0, activeCatalog.length - 1);
        }
        _couponCount = couponCount;
      });
    } catch (_) {
      final fallback = await _loadMarketingFallbackBundle();
      if (!mounted) {
        return;
      }
      setState(() {
        _offers = fallback.offers;
        _catalogs = fallback.catalogs;
        _couponCount = fallback.couponCount;
        _selectedOfferIndex = _offers.isEmpty
            ? 0
            : math.min(_selectedOfferIndex, _offers.length - 1);
        final activeCatalog =
            _catalogs[_activeSubPage] ?? const <_MarketingCatalogRecord>[];
        _selectedCatalogIndex = activeCatalog.isEmpty
            ? 0
            : math.min(_selectedCatalogIndex, activeCatalog.length - 1);
      });
    }
  }

  Future<void> _loadMarketingTargetChoices() async {
    try {
      final results = await Future.wait([
        widget.api._fetchMasterRestaurants(widget.session.token),
        widget.api._fetchMasterRestaurantProductsRaw(widget.session.token),
      ]);
      final restaurants = results[0] as List<_RestaurantProfile>;
      final products = results[1] as List<Map<String, dynamic>>;

      final restaurantChoices = restaurants
          .map(
            (restaurant) => _MarketingTargetChoice(
              id: int.tryParse(restaurant.id) ?? 0,
              title: _normalizeUtf8Text(restaurant.name),
              subtitle: _normalizeUtf8Text(restaurant.subtitle),
            ),
          )
          .where((choice) => choice.id > 0)
          .toList(growable: false);
      final productChoices = products
          .map((row) {
            final id = _toInt(row['items_id'] ?? row['id']);
            return _MarketingTargetChoice(
              id: id,
              title: _normalizeUtf8Text(
                _firstText([
                  row['items_name_ar'],
                  row['items_name_en'],
                  'منتج',
                ]),
              ),
              subtitle: _normalizeUtf8Text(
                _firstText([row['store_name'], row['vendor_name'], '']),
              ),
            );
          })
          .where((choice) => choice.id > 0)
          .toList(growable: false);

      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantTargetChoices = restaurantChoices;
        _productTargetChoices = productChoices;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _restaurantTargetChoices = const <_MarketingTargetChoice>[];
        _productTargetChoices = const <_MarketingTargetChoice>[];
      });
    }
  }

  List<_MarketingTargetChoice> _marketingTargetChoicesFor(
    String targetType,
    int selectedId,
  ) {
    final choices = targetType == 'product'
        ? _productTargetChoices
        : _restaurantTargetChoices;
    if (selectedId <= 0 || choices.any((choice) => choice.id == selectedId)) {
      return choices;
    }

    return [
      _MarketingTargetChoice(
        id: selectedId,
        title: '#$selectedId',
        subtitle: 'القيمة الحالية',
      ),
      ...choices,
    ];
  }

  Future<_MarketingLiveBundle> _loadMarketingFallbackBundle() async {
    final homeData = await _fetchMarketingEndpoint('home-ecommerse/home.php');
    final couponData = await _fetchMarketingEndpoint('coupon/list_coupons.php');
    final adsData = await _fetchMarketingEndpoint('dash/ads/get/get_ads2.php');
    final storiesData = await _fetchMarketingEndpoint('videos/get_videos.php');
    final categoriesData = await _fetchMarketingEndpoint(
      'dash/sections/get/get_categories.php',
    );

    final home = _asMap(homeData['data']);
    final couponRows = _asMapList(couponData['data']);
    final adsRows = _asMapList(adsData['data']);
    final storyRows = _asMapList(storiesData['data']);
    final categoryRows = _asMapList(categoriesData['data']);

    final coupons = couponRows
        .map(
          (row) => _MarketingCatalogRecord(
            id: _toInt(row['coupon_id'] ?? row['id']),
            title: _normalizeUtf8Text(
              _firstText([
                row['coupon_name'],
                row['title'],
                '#${row['coupon_id'] ?? row['id']}',
              ]),
            ),
            subtitle: _normalizeUtf8Text(
              _firstText([
                row['coupon_discount'] != null
                    ? 'خصم ${_toInt(row['coupon_discount'])}%'
                    : row['subtitle'],
                '',
              ]),
            ),
            typeLabel: 'كوبون',
            placement: 'التطبيق',
            metricLabel: 'عدد الاستخدامات',
            metricValue: _formatUserWholeNumber(_toDouble(row['coupon_count'])),
            status: _couponStatusLabel(
              _toInt(row['coupon_count']) > 0 &&
                  _couponIsValid(row['coupon_expiredate']?.toString() ?? ''),
            ),
            startDate: '',
            endDate: row['coupon_expiredate']?.toString() ?? '',
            imageUrl: '',
            accent: const Color(0xFF7C3AED),
          ),
        )
        .toList(growable: false);

    final sliderRows = _buildFallbackAds(adsRows);
    final sliderPrimaryBanners = _filterMarketingAdsByPlacement(
      sliderRows,
      'home',
    );
    final sliderSecondaryBanners = _filterMarketingAdsByPlacement(
      sliderRows,
      'home_middle',
    );
    final stories = _buildFallbackStories(
      _normalizeFallbackVideoStories(storyRows),
    );
    final featured = _buildFallbackCategories(
      categoryRows.isNotEmpty ? categoryRows : _asMapList(home['categories']),
    );
    final offers = _buildFallbackOffers(_asMapList(home['banners']));

    return _MarketingLiveBundle(
      offers: offers,
      catalogs: {
        'coupons': coupons,
        'slider_primary': sliderPrimaryBanners,
        'slider_secondary': sliderSecondaryBanners.isNotEmpty
            ? sliderSecondaryBanners
            : sliderRows,
        'stories': stories,
        'featured': featured,
        'notifications': const <_MarketingCatalogRecord>[],
      },
      couponCount: coupons.length,
    );
  }

  Future<Map<String, dynamic>> _fetchMarketingEndpoint(String path) async {
    try {
      return await widget.api._sendGet(path, token: widget.session.token);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  List<_MarketingCatalogRecord> _filterMarketingAdsByPlacement(
    List<_MarketingCatalogRecord> rows,
    String placement,
  ) {
    final normalized = placement.trim().toLowerCase();
    if (normalized.isEmpty) {
      return rows;
    }

    return rows
        .where((row) {
          final currentPlacement = row.placement.trim().toLowerCase();
          if (normalized == 'home') {
            return currentPlacement == 'home' ||
                currentPlacement == 'slider' ||
                currentPlacement.isEmpty;
          }
          if (normalized == 'home_middle') {
            return currentPlacement == 'home_middle' ||
                currentPlacement == 'slider_2' ||
                currentPlacement == 'second';
          }
          return currentPlacement == normalized;
        })
        .toList(growable: false);
  }

  List<_MarketingCatalogRecord> _buildFallbackAds(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .map(
          (row) => _MarketingCatalogRecord(
            id: _toInt(row['id']),
            title: _normalizeUtf8Text(
              _firstText([
                row['title_ar'],
                row['title_en'],
                row['title'],
                row['items_name_ar'],
                row['items_name_en'],
                'إعلان سلايدر',
              ]),
            ),
            subtitle: 'إعلان من جدول ads',
            typeLabel: 'إعلان',
            placement: _firstText([row['placement'], 'slider']),
            metricLabel: 'مدة العرض',
            metricValue: _formatUserWholeNumber(
              _toDouble(row['display_seconds'], 8),
            ),
            status: _toInt(row['is_active'], 1) == 1 ? 'نشط' : 'متوقف',
            startDate: _firstText([row['created_at'], '']),
            endDate: _firstText([row['updated_at'], '']),
            imageUrl: _firstText([row['image_url'], '']),
            accent: const Color(0xFF16A34A),
            targetType: _firstText([row['target_type'], 'restaurant']),
            targetId: _toInt(row['target_id'] ?? row['item_id']),
            sortOrder: _toInt(row['sort_order']),
          ),
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _normalizeFallbackVideoStories(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .map((row) {
          if (!row.containsKey('video_id')) {
            return row;
          }
          final targetType = _firstText([
            row['video_target_type'],
            _toInt(row['video_product_id']) > 0 ? 'product' : 'video',
          ]);
          return <String, dynamic>{
            ...row,
            'id': row['video_id'],
            'title': row['video_title'],
            'vendor_name': _firstText([
              row['video_desc'],
              row['uploader_name'],
              row['product_name_ar'],
              row['product_name_en'],
              '',
            ]),
            'media_type': 'video',
            'target_type': targetType,
            'target_id':
                row['video_target_id'] ??
                row['video_product_id'] ??
                row['video_id'],
            'sort_order': row['video_views'],
            'is_active': 1,
            'starts_at': row['video_date'],
            'ends_at': '',
            'image_url': row['video_thumbnail'],
            'video_url': row['video_url'],
          };
        })
        .toList(growable: false);
  }

  List<_MarketingCatalogRecord> _buildFallbackStories(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .where((row) => !_isSeedStoryRow(row))
        .map(
          (row) => _MarketingCatalogRecord(
            id: _toInt(row['id'] ?? row['story_id']),
            title: _normalizeUtf8Text(
              _firstText([
                row['title_ar'],
                row['title_en'],
                row['title'],
                'Story',
              ]),
            ),
            subtitle: _normalizeUtf8Text(
              _firstText([row['vendor_name'], row['store_name'], '']),
            ),
            typeLabel: _firstText([row['media_type'], 'video']),
            placement: _firstText([row['target_type'], 'restaurant']),
            metricLabel: 'الترتيب',
            metricValue: _formatUserWholeNumber(_toDouble(row['sort_order'])),
            status: _toInt(row['is_active']) == 1 ? 'نشط' : 'متوقف',
            startDate: _firstText([row['starts_at'], '']),
            endDate: _firstText([row['ends_at'], '']),
            imageUrl: _firstText([
              row['video_thumbnail'],
              row['image_url'],
              '',
            ]),
            videoUrl: _firstText([row['video_url'], '']),
            accent: const Color(0xFF0EA5E9),
            targetType: _firstText([row['target_type'], 'restaurant']),
            targetId: _toInt(row['target_id']),
            vendorId: _toInt(row['vendor_id']),
            sortOrder: _toInt(row['sort_order']),
            mediaType: _firstText([row['media_type'], 'video']),
          ),
        )
        .toList(growable: false);
  }

  bool _isSeedStoryRow(Map<String, dynamic> row) {
    final mediaPath = _firstText([
      row['video_url'],
      row['image_url'],
      '',
    ]).toLowerCase();
    return mediaPath.contains('picsum.photos/seed/marketing-story-');
  }

  List<_MarketingCatalogRecord> _buildFallbackCategories(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .map(
          (row) => _MarketingCatalogRecord(
            id: _toInt(row['id'] ?? row['categories_id']),
            title: _normalizeUtf8Text(
              _firstText([
                row['name_ar'],
                row['categories_name_ar'],
                row['name_en'],
                row['categories_name_en'],
                'قسم مميز',
              ]),
            ),
            subtitle: 'قسم طعام',
            typeLabel: 'قسم مميز',
            placement: 'الصفحة الرئيسية',
            metricLabel: 'عدد المنتجات',
            metricValue: _formatUserWholeNumber(
              _toDouble(row['products_count']),
            ),
            status: _toInt(row['is_active'] ?? row['categories_active']) == 1
                ? 'نشط'
                : 'متوقف',
            startDate: _firstText([row['categories_datetime'], '']),
            endDate: '',
            imageUrl: _firstText([
              row['image_url'],
              row['categories_image'],
              '',
            ]),
            accent: const Color(0xFF16A34A),
            vendorId: _toInt(row['vendor_id']),
          ),
        )
        .toList(growable: false);
  }

  List<_MarketingOfferRecord> _buildFallbackOffers(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .map(
          (row) => _MarketingOfferRecord(
            id: _toInt(row['id']),
            name: _normalizeUtf8Text(
              _firstText([
                row['title_ar'],
                row['title_en'],
                row['items_name_ar'],
                row['items_name_en'],
                row['title'],
                'عرض صفحة العروض',
              ]),
            ),
            typeLabel: 'عرض صفحة العروض',
            goal: _normalizeUtf8Text(
              _firstText([
                row['subtitle_ar'],
                row['subtitle_en'],
                row['placement'],
                'صفحة العروض',
              ]),
            ),
            startDate: _firstText([row['starts_at'], row['created_at'], '-']),
            endDate: _firstText([row['ends_at'], '-']),
            views: 0,
            clicks: 0,
            orders: 0,
            status: _toInt(row['is_active'], 1) == 1 ? 'نشط' : 'متوقف',
            badgeText: 'عرض',
            badgeColor: const Color(0xFF16A34A),
            targetType: _offerTargetType(row),
            targetId: _offerTargetId(row),
            placement: _firstText([row['placement'], 'home']),
            displaySeconds: 8,
          ),
        )
        .toList(growable: false);
  }

  String _offerTargetType(Map<String, dynamic> row) {
    final explicit = _firstText([row['target_type'], '']).toLowerCase();
    if (explicit == 'product' || explicit == 'restaurant') {
      return explicit;
    }
    final target = _firstText([
      row['cta_target'],
      row['link_url'],
      '',
    ]).toLowerCase();
    return target.startsWith('product:') || target.startsWith('item:')
        ? 'product'
        : 'restaurant';
  }

  int _offerTargetId(Map<String, dynamic> row) {
    final explicit = _toInt(row['target_id'] ?? row['item_id']);
    if (explicit > 0) {
      return explicit;
    }
    final target = _firstText([row['cta_target'], row['link_url'], '']);
    final match = RegExp(r'(\d+)').firstMatch(target);
    return match == null ? 0 : int.tryParse(match.group(1) ?? '') ?? 0;
  }

  bool _looksLikeVideoUrl(String value) => _marketingLooksLikeVideoUrl(value);

  Future<html.File?> _pickMarketingVideoFile() async {
    final input = html.FileUploadInputElement()
      ..accept = 'video/mp4,video/webm,video/quicktime,video/*'
      ..multiple = false;
    input.click();
    await input.onChange.first;
    return input.files?.isNotEmpty == true ? input.files!.first : null;
  }

  Future<html.File?> _pickMarketingImageFile() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/png,image/jpeg,image/webp,image/gif'
      ..multiple = false;
    input.click();
    await input.onChange.first;
    return input.files?.isNotEmpty == true ? input.files!.first : null;
  }

  Future<void> _runMarketingAction({
    required String entity,
    required String action,
    int? id,
    Map<String, dynamic>? data,
    required String successMessage,
  }) async {
    try {
      await widget.api._runMasterMarketingAction(
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

  Future<void> _showMarketingOfferEditor([_MarketingOfferRecord? offer]) async {
    final titleController = TextEditingController(text: offer?.name ?? '');
    final imageController = TextEditingController();
    final targetController = TextEditingController(
      text: offer == null || offer.targetId <= 0 ? '' : '${offer.targetId}',
    );
    final placementController = TextEditingController(
      text: offer?.placement ?? 'home',
    );
    final secondsController = TextEditingController(
      text: '${offer?.displaySeconds ?? 8}',
    );
    var targetType = offer?.targetType == 'product' ? 'product' : 'restaurant';
    var selectedTargetId = offer?.targetId ?? 0;
    var isUploadingImage = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final targetChoices = _marketingTargetChoicesFor(
              targetType,
              selectedTargetId,
            );
            return AlertDialog(
              title: Text(
                offer == null ? 'عرض جديد' : 'تعديل العرض',
                textAlign: TextAlign.right,
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'اسم العرض',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageController,
                      textAlign: TextAlign.right,
                      readOnly: true,
                      onTap: isUploadingImage
                          ? null
                          : () async {
                              final file = await _pickMarketingImageFile();
                              if (file == null || !dialogContext.mounted) {
                                return;
                              }
                              setDialogState(() {
                                isUploadingImage = true;
                              });
                              try {
                                imageController.text = await widget.api
                                    ._uploadMasterMarketingImage(
                                      widget.session.token,
                                      file: file,
                                    );
                              } catch (error) {
                                if (dialogContext.mounted) {
                                  _showMasterSnack(
                                    dialogContext,
                                    error.toString(),
                                  );
                                }
                              } finally {
                                if (dialogContext.mounted) {
                                  setDialogState(
                                    () => isUploadingImage = false,
                                  );
                                }
                              }
                            },
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.upload_file_outlined),
                        labelText: 'رفع الصورة من الجهاز',
                        helperText:
                            'اضغط لاختيار صورة من جهازك ورفعها تلقائيًا',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: targetType,
                      items: const [
                        DropdownMenuItem(
                          value: 'restaurant',
                          child: Text('مطعم'),
                        ),
                        DropdownMenuItem(value: 'product', child: Text('منتج')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            targetType = value;
                            selectedTargetId = 0;
                            targetController.clear();
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'نوع الهدف',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'offer-target-$targetType-$selectedTargetId-${targetChoices.length}',
                      ),
                      initialValue: selectedTargetId > 0
                          ? selectedTargetId
                          : null,
                      isExpanded: true,
                      items: targetChoices
                          .map(
                            (choice) => DropdownMenuItem<int>(
                              value: choice.id,
                              child: Text(
                                choice.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: targetChoices.isEmpty
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedTargetId = value ?? 0;
                                targetController.text = selectedTargetId > 0
                                    ? '$selectedTargetId'
                                    : '';
                              });
                            },
                      decoration: InputDecoration(
                        labelText: targetType == 'product'
                            ? 'اختر المنتج'
                            : 'اختر المطعم',
                        prefixIcon: Icon(
                          targetType == 'product'
                              ? Icons.inventory_2_outlined
                              : Icons.storefront_outlined,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    Offstage(
                      child: TextField(
                        controller: targetController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رقم المطعم أو المنتج',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: placementController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'موضع العرض',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: secondsController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'مدة العرض بالثواني',
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
      },
    );
    if (saved == true && mounted) {
      if (offer?.id == -1) {
        _showMasterSnack(context, 'ارفع الفيديو أولًا قبل الحفظ');
      } else {
        await _runMarketingAction(
          entity: 'offer',
          action: 'save',
          id: offer?.id,
          successMessage: 'تم حفظ العرض',
          data: {
            'title': titleController.text.trim(),
            if (imageController.text.trim().isNotEmpty)
              'image_url': imageController.text.trim(),
            'target_type': targetType,
            'target_id': selectedTargetId,
            'placement': placementController.text.trim(),
            'display_seconds': int.tryParse(secondsController.text.trim()) ?? 8,
            'is_active': 1,
          },
        );
      }
    }
    titleController.dispose();
    imageController.dispose();
    targetController.dispose();
    placementController.dispose();
    secondsController.dispose();
  }

  Future<void> _toggleMarketingOffer(_MarketingOfferRecord offer) async {
    final active = _masterStatusIsActive(offer.status);
    await _runMarketingAction(
      entity: 'offer',
      action: active ? 'disable' : 'activate',
      id: offer.id,
      successMessage: active ? 'تم إيقاف العرض' : 'تم تفعيل العرض',
    );
  }

  Future<void> _deleteMarketingOffer(_MarketingOfferRecord offer) async {
    await _runMarketingAction(
      entity: 'offer',
      action: 'delete',
      id: offer.id,
      successMessage: 'تم تعطيل العرض بأمان',
    );
  }

  String _marketingCatalogEntity(String key) {
    return switch (key) {
      'coupons' => 'coupon',
      'slider_primary' || 'slider_secondary' || 'sliders' => 'ad',
      'stories' => 'video',
      'featured' => 'category',
      'notifications' => 'notification',
      _ => '',
    };
  }

  String _marketingCatalogPlacement(String key, [String? fallback]) {
    final normalizedKey = key.trim().toLowerCase();
    if (normalizedKey == 'slider_secondary' ||
        normalizedKey == 'slider_home_middle' ||
        normalizedKey == 'sliders_secondary') {
      return 'home_middle';
    }
    if (normalizedKey == 'slider_primary' ||
        normalizedKey == 'slider_home' ||
        normalizedKey == 'sliders' ||
        normalizedKey == 'sliders_primary') {
      return 'home';
    }
    return fallback?.trim().isNotEmpty == true ? fallback!.trim() : 'home';
  }

  Future<void> _showMarketingCatalogEditor(
    String key, {
    _MarketingCatalogRecord? record,
  }) async {
    final entity = _marketingCatalogEntity(key);
    if (entity.isEmpty) {
      _showMasterSnack(context, 'هذا القسم للعرض من البيانات الحية فقط');
      return;
    }
    if (entity == 'notification') {
      await _showMarketingNotificationComposer(record: record);
      return;
    }
    final titleController = TextEditingController(text: record?.title ?? '');
    final subtitleController = TextEditingController(
      text: record?.subtitle ?? '',
    );
    final placementController = TextEditingController(
      text: entity == 'notification'
          ? 'marketing'
          : entity == 'ad'
          ? _marketingCatalogPlacement(key, record?.placement ?? 'home')
          : record?.placement ?? 'home',
    );
    final metricController = TextEditingController(
      text: entity == 'notification'
          ? ''
          : entity == 'story' || entity == 'video'
          ? (record == null || record.targetId <= 0 ? '' : '${record.targetId}')
          : entity == 'category'
          ? (record == null || record.vendorId <= 0 ? '' : '${record.vendorId}')
          : record?.metricValue ?? '',
    );
    final endDateController = TextEditingController(
      text: record?.endDate ?? '',
    );
    final videoController = TextEditingController(
      text: entity == 'video' ? (record?.videoUrl ?? '') : '',
    );
    final imageController = TextEditingController(text: record?.imageUrl ?? '');
    var isUploadingVideo = false;
    var isUploadingImage = false;
    var uploadedVideoUrl = videoController.text.trim();
    String? uploadedVideoName;
    var selectedCatalogTargetId =
        int.tryParse(metricController.text.trim()) ?? 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewUrl = videoController.text.trim();
            final catalogTargetType =
                placementController.text.trim() == 'product'
                ? 'product'
                : 'restaurant';
            final catalogTargetChoices = _marketingTargetChoicesFor(
              catalogTargetType,
              selectedCatalogTargetId,
            );
            final dialogWidth = math.max(
              320.0,
              math.min(
                MediaQuery.of(context).size.width - 64,
                entity == 'video' ? 720.0 : 540.0,
              ),
            );
            return AlertDialog(
              insetPadding: const EdgeInsets.all(24),
              titlePadding: EdgeInsets.zero,
              title: _MarketingEditorHeader(
                title: record == null ? 'إضافة جديدة' : 'تعديل العنصر',
                subtitle: entity == 'video'
                    ? 'ارفع الفيديو من جهازك أو ضع رابط فيديو مباشر، وستظهر المعاينة قبل الحفظ.'
                    : 'أدخل بيانات العنصر التسويقي واحفظها في قاعدة البيانات.',
                icon: entity == 'video'
                    ? Icons.video_library_outlined
                    : Icons.edit_note_outlined,
              ),
              content: Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: dialogWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entity == 'video') ...[
                          _MarketingVideoUploadPreview(
                            videoUrl: previewUrl,
                            fileName: uploadedVideoName,
                            isUploading: isUploadingVideo,
                            onUpload: isUploadingVideo
                                ? null
                                : () async {
                                    final file =
                                        await _pickMarketingVideoFile();
                                    if (file == null) {
                                      return;
                                    }
                                    if (!dialogContext.mounted) {
                                      return;
                                    }
                                    setDialogState(() {
                                      isUploadingVideo = true;
                                      uploadedVideoName = file.name;
                                    });
                                    try {
                                      final url = await widget.api
                                          ._uploadMasterMarketingVideo(
                                            widget.session.token,
                                            file: file,
                                          );
                                      if (!dialogContext.mounted) {
                                        return;
                                      }
                                      videoController.text = url;
                                      uploadedVideoUrl = url.trim();
                                      setDialogState(() {
                                        isUploadingVideo = false;
                                        uploadedVideoName = file.name;
                                      });
                                      if (dialogContext.mounted) {
                                        _showMasterSnack(
                                          dialogContext,
                                          'تم رفع الفيديو',
                                        );
                                      }
                                    } catch (error) {
                                      if (!dialogContext.mounted) {
                                        return;
                                      }
                                      setDialogState(() {
                                        isUploadingVideo = false;
                                      });
                                      if (dialogContext.mounted) {
                                        _showMasterSnack(
                                          dialogContext,
                                          error.toString(),
                                        );
                                      }
                                    }
                                  },
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (entity == 'never-video')
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              'video-target-$catalogTargetType-$selectedCatalogTargetId-${catalogTargetChoices.length}',
                            ),
                            initialValue: selectedCatalogTargetId > 0
                                ? selectedCatalogTargetId
                                : null,
                            isExpanded: true,
                            items: catalogTargetChoices
                                .map(
                                  (choice) => DropdownMenuItem<int>(
                                    value: choice.id,
                                    child: Text(
                                      choice.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: catalogTargetChoices.isEmpty
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      selectedCatalogTargetId = value ?? 0;
                                      metricController.text =
                                          selectedCatalogTargetId > 0
                                          ? '$selectedCatalogTargetId'
                                          : '';
                                    });
                                  },
                            decoration: InputDecoration(
                              labelText: catalogTargetType == 'product'
                                  ? 'اختر المنتج'
                                  : 'اختر المطعم',
                              prefixIcon: Icon(
                                catalogTargetType == 'product'
                                    ? Icons.inventory_2_outlined
                                    : Icons.storefront_outlined,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          )
                        else
                          TextField(
                            controller: titleController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: entity == 'coupon'
                                  ? 'كود الكوبون'
                                  : 'العنوان',
                              prefixIcon: const Icon(Icons.title_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: subtitleController,
                          textAlign: TextAlign.right,
                          minLines: entity == 'video' ? 2 : 1,
                          maxLines: entity == 'video' ? 3 : 1,
                          decoration: InputDecoration(
                            labelText: entity == 'coupon'
                                ? 'نسبة الخصم'
                                : 'الوصف',
                            prefixIcon: Icon(
                              entity == 'coupon'
                                  ? Icons.percent_outlined
                                  : Icons.notes_outlined,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (entity == 'video')
                          DropdownButtonFormField<String>(
                            initialValue:
                                placementController.text.trim() == 'product'
                                ? 'product'
                                : 'restaurant',
                            decoration: const InputDecoration(
                              labelText: 'وجهة الفيديو',
                              prefixIcon: Icon(Icons.ads_click_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'restaurant',
                                child: Text('مطعم'),
                              ),
                              DropdownMenuItem(
                                value: 'product',
                                child: Text('منتج'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                placementController.text = value;
                                selectedCatalogTargetId = 0;
                                metricController.clear();
                              });
                            },
                          )
                        else
                          TextField(
                            controller: placementController,
                            readOnly: entity == 'ad',
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: entity == 'ad'
                                  ? 'الموضع (محدد تلقائياً)'
                                  : 'الموضع / النوع',
                              prefixIcon: Icon(
                                entity == 'ad'
                                    ? Icons.lock_outline
                                    : Icons.place_outlined,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (entity == 'video')
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              'video-target-$catalogTargetType-$selectedCatalogTargetId-${catalogTargetChoices.length}',
                            ),
                            initialValue: selectedCatalogTargetId > 0
                                ? selectedCatalogTargetId
                                : null,
                            isExpanded: true,
                            items: catalogTargetChoices
                                .map(
                                  (choice) => DropdownMenuItem<int>(
                                    value: choice.id,
                                    child: Text(
                                      choice.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: catalogTargetChoices.isEmpty
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      selectedCatalogTargetId = value ?? 0;
                                      metricController.text =
                                          selectedCatalogTargetId > 0
                                          ? '$selectedCatalogTargetId'
                                          : '';
                                    });
                                  },
                            decoration: InputDecoration(
                              labelText: catalogTargetType == 'product'
                                  ? 'اختر المنتج'
                                  : 'اختر المطعم',
                              prefixIcon: Icon(
                                catalogTargetType == 'product'
                                    ? Icons.inventory_2_outlined
                                    : Icons.storefront_outlined,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          )
                        else
                          TextField(
                            controller: metricController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: entity == 'coupon'
                                  ? 'عدد الاستخدامات'
                                  : entity == 'ad'
                                  ? 'مدة العرض بالثواني'
                                  : entity == 'video'
                                  ? 'رقم المطعم أو المنتج'
                                  : 'ترتيب العرض',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: endDateController,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ النهاية',
                            hintText: 'YYYY-MM-DD HH:MM:SS',
                            prefixIcon: Icon(Icons.event_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (entity == 'ad' ||
                            entity == 'banner' ||
                            entity == 'story' ||
                            entity == 'video' ||
                            entity == 'category') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: imageController,
                            textAlign: TextAlign.left,
                            textDirection: TextDirection.ltr,
                            readOnly: true,
                            onTap: isUploadingVideo || isUploadingImage
                                ? null
                                : () async {
                                    final file =
                                        await _pickMarketingImageFile();
                                    if (file == null ||
                                        !dialogContext.mounted) {
                                      return;
                                    }
                                    setDialogState(
                                      () => isUploadingImage = true,
                                    );
                                    try {
                                      imageController.text = await widget.api
                                          ._uploadMasterMarketingImage(
                                            widget.session.token,
                                            file: file,
                                          );
                                    } catch (error) {
                                      if (dialogContext.mounted) {
                                        _showMasterSnack(
                                          dialogContext,
                                          error.toString(),
                                        );
                                      }
                                    } finally {
                                      if (dialogContext.mounted) {
                                        setDialogState(
                                          () => isUploadingImage = false,
                                        );
                                      }
                                    }
                                  },
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              suffixIcon: const Icon(
                                Icons.upload_file_outlined,
                              ),
                              labelText: entity == 'video'
                                  ? 'رفع صورة الغلاف من الجهاز'
                                  : 'رفع الصورة من الجهاز',
                              helperText:
                                  'اضغط لاختيار ملف من جهازك ورفعه تلقائيًا',
                              prefixIcon: Icon(
                                entity == 'video'
                                    ? Icons.link_outlined
                                    : Icons.image_outlined,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.start,
              actions: [
                TextButton(
                  onPressed: isUploadingVideo || isUploadingImage
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: isUploadingVideo || isUploadingImage
                      ? null
                      : () {
                          if (entity == 'video' &&
                              uploadedVideoUrl.trim().isEmpty &&
                              videoController.text.trim().isEmpty) {
                            _showMasterSnack(
                              dialogContext,
                              'ارفع ملف الفيديو وانتظر اكتمال الرفع قبل الحفظ',
                            );
                            return;
                          }
                          Navigator.of(dialogContext).pop(true);
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == true && mounted) {
      await _runMarketingAction(
        entity: entity,
        action: 'save',
        id: record?.id,
        successMessage: 'تم حفظ العنصر',
        data: _buildMarketingCatalogPayload(
          entity: entity,
          title: titleController.text.trim(),
          subtitle: subtitleController.text.trim(),
          placement: placementController.text.trim(),
          metric: metricController.text.trim(),
          endDate: endDateController.text.trim(),
          imageUrl: imageController.text.trim(),
          videoUrl: uploadedVideoUrl.trim().isNotEmpty
              ? uploadedVideoUrl.trim()
              : videoController.text.trim(),
          record: record,
          catalogKey: key,
        ),
      );
    }
    titleController.dispose();
    subtitleController.dispose();
    placementController.dispose();
    metricController.dispose();
    endDateController.dispose();
    imageController.dispose();
    videoController.dispose();
  }

  Future<void> _showMarketingNotificationComposer({
    _MarketingCatalogRecord? record,
  }) async {
    List<_UserRecord> users = const <_UserRecord>[];
    try {
      users = (await widget.api._fetchMasterUsersOverview(
        widget.session.token,
      )).users;
    } catch (_) {
      users = const <_UserRecord>[];
    }

    if (!mounted) {
      return;
    }

    final titleController = TextEditingController(text: record?.title ?? '');
    final bodyController = TextEditingController(text: record?.subtitle ?? '');
    final searchController = TextEditingController();
    var sendToAll = true;
    _UserRecord? selectedUser;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredUsers = query.isEmpty
                ? users.take(20).toList(growable: false)
                : users
                      .where(
                        (user) =>
                            user.name.toLowerCase().contains(query) ||
                            user.email.toLowerCase().contains(query),
                      )
                      .take(20)
                      .toList(growable: false);
            final canSend =
                titleController.text.trim().isNotEmpty &&
                bodyController.text.trim().isNotEmpty &&
                (sendToAll || selectedUser != null);
            final dialogWidth = math.max(
              320.0,
              math.min(MediaQuery.of(context).size.width - 64, 680.0),
            );

            return AlertDialog(
              insetPadding: const EdgeInsets.all(24),
              titlePadding: EdgeInsets.zero,
              title: const _MarketingEditorHeader(
                title: 'إرسال إشعار تسويقي',
                subtitle:
                    'الإشعار الجماعي يصل لكل المستخدمين، أما الفردي فيتطلب اختيار مستخدم من البحث بالاسم أو البريد.',
                icon: Icons.notifications_active_outlined,
              ),
              content: Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: dialogWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'عنوان الإشعار',
                            prefixIcon: Icon(Icons.title_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: bodyController,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setDialogState(() {}),
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'نص الرسالة',
                            prefixIcon: Icon(Icons.notes_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MarketingAudienceCard(
                                selected: sendToAll,
                                icon: Icons.groups_outlined,
                                title: 'إشعار جماعي',
                                subtitle: 'إرسال الرسالة لكل المستخدمين.',
                                onTap: () {
                                  setDialogState(() {
                                    sendToAll = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MarketingAudienceCard(
                                selected: !sendToAll,
                                icon: Icons.person_search_outlined,
                                title: 'إشعار فردي',
                                subtitle:
                                    'اختيار مستخدم واحد بالاسم أو البريد.',
                                onTap: () {
                                  setDialogState(() {
                                    sendToAll = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (!sendToAll) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: searchController,
                            textAlign: TextAlign.right,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_outlined),
                              labelText: 'ابحث بالاسم أو البريد الإلكتروني',
                              hintText: 'مثال: ahmad أو user@email.com',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (selectedUser != null)
                            _SelectedMarketingUser(user: selectedUser!),
                          if (selectedUser != null) const SizedBox(height: 10),
                          Container(
                            height: 240,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: filteredUsers.isEmpty
                                ? const Center(
                                    child: Text(
                                      'لا توجد نتائج مطابقة للاسم أو البريد',
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filteredUsers.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final user = filteredUsers[index];
                                      final selected =
                                          selectedUser?.id == user.id;
                                      return ListTile(
                                        selected: selected,
                                        selectedTileColor: const Color(
                                          0xFFEAF7EF,
                                        ),
                                        leading: Icon(
                                          selected
                                              ? Icons.check_circle
                                              : Icons.person_outline,
                                          color: selected
                                              ? _kPrimaryGreen
                                              : const Color(0xFF64748B),
                                        ),
                                        title: Text(
                                          user.name,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          user.email.isEmpty
                                              ? 'لا يوجد بريد إلكتروني'
                                              : user.email,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Text(
                                          '#${user.id}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        onTap: () {
                                          setDialogState(() {
                                            selectedUser = user;
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.start,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        bodyController.text.trim().isEmpty) {
                      _showMasterSnack(context, 'أكمل عنوان ونص الإشعار');
                      return;
                    }
                    if (!sendToAll && selectedUser == null) {
                      _showMasterSnack(
                        context,
                        'اختر المستخدم من نتائج البحث أولا',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: Text(canSend ? 'إرسال' : 'أكمل البيانات'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _runMarketingAction(
        entity: 'notification',
        action: 'send',
        successMessage: 'تم إرسال الإشعار',
        data: {
          'title': titleController.text.trim(),
          'body': bodyController.text.trim(),
          'type': 'marketing',
          'target': sendToAll ? 'all' : 'user',
          if (!sendToAll) 'user_id': int.tryParse(selectedUser?.id ?? '') ?? 0,
          'send_push': 1,
        },
      );
    }

    titleController.dispose();
    bodyController.dispose();
    searchController.dispose();
  }

  Map<String, dynamic> _buildMarketingCatalogPayload({
    required String entity,
    required String title,
    required String subtitle,
    required String placement,
    required String metric,
    required String endDate,
    required String imageUrl,
    String videoUrl = '',
    _MarketingCatalogRecord? record,
    String? catalogKey,
  }) {
    if (entity == 'coupon') {
      return {
        'title': title,
        'discount':
            int.tryParse(subtitle.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
        'count': int.tryParse(metric) ?? 100,
        if (endDate.isNotEmpty) 'end_date': endDate,
      };
    }

    if (entity == 'notification') {
      return {
        'title': title,
        'body': subtitle,
        'type': placement.isEmpty ? 'marketing' : placement,
        'target': metric.isEmpty ? 'all' : 'user',
        if (metric.isNotEmpty) 'user_id': int.tryParse(metric) ?? 0,
        'send_push': 1,
      };
    }

    if (entity == 'ad') {
      final effectivePlacement = _marketingCatalogPlacement(
        catalogKey ?? '',
        placement.isEmpty ? 'home' : placement,
      );
      return {
        'title': title,
        'subtitle': subtitle,
        'placement': effectivePlacement,
        'display_seconds': int.tryParse(metric) ?? 8,
        'sort_order': record?.sortOrder ?? 0,
        'target_type': record?.targetType == 'product'
            ? 'product'
            : 'restaurant',
        'target_id': record?.targetId ?? 0,
        if (imageUrl.isNotEmpty) 'image_url': imageUrl,
        'is_active': 1,
      };
    }

    if (entity == 'story') {
      final targetType = placement.isEmpty
          ? (record?.targetType.isNotEmpty == true
                ? record!.targetType
                : 'restaurant')
          : placement;
      final targetId = int.tryParse(metric) ?? record?.targetId ?? 0;
      final mediaType =
          _looksLikeVideoUrl(imageUrl) ||
              record?.mediaType.toLowerCase() == 'video'
          ? 'video'
          : 'image';
      return {
        'title': title,
        'subtitle': subtitle,
        'target_type': targetType == 'product' ? 'product' : 'restaurant',
        'target_id': targetId,
        'vendor_id': targetType == 'product'
            ? (record?.vendorId ?? 0)
            : targetId,
        'sort_order': record?.sortOrder ?? 0,
        if (imageUrl.isNotEmpty && mediaType == 'image') 'image_url': imageUrl,
        if (imageUrl.isNotEmpty && mediaType == 'video') 'video_url': imageUrl,
        if (endDate.isNotEmpty) 'end_date': endDate,
        'media_type': mediaType,
        'is_active': 1,
      };
    }

    if (entity == 'video') {
      final targetType = placement.isEmpty
          ? (record?.targetType.isNotEmpty == true
                ? record!.targetType
                : 'video')
          : placement;
      final targetId = int.tryParse(metric) ?? record?.targetId ?? 0;
      final inputUrl = videoUrl.trim();
      final thumbnailUrl = imageUrl.trim();
      final isVideoInput = _looksLikeVideoUrl(inputUrl);
      return {
        'title': title,
        'subtitle': subtitle,
        'target_type': targetType == 'product' || targetType == 'restaurant'
            ? targetType
            : '',
        'target_id': targetId,
        'product_id': targetType == 'product' ? targetId : 0,
        if (inputUrl.isNotEmpty && isVideoInput) 'video_url': inputUrl,
        if (thumbnailUrl.isNotEmpty) 'video_thumbnail': thumbnailUrl,
        'is_active': 1,
      };
    }

    if (entity == 'category') {
      return {
        'title': title,
        'subtitle': subtitle.isEmpty ? title : subtitle,
        'vendor_id': int.tryParse(metric) ?? record?.vendorId ?? 0,
        if (imageUrl.isNotEmpty) 'image_url': imageUrl,
        'is_active': 1,
      };
    }

    return {
      'title': title,
      'subtitle': subtitle,
      'placement': placement,
      'sort_order': int.tryParse(metric) ?? record?.sortOrder ?? 0,
      if (imageUrl.isNotEmpty) 'image_url': imageUrl,
      'is_active': 1,
    };
  }

  Future<void> _toggleMarketingCatalog(
    String key,
    _MarketingCatalogRecord record,
  ) async {
    final entity = _marketingCatalogEntity(key);
    if (entity.isEmpty) {
      _showMasterSnack(context, 'هذا القسم للعرض من البيانات الحية فقط');
      return;
    }
    final active = _masterStatusIsActive(record.status);
    await _runMarketingAction(
      entity: entity,
      action: active ? 'disable' : 'activate',
      id: record.id,
      successMessage: active ? 'تم إيقاف العنصر' : 'تم تفعيل العنصر',
    );
  }

  Future<void> _deleteMarketingCatalog(
    String key,
    _MarketingCatalogRecord record,
  ) async {
    final entity = _marketingCatalogEntity(key);
    if (entity.isEmpty) {
      _showMasterSnack(context, 'هذا القسم للعرض من البيانات الحية فقط');
      return;
    }
    await _runMarketingAction(
      entity: entity,
      action: 'delete',
      id: record.id,
      successMessage: 'تم تعطيل العنصر بأمان',
    );
  }
}

class _MarketingOfferRecord {
  const _MarketingOfferRecord({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.goal,
    required this.startDate,
    required this.endDate,
    required this.views,
    required this.clicks,
    required this.orders,
    required this.status,
    required this.badgeText,
    required this.badgeColor,
    required this.targetType,
    required this.targetId,
    required this.placement,
    required this.displaySeconds,
  });

  final int id;
  final String name;
  final String typeLabel;
  final String goal;
  final String startDate;
  final String endDate;
  final int views;
  final int clicks;
  final int orders;
  final String status;
  final String badgeText;
  final Color badgeColor;
  final String targetType;
  final int targetId;
  final String placement;
  final int displaySeconds;
}

class _MarketingLiveBundle {
  const _MarketingLiveBundle({
    required this.offers,
    required this.catalogs,
    required this.couponCount,
  });

  final List<_MarketingOfferRecord> offers;
  final Map<String, List<_MarketingCatalogRecord>> catalogs;
  final int couponCount;
}

class _MarketingTargetChoice {
  const _MarketingTargetChoice({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  final int id;
  final String title;
  final String subtitle;

  String get label {
    final cleanTitle = title.trim().isEmpty ? '#$id' : title.trim();
    final cleanSubtitle = subtitle.trim();
    if (cleanSubtitle.isEmpty || cleanSubtitle == cleanTitle) {
      return '$cleanTitle  #$id';
    }
    return '$cleanTitle - $cleanSubtitle  #$id';
  }
}

bool _masterStatusIsActive(String status) {
  final value = status.toLowerCase();
  return value.contains('active') ||
      value.contains('enabled') ||
      value.contains('نشط') ||
      value.contains('مفعل') ||
      value.contains('نشط') ||
      value.contains('نشط');
}

bool _couponIsValid(String expireDate) {
  if (expireDate.trim().isEmpty) {
    return true;
  }
  final parsed = DateTime.tryParse(expireDate);
  if (parsed == null) {
    return true;
  }
  return parsed.isAfter(DateTime.now());
}

String _couponStatusLabel(bool active) {
  return active ? 'نشط' : 'متوقف';
}

final Set<String> _registeredMarketingVideoViews = <String>{};

bool _marketingLooksLikeVideoUrl(String value) {
  final lower = value.trim().toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.m3u8') ||
      lower.contains('/video/');
}

class _MarketingCatalogRecord {
  const _MarketingCatalogRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.placement,
    required this.metricLabel,
    required this.metricValue,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    this.videoUrl = '',
    required this.accent,
    this.targetType = '',
    this.targetId = 0,
    this.vendorId = 0,
    this.sortOrder = 0,
    this.mediaType = '',
  });

  final int id;
  final String title;
  final String subtitle;
  final String typeLabel;
  final String placement;
  final String metricLabel;
  final String metricValue;
  final String status;
  final String startDate;
  final String endDate;
  final String imageUrl;
  final String videoUrl;
  final Color accent;
  final String targetType;
  final int targetId;
  final int vendorId;
  final int sortOrder;
  final String mediaType;
}

String _marketingAssetUrl(String value) {
  final raw = value.trim();
  if (raw.isEmpty || raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  var clean = raw.replaceAll('\\', '/');
  clean = clean.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('roaq/')) {
    clean = clean.substring('roaq/'.length);
  }
  if (!clean.contains('/')) {
    clean = 'ads/uploud/img/$clean';
  }
  return 'https://savir-technology.online/roaqv2/$clean';
}

List<_MarketingCatalogRecord> _buildMarketingCatalogFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    return _MarketingCatalogRecord(
      id: _toInt(row['id']),
      title: _normalizeUtf8Text(_firstText([row['title'], '#${row['id']}'])),
      subtitle: _normalizeUtf8Text(_firstText([row['subtitle'], ''])),
      typeLabel: _normalizeUtf8Text(_firstText([row['type_label'], '-'])),
      placement: _normalizeUtf8Text(_firstText([row['placement'], '-'])),
      metricLabel: _normalizeUtf8Text(_firstText([row['metric_label'], '-'])),
      metricValue: _formatUserWholeNumber(_toDouble(row['metric_value'])),
      status: _normalizeUtf8Text(_firstText([row['status'], '-'])),
      startDate: _firstText([row['start_date'], '-']),
      endDate: _firstText([row['end_date'], row['start_date'], '-']),
      imageUrl: _firstText([row['image_url'], '']),
      videoUrl: _firstText([row['video_url'], '']),
      accent: _hexToColor(
        _firstText([row['accent_hex'], '#16A34A']),
        fallback: const Color(0xFF16A34A),
      ),
      targetType: _firstText([row['target_type'], row['placement'], '']),
      targetId: _toInt(row['target_id']),
      vendorId: _toInt(row['vendor_id']),
      sortOrder: _toInt(row['sort_order'] ?? row['metric_value']),
      mediaType: _firstText([row['media_type'], row['type_label'], '']),
    );
  }).toList();
}

List<_MarketingOfferRecord> _buildMarketingOffersFromRaw(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    final typeLabel = _normalizeUtf8Text(
      _firstText([row['type_label'], 'عرض']),
    );
    final status = _normalizeUtf8Text(_firstText([row['status'], 'نشط']));
    final targetType = (row['target_type'] ?? '').toString().toLowerCase();
    final badgeText = _firstText([
      row['badge_text'],
      targetType == 'product' ? 'منتج' : 'مطعم',
    ]);

    Color badgeColor;
    switch (status) {
      case 'نشط':
        badgeColor = const Color(0xFF16A34A);
        break;
      case 'متوقف':
        badgeColor = const Color(0xFFEF4444);
        break;
      default:
        badgeColor = const Color(0xFFF97316);
    }

    return _MarketingOfferRecord(
      id: _toInt(row['offer_id'] ?? row['id']),
      name: _normalizeUtf8Text(_firstText([row['name'], 'عرض تسويقي'])),
      typeLabel: typeLabel,
      goal: _normalizeUtf8Text(_firstText([row['goal'], 'حملة تسويقية'])),
      startDate: _firstText([row['start_date'], '-']),
      endDate: _firstText([row['end_date'], row['updated_at'], '-']),
      views: _toInt(row['views']),
      clicks: _toInt(row['clicks']),
      orders: _toInt(row['orders']),
      status: status,
      badgeText: _normalizeUtf8Text(badgeText),
      badgeColor: badgeColor,
      targetType: targetType.isEmpty ? 'restaurant' : targetType,
      targetId: _toInt(row['target_id']),
      placement: _firstText([row['placement'], 'home']),
      displaySeconds: _toInt(row['display_seconds'], 8),
    );
  }).toList();
}

List<_OperationsStatCardData> _buildMarketingLiveStatCards({
  required List<_MarketingOfferRecord> offers,
  required int couponCount,
}) {
  final totalViews = offers.fold<int>(0, (sum, offer) => sum + offer.views);
  final totalClicks = offers.fold<int>(0, (sum, offer) => sum + offer.clicks);
  final totalOrders = offers.fold<int>(0, (sum, offer) => sum + offer.orders);
  final activeOffers = offers
      .where((offer) => _masterStatusIsActive(offer.status))
      .length;
  final clickRate = totalViews == 0 ? 0 : (totalClicks / totalViews) * 100;
  final orderRate = totalClicks == 0 ? 0 : (totalOrders / totalClicks) * 100;

  return [
    _OperationsStatCardData(
      title: 'إجمالي العروض',
      value: '${offers.length}',
      icon: Icons.local_offer_outlined,
      accent: const Color(0xFF22C55E),
      background: const Color(0xFFEAF7EE),
      detailLine: 'عروض مسجلة',
      trendLabel: '$activeOffers',
      trendCaption: 'نشط الآن',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'إجمالي الكوبونات',
      value: '$couponCount',
      icon: Icons.confirmation_number_outlined,
      accent: const Color(0xFF22C55E),
      background: const Color(0xFFEAF7EE),
      detailLine: 'من قاعدة البيانات',
      trendLabel: '$couponCount',
      trendCaption: 'كوبون',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'إجمالي المشاهدات',
      value: _formatUserWholeNumber(totalViews.toDouble()),
      icon: Icons.visibility_outlined,
      accent: const Color(0xFF60A5FA),
      background: const Color(0xFFEAF3FF),
      detailLine: 'مستخرجة من الحملات',
      trendLabel: '${offers.length}',
      trendCaption: 'حملة',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'معدل الاستخدام',
      value: '${orderRate.toStringAsFixed(2)}%',
      icon: Icons.auto_graph_rounded,
      accent: const Color(0xFFF4B000),
      background: const Color(0xFFFFF3DF),
      detailLine: 'تحويل من نقرات لطلبات',
      trendLabel: '${clickRate.toStringAsFixed(2)}%',
      trendCaption: 'CTR',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'النقرات على العروض',
      value: _formatUserWholeNumber(totalClicks.toDouble()),
      icon: Icons.ads_click_outlined,
      accent: const Color(0xFF22C55E),
      background: const Color(0xFFEAF7EE),
      detailLine: 'من الحملات الحالية',
      trendLabel: '${clickRate.toStringAsFixed(2)}%',
      trendCaption: 'نسبة النقر',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'طلبات من الحملات',
      value: _formatUserWholeNumber(totalOrders.toDouble()),
      icon: Icons.shopping_cart_outlined,
      accent: const Color(0xFF60A5FA),
      background: const Color(0xFFEAF3FF),
      detailLine: 'طلبات مرتبطة بالعروض',
      trendLabel: '${orderRate.toStringAsFixed(2)}%',
      trendCaption: 'معدل التحويل',
      trendPositive: true,
    ),
  ];
}

String _marketingDisplayTitle(String key) {
  switch (key) {
    case 'offers':
      return 'العروض';
    case 'coupons':
      return 'الكوبونات';
    case 'slider_primary':
      return 'السلايدر الأول';
    case 'slider_secondary':
      return 'السلايدر الثاني';
    case 'sliders':
      return 'السلايدر الأول';
    case 'stories':
      return 'Stories / الفيديوهات';
    case 'featured':
      return 'الأقسام المميزة';
    default:
      return 'العروض';
  }
}

String _marketingTabLabel(String key) {
  switch (key) {
    case 'offers':
      return 'العروض';
    case 'coupons':
      return 'الكوبونات';
    case 'slider_primary':
      return 'السلايدر الأول';
    case 'slider_secondary':
      return 'السلايدر الثاني';
    case 'sliders':
      return 'السلايدر الأول';
    case 'stories':
      return 'Stories';
    case 'featured':
      return 'الأقسام المميزة';
    default:
      return key;
  }
}

List<(String, String, IconData)> _marketingVisibleTabs() {
  return const [
    ('offers', 'العروض', Icons.local_offer_outlined),
    ('coupons', 'الكوبونات', Icons.confirmation_number_outlined),
    ('slider_primary', 'السلايدر الأول', Icons.view_carousel_outlined),
    ('slider_secondary', 'السلايدر الثاني', Icons.view_carousel_outlined),
    ('stories', 'Stories / الفيديوهات', Icons.play_circle_outline),
    ('featured', 'الأقسام المميزة', Icons.star_outline_rounded),
  ];
}

String _normalizeMarketingSubPage(String key) {
  switch (key) {
    case 'offers':
    case 'coupons':
    case 'stories':
    case 'featured':
      return key;
    case 'sliders':
    case 'slider_primary':
    case 'slider_home':
      return 'slider_primary';
    case 'slider_secondary':
    case 'slider_home_middle':
      return 'slider_secondary';
    default:
      return 'offers';
  }
}

class _MarketingEditorHeader extends StatelessWidget {
  const _MarketingEditorHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F8F4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kPrimaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: _kPrimaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF12231A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w600,
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

class _MarketingVideoUploadPreview extends StatelessWidget {
  const _MarketingVideoUploadPreview({
    required this.videoUrl,
    required this.fileName,
    required this.isUploading,
    required this.onUpload,
  });

  final String videoUrl;
  final String? fileName;
  final bool isUploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final hasVideo = _marketingLooksLikeVideoUrl(videoUrl);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasVideo
                  ? _MarketingVideoPreview(videoUrl: videoUrl)
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'معاينة الفيديو',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF12231A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fileName ??
                      (hasVideo
                          ? 'فيديو جاهز للمعاينة'
                          : 'لم يتم اختيار فيديو بعد'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(isUploading ? 'جار الرفع' : 'رفع من الجهاز'),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketingAudienceCard extends StatelessWidget {
  const _MarketingAudienceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF7EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kPrimaryGreen : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _kPrimaryGreen : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kPrimaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _kPrimaryGreen, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF12231A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      height: 1.35,
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

class _SelectedMarketingUser extends StatelessWidget {
  const _SelectedMarketingUser({required this.user});

  final _UserRecord user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimaryGreen.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _kPrimaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${user.name}  •  ${user.email.isEmpty ? 'بدون بريد' : user.email}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF12231A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '#${user.id}',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketingActionsMenu extends StatelessWidget {
  const _MarketingActionsMenu({
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PopupMenuButton<String>(
        tooltip: 'الإجراءات',
        icon: const Icon(Icons.more_horiz_rounded, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
              break;
            case 'toggle':
              onToggle();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: _MarketingActionMenuItem(
              icon: Icons.edit_outlined,
              label: 'تعديل',
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: _MarketingActionMenuItem(
              icon: isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: isActive ? 'إيقاف' : 'تفعيل',
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: _MarketingActionMenuItem(
              icon: Icons.delete_outline,
              label: 'حذف آمن',
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketingActionMenuItem extends StatelessWidget {
  const _MarketingActionMenuItem({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF334155),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MarketingTabsBar extends StatelessWidget {
  const _MarketingTabsBar({
    required this.activeSubPage,
    required this.onTabTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onTabTap;

  @override
  Widget build(BuildContext context) {
    final tabs = _marketingVisibleTabs();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () => onTabTap(tabs[i].$1),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: activeSubPage == tabs[i].$1
                            ? _kPrimaryGreen
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        tabs[i].$3,
                        size: 16,
                        color: activeSubPage == tabs[i].$1
                            ? _kPrimaryGreen
                            : const Color(0xFF6F7680),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tabs[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: activeSubPage == tabs[i].$1
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: activeSubPage == tabs[i].$1
                                ? _kPrimaryGreen
                                : const Color(0xFF6F7680),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _MarketingOffersWorkspace extends StatelessWidget {
  const _MarketingOffersWorkspace({
    required this.offers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
    required this.onFilter,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onAddCoupon,
  });

  final List<_MarketingOfferRecord> offers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;
  final VoidCallback onFilter;
  final ValueChanged<_MarketingOfferRecord> onEdit;
  final ValueChanged<_MarketingOfferRecord> onToggle;
  final ValueChanged<_MarketingOfferRecord> onDelete;
  final VoidCallback onAddCoupon;

  @override
  Widget build(BuildContext context) {
    final visibleOffers = offers;
    if (visibleOffers.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'قائمة العروض',
        description:
            'لا توجد عروض حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
        icon: Icons.local_offer_outlined,
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      // This workspace is inside the page's vertical scroll view. Stretching
      // children across an unbounded vertical axis can produce infinite
      // height constraints and collapse the whole render tree.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'قائمة العروض',
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('عرض جديد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(150, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: onFilter,
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('تصفية'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 180,
                        child: OutlinedButton.icon(
                          onPressed: () => _showMarketingOfferReport(
                            context,
                            visibleOffers[selectedIndex],
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          label: const Text('آخر 30 يوم'),
                        ),
                      ),
                    ],
                  ),
                ),
                const _RestaurantTableHeader(
                  columns: [
                    (12, 'العرض'),
                    (10, 'النوع'),
                    (10, 'الهدف'),
                    (12, 'فترة العرض'),
                    (10, 'المشاهدات'),
                    (10, 'النقرات'),
                    (8, 'الطلبات'),
                    (10, 'الحالة'),
                    (8, 'الإجراءات'),
                  ],
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleOffers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = visibleOffers[index];
                    final isSelected = index == selectedIndex;
                    return InkWell(
                      onTap: () => onSelected(index),
                      child: Container(
                        height: 72,
                        color: isSelected
                            ? const Color(0xFFF1F8F4)
                            : Colors.transparent,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _OrdersTableCell(
                              flex: 12,
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: item.badgeColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.badgeText,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: _statusPill(item.typeLabel),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                item.goal,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 12,
                              child: _OrdersTwoLine(
                                title: item.startDate,
                                subtitle: item.endDate,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                '${item.views}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                '${item.clicks}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 8,
                              child: Text(
                                '${item.orders}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: _statusPill(item.status),
                            ),
                            _OrdersTableCell(
                              flex: 8,
                              child: _MarketingActionsMenu(
                                isActive: _masterStatusIsActive(item.status),
                                onEdit: () => onEdit(item),
                                onToggle: () => onToggle(item),
                                onDelete: () => onDelete(item),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 352,
          child: _MarketingOfferSummaryPanel(
            offers: offers,
            selectedIndex: selectedIndex,
            onAddOffer: onAdd,
            onAddCoupon: onAddCoupon,
          ),
        ),
      ],
    );
  }
}

void _showMarketingOfferReport(
  BuildContext context,
  _MarketingOfferRecord offer,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تقرير الحملة', textAlign: TextAlign.right),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrdersMetricLine(label: 'العرض', value: offer.name),
              _OrdersMetricLine(label: 'النوع', value: offer.typeLabel),
              _OrdersMetricLine(label: 'الهدف', value: offer.goal),
              _OrdersMetricLine(label: 'البداية', value: offer.startDate),
              _OrdersMetricLine(label: 'النهاية', value: offer.endDate),
              _OrdersMetricLine(label: 'المشاهدات', value: '${offer.views}'),
              _OrdersMetricLine(label: 'النقرات', value: '${offer.clicks}'),
              _OrdersMetricLine(label: 'الطلبات', value: '${offer.orders}'),
              _OrdersMetricLine(label: 'الحالة', value: offer.status),
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

class _MarketingOfferSummaryPanel extends StatelessWidget {
  const _MarketingOfferSummaryPanel({
    required this.offers,
    required this.selectedIndex,
    required this.onAddOffer,
    required this.onAddCoupon,
  });

  final List<_MarketingOfferRecord> offers;
  final int selectedIndex;
  final VoidCallback onAddOffer;
  final VoidCallback onAddCoupon;

  @override
  Widget build(BuildContext context) {
    final selected = offers[selectedIndex];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RestaurantShellCard(
            title: 'العروض',
            expandChild: false,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: _OrdersChannelsDonut(
                      channels: const [
                        _OrdersChannelData(
                          label: 'العروض',
                          value: 5606,
                          percent: 45,
                        ),
                        _OrdersChannelData(
                          label: 'الكوبونات',
                          value: 3743,
                          percent: 30,
                        ),
                        _OrdersChannelData(
                          label: 'المناسبات',
                          value: 1869,
                          percent: 15,
                        ),
                        _OrdersChannelData(
                          label: 'الأقسام المميزة',
                          value: 1240,
                          percent: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'العروض الأعلى أداء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in [
                    ('خصم 25% على جميع الطلبات', '19.6%', '2,450 طلب'),
                    (
                      'توصيل مجاني للطلبات فوق 50 ${MasterCurrency.symbol}',
                      '14.8%',
                      '1,850 طلب',
                    ),
                    ('عروض نهاية الأسبوع', '12.2%', '1,520 طلب'),
                    ('اشتر 1 واحصل 1 مجاناً', '10.5%', '1,310 طلب'),
                    ('خصم 20% للعملاء الجدد', '9.0%', '1,125 طلب'),
                  ])
                    _OrdersMetricLine(
                      label: item.$1,
                      value: '${item.$2} • ${item.$3}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _RestaurantShellCard(
            title: 'أدوات سريعة',
            expandChild: false,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OrdersMetricLine(
                    label: 'العرض المحدد',
                    value: selected.name,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAddOffer,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('عرض جديد'),
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
                          onPressed: onAddCoupon,
                          icon: const Icon(Icons.confirmation_number_outlined),
                          label: const Text('كوبون جديد'),
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
                              _showMarketingOfferReport(context, selected),
                          icon: const Icon(Icons.bar_chart_outlined),
                          label: const Text('تقرير الحملات'),
                        ),
                      ),
                    ],
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

class _MarketingEmptyCatalogWorkspace extends StatelessWidget {
  const _MarketingEmptyCatalogWorkspace({
    required this.title,
    required this.onAdd,
    required this.onFilter,
  });

  final String title;
  final VoidCallback onAdd;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: title,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  size: 34,
                  color: _kPrimaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لا توجد بيانات مطابقة حاليا. يمكنك إنشاء عنصر جديد أو تعديل التصفية.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667085), height: 1.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryGreen,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onFilter,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('تصفية'),
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

class _MarketingCatalogWorkspace extends StatelessWidget {
  const _MarketingCatalogWorkspace({
    required this.title,
    required this.records,
    required this.selectedIndex,
    required this.onSelected,
    required this.onFilter,
    required this.onAdd,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final String title;
  final List<_MarketingCatalogRecord> records;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onFilter;
  final VoidCallback onAdd;
  final ValueChanged<_MarketingCatalogRecord> onEdit;
  final ValueChanged<_MarketingCatalogRecord> onToggle;
  final ValueChanged<_MarketingCatalogRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final visibleRecords = records;
    if (visibleRecords.isEmpty) {
      return _MarketingEmptyCatalogWorkspace(
        title: title,
        onAdd: onAdd,
        onFilter: onFilter,
      );
    }

    final safeIndex = selectedIndex.clamp(0, visibleRecords.length - 1);
    final selected = visibleRecords[safeIndex];

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: title,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة جديدة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: onFilter,
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('تصفية'),
                      ),
                      const Spacer(),
                      Text(
                        'إجمالي ${visibleRecords.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4E5660),
                        ),
                      ),
                    ],
                  ),
                ),
                const _RestaurantTableHeader(
                  columns: [
                    (18, 'العنوان'),
                    (10, 'النوع'),
                    (10, 'الموضع'),
                    (10, 'المؤشر'),
                    (10, 'القيمة'),
                    (10, 'البداية'),
                    (10, 'النهاية'),
                    (10, 'الحالة'),
                    (8, 'الإجراءات'),
                  ],
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleRecords.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = visibleRecords[index];
                    final isSelected = index == safeIndex;
                    return InkWell(
                      onTap: () => onSelected(index),
                      child: Container(
                        height: 72,
                        color: isSelected
                            ? const Color(0xFFF1F8F4)
                            : Colors.transparent,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _OrdersTableCell(
                              flex: 18,
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  _MarketingCatalogThumb(item: item),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _OrdersTwoLine(
                                      title: item.title,
                                      subtitle: item.subtitle.isEmpty
                                          ? '#${item.id}'
                                          : item.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: _statusPill(item.typeLabel),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                item.placement,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                item.metricLabel,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                item.metricValue,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                item.startDate,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                item.endDate,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: _statusPill(item.status),
                            ),
                            _OrdersTableCell(
                              flex: 8,
                              child: _MarketingActionsMenu(
                                isActive: _masterStatusIsActive(item.status),
                                onEdit: () => onEdit(item),
                                onToggle: () => onToggle(item),
                                onDelete: () => onDelete(item),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 352,
          child: _MarketingCatalogDetailsPanel(
            record: selected,
            onEdit: () => onEdit(selected),
          ),
        ),
      ],
    );
  }
}

class _MarketingCatalogThumb extends StatelessWidget {
  const _MarketingCatalogThumb({required this.item});

  final _MarketingCatalogRecord item;

  @override
  Widget build(BuildContext context) {
    if (item.videoUrl.isNotEmpty ||
        _marketingLooksLikeVideoUrl(item.imageUrl)) {
      return _fallbackThumb(icon: Icons.play_circle_outline);
    }
    if (item.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          Uri.encodeFull(_marketingAssetUrl(item.imageUrl)),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return _fallbackThumb(icon: Icons.image_outlined);
          },
          errorBuilder: (_, _, _) => _fallbackThumb(),
        ),
      );
    }
    return _fallbackThumb();
  }

  Widget _fallbackThumb({IconData icon = Icons.campaign_outlined}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: item.accent),
    );
  }
}

class _MarketingVideoPreview extends StatelessWidget {
  const _MarketingVideoPreview({required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    final src = Uri.encodeFull(_marketingVideoUrl(videoUrl));
    final viewType = 'marketing-video-${src.hashCode.abs()}';
    if (!_registeredMarketingVideoViews.contains(viewType)) {
      _registeredMarketingVideoViews.add(viewType);
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        return html.VideoElement()
          ..src = src
          ..controls = true
          ..preload = 'metadata'
          ..setAttribute('playsinline', 'true')
          ..setAttribute('webkit-playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block'
          ..style.border = '0'
          ..style.borderRadius = '16px'
          ..style.backgroundColor = '#0F172A'
          ..style.objectFit = 'cover';
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}

void _openMarketingVideoUrl(String videoUrl) {
  final url = _marketingVideoUrl(videoUrl);
  if (url.isEmpty) {
    return;
  }
  html.window.open(Uri.encodeFull(url), '_blank');
}

String _marketingVideoUrl(String value) {
  final raw = value.trim();
  if (raw.isEmpty || raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  var clean = raw.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('roaq/')) {
    clean = clean.substring('roaq/'.length);
  }
  if (!clean.contains('/')) {
    clean = 'uploud/video/$clean';
  }
  return 'https://savir-technology.online/roaqv2/$clean';
}

class _MarketingImageFallback extends StatelessWidget {
  const _MarketingImageFallback({required this.record});

  final _MarketingCatalogRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: record.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: record.accent.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: record.accent,
          size: 34,
        ),
      ),
    );
  }
}

class _MarketingCatalogDetailsPanel extends StatelessWidget {
  const _MarketingCatalogDetailsPanel({
    required this.record,
    required this.onEdit,
  });

  final _MarketingCatalogRecord record;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final previewVideoUrl = record.videoUrl.isNotEmpty
        ? record.videoUrl
        : _marketingLooksLikeVideoUrl(record.imageUrl)
        ? record.imageUrl
        : '';
    return _RestaurantShellCard(
      title: 'تفاصيل ${record.typeLabel}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: previewVideoUrl.isNotEmpty ? double.infinity : 140,
                height: previewVideoUrl.isNotEmpty ? 220 : 100,
                child: previewVideoUrl.isNotEmpty
                    ? _MarketingVideoPreview(videoUrl: previewVideoUrl)
                    : record.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          Uri.encodeFull(_marketingAssetUrl(record.imageUrl)),
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              return child;
                            }
                            return _MarketingImageFallback(record: record);
                          },
                          errorBuilder: (_, _, _) =>
                              _MarketingImageFallback(record: record),
                        ),
                      )
                    : _MarketingCatalogThumb(item: record),
              ),
            ),
            if (previewVideoUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openMarketingVideoUrl(previewVideoUrl),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('فتح الفيديو'),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              record.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (record.subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                record.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6F7680)),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _detailMetricCard(record.metricLabel, record.metricValue),
                _detailMetricCard('الحالة', record.status),
              ],
            ),
            const SizedBox(height: 16),
            _detailLine(Icons.category_outlined, 'النوع', record.typeLabel),
            _detailLine(Icons.place_outlined, 'الموضع', record.placement),
            _detailLine(
              Icons.calendar_today_outlined,
              'البداية',
              record.startDate,
            ),
            _detailLine(
              Icons.event_available_outlined,
              'النهاية',
              record.endDate,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketingRightSidebar extends StatelessWidget {
  const _MarketingRightSidebar({
    required this.activeSubPage,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onOrdersTap,
    required this.onLogisticsTap,
    required this.onRestaurantsTap,
    required this.onUsersTap,
    required this.onFinanceTap,
    required this.onSupportTap,
    required this.onCollapse,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLogisticsTap;
  final VoidCallback onRestaurantsTap;
  final VoidCallback onUsersTap;
  final VoidCallback onFinanceTap;
  final VoidCallback onSupportTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final submenu = _marketingVisibleTabs();
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
                selected: false,
                onTap: onFinanceTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'التسويق والنمو',
                icon: Icons.campaign_outlined,
                selected: true,
                onTap: () => onSubPageTap('offers'),
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
                    for (var i = 0; i < submenu.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final item = submenu[i];
                          final selected = activeSubPage == item.$1;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onSubPageTap(item.$1),
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
                                    item.$3,
                                    size: 16,
                                    color: selected
                                        ? _kPrimaryGreen
                                        : const Color(0xFF4E5660),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.$2,
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
                      if (i != submenu.length - 1) const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final item in const [
                // 'الجودة وخدمة العملاء' removed per user request
                _OperationsSidebarTileData(
                  label: 'التقارير والتحليلات',
                  icon: Icons.query_stats_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'الإعلانات / السلايدر',
                  icon: Icons.view_carousel_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'الإدارة والصلاحيات',
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ]) ...[
                _OperationsSidebarMenuItem(
                  data: item,
                  onTap: () {
                    if (item.icon == Icons.verified_user_outlined) {
                      onSupportTap();
                    } else if (item.icon == Icons.query_stats_outlined) {
                      onSubPageTap('offers');
                    } else if (item.icon == Icons.view_carousel_outlined) {
                      onSubPageTap('sliders');
                    } else if (item.icon ==
                        Icons.admin_panel_settings_outlined) {
                      onOperationsTap();
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
}
