// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _OrdersHeaderBar extends StatelessWidget {
  const _OrdersHeaderBar({
    required this.serverNow,
    required this.onReload,
    required this.showInsightsSidebar,
    required this.showNavigationSidebar,
    required this.onToggleInsightsSidebar,
    required this.onToggleNavigationSidebar,
    this.title = 'جميع الطلبات',
    this.subtitle = 'عرض وإدارة جميع الطلبات في المنصة',
    this.icon = Icons.receipt_long_outlined,
  });

  final DateTime serverNow;
  final VoidCallback onReload;
  final bool showInsightsSidebar;
  final bool showNavigationSidebar;
  final VoidCallback onToggleInsightsSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // The module is rendered inside _MasterResponsiveShell, which already
    // provides the single global dashboard header. Keeping another header
    // here created a duplicated toolbar on every orders workspace.
    return const SizedBox.shrink();
    /*
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1120;

          return Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const _OrdersHeaderActionButton(
                        icon: Icons.settings_outlined,
                        label: 'الإعدادات',
                      ),
                      const SizedBox(width: 7),
                      const _OrdersHeaderActionButton(
                        icon: Icons.fullscreen_rounded,
                        label: 'ملء الشاشة',
                      ),
                      if (!showInsightsSidebar) ...[
                        const SizedBox(width: 7),
                        _OrdersSidebarToggleButton(
                          tooltip: 'إظهار ملخصات الطلبات',
                          icon: Icons.view_sidebar_outlined,
                          active: true,
                          onTap: onToggleInsightsSidebar,
                        ),
                      ],
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
                      _OrdersHeaderActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'الدعم',
                        badge: '5',
                        onTap: () => _openMasterSupportChats(
                          context,
                          serverNow: serverNow,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const _OrdersHeaderActionButton(
                        icon: Icons.notifications_none_rounded,
                        label: 'الإشعارات',
                        badge: '12',
                      ),
                      const SizedBox(width: 18),
                      if (!isCompact) ...[
                        _MasterStatusPill(label: 'النظام يعمل بشكل طبيعي'),
                        const SizedBox(width: 12),
                      ],
                      _MasterDateBlock(serverNow: serverNow),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 280 : 340),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E232A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6F7680),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(icon, color: _kDeepGreen, size: 28),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    */
  }
}

class _OrdersHeaderActionButton extends StatelessWidget {
  // ignore: unused_element_parameter
  const _OrdersHeaderActionButton({
    required this.icon,
    required this.label,
    // ignore: unused_element_parameter
    this.badge,
    // ignore: unused_element_parameter
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
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
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFE5E8E5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: const Color(0xFF4E5660)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7.8,
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
                      minWidth: 15,
                      minHeight: 15,
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
                        fontSize: 8,
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

class _OrdersStatsStrip extends StatelessWidget {
  const _OrdersStatsStrip({required this.cards});

  final List<_OperationsStatCardData> cards;

  @override
  Widget build(BuildContext context) {
    final visible = cards.take(7).toList();
    return SizedBox(
      height: 70,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            Expanded(child: _OrdersStatMiniCard(card: visible[index])),
            if (index != visible.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _OrdersSidebarToggleButton extends StatelessWidget {
  const _OrdersSidebarToggleButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEAF5ED) : const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? const Color(0xFFD7EBDD)
                    : const Color(0xFFE5E8E5),
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: active ? _kPrimaryGreen : const Color(0xFF4E5660),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersStatMiniCard extends StatelessWidget {
  const _OrdersStatMiniCard({required this.card});

  final _OperationsStatCardData card;

  @override
  Widget build(BuildContext context) {
    final trendColor = card.trendPositive
        ? const Color(0xFF1A8B4A)
        : const Color(0xFFD92C2C);
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E9E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E232A),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E232A),
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      [
                        if (card.trendLabel.trim().isNotEmpty)
                          card.trendLabel.trim(),
                        if (card.trendCaption.trim().isNotEmpty)
                          card.trendCaption.trim(),
                      ].join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.8,
                        fontWeight: FontWeight.w900,
                        color: trendColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      card.trendPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: trendColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: card.background,
              shape: BoxShape.circle,
            ),
            child: Icon(card.icon, size: 16, color: card.accent),
          ),
        ],
      ),
    );
  }
}

