// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _DeliveryDriversInsights extends StatelessWidget {
  const _DeliveryDriversInsights({required this.data});

  final _MasterDeliveryLogisticsData data;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, data.summaryInt('total_drivers'));
    final available = data.summaryInt('available_drivers');
    final busy = data.summaryInt('busy_drivers');
    final unavailable = data.summaryInt('unavailable_drivers');
    return SingleChildScrollView(
      child: Column(
        children: [
          _OrdersSideCard(
            title: 'حالة السائقين',
            children: [
              Center(
                child: SizedBox.square(
                  dimension: 78,
                  child: CustomPaint(
                    painter: _OrdersDonutPainter(
                      values: [
                        available.toDouble(),
                        busy.toDouble(),
                        unavailable.toDouble(),
                      ],
                      colors: const [
                        Color(0xFF1A8B4A),
                        Color(0xFF2563EB),
                        Color(0xFF9AA1AA),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _OrdersMetricLine(
                label: 'متاح',
                value: '$available (${((available / total) * 100).round()}%)',
              ),
              _OrdersMetricLine(
                label: 'مشغول',
                value: '$busy (${((busy / total) * 100).round()}%)',
              ),
              _OrdersMetricLine(
                label: 'غير متاح',
                value:
                    '$unavailable (${((unavailable / total) * 100).round()}%)',
              ),
            ],
          ),
          const SizedBox(height: 6),
          _OrdersSideCard(
            title: 'أداء التوصيل اليوم',
            children: [
              _OrdersMetricLine(
                label: 'متوسط وقت التوصيل',
                value:
                    '${data.summaryDouble('avg_delivery_minutes').round()} دقيقة',
              ),
              _OrdersMetricLine(
                label: 'طلبات قيد التوصيل',
                value: '${data.summaryInt('active_delivery_orders')}',
              ),
              _OrdersMetricLine(
                label: 'طلبات موزعة اليوم',
                value: '${data.summaryInt('assigned_today')}',
              ),
              _OrdersMetricLine(
                label: 'طلبات غير موزعة',
                value: '${data.summaryInt('unassigned_orders')}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          _OrdersSideCard(
            title: 'حالة المركبات',
            children: [
              for (final entry in _asMap(
                data.summary['vehicle_counts'],
              ).entries.take(5))
                _OrdersMetricLine(
                  label: entry.key.toString(),
                  value: entry.value.toString(),
                ),
              if (_asMap(data.summary['vehicle_counts']).isEmpty)
                const _OrdersMetricLine(label: 'لا توجد بيانات', value: '0'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDriversTableCard extends StatelessWidget {
  const _DeliveryDriversTableCard({
    required this.data,
    required this.searchController,
    required this.statusFilter,
    required this.vehicleFilter,
    required this.onStatusChanged,
    required this.onVehicleChanged,
    required this.onSearchSubmitted,
    required this.onReload,
    required this.onAddDriver,
    required this.onViewDriver,
    required this.onMessageDriver,
    required this.onToggleDriver,
  });

  final _MasterDeliveryLogisticsData data;
  final TextEditingController searchController;
  final String statusFilter;
  final String vehicleFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onVehicleChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onReload;
  final VoidCallback onAddDriver;
  final ValueChanged<_DeliveryDriverData> onViewDriver;
  final ValueChanged<_DeliveryDriverData> onMessageDriver;
  final ValueChanged<_DeliveryDriverData> onToggleDriver;

  @override
  Widget build(BuildContext context) {
    const statusOptions = {
      'all': 'جميع الحالات',
      'available': 'متاح',
      'busy': 'مشغول',
      'unavailable': 'غير متاح',
    };
    const vehicleOptions = {
      'all': 'كل المركبات',
      'bike': 'دراجة',
      'car': 'سيارة',
      'motorcycle': 'دراجة نارية',
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    'قائمة السائقين (${data.drivers.length})',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: _DeliverySearchBox(
                    controller: searchController,
                    hint: 'ابحث عن سائق بالاسم أو رقم الهاتف...',
                    onSubmitted: onSearchSubmitted,
                  ),
                ),
                _OrdersFilterButton(
                  label: _ordersFilterLabel(statusFilter, statusOptions),
                  options: statusOptions,
                  onChanged: onStatusChanged,
                ),
                _OrdersFilterButton(
                  label: _ordersFilterLabel(vehicleFilter, vehicleOptions),
                  options: vehicleOptions,
                  onChanged: onVehicleChanged,
                ),
                ElevatedButton.icon(
                  onPressed: onAddDriver,
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('إضافة سائق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(78, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ],
            ),
          ),
          const _DeliveryDriversTableHeader(),
          Expanded(
            child: data.drivers.isEmpty
                ? const Center(child: Text('لا توجد بيانات سائقين متاحة الآن'))
                : ListView.separated(
                    itemCount: data.drivers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _DeliveryDriverTableRow(
                        driver: data.drivers[index],
                        onView: onViewDriver,
                        onMessage: onMessageDriver,
                        onToggle: onToggleDriver,
                      );
                    },
                  ),
          ),
          _DeliveryTableFooter(label: 'إجمالي ${data.drivers.length} سائق'),
        ],
      ),
    );
  }
}

class _DeliveryDriversTableHeader extends StatelessWidget {
  const _DeliveryDriversTableHeader();

  @override
  Widget build(BuildContext context) {
    return _DeliveryHeaderRow(
      columns: const [
        (18, 'السائق'),
        (13, 'الهاتف'),
        (13, 'المركبة'),
        (10, 'الحالة'),
        (15, 'الموقع الحالي'),
        (9, 'طلبات اليوم'),
        (8, 'تقييم'),
        (14, 'الإجراءات'),
      ],
    );
  }
}

class _DeliveryDriverTableRow extends StatelessWidget {
  const _DeliveryDriverTableRow({
    required this.driver,
    required this.onView,
    required this.onMessage,
    required this.onToggle,
  });

  final _DeliveryDriverData driver;
  final ValueChanged<_DeliveryDriverData> onView;
  final ValueChanged<_DeliveryDriverData> onMessage;
  final ValueChanged<_DeliveryDriverData> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _OrdersTableCell(
            flex: 18,
            child: _OrdersTwoLine(title: driver.name, subtitle: driver.phone),
          ),
          _OrdersTableCell(
            flex: 13,
            child: Text(
              driver.phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10.5),
            ),
          ),
          _OrdersTableCell(
            flex: 13,
            child: _OrdersTwoLine(
              title: driver.vehicleType,
              subtitle: driver.vehicleNumber,
            ),
          ),
          _OrdersTableCell(
            flex: 10,
            child: _DeliveryStatusPill(
              label: driver.statusLabel,
              color: driver.statusColor,
              background: driver.statusBackground,
            ),
          ),
          _OrdersTableCell(
            flex: 15,
            child: Text(
              driver.currentLocation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10.5),
            ),
          ),
          _OrdersTableCell(
            flex: 9,
            child: Text(
              '${driver.todayOrders}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _OrdersTableCell(
            flex: 8,
            child: Text(
              driver.rating.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _OrdersTableCell(
            flex: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniIconButton(
                  icon: Icons.visibility_outlined,
                  tooltip: 'عرض ${driver.name}',
                  onTap: () => onView(driver),
                ),
                const SizedBox(width: 4),
                _MiniIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'مراسلة ${driver.name}',
                  onTap: () => onMessage(driver),
                ),
                const SizedBox(width: 4),
                _MiniIconButton(
                  icon: driver.statusKey == 'unavailable'
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  tooltip: 'إجراءات ${driver.name}',
                  onTap: () => onToggle(driver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchOptionsCard extends StatelessWidget {
  const _DispatchOptionsCard({
    required this.searchController,
    required this.onSearchSubmitted,
    required this.assigning,
    required this.canAssign,
    required this.onAssign,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchSubmitted;
  final bool assigning;
  final bool canAssign;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'خيارات التوزيع',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            textDirection: TextDirection.rtl,
            children: const [
              Expanded(
                child: _DistributionModeCard(
                  title: 'توزيع تلقائي ذكي',
                  subtitle: 'اختيار أفضل سائق حسب المسافة والحمولة',
                  icon: Icons.auto_awesome_rounded,
                  selected: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DistributionModeCard(
                  title: 'توزيع يدوي',
                  subtitle: 'اختيار السائق المناسب لكل طلب',
                  icon: Icons.touch_app_outlined,
                  selected: false,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DistributionModeCard(
                  title: 'توزيع بالجدولة',
                  subtitle: 'تجميع عدة طلبات لمسار واحد',
                  icon: Icons.alt_route_rounded,
                  selected: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _DeliverySearchBox(
                  controller: searchController,
                  hint: 'ابحث عن طلب أو مطعم أو منطقة...',
                  onSubmitted: onSearchSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              _OrdersFilterButton(
                label: 'نطاق البحث',
                options: const {'9': '9 كم', '5': '5 كم', '12': '12 كم'},
                onChanged: (_) => onSearchSubmitted(),
              ),
              const SizedBox(width: 8),
              _OrdersFilterButton(
                label: 'أقرب سائق',
                options: const {
                  'nearest': 'أقرب سائق',
                  'rating': 'الأعلى تقييما',
                  'load': 'الأقل حمولة',
                },
                onChanged: (_) => onSearchSubmitted(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: canAssign && !assigning ? onAssign : null,
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
            label: Text(assigning ? 'جاري التوزيع...' : 'توزيع تلقائي الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionModeCard extends StatelessWidget {
  const _DistributionModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF1F8F4) : const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _kPrimaryGreen : const Color(0xFFE7ECE8),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? _kPrimaryGreen : const Color(0xFF6F7680),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7680),
                    height: 1.2,
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

class _UnassignedOrdersListCard extends StatelessWidget {
  const _UnassignedOrdersListCard({
    required this.orders,
    required this.selectedOrderId,
    required this.onOrderSelected,
  });

  final List<_DeliveryOrderData> orders;
  final int? selectedOrderId;
  final ValueChanged<int> onOrderSelected;

  @override
  Widget build(BuildContext context) {
    return _DeliveryListShell(
      title: 'الطلبات غير الموزعة (${orders.length})',
      footer: OutlinedButton(
        onPressed: () => _showMasterSnack(
          context,
          'تم تحديث قائمة الطلبات من قاعدة البيانات',
        ),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
        child: const Text('عرض جميع الطلبات غير الموزعة'),
      ),
      child: orders.isEmpty
          ? const Center(child: Text('لا توجد طلبات غير موزعة'))
          : ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = orders[index];
                final selected = selectedOrderId == order.orderId;
                return _DeliveryOrderSelectableTile(
                  order: order,
                  selected: selected,
                  onTap: () => onOrderSelected(order.orderId),
                );
              },
            ),
    );
  }
}

class _AvailableDriversAssignTable extends StatelessWidget {
  const _AvailableDriversAssignTable({
    required this.drivers,
    required this.selectedDriverId,
    required this.onDriverSelected,
    required this.onAssignDriver,
  });

  final List<_DeliveryDriverData> drivers;
  final int? selectedDriverId;
  final ValueChanged<int> onDriverSelected;
  final ValueChanged<int> onAssignDriver;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactRows = constraints.maxHeight < 210;
        final rowHeight = compactRows ? 38.0 : 50.0;
        return _DeliveryListShell(
          title: 'السائقون المتاحون الآن (${drivers.length})',
          footer: compactRows
              ? null
              : const _DeliveryTableFooter(label: 'عرض جميع السائقين'),
          child: Column(
            children: [
              const _AvailableDriversAssignHeader(),
              Expanded(
                child: drivers.isEmpty
                    ? const Center(child: Text('لا توجد بيانات سائقين متاحة'))
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: drivers.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final driver = drivers[index];
                          final selected = selectedDriverId == driver.driverId;
                          return _AvailableDriverAssignRow(
                            driver: driver,
                            selected: selected,
                            height: rowHeight,
                            compact: compactRows,
                            onTap: () {
                              onDriverSelected(driver.driverId);
                              onAssignDriver(driver.driverId);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvailableDriverAssignRow extends StatelessWidget {
  const _AvailableDriverAssignRow({
    required this.driver,
    required this.selected,
    required this.height,
    required this.compact,
    required this.onTap,
  });

  final _DeliveryDriverData driver;
  final bool selected;
  final double height;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: selected ? const Color(0xFFF1F8F4) : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _OrdersTableCell(
            flex: 18,
            child: _OrdersTwoLine(title: driver.name, subtitle: driver.phone),
          ),
          _OrdersTableCell(
            flex: 10,
            child: _DeliveryStatusPill(
              label: driver.statusLabel,
              color: driver.statusColor,
              background: driver.statusBackground,
            ),
          ),
          _OrdersTableCell(
            flex: 14,
            child: Text(
              driver.currentLocation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: compact ? 9.4 : 10.2),
            ),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text(
              '${driver.activeOrders} / 3',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 9.6 : 10.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _OrdersTableCell(
            flex: 9,
            child: Text(
              driver.rating.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: Size(compact ? 50 : 58, compact ? 26 : 30),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'تعيين',
                  style: TextStyle(fontSize: compact ? 9.8 : 10.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableDriversAssignHeader extends StatelessWidget {
  const _AvailableDriversAssignHeader();

  @override
  Widget build(BuildContext context) {
    return _DeliveryHeaderRow(
      columns: const [
        (18, 'السائق'),
        (10, 'الحالة'),
        (14, 'الموقع الحالي'),
        (10, 'الحمولة الحالية'),
        (9, 'التقييم'),
        (10, 'الإجراء'),
      ],
    );
  }
}

class _DeliveryMapCard extends StatelessWidget {
  const _DeliveryMapCard({required this.title, required this.markers});

  final String title;
  final List<_OperationsMapMarkerData> markers;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          _DeliveryPanelHeader(title: title, icon: Icons.my_location_rounded),
          Expanded(
            child: _LiveOperationsMap(
              markers: markers,
              showWeatherBadge: false,
              showLayerPanel: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryActiveOrdersCard extends StatelessWidget {
  const _DeliveryActiveOrdersCard({required this.orders});

  final List<_DeliveryActiveOrderData> orders;

  @override
  Widget build(BuildContext context) {
    return _DeliveryListPanel(
      title: 'الطلبات قيد التوصيل (${orders.length})',
      emptyText: 'لا توجد طلبات قيد التوصيل',
      children: [
        for (final order in orders.take(8))
          _DeliveryCompactOrderTile(
            orderNo: order.orderNo,
            title: order.restaurant,
            subtitle: order.driverName,
            status: order.statusLabel,
            statusColor: order.statusColor,
            timeLabel: order.timeLabel,
          ),
      ],
    );
  }
}

class _DeliveryUnassignedOrdersCard extends StatelessWidget {
  const _DeliveryUnassignedOrdersCard({required this.orders});

  final List<_DeliveryOrderData> orders;

  @override
  Widget build(BuildContext context) {
    return _DeliveryListPanel(
      title: 'طلبات قبل التوصيل (${orders.length})',
      emptyText: 'لا توجد طلبات قبل التوصيل',
      children: [
        for (final order in orders.take(8))
          _DeliveryCompactOrderTile(
            orderNo: order.orderNo,
            title: order.restaurant,
            subtitle: order.addressLabel,
            status: order.statusLabel,
            statusColor: order.statusColor,
            timeLabel: order.timeLabel,
          ),
      ],
    );
  }
}

class _DeliveryAssignmentHistoryCard extends StatelessWidget {
  const _DeliveryAssignmentHistoryCard({required this.events});

  final List<_DeliveryAssignmentEventData> events;

  @override
  Widget build(BuildContext context) {
    return _DeliveryListPanel(
      title: 'آخر عمليات التوزيع',
      emptyText: 'لا توجد عمليات توزيع حديثة',
      children: [
        for (final event in events.take(8))
          _DeliveryCompactOrderTile(
            orderNo: event.orderNo,
            title: event.restaurant,
            subtitle: event.driverName,
            status: event.statusLabel,
            statusColor: _kPrimaryGreen,
            timeLabel: event.timeLabel,
          ),
      ],
    );
  }
}

class _DeliveryListPanel extends StatelessWidget {
  const _DeliveryListPanel({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _DeliveryListShell(
      title: title,
      child: children.isEmpty
          ? Center(child: Text(emptyText))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: children.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => children[index],
            ),
    );
  }
}

class _DeliveryCompactOrderTile extends StatelessWidget {
  const _DeliveryCompactOrderTile({
    required this.orderNo,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.timeLabel,
  });

  final String orderNo;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  orderNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, height: 1.1),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.8,
                    color: Color(0xFF6F7680),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeLabel,
                style: const TextStyle(fontSize: 9, color: Color(0xFF6F7680)),
              ),
              const SizedBox(height: 5),
              _DeliveryStatusPill(
                label: status,
                color: statusColor,
                background: statusColor.withValues(alpha: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliverySearchBox extends StatelessWidget {
  const _DeliverySearchBox({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 15),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7ECE8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7ECE8)),
          ),
        ),
      ),
    );
  }
}

class _DeliveryStatusPill extends StatelessWidget {
  const _DeliveryStatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DeliveryTableFooter extends StatelessWidget {
  const _DeliveryTableFooter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7ECE8))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6F7680),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(54, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('السابق', style: TextStyle(fontSize: 10.2)),
          ),
          const SizedBox(width: 6),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kPrimaryGreen,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(54, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('التالي', style: TextStyle(fontSize: 10.2)),
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7ECE8)),
          ),
          child: Icon(
            icon,
            size: 12,
            color: onTap == null
                ? const Color(0xFFB8C0CA)
                : const Color(0xFF4E5660),
          ),
        ),
      ),
    );
  }
}

class _RestaurantLogoThumb extends StatelessWidget {
  const _RestaurantLogoThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: url.trim().isEmpty
          ? const Icon(Icons.storefront_outlined, size: 18)
          : Image.network(url, fit: BoxFit.cover),
    );
  }
}

class _DeliveryHeaderRow extends StatelessWidget {
  const _DeliveryHeaderRow({required this.columns});

  final List<(int, String)> columns;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      color: Color(0xFF6F7680),
    );
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 5),
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
                style: style,
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryPanelHeader extends StatelessWidget {
  const _DeliveryPanelHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 13, color: _kPrimaryGreen),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryListShell extends StatelessWidget {
  const _DeliveryListShell({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          _DeliveryPanelHeader(title: title, icon: Icons.adjust_rounded),
          Expanded(child: child),
          if (footer != null)
            Padding(padding: const EdgeInsets.all(8), child: footer!),
        ],
      ),
    );
  }
}

class _DeliveryOrderSelectableTile extends StatelessWidget {
  const _DeliveryOrderSelectableTile({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final _DeliveryOrderData order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? const Color(0xFFF1F8F4) : Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            _RestaurantLogoThumb(url: order.restaurantLogoUrl),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        order.orderNo,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DeliveryStatusPill(
                        label: order.statusLabel,
                        color: order.statusColor,
                        background: order.statusBackground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    order.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    order.addressLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.4,
                      color: Color(0xFF6F7680),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        order.amountLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        order.timeLabel,
                        style: const TextStyle(
                          fontSize: 9.4,
                          color: Color(0xFF6F7680),
                        ),
                      ),
                    ],
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
