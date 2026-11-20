// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _DeliveryDriversWorkspace extends StatelessWidget {
  const _DeliveryDriversWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.statusFilter,
    required this.vehicleFilter,
    required this.onStatusChanged,
    required this.onVehicleChanged,
    required this.onSearchSubmitted,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onOpenDispatch,
    required this.onOpenTracking,
    required this.onOpenZones,
    required this.onOpenEmergency,
    required this.onAddDriver,
    required this.onViewDriver,
    required this.onMessageDriver,
    required this.onToggleDriver,
  });

  final _MasterDeliveryLogisticsData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String statusFilter;
  final String vehicleFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onVehicleChanged;
  final VoidCallback onSearchSubmitted;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onOpenDispatch;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenZones;
  final VoidCallback onOpenEmergency;
  final VoidCallback onAddDriver;
  final ValueChanged<_DeliveryDriverData> onViewDriver;
  final ValueChanged<_DeliveryDriverData> onMessageDriver;
  final ValueChanged<_DeliveryDriverData> onToggleDriver;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OrdersStatsStrip(cards: data.stats),
        const SizedBox(height: 14),
        _DeliveryLogisticsTabs(
          active: 'drivers',
          onOpenDispatch: onOpenDispatch,
          onOpenTracking: onOpenTracking,
          onOpenZones: onOpenZones,
          onOpenEmergency: onOpenEmergency,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              if (compact) {
                return Column(
                  children: [
                    Flexible(
                      flex: 2,
                      child: _DeliveryDriversInsights(data: data),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 2,
                      child: _DeliveryMapCard(
                        title: 'التتبع المباشر',
                        markers: data.mapMarkers,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 4,
                      child: _DeliveryDriversTableCard(
                        data: data,
                        searchController: searchController,
                        statusFilter: statusFilter,
                        vehicleFilter: vehicleFilter,
                        onStatusChanged: onStatusChanged,
                        onVehicleChanged: onVehicleChanged,
                        onSearchSubmitted: onSearchSubmitted,
                        onReload: onReload,
                        onAddDriver: onAddDriver,
                        onViewDriver: onViewDriver,
                        onMessageDriver: onMessageDriver,
                        onToggleDriver: onToggleDriver,
                      ),
                    ),
                  ],
                );
              }
              return Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        Expanded(
                          child: _DeliveryMapCard(
                            title: 'التتبع المباشر',
                            markers: data.mapMarkers,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _DeliveryUnassignedOrdersCard(
                            orders: data.unassignedOrders,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _DeliveryDriversTableCard(
                      data: data,
                      searchController: searchController,
                      statusFilter: statusFilter,
                      vehicleFilter: vehicleFilter,
                      onStatusChanged: onStatusChanged,
                      onVehicleChanged: onVehicleChanged,
                      onSearchSubmitted: onSearchSubmitted,
                      onReload: onReload,
                      onAddDriver: onAddDriver,
                      onViewDriver: onViewDriver,
                      onMessageDriver: onMessageDriver,
                      onToggleDriver: onToggleDriver,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 280,
                    child: _DeliveryDriversInsights(data: data),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeliveryDriversHeader extends StatelessWidget {
  const _DeliveryDriversHeader({
    required this.serverNow,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
  });

  final DateTime serverNow;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          const _DeliveryHeaderActionButton(
            icon: Icons.settings_outlined,
            label: 'الإعدادات',
          ),
          const SizedBox(width: 7),
          const _DeliveryHeaderActionButton(
            icon: Icons.fullscreen_rounded,
            label: 'ملء الشاشة',
          ),
          if (!showNavigationSidebar) ...[
            const SizedBox(width: 7),
            _OrdersSidebarToggleButton(
              tooltip: 'إظهار القائمة الجانبية',
              icon: Icons.view_sidebar_outlined,
              active: true,
              onTap: onToggleNavigationSidebar,
            ),
          ],
          const SizedBox(width: 7),
          const _DeliveryHeaderActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'الدعم',
            badge: '5',
          ),
          const SizedBox(width: 7),
          const _DeliveryHeaderActionButton(
            icon: Icons.notifications_none_rounded,
            label: 'الإشعارات',
            badge: '12',
          ),
          const Spacer(),
          _MasterStatusPill(label: 'النظام يعمل بشكل طبيعي'),
          const SizedBox(width: 12),
          _MasterDateBlock(serverNow: serverNow),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'إدارة التوصيل واللوجستيات',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E232A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'نظرة عامة على أسطول التوصيل والعمليات اللوجستية',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F7680),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.delivery_dining_outlined,
            color: _kDeepGreen,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _DeliveryHeaderActionButton extends StatelessWidget {
  const _DeliveryHeaderActionButton({
    required this.icon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: null,
        child: SizedBox(
          width: 44,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 50,
                padding: const EdgeInsets.only(top: 7, bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE5E8E5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 17, color: const Color(0xFF4E5660)),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 6.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4E5660),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
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
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
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

class _DriverDispatchWorkspace extends StatelessWidget {
  const _DriverDispatchWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.selectedOrderId,
    required this.selectedDriverId,
    required this.assigning,
    required this.onOrderSelected,
    required this.onDriverSelected,
    required this.onAssign,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onOpenDrivers,
    required this.onOpenTracking,
    required this.onOpenZones,
    required this.onOpenEmergency,
  });

  final _MasterDeliveryLogisticsData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final VoidCallback onSearchSubmitted;
  final int? selectedOrderId;
  final int? selectedDriverId;
  final bool assigning;
  final ValueChanged<int> onOrderSelected;
  final ValueChanged<int> onDriverSelected;
  final VoidCallback onAssign;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onOpenDrivers;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenZones;
  final VoidCallback onOpenEmergency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'توزيع الطلبات على السائقين',
          subtitle: 'توزيع الطلبات تلقائيا أو يدويا على السائقين المتاحين',
          icon: Icons.delivery_dining_rounded,
        ),
        const SizedBox(height: 10),
        _OrdersStatsStrip(cards: data.dispatchStats),
        const SizedBox(height: 10),
        _DeliveryLogisticsTabs(
          active: 'dispatch',
          onOpenDrivers: onOpenDrivers,
          onOpenTracking: onOpenTracking,
          onOpenZones: onOpenZones,
          onOpenEmergency: onOpenEmergency,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1120;
              if (compact) {
                return Column(
                  children: [
                    _DispatchOptionsCard(
                      searchController: searchController,
                      onSearchSubmitted: onSearchSubmitted,
                      assigning: assigning,
                      canAssign:
                          selectedOrderId != null && selectedDriverId != null,
                      onAssign: onAssign,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _AvailableDriversAssignTable(
                        drivers: data.drivers
                            .where((driver) => driver.statusKey == 'available')
                            .toList(),
                        selectedDriverId: selectedDriverId,
                        onDriverSelected: onDriverSelected,
                        onAssignDriver: (driverId) {
                          onDriverSelected(driverId);
                          Future.microtask(onAssign);
                        },
                      ),
                    ),
                  ],
                );
              }
              return Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 330,
                    child: Column(
                      children: [
                        Expanded(
                          child: _DeliveryMapCard(
                            title: 'خريطة التوزيع المباشر',
                            markers: data.mapMarkers,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _DeliveryAssignmentHistoryCard(
                            events: data.assignmentHistory,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        _DispatchOptionsCard(
                          searchController: searchController,
                          onSearchSubmitted: onSearchSubmitted,
                          assigning: assigning,
                          canAssign:
                              selectedOrderId != null &&
                              selectedDriverId != null,
                          onAssign: onAssign,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _AvailableDriversAssignTable(
                            drivers: data.drivers
                                .where(
                                  (driver) => driver.statusKey == 'available',
                                )
                                .toList(),
                            selectedDriverId: selectedDriverId,
                            onDriverSelected: onDriverSelected,
                            onAssignDriver: (driverId) {
                              onDriverSelected(driverId);
                              Future.microtask(onAssign);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 286,
                    child: _UnassignedOrdersListCard(
                      orders: data.unassignedOrders,
                      selectedOrderId: selectedOrderId,
                      onOrderSelected: onOrderSelected,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeliveryLogisticsTabs extends StatelessWidget {
  const _DeliveryLogisticsTabs({
    required this.active,
    this.onOpenDrivers,
    this.onOpenDispatch,
    this.onOpenTracking,
    this.onOpenZones,
    this.onOpenEmergency,
  });

  final String active;
  final VoidCallback? onOpenDrivers;
  final VoidCallback? onOpenDispatch;
  final VoidCallback? onOpenTracking;
  final VoidCallback? onOpenZones;
  final VoidCallback? onOpenEmergency;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (
        'drivers',
        'إدارة السائقين',
        Icons.manage_accounts_outlined,
        onOpenDrivers,
      ),
      (
        'dispatch',
        'توزيع الطلبات على السائقين',
        Icons.assignment_ind_outlined,
        onOpenDispatch,
      ),
      (
        'tracking',
        'التتبع المباشر',
        Icons.location_on_outlined,
        onOpenTracking,
      ),
      ('zones', 'مناطق الخدمة والتوصيل', Icons.map_outlined, onOpenZones),
      (
        'emergency',
        'طوارئ السائقين',
        Icons.emergency_outlined,
        onOpenEmergency,
      ),
    ];
    return SizedBox(
      height: 44,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: _DeliveryTabButton(
                label: tabs[i].$2,
                icon: tabs[i].$3,
                selected: active == tabs[i].$1,
                onTap:
                    tabs[i].$4 ??
                    () => _showMasterSnack(
                      context,
                      'هذا القسم غير متاح لهذا الحساب',
                    ),
              ),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DeliveryTabButton extends StatelessWidget {
  const _DeliveryTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF5ED) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD7EBDD)
                  : const Color(0xFFE7ECE8),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.4,
                    fontWeight: FontWeight.w800,
                    color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
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

class _DeliveryDistributionHeader extends StatelessWidget {
  const _DeliveryDistributionHeader({
    required this.serverNow,
    required this.onToggleNavigationSidebar,
    required this.showNavigationSidebar,
  });

  final DateTime serverNow;
  final VoidCallback onToggleNavigationSidebar;
  final bool showNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                GestureDetector(
                  onTap: onToggleNavigationSidebar,
                  child: Icon(
                    showNavigationSidebar
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    size: 18,
                    color: const Color(0xFF4E5660),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'توزيع الطلبات على السائقين',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B3A26),
                  ),
                ),
              ],
            ),
          ),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                '${serverNow.hour}:${serverNow.minute.toString().padLeft(2, '0')}:${serverNow.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E5660),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: const Color(0xFF4E5660),
              ),
              const SizedBox(width: 8),
              Text(
                '${serverNow.day} مايو 2026',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E5660),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDistributionStats extends StatelessWidget {
  const _DeliveryDistributionStats({required this.stats});

  final List<_OperationsStatCardData> stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Column(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: stat.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(stat.icon, size: 20, color: stat.accent),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: stat.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            stat.trendPositive
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 16,
                            color: stat.trendPositive
                                ? Colors.green
                                : Colors.red,
                          ),
                          Text(
                            stat.trendCaption,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: stat.trendPositive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B3A26),
                      ),
                    ),
                    Text(
                      stat.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E5660),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryDistributionMap extends StatelessWidget {
  const _DeliveryDistributionMap({required this.markers});

  final List<_OperationsMapMarkerData> markers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(30.0444, 31.2357),
              initialZoom: 13,
              backgroundColor: Color(0xFFF0F2F5),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: markers
                    .map(
                      (m) => Marker(
                        point: m.point,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: m.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Icon(m.icon, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: const Icon(Icons.add, size: 20, color: Color(0xFF4E5660)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDistributionOrders extends StatelessWidget {
  const _DeliveryDistributionOrders({required this.orders});

  final List<_DeliveryOrderData> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'الطلبات غير الموزعة (${orders.length})',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B3A26),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: const Color(0xFFE7ECE8)),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderNo,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B3A26),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: order.statusBackground,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: order.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.customer,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5660),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.amountLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7B8A99),
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
    );
  }
}

class _DeliveryDistributionDrivers extends StatelessWidget {
  const _DeliveryDistributionDrivers({required this.drivers});

  final List<_DeliveryDriverData> drivers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'السائقين المتاحين (${drivers.length})',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B3A26),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: drivers.length,
              separatorBuilder: (context, index) =>
                  const VerticalDivider(width: 1, color: Color(0xFFE7ECE8)),
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5ED),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: driver.statusColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            driver.name.isNotEmpty
                                ? driver.name[0].toUpperCase()
                                : '؟',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B3A26),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        driver.name,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B3A26),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            driver.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7B8A99),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: driver.statusBackground,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          driver.statusLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: driver.statusColor,
                          ),
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
    );
  }
}