class _OrdersToolbar extends StatelessWidget {
  const _OrdersToolbar({
    required this.data,
    required this.onReload,
    required this.searchController,
    required this.paymentFilter,
    required this.statusFilter,
    required this.typeFilter,
    required this.onSearchSubmitted,
    required this.onPaymentChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onExport,
  });

  final _MasterOrdersData data;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String paymentFilter;
  final String statusFilter;
  final String typeFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<String> onStatusChanged;
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
          label: _ordersFilterLabel(paymentFilter, const {
            'all': 'حالة الدفع',
            'visa': 'فيزا',
            'cash': 'كاش',
            'wallet': 'محفظة',
          }),
          options: const {
            'all': 'حالة الدفع',
            'visa': 'فيزا',
            'cash': 'كاش',
            'wallet': 'محفظة',
          },
          onChanged: onPaymentChanged,
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: _ordersFilterLabel(typeFilter, const {
            'all': 'نوع الطلب',
            'delivery': 'توصيل',
            'pickup': 'استلام ذاتي',
          }),
          options: const {
            'all': 'نوع الطلب',
            'delivery': 'توصيل',
            'pickup': 'استلام ذاتي',
          },
          onChanged: onTypeChanged,
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'تاريخ الطلب',
          options: const {'all': 'كل التواريخ'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        _OrdersFilterButton(
          label: 'الموظف',
          options: const {'all': 'كل الموظفين'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: onExport,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(86, 40),
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

class _OrdersFilterButton extends StatelessWidget {
  const _OrdersFilterButton({
    required this.label,
    required this.options,
    required this.onChanged,
    this.selectedKey,
  });

  final String label;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final String? selectedKey;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedKey == null
        ? label
        : options[selectedKey] ?? label;
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => options.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 40,
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF4E5660),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                selectedLabel,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _ordersFilterLabel(String value, Map<String, String> options) {
  return options[value] ?? options['all'] ?? 'الكل';
}

class _OrdersInsightsPanel extends StatelessWidget {
  const _OrdersInsightsPanel({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _OrdersSideCard(
          title: 'قنوات الطلبات',
          children: [_OrdersChannelsDonut(channels: data.channels)],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'إحصائيات مالية اليوم',
          children: [
            for (final item in data.finance)
              _OrdersMetricLine(label: item.label, value: item.value),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'أفضل المطاعم اليوم',
          children: [
            for (var i = 0; i < data.topRestaurants.length; i++)
              _OrdersMetricLine(
                label: '${i + 1}. ${data.topRestaurants[i].name}',
                value: '${data.topRestaurants[i].orders} طلب',
              ),
          ],
        ),
      ],
    );
  }
}

class _OrdersChannelsDonut extends StatelessWidget {
  const _OrdersChannelsDonut({required this.channels});

  final List<_OrdersChannelData> channels;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'لا توجد بيانات',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A919A),
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFF0F8A4A),
      const Color(0xFF30B7D7),
      const Color(0xFFF4B000),
      const Color(0xFFEF4444),
    ];
    final visible = channels.take(4).toList();
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: CustomPaint(
            painter: _OrdersDonutPainter(
              values: visible.map((item) => item.percent.toDouble()).toList(),
              colors: colors,
            ),
            child: Center(
              child: Text(
                '${visible.fold<int>(0, (sum, item) => sum + item.value)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E232A),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              for (var index = 0; index < visible.length; index++)
                _OrdersChannelLegend(
                  item: visible[index],
                  color: colors[index % colors.length],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersChannelLegend extends StatelessWidget {
  const _OrdersChannelLegend({required this.item, required this.color});

  final _OrdersChannelData item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.7,
                fontWeight: FontWeight.w700,
                color: Color(0xFF59616B),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${item.percent}%',
            style: const TextStyle(
              fontSize: 9.7,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E232A),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersDonutPainter extends CustomPainter {
  const _OrdersDonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final basePaint = Paint()
      ..color = const Color(0xFFEFF2F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      basePaint,
    );

    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        sweep - 0.04,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _OrdersDonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _OrdersSideCard extends StatelessWidget {
  const _OrdersSideCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11.8, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          if (children.isEmpty)
            const Text(
              'لا توجد بيانات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF8A919A)),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _OrdersMetricLine extends StatelessWidget {
  const _OrdersMetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF59616B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10.4,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E232A),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersTablePanel extends StatelessWidget {
  const _OrdersTablePanel({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(1010.0, constraints.maxWidth);
        return SizedBox(
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
                const _OrdersTableHeader(),
                Expanded(
                  child: data.orders.isEmpty
                      ? const Center(child: Text('لا توجد طلبات متاحة الآن'))
                      : ListView.separated(
                          itemCount: data.orders.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _OrdersTableRow(order: data.orders[index]),
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

class _OrdersTableHeader extends StatelessWidget {
  const _OrdersTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: Color(0xFF6F7680),
    );
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFCFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: const [
          _OrdersTableCell(
            flex: 10,
            child: Text('رقم الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 16,
            child: Text('العميل', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 18,
            child: Text('المطعم', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 11,
            child: Text('نوع الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 13,
            child: Text(
              'الحالة الحالية',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          _OrdersTableCell(
            flex: 11,
            child: Text('المبلغ', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 11,
            child: Text(
              'طريقة الدفع',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('الوقت', style: style, textAlign: TextAlign.right),
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

class _OrdersTableRow extends StatelessWidget {
  const _OrdersTableRow({required this.order});

  final _MasterOrderRowData order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _OrdersTableCell(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  order.orderNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _kPrimaryGreen,
                  ),
                ),
                Text(
                  order.relativeLabel,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF8A919A)),
                ),
              ],
            ),
          ),
          _OrdersTableCell(
            flex: 16,
            child: _OrdersTwoLine(title: order.customer, subtitle: order.phone),
          ),
          _OrdersTableCell(
            flex: 18,
            child: _OrdersRestaurantCell(order: order),
          ),
          _OrdersTableCell(
            flex: 11,
            child: Text(
              order.typeLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          _OrdersTableCell(flex: 13, child: _OrdersStatusPill(order: order)),
          _OrdersTableCell(
            flex: 11,
            child: Text(
              order.amountLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _OrdersTableCell(flex: 11, child: _OrdersPaymentBadge(order: order)),
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
                  icon: Icons.visibility_outlined,
                  message: 'عرض ${order.orderNo}',
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

class _OrdersTableCell extends StatelessWidget {
  const _OrdersTableCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}

class _OrdersTwoLine extends StatelessWidget {
  const _OrdersTwoLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title.isEmpty ? '-' : title,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.3,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A8088),
          ),
        ),
      ],
    );
  }
}

class _OrdersRestaurantCell extends StatelessWidget {
  const _OrdersRestaurantCell({required this.order});

  final _MasterOrderRowData order;

  @override
  Widget build(BuildContext context) {
    final logoUrl = order.restaurantLogoUrl.trim();
    final fallback = order.restaurant.trim().isEmpty
        ? 'A'
        : order.restaurant.trim().characters.first.toUpperCase();
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 34,
          height: 34,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F4),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE7ECE8)),
          ),
          child: logoUrl.isEmpty
              ? Center(
                  child: Text(
                    fallback,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _kPrimaryGreen,
                    ),
                  ),
                )
              : Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        fallback,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _kPrimaryGreen,
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OrdersTwoLine(
            title: order.restaurant,
            subtitle: order.branch,
          ),
        ),
      ],
    );
  }
}

class _OrdersPaymentBadge extends StatelessWidget {
  const _OrdersPaymentBadge({required this.order});

  final _MasterOrderRowData order;

  @override
  Widget build(BuildContext context) {
    final key = order.paymentKey.toLowerCase();
    final color = key == 'visa'
        ? const Color(0xFF2563EB)
        : key == 'wallet'
        ? _kPrimaryGreen
        : const Color(0xFF1E232A);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Icon(order.paymentIcon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            order.paymentLabel,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.6,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersStatusPill extends StatelessWidget {
  const _OrdersStatusPill({required this.order});

  final _MasterOrderRowData order;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: order.statusBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          order.statusLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: order.statusColor,
          ),
        ),
      ),
    );
  }
}

class _OrdersActionButton extends StatelessWidget {
  const _OrdersActionButton({
    required this.icon,
    required this.message,
    this.order,
  });

  final IconData icon;
  final String message;
  final _MasterOrderRowData? order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        final row = order;
        if (row == null) {
          _showMasterSnack(context, message);
          return;
        }
        if (icon == Icons.visibility_outlined) {
          _showOrderDetailsSheet(context, row);
          return;
        }
        if (icon == Icons.copy_rounded) {
          _copyOrderToClipboard(context, row);
          return;
        }
        if (icon == Icons.print_outlined) {
          _showOrderPrintSheet(context, row);
          return;
        }
        if (icon == Icons.chat_bubble_outline_rounded) {
          _showOrderTimelineSheet(context, row);
          return;
        }
        if (icon == Icons.more_vert_rounded) {
          _showOrderActionsSheet(context, row);
          return;
        }
        _showMasterSnack(context, message);
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Icon(icon, size: 12.5, color: const Color(0xFF4E5660)),
      ),
    );
  }
}

void _copyOrderToClipboard(BuildContext context, _MasterOrderRowData order) {
  final text = [
    'رقم الطلب: ${order.orderNo}',
    'العميل: ${order.customer}',
    'الهاتف: ${order.phone}',
    'المطعم: ${order.restaurant}',
    'النوع: ${order.typeLabel}',
    'الحالة: ${order.statusLabel}',
    'المبلغ: ${order.amountLabel}',
    'الدفع: ${order.paymentLabel}',
    'الوقت: ${order.timeLabel}',
  ].join('\n');
  Clipboard.setData(ClipboardData(text: text));
  _showMasterSnack(context, 'تم نسخ بيانات ${order.orderNo}');
}

void _printOrderFromPreview(BuildContext context, _MasterOrderRowData order) {
  final receiptHtml = _buildPrintableReceiptHtml(order);
  final frame = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..srcdoc = receiptHtml;
  html.document.body?.append(frame);
  frame.onLoad.first.then((_) {
    Future<void>.delayed(const Duration(seconds: 2), frame.remove);
  });
  _showMasterSnack(context, 'جاري طباعة فاتورة ${order.orderNo} فقط');
}

String _buildPrintableReceiptHtml(_MasterOrderRowData order) {
  final qrSvg = _buildQrSvg(_orderQrPayload(order));
  final items = order.items.isEmpty
      ? [
          _OrderReceiptItemData(
            name: 'طلب من المطعم',
            quantity: 1,
            unitPrice: order.amountLabel,
            total: order.amountLabel,
          ),
        ]
      : order.items;
  final rows = items
      .map(
        (item) =>
            '<tr><td>${_htmlEscape(item.name)}</td><td>${item.quantity}</td><td>${_htmlEscape(item.total.isEmpty ? item.unitPrice : item.total)}</td></tr>',
      )
      .join();
  return '''
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>${_htmlEscape(order.orderNo)} Receipt</title>
  <style>
    @page { size: 80mm auto; margin: 4mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #fff;
      color: #111827;
      font-family: Arial, Tahoma, sans-serif;
      font-size: 11px;
      line-height: 1.45;
      direction: rtl;
    }
    .receipt { width: 72mm; margin: 0 auto; padding: 2mm; }
    .center { text-align: center; }
    .brand { font-size: 15px; font-weight: 800; margin-bottom: 2px; }
    .restaurant { font-size: 13px; font-weight: 800; }
    .type { font-size: 12px; margin-top: 2px; }
    .line { border-top: 1px dashed #9ca3af; margin: 8px 0; }
    .meta, table { width: 100%; border-collapse: collapse; }
    .meta td { padding: 2px 0; }
    .meta td:first-child { color: #374151; }
    .meta td:last-child { text-align: left; font-weight: 700; }
    th, td { padding: 4px 0; border-bottom: 1px dashed #d1d5db; }
    th { color: #4b5563; font-weight: 700; }
    td:nth-child(2), th:nth-child(2) { text-align: center; width: 32px; }
    td:last-child, th:last-child { text-align: left; width: 58px; }
    .total { display: flex; justify-content: space-between; font-size: 14px; font-weight: 900; margin-top: 8px; }
    .qr { width: 26mm; height: 26mm; margin: 8px auto 3px; }
    .thanks { margin-top: 10px; font-weight: 700; }
    .small { font-size: 10px; color: #374151; }
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
  <main class="receipt">
    <section class="center">
      <div class="brand">FOXA</div>
      <div class="restaurant">${_htmlEscape(order.restaurant.isEmpty ? 'FOXA' : order.restaurant)}</div>
      <div class="type">${_htmlEscape(order.typeLabel)} - ${order.paymentKey == 'cash' ? 'إيصال طلب' : 'فاتورة'}</div>
    </section>
    <div class="line"></div>
    <table class="meta">
      <tr><td>رقم الطلب</td><td>${_htmlEscape(order.orderNo)}</td></tr>
      <tr><td>الوقت</td><td>${_htmlEscape(order.timeLabel)}</td></tr>
      <tr><td>الدفع</td><td>${_htmlEscape(order.paymentLabel)}</td></tr>
    </table>
    <div class="line"></div>
    <table>
      <thead><tr><th>الصنف</th><th>الكمية</th><th>السعر</th></tr></thead>
      <tbody>$rows</tbody>
    </table>
    <div class="total"><span>الإجمالي</span><span>${_htmlEscape(order.amountLabel)}</span></div>
    <div class="center">
      <div class="thanks">شكرا لثقتكم بنا</div>
      <div class="qr">$qrSvg</div>
      <div class="small">امسح الكود لتتبع طلبك</div>
    </div>
  </main>
  <script>
    window.addEventListener('load', function () {
      setTimeout(function () {
        window.focus();
        window.print();
      }, 120);
    });
  </script>
</body>
</html>
''';
}

String _htmlEscape(String value) {
  return const HtmlEscape().convert(value);
}

String _buildQrSvg(String data) {
  final code = qr.QrCode.fromData(
    data: data,
    errorCorrectLevel: qr.QrErrorCorrectLevel.M,
  );
  final image = qr.QrImage(code);
  final count = image.moduleCount;
  final buffer = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $count $count" shape-rendering="crispEdges">',
  );
  buffer.write('<rect width="$count" height="$count" fill="#fff"/>');
  for (var row = 0; row < count; row++) {
    for (var col = 0; col < count; col++) {
      if (image.isDark(row, col)) {
        buffer.write(
          '<rect x="$col" y="$row" width="1" height="1" fill="#000"/>',
        );
      }
    }
  }
  buffer.write('</svg>');
  return buffer.toString();
}

void _showOrderDetailsSheet(BuildContext context, _MasterOrderRowData order) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تفاصيل الطلب ${order.orderNo}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OrderDetailChip(label: 'العميل', value: order.customer),
                  _OrderDetailChip(label: 'الهاتف', value: order.phone),
                  _OrderDetailChip(label: 'المطعم', value: order.restaurant),
                  _OrderDetailChip(label: 'النوع', value: order.typeLabel),
                  _OrderDetailChip(label: 'الحالة', value: order.statusLabel),
                  _OrderDetailChip(label: 'المبلغ', value: order.amountLabel),
                  _OrderDetailChip(label: 'الدفع', value: order.paymentLabel),
                  _OrderDetailChip(label: 'الوقت', value: order.timeLabel),
                  if (order.scheduledLabel.trim().isNotEmpty)
                    _OrderDetailChip(
                      label: 'الجدولة',
                      value: order.scheduledLabel,
                    ),
                  if (order.addressLabel.trim().isNotEmpty)
                    _OrderDetailChip(
                      label: 'العنوان',
                      value: order.addressLabel,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _copyOrderToClipboard(context, order),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('نسخ البيانات'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showOrderPrintSheet(context, order),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('طباعة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showOrderPrintSheet(BuildContext context, _MasterOrderRowData order) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('معاينة طباعة ${order.orderNo}'),
          content: SizedBox(
            width: 320,
            child: _PrintingReceiptPreview(order: order),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            FilledButton.icon(
              onPressed: () {
                _printOrderFromPreview(context, order);
              },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('طباعة'),
            ),
          ],
        ),
      );
    },
  );
}

void _showOrderTimelineSheet(BuildContext context, _MasterOrderRowData order) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      final steps = [
        ('تم إنشاء الطلب', order.timeLabel),
        ('الحالة الحالية', order.statusLabel),
        ('طريقة الدفع', order.paymentLabel),
        ('المطعم', order.restaurant),
      ];
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'متابعة ${order.orderNo}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (final step in steps)
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: _kPrimaryGreen,
                  ),
                  title: Text(step.$1),
                  subtitle: Text(step.$2),
                  dense: true,
                ),
            ],
          ),
        ),
      );
    },
  );
}

