// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

MasterSession? _rememberedMasterSession;
MasterAuthApiService? _rememberedMasterApi;
Future<void> Function()? _rememberedMasterLogout;

void _rememberMasterRuntime(
  MasterSession session,
  Future<void> Function() onLogout,
  MasterAuthApiService api,
) {
  _rememberedMasterSession = session;
  _rememberedMasterLogout = onLogout;
  _rememberedMasterApi = api;
}

/// Opens a top-level module from a legacy workspace sidebar while preserving
/// the same session, permission gate, and unified frame as the main sidebar.
void _navigateToRememberedMasterSection(BuildContext context, String key) {
  final session = _rememberedMasterSession;
  final api = _rememberedMasterApi;
  final onLogout = _rememberedMasterLogout;
  if (session == null || api == null || onLogout == null) {
    _showMasterSnack(context, 'أعد فتح لوحة الماستر ثم حاول مرة أخرى');
    return;
  }
  _navigateToMasterSection(
    context,
    key: key,
    session: session,
    onLogout: onLogout,
    api: api,
  );
}

void _openMasterSupportChats(BuildContext context, {DateTime? serverNow}) {
  final session = _rememberedMasterSession;
  final api = _rememberedMasterApi;
  final onLogout = _rememberedMasterLogout;
  if (session == null || api == null || onLogout == null) {
    _showMasterSnack(context, 'أعد فتح لوحة الماستر ثم حاول مرة أخرى');
    return;
  }
  if (!_masterSessionCanAccessModule(session, 'communication')) {
    _showMasterSnack(context, 'لا تملك صلاحية الوصول للدعم');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MasterSupportUnifiedPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      ),
    ),
  );
}

void _navigateToMasterSection(
  BuildContext context, {
  required String key,
  required MasterSession session,
  required Future<void> Function() onLogout,
  required MasterAuthApiService api,
  DateTime? serverNow,
  bool replace = true,
  String operationsSubSection = 'tracking',
  String restaurantsSubPage = 'all',
  String usersSubPage = 'users',
  String financeSubPage = 'wallets',
  String marketingSubPage = 'offers',
  String accessSubPage = 'overview',
}) {
  _rememberMasterRuntime(session, onLogout, api);
  final normalizedKey = key.trim().toLowerCase();
  if (!_masterCanOpenSection(session, normalizedKey)) {
    _showMasterSnack(context, 'ليس لديك صلاحية الوصول إلى هذا القسم');
    return;
  }
  final navigator = Navigator.of(context);
  if (normalizedKey == 'home') {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  final routeName = 'master:$normalizedKey';
  if (_masterRouteStack.contains(routeName)) {
    navigator.popUntil((route) => route.settings.name == routeName);
    return;
  }

  Widget? page;
  switch (normalizedKey) {
    case 'home':
      page = MasterDashboardPage(
        session: session,
        onLogout: onLogout,
        api: api,
      );
      break;
    case 'operations':
      page = MasterOperationsUnifiedPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
        initialSubSection: operationsSubSection,
      );
      break;
    case 'order':
    case 'orders':
    case 'order_management':
    case 'orders_management':
    case 'manage_orders':
      page = MasterOrdersPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
      );
      break;
    case 'delivery':
    case 'delivery_logistics':
    case 'logistics':
      page = MasterDeliveryLogisticsPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'restaurants':
      page = MasterRestaurantsPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
        initialSubPage: restaurantsSubPage,
        initialVendorType: 'restaurant',
      );
      break;
    case 'stores':
    case 'store':
      page = MasterRestaurantsPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
        initialSubPage: restaurantsSubPage,
        initialVendorType: 'store',
      );
      break;
    case 'users':
    case 'customers':
      page = MasterUsersPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
        initialSubPage: usersSubPage,
      );
      break;
    case 'finance':
      page = MasterFinancePage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
        initialSubPage: financeSubPage,
      );
      break;
    case 'support':
    case 'chat':
    case 'communication':
      page = MasterSupportUnifiedPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'marketing':
      page = MasterMarketingPage(
        session: session,
        onLogout: onLogout,
        api: api,
        unifiedFrame: true,
        serverNow: serverNow,
        initialSubPage: marketingSubPage,
      );
      break;
    case 'notifications':
      page = MasterNotificationsPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'reports':
      page = MasterReportsUnifiedPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'access':
    case 'administration':
    case 'governance':
    case 'quality':
    case 'settings':
      page = MasterAccessManagementPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
        initialSubPage:
            normalizedKey == 'access' ||
                normalizedKey == 'administration' ||
                normalizedKey == 'governance'
            ? accessSubPage
            : normalizedKey,
      );
      break;
  }

  if (page == null) {
    _showMasterSnack(context, 'هذا القسم غير متاح لهذا الحساب');
    return;
  }

  navigator.push(
    MaterialPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (_) => page!,
    ),
  );
}

bool _masterCanOpenSection(MasterSession session, String key) {
  return _masterSessionCanAccessModule(session, key);
}

void _navigateToDeliverySubPage(
  BuildContext context, {
  required String key,
  required MasterSession session,
  required Future<void> Function() onLogout,
  required MasterAuthApiService api,
  DateTime? serverNow,
}) {
  Widget? page;
  switch (key) {
    case 'drivers':
      page = MasterDeliveryLogisticsPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'dispatch':
      page = MasterDriverDispatchPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'tracking':
      page = MasterDeliveryTrackingPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'zones':
      page = MasterDeliveryZonesPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
    case 'emergency':
      page = MasterDriverEmergencyPage(
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      );
      break;
  }

  if (page == null) {
    _showMasterSnack(context, 'هذا القسم غير متاح لهذا الحساب');
    return;
  }

  Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => page!));
}

Widget _wrapLegacyDeliveryPage(
  BuildContext context, {
  required MasterSession session,
  required Future<void> Function() onLogout,
  required MasterAuthApiService api,
  required DateTime serverNow,
  required String activeSubPage,
  required Widget child,
}) {
  return _buildMasterUnifiedShell(
    context: context,
    session: session,
    onLogout: onLogout,
    api: api,
    sidebarItems: _masterFilterSidebarItems(session, const [
      _DashboardMenuItemData(
        iconKey: 'delivery',
        label: 'التوصيل واللوجستيات',
        selected: true,
      ),
    ]),
    onSidebarItemTap: (key) => _navigateToMasterSection(
      context,
      key: key,
      session: session,
      onLogout: onLogout,
      api: api,
      serverNow: serverNow,
    ),
    onDeliverySubPageTap: (key) => _navigateToDeliverySubPage(
      context,
      key: key,
      session: session,
      onLogout: onLogout,
      api: api,
      serverNow: serverNow,
    ),
    activeDeliverySubPage: activeSubPage,
    statusLabel: 'التوصيل متزامن',
    platformTitle: 'التوصيل واللوجستيات',
    platformSubtitle: 'إدارة السائقين والتوزيع والتتبع من مكان واحد',
    serverNow: serverNow,
    child: child,
  );
}

class MasterDeliveryZonesPage extends StatefulWidget {
  const MasterDeliveryZonesPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;

  @override
  State<MasterDeliveryZonesPage> createState() =>
      _MasterDeliveryZonesPageState();
}

