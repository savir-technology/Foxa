// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class MasterDeliveryLogisticsPage extends StatefulWidget {
  const MasterDeliveryLogisticsPage({
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
  State<MasterDeliveryLogisticsPage> createState() =>
      _MasterDeliveryLogisticsPageState();
}

class _MasterDeliveryLogisticsPageState
    extends State<MasterDeliveryLogisticsPage> {
  late final _DeliveryLogisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _DeliveryLogisticsController(
      api: widget.api,
      token: widget.session.token,
      view: 'drivers',
    );
  }

  void _reload() => setState(_controller.reload);
  void _setStatusFilter(String value) =>
      setState(() => _controller.setStatusFilter(value));
  void _setVehicleFilter(String value) =>
      setState(() => _controller.setVehicleFilter(value));

  Future<void> _showDriverEditor([_DeliveryDriverData? driver]) async {
    final restaurants = await widget.api._fetchMasterRestaurants(
      widget.session.token,
    );
    if (!mounted) return;
    final nameController = TextEditingController(text: driver?.name ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');
    final vehicleTypeController = TextEditingController(
      text: driver?.vehicleType ?? '',
    );
    final vehicleNumberController = TextEditingController(
      text: driver?.vehicleNumber ?? '',
    );
    var selectedRestaurantId = driver?.vendorId ?? 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(driver == null ? 'إضافة سائق' : 'تعديل السائق'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'اسم السائق'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vehicleTypeController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'نوع المركبة'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vehicleNumberController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'رقم المركبة'),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setDialogState) =>
                    DropdownButtonFormField<int>(
                      initialValue:
                          restaurants.any(
                            (r) =>
                                int.tryParse(r.id.replaceFirst('RST-', '')) ==
                                selectedRestaurantId,
                          )
                          ? selectedRestaurantId
                          : 0,
                      decoration: const InputDecoration(
                        labelText: 'المطعم المرتبط',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text('بدون ربط'),
                        ),
                        ...restaurants.map((restaurant) {
                          final id =
                              int.tryParse(
                                restaurant.id.replaceFirst('RST-', ''),
                              ) ??
                              0;
                          return DropdownMenuItem(
                            value: id,
                            child: Text(restaurant.name),
                          );
                        }),
                      ],
                      onChanged: (value) => setDialogState(
                        () => selectedRestaurantId = value ?? 0,
                      ),
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
    if (saved != true) {
      return;
    }
    await widget.api._runDeliveryDriverAction(
      widget.session.token,
      action: 'save',
      driverId: driver?.driverId,
      data: {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'vehicle_type': vehicleTypeController.text.trim(),
        'vehicle_number': vehicleNumberController.text.trim(),
        'vendor_id': selectedRestaurantId,
        'status': driver?.statusKey == 'available' ? 'online' : 'offline',
      },
    );
    if (mounted) {
      _showMasterSnack(context, 'تم حفظ بيانات السائق في قاعدة البيانات');
      _reload();
    }
  }

  Future<void> _toggleDriverStatus(_DeliveryDriverData driver) async {
    final activate = driver.statusKey == 'unavailable';
    await widget.api._runDeliveryDriverAction(
      widget.session.token,
      action: activate ? 'activate' : 'disable',
      driverId: driver.driverId,
    );
    if (mounted) {
      _showMasterSnack(
        context,
        activate ? 'تم تفعيل السائق' : 'تم تعطيل السائق',
      );
      _reload();
    }
  }

  Future<void> _setDriverApproval(
    _DeliveryDriverData driver,
    bool approve,
  ) async {
    await widget.api._runDeliveryDriverAction(
      widget.session.token,
      action: approve ? 'approve' : 'reject',
      driverId: driver.driverId,
    );
    if (mounted) {
      _showMasterSnack(
        context,
        approve ? 'تم قبول السائق نهائيًا' : 'تم رفض السائق نهائيًا',
      );
      _reload();
    }
  }

  String _driverApprovalLabel(String status) {
    switch (status) {
      case 'vendor_pending':
        return 'في انتظار موافقة المتجر';
      case 'vendor_approved':
        return 'مقبول مبدئيًا من المتجر';
      case 'vendor_rejected':
        return 'مرفوض مبدئيًا من المتجر';
      case 'approved':
        return 'مقبول نهائيًا';
      case 'rejected':
        return 'مرفوض نهائيًا';
      default:
        return 'في انتظار موافقة الماستر';
    }
  }

  void _showDriverDetails(_DeliveryDriverData driver) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                driver.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                driver.vendorId > 0
                    ? 'تابع لـ: ${driver.vendorName.isEmpty ? 'متجر مرتبط' : driver.vendorName}'
                    : 'نوع الحساب: سائق مستقل',
              ),
              Text('الموافقة: ${_driverApprovalLabel(driver.approvalStatus)}'),
              Text('الهاتف: ${driver.phone}'),
              Text('المركبة: ${driver.vehicleType} - ${driver.vehicleNumber}'),
              Text('الحالة: ${driver.statusLabel}'),
              Text('طلبات اليوم: ${driver.todayOrders}'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _showDriverEditor(driver);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل'),
                  ),
                  if (driver.approvalStatus != 'approved' &&
                      driver.approvalStatus != 'rejected') ...[
                    FilledButton.icon(
                      onPressed: () => _setDriverApproval(driver, true),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('قبول نهائي'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _setDriverApproval(driver, false),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('رفض نهائي'),
                    ),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _toggleDriverStatus(driver);
                    },
                    icon: Icon(
                      driver.statusKey == 'unavailable'
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                    ),
                    label: Text(
                      driver.statusKey == 'unavailable' ? 'تفعيل' : 'تعطيل',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: driver.phone.trim().isEmpty
                        ? null
                        : () =>
                              html.window.open('tel:${driver.phone}', '_self'),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('اتصال'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _messageDriver(_DeliveryDriverData driver) {
    if (driver.phone.trim().isEmpty) {
      _showMasterSnack(context, 'لا يوجد رقم هاتف لهذا السائق');
      return;
    }
    html.window.open('sms:${driver.phone}', '_self');
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

        return _DeliveryPageShell(
          showSidebar: _controller.showNavigationSidebar,
          sidebarActiveKey: 'drivers',
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
          onCollapse: () => setState(_controller.hideNavigationSidebar),
          content: _DeliveryDriversWorkspace(
            data: data,
            serverNow: serverNow,
            onReload: _reload,
            searchController: _controller.searchController,
            statusFilter: _controller.statusFilter,
            vehicleFilter: _controller.vehicleFilter,
            onStatusChanged: _setStatusFilter,
            onVehicleChanged: _setVehicleFilter,
            onSearchSubmitted: _reload,
            showNavigationSidebar: _controller.showNavigationSidebar,
            onToggleNavigationSidebar: () {
              setState(_controller.toggleNavigationSidebar);
            },
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
            onOpenEmergency: () => _navigateToDeliverySubPage(
              context,
              key: 'emergency',
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: serverNow,
            ),
            onAddDriver: () => _showDriverEditor(),
            onViewDriver: _showDriverDetails,
            onMessageDriver: _messageDriver,
            onToggleDriver: _toggleDriverStatus,
          ),
        );
      },
    );
  }
}