void _showOrderActionsSheet(BuildContext context, _MasterOrderRowData order) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('عرض التفاصيل'),
                onTap: () => _showOrderDetailsSheet(context, order),
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('نسخ بيانات الطلب'),
                onTap: () => _copyOrderToClipboard(context, order),
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('معاينة الطباعة'),
                onTap: () => _showOrderPrintSheet(context, order),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OrderDetailChip extends StatelessWidget {
  const _OrderDetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6F7680),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

void _exportOrdersToClipboard(
  BuildContext context,
  _MasterOrdersData data,
  String label, {
  List<_MasterOrderRowData>? orders,
}) {
  final exportOrders = orders ?? data.orders;
  final rows = <List<String>>[
    [
      'order_no',
      'customer',
      'phone',
      'restaurant',
      'type',
      'status',
      'amount',
      'payment',
      'time',
    ],
    for (final order in exportOrders)
      [
        order.orderNo,
        order.customer,
        order.phone,
        order.restaurant,
        order.typeLabel,
        order.statusLabel,
        order.amountLabel,
        order.paymentLabel,
        order.timeLabel,
      ],
  ];
  final table = StringBuffer('<table><thead><tr>');
  for (final cell in rows.first) {
    table.write('<th>${_excelEscape(cell)}</th>');
  }
  table.write('</tr></thead><tbody>');
  for (final row in rows.skip(1)) {
    table.write('<tr>');
    for (final cell in row) {
      table.write('<td>${_excelEscape(cell)}</td>');
    }
    table.write('</tr>');
  }
  table.write('</tbody></table>');
  final blob = html.Blob([
    '\uFEFF<html><meta charset="utf-8"><body>${table.toString()}</body></html>',
  ], 'application/vnd.ms-excel');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = 'orders_export.xls'
    ..click();
  html.Url.revokeObjectUrl(url);
  _showMasterSnack(
    context,
    'تم تحميل ملف Excel لـ $label (${exportOrders.length} طلب)',
  );
}

