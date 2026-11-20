// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _OrderStatusesWorkspace extends StatelessWidget {
  const _OrderStatusesWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.paymentFilter,
    required this.statusFilter,
    required this.typeFilter,
    required this.onSearchSubmitted,
    required this.onPaymentChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
  });

  final _MasterOrdersData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String paymentFilter;
  final String statusFilter;
  final String typeFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    final statusCards = _orderStatusStatsForPage(data.stats);
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'حالات الطلب',
          subtitle: 'عرض ومراقبة جميع حالات الطلب عبر المنصة',
          icon: Icons.assignment_turned_in_outlined,
        ),
        const SizedBox(height: 8),
        _OrdersStatsStrip(cards: statusCards),
        const SizedBox(height: 8),
        _OrderStatusesToolbar(
          onReload: onReload,
          searchController: searchController,
          paymentFilter: paymentFilter,
          statusFilter: statusFilter,
          typeFilter: typeFilter,
          onSearchSubmitted: onSearchSubmitted,
          onPaymentChanged: onPaymentChanged,
          onStatusChanged: onStatusChanged,
          onTypeChanged: onTypeChanged,
        ),
        const SizedBox(height: 8),
        _OrderStatusFlow(cards: data.stats),
        const SizedBox(height: 8),
        Expanded(child: _OrderStatusesTablePanel(data: data)),
      ],
    );
  }
}

class _OrderStatusesToolbar extends StatelessWidget {
  const _OrderStatusesToolbar({
    required this.onReload,
    required this.searchController,
    required this.paymentFilter,
    required this.statusFilter,
    required this.typeFilter,
    required this.onSearchSubmitted,
    required this.onPaymentChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  final VoidCallback onReload;
  final TextEditingController searchController;
  final String paymentFilter;
  final String statusFilter;
  final String typeFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;

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
                          'ابحث برقم الطلب أو اسم العميل أو رقم الهاتف...',
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
          label: _ordersFilterLabel(statusFilter, _ordersStatusFilterOptions),
          options: _ordersStatusFilterOptions,
          onChanged: onStatusChanged,
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
          label: _ordersFilterLabel(paymentFilter, const {
            'all': 'الدفع',
            'visa': 'فيزا',
            'cash': 'كاش',
            'wallet': 'محفظة',
          }),
          options: const {
            'all': 'الدفع',
            'visa': 'فيزا',
            'cash': 'كاش',
            'wallet': 'محفظة',
          },
          onChanged: onPaymentChanged,
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'جميع المطاعم',
          options: const {'all': 'جميع المطاعم'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'جميع السائقين',
          options: const {'all': 'جميع السائقين'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'اليوم',
          options: const {'all': 'اليوم'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onReload,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Row(
              children: [
                Switch(
                  value: true,
                  onChanged: (_) => onReload(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: _kPrimaryGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 5),
                const Text(
                  'تحديث تلقائي',
                  style: TextStyle(fontSize: 10.8, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: _kPrimaryGreen,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderStatusFlow extends StatelessWidget {
  const _OrderStatusFlow({required this.cards});

  final List<_OperationsStatCardData> cards;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _OrderStatusStepData.fromCard(_statusCardByTitle(cards, ['جديد'])),
      _OrderStatusStepData.fromCard(_statusCardByTitle(cards, ['قيد التحضير'])),
      _OrderStatusStepData.fromCard(
        _statusCardByTitle(cards, ['جاهزة', 'جاهز']),
      ),
      _OrderStatusStepData.fromCard(_statusCardByTitle(cards, ['مع السائق'])),
      _OrderStatusStepData.fromCard(_statusCardByTitle(cards, ['في الطريق'])),
      _OrderStatusStepData.fromCard(
        _statusCardByTitle(cards, ['تم التسليم', 'مكتملة']),
      ),
      _OrderStatusStepData.fromCard(
        _statusCardByTitle(cards, ['ملغي', 'ملغية']),
      ),
      _OrderStatusStepData.fromCard(_statusCardByTitle(cards, ['مردود'])),
    ];
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Text(
            'تسلسل حالة الطلب',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E232A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  Expanded(child: _OrderStatusFlowStep(step: steps[index])),
                  if (index != steps.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: Color(0xFF9AA1AA),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusFlowStep extends StatelessWidget {
  const _OrderStatusFlowStep({required this.step});

  final _OrderStatusStepData step;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: step.background,
            shape: BoxShape.circle,
          ),
          child: Icon(step.icon, size: 16, color: step.color),
        ),
        const SizedBox(height: 4),
        Text(
          step.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          step.value,
          style: TextStyle(
            fontSize: 8.8,
            fontWeight: FontWeight.w900,
            color: step.color,
          ),
        ),
      ],
    );
  }
}

class _OrderStatusStepData {
  const _OrderStatusStepData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  factory _OrderStatusStepData.fromCard(_OperationsStatCardData card) {
    return _OrderStatusStepData(
      title: card.title.replaceAll(' اليوم', ''),
      value: card.value,
      icon: card.icon,
      color: card.accent,
      background: card.background,
    );
  }
}

class _OrderStatusesTablePanel extends StatelessWidget {
  const _OrderStatusesTablePanel({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(1080.0, constraints.maxWidth);
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
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: _kPrimaryGreen,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'الطلبات حسب الحالة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'طلب (${data.total})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF59616B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _OrderStatusesTableHeader(),
                  Expanded(
                    child: data.orders.isEmpty
                        ? const Center(child: Text('لا توجد طلبات متاحة الآن'))
                        : ListView.separated(
                            itemCount: data.orders.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) =>
                                _OrderStatusesTableRow(
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

class _OrderStatusesTableHeader extends StatelessWidget {
  const _OrderStatusesTableHeader();

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
            flex: 11,
            child: Text('قيمة الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 12,
            child: Text('حالة الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('الوقت', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 13,
            child: Text('السائق', style: style, textAlign: TextAlign.right),
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

class _OrderStatusesTableRow extends StatelessWidget {
  const _OrderStatusesTableRow({required this.order});

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
            flex: 10,
            child: _OrdersTwoLine(
              title: order.orderNo,
              subtitle: order.relativeLabel,
            ),
          ),
          _OrdersTableCell(
            flex: 15,
            child: _OrdersTwoLine(title: order.customer, subtitle: order.phone),
          ),
          _OrdersTableCell(
            flex: 18,
            child: _OrdersRestaurantCell(order: order),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text(
              order.typeLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          _OrdersTableCell(
            flex: 11,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.amountLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                _OrdersPaymentBadge(order: order),
              ],
            ),
          ),
          _OrdersTableCell(flex: 12, child: _OrdersStatusPill(order: order)),
          _OrdersTableCell(
            flex: 10,
            child: _OrdersTwoLine(
              title: order.timeLabel,
              subtitle: order.relativeLabel,
            ),
          ),
          _OrdersTableCell(
            flex: 13,
            child: _OrdersTwoLine(
              title: order.driverName.trim().isEmpty
                  ? '-'
                  : order.driverName.trim(),
              subtitle: order.driverName.trim().isEmpty ? '' : 'مكلف بالطلب',
            ),
          ),
          _OrdersTableCell(
            flex: 12,
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
                  icon: Icons.chat_bubble_outline_rounded,
                  message: 'متابعة ${order.orderNo}',
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
