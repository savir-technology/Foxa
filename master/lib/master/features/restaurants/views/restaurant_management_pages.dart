// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterRestaurantsPage extends StatefulWidget {
  const MasterRestaurantsPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.initialSubPage = 'all',
    this.initialVendorType = 'restaurant',
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final String initialSubPage;
  final String initialVendorType;
  final bool unifiedFrame;

  @override
  State<MasterRestaurantsPage> createState() => _MasterRestaurantsPageState();
}

class _MasterRestaurantsPageState extends State<MasterRestaurantsPage> {
  late String _activeSubPage;
  bool _showNavigationSidebar = true;
  final TextEditingController _searchController = TextEditingController();
  int _selectedRestaurantIndex = 0;
  int _selectedMenuSectionIndex = 0;
  int _selectedCategoryIndex = 0;
  int _selectedProductIndex = 0;
  int _selectedToppingIndex = 0;
  int _selectedOfferIndex = 0;
  int _selectedCouponIndex = 0;
  bool _restaurantActionRunning = false;
  String _restaurantPrimaryFilter = 'all';
  String _restaurantStatusFilter = 'all';
  String _restaurantGroupFilter = 'all';
  String _vendorTypeFilter = 'restaurant';
  late Future<List<Map<String, dynamic>>> _storeSpecialtiesFuture;

  late Future<_RestaurantManagementSeed> _restaurantSeedFuture;