String _excelEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

void _showOrdersPrintSheet(
  BuildContext context,
  _MasterOrdersData data,
  String label,
) {
  final firstOrder = data.orders.isEmpty ? null : data.orders.first;
  showDialog<void>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('طباعة $label'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'عدد الطلبات الجاهزة: ${data.orders.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (firstOrder == null)
                  const Text('لا توجد طلبات متاحة للطباعة الآن')
                else
                  _PrintingReceiptPreview(order: firstOrder),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            FilledButton.icon(
              onPressed: firstOrder == null
                  ? null
                  : () {
                      _exportOrdersToClipboard(context, data, label);
                      _showMasterSnack(
                        context,
                        'تم تجهيز بيانات $label للطباعة من قاعدة البيانات',
                      );
                      _printOrderFromPreview(context, firstOrder);
                    },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('طباعة'),
            ),
          ],
        ),
      );
    },
  );
}

void _showRestaurantsSheet(BuildContext context, _MasterOrdersData data) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'جميع المطاعم حسب الطلبات',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (data.topRestaurants.isEmpty)
                const Text('لا توجد بيانات مطاعم متاحة الآن')
              else
                for (final restaurant in data.topRestaurants)
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(restaurant.name),
                    trailing: Text('${restaurant.orders} طلب'),
                    dense: true,
                  ),
            ],
          ),
        ),
      );
    },
  );
}

