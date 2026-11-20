// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _DeliveryDistributionWorkspace extends StatefulWidget {
  const _DeliveryDistributionWorkspace({
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
    required this.onAssignManual,
    required this.onAssignAutomatic,
    required this.onAssignScheduled,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
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
  final VoidCallback onAssignManual;
  final VoidCallback onAssignAutomatic;
  final VoidCallback onAssignScheduled;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;

  @override
  State<_DeliveryDistributionWorkspace> createState() =>
      _DeliveryDistributionWorkspaceState();
}

class _DeliveryDistributionWorkspaceState
    extends State<_DeliveryDistributionWorkspace> {
  String _selectedDistributionType = 'smart_auto';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ==================== HEADER ====================
          _DistributionHeaderBar(
            serverNow: widget.serverNow,
            showNavigationSidebar: widget.showNavigationSidebar,
            onToggleNavigationSidebar: widget.onToggleNavigationSidebar,
          ),
          const SizedBox(height: 16),

          // ==================== STATISTICS CARDS ====================
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.data.stats.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final stat = widget.data.stats[index];
                return SizedBox(
                  width: 140,
                  child: _DistributionStatCard(stat: stat),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // ==================== MAIN DISTRIBUTION WORKSPACE ====================
          Container(
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
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== LEFT COLUMN: PENDING ORDERS =====
                    SizedBox(
                      width: 280,
                      height: 600,
                      child: _UnassignedOrdersList(
                        orders: widget.data.unassignedOrders,
                        selectedOrderId: widget.selectedOrderId,
                        onOrderSelected: widget.onOrderSelected,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ===== CENTER COLUMN: DISTRIBUTION OPTIONS + MAP =====
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Distribution Options
                          _DistributionOptionsBar(
                            selectedType: _selectedDistributionType,
                            assigning: widget.assigning,
                            canAssignManually:
                                widget.selectedOrderId != null &&
                                widget.selectedDriverId != null,
                            onTypeChanged: (type) {
                              setState(() => _selectedDistributionType = type);
                            },
                            onAssignManual: widget.onAssignManual,
                            onAssignAutomatic: widget.onAssignAutomatic,
                            onAssignScheduled: widget.onAssignScheduled,
                          ),
                          const SizedBox(height: 14),

                          // Map
                          SizedBox(
                            height: 520,
                            child: _DistributionMapCard(
                              markers: widget.data.mapMarkers,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ===== RIGHT COLUMN: DRIVERS TABLE =====
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 600,
                        child: _DistributionDriversTable(
                          drivers: widget.data.drivers,
                          selectedDriverId: widget.selectedDriverId,
                          onDriverSelected: widget.onDriverSelected,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ==================== BOTTOM DISPATCH ACTIVITY ====================
                _DistributionBottomBar(
                  totalDrivers: widget.data.drivers.length,
                  unassignedCount: widget.data.unassignedOrders.length,
                  serverNow: widget.serverNow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HEADER BAR ====================
class _DistributionHeaderBar extends StatelessWidget {
  const _DistributionHeaderBar({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT SIDE
          Row(
            textDirection: TextDirection.rtl,
            children: [
              GestureDetector(
                onTap: onToggleNavigationSidebar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    showNavigationSidebar
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    size: 14,
                    color: const Color(0xFF4E5660),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'توزيع الطلبات على السائقين',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B3A26),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'توزيع الطلبات تلقائياً أو يدويا على السائقين المتاحين',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7B8A99),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // RIGHT SIDE
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Color(0xFF0B3A26),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'النظام يعمل بشكل طبيعي',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B3A26),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${serverNow.hour}:${serverNow.minute.toString().padLeft(2, '0')}:${serverNow.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E5660),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF4E5660),
              ),
              const SizedBox(width: 6),
              Text(
                '${serverNow.day} يوليو 2026',
                style: const TextStyle(
                  fontSize: 11,
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

// ==================== STATISTICS CARD ====================
class _DistributionStatCard extends StatelessWidget {
  const _DistributionStatCard({required this.stat});

  final _OperationsStatCardData stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Trend
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: stat.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat.icon, size: 18, color: stat.accent),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stat.trendPositive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      stat.trendPositive
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      size: 14,
                      color: stat.trendPositive
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                    ),
                    Text(
                      stat.trendCaption,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: stat.trendPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom: Value + Title
          Column(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B3A26),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B8A99),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== DISTRIBUTION OPTIONS BAR ====================
class _DistributionOptionsBar extends StatelessWidget {
  const _DistributionOptionsBar({
    required this.selectedType,
    required this.assigning,
    required this.canAssignManually,
    required this.onTypeChanged,
    required this.onAssignManual,
    required this.onAssignAutomatic,
    required this.onAssignScheduled,
  });

  final String selectedType;
  final bool assigning;
  final bool canAssignManually;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onAssignManual;
  final VoidCallback onAssignAutomatic;
  final VoidCallback onAssignScheduled;

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        'smart_auto',
        'توزيع تلقائي ذكي',
        'اختر أفضل سائق حسب المسافة والأداء',
        Icons.auto_awesome,
      ),
      ('manual', 'توزيع يدوي', 'اختر السائق المناسب لكل طلب', Icons.touch_app),
      (
        'scheduled',
        'توزيع مجدول',
        'تجميع دفعة طلبات لمسارات متوازنة',
        Icons.alt_route_rounded,
      ),
    ];
    final isManual = selectedType == 'manual';
    final action = selectedType == 'scheduled'
        ? onAssignScheduled
        : isManual
        ? onAssignManual
        : onAssignAutomatic;
    final canRun = !assigning && (!isManual || canAssignManually);
    final label = selectedType == 'scheduled'
        ? 'توزيع مجدول الآن'
        : isManual
        ? 'توزيع الطلب المحدد'
        : 'توزيع تلقائي الآن';

    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: assigning ? null : () => onTypeChanged(options[i].$1),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedType == options[i].$1
                          ? const Color(0xFFF0F9F5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedType == options[i].$1
                            ? const Color(0xFF28C76F)
                            : const Color(0xFFE9ECEF),
                        width: selectedType == options[i].$1 ? 2 : 1,
                      ),
                      boxShadow: selectedType == options[i].$1
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF28C76F,
                                ).withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                              ),
                            ],
                    ),
                    child: Column(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          options[i].$4,
                          size: 22,
                          color: selectedType == options[i].$1
                              ? const Color(0xFF0B3A26)
                              : const Color(0xFF7B8A99),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          options[i].$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selectedType == options[i].$1
                                ? const Color(0xFF0B3A26)
                                : const Color(0xFF4E5660),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          options[i].$3,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7B8A99),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < options.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canRun ? action : null,
                icon: assigning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, size: 16),
                label: Text(assigning ? 'جاري التوزيع...' : label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B8F4D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (isManual && !canAssignManually) ...[
              const SizedBox(width: 10),
              const Text(
                'اختر طلبا وسائقا',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B8A99),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ==================== UNASSIGNED ORDERS LIST ====================
class _UnassignedOrdersList extends StatelessWidget {
  const _UnassignedOrdersList({
    required this.orders,
    required this.selectedOrderId,
    required this.onOrderSelected,
  });

  final List<_DeliveryOrderData> orders;
  final int? selectedOrderId;
  final ValueChanged<int> onOrderSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: Color(0xFF0B3A26),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الطلبات غير الموزعة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B3A26),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '(${orders.length})',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B8A99),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    orders.length.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFE9ECEF)),
              itemBuilder: (_, index) {
                final order = orders[index];
                final selected = selectedOrderId == order.orderId;
                return InkWell(
                  onTap: () => onOrderSelected(order.orderId),
                  child: Container(
                    color: selected
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
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
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: order.statusBackground,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                order.statusLabel,
                                style: TextStyle(
                                  fontSize: 9,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E5660),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.amountLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7B8A99),
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

// ==================== DISTRIBUTION MAP CARD ====================
class _DistributionMapCard extends StatelessWidget {
  const _DistributionMapCard({required this.markers});

  final List<_OperationsMapMarkerData> markers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
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
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: m.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                m.icon,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Map Controls
          Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Color(0xFF4E5660),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.zoom_out_map,
                    size: 18,
                    color: Color(0xFF4E5660),
                  ),
                ),
              ],
            ),
          ),

          // Layers button
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9ECEF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.layers,
                size: 18,
                color: Color(0xFF4E5660),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DISTRIBUTION DRIVERS TABLE ====================
class _DistributionDriversTable extends StatelessWidget {
  const _DistributionDriversTable({
    required this.drivers,
    required this.selectedDriverId,
    required this.onDriverSelected,
  });

  final List<_DeliveryDriverData> drivers;
  final int? selectedDriverId;
  final ValueChanged<int> onDriverSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(
                      Icons.delivery_dining_outlined,
                      size: 16,
                      color: Color(0xFF0B3A26),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'السائقين الموزعين',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B3A26),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '(${drivers.length})',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B8A99),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: drivers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFE9ECEF)),
              itemBuilder: (_, index) {
                final driver = drivers[index];
                final selected = selectedDriverId == driver.driverId;
                return InkWell(
                  onTap: () => onDriverSelected(driver.driverId),
                  child: Container(
                    color: selected
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Column(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                driver.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B3A26),
                                ),
                              ),
                            ),
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
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: driver.statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              driver.phone,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7B8A99),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  driver.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7B8A99),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

// ==================== BOTTOM ACTIVITY BAR ====================
class _DistributionBottomBar extends StatelessWidget {
  const _DistributionBottomBar({
    required this.totalDrivers,
    required this.unassignedCount,
    required this.serverNow,
  });

  final int totalDrivers;
  final int unassignedCount;
  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF5ED),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.info_outlined,
                    size: 14,
                    color: Color(0xFF0B3A26),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عرض جميع السائقين',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B3A26),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'آخر تحديث: ${serverNow.hour}:${serverNow.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7B8A99),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF28C76F),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'السائقين: $totalDrivers',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B3A26),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFD32F2F),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'غير موزعة: $unassignedCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