  @override
  void initState() {
    super.initState();
    _activeSubPage = widget.initialSubPage;
    _vendorTypeFilter = widget.initialVendorType;
    _restaurantSeedFuture = _loadRestaurantSeed();
    _storeSpecialtiesFuture = widget.api._fetchMasterStoreSpecialties(
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
      return _buildUnifiedRestaurantsFrame(context);
    }
    final serverNow = widget.serverNow ?? DateTime.now();
    return FutureBuilder<_RestaurantManagementSeed>(
      future: _restaurantSeedFuture,
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
                        'تعذر تحميل بيانات المطاعم',
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
                            _restaurantSeedFuture = _loadRestaurantSeed();
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

        final effectiveSeed =
            snapshot.data ?? _RestaurantManagementSeed.empty();
        final visibleSeed = _filterRestaurantSeed(effectiveSeed);
        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
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
                                onReload: _handleReload,
                                showInsightsSidebar: true,
                                showNavigationSidebar: _showNavigationSidebar,
                                onToggleInsightsSidebar: () {},
                                onToggleNavigationSidebar: () {
                                  setState(() {
                                    _showNavigationSidebar =
                                        !_showNavigationSidebar;
                                  });
                                },
                                title: _restaurantPageTitle(_activeSubPage),
                                subtitle: _restaurantPageSubtitle(
                                  _activeSubPage,
                                ),
                                icon: _restaurantPageIcon(_activeSubPage),
                              ),
                              const SizedBox(height: 8),
                              _OrdersStatsStrip(
                                cards: _buildRestaurantStatCards(
                                  visibleSeed,
                                  _activeSubPage,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _RestaurantFiltersBar(
                                activeSubPage: _activeSubPage,
                                searchController: _searchController,
                                onSubmitted: _handleReload,
                                primaryFilter: _restaurantPrimaryFilter,
                                statusFilter: _restaurantStatusFilter,
                                groupFilter: _restaurantGroupFilter,
                                vendorTypeFilter: _vendorTypeFilter,
                                onPrimaryChanged: (value) {
                                  setState(
                                    () => _restaurantPrimaryFilter = value,
                                  );
                                },
                                onStatusChanged: (value) {
                                  setState(
                                    () => _restaurantStatusFilter = value,
                                  );
                                },
                                onGroupChanged: (value) {
                                  setState(
                                    () => _restaurantGroupFilter = value,
                                  );
                                },
                                onVendorTypeChanged: (value) {
                                  setState(() => _vendorTypeFilter = value);
                                },
                                onAdd: () =>
                                    _activeSubPage == 'store_specialties'
                                    ? _editStoreSpecialty()
                                    : _showRestaurantEntityEditor(
                                        title: _restaurantAddButtonLabel(
                                          _activeSubPage,
                                        ),
                                        entity: _restaurantEntityForSubPage(
                                          _activeSubPage,
                                        ),
                                        initialVendorType:
                                            widget.initialVendorType,
                                      ),
                                onAdvancedFilter:
                                    _showAdvancedRestaurantFilters,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildRestaurantWorkspace(
                                  serverNow,
                                  visibleSeed,
                                  snapshot,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: sidebarWidth,
                            child: _RestaurantsRightSidebar(
                              activeSubPage: _activeSubPage,
                              onSubPageTap: (value) {
                                setState(() => _activeSubPage = value);
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
                              onUsersTap: () => _navigateToMasterSection(
                                context,
                                key: 'users',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onFinanceTap: () {
                                _navigateToMasterSection(
                                  context,
                                  key: 'finance',
                                  session: widget.session,
                                  onLogout: widget.onLogout,
                                  api: widget.api,
                                  serverNow: serverNow,
                                );
                              },
                              onMarketingTap: () {
                                _navigateToMasterSection(
                                  context,
                                  key: 'marketing',
                                  session: widget.session,
                                  onLogout: widget.onLogout,
                                  api: widget.api,
                                  serverNow: serverNow,
                                );
                              },
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

  Widget _buildUnifiedRestaurantsFrame(BuildContext context) {
    final serverNow = widget.serverNow ?? DateTime.now();
    final sidebarItems = _masterFilterSidebarItems(widget.session, [
      _DashboardMenuItemData(
        iconKey: widget.initialVendorType == 'store' ? 'stores' : 'restaurants',
        label: 'إدارة المطاعم والمتاجر',
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
        if (key ==
            (widget.initialVendorType == 'store' ? 'stores' : 'restaurants')) {
          return;
        }
        _navigateToMasterSection(
          context,
          key: key,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
      },
      statusLabel: 'إدارة المطاعم والمتاجر',
      platformTitle: 'المطاعم والمتاجر',
      platformSubtitle: 'إدارة المتاجر والمنتجات والعروض',
      serverNow: serverNow,
      child: FutureBuilder<_RestaurantManagementSeed>(
        future: _restaurantSeedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: _UsersPlaceholderWorkspace(
                title: 'تعذر تحميل بيانات المطاعم والمتاجر',
                description: snapshot.error?.toString() ?? 'حدث خطأ غير متوقع',
                icon: Icons.error_outline_rounded,
              ),
            );
          }
          final seed = _filterRestaurantSeed(snapshot.data!);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final item in const <MapEntry<String, String>>[
                    MapEntry('all', 'المطاعم والمتاجر'),
                    MapEntry('menus', 'المنتجات'),
                    MapEntry('categories', 'الأقسام'),
                    MapEntry('toppings', 'الإضافات'),
                    MapEntry('offers', 'العروض'),
                    MapEntry('coupons', 'الكوبونات'),
                    MapEntry('store_specialties', 'تخصصات المتاجر'),
                  ])
                    ChoiceChip(
                      selected: _activeSubPage == item.key,
                      label: Text(item.value),
                      onSelected: (_) =>
                          setState(() => _activeSubPage = item.key),
                    ),
                  OutlinedButton.icon(
                    onPressed: _showBranchesHoursDialog,
                    icon: const Icon(Icons.schedule_outlined),
                    label: const Text('الفروع وساعات العمل'),
                  ),
                  FilledButton.icon(
                    onPressed: _activeSubPage == 'store_specialties'
                        ? _editStoreSpecialty
                        : () => _showRestaurantEntityEditor(
                            title: _restaurantAddButtonLabel(_activeSubPage),
                            entity: _restaurantEntityForSubPage(_activeSubPage),
                            initialVendorType: widget.initialVendorType,
                          ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OrdersStatsStrip(
                cards: _buildRestaurantStatCards(seed, _activeSubPage),
              ),
              const SizedBox(height: 12),
              _RestaurantFiltersBar(
                activeSubPage: _activeSubPage,
                searchController: _searchController,
                onSubmitted: _handleReload,
                primaryFilter: _restaurantPrimaryFilter,
                statusFilter: _restaurantStatusFilter,
                groupFilter: _restaurantGroupFilter,
                vendorTypeFilter: _vendorTypeFilter,
                onPrimaryChanged: (value) =>
                    setState(() => _restaurantPrimaryFilter = value),
                onStatusChanged: (value) =>
                    setState(() => _restaurantStatusFilter = value),
                onGroupChanged: (value) =>
                    setState(() => _restaurantGroupFilter = value),
                onVendorTypeChanged: (value) =>
                    setState(() => _vendorTypeFilter = value),
                onAdd: _activeSubPage == 'store_specialties'
                    ? _editStoreSpecialty
                    : () => _showRestaurantEntityEditor(
                        title: _restaurantAddButtonLabel(_activeSubPage),
                        entity: _restaurantEntityForSubPage(_activeSubPage),
                        initialVendorType: widget.initialVendorType,
                      ),
                onAdvancedFilter: _showAdvancedRestaurantFilters,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildRestaurantWorkspace(serverNow, seed, snapshot),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBranchesHoursDialog() async {
    try {
      final data = await widget.api._fetchMasterBranchesAndHours(
        widget.session.token,
        vendorType: widget.initialVendorType,
      );
      if (!mounted) return;
      final branches = _asMapList(data['branches']);
      final hours = _asMapList(data['hours']);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            widget.initialVendorType == 'store'
                ? 'فروع المتاجر وساعات العمل'
                : 'فروع المطاعم وساعات العمل',
          ),
          content: SizedBox(
            width: 760,
            height: 520,
            child: ListView(
              children: [
                Text(
                  'الفروع (${branches.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...branches.map(
                  (row) => ListTile(
                    leading: const Icon(Icons.store_mall_directory_outlined),
                    title: Text(
                      (row['branch_name_ar'] ?? row['branch_name_en'] ?? 'فرع')
                          .toString(),
                    ),
                    subtitle: Text(
                      '${row['store_name'] ?? row['vendor_name'] ?? ''} • رسوم التوصيل: ${row['delivery_fee'] ?? 0} ${MasterCurrency.symbol}',
                    ),
                    trailing: Text(
                      (row['is_active'] ?? 0).toString() == '1'
                          ? 'نشط'
                          : 'متوقف',
                    ),
                  ),
                ),
                const Divider(height: 24),
                Text(
                  'ساعات العمل (${hours.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...hours.map(
                  (row) => ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: Text((row['day_key'] ?? '').toString()),
                    subtitle: Text(
                      '${row['opens_at'] ?? '--:--'} - ${row['closes_at'] ?? '--:--'}',
                    ),
                    trailing: Text(
                      (row['is_open'] ?? 0).toString() == '1'
                          ? 'مفتوح'
                          : 'مغلق',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showMasterSnack(context, error.toString());
    }
  }

  void _handleReload() {
    setState(() {
      _restaurantSeedFuture = _loadRestaurantSeed();
    });
  }

  Future<void> _showRestaurantEntityEditor({
    required String title,
    required String entity,
    String mode = 'create',
    int? id,
    String initialName = '',
    String initialSlug = '',
    String initialNotes = '',
    String initialOwner = '',
    String initialEmail = '',
    String initialPhone = '',
    String initialAddress = '',
    String initialLatitude = '',
    String initialLongitude = '',
    String initialStatus = 'نشط',
    String initialNameEn = '',
    String initialDescriptionEn = '',
    String initialImageName = '',
    String initialImageUrl = '',
    String initialStockCount = '',
    String initialCategoryId = '',
    String initialVendorId = '',
    bool initialActive = true,
    String initialPrice = '',
    String initialDiscount = '',
    String initialExpireDate = '',
    String initialMinChoice = '',
    String initialMaxChoice = '',
    String initialRequired = 'اختياري',
    String initialGroupType = 'إضافات',
    String initialVendorType = 'restaurant',
    String initialStoreCategory = '',
    String initialAttributesText = '',
    String? subtitle,
  }) async {
    final seed = await _restaurantSeedFuture;
    final vendorOptions = seed.restaurants;
    final specialtyRows = await _storeSpecialtiesFuture;
    if (!mounted) {
      return;
    }
    final specialtyItems = <String, String>{
      for (final row in specialtyRows.where(
        (row) => _toInt(row['is_active'], 1) == 1,
      ))
        (row['category_key'] ?? '').toString():
            (row['name_ar'] ?? row['category_key'] ?? '').toString(),
    };
    final nameController = TextEditingController(text: initialName);
    final slugController = TextEditingController(text: initialSlug);
    final noteController = TextEditingController(text: initialNotes);
    final ownerController = TextEditingController(text: initialOwner);
    final emailController = TextEditingController(text: initialEmail);
    final phoneController = TextEditingController(text: initialPhone);
    final addressController = TextEditingController(text: initialAddress);
    final latitudeController = TextEditingController(text: initialLatitude);
    final longitudeController = TextEditingController(text: initialLongitude);
    final statusController = TextEditingController(text: initialStatus);
    final nameEnController = TextEditingController(text: initialNameEn);
    final descriptionEnController = TextEditingController(
      text: initialDescriptionEn,
    );
    final imageController = TextEditingController(text: initialImageName);
    final stockController = TextEditingController(text: initialStockCount);
    final stockUnitController = TextEditingController(
      text: initialVendorType == 'store' ? 'piece' : 'piece',
    );
    final stockStepController = TextEditingController(text: '1');
    final categoryController = TextEditingController(text: initialCategoryId);
    final vendorController = TextEditingController(text: initialVendorId);
    final activeController = TextEditingController(
      text: initialActive ? 'نشط' : 'مخفي',
    );
    final minChoiceController = TextEditingController(text: initialMinChoice);
    final maxChoiceController = TextEditingController(text: initialMaxChoice);
    final requiredController = TextEditingController(text: initialRequired);
    final groupTypeController = TextEditingController(text: initialGroupType);
    final priceController = TextEditingController(text: initialPrice);
    final discountController = TextEditingController(text: initialDiscount);
    final expireController = TextEditingController(text: initialExpireDate);
    final vendorTypeController = TextEditingController(text: initialVendorType);
    final storeCategoryController = TextEditingController(
      text: initialStoreCategory,
    );
    final attributesController = TextEditingController(
      text: initialAttributesText,
    );
    var selectedImageLabel = initialImageName;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 24,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            titlePadding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
            contentPadding: const EdgeInsets.fromLTRB(28, 8, 28, 4),
            actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 22),
            title: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    entity == 'restaurant'
                        ? Icons.storefront_rounded
                        : entity == 'product'
                        ? Icons.inventory_2_rounded
                        : entity == 'category'
                        ? Icons.category_rounded
                        : Icons.tune_rounded,
                    color: _kPrimaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10251C),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mode == 'create'
                            ? '\u0625\u0646\u0634\u0627\u0621 \u0633\u062c\u0644 \u062c\u062f\u064a\u062f'
                            : '\u062a\u062d\u062f\u064a\u062b \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0633\u062c\u0644',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718078),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF718078),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 760,
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    isDense: true,
                    filled: true,
                    fillColor: Color(0xFFF8FAF9),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF66756D),
                    ),
                    floatingLabelStyle: TextStyle(
                      fontSize: 13,
                      color: _kPrimaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFE1E9E4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFE1E9E4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: _kPrimaryGreen, width: 1.5),
                    ),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 860,
                    maxHeight: MediaQuery.sizeOf(context).height * .82,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (subtitle != null) ...[
                          Text(
                            subtitle,
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Color(0xFF6F7680)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: nameController,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'الاسم',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (entity == 'restaurant') ...[
                          const SizedBox(height: 10),
                          _masterDropdown(
                            label:
                                '\u0646\u0648\u0639 \u0627\u0644\u0646\u0634\u0627\u0637',
                            value: vendorTypeController.text,
                            items: const {
                              'restaurant': '\u0645\u0637\u0639\u0645',
                              'store': '\u0645\u062a\u062c\u0631',
                            },
                            onChanged: (value) => setDialogState(() {
                              vendorTypeController.text = value;
                              if (value == 'restaurant') {
                                storeCategoryController.clear();
                              }
                            }),
                          ),
                          if (vendorTypeController.text == 'store') ...[
                            const SizedBox(height: 10),
                            _masterDropdown(
                              label:
                                  '\u062a\u062e\u0635\u0635 \u0627\u0644\u0645\u062a\u062c\u0631',
                              value: storeCategoryController.text.isEmpty
                                  ? 'general'
                                  : storeCategoryController.text,
                              items: specialtyItems.isEmpty
                                  ? const {
                                      'general':
                                          '\u0645\u062a\u062c\u0631 \u0639\u0627\u0645',
                                    }
                                  : specialtyItems,
                              onChanged: (value) => setDialogState(
                                () => storeCategoryController.text = value,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextField(
                            controller: slugController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'المعرّف المختصر (Slug)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (entity == 'restaurant' || entity == 'product') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteController,
                            textAlign: TextAlign.right,
                            maxLines: entity == 'product' ? 2 : 3,
                            decoration: InputDecoration(
                              labelText: entity == 'product'
                                  ? 'وصف الإضافة'
                                  : 'ملاحظات',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (entity == 'product') ...[
                          const SizedBox(height: 10),
                          _masterVendorDropdown(
                            vendorController,
                            vendorOptions,
                            setDialogState,
                          ),
                          const SizedBox(height: 10),
                          if (initialImageUrl.isNotEmpty)
                            Container(
                              height: 130,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                initialImageUrl,
                                fit: BoxFit.cover,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.prefer,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 42,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nameEnController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'اسم المنتج بالإنجليزية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descriptionEnController,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'الوصف بالإنجليزية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: imageController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'اسم الصورة أو مسارها',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: stockController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الكمية / المخزون',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: categoryController,
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم التصنيف',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const SizedBox.shrink(),
                        ],
                        if (entity == 'product' &&
                            (vendorOptions.isEmpty ||
                                vendorOptions.any(
                                  (vendor) =>
                                      _restaurantEntityNumericId(
                                            vendor.id,
                                          ).toString() ==
                                          vendorController.text &&
                                      vendor.vendorType == 'store',
                                ))) ...[
                          const SizedBox(height: 10),
                          _masterDropdown(
                            label: 'وحدة المخزون',
                            value: stockUnitController.text,
                            items: const {
                              'piece': 'قطعة',
                              'kg': 'كيلو',
                              'g': 'جرام',
                              'liter': 'لتر',
                              'ml': 'ملليلتر',
                            },
                            onChanged: (value) => setDialogState(
                              () => stockUnitController.text = value,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: stockStepController,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'خطوة الكمية',
                              hintText: 'مثال: 0.5 للكيلو',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: attributesController,
                            textAlign: TextAlign.right,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText:
                                  'Product attributes (one per line: Name: value1, value2)',
                              hintText: 'Color: Red, Blue\nSize: Small, Large',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ] else if (entity == 'product') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'منتجات المطاعم لا تستخدم اللون والمقاس والـ variants العامة. استخدم قسم الإضافات والمكونات الخاص بالمطعم.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Color(0xFF185C3B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (entity == 'category') ...[
                          const SizedBox(height: 10),
                          _masterDropdown(
                            label:
                                '\u0646\u0648\u0639 \u0627\u0644\u062a\u0635\u0646\u064a\u0641',
                            value: vendorTypeController.text == 'store'
                                ? 'store'
                                : 'restaurant',
                            items: const {
                              'restaurant':
                                  '\u062a\u0635\u0646\u064a\u0641 \u0645\u0637\u0627\u0639\u0645',
                              'store':
                                  '\u062a\u0635\u0646\u064a\u0641 \u0645\u062a\u0627\u062c\u0631',
                            },
                            onChanged: (value) => setDialogState(
                              () => vendorTypeController.text = value,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _masterImagePicker(
                            label:
                                '\u0635\u0648\u0631\u0629 \u0627\u0644\u062a\u0635\u0646\u064a\u0641',
                            fileName: selectedImageLabel,
                            onPick: () async {
                              final input = html.FileUploadInputElement()
                                ..accept = 'image/*';
                              input.click();
                              await input.onChange.first;
                              final file = input.files?.first;
                              if (file == null) return;
                              final reader = html.FileReader()
                                ..readAsDataUrl(file);
                              await reader.onLoadEnd.first;
                              setDialogState(() {
                                selectedImageLabel = file.name;
                                imageController.text =
                                    reader.result?.toString() ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          if (initialImageUrl.isNotEmpty)
                            Container(
                              height: 130,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                initialImageUrl,
                                fit: BoxFit.cover,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.prefer,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 42,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nameEnController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'اسم التصنيف بالإنجليزية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const SizedBox.shrink(),
                          const SizedBox(height: 10),
                          const SizedBox.shrink(),
                        ],
                        if (entity == 'topping') ...[
                          const SizedBox(height: 10),
                          if (initialImageUrl.isNotEmpty)
                            Container(
                              height: 130,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                initialImageUrl,
                                fit: BoxFit.cover,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.prefer,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 42,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nameEnController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'اسم الإضافة بالإنجليزية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: priceController,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'فرق السعر',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: imageController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'صورة الإضافة أو مسارها',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minChoiceController,
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'الحد الأدنى',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: maxChoiceController,
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'الحد الأقصى',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: vendorController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'رقم مجموعة الإضافة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: groupTypeController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'النوع (إضافات / مكونات)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: requiredController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'الإلزامية (إجباري / اختياري)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: activeController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'الحالة (نشط / مخفي)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (entity == 'coupon') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: priceController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'نسبة الخصم (%)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: discountController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'عدد الاستخدامات',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: expireController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الانتهاء (YYYY-MM-DD HH:MM:SS)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (entity == 'restaurant') ...[
                          const SizedBox(height: 10),
                          _masterDropdown(
                            label: '\u0627\u0644\u062d\u0627\u0644\u0629',
                            value:
                                statusController.text == 'active' ||
                                    statusController.text.contains(
                                      '\u0646\u0634\u0637',
                                    )
                                ? 'active'
                                : statusController.text == 'pending' ||
                                      statusController.text.contains(
                                        '\u0645\u0631\u0627\u062c\u0639\u0629',
                                      )
                                ? 'pending'
                                : 'inactive',
                            items: const {
                              'active': '\u0646\u0634\u0637',
                              'inactive': '\u0645\u063a\u0644\u0642',
                              'pending':
                                  '\u0642\u064a\u062f \u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0629',
                            },
                            onChanged: (value) => setDialogState(
                              () => statusController.text = value,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: ownerController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'اسم المالك',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: phoneController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _masterLocationPicker(
                            addressController: addressController,
                            latitudeController: latitudeController,
                            longitudeController: longitudeController,
                            setDialogState: setDialogState,
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(height: 10),
                          const SizedBox.shrink(),
                        ],
                        if (entity == 'product') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: priceController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: entity == 'coupon' ? 'الخصم' : 'السعر',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (entity == 'product') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: discountController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: entity == 'coupon'
                                  ? 'عدد الاستخدامات'
                                  : 'نسبة الخصم',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Text(
                          'سيتم حفظ البيانات مباشرة في قاعدة البيانات ثم تحديث القائمة.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5F6E66),
                  minimumSize: const Size(112, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final savedId = await _saveRestaurantEntity(
                    entity: entity,
                    mode: mode,
                    id: id,
                    label: title,
                    data: {
                      'name': nameController.text.trim(),
                      'description': noteController.text.trim(),
                      'notes': noteController.text.trim(),
                      if (entity == 'product') ...{
                        'name_en': nameEnController.text.trim(),
                        'description_en': descriptionEnController.text.trim(),
                        'image': imageController.text.trim(),
                        'count': int.tryParse(stockController.text.trim()) ?? 0,
                        'stock_unit': stockUnitController.text.trim(),
                        'stock_step':
                            double.tryParse(stockStepController.text.trim()) ??
                            1,
                        'category_id':
                            int.tryParse(categoryController.text.trim()) ?? 0,
                        'vendor_id':
                            int.tryParse(vendorController.text.trim()) ?? 0,
                        'active': activeController.text.trim() == 'مخفي'
                            ? 0
                            : 1,
                      },
                      if (entity == 'category') ...{
                        'name_en': nameEnController.text.trim(),
                        'image': imageController.text.trim(),
                        'vendor_id': 0,
                        'category_type': vendorTypeController.text == 'store'
                            ? 'store'
                            : 'restaurant',
                      },
                      if (entity == 'topping') ...{
                        'name_en': nameEnController.text.trim(),
                        'image': imageController.text.trim(),
                        'price':
                            double.tryParse(priceController.text.trim()) ?? 0,
                        'group_id':
                            int.tryParse(vendorController.text.trim()) ?? 0,
                        'min_choice':
                            int.tryParse(minChoiceController.text.trim()) ?? 0,
                        'max_choice':
                            int.tryParse(maxChoiceController.text.trim()) ?? 1,
                        'is_required':
                            requiredController.text.trim() == 'إجباري' ? 1 : 0,
                        'group_type':
                            groupTypeController.text.trim() == 'مكونات'
                            ? 'ingredient'
                            : 'modifier',
                        'active': activeController.text.trim() == 'مخفي'
                            ? 0
                            : 1,
                      },
                      if (entity == 'coupon') ...{
                        'discount':
                            int.tryParse(priceController.text.trim()) ?? 0,
                        'count':
                            int.tryParse(discountController.text.trim()) ?? 0,
                        'expire_date': expireController.text.trim(),
                      },
                      if (entity == 'restaurant') ...{
                        'vendor_type':
                            vendorTypeController.text.trim().toLowerCase() ==
                                'store'
                            ? 'store'
                            : 'restaurant',
                        'store_category': storeCategoryController.text.trim(),
                        'slug': slugController.text.trim(),
                        'owner': ownerController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'address': addressController.text.trim(),
                        'latitude':
                            double.tryParse(latitudeController.text.trim()) ??
                            0,
                        'longitude':
                            double.tryParse(longitudeController.text.trim()) ??
                            0,
                        'status': switch (statusController.text.trim()) {
                          'نشط' => 'active',
                          'مغلق' => 'inactive',
                          'قيد المراجعة' => 'pending',
                          final value => value.isEmpty ? 'active' : value,
                        },
                      },
                      if (priceController.text.trim().isNotEmpty)
                        if (entity == 'coupon')
                          'discount': priceController.text.trim()
                        else
                          'price': priceController.text.trim(),
                      if (discountController.text.trim().isNotEmpty)
                        if (entity == 'coupon')
                          'count': discountController.text.trim()
                        else
                          'discount': discountController.text.trim(),
                    },
                  );
                  final selectedVendor = vendorOptions.where(
                    (vendor) =>
                        _restaurantEntityNumericId(vendor.id).toString() ==
                        vendorController.text,
                  );
                  final selectedVendorIsStore =
                      selectedVendor.isNotEmpty &&
                      selectedVendor.first.vendorType == 'store';
                  if (entity == 'product' &&
                      selectedVendorIsStore &&
                      savedId != null &&
                      savedId > 0) {
                    await widget.api._saveMasterProductAttributes(
                      widget.session.token,
                      itemId: savedId,
                      attributes: _parseMasterAttributes(
                        attributesController.text,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
    slugController.dispose();
    noteController.dispose();
    priceController.dispose();
    discountController.dispose();
    ownerController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    statusController.dispose();
    nameEnController.dispose();
    descriptionEnController.dispose();
    imageController.dispose();
    stockController.dispose();
    stockUnitController.dispose();
    stockStepController.dispose();
    categoryController.dispose();
    vendorController.dispose();
    activeController.dispose();
    minChoiceController.dispose();
    maxChoiceController.dispose();
    requiredController.dispose();
    groupTypeController.dispose();
    expireController.dispose();
    vendorTypeController.dispose();
    storeCategoryController.dispose();
    attributesController.dispose();
  }

  Widget _masterDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.containsKey(value) ? value : items.keys.first;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      alignment: Alignment.centerRight,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.entries
          .map(
            (item) => DropdownMenuItem(
              value: item.key,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(item.value),
              ),
            ),
          )
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  Widget _masterVendorDropdown(
    TextEditingController controller,
    List<_RestaurantProfile> vendors,
    StateSetter setDialogState,
  ) {
    final items = <String, String>{
      for (final vendor in vendors)
        _restaurantEntityNumericId(vendor.id).toString():
            '${vendor.name} — ${vendor.vendorType == 'store' ? '\u0645\u062a\u062c\u0631' : '\u0645\u0637\u0639\u0645'}',
    };
    if (controller.text.isEmpty && items.isNotEmpty) {
      controller.text = items.keys.first;
    }
    return _masterDropdown(
      label:
          '\u0627\u0644\u0645\u062a\u062c\u0631 \u0623\u0648 \u0627\u0644\u0645\u0637\u0639\u0645',
      value: controller.text,
      items: items.isEmpty
          ? {
              '0':
                  '\u0644\u0627 \u062a\u0648\u062c\u062f \u062c\u0647\u0627\u062a',
            }
          : items,
      onChanged: (value) => setDialogState(() => controller.text = value),
    );
  }

  Widget _masterImagePicker({
    required String label,
    required String fileName,
    required Future<void> Function() onPick,
  }) {
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.upload_file_rounded),
      label: Text(
        fileName.isEmpty
            ? '\u0627\u062e\u062a\u0631 \u0635\u0648\u0631\u0629 \u0645\u0646 \u0627\u0644\u062c\u0647\u0627\u0632'
            : '$label: $fileName',
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _masterLocationPicker({
    required TextEditingController addressController,
    required TextEditingController latitudeController,
    required TextEditingController longitudeController,
    required StateSetter setDialogState,
  }) {
    // Cairo is the default location for new restaurants/stores.
    final latitude = double.tryParse(latitudeController.text) ?? 30.0444;
    final longitude = double.tryParse(longitudeController.text) ?? 31.2357;
    if (latitudeController.text.trim().isEmpty) {
      latitudeController.text = latitude.toStringAsFixed(6);
    }
    if (longitudeController.text.trim().isEmpty) {
      longitudeController.text = longitude.toStringAsFixed(6);
    }
    final center = LatLng(latitude, longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '\u0645\u0648\u0642\u0639 \u0627\u0644\u0645\u0646\u0634\u0623\u0629',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF18352A),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12.5,
                onTap: (_, point) => setDialogState(() {
                  latitudeController.text = point.latitude.toStringAsFixed(6);
                  longitudeController.text = point.longitude.toStringAsFixed(6);
                  addressController.text =
                      '\u0645\u0648\u0642\u0639 \u0645\u062d\u062f\u062f \u0639\u0644\u0649 \u0627\u0644\u062e\u0631\u064a\u0637\u0629';
                }),
              ),
              children: [
                TileLayer(
                  urlTemplate: _kMapboxAccessToken.trim().isNotEmpty
                      ? _kMapboxTileUrl
                      : _kOsmTileUrl,
                  fallbackUrl: _kOsmTileUrl,
                  additionalOptions: const {'accessToken': _kMapboxAccessToken},
                  userAgentPackageName: 'com.aleppoeats.master',
                  maxNativeZoom: 18,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF087443),
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          addressController.text.isEmpty
              ? '\u0627\u0636\u063a\u0637 \u0639\u0644\u0649 \u0627\u0644\u062e\u0631\u064a\u0637\u0629 \u0644\u062a\u062d\u062f\u064a\u062f \u0627\u0644\u0645\u0648\u0642\u0639'
              : addressController.text,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Color(0xFF65756D)),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _parseMasterAttributes(String raw) {
    final result = <Map<String, dynamic>>[];
    for (final line in raw.split(RegExp(r'[\r\n]+'))) {
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final name = parts.first.trim();
      if (name.isEmpty) continue;
      final values = parts
          .skip(1)
          .join(':')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .map(
            (value) => <String, dynamic>{'value_ar': value, 'value_en': value},
          )
          .toList();
      result.add({
        'name_ar': name,
        'name_en': name,
        'is_required': false,
        'values': values,
      });
    }
    return result;
  }

  String _restaurantEntityForSubPage(String subPage) {
    return switch (subPage) {
      'categories' => 'category',
      'products' => 'product',
      'toppings' => 'topping',
      'offers' => 'offer',
      'coupons' => 'coupon',
      _ => 'restaurant',
    };
  }

  Future<int?> _saveRestaurantEntity({
    required String entity,
    required String mode,
    int? id,
    required String label,
    required Map<String, dynamic> data,
  }) async {
    if (_restaurantActionRunning) {
      return null;
    }
    final name = (data['name'] ?? '').toString().trim();
    if (name.isEmpty) {
      _showMasterSnack(context, 'اكتب الاسم قبل الحفظ');
      return null;
    }
    setState(() => _restaurantActionRunning = true);
    try {
      final imageValue = (data['image'] ?? '').toString();
      if ((entity == 'category' || entity == 'product') &&
          imageValue.startsWith('data:image/')) {
        data['image'] = await widget.api._uploadMasterEntityImage(
          widget.session.token,
          entity: entity,
          dataUrl: imageValue,
        );
      }
      final savedId = await widget.api._saveMasterRestaurantEntity(
        widget.session.token,
        entity: entity,
        mode: mode,
        id: id,
        data: data,
      );
      if (!mounted) {
        return null;
      }
      _showMasterSnack(context, 'تم حفظ $label بنجاح');
      _handleReload();
      return savedId > 0 ? savedId : id;
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _restaurantActionRunning = false);
      }
    }
    return null;
  }

  Future<void> _editStoreSpecialty([Map<String, dynamic>? row]) async {
    final key = TextEditingController(
      text: (row?['category_key'] ?? '').toString(),
    );
    final nameAr = TextEditingController(
      text: (row?['name_ar'] ?? '').toString(),
    );
    final nameEn = TextEditingController(
      text: (row?['name_en'] ?? '').toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          row == null ? 'إضافة تخصص متجر' : 'تعديل تخصص متجر',
          textAlign: TextAlign.right,
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameAr,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'اسم التخصص بالعربية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameEn,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'اسم التخصص بالإنجليزية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: key,
                textAlign: TextAlign.left,
                decoration: const InputDecoration(
                  labelText: 'المعرف البرمجي (مثل fashion)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await widget.api._saveMasterStoreSpecialty(
                  widget.session.token,
                  id: _toInt(row?['id']),
                  categoryKey: key.text.trim(),
                  nameAr: nameAr.text.trim(),
                  nameEn: nameEn.text.trim(),
                );
                if (mounted) {
                  setState(
                    () => _storeSpecialtiesFuture = widget.api
                        ._fetchMasterStoreSpecialties(widget.session.token),
                  );
                }
              } catch (error) {
                if (mounted) _showMasterSnack(context, error.toString());
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      ),
    ).whenComplete(() {
      key.dispose();
      nameAr.dispose();
      nameEn.dispose();
    });
  }

  Future<void> _deleteStoreSpecialty(Map<String, dynamic> row) async {
    try {
      await widget.api._deleteMasterStoreSpecialty(
        widget.session.token,
        _toInt(row['id']),
      );
      if (mounted) {
        setState(
          () => _storeSpecialtiesFuture = widget.api
              ._fetchMasterStoreSpecialties(widget.session.token),
        );
      }
    } catch (error) {
      if (mounted) _showMasterSnack(context, error.toString());
    }
  }

  Future<void> _showAdvancedRestaurantFilters() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تصفية متقدمة', textAlign: TextAlign.right),
          content: const SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'كلمة البحث',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'الحالة أو المدينة',
                    border: OutlineInputBorder(),
                  ),
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
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleReload();
              },
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('تطبيق'),
            ),
          ],
        );
      },
    );
  }

  Future<_RestaurantManagementSeed> _loadRestaurantSeed() async {
    final token = widget.session.token;
    final overview = await widget.api._fetchMasterRestaurantsOverviewRaw(
      token,
      vendorType: widget.initialVendorType,
    );
    final restaurants = _asMapList(
      overview['restaurants'],
    ).map(_RestaurantProfile.fromJson).toList();
    final categoryRows = _asMapList(overview['categories']);
    final productRows = _asMapList(overview['products']);

    final categoryNameById = <String, String>{};
    for (final row in categoryRows) {
      final id = (row['categories_id'] ?? '').toString();
      final name = _normalizeUtf8Text(
        _firstText([
          row['categories_name_ar'],
          row['categories_name_en'],
          'تصنيف',
        ]),
      );
      if (id.isNotEmpty) {
        categoryNameById[id] = name;
      }
    }

    final products = <_ProductRecord>[];
    for (final row in productRows) {
      products.add(
        _buildLiveProductRecord(row, categoryNameById: categoryNameById),
      );
    }

    final categories = <_CategoryRecord>[];
    for (var index = 0; index < categoryRows.length; index++) {
      categories.add(
        _buildLiveCategoryRecord(
          categoryRows[index],
          index: index,
          products: products,
        ),
      );
    }

    final menuSections = categories
        .map(
          (category) => _MenuSectionRecord(
            category.name,
            category.productsCount,
            category.status,
            category.icon,
          ),
        )
        .toList();

    final restaurantNameById = <String, String>{
      for (final restaurant in restaurants) restaurant.id: restaurant.name,
      for (final restaurant in restaurants)
        restaurant.id.replaceFirst('RST-', ''): restaurant.name,
    };
    final toppings = _asMapList(overview['toppings'])
        .map(
          (row) =>
              _buildLiveToppingRecord(row, categoryNameById: categoryNameById),
        )
        .toList();
    final offers = _asMapList(
      overview['offers'],
    ).map((row) => _buildLiveOfferRecord(row, restaurantNameById)).toList();
    final coupons = _asMapList(
      overview['coupons'],
    ).map(_buildLiveCouponRecord).toList();

    return _RestaurantManagementSeed.empty().copyWith(
      restaurants: restaurants,
      categories: categories,
      products: products,
      menuSections: menuSections,
      toppings: toppings,
      offers: offers,
      coupons: coupons,
    );
  }

  _RestaurantManagementSeed _filterRestaurantSeed(
    _RestaurantManagementSeed seed,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool matchesText(List<String> values) {
      if (query.isEmpty) {
        return true;
      }
      return values.any((value) => value.toLowerCase().contains(query));
    }

    bool matchesStatus(String status) {
      if (_restaurantStatusFilter == 'all') {
        return true;
      }
      if (_restaurantStatusFilter == 'active') {
        return status == 'نشط';
      }
      if (_restaurantStatusFilter == 'hidden') {
        return status.contains('مخفي') || status.contains('مغلق');
      }
      if (_restaurantStatusFilter == 'paused') {
        return status.contains('مؤقت') || status.contains('مراجعة');
      }
      return true;
    }

    bool matchesPrimary({
      required String status,
      int orders = 0,
      bool enabled = true,
    }) {
      if (_restaurantPrimaryFilter == 'featured') {
        return orders > 0 || enabled;
      }
      if (_restaurantPrimaryFilter == 'inactive') {
        return !enabled || status != 'نشط';
      }
      return true;
    }

    final restaurants = seed.restaurants.where((item) {
      return matchesText([
            item.name,
            item.subtitle,
            item.owner,
            item.phone,
            item.city,
            item.zone,
          ]) &&
          matchesStatus(item.status) &&
          (_vendorTypeFilter == 'all' ||
              item.vendorType == _vendorTypeFilter) &&
          matchesPrimary(status: item.status, orders: item.todayOrders);
    }).toList();

    final categories = seed.categories.where((item) {
      return matchesText([item.name, item.description]) &&
          matchesStatus(item.status) &&
          matchesPrimary(status: item.status, orders: item.productsCount);
    }).toList();

    final products = seed.products.where((item) {
      return matchesText([item.name, item.id, item.restaurant, item.section]) &&
          matchesStatus(item.status) &&
          matchesPrimary(status: item.status, orders: item.orders);
    }).toList();

    final toppings = seed.toppings.where((item) {
      return matchesText([item.name, item.id, item.restaurant, item.section]) &&
          matchesStatus(item.status) &&
          matchesPrimary(
            status: item.status,
            orders: item.maxChoice,
            enabled: item.enabled,
          );
    }).toList();

    final offers = seed.offers.where((item) {
      return matchesText([item.name, item.id, item.restaurant]) &&
          matchesStatus(item.status) &&
          matchesPrimary(status: item.status, orders: item.performanceOrders);
    }).toList();

    final coupons = seed.coupons.where((item) {
      return matchesText([item.code, item.restaurant, item.value]) &&
          matchesStatus(item.status) &&
          matchesPrimary(status: item.status);
    }).toList();

    final categoryNames = categories.map((item) => item.name).toSet();
    final menuSections = seed.menuSections.where((item) {
      return matchesText([item.name]) &&
          (categoryNames.isEmpty || categoryNames.contains(item.name));
    }).toList();

    return seed.copyWith(
      restaurants: restaurants,
      categories: categories,
      products: products,
      toppings: toppings,
      offers: offers,
      coupons: coupons,
      menuSections: menuSections,
    );
  }

  Future<void> _editRestaurant(_RestaurantProfile profile) {
    return _showRestaurantEntityEditor(
      title: 'تعديل المطعم',
      entity: 'restaurant',
      mode: 'update',
      id: _restaurantEntityNumericId(profile.id),
      initialName: profile.name,
      initialSlug: profile.slug,
      initialNotes: profile.description,
      initialOwner: profile.owner,
      initialEmail: profile.email,
      initialPhone: profile.phone,
      initialAddress: profile.address,
      initialLatitude: profile.marker.point.latitude.toStringAsFixed(6),
      initialLongitude: profile.marker.point.longitude.toStringAsFixed(6),
      initialStatus: profile.status,
      initialVendorType: profile.vendorType,
      initialStoreCategory: profile.storeCategory,
      subtitle: profile.owner,
    );
  }

  Future<void> _editProductById(String title, int id) async {
    final seed = await _restaurantSeedFuture;
    if (!mounted) {
      return;
    }
    _ProductRecord? product;
    for (final item in seed.products) {
      if (_restaurantRecordId(item.id) == id) {
        product = item;
        break;
      }
    }
    if (product == null) {
      _showMasterSnack(context, 'تعذر تحميل بيانات المنتج كاملة');
      return;
    }
    var attributesText = '';
    try {
      final raw = await widget.api._fetchMasterProductEditRaw(
        widget.session.token,
        id,
      );
      final rows = raw['attributes'] is List
          ? raw['attributes'] as List
          : const [];
      attributesText = rows
          .map((row) {
            final item = row is Map ? row : const {};
            final values = item['values'] is List
                ? (item['values'] as List)
                      .map(
                        (value) =>
                            (value is Map
                                    ? (value['value_ar'] ?? value['value_en'])
                                    : value)
                                .toString(),
                      )
                      .join(', ')
                : '';
            return '${(item['name_ar'] ?? item['name_en'] ?? '').toString()}: $values';
          })
          .where((line) => !line.startsWith(':'))
          .join('\n');
    } catch (_) {}
    await _showRestaurantEntityEditor(
      title: title,
      entity: 'product',
      mode: 'update',
      id: id,
      initialName: product.name,
      initialNameEn: product.nameEn,
      initialNotes: product.description,
      initialDescriptionEn: product.descriptionEn,
      initialPrice: product.priceValue.toString(),
      initialDiscount: product.discountPercent.toString(),
      initialImageName: product.imageName,
      initialImageUrl: product.imageUrl,
      initialStockCount: product.stockCount.toString(),
      initialCategoryId: product.categoryId.toString(),
      initialVendorId: product.vendorId.toString(),
      initialActive: product.active,
      initialAttributesText: attributesText,
      subtitle: product.restaurant,
    );
  }

  Future<void> _editCategoryById(String title, int id) async {
    final seed = await _restaurantSeedFuture;
    if (!mounted) {
      return;
    }
    _CategoryRecord? category;
    for (final item in seed.categories) {
      if (_restaurantRecordId(item.id) == id) {
        category = item;
        break;
      }
    }
    if (category == null) {
      _showMasterSnack(context, 'تعذر تحميل بيانات التصنيف كاملة');
      return;
    }
    await _showRestaurantEntityEditor(
      title: title,
      entity: 'category',
      mode: 'update',
      id: id,
      initialName: category.name,
      initialNameEn: category.nameEn,
      initialImageName: category.imageName,
      initialImageUrl: category.imageUrl,
      initialVendorType: category.categoryType,
      subtitle: category.description,
    );
  }

  Future<void> _editToppingById(String title, int id) async {
    final seed = await _restaurantSeedFuture;
    if (!mounted) {
      return;
    }
    _ToppingRecord? topping;
    for (final item in seed.toppings) {
      if (_restaurantRecordId(item.id) == id) {
        topping = item;
        break;
      }
    }
    if (topping == null) {
      _showMasterSnack(context, 'تعذر تحميل بيانات الإضافة كاملة');
      return;
    }
    await _showRestaurantEntityEditor(
      title: title,
      entity: 'topping',
      mode: 'update',
      id: id,
      initialName: topping.name,
      initialNameEn: topping.nameEn,
      initialPrice: topping.priceValue.toString(),
      initialImageName: topping.imageName,
      initialImageUrl: topping.imageUrl,
      initialMinChoice: topping.minChoice.toString(),
      initialMaxChoice: topping.maxChoice.toString(),
      initialRequired: topping.type,
      initialGroupType: topping.groupType,
      initialVendorId: topping.groupId.toString(),
      initialActive: topping.enabled,
      subtitle: topping.restaurant,
    );
  }

  Future<void> _editCouponById(String title, int id) async {
    final seed = await _restaurantSeedFuture;
    if (!mounted) {
      return;
    }
    _CouponRecord? coupon;
    for (final item in seed.coupons) {
      if (_restaurantRecordId(item.id) == id) {
        coupon = item;
        break;
      }
    }
    if (coupon == null) {
      _showMasterSnack(context, 'تعذر تحميل بيانات الكوبون كاملة');
      return;
    }
    await _showRestaurantEntityEditor(
      title: title,
      entity: 'coupon',
      mode: 'update',
      id: id,
      initialName: coupon.code,
      initialPrice: coupon.discountPercent.toString(),
      initialDiscount: coupon.usageCount.toString(),
      initialExpireDate: coupon.expireDate,
      subtitle: coupon.restaurant,
    );
  }

  Future<void> _deleteRestaurant(_RestaurantProfile profile) async {
    if (_restaurantActionRunning) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد حذف المطعم'),
        content: Text(
          'هل تريد حذف «${profile.name}»؟ لا يمكن تنفيذ الحذف إذا كان المطعم مرتبطًا بطلبات أو منتجات.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('تأكيد الحذف'),
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runRestaurantEntityAction(
      entity: 'restaurant',
      id: profile.id,
      action: 'delete',
      label: 'حذف المطعم',
    );
  }

  int _restaurantEntityNumericId(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _runRestaurantEntityAction({
    required String entity,
    required String id,
    required String action,
    required String label,
  }) async {
    if (_restaurantActionRunning) {
      return;
    }
    final numericId = _restaurantEntityNumericId(id);
    if (numericId <= 0) {
      _showMasterSnack(context, 'لا يوجد معرف صالح لتنفيذ العملية');
      return;
    }

    setState(() => _restaurantActionRunning = true);
    try {
      await widget.api._runMasterRestaurantEntityAction(
        widget.session.token,
        entity: entity,
        id: numericId,
        action: action,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, 'تم تنفيذ $label بنجاح');
      _handleReload();
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _restaurantActionRunning = false);
      }
    }
  }

  Future<void> _toggleProductStatus(_ProductRecord product) {
    return _runRestaurantEntityAction(
      entity: 'product',
      id: product.id,
      action: product.status == 'نشط' ? 'deactivate' : 'activate',
      label: product.status == 'نشط' ? 'إخفاء المنتج' : 'تفعيل المنتج',
    );
  }

  Future<void> _deleteProduct(_ProductRecord product) {
    return _runRestaurantEntityAction(
      entity: 'product',
      id: product.id,
      action: 'delete',
      label: 'حذف المنتج',
    );
  }

  Future<void> _toggleCategoryStatus(_CategoryRecord category) {
    return _runRestaurantEntityAction(
      entity: 'category',
      id: category.id,
      action: category.status == 'نشط' ? 'deactivate' : 'activate',
      label: category.status == 'نشط' ? 'إخفاء التصنيف' : 'تفعيل التصنيف',
    );
  }

  Future<void> _deleteCategory(_CategoryRecord category) {
    return _runRestaurantEntityAction(
      entity: 'category',
      id: category.id,
      action: 'delete',
      label: 'حذف التصنيف',
    );
  }

  Future<void> _toggleToppingStatus(_ToppingRecord topping) {
    return _runRestaurantEntityAction(
      entity: 'topping',
      id: topping.id,
      action: topping.enabled ? 'deactivate' : 'activate',
      label: topping.enabled ? 'إخفاء الإضافة' : 'تفعيل الإضافة',
    );
  }

  Future<void> _deleteTopping(_ToppingRecord topping) {
    return _runRestaurantEntityAction(
      entity: 'topping',
      id: topping.id,
      action: 'delete',
      label: 'حذف الإضافة',
    );
  }

  Future<void> _toggleOfferStatus(_OfferRecord offer) {
    return _runRestaurantEntityAction(
      entity: 'offer',
      id: offer.id,
      action: offer.status == 'نشط' ? 'deactivate' : 'activate',
      label: offer.status == 'نشط' ? 'إيقاف العرض' : 'تفعيل العرض',
    );
  }

  Future<void> _deleteOffer(_OfferRecord offer) {
    return _runRestaurantEntityAction(
      entity: 'offer',
      id: offer.id,
      action: 'delete',
      label: 'حذف العرض',
    );
  }

  Future<void> _deleteCoupon(_CouponRecord coupon) {
    return _runRestaurantEntityAction(
      entity: 'coupon',
      id: coupon.id,
      action: 'delete',
      label: 'حذف الكوبون',
    );
  }

  Widget _buildRestaurantWorkspace(
    DateTime serverNow,
    _RestaurantManagementSeed effectiveSeed,
    AsyncSnapshot<_RestaurantManagementSeed> snapshot,
  ) {
    switch (_activeSubPage) {
      case 'menus':
        if (effectiveSeed.menuSections.isEmpty) {
          return _restaurantEmptyWorkspace(_activeSubPage);
        }
        return _RestaurantMenusWorkspace(
          seed: effectiveSeed,
          selectedSectionIndex: _selectedMenuSectionIndex,
          onSectionSelected: (value) {
            setState(() => _selectedMenuSectionIndex = value);
          },
          onToggleProductStatus: _toggleProductStatus,
          onDeleteProduct: _deleteProduct,
        );
      case 'categories':
        if (effectiveSeed.categories.isEmpty) {
          return _restaurantEmptyWorkspace(_activeSubPage);
        }
        return _RestaurantCategoriesWorkspace(
          seed: effectiveSeed,
          selectedCategoryIndex: _selectedCategoryIndex,
          onCategorySelected: (value) {
            setState(() => _selectedCategoryIndex = value);
          },
          onToggleCategoryStatus: _toggleCategoryStatus,
          onDeleteCategory: _deleteCategory,
        );
      case 'store_specialties':
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _storeSpecialtiesFuture,
          builder: (context, specialtiesSnapshot) {
            if (specialtiesSnapshot.hasError) {
              return _StoreSpecialtiesWorkspace(
                rows: const [],
                loading: false,
                error: specialtiesSnapshot.error.toString(),
                onAdd: () => _editStoreSpecialty(),
                onEdit: (row) => _editStoreSpecialty(row),
                onDelete: _deleteStoreSpecialty,
              );
            }
            return _StoreSpecialtiesWorkspace(
              rows: specialtiesSnapshot.data ?? const [],
              loading:
                  specialtiesSnapshot.connectionState != ConnectionState.done,
              onAdd: () => _editStoreSpecialty(),
              onEdit: (row) => _editStoreSpecialty(row),
              onDelete: _deleteStoreSpecialty,
            );
          },
        );
      case 'products':
        if (effectiveSeed.products.isEmpty) {
          return _restaurantEmptyWorkspace(_activeSubPage);
        }
        return _RestaurantProductsWorkspace(
          seed: effectiveSeed,
          selectedProductIndex: _selectedProductIndex,
          onProductSelected: (value) {
            setState(() => _selectedProductIndex = value);
          },
          onToggleProductStatus: _toggleProductStatus,
          onDeleteProduct: _deleteProduct,
        );
      case 'toppings':
        if (effectiveSeed.toppings.isEmpty) {
          return _restaurantEmptyWorkspace(_activeSubPage);
        }
        return _RestaurantToppingsWorkspace(
          seed: effectiveSeed,
          selectedToppingIndex: _selectedToppingIndex,
          onToppingSelected: (value) {
            setState(() => _selectedToppingIndex = value);
          },
          onToggleToppingStatus: _toggleToppingStatus,
          onDeleteTopping: _deleteTopping,
        );
      case 'offers':
        if (effectiveSeed.offers.isEmpty) {
          return _restaurantEmptyWorkspace(_activeSubPage);
        }
        return _RestaurantOffersWorkspace(
          seed: effectiveSeed,
          selectedOfferIndex: _selectedOfferIndex,
          onOfferSelected: (value) {
            setState(() => _selectedOfferIndex = value);
          },
          onToggleOfferStatus: _toggleOfferStatus,
          onDeleteOffer: _deleteOffer,
        );
      case 'coupons':
        if (effectiveSeed.coupons.isEmpty) {
          return _restaurantEmptyWorkspace(_activeSubPage);
        }
        return _RestaurantCouponsWorkspace(
          seed: effectiveSeed,
          selectedCouponIndex: _selectedCouponIndex,
          onCouponSelected: (value) {
            setState(() => _selectedCouponIndex = value);
          },
          onDeleteCoupon: _deleteCoupon,
        );
      case 'all':
      default:
        if (snapshot.connectionState == ConnectionState.waiting &&
            effectiveSeed.restaurants.isEmpty) {
          return const _UsersPlaceholderWorkspace(
            title: 'جاري تحميل المطاعم',
            description: 'نقوم الآن بجلب بيانات المطاعم الحقيقية من الباك إند.',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return const _UsersPlaceholderWorkspace(
            title: 'تعذر تحميل المطاعم',
            description:
                'لم نتمكن من قراءة بيانات المطاعم من قاعدة البيانات حالياً.',
            icon: Icons.error_outline_rounded,
          );
        }
        if (effectiveSeed.restaurants.isEmpty) {
          return const _UsersPlaceholderWorkspace(
            title: 'لا توجد مطاعم',
            description: 'لم تصل أي سجلات مطاعم من الباك إند حتى الآن.',
            icon: Icons.storefront_outlined,
          );
        }
        final selectedRestaurantIndex =
            _selectedRestaurantIndex >= effectiveSeed.restaurants.length
            ? effectiveSeed.restaurants.length - 1
            : _selectedRestaurantIndex;
        return _RestaurantsAllWorkspace(
          seed: effectiveSeed,
          selectedRestaurantIndex: selectedRestaurantIndex,
          onRestaurantSelected: (value) {
            setState(() => _selectedRestaurantIndex = value);
          },
          onEditRestaurant: _editRestaurant,
          onDeleteRestaurant: _deleteRestaurant,
        );
    }
  }

  Widget _restaurantEmptyWorkspace(String key) {
    return _UsersPlaceholderWorkspace(
      title: _restaurantPageTitle(key),
      description:
          'لا توجد بيانات حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
      icon: _restaurantPageIcon(key),
    );
  }
}

String _restaurantPageTitle(String key) {
  switch (key) {
    case 'menus':
      return 'قوائم الطعام';
    case 'categories':
      return 'التصنيفات';
    case 'store_specialties':
      return 'تخصصات المتاجر';
    case 'products':
      return 'المنتجات';
    case 'toppings':
      return 'الإضافات (Toppings)';
    case 'offers':
      return 'عروض المطاعم';
    case 'coupons':
      return 'كوبونات المطاعم';
    case 'all':
    default:
      return 'جميع المطاعم';
  }
}

String _restaurantPageSubtitle(String key) {
  switch (key) {
    case 'menus':
      return 'إدارة أقسام ومواسم الطعام الخاصة بكل مطعم';
    case 'categories':
      return 'إدارة جميع تصنيفات الطعام المعروضة في المنصة';
    case 'store_specialties':
      return 'إضافة وتعديل وحذف تخصصات المتاجر المتاحة على المنصة';
    case 'products':
      return 'إدارة جميع منتجات قائمة الطعام في كافة المطاعم';
    case 'toppings':
      return 'إدارة جميع الإضافات المتاحة لإضافتها على المنتجات';
    case 'offers':
      return 'إدارة جميع العروض الخاصة بالمطاعم';
    case 'coupons':
      return 'إدارة جميع كوبونات الخصم الخاصة بكل مطعم';
    case 'all':
    default:
      return 'عرض وإدارة جميع المطاعم الشريكة في المنصة';
  }
}

IconData _restaurantPageIcon(String key) {
  switch (key) {
    case 'menus':
      return Icons.menu_book_outlined;
    case 'categories':
      return Icons.widgets_outlined;
    case 'products':
      return Icons.inventory_2_outlined;
    case 'toppings':
      return Icons.tune_rounded;
    case 'offers':
      return Icons.local_offer_outlined;
    case 'coupons':
      return Icons.confirmation_number_outlined;
    case 'all':
    default:
      return Icons.storefront_outlined;
  }
}

class _RestaurantManagementSeed {
  const _RestaurantManagementSeed({
    required this.restaurants,
    required this.menuSections,
    required this.categories,
    required this.products,
    required this.toppings,
    required this.offers,
    required this.coupons,
  });

  final List<_RestaurantProfile> restaurants;
  final List<_MenuSectionRecord> menuSections;
  final List<_CategoryRecord> categories;
  final List<_ProductRecord> products;
  final List<_ToppingRecord> toppings;
  final List<_OfferRecord> offers;
  final List<_CouponRecord> coupons;

  _RestaurantManagementSeed copyWith({
    List<_RestaurantProfile>? restaurants,
    List<_MenuSectionRecord>? menuSections,
    List<_CategoryRecord>? categories,
    List<_ProductRecord>? products,
    List<_ToppingRecord>? toppings,
    List<_OfferRecord>? offers,
    List<_CouponRecord>? coupons,
  }) {
    return _RestaurantManagementSeed(
      restaurants: restaurants ?? this.restaurants,
      menuSections: menuSections ?? this.menuSections,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      toppings: toppings ?? this.toppings,
      offers: offers ?? this.offers,
      coupons: coupons ?? this.coupons,
    );
  }

  factory _RestaurantManagementSeed.build() {
    return _RestaurantManagementSeed.empty();
  }

  factory _RestaurantManagementSeed.empty() {
    return const _RestaurantManagementSeed(
      restaurants: <_RestaurantProfile>[],
      menuSections: <_MenuSectionRecord>[],
      categories: <_CategoryRecord>[],
      products: <_ProductRecord>[],
      toppings: <_ToppingRecord>[],
      offers: <_OfferRecord>[],
      coupons: <_CouponRecord>[],
    );
  }
}

class _RestaurantProfile {
  const _RestaurantProfile({
    required this.id,
    required this.name,
    required this.slug,
    required this.subtitle,
    required this.owner,
    required this.email,
    required this.description,
    required this.phone,
    required this.city,
    required this.zone,
    required this.address,
    required this.status,
    required this.todayOrders,
    required this.averagePrepMinutes,
    required this.rating,
    required this.revenueLabel,
    required this.coverageZones,
    required this.logoUrl,
    required this.vendorType,
    required this.storeCategory,
    required this.marker,
  });

  final String id;
  final String name;
  final String slug;
  final String subtitle;
  final String owner;
  final String email;
  final String description;
  final String phone;
  final String city;
  final String zone;
  final String address;
  final String status;
  final int todayOrders;
  final int averagePrepMinutes;
  final double rating;
  final String revenueLabel;
  final int coverageZones;
  final String logoUrl;
  final String vendorType;
  final String storeCategory;
  final _OperationsMapMarkerData marker;

  factory _RestaurantProfile.fromJson(Map<String, dynamic> json) {
    final id = (json['vendor_id'] ?? json['id'] ?? '').toString();
    final storeName = (json['store_name'] ?? '').toString().trim();
    final vendorName = (json['vendor_name'] ?? '').toString().trim();
    final address = (json['store_address'] ?? '').toString().trim();
    final latitude = _parseMasterDouble(json['store_latitude'], 33.5138);
    final longitude = _parseMasterDouble(json['store_longitude'], 36.2765);
    final logoName = (json['vendor_logo'] ?? '').toString().trim();
    final name = storeName.isEmpty ? vendorName : storeName;
    final vendorType =
        (json['vendor_type'] ?? 'restaurant').toString().toLowerCase() ==
            'store'
        ? 'store'
        : 'restaurant';
    final status = _mapRestaurantStatus(
      (json['vendor_status'] ?? '').toString(),
      _toInt(json['vendor_is_verified']),
    );
    final subtitle = vendorName.isNotEmpty && vendorName != name
        ? vendorName
        : 'مطعم على المنصة';
    final zone = _extractRestaurantZone(address);
    final city = _extractRestaurantCity(address);

    return _RestaurantProfile(
      id: id.isEmpty ? 'RST-UNKNOWN' : id,
      name: name.isEmpty ? 'مطعم بدون اسم' : name,
      slug: (json['store_slug'] ?? '').toString(),
      subtitle: subtitle,
      owner: vendorName.isEmpty ? 'غير محدد' : vendorName,
      email: (json['vendor_email'] ?? '').toString(),
      description: (json['vendor_description'] ?? '').toString(),
      phone: (json['vendor_phone'] ?? '').toString(),
      city: city,
      zone: zone,
      address: address.isEmpty ? 'لا يوجد عنوان مسجل' : address,
      status: status,
      todayOrders: _toInt(json['today_orders']),
      averagePrepMinutes: _toInt(json['average_prep_minutes']),
      rating: _parseMasterDouble(json['rating']),
      revenueLabel:
          '${(json['revenue'] ?? '0').toString()} ${MasterCurrency.symbol}',
      coverageZones: _toInt(json['coverage_zones'], address.isEmpty ? 0 : 1),
      logoUrl: logoName.isEmpty
          ? ''
          : _masterMediaUrl('uploads/vendors/logo/$logoName'),
      vendorType: vendorType,
      storeCategory: (json['store_category'] ?? '').toString(),
      marker: _OperationsMapMarkerData(
        type: 'restaurant',
        label: name.isEmpty ? 'مطعم' : name,
        subtitle: zone,
        point: LatLng(latitude, longitude),
        icon: Icons.storefront_outlined,
        color: _restaurantStatusColor(status),
      ),
    );
  }
}

String _extractRestaurantCity(String address) {
  final segments = address
      .split('-')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return '-';
  }
  return segments.first;
}

String _extractRestaurantZone(String address) {
  final segments = address
      .split('-')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.length < 2) {
    return address.isEmpty ? '-' : segments.first;
  }
  return segments[1];
}

String _mapRestaurantStatus(String rawStatus, int isVerified) {
  final normalized = rawStatus.trim().toLowerCase();
  if (normalized == 'active' || normalized == 'approved') {
    return isVerified == 1 ? 'نشط' : 'قيد المراجعة';
  }
  if (normalized == 'pending' || normalized == 'review') {
    return 'قيد المراجعة';
  }
  if (normalized == 'inactive' || normalized == 'disabled') {
    return 'مغلق';
  }
  return isVerified == 1 ? 'نشط' : 'قيد المراجعة';
}

Color _restaurantStatusColor(String status) {
  switch (status) {
    case 'نشط':
      return const Color(0xFF1A8B4A);
    case 'مغلق':
      return const Color(0xFFEF4444);
    case 'قيد المراجعة':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF2563EB);
  }
}

_ProductRecord _buildLiveProductRecord(
  Map<String, dynamic> json, {
  required Map<String, String> categoryNameById,
}) {
  final id = (json['items_id'] ?? '').toString();
  final section =
      categoryNameById[(json['items_cat'] ?? '').toString()] ?? 'غير مصنف';
  final basePrice = _parseMasterDouble(json['items_price']);
  final discountPercent = _toInt(json['items_discount']);
  final discountedPrice = discountPercent > 0 && discountPercent < 100
      ? basePrice * (1 - (discountPercent / 100))
      : basePrice;
  final imageName = (json['items_image'] ?? '').toString().trim();

  return _ProductRecord(
    id.isEmpty ? 'PRD-UNKNOWN' : 'PRD-$id',
    _normalizeUtf8Text(
      _firstText([json['items_name_ar'], json['items_name_en'], 'منتج']),
    ),
    _normalizeUtf8Text(
      _firstText([json['store_name'], json['vendor_name'], 'مطعم']),
    ),
    section,
    '${basePrice.toStringAsFixed(basePrice.truncateToDouble() == basePrice ? 0 : 2)} ${MasterCurrency.symbol}',
    '${discountedPrice.toStringAsFixed(discountedPrice.truncateToDouble() == discountedPrice ? 0 : 2)} ${MasterCurrency.symbol}',
    'توصيل',
    _toInt(json['items_active'], 1) == 1 ? 'نشط' : 'مخفي',
    _toInt(json['orders_count'], _toInt(json['items_count'])),
    _parseMasterDouble(json['average_rating']),
    _masterProductImageUrl(imageName),
    nameEn: (json['items_name_en'] ?? '').toString(),
    description: (json['items_desc_ar'] ?? '').toString(),
    descriptionEn: (json['items_desc_en'] ?? '').toString(),
    imageName: imageName,
    priceValue: basePrice,
    discountPercent: discountPercent,
    stockCount: _toInt(json['items_count']),
    categoryId: _toInt(json['items_cat']),
    vendorId: _toInt(json['vendor_id']),
    active: _toInt(json['items_active'], 1) == 1,
  );
}

String _masterProductImageUrl(String value) {
  final image = value.trim();
  if (image.isEmpty) return '';
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }
  final cleaned = image.replaceFirst(RegExp(r'^/?roaq/'), '');
  return _masterMediaUrl(
    cleaned.startsWith('uploud/') ? cleaned : 'uploud/items/$cleaned',
  );
}

_CategoryRecord _buildLiveCategoryRecord(
  Map<String, dynamic> json, {
  required int index,
  required List<_ProductRecord> products,
}) {
  final name = _normalizeUtf8Text(
    _firstText([
      json['categories_name_ar'],
      json['categories_name_en'],
      'تصنيف',
    ]),
  );
  final matchingProducts = products
      .where((product) => product.section == name)
      .toList();
  final restaurantNames = matchingProducts
      .map((product) => product.restaurant)
      .where((name) => name.trim().isNotEmpty)
      .toSet();
  final colorHex = _restaurantCategoryColor(index);
  final imageName = (json['categories_image'] ?? '').toString().trim();

  return _CategoryRecord(
    (json['categories_id'] ?? '').toString(),
    name,
    'تصنيف عام مشترك يمكن استخدامه مع أكثر من متجر أو مطعم',
    'نشط',
    colorHex,
    restaurantNames.length,
    matchingProducts.length,
    index + 1,
    imageName.isEmpty ? '' : _masterMediaUrl('uploud/categories/$imageName'),
    _restaurantCategoryIcon(name),
    nameEn: (json['categories_name_en'] ?? '').toString(),
    imageName: imageName,
    vendorId: _toInt(json['vendor_id']),
    categoryType:
        (json['category_type'] ?? 'restaurant').toString().toLowerCase() ==
            'store'
        ? 'store'
        : 'restaurant',
  );
}

String _restaurantCategoryColor(int index) {
  const palette = [
    '#FF5733',
    '#28A745',
    '#FFC107',
    '#17A2B8',
    '#6F42C1',
    '#FD7E14',
    '#E91E63',
    '#607D8B',
  ];
  return palette[index % palette.length];
}

IconData _restaurantCategoryIcon(String name) {
  if (name.contains('بيتزا')) return Icons.local_pizza_outlined;
  if (name.contains('برجر') || name.contains('ساندويتش')) {
    return Icons.lunch_dining_outlined;
  }
  if (name.contains('مشروب')) return Icons.local_drink_outlined;
  if (name.contains('سلطة')) return Icons.eco_outlined;
  if (name.contains('حلو')) return Icons.cake_outlined;
  if (name.contains('شوربة')) return Icons.ramen_dining_outlined;
  if (name.contains('فطور')) return Icons.free_breakfast_outlined;
  return Icons.widgets_outlined;
}

_ToppingRecord _buildLiveToppingRecord(
  Map<String, dynamic> json, {
  required Map<String, String> categoryNameById,
}) {
  final modifierId = (json['modifier_id'] ?? '').toString();
  final categoryName =
      categoryNameById[(json['items_cat'] ?? '').toString()] ?? 'غير مصنف';
  final imageValue = (json['image_url'] ?? '').toString().trim();
  return _ToppingRecord(
    modifierId.isEmpty ? 'TOP-UNKNOWN' : 'TOP-$modifierId',
    _normalizeUtf8Text(_firstText([json['name_ar'], json['name_en'], 'إضافة'])),
    _normalizeUtf8Text(_firstText([json['store_name'], 'مطعم'])),
    _normalizeUtf8Text(_firstText([json['group_name_ar'], categoryName])),
    '${_formatUserWholeNumber(_parseMasterDouble(json['price_delta']))} ${MasterCurrency.symbol}',
    _toInt(json['is_required']) == 1 ? 'إجباري' : 'اختياري',
    _toInt(json['min_select']),
    _toInt(json['max_select'], 1),
    _toInt(json['is_active'], 1) == 1,
    _toInt(json['is_active'], 1) == 1 ? 'نشط' : 'مخفي',
    _masterModifierImageUrl(imageValue),
    nameEn: (json['name_en'] ?? '').toString(),
    imageName: imageValue,
    priceValue: _parseMasterDouble(json['price_delta']),
    groupId: _toInt(json['group_id']),
    groupType:
        (json['group_type'] ?? '').toString().toLowerCase() == 'ingredient'
        ? 'مكونات'
        : 'إضافات',
  );
}

String _masterModifierImageUrl(String value) {
  final image = value.trim();
  if (image.isEmpty) return '';
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }
  final cleaned = image.replaceFirst(RegExp(r'^/?roaq/'), '');
  if (cleaned.startsWith('uploud/') || cleaned.startsWith('uploads/')) {
    return _masterMediaUrl(cleaned);
  }
  return _masterMediaUrl('uploud/modifier_options/$cleaned');
}

_OfferRecord _buildLiveOfferRecord(
  Map<String, dynamic> json,
  Map<String, String> restaurantNameById,
) {
  final id = (json['banner_id'] ?? json['id'] ?? '').toString();
  final vendorId = (json['vendor_id'] ?? '').toString();
  final title = _normalizeUtf8Text(
    _firstText([json['title_ar'], json['title_en'], 'عرض مطعم']),
  );
  final imageValue = (json['image_url'] ?? '').toString().trim();
  final startDate = _firstText([json['starts_at'], json['created_at'], '-']);
  final endDate = _firstText([json['ends_at'], '-']);
  final isActive = _toInt(json['is_active'], 1) == 1;
  return _OfferRecord(
    id.isEmpty ? 'OFF-UNKNOWN' : 'OFF-$id',
    title,
    _normalizeUtf8Text(_firstText([restaurantNameById[vendorId], 'المنصة'])),
    _normalizeUtf8Text(_firstText([json['target_type'], 'عرض'])),
    _normalizeUtf8Text(
      _firstText([json['subtitle_ar'], json['subtitle_en'], '-']),
    ),
    isActive ? 'نشط' : 'مخفي',
    startDate,
    endDate,
    'التطبيق',
    _normalizeUtf8Text(
      _firstText([json['subtitle_ar'], json['subtitle_en'], '-']),
    ),
    imageValue.isEmpty ? '' : _masterMediaUrl(imageValue),
    _toInt(json['sort_order']),
  );
}

_CouponRecord _buildLiveCouponRecord(Map<String, dynamic> json) {
  final count = _toInt(json['coupon_count']);
  final discount = _toInt(json['coupon_discount']);
  final expireDate = _firstText([json['coupon_expiredate'], '-']);
  return _CouponRecord(
    (json['coupon_id'] ?? '').toString(),
    _normalizeUtf8Text(_firstText([json['coupon_name'], '-'])),
    'المنصة',
    'نسبة مئوية',
    '${_toInt(json['coupon_discount'])}%',
    '0 ${MasterCurrency.symbol}',
    '-',
    expireDate,
    '$count استخدام',
    count > 0 ? 'نشط' : 'مستهلك',
    '',
    discountPercent: discount,
    usageCount: count,
    expireDate: expireDate,
  );
}

class _MenuSectionRecord {
  const _MenuSectionRecord(this.name, this.count, this.status, this.icon);

  final String name;
  final int count;
  final String status;
  final IconData icon;
}

class _CategoryRecord {
  const _CategoryRecord(
    this.id,
    this.name,
    this.description,
    this.status,
    this.colorHex,
    this.restaurantsCount,
    this.productsCount,
    this.displayOrder,
    this.imageUrl,
    this.icon, {
    this.nameEn = '',
    this.imageName = '',
    this.vendorId = 0,
    this.categoryType = 'restaurant',
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final String colorHex;
  final int restaurantsCount;
  final int productsCount;
  final int displayOrder;
  final String imageUrl;
  final IconData icon;
  final String nameEn;
  final String imageName;
  final int vendorId;
  final String categoryType;
}

class _ProductRecord {
  const _ProductRecord(
    this.id,
    this.name,
    this.restaurant,
    this.section,
    this.price,
    this.discountedPrice,
    this.orderType,
    this.status,
    this.orders,
    this.rating,
    this.imageUrl, {
    this.nameEn = '',
    this.description = '',
    this.descriptionEn = '',
    this.imageName = '',
    this.priceValue = 0,
    this.discountPercent = 0,
    this.stockCount = 0,
    this.categoryId = 0,
    this.vendorId = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String restaurant;
  final String section;
  final String price;
  final String discountedPrice;
  final String orderType;
  final String status;
  final int orders;
  final double rating;
  final String imageUrl;
  final String nameEn;
  final String description;
  final String descriptionEn;
  final String imageName;
  final double priceValue;
  final int discountPercent;
  final int stockCount;
  final int categoryId;
  final int vendorId;
  final bool active;
}

class _ToppingRecord {
  const _ToppingRecord(
    this.id,
    this.name,
    this.restaurant,
    this.section,
    this.price,
    this.type,
    this.minChoice,
    this.maxChoice,
    this.enabled,
    this.status,
    this.imageUrl, {
    this.nameEn = '',
    this.imageName = '',
    this.priceValue = 0,
    this.groupId = 0,
    this.groupType = 'إضافات',
  });

  final String id;
  final String name;
  final String restaurant;
  final String section;
  final String price;
  final String type;
  final int minChoice;
  final int maxChoice;
  final bool enabled;
  final String status;
  final String imageUrl;
  final String nameEn;
  final String imageName;
  final double priceValue;
  final int groupId;
  final String groupType;
}

class _OfferRecord {
  const _OfferRecord(
    this.id,
    this.name,
    this.restaurant,
    this.discountType,
    this.minOrder,
    this.status,
    this.startDate,
    this.endDate,
    this.channel,
    this.discountValue,
    this.imageUrl,
    this.performanceOrders,
  );

  final String id;
  final String name;
  final String restaurant;
  final String discountType;
  final String minOrder;
  final String status;
  final String startDate;
  final String endDate;
  final String channel;
  final String discountValue;
  final String imageUrl;
  final int performanceOrders;
}

class _CouponRecord {
  const _CouponRecord(
    this.id,
    this.code,
    this.restaurant,
    this.type,
    this.value,
    this.minOrder,
    this.startDate,
    this.endDate,
    this.uses,
    this.status,
    this.imageUrl, {
    this.discountPercent = 0,
    this.usageCount = 0,
    this.expireDate = '',
  });

  final String id;
  final String code;
  final String restaurant;
  final String type;
  final String value;
  final String minOrder;
  final String startDate;
  final String endDate;
  final String uses;
  final String status;
  final String imageUrl;
  final int discountPercent;
  final int usageCount;
  final String expireDate;
}

int _moneyFromLabel(String label) {
  final cleaned = label.replaceAll(RegExp(r'[^\d.-]'), '');
  return double.tryParse(cleaned)?.round() ?? 0;
}

String _formatRestaurantInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

List<_OperationsStatCardData> _buildRestaurantStatCards(
  _RestaurantManagementSeed seed,
  String activeSubPage,
) {
  final activeCategories = seed.categories
      .where((category) => category.status == 'نشط')
      .length;
  final hiddenCategories = seed.categories.length - activeCategories;
  final activeProducts = seed.products
      .where((product) => product.status == 'نشط')
      .length;
  final hiddenProducts = seed.products.length - activeProducts;
  final soldOutProducts = seed.products
      .where((product) => product.status.contains('نفد'))
      .length;
  final topProducts = seed.products
      .where((product) => product.orders > 0)
      .length;
  final activeRestaurants = seed.restaurants
      .where((restaurant) => restaurant.status == 'نشط')
      .length;
  final reviewRestaurants = seed.restaurants
      .where((restaurant) => restaurant.status == 'قيد المراجعة')
      .length;
  final suspendedRestaurants = seed.restaurants
      .where((restaurant) => restaurant.status == 'معلق')
      .length;
  final closedRestaurants =
      seed.restaurants.length -
      activeRestaurants -
      reviewRestaurants -
      suspendedRestaurants;
  final todayOrders = seed.restaurants.fold<int>(
    0,
    (sum, restaurant) => sum + restaurant.todayOrders,
  );
  final activeToppings = seed.toppings
      .where((topping) => topping.enabled)
      .length;
  final requiredToppings = seed.toppings
      .where((topping) => topping.type.contains('إجباري'))
      .length;
  final optionalToppings = seed.toppings.length - requiredToppings;
  final toppingsValue = seed.toppings.fold<int>(
    0,
    (sum, topping) => sum + _moneyFromLabel(topping.price),
  );
  final activeOffers = seed.offers
      .where((offer) => offer.status == 'نشط')
      .length;
  final scheduledOffers = seed.offers
      .where((offer) => offer.status == 'مجدول')
      .length;
  final stoppedOffers = seed.offers
      .where((offer) => offer.status == 'متوقف' || offer.status == 'منتهي')
      .length;
  final hiddenOffers =
      seed.offers.length - activeOffers - scheduledOffers - stoppedOffers;
  final offerDiscountTotal = seed.offers.fold<int>(
    0,
    (sum, offer) => sum + _moneyFromLabel(offer.discountValue),
  );
  final couponRestaurants = seed.coupons
      .map((coupon) => coupon.restaurant)
      .where((restaurant) => restaurant.trim().isNotEmpty)
      .toSet()
      .length;
  final activeCoupons = seed.coupons
      .where((coupon) => coupon.status == 'نشط')
      .length;
  final expiredCoupons = seed.coupons
      .where((coupon) => coupon.status == 'منتهي')
      .length;
  final scheduledCoupons = seed.coupons
      .where((coupon) => coupon.status == 'مجدول')
      .length;
  final hiddenCoupons =
      seed.coupons.length - activeCoupons - expiredCoupons - scheduledCoupons;
  final couponDiscountTotal = seed.coupons.fold<int>(
    0,
    (sum, coupon) => sum + _moneyFromLabel(coupon.value),
  );
  switch (activeSubPage) {
    case 'menus':
      return [
        _miniStat(
          'المنتجات المخفية',
          '$hiddenProducts',
          Icons.visibility_off_outlined,
          const Color(0xFF9CA3AF),
          const Color(0xFFF3F4F6),
          'منتج',
          'عن أمس -2%',
          false,
        ),
        _miniStat(
          'المنتجات الظاهرة',
          '$activeProducts',
          Icons.visibility_outlined,
          const Color(0xFFEF4444),
          const Color(0xFFFDECEC),
          'منتج',
          '',
          true,
        ),
        _miniStat(
          'المنتجات الأكثر طلباً',
          '$topProducts',
          Icons.star_border_rounded,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'منتج',
          '',
          true,
        ),
        _miniStat(
          'إجمالي الإضافات',
          '${seed.toppings.length}',
          Icons.token_outlined,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'إضافة',
          '',
          true,
        ),
        _miniStat(
          'إجمالي المنتجات',
          '${seed.products.length}',
          Icons.table_rows_outlined,
          const Color(0xFF60A5FA),
          const Color(0xFFEAF3FF),
          'منتج',
          '',
          true,
        ),
        _miniStat(
          'إجمالي الأقسام',
          '${seed.menuSections.length}',
          Icons.category_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'قسم',
          '',
          true,
        ),
      ];
    case 'categories':
      return [
        _miniStat(
          'المنتجات تحت التصنيفات',
          '${seed.products.length}',
          Icons.star_border_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'منتج',
          'عن أمس +16%',
          true,
        ),
        _miniStat(
          'تستخدم في المطاعم',
          '${seed.restaurants.length}',
          Icons.reorder_outlined,
          const Color(0xFF60A5FA),
          const Color(0xFFEAF3FF),
          'تصنيف',
          'عن أمس +18%',
          true,
        ),
        _miniStat(
          'تصنيفات مخفية',
          '$hiddenCategories',
          Icons.visibility_off_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'تصنيفات',
          'عن أمس -20%',
          false,
        ),
        _miniStat(
          'تصنيفات نشطة',
          '$activeCategories',
          Icons.check_circle_outline,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'تصنيف',
          'عن أمس +14%',
          true,
        ),
        _miniStat(
          'إجمالي التصنيفات',
          '${seed.categories.length}',
          Icons.widgets_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'تصنيف',
          'عن أمس +16%',
          true,
        ),
      ];
    case 'products':
      return [
        _miniStat(
          'إجمالي قيمة المنتجات',
          '${seed.products.length}',
          Icons.paid_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'منتج',
          '',
          true,
        ),
        _miniStat(
          'الأكثر طلباً اليوم',
          '$topProducts',
          Icons.star_border_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'منتج',
          '',
          true,
        ),
        _miniStat(
          'منتجات نفدت',
          '$soldOutProducts',
          Icons.reorder_outlined,
          const Color(0xFF60A5FA),
          const Color(0xFFEAF3FF),
          'منتج',
          'عن أمس -8%',
          false,
        ),
        _miniStat(
          'المنتجات المخفية',
          '$hiddenProducts',
          Icons.visibility_off_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'منتج',
          'عن أمس -12%',
          false,
        ),
        _miniStat(
          'المنتجات النشطة',
          '$activeProducts',
          Icons.check_circle_outline,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'منتج',
          'عن أمس +16%',
          true,
        ),
        _miniStat(
          'إجمالي المنتجات',
          '${seed.products.length}',
          Icons.inventory_2_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'منتج',
          'عن أمس +18%',
          true,
        ),
      ];
    case 'toppings':
      return [
        _miniStat(
          'إجمالي قيمة الإضافات',
          _formatRestaurantInt(toppingsValue),
          Icons.paid_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          '${MasterCurrency.symbol}',
          'عن أمس +18%',
          true,
        ),
        _miniStat(
          'إضافات اختيارية',
          '$optionalToppings',
          Icons.format_list_bulleted_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'إضافة',
          'عن أمس +15%',
          true,
        ),
        _miniStat(
          'إضافات إلزامية',
          '$requiredToppings',
          Icons.star_border_rounded,
          const Color(0xFF3B82F6),
          const Color(0xFFEAF3FF),
          'إضافة',
          'عن أمس +9%',
          true,
        ),
        _miniStat(
          'إضافات معطلة',
          '${seed.toppings.length - activeToppings}',
          Icons.visibility_off_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'إضافة',
          'عن أمس -12%',
          false,
        ),
        _miniStat(
          'إضافات مفعلة',
          '$activeToppings',
          Icons.check_circle_outline,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'إضافة',
          'عن أمس +16%',
          true,
        ),
        _miniStat(
          'إجمالي الإضافات',
          '${seed.toppings.length}',
          Icons.tune_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'إضافة',
          'عن أمس +14%',
          true,
        ),
      ];
    case 'offers':
      return [
        _miniStat(
          'إجمالي الخصم',
          _formatRestaurantInt(offerDiscountTotal),
          Icons.paid_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          '${MasterCurrency.symbol}',
          'عن أمس +25%',
          true,
        ),
        _miniStat(
          'المطاعم المشاركة',
          '${seed.offers.map((offer) => offer.restaurant).toSet().length}',
          Icons.shopping_bag_outlined,
          const Color(0xFF60A5FA),
          const Color(0xFFEAF3FF),
          'مطعم',
          'عن أمس +22%',
          true,
        ),
        _miniStat(
          'عروض مخفية',
          '$hiddenOffers',
          Icons.visibility_off_outlined,
          const Color(0xFF9CA3AF),
          const Color(0xFFF3F4F6),
          'عروض',
          'عن أمس -5%',
          false,
        ),
        _miniStat(
          'عروض متوقفة',
          '$stoppedOffers',
          Icons.pause_circle_outline,
          const Color(0xFFEF4444),
          const Color(0xFFFDECEC),
          'عروض',
          'عن أمس -10%',
          false,
        ),
        _miniStat(
          'عروض مجدولة',
          '$scheduledOffers',
          Icons.watch_later_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'عروض',
          'عن أمس -12%',
          false,
        ),
        _miniStat(
          'عروض نشطة',
          '$activeOffers',
          Icons.check_circle_outline,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'عرض',
          'عن أمس +18%',
          true,
        ),
        _miniStat(
          'إجمالي العروض',
          '${seed.offers.length}',
          Icons.local_offer_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'عرض',
          'عن أمس +20%',
          true,
        ),
      ];
    case 'coupons':
      return [
        _miniStat(
          'المطاعم التي تستخدم كوبونات',
          '$couponRestaurants',
          Icons.shopping_bag_outlined,
          const Color(0xFF60A5FA),
          const Color(0xFFEAF3FF),
          'مطعم',
          '',
          true,
        ),
        _miniStat(
          'إجمالي الخصومات',
          _formatRestaurantInt(couponDiscountTotal),
          Icons.paid_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          '${MasterCurrency.symbol}',
          'عن أمس +25%',
          true,
        ),
        _miniStat(
          'مخفية',
          '$hiddenCoupons',
          Icons.visibility_off_outlined,
          const Color(0xFF9CA3AF),
          const Color(0xFFF3F4F6),
          'كوبونات',
          'عن أمس -5%',
          false,
        ),
        _miniStat(
          'كوبونات منتهية',
          '$expiredCoupons',
          Icons.pause_circle_outline,
          const Color(0xFFEF4444),
          const Color(0xFFFDECEC),
          'كوبون',
          'عن أمس -15%',
          false,
        ),
        _miniStat(
          'كوبونات مجدولة',
          '$scheduledCoupons',
          Icons.watch_later_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'كوبون',
          'عن أمس -8%',
          false,
        ),
        _miniStat(
          'كوبونات نشطة',
          '$activeCoupons',
          Icons.check_circle_outline,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'كوبون',
          'عن أمس +22%',
          true,
        ),
        _miniStat(
          'إجمالي الكوبونات',
          '${seed.coupons.length}',
          Icons.confirmation_number_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'كوبون',
          'عن أمس +18%',
          true,
        ),
      ];
    case 'all':
    default:
      return [
        _miniStat(
          'طلبات اليوم',
          _formatRestaurantInt(todayOrders),
          Icons.shopping_bag_outlined,
          const Color(0xFF60A5FA),
          const Color(0xFFEAF3FF),
          'طلب',
          'عن أمس +21%',
          true,
        ),
        _miniStat(
          'مغلقة',
          '$closedRestaurants',
          Icons.close_rounded,
          const Color(0xFF9CA3AF),
          const Color(0xFFF3F4F6),
          'مطاعم',
          'عن أمس -5%',
          false,
        ),
        _miniStat(
          'مغلقة مؤقتاً',
          '$suspendedRestaurants',
          Icons.pause_circle_outline,
          const Color(0xFFEF4444),
          const Color(0xFFFDECEC),
          'مطاعم',
          'عن أمس -12%',
          false,
        ),
        _miniStat(
          'قيد المراجعة',
          '$reviewRestaurants',
          Icons.watch_later_outlined,
          const Color(0xFFF59E0B),
          const Color(0xFFFFF3DF),
          'مطعم',
          'عن أمس -8%',
          false,
        ),
        _miniStat(
          'المطاعم النشطة',
          '$activeRestaurants',
          Icons.check_circle_outline,
          const Color(0xFF22C55E),
          const Color(0xFFEAF7EE),
          'مطعم',
          'عن أمس +15%',
          true,
        ),
        _miniStat(
          'إجمالي المطاعم',
          '${seed.restaurants.length}',
          Icons.storefront_outlined,
          const Color(0xFF16A34A),
          const Color(0xFFEAF7EE),
          'مطعم',
          'عن أمس +18%',
          true,
        ),
      ];
  }
}

_OperationsStatCardData _miniStat(
  String title,
  String value,
  IconData icon,
  Color accent,
  Color background,
  String detailLine,
  String trendCaption,
  bool positive,
) {
  return _OperationsStatCardData(
    title: title,
    value: value,
    icon: icon,
    accent: accent,
    background: background,
    detailLine: detailLine,
    trendLabel: trendCaption.isEmpty ? '' : trendCaption.split(' ').last,
    trendCaption: trendCaption.isEmpty ? '' : trendCaption,
    trendPositive: positive,
  );
}

String _restaurantAddButtonLabel(String key) {
  return switch (key) {
    'menus' => 'إضافة قسم',
    'categories' => 'إضافة تصنيف',
    'store_specialties' => 'إضافة تخصص متجر',
    'products' => 'إضافة منتج',
    'toppings' => 'إضافة إضافة',
    'offers' => 'إضافة عرض جديد',
    'coupons' => 'إضافة كوبون جديد',
    _ => 'إضافة مطعم',
  };
}

int _restaurantRecordId(String value) {
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

Future<void> _showRestaurantEditDialog(
  BuildContext context, {
  required String title,
  required String name,
  required String entity,
  required int id,
}) {
  final pageState = context
      .findAncestorStateOfType<_MasterRestaurantsPageState>();
  if (pageState != null && id > 0) {
    if (entity == 'product') return pageState._editProductById(title, id);
    if (entity == 'category') return pageState._editCategoryById(title, id);
    if (entity == 'topping') return pageState._editToppingById(title, id);
    if (entity == 'coupon') return pageState._editCouponById(title, id);
  }
  final controller = TextEditingController(text: name);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (pageState == null || id <= 0) {
                _showMasterSnack(context, 'تعذر تحديد السجل المطلوب');
                return;
              }
              await pageState._saveRestaurantEntity(
                entity: entity,
                mode: 'update',
                id: id,
                label: title,
                data: {'name': controller.text.trim()},
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

class _RestaurantFiltersBar extends StatelessWidget {
  const _RestaurantFiltersBar({
    required this.activeSubPage,
    required this.searchController,
    required this.onSubmitted,
    required this.primaryFilter,
    required this.statusFilter,
    required this.groupFilter,
    required this.vendorTypeFilter,
    required this.onPrimaryChanged,
    required this.onStatusChanged,
    required this.onGroupChanged,
    required this.onVendorTypeChanged,
    required this.onAdd,
    required this.onAdvancedFilter,
  });

  final String activeSubPage;
  final TextEditingController searchController;
  final VoidCallback onSubmitted;
  final String primaryFilter;
  final String statusFilter;
  final String groupFilter;
  final String vendorTypeFilter;
  final ValueChanged<String> onPrimaryChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<String> onVendorTypeChanged;
  final VoidCallback onAdd;
  final VoidCallback onAdvancedFilter;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = switch (activeSubPage) {
      'menus' => 'إضافة قسم',
      'categories' => 'إضافة تصنيف',
      'products' => 'إضافة منتج',
      'toppings' => 'إضافة إضافة جديدة',
      'offers' => 'إضافة عرض جديد',
      'coupons' => 'إضافة كوبون جديد',
      _ => 'إضافة مطعم',
    };
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
          if (activeSubPage != 'offers') ...[
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B8F4D),
                foregroundColor: Colors.white,
                minimumSize: const Size(138, 44),
              ),
            ),
            const SizedBox(width: 10),
          ],
          _OrdersFilterButton(
            label: _ordersFilterLabel(vendorTypeFilter, const {
              'all': 'All activities',
              'restaurant': 'Restaurants',
              'store': 'Stores',
            }),
            options: const {
              'all': 'All activities',
              'restaurant': 'Restaurants',
              'store': 'Stores',
            },
            onChanged: onVendorTypeChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: _ordersFilterLabel(primaryFilter, const {
              'all': 'جميع المطاعم',
              'featured': 'الأكثر نشاطاً',
              'inactive': 'المخفية',
            }),
            options: const {
              'all': 'جميع المطاعم',
              'featured': 'الأكثر نشاطاً',
              'inactive': 'المخفية',
            },
            onChanged: onPrimaryChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: _ordersFilterLabel(statusFilter, const {
              'all': 'جميع الحالات',
              'active': 'نشط',
              'paused': 'مغلق مؤقتاً',
              'hidden': 'مخفي',
            }),
            options: const {
              'all': 'جميع الحالات',
              'active': 'نشط',
              'paused': 'مغلق مؤقتاً',
              'hidden': 'مخفي',
            },
            onChanged: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: _ordersFilterLabel(groupFilter, {
              'all': activeSubPage == 'all' ? 'جميع المدن' : 'جميع الأقسام',
              'one': 'الخيار 1',
              'two': 'الخيار 2',
            }),
            options: const {
              'all': 'الكل',
              'one': 'الخيار 1',
              'two': 'الخيار 2',
            },
            onChanged: onGroupChanged,
          ),
          const SizedBox(width: 8),
          if (activeSubPage == 'all' ||
              activeSubPage == 'products' ||
              activeSubPage == 'offers' ||
              activeSubPage == 'coupons') ...[
            OutlinedButton.icon(
              onPressed: onAdvancedFilter,
              icon: const Icon(Icons.filter_alt_outlined, size: 16),
              label: const Text('تصفية متقدمة'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(126, 42)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _DeliverySearchBox(
              controller: searchController,
              hint: _searchHint(activeSubPage),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

String _searchHint(String key) {
  switch (key) {
    case 'menus':
      return 'ابحث عن منتج أو قسم...';
    case 'categories':
      return 'ابحث عن تصنيف...';
    case 'products':
      return 'ابحث عن منتج أو اسم أو كود...';
    case 'toppings':
      return 'ابحث عن إضافة...';
    case 'offers':
      return 'ابحث عن عرض أو مطعم...';
    case 'coupons':
      return 'ابحث عن كوبون...';
    case 'all':
    default:
      return 'ابحث عن مطعم بالاسم أو المالك أو الهاتف...';
  }
}

void _showRestaurantActions(
  BuildContext context, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل بيانات المطعم'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
              ),
              title: const Text(
                'حذف المطعم',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _RestaurantsAllWorkspace extends StatelessWidget {
  const _RestaurantsAllWorkspace({
    required this.seed,
    required this.selectedRestaurantIndex,
    required this.onRestaurantSelected,
    required this.onEditRestaurant,
    required this.onDeleteRestaurant,
  });

  final _RestaurantManagementSeed seed;
  final int selectedRestaurantIndex;
  final ValueChanged<int> onRestaurantSelected;
  final ValueChanged<_RestaurantProfile> onEditRestaurant;
  final ValueChanged<_RestaurantProfile> onDeleteRestaurant;

  @override
  Widget build(BuildContext context) {
    if (seed.restaurants.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد مطاعم',
        description: 'ستظهر هنا قائمة المطاعم بمجرد وصولها من قاعدة البيانات.',
        icon: Icons.storefront_outlined,
      );
    }
    final safeSelectedRestaurantIndex =
        selectedRestaurantIndex >= seed.restaurants.length
        ? seed.restaurants.length - 1
        : selectedRestaurantIndex;
    final selected = seed.restaurants[safeSelectedRestaurantIndex];
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'قائمة المطاعم (${seed.restaurants.length})',
            child: Column(
              children: [
                const _RestaurantTableHeader(
                  columns: [
                    (18, 'المطعم'),
                    (12, 'المنطقة'),
                    (10, 'المدينة'),
                    (12, 'الحالة'),
                    (14, 'طلبات اليوم'),
                    (14, 'متوسط وقت التحضير'),
                    (10, 'التقييم'),
                    (10, 'الإجراءات'),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: seed.restaurants.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = seed.restaurants[index];
                      final selectedRow = index == safeSelectedRestaurantIndex;
                      return InkWell(
                        onTap: () => onRestaurantSelected(index),
                        child: Container(
                          height: 64,
                          color: selectedRow
                              ? const Color(0xFFF0F9F5)
                              : Colors.transparent,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _OrdersTableCell(
                                flex: 18,
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    _ImageThumb(url: item.logoUrl, size: 40),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _OrdersTwoLine(
                                        title: item.name,
                                        subtitle: item.subtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 12,
                                child: Text(
                                  item.zone,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  item.city,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 12,
                                child: _statusPill(item.status),
                              ),
                              _OrdersTableCell(
                                flex: 14,
                                child: Text(
                                  '${item.todayOrders}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 14,
                                child: Text(
                                  '${item.averagePrepMinutes} دقيقة',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  '${item.rating}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _MiniIconButton(
                                        icon: Icons.more_vert_rounded,
                                        tooltip: 'إجراءات',
                                        onTap: () => _showRestaurantActions(
                                          context,
                                          onEdit: () => onEditRestaurant(item),
                                          onDelete: () =>
                                              onDeleteRestaurant(item),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      _MiniIconButton(
                                        icon: Icons.edit_outlined,
                                        tooltip: 'تعديل',
                                        onTap: () => onEditRestaurant(item),
                                      ),
                                      const SizedBox(width: 2),
                                      _MiniIconButton(
                                        icon: Icons.visibility_outlined,
                                        tooltip: 'عرض',
                                        onTap: () =>
                                            onRestaurantSelected(index),
                                      ),
                                    ],
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
        const SizedBox(width: 8),
        SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: _RestaurantDetailsPanel(profile: selected),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190,
                  child: _RestaurantCoverageMapCard(profile: selected),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 176,
                  child: _RestaurantQuickActionsCard(
                    profile: selected,
                    onEdit: () => onEditRestaurant(selected),
                    onDelete: () => onDeleteRestaurant(selected),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RestaurantMenusWorkspace extends StatelessWidget {
  const _RestaurantMenusWorkspace({
    required this.seed,
    required this.selectedSectionIndex,
    required this.onSectionSelected,
    required this.onToggleProductStatus,
    required this.onDeleteProduct,
  });

  final _RestaurantManagementSeed seed;
  final int selectedSectionIndex;
  final ValueChanged<int> onSectionSelected;
  final ValueChanged<_ProductRecord> onToggleProductStatus;
  final ValueChanged<_ProductRecord> onDeleteProduct;

  @override
  Widget build(BuildContext context) {
    if (seed.menuSections.isEmpty || seed.products.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد أقسام أو منتجات',
        description:
            'ستظهر هنا أقسام القائمة ومنتجاتها بمجرد وصولها من قاعدة البيانات.',
        icon: Icons.menu_book_outlined,
      );
    }
    final safeSelectedSectionIndex =
        selectedSectionIndex >= seed.menuSections.length
        ? seed.menuSections.length - 1
        : selectedSectionIndex;
    final section = seed.menuSections[safeSelectedSectionIndex];
    final sectionProducts = seed.products
        .where((product) => product.section == section.name)
        .toList();
    final selectedProduct = sectionProducts.isEmpty
        ? seed.products.first
        : sectionProducts.first;
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 270,
          child: _RestaurantShellCard(
            title: 'الأقسام (${seed.menuSections.length})',
            child: ListView.separated(
              itemCount: seed.menuSections.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = seed.menuSections[index];
                final selected = index == safeSelectedSectionIndex;
                return InkWell(
                  onTap: () => onSectionSelected(index),
                  child: Container(
                    color: selected
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF4F6FA),
                          child: Icon(
                            item.icon,
                            color: const Color(0xFF0B8F4D),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OrdersTwoLine(
                            title: item.name,
                            subtitle: '${item.count} منتج',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            _statusPill(item.status),
                            const SizedBox(height: 6),
                            const Icon(Icons.visibility_outlined, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RestaurantShellCard(
            title: 'المنتجات',
            child: Column(
              children: [
                const _RestaurantTableHeader(
                  columns: [
                    (22, 'المنتج'),
                    (12, 'السعر'),
                    (10, 'الحالة'),
                    (10, 'التوفر'),
                    (10, 'الأكثر طلباً'),
                    (14, 'خيارات'),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: sectionProducts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = sectionProducts[index];
                      return SizedBox(
                        height: 62,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _OrdersTableCell(
                              flex: 22,
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  _ImageThumb(url: item.imageUrl, size: 44),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _OrdersTwoLine(
                                      title: item.name,
                                      subtitle: item.restaurant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 12,
                              child: Text(
                                item.price,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: _statusPill(item.status),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: _statusPill('متوفر'),
                            ),
                            _OrdersTableCell(
                              flex: 10,
                              child: Text(
                                '${item.rating}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _OrdersTableCell(
                              flex: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _MiniIconButton(
                                    icon: item.status == 'نشط'
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    tooltip: item.status == 'نشط'
                                        ? 'إخفاء'
                                        : 'تفعيل',
                                    onTap: () => onToggleProductStatus(item),
                                  ),
                                  const SizedBox(width: 2),
                                  _MiniIconButton(
                                    icon: Icons.edit_outlined,
                                    tooltip: 'تعديل',
                                    onTap: () => _showRestaurantEditDialog(
                                      context,
                                      title: 'تعديل المنتج',
                                      name: item.name,
                                      entity: 'product',
                                      id: _restaurantRecordId(item.id),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  _MiniIconButton(
                                    icon: Icons.delete_outline,
                                    tooltip: 'حذف',
                                    onTap: () => onDeleteProduct(item),
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
        const SizedBox(width: 8),
        SizedBox(
          width: 312,
          child: _MenuProductDetailsPanel(
            section: section,
            product: selectedProduct,
            toppings: seed.toppings.take(5).toList(),
            onToggleStatus: () => onToggleProductStatus(selectedProduct),
            onDelete: () => onDeleteProduct(selectedProduct),
          ),
        ),
      ],
    );
  }
}

class _RestaurantCategoriesWorkspace extends StatelessWidget {
  const _RestaurantCategoriesWorkspace({
    required this.seed,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
    required this.onToggleCategoryStatus,
    required this.onDeleteCategory,
  });

  final _RestaurantManagementSeed seed;
  final int selectedCategoryIndex;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<_CategoryRecord> onToggleCategoryStatus;
  final ValueChanged<_CategoryRecord> onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    if (seed.categories.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد تصنيفات',
        description:
            'ستظهر هنا التصنيفات الحقيقية عند وصولها من قاعدة البيانات.',
        icon: Icons.widgets_outlined,
      );
    }
    final safeSelectedCategoryIndex =
        selectedCategoryIndex >= seed.categories.length
        ? seed.categories.length - 1
        : selectedCategoryIndex;
    final selected = seed.categories[safeSelectedCategoryIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة التصنيفات (${seed.categories.length})',
      detail: _CategoryDetailsPanel(
        category: selected,
        onDelete: () => onDeleteCategory(selected),
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (18, 'التصنيف'),
              (18, 'الوصف'),
              (12, 'الأيقونة'),
              (12, 'اللون'),
              (12, 'عدد المطاعم'),
              (10, 'عدد الظهور'),
              (8, 'ترتيب'),
              (10, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: seed.categories.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = seed.categories[index];
                final selectedRow = safeSelectedCategoryIndex == index;
                return InkWell(
                  onTap: () => onCategorySelected(index),
                  child: Container(
                    height: 62,
                    color: selectedRow
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 18,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _ImageThumb(url: item.imageUrl, size: 38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
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
                          child: Icon(
                            item.icon,
                            color: _hexToColor(item.colorHex),
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.colorHex,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _hexToColor(item.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            '${item.restaurantsCount}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(item.status),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Text(
                            '${item.displayOrder}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: item.status == 'نشط'
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                tooltip: item.status == 'نشط'
                                    ? 'إخفاء'
                                    : 'تفعيل',
                                onTap: () => onToggleCategoryStatus(item),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => _showRestaurantEditDialog(
                                  context,
                                  title: 'تعديل التصنيف',
                                  name: item.name,
                                  entity: 'category',
                                  id: _restaurantRecordId(item.id),
                                ),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.visibility_outlined,
                                tooltip: 'عرض',
                                onTap: () => onCategorySelected(index),
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

class _RestaurantProductsWorkspace extends StatelessWidget {
  const _RestaurantProductsWorkspace({
    required this.seed,
    required this.selectedProductIndex,
    required this.onProductSelected,
    required this.onToggleProductStatus,
    required this.onDeleteProduct,
  });

  final _RestaurantManagementSeed seed;
  final int selectedProductIndex;
  final ValueChanged<int> onProductSelected;
  final ValueChanged<_ProductRecord> onToggleProductStatus;
  final ValueChanged<_ProductRecord> onDeleteProduct;

  @override
  Widget build(BuildContext context) {
    if (seed.products.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد منتجات',
        description:
            'ستظهر هنا المنتجات الحقيقية عند وصولها من قاعدة البيانات.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final safeSelectedProductIndex =
        selectedProductIndex >= seed.products.length
        ? seed.products.length - 1
        : selectedProductIndex;
    final selected = seed.products[safeSelectedProductIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة المنتجات (${seed.products.length})',
      detail: _ProductDetailsPanel(
        product: selected,
        onDelete: () => onDeleteProduct(selected),
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (20, 'المنتج'),
              (14, 'المطعم'),
              (12, 'القسم'),
              (12, 'السعر'),
              (12, 'نوع الطلب'),
              (10, 'الطلبات'),
              (10, 'الأكثر طلباً'),
              (10, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: seed.products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = seed.products[index];
                final selectedRow = safeSelectedProductIndex == index;
                return InkWell(
                  onTap: () => onProductSelected(index),
                  child: Container(
                    height: 62,
                    color: selectedRow
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 20,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _ImageThumb(url: item.imageUrl, size: 42),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OrdersTwoLine(
                                  title: item.name,
                                  subtitle: item.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Text(
                            item.restaurant,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.section,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(item.price, textAlign: TextAlign.center),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _statusPill(item.orderType),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            '${item.orders}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            '${item.rating}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: item.status == 'نشط'
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                tooltip: item.status == 'نشط'
                                    ? 'إخفاء'
                                    : 'تفعيل',
                                onTap: () => onToggleProductStatus(item),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => _showRestaurantEditDialog(
                                  context,
                                  title: 'تعديل المنتج',
                                  name: item.name,
                                  entity: 'product',
                                  id: _restaurantRecordId(item.id),
                                ),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.visibility_outlined,
                                tooltip: 'عرض',
                                onTap: () => onProductSelected(index),
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

class _RestaurantToppingsWorkspace extends StatelessWidget {
  const _RestaurantToppingsWorkspace({
    required this.seed,
    required this.selectedToppingIndex,
    required this.onToppingSelected,
    required this.onToggleToppingStatus,
    required this.onDeleteTopping,
  });

  final _RestaurantManagementSeed seed;
  final int selectedToppingIndex;
  final ValueChanged<int> onToppingSelected;
  final ValueChanged<_ToppingRecord> onToggleToppingStatus;
  final ValueChanged<_ToppingRecord> onDeleteTopping;

  @override
  Widget build(BuildContext context) {
    final safeSelectedToppingIndex =
        selectedToppingIndex >= seed.toppings.length
        ? seed.toppings.length - 1
        : selectedToppingIndex;
    final selected = seed.toppings[safeSelectedToppingIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة الإضافات (${seed.toppings.length})',
      detail: _ToppingDetailsPanel(
        topping: selected,
        onDelete: () => onDeleteTopping(selected),
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (18, 'الإضافة'),
              (14, 'المطعم'),
              (12, 'القسم'),
              (10, 'السعر'),
              (10, 'النوع'),
              (10, 'الحد الأقصى'),
              (10, 'الحد الأدنى'),
              (8, 'إلزامية'),
              (8, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: seed.toppings.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = seed.toppings[index];
                final selectedRow = safeSelectedToppingIndex == index;
                return InkWell(
                  onTap: () => onToppingSelected(index),
                  child: Container(
                    height: 62,
                    color: selectedRow
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 18,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _ImageThumb(url: item.imageUrl, size: 38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OrdersTwoLine(
                                  title: item.name,
                                  subtitle: item.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Text(
                            item.restaurant,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.section,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(item.price, textAlign: TextAlign.center),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(item.type),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            '${item.maxChoice}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            '${item.minChoice}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Icon(
                            item.enabled
                                ? Icons.check_circle
                                : Icons.remove_circle_outline,
                            color: item.enabled
                                ? _kPrimaryGreen
                                : const Color(0xFF9CA3AF),
                            size: 18,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: item.enabled
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                tooltip: item.enabled ? 'إخفاء' : 'تفعيل',
                                onTap: () => onToggleToppingStatus(item),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => _showRestaurantEditDialog(
                                  context,
                                  title: 'تعديل الإضافة',
                                  name: item.name,
                                  entity: 'topping',
                                  id: _restaurantRecordId(item.id),
                                ),
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

class _RestaurantOffersWorkspace extends StatelessWidget {
  const _RestaurantOffersWorkspace({
    required this.seed,
    required this.selectedOfferIndex,
    required this.onOfferSelected,
    required this.onToggleOfferStatus,
    required this.onDeleteOffer,
  });

  final _RestaurantManagementSeed seed;
  final int selectedOfferIndex;
  final ValueChanged<int> onOfferSelected;
  final ValueChanged<_OfferRecord> onToggleOfferStatus;
  final ValueChanged<_OfferRecord> onDeleteOffer;

  @override
  Widget build(BuildContext context) {
    final safeSelectedOfferIndex = selectedOfferIndex >= seed.offers.length
        ? seed.offers.length - 1
        : selectedOfferIndex;
    final selected = seed.offers[safeSelectedOfferIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة العروض (${seed.offers.length})',
      detail: _OfferDetailsPanel(
        offer: selected,
        onDelete: () => onDeleteOffer(selected),
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (18, 'العرض'),
              (14, 'المطعم'),
              (12, 'نوع العرض'),
              (12, 'الخصم'),
              (10, 'قناة الظهور'),
              (10, 'الفترة'),
              (10, 'الأداء'),
              (8, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: seed.offers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = seed.offers[index];
                final selectedRow = safeSelectedOfferIndex == index;
                return InkWell(
                  onTap: () => onOfferSelected(index),
                  child: Container(
                    height: 66,
                    color: selectedRow
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 18,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _ImageThumb(url: item.imageUrl, size: 42),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Text(
                            item.restaurant,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _statusPill(item.discountType),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            item.minOrder,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            item.channel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _OrdersTwoLine(
                            title: item.startDate,
                            subtitle: item.endDate,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            '${item.performanceOrders} طلب',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: item.status == 'نشط'
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                tooltip: item.status == 'نشط'
                                    ? 'إيقاف'
                                    : 'تفعيل',
                                onTap: () => onToggleOfferStatus(item),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => _showRestaurantEditDialog(
                                  context,
                                  title: 'تعديل العرض',
                                  name: item.name,
                                  entity: 'offer',
                                  id: _restaurantRecordId(item.id),
                                ),
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

class _RestaurantCouponsWorkspace extends StatelessWidget {
  const _RestaurantCouponsWorkspace({
    required this.seed,
    required this.selectedCouponIndex,
    required this.onCouponSelected,
    required this.onDeleteCoupon,
  });

  final _RestaurantManagementSeed seed;
  final int selectedCouponIndex;
  final ValueChanged<int> onCouponSelected;
  final ValueChanged<_CouponRecord> onDeleteCoupon;

  @override
  Widget build(BuildContext context) {
    final safeSelectedCouponIndex = selectedCouponIndex >= seed.coupons.length
        ? seed.coupons.length - 1
        : selectedCouponIndex;
    final selected = seed.coupons[safeSelectedCouponIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة كوبونات المطاعم (${seed.coupons.length})',
      detail: _CouponDetailsPanel(
        coupon: selected,
        onDelete: () => onDeleteCoupon(selected),
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (16, 'الكوبون'),
              (14, 'المطعم'),
              (10, 'النوع'),
              (10, 'قيمة الخصم'),
              (12, 'الحد الأدنى'),
              (14, 'تاريخ النهاية'),
              (12, 'الحالة'),
              (12, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: seed.coupons.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = seed.coupons[index];
                final selectedRow = safeSelectedCouponIndex == index;
                return InkWell(
                  onTap: () => onCouponSelected(index),
                  child: Container(
                    height: 66,
                    color: selectedRow
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFA7D7B8),
                              ),
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                const Icon(
                                  Icons.copy_outlined,
                                  size: 16,
                                  color: Color(0xFF0B8F4D),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.code,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0B8F4D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 14,
                          child: Text(
                            item.restaurant,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(item.type),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(item.value, textAlign: TextAlign.center),
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
                          child: _OrdersTwoLine(
                            title: item.startDate,
                            subtitle: item.endDate,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _statusPill(item.status),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'حذف',
                                onTap: () => onDeleteCoupon(item),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => _showRestaurantEditDialog(
                                  context,
                                  title: 'تعديل الكوبون',
                                  name: item.code,
                                  entity: 'coupon',
                                  id: _restaurantRecordId(item.id),
                                ),
                              ),
                              const SizedBox(width: 2),
                              _MiniIconButton(
                                icon: Icons.visibility_outlined,
                                tooltip: 'عرض',
                                onTap: () => onCouponSelected(index),
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

class _MasterDetailTableLayout extends StatelessWidget {
  const _MasterDetailTableLayout({
    required this.title,
    required this.child,
    required this.detail,
  });

  final String title;
  final Widget child;
  final Widget detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _RestaurantShellCard(title: title, child: child),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 330,
              child: SingleChildScrollView(
                child: SizedBox(
                  height: constraints.maxHeight < 650
                      ? 650
                      : constraints.maxHeight,
                  child: detail,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RestaurantDetailsPanel extends StatelessWidget {
  const _RestaurantDetailsPanel({required this.profile});

  final _RestaurantProfile profile;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المطعم',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _ImageThumb(url: profile.logoUrl, size: 58),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        profile.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.subtitle,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 10.4,
                          color: Color(0xFF6F7680),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _statusPill(profile.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _detailMetricCard(
                    'طلبات اليوم',
                    '${profile.todayOrders}',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _detailMetricCard('الإيرادات', profile.revenueLabel),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _detailMetricCard(
                    'متوسط التحضير',
                    '${profile.averagePrepMinutes} دقيقة',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _detailMetricCard('التقييم', '${profile.rating}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _detailLine(Icons.person_outline, 'صاحب المتجر', profile.owner),
            _detailLine(Icons.call_outlined, 'رقم الهاتف', profile.phone),
            _detailLine(Icons.place_outlined, 'العنوان', profile.address),
            _detailLine(
              Icons.map_outlined,
              'المناطق المغطاة',
              '${profile.coverageZones} مناطق',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCoverageMapCard extends StatelessWidget {
  const _RestaurantCoverageMapCard({required this.profile});

  final _RestaurantProfile profile;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'المناطق المغطاة',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _LiveOperationsMap(
          markers: [profile.marker],
          showWeatherBadge: false,
          showLayerPanel: false,
        ),
      ),
    );
  }
}

class _RestaurantQuickActionsCard extends StatelessWidget {
  const _RestaurantQuickActionsCard({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  final _RestaurantProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'الإجراءات السريعة',
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: [
            _actionButton(context, 'تعديل بيانات المطعم', Icons.edit_outlined),
            const SizedBox(height: 6),
            _actionButton(
              context,
              'حذف المطعم',
              Icons.delete_outline,
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon, {
    bool destructive = false,
    bool loading = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading
            ? null
            : onPressed ??
                  (icon == Icons.edit_outlined
                      ? onEdit
                      : icon == Icons.delete_outline
                      ? onDelete
                      : () => _showMasterSnack(
                          context,
                          '$label - ${profile.name}',
                        )),
        icon: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: destructive ? const Color(0xFFDC2626) : null),
        label: Text(
          label,
          style: TextStyle(color: destructive ? const Color(0xFFDC2626) : null),
        ),
        style: _compactDetailButtonStyle(destructive: destructive),
      ),
    );
  }
}

class _MenuProductDetailsPanel extends StatelessWidget {
  const _MenuProductDetailsPanel({
    required this.section,
    required this.product,
    required this.toppings,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final _MenuSectionRecord section;
  final _ProductRecord product;
  final List<_ToppingRecord> toppings;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المنتج',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _ImageThumb(url: product.imageUrl, size: 62),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(product.restaurant, textAlign: TextAlign.right),
                      const SizedBox(height: 4),
                      Text(
                        '${product.price} • ID: ${product.id}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _detailMetricCard('الأكثر طلباً', '#2')),
                const SizedBox(width: 6),
                Expanded(
                  child: _detailMetricCard('عدد الطلبات', '${product.orders}'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _detailMetricCard('التقييم', '${product.rating}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRestaurantEditDialog(
                  context,
                  title: 'تعديل المنتج',
                  name: product.name,
                  entity: 'product',
                  id: _restaurantRecordId(product.id),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onToggleStatus,
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('إخفاء'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFDC2626),
                ),
                label: const Text(
                  'حذف المنتج',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'الإضافات (5)',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: toppings.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = toppings[index];
                  return Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Color(0xFF6F7680),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.name, textAlign: TextAlign.right),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(value: index < 4, onChanged: null),
                    ],
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

class _CategoryDetailsPanel extends StatelessWidget {
  const _CategoryDetailsPanel({required this.category, required this.onDelete});

  final _CategoryRecord category;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل التصنيف',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _hexToColor(
                    category.colorHex,
                  ).withValues(alpha: 0.12),
                  child: Icon(
                    category.icon,
                    color: _hexToColor(category.colorHex),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        category.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _statusPill(category.status),
                      const SizedBox(height: 6),
                      Text(
                        category.description,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard(
                  'عدد المطاعم',
                  '${category.restaurantsCount}',
                ),
                _detailMetricCard('عدد المنتجات', '${category.productsCount}'),
                _detailMetricCard('ترتيب العرض', '${category.displayOrder}'),
                _detailMetricCard('لون التصنيف', category.colorHex),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRestaurantEditDialog(
                      context,
                      title: 'تعديل التصنيف',
                      name: category.name,
                      entity: 'category',
                      id: _restaurantRecordId(category.id),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل التصنيف'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف التصنيف',
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

class _ProductDetailsPanel extends StatelessWidget {
  const _ProductDetailsPanel({required this.product, required this.onDelete});

  final _ProductRecord product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المنتج',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(product.status),
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.id,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                      const SizedBox(height: 6),
                      Text(product.restaurant, textAlign: TextAlign.right),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ImageThumb(url: product.imageUrl, size: 68),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('القسم', product.section),
                _detailMetricCard('السعر', product.price),
                _detailMetricCard('السعر بعد الخصم', product.discountedPrice),
                _detailMetricCard('عدد الطلبات', '${product.orders}'),
                _detailMetricCard('التقييم', '${product.rating}'),
                _detailMetricCard('نوع الطلب', product.orderType),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRestaurantEditDialog(
                      context,
                      title: 'تعديل المنتج',
                      name: product.name,
                      entity: 'product',
                      id: _restaurantRecordId(product.id),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل المنتج'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف المنتج',
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

class _ToppingDetailsPanel extends StatelessWidget {
  const _ToppingDetailsPanel({required this.topping, required this.onDelete});

  final _ToppingRecord topping;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل الإضافة',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(topping.status),
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        topping.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topping.id,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                      const SizedBox(height: 6),
                      _statusPill(topping.type),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ImageThumb(url: topping.imageUrl, size: 58),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('القسم', topping.section),
                _detailMetricCard('نوع السعر', topping.price),
                _detailMetricCard('الحد الأدنى', '${topping.minChoice}'),
                _detailMetricCard('الحد الأقصى', '${topping.maxChoice}'),
                _detailMetricCard('عدد المنتجات', '48 منتج'),
                _detailMetricCard('آخر تحديث', '-'),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'الحالة والإعدادات',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const _SettingsLine('متاح في صفحة المنتج'),
            const _SettingsLine('يظهر في خيارات الطلب'),
            const _SettingsLine('يمكن اختيار أكثر من مرة'),
            const _SettingsLine('تؤثر على السعر'),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRestaurantEditDialog(
                      context,
                      title: 'تعديل الإضافة',
                      name: topping.name,
                      entity: 'topping',
                      id: _restaurantRecordId(topping.id),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل الإضافة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف الإضافة',
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

class _OfferDetailsPanel extends StatelessWidget {
  const _OfferDetailsPanel({required this.offer, required this.onDelete});

  final _OfferRecord offer;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل العرض',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(offer.status),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        offer.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(offer.restaurant, textAlign: TextAlign.right),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${offer.id}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ImageThumb(url: offer.imageUrl, size: 68),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('نوع العرض', offer.discountType),
                _detailMetricCard('قيمة الخصم', offer.discountValue),
                _detailMetricCard('الحد الأدنى للطلب', offer.minOrder),
                _detailMetricCard('قناة الظهور', offer.channel),
                _detailMetricCard('تاريخ البداية', offer.startDate),
                _detailMetricCard('تاريخ الانتهاء', offer.endDate),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRestaurantEditDialog(
                      context,
                      title: 'تعديل العرض',
                      name: offer.name,
                      entity: 'offer',
                      id: _restaurantRecordId(offer.id),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل العرض'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف العرض',
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

class _CouponDetailsPanel extends StatelessWidget {
  const _CouponDetailsPanel({required this.coupon, required this.onDelete});

  final _CouponRecord coupon;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل الكوبون',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(coupon.status),
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Container(
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFD6B8FF),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          coupon.code,
                          style: const TextStyle(
                            fontSize: 22,
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
                _ImageThumb(url: coupon.imageUrl, size: 68),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${coupon.value} خصم على جميع الطلبات',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'استمتع بخصم يصل على جميع أصناف المطعم',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF6F7680)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('النوع', coupon.type),
                _detailMetricCard('قيمة الخصم', coupon.value),
                _detailMetricCard('الحد الأدنى لطلب', coupon.minOrder),
                _detailMetricCard('الاستخدامات', '${coupon.uses} مرة'),
                _detailMetricCard('المطعم', coupon.restaurant),
                _detailMetricCard('تاريخ البداية', coupon.startDate),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRestaurantEditDialog(
                      context,
                      title: 'تعديل الكوبون',
                      name: coupon.code,
                      entity: 'coupon',
                      id: _restaurantRecordId(coupon.id),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل الكوبون'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف الكوبون',
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

class _RestaurantsRightSidebar extends StatelessWidget {
  const _RestaurantsRightSidebar({
    required this.activeSubPage,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onOrdersTap,
    required this.onLogisticsTap,
    required this.onUsersTap,
    required this.onFinanceTap,
    required this.onMarketingTap,
    required this.onAccessTap,
    required this.onCollapse,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLogisticsTap;
  final VoidCallback onUsersTap;
  final VoidCallback onFinanceTap;
  final VoidCallback onMarketingTap;
  final VoidCallback onAccessTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
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
                selected: true,
                onTap: () => onSubPageTap('all'),
              ),
              const SizedBox(height: 10),
              _RestaurantsSubMenu(
                activeSubPage: activeSubPage,
                onSubPageTap: onSubPageTap,
              ),
              const SizedBox(height: 12),
              _OperationsSidebarMainItem(
                label:
                    '\u0627\u0644\u0642\u0628\u0648\u0644 \u0648\u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0627\u062a',
                icon: Icons.how_to_reg_outlined,
                selected: false,
                onTap: onAccessTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMenuItem(
                data: const _OperationsSidebarTileData(
                  label: 'إدارة العملاء والمستخدمين',
                  icon: Icons.people_alt_outlined,
                ),
                onTap: onUsersTap,
              ),
              const SizedBox(height: 8),
              for (final item in const [
                _OperationsSidebarTileData(
                  label: 'الإدارة المالية',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'التسويق والنمو',
                  icon: Icons.campaign_outlined,
                ),
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
                    if (item.icon == Icons.account_balance_wallet_outlined) {
                      onFinanceTap();
                    } else if (item.icon == Icons.campaign_outlined) {
                      onMarketingTap();
                    } else if (item.icon ==
                        Icons.notifications_active_outlined) {
                      _navigateToRememberedMasterSection(
                        context,
                        'communication',
                      );
                    } else if (item.icon == Icons.query_stats_outlined) {
                      _navigateToRememberedMasterSection(context, 'reports');
                    } else if (item.icon == Icons.settings_outlined) {
                      _navigateToRememberedMasterSection(context, 'settings');
                    } else if (item.icon ==
                        Icons.admin_panel_settings_outlined) {
                      onAccessTap();
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

class _StoreSpecialtiesWorkspace extends StatelessWidget {
  const _StoreSpecialtiesWorkspace({
    required this.rows,
    required this.loading,
    this.error,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Map<String, dynamic>> rows;
  final bool loading;
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Expanded(
                  child: Text(
                    'تخصصات المتاجر',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة تخصص'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'إضافة وتعديل وحذف أنواع المتاجر المتاحة على المنصة.',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 18),
            if (error != null) ...[
              const Text(
                'تعذر الاتصال ببيانات تخصصات المتاجر.',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 6),
              Text(
                error!,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ] else if (rows.isEmpty)
              const Text('لا توجد تخصصات متاجر.', textAlign: TextAlign.right)
            else
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0EAE4)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          (row['name_ar'] ?? '').toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${(row['name_en'] ?? '').toString()}  •  ${(row['category_key'] ?? '').toString()}',
                          textAlign: TextAlign.right,
                        ),
                        leading: Wrap(
                          spacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: () => onEdit(row),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: _kPrimaryGreen,
                              ),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: () => onDelete(row),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
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
    );
  }
}

class _RestaurantsSubMenu extends StatelessWidget {
  const _RestaurantsSubMenu({
    required this.activeSubPage,
    required this.onSubPageTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all', 'جميع المطاعم', Icons.storefront_outlined),
      ('menus', 'قوائم الطعام', Icons.menu_book_outlined),
      ('categories', 'التصنيفات', Icons.widgets_outlined),
      ('store_specialties', 'تخصصات المتاجر', Icons.category_outlined),
      ('products', 'المنتجات', Icons.inventory_2_outlined),
      ('toppings', 'الإضافات (Toppings)', Icons.tune_rounded),
      ('offers', 'عروض المطاعم', Icons.local_offer_outlined),
      ('coupons', 'كوبونات المطاعم', Icons.confirmation_number_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Builder(
              builder: (context) {
                final selected = activeSubPage == items[i].$1;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSubPageTap(items[i].$1),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            items[i].$3,
                            size: 16,
                            color: selected
                                ? _kPrimaryGreen
                                : const Color(0xFF4E5660),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              items[i].$2,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  ),
                );
              },
            ),
            if (i != items.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _RestaurantShellCard extends StatelessWidget {
  const _RestaurantShellCard({
    required this.title,
    required this.child,
    this.expandChild = true,
  });

  final String title;
  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldExpand =
              expandChild &&
              constraints.hasBoundedHeight &&
              constraints.maxHeight.isFinite;
          return Column(
            mainAxisSize: shouldExpand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (shouldExpand) Expanded(child: child) else child,
            ],
          );
        },
      ),
    );
  }
}

class _RestaurantTableHeader extends StatelessWidget {
  const _RestaurantTableHeader({required this.columns});

  final List<(int, String)> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFFBFCFB),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (final column in columns)
            _OrdersTableCell(
              flex: column.$1,
              child: Text(
                column.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6F7680),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

ButtonStyle _compactDetailButtonStyle({bool destructive = false}) {
  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(34),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    textStyle: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
    visualDensity: VisualDensity.compact,
    side: BorderSide(
      color: destructive ? const Color(0xFFF5B5B5) : const Color(0xFFE7ECE8),
    ),
  );
}

Widget _detailMetricCard(String label, String value) {
  return Container(
    width: 128,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFBFCFD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE7ECE8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9.8, color: Color(0xFF6F7680)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

Widget _detailLine(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.5),
    child: Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6F7680)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 9.7, color: Color(0xFF6F7680)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _statusPill(String label) {
  Color fg = _kPrimaryGreen;
  Color bg = const Color(0xFFEAF7EE);
  if (label.contains('مؤقت') || label.contains('مجدول')) {
    fg = const Color(0xFFF59E0B);
    bg = const Color(0xFFFFF3DF);
  } else if (label.contains('مغلق') ||
      label.contains('معطل') ||
      label.contains('متوقف')) {
    fg = const Color(0xFFEF4444);
    bg = const Color(0xFFFDECEC);
  } else if (label.contains('مخفي')) {
    fg = const Color(0xFF9CA3AF);
    bg = const Color(0xFFF3F4F6);
  } else if (label.contains('نسبة') ||
      label.contains('ثابت') ||
      label.contains('توصيل') ||
      label.contains('استلام') ||
      label.contains('إجباري') ||
      label.contains('اختياري')) {
    fg = const Color(0xFF0B8F4D);
    bg = const Color(0xFFEAF7EE);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 9.6, fontWeight: FontWeight.w800, color: fg),
    ),
  );
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.url, this.size = 48});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF1F5F9),
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.fastfood_outlined),
      ),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  const _SettingsLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: _kPrimaryGreen,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10.6),
            ),
          ),
        ],
      ),
    );
  }
}