class _OrdersPaginationBar extends StatelessWidget {
  const _OrdersPaginationBar({required this.data});

  final _MasterOrdersData data;

  @override
  Widget build(BuildContext context) {
    final paginationButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(64, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7ECE8))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'عرض ${data.orders.length} من ${data.total}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6F7680),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: null,
            style: paginationButtonStyle,
            child: const Text('السابق'),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kPrimaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data.page}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: null,
            style: paginationButtonStyle,
            child: const Text('التالي'),
          ),
        ],
      ),
    );
  }
}

class _OrdersFooterStatus extends StatelessWidget {
  const _OrdersFooterStatus({required this.serverNow});

  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    // The unified master shell owns the only platform status footer.
    // Workspaces can still keep this widget for source compatibility, but it
    // must not render a second bottom bar inside a module.
    return const SizedBox.shrink();
    /*
    return LayoutBuilder(
      builder: (context, constraints) {
        final statusItems = const [
          _MasterStatusChip(
            item: _DashboardStatusItemData(
              label: 'Database',
              isHealthy: true,
              dotHex: '#1A8B4A',
            ),
          ),
          _MasterStatusChip(
            item: _DashboardStatusItemData(
              label: 'Orders API',
              isHealthy: true,
              dotHex: '#1A8B4A',
            ),
          ),
          _MasterStatusChip(
            item: _DashboardStatusItemData(
              label: 'Notifications',
              isHealthy: true,
              dotHex: '#1A8B4A',
            ),
          ),
        ];

        if (constraints.maxWidth < 620) {
          return Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'آخر تحديث: ${_formatArabicTimeLabel(serverNow)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6F7680)),
              ),
              ...statusItems,
            ],
          );
        }

    return Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'آخر تحديث: ${_formatArabicTimeLabel(serverNow)}',
              style: const TextStyle(fontSize: 10.4, color: Color(0xFF6F7680)),
            ),
            const Spacer(),
            statusItems[0],
            const SizedBox(width: 14),
            statusItems[1],
            const SizedBox(width: 14),
            statusItems[2],
          ],
        );
      },
    ); */
  }
}

