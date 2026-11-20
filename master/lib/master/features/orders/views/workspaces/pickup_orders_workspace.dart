// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _PickupOrdersWorkspace extends StatelessWidget {
  const _PickupOrdersWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.paymentFilter,
    required this.statusFilter,
    required this.onSearchSubmitted,
    required this.onPaymentChanged,
    required this.onStatusChanged,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onExport,
  });

  final _MasterOrdersData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String paymentFilter;
  final String statusFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<String> onStatusChanged;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final stats = _pickupOrdersStats(data);
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'طلبات الاستلام الذاتي (Pickup)',
          subtitle:
              'عرض وإدارة جميع الطلبات التي يختار فيها العميل الاستلام من المطعم',
          icon: Icons.store_mall_directory_outlined,
        ),
        const SizedBox(height: 8),
        _OrdersStatsStrip(cards: stats),
        const SizedBox(height: 8),
        _PickupOrdersToolbar(
          data: data,
          onReload: onReload,
          searchController: searchController,
          paymentFilter: paymentFilter,
          statusFilter: statusFilter,
          onSearchSubmitted: onSearchSubmitted,
          onPaymentChanged: onPaymentChanged,
          onStatusChanged: onStatusChanged,
          onExport: onExport,
        ),
        const SizedBox(height: 8),
        _PickupStatusTabs(data: data),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 220, child: _PickupOrdersInsights(data: data)),
              const SizedBox(width: 8),
              Expanded(child: _PickupOrdersTablePanel(data: data)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickupOrdersToolbar extends StatelessWidget {
  const _PickupOrdersToolbar({
    required this.data,
    required this.onReload,
    required this.searchController,
    required this.paymentFilter,
    required this.statusFilter,
    required this.onSearchSubmitted,
    required this.onPaymentChanged,
    required this.onStatusChanged,
    required this.onExport,
  });

  final _MasterOrdersData data;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String paymentFilter;
  final String statusFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6F7680),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearchSubmitted(),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'ابحث برقم الطلب أو اسم العميل أو المطعم...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9AA1AA),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E232A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _OrdersFilterButton(
          label: _ordersFilterLabel(paymentFilter, const {
            'all': 'طرق الدفع',
            'visa': 'فيزا',
            'cash': 'كاش',
            'wallet': 'محفظة',
          }),
          options: const {
            'all': 'طرق الدفع',
            'visa': 'فيزا',
            'cash': 'كاش',
            'wallet': 'محفظة',
          },
          onChanged: onPaymentChanged,
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'اليوم',
          options: const {'all': 'اليوم'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: _ordersFilterLabel(statusFilter, _ordersStatusFilterOptions),
          options: _ordersStatusFilterOptions,
          onChanged: onStatusChanged,
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'جميع المطاعم',
          options: const {'all': 'جميع المطاعم'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: () => _showOrdersPrintSheet(context, data, 'طلبات Pickup'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(74, 40),
            side: const BorderSide(color: Color(0xFFE7ECE8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.print_outlined, size: 16),
          label: const Text('طباعة'),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: onExport,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(74, 40),
            side: const BorderSide(color: Color(0xFFE7ECE8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('تصدير'),
        ),
      ],
    );
  }
}

class _PickupStatusTabs extends StatelessWidget {
  const _PickupStatusTabs({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    final preparing = _pickupStatusCount(data, ['تحضير']);
    final ready = _pickupStatusCount(data, ['جاهز']);
    final received = _pickupStatusCount(data, ['تم', 'مكتملة', 'تسليم']);
    final canceled = _pickupStatusCount(data, ['ملغي', 'ملغ']);
    final items = [
      ('الكل', data.total, const Color(0xFF4E5660)),
      ('قيد التحضير', preparing, const Color(0xFFD79A00)),
      ('جاهز للاستلام', ready, const Color(0xFF2563EB)),
      ('تم الاستلام', received, _kPrimaryGreen),
      ('ملغي', canceled, const Color(0xFFD92C2C)),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (final item in items) ...[
            Expanded(
              child: Container(
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.$1 == 'الكل'
                      ? const Color(0xFFF6F7F8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 10.2,
                        fontWeight: FontWeight.w900,
                        color: item.$3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.$3.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${item.$2}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: item.$3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickupOrdersInsights extends StatelessWidget {
  const _PickupOrdersInsights({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    final timeChannels = data.timeChannels
        .where((item) => item.value > 0 || item.percent > 0)
        .toList();
    return ListView(
      children: [
        _OrdersSideCard(
          title: 'توزيع الطلبات حسب الوقت',
          children: [_OrdersChannelsDonut(channels: timeChannels)],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'المطاعم الأعلى طلبات Pickup',
          children: data.topRestaurants.isEmpty
              ? []
              : [
                  for (final restaurant in data.topRestaurants.take(5))
                    _OrdersMetricLine(
                      label: restaurant.name,
                      value: '${restaurant.orders}',
                    ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: () => _showRestaurantsSheet(context, data),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE7ECE8)),
                      foregroundColor: _kPrimaryGreen,
                    ),
                    child: const Text(
                      'عرض جميع المطاعم',
                      style: TextStyle(fontSize: 10.5),
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'معلومات سريعة',
          children: [
            _OrdersMetricLine(
              label: 'متوسط وقت الطلب',
              value: '${data.avgPreparationMinutes} دقيقة',
            ),
            _OrdersMetricLine(
              label: 'نسبة الإلغاء',
              value:
                  '${data.total == 0 ? 0 : ((_pickupStatusCount(data, ['ملغي', 'ملغ']) / data.total) * 100).toStringAsFixed(1)}%',
            ),
            _OrdersMetricLine(
              label: 'الطلبات الجاهزة الآن',
              value: '${_pickupStatusCount(data, ['جاهز'])}',
            ),
          ],
        ),
      ],
    );
  }
}

class _PickupOrdersTablePanel extends StatelessWidget {
  const _PickupOrdersTablePanel({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.circle, size: 8, color: _kPrimaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        'قائمة طلبات الاستلام الذاتي (${data.total})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const _PickupOrdersTableHeader(),
                Expanded(
                  child: data.orders.isEmpty
                      ? const Center(
                          child: Text('لا توجد طلبات استلام ذاتي متاحة الآن'),
                        )
                      : ListView.separated(
                          itemCount: data.orders.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _PickupOrdersTableRow(order: data.orders[index]),
                        ),
                ),
                _OrdersPaginationBar(data: data),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PickupOrdersTableHeader extends StatelessWidget {
  const _PickupOrdersTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: Color(0xFF6F7680),
    );
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFFFBFCFB)),
      child: Row(
        textDirection: TextDirection.rtl,
        children: const [
          _OrdersTableCell(
            flex: 9,
            child: Text('رقم الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 13,
            child: Text('العميل', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 16,
            child: Text('المطعم', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 13,
            child: Text(
              'وقت الاستلام المطلوب',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('الحالة', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text(
              'طريقة الدفع',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('وقت الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 12,
            child: Text('الإجراءات', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _PickupOrdersTableRow extends StatelessWidget {
  const _PickupOrdersTableRow({required this.order});

  final _MasterOrderRowData order;

  @override
  Widget build(BuildContext context) {
    final pickupTitle = order.scheduledLabel.trim().isEmpty
        ? 'فوري'
        : order.scheduledLabel.trim();
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _OrdersTableCell(
            flex: 9,
            child: _OrdersTwoLine(
              title: order.orderNo.replaceFirst('#', '#P'),
              subtitle: order.relativeLabel,
            ),
          ),
          _OrdersTableCell(
            flex: 13,
            child: _OrdersTwoLine(title: order.customer, subtitle: order.phone),
          ),
          _OrdersTableCell(
            flex: 16,
            child: _OrdersRestaurantCell(order: order),
          ),
          _OrdersTableCell(
            flex: 13,
            child: _OrdersTwoLine(
              title: pickupTitle,
              subtitle: order.timeLabel,
            ),
          ),
          _OrdersTableCell(flex: 10, child: _OrdersStatusPill(order: order)),
          _OrdersTableCell(flex: 10, child: _OrdersPaymentBadge(order: order)),
          _OrdersTableCell(
            flex: 10,
            child: _OrdersTwoLine(
              title: order.timeLabel,
              subtitle: order.relativeLabel,
            ),
          ),
          _OrdersTableCell(
            flex: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OrdersActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  message: 'متابعة ${order.orderNo}',
                  order: order,
                ),
                const SizedBox(width: 6),
                _OrdersActionButton(
                  icon: Icons.print_outlined,
                  message: 'طباعة ${order.orderNo}',
                  order: order,
                ),
                const SizedBox(width: 6),
                _OrdersActionButton(
                  icon: Icons.visibility_outlined,
                  message: 'عرض ${order.orderNo}',
                  order: order,
                ),
                const SizedBox(width: 6),
                _OrdersActionButton(
                  icon: Icons.more_vert_rounded,
                  message: 'إجراءات ${order.orderNo}',
                  order: order,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_OperationsStatCardData> _pickupOrdersStats(_MasterOrdersData data) {
  final preparing = _pickupStatusCount(data, ['تحضير']);
  final ready = _pickupStatusCount(data, ['جاهز']);
  final received = _pickupStatusCount(data, ['تم', 'مكتملة', 'تسليم']);
  final canceled = _pickupStatusCount(data, ['ملغي', 'ملغ']);
  return [
    _pickupStat(
      title: 'متوسط التحضير',
      value: '${data.avgPreparationMinutes}',
      icon: Icons.access_time_rounded,
      color: const Color(0xFF64748B),
      caption: 'دقيقة',
    ),
    _pickupStat(
      title: 'ملغي',
      value: '$canceled',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFD92C2C),
      positive: false,
    ),
    _pickupStat(
      title: 'تم الاستلام',
      value: '$received',
      icon: Icons.check_circle_outline_rounded,
      color: _kPrimaryGreen,
    ),
    _pickupStat(
      title: 'جاهز للاستلام',
      value: '$ready',
      icon: Icons.shopping_bag_outlined,
      color: const Color(0xFF2563EB),
    ),
    _pickupStat(
      title: 'قيد التحضير',
      value: '$preparing',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFFF59E0B),
    ),
    _pickupStat(
      title: 'اليوم',
      value: '${data.orders.length}',
      icon: Icons.today_outlined,
      color: const Color(0xFF2563EB),
    ),
    _pickupStat(
      title: 'إجمالي طلبات Pickup',
      value: '${data.total}',
      icon: Icons.shopping_bag_outlined,
      color: const Color(0xFF4E5660),
    ),
  ];
}

_OperationsStatCardData _pickupStat({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  String caption = 'عن أمس',
  bool positive = true,
}) {
  return _OperationsStatCardData(
    title: title,
    value: value,
    icon: icon,
    accent: color,
    background: color.withValues(alpha: 0.11),
    detailLine: '',
    trendLabel: positive ? '+$value' : '-$value',
    trendCaption: caption,
    trendPositive: positive,
  );
}

int _pickupStatusCount(_MasterOrdersData data, List<String> needles) {
  return data.orders.where((order) {
    final status = order.statusLabel;
    return needles.any(status.contains);
  }).length;
}