class MasterDriverDispatchPage extends StatefulWidget {
  const MasterDriverDispatchPage({
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
  State<MasterDriverDispatchPage> createState() =>
      _MasterDriverDispatchPageState();
}

class _MasterDriverDispatchPageState extends State<MasterDriverDispatchPage> {
  late final _DeliveryLogisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _DeliveryLogisticsController(
      api: widget.api,
      token: widget.session.token,
      view: 'dispatch',
    );
  }

  void _reload() => setState(_controller.reload);

  Future<void> _assignSelected() async {
    if (_controller.selectedOrderId == null ||
        _controller.selectedDriverId == null ||
        _controller.assigning) {
      return;
    }
    setState(() => _controller.assigning = true);
    try {
      final message = await _controller.assignSelected();
      if (!mounted) {
        return;
      }
      if (message.isNotEmpty) {
        _showMasterSnack(context, message);
      }
      setState(() {});
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _controller.assigning = false);
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

        return _DeliveryPageShell(
          showSidebar: _controller.showNavigationSidebar,
          sidebarActiveKey: 'dispatch',
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
          onCollapse: () => setState(_controller.hideNavigationSidebar),
          content: _DriverDispatchWorkspace(
            data: data,
            serverNow: serverNow,
            onReload: _reload,
            searchController: _controller.searchController,
            onSearchSubmitted: _reload,
            selectedOrderId: _controller.selectedOrderId,
            selectedDriverId: _controller.selectedDriverId,
            assigning: _controller.assigning,
            onOrderSelected: (id) {
              final matches = data.unassignedOrders.where(
                (order) => order.orderId == id,
              );
              setState(
                () => _controller.selectOrder(
                  id,
                  vendorId: matches.isEmpty ? 0 : matches.first.vendorId,
                ),
              );
            },
            onDriverSelected: (id) {
              setState(() {
                if (_controller.selectedOrderId == null &&
                    data.unassignedOrders.isNotEmpty) {
                  final firstOrder = data.unassignedOrders.first;
                  _controller.selectOrder(
                    firstOrder.orderId,
                    vendorId: firstOrder.vendorId,
                  );
                }
                _controller.selectDriver(id);
              });
            },
            onAssign: _assignSelected,
            showNavigationSidebar: _controller.showNavigationSidebar,
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
            onOpenEmergency: () => _navigateToDeliverySubPage(
              context,
              key: 'emergency',
              session: widget.session,
              onLogout: widget.onLogout,
              api: widget.api,
              serverNow: serverNow,
            ),
          ),
        );
      },
    );
  }
}

