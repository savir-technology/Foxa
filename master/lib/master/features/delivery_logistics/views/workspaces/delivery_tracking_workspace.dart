// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _DeliveryTrackingWorkspace extends StatefulWidget {
  const _DeliveryTrackingWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onOpenDrivers,
    required this.onOpenDispatch,
    required this.onOpenZones,
    required this.onOpenEmergency,
  });

  final _MasterDeliveryLogisticsData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final VoidCallback onSearchSubmitted;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onOpenDrivers;
  final VoidCallback onOpenDispatch;
  final VoidCallback onOpenZones;
  final VoidCallback onOpenEmergency;

  @override
  State<_DeliveryTrackingWorkspace> createState() =>
      _DeliveryTrackingWorkspaceState();
}

class _DeliveryTrackingWorkspaceState
    extends State<_DeliveryTrackingWorkspace> {
  String _driverFilter = 'all';
  String _statusFilter = 'all';
  String _areaFilter = 'all';
  bool _liveUpdates = true;

  bool _matchesSearch(String corpus) {
    final query = widget.searchController.text.trim().toLowerCase();
    return query.isEmpty || corpus.toLowerCase().contains(query);
  }

  bool _matchesArea(String corpus) {
    if (_areaFilter == 'all') {
      return true;
    }
    final value = corpus.toLowerCase();
    if (_areaFilter == 'north') {
      return value.contains('north') || value.contains('شمال');
    }
    if (_areaFilter == 'center') {
      return value.contains('center') ||
          value.contains('central') ||
          value.contains('وسط');
    }
    if (_areaFilter == 'south') {
      return value.contains('south') || value.contains('جنوب');
    }
    return true;
  }

  List<_DeliveryDriverData> _filterDrivers(List<_DeliveryDriverData> drivers) {
    return drivers
        .where((driver) {
          final corpus =
              '${driver.name} ${driver.phone} ${driver.vehicleType} ${driver.vehicleNumber} ${driver.statusKey} ${driver.statusLabel} ${driver.currentLocation}';
          final driverMatch = switch (_driverFilter) {
            'available' => driver.statusKey == 'available',
            'busy' => driver.statusKey == 'busy' || driver.activeOrders > 0,
            _ => true,
          };
          return driverMatch && _matchesSearch(corpus) && _matchesArea(corpus);
        })
        .toList(growable: false);
  }

  List<_DeliveryActiveOrderData> _filterOrders(
    List<_DeliveryActiveOrderData> orders,
  ) {
    return orders
        .where((order) {
          final corpus =
              '${order.orderNo} ${order.customer} ${order.driverName} ${order.restaurant} ${order.statusLabel} ${order.relativeLabel}';
          final value = corpus.toLowerCase();
          final statusMatch = switch (_statusFilter) {
            'on_way' => value.contains('way') || value.contains('طريق'),
            'late' => value.contains('late') || value.contains('متأخر'),
            _ => true,
          };
          return statusMatch && _matchesSearch(corpus) && _matchesArea(corpus);
        })
        .toList(growable: false);
  }

  List<_OperationsMapMarkerData> _filterMarkers(
    List<_OperationsMapMarkerData> markers,
  ) {
    return markers
        .where((marker) {
          final corpus = '${marker.type} ${marker.label} ${marker.subtitle}';
          return _matchesSearch(corpus) && _matchesArea(corpus);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final serverNow = widget.serverNow;
    final onReload = _liveUpdates ? widget.onReload : () {};
    final drivers = _filterDrivers(data.drivers);
    final activeOrders = _filterOrders(data.activeOrders);
    final mapMarkers = _filterMarkers(data.mapMarkers);
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: widget.showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: widget.onToggleNavigationSidebar,
          title: 'التتبع المباشر',
          subtitle: 'متابعة السائقين والطلبات الجارية لحظة بلحظة على الخريطة',
          icon: Icons.location_searching_rounded,
        ),
        const SizedBox(height: 10),
        _OrdersStatsStrip(cards: _buildDeliveryTrackingStatCards(data)),
        const SizedBox(height: 10),
        _DeliveryLogisticsTabs(
          active: 'tracking',
          onOpenDrivers: widget.onOpenDrivers,
          onOpenDispatch: widget.onOpenDispatch,
          onOpenZones: widget.onOpenZones,
          onOpenEmergency: widget.onOpenEmergency,
        ),
        const SizedBox(height: 10),
        _DeliveryTrackingFiltersBar(
          searchController: widget.searchController,
          onSearchSubmitted: () {
            widget.onSearchSubmitted();
            setState(() {});
          },
          driverFilter: _driverFilter,
          statusFilter: _statusFilter,
          areaFilter: _areaFilter,
          liveUpdates: _liveUpdates,
          onDriverFilterChanged: (value) =>
              setState(() => _driverFilter = value),
          onStatusFilterChanged: (value) =>
              setState(() => _statusFilter = value),
          onAreaFilterChanged: (value) => setState(() => _areaFilter = value),
          onLiveUpdatesChanged: (value) => setState(() => _liveUpdates = value),
        ),
        const SizedBox(height: 10),
        Expanded(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 1120) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 480,
                          child: _DeliveryTrackingMapSection(
                            markers: mapMarkers,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 320,
                          child: _DeliveryLiveOrdersPanel(orders: activeOrders),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 176,
                          child: _DeliveryTrackingDriversStrip(
                            drivers: drivers,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 176,
                          child: _DeliveryUrgentAlertsPanel(data: data),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: 470,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _DeliveryTrackingMapSection(
                                markers: mapMarkers,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 344,
                              child: _DeliveryLiveOrdersPanel(
                                orders: activeOrders,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _DeliveryTrackingDriversStrip(
                                drivers: drivers,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 344,
                              child: _DeliveryUrgentAlertsPanel(data: data),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<_OperationsStatCardData> _buildDeliveryTrackingStatCards(
  _MasterDeliveryLogisticsData data,
) {
  final onlineDrivers =
      data.summaryInt('available_drivers') + data.summaryInt('busy_drivers');
  final onWayOrders = data.activeOrders
      .where((order) => order.statusLabel.contains('الطريق'))
      .length;
  final zoneCount = math.max(1, (data.mapMarkers.length / 4).round());
  final alertCount = math.min(9, data.unassignedOrders.length);

  return [
    _OperationsStatCardData(
      title: 'الطلبات الجارية',
      value: '${data.activeOrders.length}',
      icon: Icons.delivery_dining_outlined,
      accent: const Color(0xFF0B8F4D),
      background: const Color(0xFFEAF7EE),
      detailLine: '',
      trendLabel: '+12%',
      trendCaption: 'عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'سائقين متصلين الآن',
      value: '$onlineDrivers',
      icon: Icons.people_alt_outlined,
      accent: const Color(0xFF16A34A),
      background: const Color(0xFFEAF7EE),
      detailLine: '',
      trendLabel: '+8%',
      trendCaption: 'عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'الطلبات في الطريق',
      value: '$onWayOrders',
      icon: Icons.local_shipping_outlined,
      accent: const Color(0xFFA855F7),
      background: const Color(0xFFF5EAFE),
      detailLine: '',
      trendLabel: '+15%',
      trendCaption: 'عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'متوسط وقت التوصيل',
      value: '${data.summaryDouble('avg_delivery_minutes').round()}',
      icon: Icons.access_time_rounded,
      accent: const Color(0xFF0EA5E9),
      background: const Color(0xFFE9F7FF),
      detailLine: 'دقيقة',
      trendLabel: '-3%',
      trendCaption: 'عن أمس',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'المناطق النشطة',
      value: '$zoneCount',
      icon: Icons.map_outlined,
      accent: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF3DF),
      detailLine: 'مناطق',
      trendLabel: '',
      trendCaption: '',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'الإنذارات الفعالة',
      value: '$alertCount',
      icon: Icons.warning_amber_rounded,
      accent: const Color(0xFFEF4444),
      background: const Color(0xFFFDECEC),
      detailLine: 'تحتاج متابعة',
      trendLabel: '',
      trendCaption: '',
      trendPositive: false,
    ),
  ];
}

class _DeliveryTrackingFiltersBar extends StatelessWidget {
  const _DeliveryTrackingFiltersBar({
    required this.searchController,
    required this.onSearchSubmitted,
    required this.driverFilter,
    required this.statusFilter,
    required this.areaFilter,
    required this.liveUpdates,
    required this.onDriverFilterChanged,
    required this.onStatusFilterChanged,
    required this.onAreaFilterChanged,
    required this.onLiveUpdatesChanged,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchSubmitted;
  final String driverFilter;
  final String statusFilter;
  final String areaFilter;
  final bool liveUpdates;
  final ValueChanged<String> onDriverFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final ValueChanged<String> onAreaFilterChanged;
  final ValueChanged<bool> onLiveUpdatesChanged;

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
          OutlinedButton.icon(
            onPressed: () {
              onDriverFilterChanged('all');
              onStatusFilterChanged('all');
              onAreaFilterChanged('all');
              searchController.clear();
              onSearchSubmitted();
            },
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('تصفية متقدمة'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(124, 42)),
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: 'جميع السائقين',
            options: const {
              'all': 'جميع السائقين',
              'available': 'السائقون المتاحون',
              'busy': 'السائقون في الطريق',
            },
            onChanged: onDriverFilterChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: 'جميع الحالات',
            options: const {
              'all': 'جميع الحالات',
              'on_way': 'في الطريق',
              'late': 'متأخر',
            },
            onChanged: onStatusFilterChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: 'جميع المناطق',
            options: const {
              'all': 'جميع المناطق',
              'north': 'الشمالية',
              'center': 'الوسط',
              'south': 'الجنوبية',
            },
            onChanged: onAreaFilterChanged,
          ),
          const SizedBox(width: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Switch.adaptive(
                  value: liveUpdates,
                  activeTrackColor: _kPrimaryGreen,
                  activeThumbColor: Colors.white,
                  onChanged: onLiveUpdatesChanged,
                ),
                const SizedBox(width: 4),
                const Text(
                  'تحديث مباشر',
                  style: TextStyle(fontSize: 11.4, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DeliverySearchBox(
              controller: searchController,
              hint: 'ابحث برقم الطلب أو اسم العميل...',
              onSubmitted: onSearchSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTrackingMapSection extends StatelessWidget {
  const _DeliveryTrackingMapSection({required this.markers});

  final List<_OperationsMapMarkerData> markers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Expanded(
                  child: Text(
                    'خريطة التتبع المباشر',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: () => _showMasterSnack(
                    context,
                    'تم عرض كل العناصر المتاحة في هذا القسم',
                  ),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _LiveOperationsMap(
                markers: markers,
                showWeatherBadge: false,
                showLayerPanel: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLiveOrdersPanel extends StatelessWidget {
  const _DeliveryLiveOrdersPanel({required this.orders});

  final List<_DeliveryActiveOrderData> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'الطلبات الجارية (${orders.length})',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showMasterSnack(
                    context,
                    'تم عرض كل العناصر المتاحة في هذا القسم',
                  ),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('لا توجد طلبات جارية الآن'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: math.min(orders.length, 8),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _DeliveryLiveOrderTile(order: order);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLiveOrderTile extends StatelessWidget {
  const _DeliveryLiveOrderTile({required this.order});

  final _DeliveryActiveOrderData order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      order.orderNo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: order.statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DeliveryStatusPill(
                      label: order.statusLabel,
                      color: order.statusColor,
                      background: order.statusColor.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.customer,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.restaurant} • ${order.driverName}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7680),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF6F7680),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.timeLabel,
                      style: const TextStyle(fontSize: 10.6),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.route_outlined,
                      size: 14,
                      color: Color(0xFF6F7680),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.amountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 10.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              _MiniIconButton(
                icon: Icons.call_outlined,
                tooltip: 'اتصال بالسائق',
                onTap: () => _showMasterSnack(
                  context,
                  'رقم هاتف السائق غير متاح في بيانات هذا الطلب',
                ),
              ),
              const SizedBox(height: 6),
              _MiniIconButton(
                icon: Icons.visibility_outlined,
                tooltip: 'عرض التفاصيل',
                onTap: () =>
                    _showMasterSnack(context, 'تفاصيل الطلب ${order.orderNo}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryTrackingDriversStrip extends StatelessWidget {
  const _DeliveryTrackingDriversStrip({required this.drivers});

  final List<_DeliveryDriverData> drivers;

  @override
  Widget build(BuildContext context) {
    final visible = drivers
        .where((driver) => driver.statusKey != 'unavailable')
        .take(8)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'السائقين المتصلين الآن (${visible.length})',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showMasterSnack(
                    context,
                    'تم عرض كل العناصر المتاحة في هذا القسم',
                  ),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('لا توجد بيانات سائقين مباشرة'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final driver = visible[index];
                      return SizedBox(
                        width: 132,
                        child: _DeliveryTrackingDriverCard(driver: driver),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTrackingDriverCard extends StatelessWidget {
  const _DeliveryTrackingDriverCard({required this.driver});

  final _DeliveryDriverData driver;

  @override
  Widget build(BuildContext context) {
    final initials = driver.name.trim().isEmpty
        ? 'س'
        : driver.name.trim().split(' ').take(2).map((part) => part[0]).join();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: driver.statusBackground,
            child: Text(
              initials,
              style: TextStyle(
                color: driver.statusColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            driver.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _DeliveryStatusPill(
            label: driver.statusLabel,
            color: driver.statusColor,
            background: driver.statusBackground,
          ),
          const SizedBox(height: 8),
          Text(
            '${driver.activeOrders} طلبات',
            style: const TextStyle(fontSize: 10.4, color: Color(0xFF6F7680)),
          ),
          const SizedBox(height: 4),
          Text(
            '${driver.rating.toStringAsFixed(1)} ★',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DeliveryUrgentAlertsPanel extends StatelessWidget {
  const _DeliveryUrgentAlertsPanel({required this.data});

  final _MasterDeliveryLogisticsData data;

  @override
  Widget build(BuildContext context) {
    final alerts =
        <(String title, String subtitle, IconData icon, Color color)>[
          for (final order in data.unassignedOrders.take(2))
            (
              'الطلب ${order.orderNo} ينتظر التوزيع',
              '${order.restaurant} • ${order.relativeLabel}',
              Icons.warning_amber_rounded,
              const Color(0xFFF59E0B),
            ),
          for (final order
              in data.activeOrders
                  .where((item) => item.statusLabel.contains('الطريق'))
                  .take(1))
            (
              'متابعة ${order.orderNo} أثناء التوصيل',
              '${order.driverName} • ${order.relativeLabel}',
              Icons.info_outline_rounded,
              const Color(0xFF3B82F6),
            ),
        ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'تنبيهات فورية (${alerts.length})',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          Expanded(
            child: alerts.isEmpty
                ? const Center(child: Text('لا توجد تنبيهات حرجة حالياً'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: alerts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: alert.$4.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: alert.$4.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(alert.$3, color: alert.$4, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    alert.$1,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: alert.$4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.$2,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 10.4,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6F7680),
                                    ),
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
    );
  }
}