class _OrdersRightSidebar extends StatelessWidget {
  const _OrdersRightSidebar({
    required this.activeSubPage,
    required this.onLogisticsTap,
    required this.onRestaurantsTap,
    required this.onUsersTap,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onCollapse,
  });

  final String activeSubPage;
  final VoidCallback onLogisticsTap;
  final VoidCallback onRestaurantsTap;
  final VoidCallback onUsersTap;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final menuItems = <_OperationsSidebarTileData>[
      const _OperationsSidebarTileData(
        label: 'التوصيل واللوجستيات',
        icon: Icons.delivery_dining_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'إدارة المطاعم',
        icon: Icons.storefront_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'العملاء',
        icon: Icons.people_alt_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة المالية',
        icon: Icons.account_balance_wallet_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'التسويق والنمو',
        icon: Icons.campaign_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'مركز التواصل',
        icon: Icons.notifications_active_outlined,
      ),
      // 'الجودة وخدمة العملاء' removed per user request
      const _OperationsSidebarTileData(
        label: 'التقارير والتحليلات',
        icon: Icons.query_stats_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'إعدادات المنصة',
        icon: Icons.settings_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة والصلاحيات',
        icon: Icons.admin_panel_settings_outlined,
      ),
    ];

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
                  Expanded(
                    child: Text(
                      'التنقل',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E232A),
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
                selected: true,
                onTap: () => onSubPageTap('all'),
              ),
              const SizedBox(height: 10),
              _OrdersManagementSubMenu(
                activeSubPage: activeSubPage,
                onSubPageTap: onSubPageTap,
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < menuItems.length; index++) ...[
                _OperationsSidebarMenuItem(
                  data: menuItems[index],
                  onTap: () {
                    switch (index) {
                      case 0:
                        onLogisticsTap();
                        break;
                      case 1:
                        onRestaurantsTap();
                        break;
                      case 2:
                        onUsersTap();
                        break;
                      case 3:
                        _navigateToRememberedMasterSection(context, 'finance');
                        break;
                      case 4:
                        _navigateToRememberedMasterSection(
                          context,
                          'marketing',
                        );
                        break;
                      case 5:
                        _navigateToRememberedMasterSection(
                          context,
                          'communication',
                        );
                        break;
                      case 6:
                        _navigateToRememberedMasterSection(context, 'reports');
                        break;
                      case 7:
                        _navigateToRememberedMasterSection(context, 'settings');
                        break;
                      case 8:
                        _navigateToRememberedMasterSection(context, 'access');
                        break;
                    }
                  },
                ),
                if (index != menuItems.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersManagementSubMenu extends StatelessWidget {
  const _OrdersManagementSubMenu({
    required this.activeSubPage,
    required this.onSubPageTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all', 'جميع الطلبات', Icons.radio_button_checked_rounded),
      ('statuses', 'حالات الطلب', Icons.flag_outlined),
      ('scheduled', 'الطلبات المجدولة', Icons.event_note_outlined),
      ('pickup', 'طلبات الاستلام الذاتي', Icons.store_mall_directory_outlined),
      ('printing', 'الطباعة والفواتير', Icons.print_outlined),
      ('chats', 'دردشات الطلبات المرتبطة', Icons.chat_bubble_outline_rounded),
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
          for (var index = 0; index < items.length; index++) ...[
            Builder(
              builder: (context) {
                final selected = activeSubPage == items[index].$1;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSubPageTap(items[index].$1),
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
                            items[index].$3,
                            size: 16,
                            color: selected
                                ? _kPrimaryGreen
                                : const Color(0xFF4E5660),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              items[index].$2,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.6,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected
                                    ? _kPrimaryGreen
                                    : const Color(0xFF4E5660),
                                height: 1.0,
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
            if (index != items.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _OrdersSidebarTile extends StatelessWidget {
  const _OrdersSidebarTile({
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: selected ? _kPrimaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE7ECE8),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF4E5660),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF4E5660),
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.circle, size: 6, color: Colors.white)
            else
              const Icon(
                Icons.chevron_left_rounded,
                size: 15,
                color: Color(0xFFB1B7BD),
              ),
          ],
        ),
      ),
    );
  }
}