class MasterDeliveryDistributionPage extends StatefulWidget {
  const MasterDeliveryDistributionPage({
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
  State<MasterDeliveryDistributionPage> createState() =>
      _MasterDeliveryDistributionPageState();
}

class _MasterDeliveryDistributionPageState
    extends State<MasterDeliveryDistributionPage> {
  late final _DeliveryLogisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _DeliveryLogisticsController(
      api: widget.api,
      token: widget.session.token,
      view: 'distribution',
    );
  }

  void _reload() => setState(_controller.reload);

  Future<void> _runAssignment(Future<String> Function() action) async {
    if (_controller.assigning) {
      return;
    }
    setState(() => _controller.assigning = true);
    try {
      final message = await action();
      if (!mounted) {
        return;
      }
      if (message.isNotEmpty) {
        _showMasterSnack(context, message);
      }
      setState(() {});
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _controller.assigning = false);
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

        return _DeliveryPageShell(
          showSidebar: _controller.showNavigationSidebar,
          sidebarActiveKey: 'dispatch',
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
          onCollapse: () => setState(_controller.hideNavigationSidebar),
          content: _DeliveryDistributionWorkspace(
            data: data,
            serverNow: serverNow,
            onReload: _reload,
            searchController: _controller.searchController,
            onSearchSubmitted: _reload,
            selectedOrderId: _controller.selectedOrderId,
            selectedDriverId: _controller.selectedDriverId,
            assigning: _controller.assigning,
            onOrderSelected: (id) {
              final matches = data.unassignedOrders.where(
                (order) => order.orderId == id,
              );
              setState(
                () => _controller.selectOrder(
                  id,
                  vendorId: matches.isEmpty ? 0 : matches.first.vendorId,
                ),
              );
            },
            onDriverSelected: (id) {
              setState(() => _controller.selectDriver(id));
            },
            onAssignManual: () => _runAssignment(_controller.assignSelected),
            onAssignAutomatic: () =>
                _runAssignment(() => _controller.assignAutomatic(data)),
            onAssignScheduled: () =>
                _runAssignment(() => _controller.assignScheduledBatch(data)),
            showNavigationSidebar: _controller.showNavigationSidebar,
            onToggleNavigationSidebar: () {
              setState(_controller.toggleNavigationSidebar);
            },
          ),
        );
      },
    );
  }
}

class MasterDeliveryTrackingPage extends StatefulWidget {
  const MasterDeliveryTrackingPage({
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
  State<MasterDeliveryTrackingPage> createState() =>
      _MasterDeliveryTrackingPageState();
}

class _MasterDeliveryTrackingPageState
    extends State<MasterDeliveryTrackingPage> {
  late final _DeliveryLogisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _DeliveryLogisticsController(
      api: widget.api,
      token: widget.session.token,
      view: 'tracking',
    );
  }

  void _reload() => setState(_controller.reload);

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

        return _DeliveryPageShell(
          showSidebar: _controller.showNavigationSidebar,
          sidebarActiveKey: 'tracking',
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
          onCollapse: () => setState(_controller.hideNavigationSidebar),
          content: _DeliveryTrackingWorkspace(
            data: data,
            serverNow: serverNow,
            onReload: _reload,
            searchController: _controller.searchController,
            onSearchSubmitted: _reload,
            showNavigationSidebar: _controller.showNavigationSidebar,
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
            onOpenZones: () => _navigateToDeliverySubPage(
              context,
              key: 'zones',
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
        );
      },
    );
  }
}

class _DeliveryPageShell extends StatelessWidget {
  const _DeliveryPageShell({
    required this.showSidebar,
    required this.sidebarActiveKey,
    required this.session,
    required this.onLogout,
    required this.api,
    required this.serverNow,
    required this.onCollapse,
    required this.content,
  });

  final bool showSidebar;
  final String sidebarActiveKey;
  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime serverNow;
  final VoidCallback onCollapse;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(session, [
      _DashboardMenuItemData(
        iconKey: 'delivery',
        label: 'التوصيل واللوجستيات',
        selected: true,
      ),
    ]);
    return _buildMasterUnifiedShell(
      context: context,
      session: session,
      onLogout: onLogout,
      api: api,
      sidebarItems: sidebarItems,
      onSidebarItemTap: (key) => _navigateToMasterSection(
        context,
        key: key,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      ),
      statusLabel: 'التوصيل متزامن',
      platformTitle: 'التوصيل واللوجستيات',
      platformSubtitle: 'إدارة السائقين والتوزيع والتتبع من مكان واحد',
      serverNow: serverNow,
      child: content,
      activeDeliverySubPage: sidebarActiveKey,
      onDeliverySubPageTap: (key) => _navigateToDeliverySubPage(
        context,
        key: key,
        session: session,
        onLogout: onLogout,
        api: api,
        serverNow: serverNow,
      ),
    );
  }
}