class _MasterDeliveryZonesPageState extends State<MasterDeliveryZonesPage> {
  late final _DeliveryLogisticsController _controller;
  int _selectedZoneIndex = 0;
  String _cityFilter = 'all';
  String _statusFilter = 'all';
  bool _showDriversOnMap = true;
  bool _showRestaurantsOnMap = true;
  bool _zoneActionRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = _DeliveryLogisticsController(
      api: widget.api,
      token: widget.session.token,
      view: 'zones',
    );
  }

  void _reload() {
    setState(_controller.reload);
  }

  List<_ServiceZoneRecord> _filterZones(List<_ServiceZoneRecord> zones) {
    final query = _controller.searchController.text.trim().toLowerCase();
    return zones
        .where((zone) {
          final matchesQuery =
              query.isEmpty ||
              zone.name.toLowerCase().contains(query) ||
              zone.city.toLowerCase().contains(query) ||
              zone.feeLabel.toLowerCase().contains(query);
          final matchesCity =
              _cityFilter == 'all' ||
              zone.city.toLowerCase().contains(_cityFilter.toLowerCase());
          final matchesStatus =
              _statusFilter == 'all' ||
              (_statusFilter == 'active' && zone.status == 'مفعلة') ||
              (_statusFilter == 'disabled' && zone.status == 'معطلة') ||
              (_statusFilter == 'review' && zone.status == 'قيد المراجعة');
          return matchesQuery && matchesCity && matchesStatus;
        })
        .toList(growable: false);
  }

  void _setCityFilter(String value) {
    setState(() {
      _cityFilter = value;
      _selectedZoneIndex = 0;
    });
  }

  void _setStatusFilter(String value) {
    setState(() {
      _statusFilter = value;
      _selectedZoneIndex = 0;
    });
  }

  void _showZoneDetails(_ServiceZoneRecord zone) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone.name, textAlign: TextAlign.right),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine(Icons.location_city_outlined, 'المدينة', zone.city),
                _detailLine(
                  Icons.payments_outlined,
                  'رسوم التوصيل',
                  zone.feeLabel,
                ),
                _detailLine(
                  Icons.route_outlined,
                  'نطاق التغطية',
                  zone.distanceLabel,
                ),
                _detailLine(Icons.timer_outlined, 'زمن التوصيل', zone.etaLabel),
                _detailLine(
                  Icons.storefront_outlined,
                  'عدد المطاعم',
                  '${zone.restaurantCount} مطعم',
                ),
                _detailLine(
                  Icons.delivery_dining_outlined,
                  'السائقون',
                  '${zone.driverCount} سائق',
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
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showZoneEditor(zone);
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('تعديل'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleZoneStatus(zone, enabled: zone.status != 'مفعلة');
            },
            child: Text(zone.status == 'مفعلة' ? 'تعطيل' : 'تفعيل'),
          ),
        ],
      ),
    );
  }

  void _showAddZoneDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منطقة خدمة', textAlign: TextAlign.right),
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'يمكنك إضافة وتعديل مناطق الخدمة من زر الإضافة في الشريط العلوي.',
            textAlign: TextAlign.right,
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

  double _zoneNumberFromLabel(String value, [double fallback = 0]) {
    final normalized = value.replaceAll(',', '.');
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(normalized);
    return match == null
        ? fallback
        : double.tryParse(match.group(0)!) ?? fallback;
  }

  List<int> _zoneEtaFromLabel(String value) {
    final matches = RegExp(r'\d+')
        .allMatches(value)
        .map((match) => int.tryParse(match.group(0) ?? '') ?? 0)
        .where((value) => value > 0)
        .toList(growable: false);
    if (matches.isEmpty) {
      return const [25, 45];
    }
    if (matches.length == 1) {
      return [matches.first, math.max(matches.first, matches.first + 20)];
    }
    return [matches.first, math.max(matches.first, matches[1])];
  }

  void _showZoneEditor([_ServiceZoneRecord? zone]) {
    final eta = zone == null
        ? const [25, 45]
        : _zoneEtaFromLabel(zone.etaLabel);
    final nameController = TextEditingController(text: zone?.name ?? '');
    final cityController = TextEditingController(text: zone?.city ?? '');
    final feeController = TextEditingController(
      text: zone == null
          ? '0'
          : _zoneNumberFromLabel(zone.feeLabel).toStringAsFixed(0),
    );
    final coverageController = TextEditingController(
      text: zone == null
          ? '5'
          : _zoneNumberFromLabel(zone.distanceLabel, 5).toString(),
    );
    final minimumOrderController = TextEditingController(
      text: zone == null
          ? '0'
          : _zoneNumberFromLabel(zone.minimumOrderLabel).toStringAsFixed(0),
    );
    final minEtaController = TextEditingController(text: '${eta.first}');
    final maxEtaController = TextEditingController(text: '${eta.last}');
    final latController = TextEditingController(
      text: zone == null || !zone.hasCoordinates
          ? ''
          : zone.center.latitude.toStringAsFixed(6),
    );
    final lngController = TextEditingController(
      text: zone == null || !zone.hasCoordinates
          ? ''
          : zone.center.longitude.toStringAsFixed(6),
    );
    bool enabled = zone?.status == null || zone!.status == 'مفعلة';
    bool saving = false;

    Future<void> save(StateSetter setDialogState) async {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _showMasterSnack(context, 'اكتب اسم المنطقة');
        return;
      }
      setDialogState(() => saving = true);
      try {
        await widget.api._saveDeliveryZone(
          widget.session.token,
          zoneId: zone?.zoneId,
          data: {
            'name': name,
            'city': cityController.text.trim(),
            'delivery_fee': _zoneNumberFromLabel(feeController.text),
            'coverage_km': _zoneNumberFromLabel(coverageController.text, 5),
            'minimum_order': _zoneNumberFromLabel(minimumOrderController.text),
            'estimated_min_minutes': _zoneNumberFromLabel(
              minEtaController.text,
              25,
            ).round(),
            'estimated_max_minutes': _zoneNumberFromLabel(
              maxEtaController.text,
              45,
            ).round(),
            'center_latitude': latController.text.trim().isEmpty
                ? null
                : _zoneNumberFromLabel(latController.text),
            'center_longitude': lngController.text.trim().isEmpty
                ? null
                : _zoneNumberFromLabel(lngController.text),
            'is_open': enabled ? 1 : 0,
          },
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
        _showMasterSnack(
          context,
          zone == null ? 'تم إنشاء المنطقة' : 'تم تحديث المنطقة',
        );
        setState(_controller.reload);
      } catch (error) {
        if (mounted) {
          _showMasterSnack(context, error.toString());
        }
      } finally {
        setDialogState(() => saving = false);
      }
    }

    final dialog = showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            zone == null ? 'إضافة منطقة خدمة' : 'تعديل منطقة الخدمة',
            textAlign: TextAlign.right,
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoneEditorField(
                      controller: nameController,
                      label: 'اسم المنطقة',
                      icon: Icons.polyline_outlined,
                    ),
                    const SizedBox(height: 10),
                    _ZoneEditorField(
                      controller: cityController,
                      label: 'المدينة أو العنوان',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ZoneEditorField(
                            controller: feeController,
                            label: 'رسوم التوصيل',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ZoneEditorField(
                            controller: coverageController,
                            label: 'نطاق التغطية كم',
                            icon: Icons.route_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ZoneEditorField(
                            controller: minEtaController,
                            label: 'أقل زمن بالدقائق',
                            icon: Icons.timer_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ZoneEditorField(
                            controller: maxEtaController,
                            label: 'أقصى زمن بالدقائق',
                            icon: Icons.timer_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ZoneEditorField(
                      controller: minimumOrderController,
                      label: 'الحد الأدنى للطلب',
                      icon: Icons.shopping_bag_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ZoneEditorField(
                            controller: latController,
                            label: 'خط العرض',
                            icon: Icons.my_location_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ZoneEditorField(
                            controller: lngController,
                            label: 'خط الطول',
                            icon: Icons.explore_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: enabled,
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => enabled = value),
                      activeThumbColor: _kPrimaryGreen,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'المنطقة مفعلة',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : () => save(setDialogState),
              icon: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(saving ? 'جار الحفظ...' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
    dialog.whenComplete(() {
      nameController.dispose();
      cityController.dispose();
      feeController.dispose();
      coverageController.dispose();
      minimumOrderController.dispose();
      minEtaController.dispose();
      maxEtaController.dispose();
      latController.dispose();
      lngController.dispose();
    });
  }

  Future<void> _toggleZoneStatus(
    _ServiceZoneRecord zone, {
    required bool enabled,
  }) async {
    if (_zoneActionRunning) {
      return;
    }
    if (zone.zoneId <= 0) {
      _showMasterSnack(context, 'لا يوجد معرف مطعم صالح لهذه المنطقة');
      return;
    }
    setState(() => _zoneActionRunning = true);
    try {
      await widget.api._updateDeliveryZoneStatus(
        widget.session.token,
        zoneId: zone.zoneId,
        enabled: enabled,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(
        context,
        enabled ? 'تم تفعيل المنطقة' : 'تم تعطيل المنطقة',
      );
      setState(_controller.reload);
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _zoneActionRunning = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MasterDeliveryLogisticsData>(
      future: _controller.future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterDeliveryLogisticsData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                ),
              ),
            ),
          );
        }

        final zones = _filterZones(data.serviceZones);
        if (_selectedZoneIndex >= zones.length && zones.isNotEmpty) {
          _selectedZoneIndex = zones.length - 1;
        }
        final selectedZone = zones.isEmpty
            ? null
            : zones[math.min(_selectedZoneIndex, zones.length - 1)];
        return _wrapLegacyDeliveryPage(
          context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
          activeSubPage: 'zones',
          child: Scaffold(
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
                            child: _DeliveryZonesWorkspace(
                              data: data,
                              serverNow: serverNow,
                              zones: zones,
                              selectedZone: selectedZone,
                              selectedZoneIndex: _selectedZoneIndex,
                              onZoneSelected: (value) {
                                setState(() => _selectedZoneIndex = value);
                              },
                              cityFilter: _cityFilter,
                              statusFilter: _statusFilter,
                              onCityFilterChanged: _setCityFilter,
                              onStatusFilterChanged: _setStatusFilter,
                              showDriversOnMap: _showDriversOnMap,
                              showRestaurantsOnMap: _showRestaurantsOnMap,
                              actionRunning: _zoneActionRunning,
                              onToggleDriversLayer: () => setState(
                                () => _showDriversOnMap = !_showDriversOnMap,
                              ),
                              onToggleRestaurantsLayer: () => setState(
                                () => _showRestaurantsOnMap =
                                    !_showRestaurantsOnMap,
                              ),
                              onAddZone: () => _showZoneEditor(),
                              onShowZone: _showZoneDetails,
                              onToggleZoneStatus: (zone) => _toggleZoneStatus(
                                zone,
                                enabled: zone.status != 'مفعلة',
                              ),
                              searchController: _controller.searchController,
                              onSearchSubmitted: () => setState(() {
                                _selectedZoneIndex = 0;
                              }),
                              onReload: _reload,
                              showNavigationSidebar:
                                  _controller.showNavigationSidebar,
                              onToggleNavigationSidebar: () {
                                setState(_controller.toggleNavigationSidebar);
                              },
                              onOpenDrivers: () => _navigateToDeliverySubPage(
                                context,
                                key: 'drivers',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOpenDispatch: () => _navigateToDeliverySubPage(
                                context,
                                key: 'dispatch',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOpenTracking: () => _navigateToDeliverySubPage(
                                context,
                                key: 'tracking',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOpenEmergency: () => _navigateToDeliverySubPage(
                                context,
                                key: 'emergency',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                            ),
                          ),
                          // ignore: dead_code
                          if (false) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: sidebarWidth,
                              child: _DeliveryLogisticsRightSidebar(
                                activeSubPage: 'zones',
                                onSubPageTap: (key) =>
                                    _navigateToDeliverySubPage(
                                      context,
                                      key: key,
                                      session: widget.session,
                                      onLogout: widget.onLogout,
                                      api: widget.api,
                                      serverNow: serverNow,
                                    ),
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
                                onRestaurantsTap: () =>
                                    _navigateToMasterSection(
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
                                onMarketingTap: () => _navigateToMasterSection(
                                  context,
                                  key: 'marketing',
                                  session: widget.session,
                                  onLogout: widget.onLogout,
                                  api: widget.api,
                                  serverNow: serverNow,
                                ),
                                onCollapse: () {
                                  setState(_controller.hideNavigationSidebar);
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
          ),
        );
      },
    );
  }
}

class MasterDriverEmergencyPage extends StatefulWidget {
  const MasterDriverEmergencyPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;

  @override
  State<MasterDriverEmergencyPage> createState() =>
      _MasterDriverEmergencyPageState();
}

class _MasterDriverEmergencyPageState extends State<MasterDriverEmergencyPage> {
  late final _DeliveryLogisticsController _controller;
  Timer? _refreshTimer;
  int _selectedRequestIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = _DeliveryLogisticsController(
      api: widget.api,
      token: widget.session.token,
      view: 'emergency',
    );
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        setState(_controller.reload);
      }
    });
  }

  void _reload() {
    setState(_controller.reload);
  }

  void _callEmergencyDriver(_EmergencyRequestRecord request) {
    final phone = request.phone.trim();
    if (phone.isEmpty || phone == '-') {
      _showMasterSnack(context, 'رقم هاتف السائق غير متوفر');
      return;
    }
    html.window.open('tel:${phone.replaceAll(' ', '')}', '_self');
  }

  Future<void> _openEmergencyChat(_EmergencyRequestRecord request) async {
    if (request.orderId <= 0) {
      _showMasterSnack(context, 'لا يوجد طلب مرتبط ببلاغ الطوارئ');
      return;
    }
    try {
      await widget.api._sendMasterOrderChatMessage(
        widget.session.token,
        orderId: request.orderId,
        message: 'رسالة من الماستر بخصوص بلاغ الطوارئ ${request.id}.',
      );
      if (mounted) {
        _showMasterSnack(context, 'تم فتح قناة المحادثة وإرسال الرسالة');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MasterOrderChatsPage(
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: widget.serverNow ?? DateTime.now(),
              initialOrderId: request.orderId,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showMasterSnack(context, 'تعذر فتح المحادثة: $error');
    }
  }

  Future<void> _resolveEmergency(_EmergencyRequestRecord request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنهاء وضع الطوارئ'),
        content: Text('هل تم التعامل مع حالة السائق ${request.driverName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إنهاء الحالة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api._resolveDriverEmergency(
        widget.session.token,
        reportId: request.emergencyReportId,
        orderId: request.orderId,
        driverId: request.driverId,
      );
      if (mounted) {
        _showMasterSnack(context, 'تم إنهاء وضع الطوارئ وتحديث السائق');
        _reload();
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, 'تعذر إنهاء وضع الطوارئ: $error');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MasterDeliveryLogisticsData>(
      future: _controller.future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _MasterDeliveryLogisticsData.empty();
        final serverNow = data.serverNow ?? widget.serverNow ?? DateTime.now();
        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: _OperationsDataErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                ),
              ),
            ),
          );
        }

        final requests = data.emergencyRequests;
        if (_selectedRequestIndex >= requests.length && requests.isNotEmpty) {
          _selectedRequestIndex = requests.length - 1;
        }
        final selectedRequest = requests.isEmpty
            ? null
            : requests[math.min(_selectedRequestIndex, requests.length - 1)];
        return _wrapLegacyDeliveryPage(
          context,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
          activeSubPage: 'emergency',
          child: Scaffold(
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
                            child: _DriverEmergencyWorkspace(
                              data: data,
                              serverNow: serverNow,
                              requests: requests,
                              selectedRequestIndex: _selectedRequestIndex,
                              selectedRequest: selectedRequest,
                              searchController: _controller.searchController,
                              onSearchSubmitted: _reload,
                              onReload: _reload,
                              onRequestSelected: (value) {
                                setState(() => _selectedRequestIndex = value);
                              },
                              onCallDriver: _callEmergencyDriver,
                              onOpenChat: _openEmergencyChat,
                              onResolveEmergency: _resolveEmergency,
                              showNavigationSidebar:
                                  _controller.showNavigationSidebar,
                              onToggleNavigationSidebar: () {
                                setState(_controller.toggleNavigationSidebar);
                              },
                              onOpenDrivers: () => _navigateToDeliverySubPage(
                                context,
                                key: 'drivers',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOpenDispatch: () => _navigateToDeliverySubPage(
                                context,
                                key: 'dispatch',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOpenTracking: () => _navigateToDeliverySubPage(
                                context,
                                key: 'tracking',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOpenZones: () => _navigateToDeliverySubPage(
                                context,
                                key: 'zones',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                            ),
                          ),
                          // ignore: dead_code
                          if (false) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: sidebarWidth,
                              child: _DeliveryLogisticsRightSidebar(
                                activeSubPage: 'emergency',
                                onSubPageTap: (key) =>
                                    _navigateToDeliverySubPage(
                                      context,
                                      key: key,
                                      session: widget.session,
                                      onLogout: widget.onLogout,
                                      api: widget.api,
                                      serverNow: serverNow,
                                    ),
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
                                onRestaurantsTap: () =>
                                    _navigateToMasterSection(
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
                                onMarketingTap: () => _navigateToMasterSection(
                                  context,
                                  key: 'marketing',
                                  session: widget.session,
                                  onLogout: widget.onLogout,
                                  api: widget.api,
                                  serverNow: serverNow,
                                ),
                                onCollapse: () {
                                  setState(_controller.hideNavigationSidebar);
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
          ),
        );
      },
    );
  }
}

class _DeliveryZonesWorkspace extends StatelessWidget {
  const _DeliveryZonesWorkspace({
    required this.data,
    required this.serverNow,
    required this.zones,
    required this.selectedZone,
    required this.selectedZoneIndex,
    required this.onZoneSelected,
    required this.cityFilter,
    required this.statusFilter,
    required this.onCityFilterChanged,
    required this.onStatusFilterChanged,
    required this.showDriversOnMap,
    required this.showRestaurantsOnMap,
    required this.actionRunning,
    required this.onToggleDriversLayer,
    required this.onToggleRestaurantsLayer,
    required this.onAddZone,
    required this.onShowZone,
    required this.onToggleZoneStatus,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onReload,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onOpenDrivers,
    required this.onOpenDispatch,
    required this.onOpenTracking,
    required this.onOpenEmergency,
  });

  final _MasterDeliveryLogisticsData data;
  final DateTime serverNow;
  final List<_ServiceZoneRecord> zones;
  final _ServiceZoneRecord? selectedZone;
  final int selectedZoneIndex;
  final ValueChanged<int> onZoneSelected;
  final String cityFilter;
  final String statusFilter;
  final ValueChanged<String> onCityFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final bool showDriversOnMap;
  final bool showRestaurantsOnMap;
  final bool actionRunning;
  final VoidCallback onToggleDriversLayer;
  final VoidCallback onToggleRestaurantsLayer;
  final VoidCallback onAddZone;
  final ValueChanged<_ServiceZoneRecord> onShowZone;
  final ValueChanged<_ServiceZoneRecord> onToggleZoneStatus;
  final TextEditingController searchController;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onReload;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onOpenDrivers;
  final VoidCallback onOpenDispatch;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenEmergency;

  @override
  Widget build(BuildContext context) {
    final selectedZone = this.selectedZone;
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'مناطق الخدمة والتوصيل',
          subtitle:
              'إدارة المناطق الجغرافية المتاحة للتوصيل وتحديد الرسوم والقيود لكل منطقة',
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 8),
        _ZonesCompactStatsStrip(cards: _buildZonesStatCards(zones)),
        const SizedBox(height: 8),
        _DeliveryLogisticsTabs(
          active: 'zones',
          onOpenDrivers: onOpenDrivers,
          onOpenDispatch: onOpenDispatch,
          onOpenTracking: onOpenTracking,
          onOpenEmergency: onOpenEmergency,
        ),
        const SizedBox(height: 8),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            ElevatedButton.icon(
              onPressed: onAddZone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(122, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('إضافة منطقة', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            _OrdersFilterButton(
              label: switch (cityFilter) {
                'حلب' => 'حلب',
                'دمشق' => 'دمشق',
                _ => 'جميع المدن',
              },
              options: const {
                'all': 'جميع المدن',
                'حلب': 'حلب',
                'دمشق': 'دمشق',
              },
              onChanged: onCityFilterChanged,
            ),
            const SizedBox(width: 8),
            _OrdersFilterButton(
              label: switch (statusFilter) {
                'active' => 'مفعلة',
                'review' => 'قيد المراجعة',
                'disabled' => 'معطلة',
                _ => 'كل الحالات',
              },
              options: const {
                'all': 'كل الحالات',
                'active': 'مفعلة',
                'review': 'قيد المراجعة',
                'disabled': 'معطلة',
              },
              onChanged: onStatusFilterChanged,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DeliverySearchBox(
                controller: searchController,
                hint: 'بحث عن منطقة...',
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: selectedZone == null
              ? const _UsersPlaceholderWorkspace(
                  title: 'مناطق الخدمة والتوصيل',
                  description:
                      'لا توجد بيانات مناطق خدمة حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
                  icon: Icons.map_outlined,
                )
              : Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 332,
                      child: _ZoneListCard(
                        zones: zones,
                        selectedIndex: selectedZoneIndex,
                        onSelected: onZoneSelected,
                        onShowZone: onShowZone,
                        onToggleZoneStatus: onToggleZoneStatus,
                        actionRunning: actionRunning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ZoneCoverageMapCard(
                        zones: zones,
                        selectedZone: selectedZone,
                        drivers: data.drivers,
                        showDrivers: showDriversOnMap,
                        showRestaurants: showRestaurantsOnMap,
                        onToggleDrivers: onToggleDriversLayer,
                        onToggleRestaurants: onToggleRestaurantsLayer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 286,
                      child: _ZoneDetailsPanel(
                        zone: selectedZone,
                        actionRunning: actionRunning,
                        onShowDetails: () => onShowZone(selectedZone),
                        onToggleStatus: () => onToggleZoneStatus(selectedZone),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DriverEmergencyWorkspace extends StatelessWidget {
  const _DriverEmergencyWorkspace({
    required this.data,
    required this.serverNow,
    required this.requests,
    required this.selectedRequestIndex,
    required this.selectedRequest,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onReload,
    required this.onRequestSelected,
    required this.onCallDriver,
    required this.onOpenChat,
    required this.onResolveEmergency,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onOpenDrivers,
    required this.onOpenDispatch,
    required this.onOpenTracking,
    required this.onOpenZones,
  });

  final _MasterDeliveryLogisticsData data;
  final DateTime serverNow;
  final List<_EmergencyRequestRecord> requests;
  final int selectedRequestIndex;
  final _EmergencyRequestRecord? selectedRequest;
  final TextEditingController searchController;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onReload;
  final ValueChanged<int> onRequestSelected;
  final ValueChanged<_EmergencyRequestRecord> onCallDriver;
  final ValueChanged<_EmergencyRequestRecord> onOpenChat;
  final Future<void> Function(_EmergencyRequestRecord) onResolveEmergency;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onOpenDrivers;
  final VoidCallback onOpenDispatch;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenZones;

  @override
  Widget build(BuildContext context) {
    final selectedRequest = this.selectedRequest;
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'طوارئ السائقين',
          subtitle: 'استعراض وإدارة طلبات المساعدة الطارئة من السائقين',
          icon: Icons.emergency_outlined,
        ),
        const SizedBox(height: 10),
        _OrdersStatsStrip(cards: _buildEmergencyStatCards(requests)),
        const SizedBox(height: 10),
        _DeliveryLogisticsTabs(
          active: 'emergency',
          onOpenDrivers: onOpenDrivers,
          onOpenDispatch: onOpenDispatch,
          onOpenTracking: onOpenTracking,
          onOpenZones: onOpenZones,
        ),
        const SizedBox(height: 10),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            _OrdersFilterButton(
              label: 'تصفية متقدمة',
              options: const {'all': 'تصفية متقدمة'},
              onChanged: (_) => onSearchSubmitted(),
            ),
            const SizedBox(width: 8),
            _OrdersFilterButton(
              label: 'جميع الحالات',
              options: const {
                'all': 'جميع الحالات',
                'active': 'نشط',
                'road': 'في الطريق',
                'resolved': 'تم الحل',
              },
              onChanged: (_) => onSearchSubmitted(),
            ),
            const SizedBox(width: 8),
            _OrdersFilterButton(
              label: 'جميع المستويات',
              options: const {
                'all': 'جميع المستويات',
                'high': 'عالية',
                'medium': 'متوسطة',
                'low': 'منخفضة',
              },
              onChanged: (_) => onSearchSubmitted(),
            ),
            const SizedBox(width: 8),
            _OrdersFilterButton(
              label: 'جميع المدن',
              options: const {
                'all': 'جميع المدن',
                'damascus': 'دمشق',
                'aleppo': 'حلب',
              },
              onChanged: (_) => onSearchSubmitted(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DeliverySearchBox(
                controller: searchController,
                hint: 'بحث برقم الطلب أو اسم السائق...',
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: selectedRequest == null
              ? _EmergencyMapCard(requests: requests, selectedRequest: null)
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E7E3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 500,
                                child: _EmergencyDetailsPanel(
                                  request: selectedRequest,
                                  onCallDriver: () =>
                                      onCallDriver(selectedRequest),
                                  onOpenChat: () => onOpenChat(selectedRequest),
                                  onResolveEmergency: () =>
                                      onResolveEmergency(selectedRequest),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 310,
                                child: _EmergencyRequestsListCard(
                                  requests: requests,
                                  selectedIndex: selectedRequestIndex,
                                  onSelected: onRequestSelected,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 400,
                                child: _EmergencyMapCard(
                                  requests: requests,
                                  selectedRequest: selectedRequest,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 520,
                                child: _EmergencyAnalysisCard(
                                  requests: requests,
                                ),
                              ),
                            ],
                          ),
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

class _ServiceZoneRecord {
  const _ServiceZoneRecord({
    required this.zoneId,
    required this.name,
    required this.city,
    required this.status,
    required this.feeLabel,
    required this.distanceLabel,
    required this.restaurantCount,
    required this.driverCount,
    required this.etaLabel,
    required this.minimumOrderLabel,
    required this.serviceFeeLabel,
    required this.freeDeliveryOverLabel,
    required this.priorityLabel,
    required this.color,
    required this.center,
    required this.points,
    required this.hasCoordinates,
  });

  final int zoneId;
  final String name;
  final String city;
  final String status;
  final String feeLabel;
  final String distanceLabel;
  final int restaurantCount;
  final int driverCount;
  final String etaLabel;
  final String minimumOrderLabel;
  final String serviceFeeLabel;
  final String freeDeliveryOverLabel;
  final String priorityLabel;
  final Color color;
  final LatLng center;
  final List<LatLng> points;
  final bool hasCoordinates;

  factory _ServiceZoneRecord.fromJson(Map<String, dynamic> json) {
    final name = _normalizeUtf8Text(_firstText([json['name'], 'منطقة خدمة']));
    final rawCenter = LatLng(
      _toDouble(json['center_lat']),
      _toDouble(json['center_lng']),
    );
    final hasCenter =
        rawCenter.latitude.abs() > 0.000001 &&
        rawCenter.longitude.abs() > 0.000001;
    final center = hasCenter ? rawCenter : LatLng(30.0444, 31.2357);
    final points = _asMapList(json['points'])
        .map(
          (point) => LatLng(_toDouble(point['lat']), _toDouble(point['lng'])),
        )
        .where(
          (point) =>
              point.latitude.abs() > 0.000001 &&
              point.longitude.abs() > 0.000001,
        )
        .toList(growable: false);
    final derivedPoints = points.length >= 3
        ? points
        : hasCenter
        ? <LatLng>[
            LatLng(center.latitude + 0.018, center.longitude - 0.018),
            LatLng(center.latitude + 0.018, center.longitude + 0.018),
            LatLng(center.latitude - 0.018, center.longitude + 0.018),
            LatLng(center.latitude - 0.018, center.longitude - 0.018),
          ]
        : const <LatLng>[];
    return _ServiceZoneRecord(
      zoneId: _toInt(json['zone_id'] ?? json['vendor_id']),
      name: name,
      city: _normalizeUtf8Text(_firstText([json['city'], 'غير محدد'])),
      status: _normalizeUtf8Text(_firstText([json['status'], 'مفعلة'])),
      feeLabel: _normalizeUtf8Text(_firstText([json['fee_label'], '0 س'])),
      distanceLabel: _normalizeUtf8Text(
        _firstText([json['distance_label'], '0 كم']),
      ),
      restaurantCount: _toInt(json['restaurant_count']),
      driverCount: _toInt(json['driver_count']),
      etaLabel: _normalizeUtf8Text(_firstText([json['eta_label'], '-'])),
      minimumOrderLabel: _normalizeUtf8Text(
        _firstText([json['minimum_order_label'], '0 س']),
      ),
      serviceFeeLabel: _normalizeUtf8Text(
        _firstText([json['service_fee_label'], '0%']),
      ),
      freeDeliveryOverLabel: _normalizeUtf8Text(
        _firstText([json['free_delivery_over_label'], '0 س']),
      ),
      priorityLabel: _normalizeUtf8Text(
        _firstText([json['priority_label'], '-']),
      ),
      color: _hexToColor(_firstText([json['color_hex'], '#1A8B4A'])),
      center: center,
      points: derivedPoints,
      hasCoordinates: hasCenter,
    );
  }
}

class _EmergencyRequestRecord {
  const _EmergencyRequestRecord({
    required this.id,
    required this.emergencyReportId,
    required this.orderId,
    required this.driverId,
    required this.driverName,
    required this.phone,
    required this.status,
    required this.severity,
    required this.type,
    required this.location,
    required this.description,
    required this.createdAt,
    required this.elapsedLabel,
    required this.color,
    required this.point,
    required this.avatarUrl,
  });

  final String id;
  final int emergencyReportId;
  final int orderId;
  final int driverId;
  final String driverName;
  final String phone;
  final String status;
  final String severity;
  final String type;
  final String location;
  final String description;
  final String createdAt;
  final String elapsedLabel;
  final Color color;
  final LatLng point;
  final String avatarUrl;

  factory _EmergencyRequestRecord.fromJson(Map<String, dynamic> json) {
    return _EmergencyRequestRecord(
      id: _normalizeUtf8Text(_firstText([json['id'], '#EMR'])),
      emergencyReportId: _toInt(json['emergency_report_id']),
      orderId: _toInt(json['order_id']),
      driverId: _toInt(json['driver_id']),
      driverName: _normalizeUtf8Text(_firstText([json['driver_name'], 'سائق'])),
      phone: _firstText([json['phone'], '-']),
      status: _normalizeUtf8Text(_firstText([json['status'], 'نشط'])),
      severity: _normalizeUtf8Text(_firstText([json['severity'], 'عالية'])),
      type: _normalizeUtf8Text(_firstText([json['type'], 'طلب طوارئ'])),
      location: _normalizeUtf8Text(_firstText([json['location'], '-'])),
      description: _normalizeUtf8Text(_firstText([json['description'], '-'])),
      createdAt: _firstText([json['created_at'], '-']),
      elapsedLabel: _normalizeUtf8Text(_firstText([json['elapsed_label'], ''])),
      color: _hexToColor(_firstText([json['color_hex'], '#EF4444'])),
      point: LatLng(_toDouble(json['lat']), _toDouble(json['lng'])),
      avatarUrl: _firstText([json['avatar_url'], '']),
    );
  }
}

List<_OperationsStatCardData> _buildZonesStatCards(
  List<_ServiceZoneRecord> zones,
) {
  final active = zones.where((zone) => zone.status == 'مفعلة').length;
  final paused = zones.where((zone) => zone.status == 'قيد المراجعة').length;
  final disabled = zones.where((zone) => zone.status == 'معطلة').length;
  final avgFee = zones.isEmpty
      ? 0
      : zones
                .map(
                  (zone) =>
                      int.tryParse(
                        zone.feeLabel.replaceAll(RegExp(r'[^0-9]'), ''),
                      ) ??
                      0,
                )
                .fold<int>(0, (a, b) => a + b) ~/
            zones.length;
  return [
    _OperationsStatCardData(
      title: 'إجمالي المناطق',
      value: '${zones.length}',
      icon: Icons.public_outlined,
      accent: const Color(0xFF1A8B4A),
      background: const Color(0xFFEAF5ED),
      detailLine: '',
      trendLabel: 'منطقة',
      trendCaption: '',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'مناطق مفعلة',
      value: '$active',
      icon: Icons.check_circle_outline_rounded,
      accent: const Color(0xFF1A8B4A),
      background: const Color(0xFFEAF5ED),
      detailLine: '',
      trendLabel: '87.5% من الإجمالي',
      trendCaption: '',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'مناطق معطلة',
      value: '$disabled',
      icon: Icons.pause_circle_outline_rounded,
      accent: const Color(0xFF9CA3AF),
      background: const Color(0xFFF3F4F6),
      detailLine: '',
      trendLabel: '9.4% من الإجمالي',
      trendCaption: '',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'مناطق قيد المراجعة',
      value: '$paused',
      icon: Icons.timelapse_rounded,
      accent: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF3DF),
      detailLine: '',
      trendLabel: '3.1% من الإجمالي',
      trendCaption: '',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'متوسط رسوم التوصيل',
      value: _formatArabicInt(avgFee),
      icon: Icons.location_on_outlined,
      accent: const Color(0xFF0B8F4D),
      background: const Color(0xFFEAF7EE),
      detailLine: '',
      trendLabel: MasterCurrency.symbol,
      trendCaption: '',
      trendPositive: true,
    ),
  ];
}

List<_OperationsStatCardData> _buildEmergencyStatCards(
  List<_EmergencyRequestRecord> requests,
) {
  final active = requests.where((item) => item.status == 'نشط').length;
  final resolved = requests.where((item) => item.status == 'تم الحل').length;
  final cancelled = requests
      .where((item) => item.status == 'تم الإلغاء')
      .length;
  final high = requests.where((item) => item.severity == 'عالية').length;
  return [
    _OperationsStatCardData(
      title: 'إجمالي طلبات الطوارئ',
      value: '${requests.length}',
      icon: Icons.sos_outlined,
      accent: const Color(0xFFEF4444),
      background: const Color(0xFFFDECEC),
      detailLine: '',
      trendLabel: 'طلب',
      trendCaption: '15% عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'طوارئ نشطة الآن',
      value: '$active',
      icon: Icons.error_outline_rounded,
      accent: const Color(0xFFEF4444),
      background: const Color(0xFFFDECEC),
      detailLine: '',
      trendLabel: 'طلب',
      trendCaption: '33% عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'متوسط وقت الاستجابة',
      value: '2.4',
      icon: Icons.av_timer_rounded,
      accent: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF3DF),
      detailLine: '',
      trendLabel: 'دقيقة',
      trendCaption: '18% عن أمس',
      trendPositive: false,
    ),
    _OperationsStatCardData(
      title: 'تم حلها اليوم',
      value: '$resolved',
      icon: Icons.check_circle_outline_rounded,
      accent: const Color(0xFF10B981),
      background: const Color(0xFFEAF8F1),
      detailLine: '',
      trendLabel: 'طلب',
      trendCaption: '20% عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'السائقون الفرديون',
      value: '$high',
      icon: Icons.support_agent_rounded,
      accent: const Color(0xFF60A5FA),
      background: const Color(0xFFEFF6FF),
      detailLine: '',
      trendLabel: 'سائق',
      trendCaption: '',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'تم الإلغاء',
      value: '$cancelled',
      icon: Icons.shield_outlined,
      accent: const Color(0xFF0B8F4D),
      background: const Color(0xFFEAF7EE),
      detailLine: '',
      trendLabel: 'طلب',
      trendCaption: '25% عن أمس',
      trendPositive: false,
    ),
  ];
}

String _formatArabicInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return '$buffer ${MasterCurrency.symbol}';
}

class _ZonesCompactStatsStrip extends StatelessWidget {
  const _ZonesCompactStatsStrip({required this.cards});

  final List<_OperationsStatCardData> cards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: _ZoneCompactStatCard(data: cards[i])),
            if (i != cards.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ZoneCompactStatCard extends StatelessWidget {
  const _ZoneCompactStatCard({required this.data});

  final _OperationsStatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8E5)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: data.background,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 17, color: data.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.2,
                    color: Color(0xFF4E5660),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF121821),
                    height: 1,
                  ),
                ),
                if (data.trendLabel.isNotEmpty)
                  Text(
                    data.trendLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: data.trendPositive
                          ? _kPrimaryGreen
                          : const Color(0xFFDC2626),
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
}

class _ZoneEditorField extends StatelessWidget {
  const _ZoneEditorField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAF9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E7E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E7E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimaryGreen),
        ),
      ),
    );
  }
}

class _ZoneListCard extends StatelessWidget {
  const _ZoneListCard({
    required this.zones,
    required this.selectedIndex,
    required this.onSelected,
    required this.onShowZone,
    required this.onToggleZoneStatus,
    required this.actionRunning,
  });

  final List<_ServiceZoneRecord> zones;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<_ServiceZoneRecord> onShowZone;
  final ValueChanged<_ServiceZoneRecord> onToggleZoneStatus;
  final bool actionRunning;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'قائمة المناطق (${zones.length})',
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (10, 'المنطقة'),
              (6, 'المدينة'),
              (7, 'رسوم التوصيل'),
              (5, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: zones.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final zone = zones[index];
                final selected = index == selectedIndex;
                return InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    height: 66,
                    color: selected ? const Color(0xFFF1F8F4) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: zone.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      zone.name,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${zone.restaurantCount} مطعم',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6F7680),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 6,
                          child: Text(zone.city, textAlign: TextAlign.right),
                        ),
                        _OrdersTableCell(
                          flex: 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(zone.feeLabel, textAlign: TextAlign.right),
                              const SizedBox(height: 4),
                              Text(
                                zone.distanceLabel,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6F7680),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 0.72,
                                child: Switch.adaptive(
                                  value: zone.status == 'مفعلة',
                                  activeThumbColor: _kPrimaryGreen,
                                  activeTrackColor: const Color(0xFFDCEFE5),
                                  onChanged: actionRunning
                                      ? null
                                      : (_) => onToggleZoneStatus(zone),
                                ),
                              ),
                              IconButton(
                                tooltip: 'عرض التفاصيل',
                                iconSize: 16,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onShowZone(zone),
                                icon: const Icon(Icons.visibility_outlined),
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
          SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: zones.isEmpty
                        ? null
                        : () => onShowZone(
                            zones[math.min(selectedIndex, zones.length - 1)],
                          ),
                    child: const Text('عرض', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _kPrimaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
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

class _ZoneCoverageMapCard extends StatelessWidget {
  const _ZoneCoverageMapCard({
    required this.zones,
    required this.selectedZone,
    required this.drivers,
    required this.showDrivers,
    required this.showRestaurants,
    required this.onToggleDrivers,
    required this.onToggleRestaurants,
  });

  final List<_ServiceZoneRecord> zones;
  final _ServiceZoneRecord selectedZone;
  final List<_DeliveryDriverData> drivers;
  final bool showDrivers;
  final bool showRestaurants;
  final VoidCallback onToggleDrivers;
  final VoidCallback onToggleRestaurants;

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();
    final mappedZones = zones
        .where((zone) => zone.hasCoordinates)
        .toList(growable: false);
    final fallbackCenter = mappedZones.isNotEmpty
        ? mappedZones.first.center
        : LatLng(30.0444, 31.2357);
    final effectiveCenter = selectedZone.hasCoordinates
        ? selectedZone.center
        : fallbackCenter;
    return _RestaurantShellCard(
      title: 'عرض المنطقة المحددة',
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: effectiveCenter,
              initialZoom: 12.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _kMapboxAccessToken.trim().isNotEmpty
                    ? _kMapboxTileUrl
                    : _kEsriTileUrl,
                fallbackUrl: _kOsmTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                additionalOptions: const {'accessToken': _kMapboxAccessToken},
                userAgentPackageName: 'com.aleppoeats.master',
                maxNativeZoom: 18,
                keepBuffer: 1,
                panBuffer: 0,
              ),
              PolygonLayer(
                polygons: [
                  for (final zone in mappedZones)
                    if (zone.points.length >= 3)
                      Polygon(
                        points: zone.points,
                        color: zone.color.withValues(alpha: 0.18),
                        borderStrokeWidth: zone.name == selectedZone.name
                            ? 3
                            : 2,
                        borderColor: zone.color,
                      ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (showRestaurants)
                    for (final zone in mappedZones)
                      Marker(
                        point: zone.center,
                        width: 78,
                        height: 34,
                        child: _ZonePriceBadge(zone: zone),
                      ),
                ],
              ),
            ],
          ),
          if (!selectedZone.hasCoordinates)
            Positioned(
              top: 54,
              right: 12,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'لا توجد إحداثيات حقيقية لهذه المنطقة، لذلك لم يتم رسمها على الخريطة.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _ZoneMapActionChip(
                  icon: Icons.delivery_dining_outlined,
                  label: 'عرض السائقين',
                  selected: showDrivers,
                  onTap: onToggleDrivers,
                ),
                const SizedBox(width: 8),
                _ZoneMapActionChip(
                  icon: Icons.storefront_outlined,
                  label: 'عرض جميع المتاجر',
                  selected: showRestaurants,
                  onTap: onToggleRestaurants,
                ),
              ],
            ),
          ),
          const Positioned(top: 12, left: 12, child: _MapProviderBadge()),
          if (showDrivers)
            Positioned(
              top: 54,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Text(
                  'السائقون المتاحون: ${drivers.length}',
                  style: const TextStyle(
                    color: _kPrimaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 50,
            child: Column(
              children: [
                _ZoneMapToolButton(
                  icon: Icons.add,
                  onTap: () => mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom + 0.7,
                  ),
                ),
                const SizedBox(height: 6),
                _ZoneMapToolButton(
                  icon: Icons.remove,
                  onTap: () => mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom - 0.7,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                children: const [
                  _ZoneLegendDot(color: Color(0xFF1A8B4A), label: 'مفعلة'),
                  SizedBox(width: 12),
                  _ZoneLegendDot(color: Color(0xFF9CA3AF), label: 'معطلة'),
                  SizedBox(width: 12),
                  _ZoneLegendDot(
                    color: Color(0xFFF59E0B),
                    label: 'قيد المراجعة',
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

class _ZonePriceBadge extends StatelessWidget {
  const _ZonePriceBadge({required this.zone});

  final _ServiceZoneRecord zone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: zone.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          zone.feeLabel,
          style: TextStyle(
            color: zone.color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ZoneMapActionChip extends StatelessWidget {
  const _ZoneMapActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F8F4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFD7EBDD) : const Color(0xFFE7ECE8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
                color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneMapToolButton extends StatelessWidget {
  const _ZoneMapToolButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 17, color: const Color(0xFF374151)),
        ),
      ),
    );
  }
}

class _ZoneLegendDot extends StatelessWidget {
  const _ZoneLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ZoneDetailsPanel extends StatelessWidget {
  const _ZoneDetailsPanel({
    required this.zone,
    required this.actionRunning,
    required this.onShowDetails,
    required this.onToggleStatus,
  });

  final _ServiceZoneRecord zone;
  final bool actionRunning;
  final VoidCallback onShowDetails;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المنطقة المحددة',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: zone.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _statusPill(zone.status),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: zone.status == 'مفعلة',
                  activeThumbColor: _kPrimaryGreen,
                  activeTrackColor: const Color(0xFFDCEFE5),
                  onChanged: actionRunning ? null : (_) => onToggleStatus(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailLine(Icons.payments_outlined, 'رسوم التوصيل', zone.feeLabel),
            _detailLine(
              Icons.route_outlined,
              'حد أقصى للمسافة',
              zone.distanceLabel,
            ),
            _detailLine(
              Icons.storefront_outlined,
              'عدد المطاعم',
              '${zone.restaurantCount} مطعم',
            ),
            _detailLine(
              Icons.delivery_dining_outlined,
              'عدد السائقين النشطين',
              '${zone.driverCount} سائق',
            ),
            _detailLine(
              Icons.timer_outlined,
              'وقت التوصيل المتوقع',
              zone.etaLabel,
            ),
            const SizedBox(height: 12),
            const Text(
              'الإعدادات',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _detailLine(
              Icons.shopping_bag_outlined,
              'الحد الأدنى للطلب',
              zone.minimumOrderLabel,
            ),
            _detailLine(
              Icons.percent_rounded,
              'رسوم الخدمة',
              zone.serviceFeeLabel,
            ),
            _detailLine(
              Icons.local_shipping_outlined,
              'توصيل مجاني فوق',
              zone.freeDeliveryOverLabel,
            ),
            _detailLine(
              Icons.trending_up_rounded,
              'أولوية التوصيل',
              zone.priorityLabel,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onShowDetails,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimaryGreen,
                minimumSize: const Size.fromHeight(38),
              ),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('عرض / تعديل', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: actionRunning ? null : onToggleStatus,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
                side: const BorderSide(color: Color(0xFFF2B8B5)),
              ),
              icon: const Icon(
                Icons.pause_circle_outline_rounded,
                size: 15,
                color: Color(0xFFDC2626),
              ),
              label: Text(
                zone.status == 'مفعلة' ? 'تعطيل المنطقة' : 'تفعيل المنطقة',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyRequestsListCard extends StatelessWidget {
  const _EmergencyRequestsListCard({
    required this.requests,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_EmergencyRequestRecord> requests;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'قائمة طلبات الطوارئ (${requests.length})',
      child: Column(
        children: [
          for (var index = 0; index < requests.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            Builder(
              builder: (context) {
                final item = requests[index];
                final selected = index == selectedIndex;
                return InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    color: selected ? const Color(0xFFFFF7F7) : null,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: Text(
                                item.id,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _statusPill(item.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.driverName, textAlign: TextAlign.right),
                        const SizedBox(height: 4),
                        Text(
                          item.location,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11.2,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.severity,
                              style: TextStyle(
                                color: item.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              item.createdAt,
                              style: const TextStyle(
                                fontSize: 11.2,
                                color: Color(0xFF6F7680),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _EmergencyMapCard extends StatelessWidget {
  const _EmergencyMapCard({required this.requests, this.selectedRequest});

  final List<_EmergencyRequestRecord> requests;
  final _EmergencyRequestRecord? selectedRequest;

  @override
  Widget build(BuildContext context) {
    final mappedRequests = requests
        .where(
          (request) =>
              request.point.latitude.abs() > 0.000001 &&
              request.point.longitude.abs() > 0.000001,
        )
        .toList(growable: false);
    final mapCenter =
        selectedRequest != null &&
            selectedRequest!.point.latitude.abs() > 0.000001 &&
            selectedRequest!.point.longitude.abs() > 0.000001
        ? selectedRequest!.point
        : mappedRequests.isNotEmpty
        ? mappedRequests.first.point
        : LatLng(30.0444, 31.2357);
    return _RestaurantShellCard(
      title: 'خريطة طلبات الطوارئ المباشرة',
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: mapCenter, initialZoom: 11.5),
            children: [
              TileLayer(
                urlTemplate: _kMapboxAccessToken.trim().isNotEmpty
                    ? _kMapboxTileUrl
                    : _kEsriTileUrl,
                fallbackUrl: _kOsmTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                additionalOptions: const {'accessToken': _kMapboxAccessToken},
                userAgentPackageName: 'com.aleppoeats.master',
              ),
              MarkerLayer(
                markers: [
                  for (final item in mappedRequests)
                    Marker(
                      point: item.point,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (requests.isEmpty)
            Positioned.fill(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7ECE8)),
                  ),
                  child: const Text(
                    'لا توجد بلاغات طوارئ مسجلة حاليًا',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                children: [
                  _ZoneLegendDot(color: const Color(0xFFEF4444), label: 'نشط'),
                  const SizedBox(width: 12),
                  _ZoneLegendDot(
                    color: const Color(0xFFF59E0B),
                    label: 'في الطريق',
                  ),
                  const SizedBox(width: 12),
                  _ZoneLegendDot(
                    color: const Color(0xFF10B981),
                    label: 'تم الحل',
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

class _EmergencyAnalysisCard extends StatelessWidget {
  const _EmergencyAnalysisCard({required this.requests});

  final List<_EmergencyRequestRecord> requests;

  @override
  Widget build(BuildContext context) {
    final high = requests.where((item) => item.severity == 'عالية').length;
    final medium = requests.where((item) => item.severity == 'متوسطة').length;
    final low = requests.where((item) => item.severity == 'منخفضة').length;
    return Column(
      children: [
        Expanded(
          child: _OrdersSideCard(
            title: 'أنواع الطوارئ',
            children: const [
              _OrdersMetricLine(label: 'حوادث مرورية', value: '12 طلب'),
              _OrdersMetricLine(label: 'أعطال مركبة', value: '8 طلبات'),
              _OrdersMetricLine(label: 'إصابة خفيفة', value: '4 طلبات'),
              _OrdersMetricLine(label: 'أخرى', value: '3 طلبات'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _OrdersSideCard(
            title: 'توزيع المستويات',
            children: [
              _OrdersMetricLine(label: 'عالية', value: '$high'),
              _OrdersMetricLine(label: 'متوسطة', value: '$medium'),
              _OrdersMetricLine(label: 'منخفضة', value: '$low'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _OrdersSideCard(
            title: 'متوسط أوقات الاستجابة',
            children: const [
              _OrdersMetricLine(label: 'عالية', value: '1.8 دقيقة'),
              _OrdersMetricLine(label: 'متوسطة', value: '2.6 دقيقة'),
              _OrdersMetricLine(label: 'منخفضة', value: '4.1 دقيقة'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyDetailsPanel extends StatelessWidget {
  const _EmergencyDetailsPanel({
    required this.request,
    required this.onCallDriver,
    required this.onOpenChat,
    required this.onResolveEmergency,
  });

  final _EmergencyRequestRecord request;
  final VoidCallback onCallDriver;
  final VoidCallback onOpenChat;
  final VoidCallback onResolveEmergency;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل طلب الطوارئ',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _AvatarThumb(
                  url: request.avatarUrl,
                  name: request.driverName,
                  size: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        request.driverName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.phone,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(child: _detailMetricCard('المستوى', request.severity)),
                const SizedBox(width: 8),
                Expanded(child: _detailMetricCard('النوع', request.type)),
              ],
            ),
            const SizedBox(height: 12),
            _detailLine(
              Icons.location_on_outlined,
              'الموقع الحالي',
              request.location,
            ),
            _detailLine(
              Icons.watch_later_outlined,
              'الوقت منذ الإنشاء',
              request.elapsedLabel,
            ),
            _detailLine(
              Icons.description_outlined,
              'الوصف',
              request.description,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onCallDriver,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.call_outlined, size: 16),
              label: const Text('اتصال بالسائق'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onResolveEmergency,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16834A),
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('إنهاء وضع الطوارئ'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onOpenChat,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('محادثة'),
            ),
          ],
        ),
      ),
    );
  }
}
