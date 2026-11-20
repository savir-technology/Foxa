// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _ScheduledOrdersWorkspace extends StatelessWidget {
  const _ScheduledOrdersWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.typeFilter,
    required this.onSearchSubmitted,
    required this.onTypeChanged,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onExport,
  });

  final _MasterOrdersData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String typeFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onTypeChanged;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final cards = _scheduledOrdersStats(data);
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'الطلبات المجدولة',
          subtitle: 'عرض وإدارة جميع الطلبات المجدولة مسبقا',
          icon: Icons.event_note_outlined,
        ),
        const SizedBox(height: 8),
        _OrdersStatsStrip(cards: cards),
        const SizedBox(height: 8),
        _ScheduledOrdersToolbar(
          data: data,
          onReload: onReload,
          searchController: searchController,
          typeFilter: typeFilter,
          onSearchSubmitted: onSearchSubmitted,
          onTypeChanged: onTypeChanged,
          onExport: onExport,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 220, child: _ScheduledOrdersInsights(data: data)),
              const SizedBox(width: 8),
              Expanded(child: _ScheduledOrdersTablePanel(data: data)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduledOrdersToolbar extends StatelessWidget {
  const _ScheduledOrdersToolbar({
    required this.data,
    required this.onReload,
    required this.searchController,
    required this.typeFilter,
    required this.onSearchSubmitted,
    required this.onTypeChanged,
    required this.onExport,
  });

  final _MasterOrdersData data;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String typeFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onTypeChanged;
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
                      hintText:
                          'ابحث برقم الطلب أو العميل أو المطعم أو رقم الهاتف...',
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
          label: 'تاريخ الجدولة',
          options: const {'all': 'كل التواريخ'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: _ordersFilterLabel(typeFilter, const {
            'all': 'طرق الطلب',
            'delivery': 'توصيل',
            'pickup': 'استلام ذاتي',
          }),
          options: const {
            'all': 'طرق الطلب',
            'delivery': 'توصيل',
            'pickup': 'استلام ذاتي',
          },
          onChanged: onTypeChanged,
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'جميع المطاعم',
          options: const {'all': 'جميع المطاعم'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: () =>
              _showOrdersPrintSheet(context, data, 'الطلبات المجدولة'),
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

class _ScheduledOrdersInsights extends StatelessWidget {
  const _ScheduledOrdersInsights({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    final delivery = data.orders
        .where((order) => order.typeLabel.contains('توصيل'))
        .length;
    final pickup = data.orders.length - delivery;
    final morning = data.orders.length;
    final noon = 0;
    final evening = 0;
    final timeTotal = math.max(1, morning + noon + evening);
    final timeChannels = [
      _OrdersChannelData(
        label: 'صباحا',
        value: morning,
        percent: (morning / timeTotal * 100).round(),
      ),
      _OrdersChannelData(label: 'ظهرا', value: noon, percent: 0),
      _OrdersChannelData(label: 'مساء', value: evening, percent: 0),
    ];
    return ListView(
      children: [
        _OrdersSideCard(
          title: 'التقويم',
          children: [_ScheduledMiniCalendar(total: data.total)],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'توزيع حسب الوقت',
          children: [_OrdersChannelsDonut(channels: timeChannels)],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'طرق الطلب',
          children: [
            _OrdersMetricLine(label: 'توصيل', value: '$delivery'),
            _OrdersMetricLine(label: 'استلام ذاتي', value: '$pickup'),
          ],
        ),
      ],
    );
  }
}

class _ScheduledMiniCalendar extends StatelessWidget {
  const _ScheduledMiniCalendar({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          const Text(
            'هذا الشهر',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 6,
            children: [
              for (var day = 1; day <= 28; day++)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: day == 17
                        ? _kPrimaryGreen
                        : day % 6 == 0
                        ? const Color(0xFFEAF5ED)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE7ECE8)),
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 8.6,
                      fontWeight: FontWeight.w800,
                      color: day == 17 ? Colors.white : const Color(0xFF4E5660),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$total طلب مجدول',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _kPrimaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledOrdersTablePanel extends StatelessWidget {
  const _ScheduledOrdersTablePanel({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
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
                        Text(
                          'قائمة الطلبات المجدولة (${data.total})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _ScheduledOrdersTableHeader(),
                  Expanded(
                    child: data.orders.isEmpty
                        ? const Center(
                            child: Text('لا توجد طلبات مجدولة متاحة الآن'),
                          )
                        : ListView.separated(
                            itemCount: data.orders.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) =>
                                _ScheduledOrdersTableRow(
                                  order: data.orders[index],
                                ),
                          ),
                  ),
                  _OrdersPaginationBar(data: data),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduledOrdersTableHeader extends StatelessWidget {
  const _ScheduledOrdersTableHeader();

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
            flex: 9,
            child: Text(
              'طريقة الطلب',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          _OrdersTableCell(
            flex: 12,
            child: Text(
              'موعد التنفيذ',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          _OrdersTableCell(
            flex: 12,
            child: Text('العنوان', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 9,
            child: Text('الحالة', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('الإجراءات', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ScheduledOrdersTableRow extends StatelessWidget {
  const _ScheduledOrdersTableRow({required this.order});

  final _MasterOrderRowData order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _OrdersTableCell(
            flex: 9,
            child: _OrdersTwoLine(
              title: order.orderNo,
              subtitle: order.scheduledLabel.isEmpty ? 'مجدول' : 'مجدول',
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
            flex: 9,
            child: Text(
              order.typeLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          _OrdersTableCell(
            flex: 12,
            child: _OrdersTwoLine(
              title: order.scheduledLabel.isEmpty
                  ? order.timeLabel
                  : order.scheduledLabel,
              subtitle: order.relativeLabel,
            ),
          ),
          _OrdersTableCell(
            flex: 12,
            child: _OrdersTwoLine(
              title: order.addressLabel.isEmpty ? '-' : order.addressLabel,
              subtitle: '',
            ),
          ),
          _OrdersTableCell(flex: 9, child: _OrdersStatusPill(order: order)),
          _OrdersTableCell(
            flex: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OrdersActionButton(
                  icon: Icons.visibility_outlined,
                  message: 'عرض ${order.orderNo}',
                  order: order,
                ),
                const SizedBox(width: 6),
                _OrdersActionButton(
                  icon: Icons.copy_rounded,
                  message: 'نسخ ${order.orderNo}',
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

List<_OperationsStatCardData> _scheduledOrdersStats(_MasterOrdersData data) {
  final today = data.orders
      .where((order) => order.scheduledLabel.contains('اليوم'))
      .length;
  final tomorrow = data.orders
      .where(
        (order) =>
            order.scheduledLabel.contains('غداً') ||
            order.scheduledLabel.contains('غدا'),
      )
      .length;
  final canceled = data.orders
      .where((order) => order.statusLabel.contains('ملغ'))
      .length;
  return [
    _scheduledStat(
      title: 'مكتملة (تم تنفيذها)',
      value: '0',
      icon: Icons.check_circle_outline_rounded,
      color: _kPrimaryGreen,
    ),
    _scheduledStat(
      title: 'ملغاة',
      value: '$canceled',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFD92C2C),
      positive: false,
    ),
    _scheduledStat(
      title: 'هذا الأسبوع',
      value: '${data.total}',
      icon: Icons.event_available_outlined,
      color: _kPrimaryGreen,
    ),
    _scheduledStat(
      title: 'غداً',
      value: '$tomorrow',
      icon: Icons.calendar_month_outlined,
      color: const Color(0xFFF59E0B),
    ),
    _scheduledStat(
      title: 'اليوم',
      value: '$today',
      icon: Icons.today_outlined,
      color: const Color(0xFF2563EB),
    ),
    _scheduledStat(
      title: 'إجمالي المجدولة',
      value: '${data.total}',
      icon: Icons.event_note_outlined,
      color: const Color(0xFF7C3AED),
    ),
  ];
}

_OperationsStatCardData _scheduledStat({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
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
    trendCaption: 'عن أمس',
    trendPositive: positive,
  );
}

const Map<String, String> _ordersStatusFilterOptions = {
  'all': 'حالة الطلب',
  'pending': 'جديد',
  'preparing': 'قيد التحضير',
  'ready': 'جاهز',
  'with_driver': 'مع السائق',
  'on_way': 'في الطريق',
  'delivered': 'تم التسليم',
  'canceled': 'ملغي',
  'returned': 'مردود',
};

const Map<String, String> _ordersTypeFilterOptions = {
  'all': 'طرق الطلب',
  'delivery': 'توصيل',
  'pickup': 'استلام ذاتي',
};

List<_OperationsStatCardData> _orderStatusStatsForPage(
  List<_OperationsStatCardData> cards,
) {
  final ordered = [
    _statusCardByTitle(cards, ['جديد']),
    _statusCardByTitle(cards, ['قيد التحضير']),
    _statusCardByTitle(cards, ['جاهزة', 'جاهز']),
    _statusCardByTitle(cards, ['مع السائق']),
    _statusCardByTitle(cards, ['تم التسليم', 'مكتملة']),
    _statusCardByTitle(cards, ['ملغي', 'ملغية']),
    _statusCardByTitle(cards, ['مردود']),
  ];
  return ordered;
}

_OperationsStatCardData _statusCardByTitle(
  List<_OperationsStatCardData> cards,
  List<String> needles,
) {
  for (final card in cards) {
    for (final needle in needles) {
      if (card.title.contains(needle)) {
        return card;
      }
    }
  }
  final title = needles.first;
  return _fallbackStatusCard(title);
}

_OperationsStatCardData _fallbackStatusCard(String title) {
  final isDanger =
      title.contains('ملغي') ||
      title.contains('مردود') ||
      title.contains('مرد');
  final isWarning = title.contains('تحضير') || title.contains('سائق');
  final color = isDanger
      ? const Color(0xFFD92C2C)
      : isWarning
      ? const Color(0xFFF59E0B)
      : _kPrimaryGreen;
  final background = isDanger
      ? const Color(0xFFFDEEEF)
      : isWarning
      ? const Color(0xFFFFF4E4)
      : const Color(0xFFEAF5ED);
  final icon = title.contains('مرد')
      ? Icons.rotate_left_rounded
      : title.contains('ملغي')
      ? Icons.cancel_outlined
      : title.contains('تحضير')
      ? Icons.kitchen_rounded
      : title.contains('سائق')
      ? Icons.delivery_dining_outlined
      : title.contains('جاهز')
      ? Icons.receipt_long_outlined
      : Icons.add_circle_outline_rounded;
  return _OperationsStatCardData(
    title: title,
    value: '0',
    icon: icon,
    accent: color,
    background: background,
    detailLine: '',
    trendLabel: '0',
    trendCaption: 'اليوم',
    trendPositive: !isDanger,
  );
}
