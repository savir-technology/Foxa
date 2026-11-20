import 'dart:math' as math;

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/model/report_models.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/remote/order_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final AccountingData _accountingData = AccountingData();
  final ItemsData _itemsData = ItemsData();

  SalesReportResponse? _salesReport;
  List<OrderModel> _orders = const [];
  List<_ProductSalesRow> _topProducts = const [];
  bool _loading = true;
  String? _error;

  DashboardAuthController? get _auth =>
      Get.isRegistered<DashboardAuthController>()
          ? Get.find<DashboardAuthController>()
          : null;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _accountingData.getSalesReport(),
        OrderData.fetchOrders(),
        _itemsData.getItems(),
      ]);

      final orders = (results[1] as List<OrderModel>);
      final items = (results[2] as List<ItemsModel>?) ?? <ItemsModel>[];
      final products = await _loadTopProducts(orders, items);

      if (!mounted) return;
      setState(() {
        _salesReport = results[0] as SalesReportResponse?;
        _orders = orders;
        _topProducts = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<List<_ProductSalesRow>> _loadTopProducts(
    List<OrderModel> orders,
    List<ItemsModel> items,
  ) async {
    final vendorId = _auth?.vendorId ?? 0;
    final imageById = <int, String>{};
    for (final item in items) {
      final id = int.tryParse(item.itemsId ?? '');
      final image = item.itemsImage?.trim() ?? '';
      if (id != null && image.isNotEmpty) {
        imageById[id] = _resolveItemImageUrl(image);
      }
    }

    final counts = <int, _ProductAccumulator>{};
    final relevantOrders = orders
        .where((order) => !order.isCancelledOrder)
        .take(60)
        .toList(growable: false);

    await Future.wait(
      relevantOrders.map((order) async {
        final orderId = order.ordersId;
        if (orderId == null) return;
        try {
          final details = await OrderData.fetchOrderItemDetails(
            '$orderId',
            order.vendorId ?? vendorId,
          );
          for (final detail in details) {
            final accumulator = counts.putIfAbsent(
              detail.itemId,
              () => _ProductAccumulator(
                name: detail.itemName,
                imageUrl: imageById[detail.itemId],
              ),
            );
            accumulator.count += detail.quantity;
          }
        } catch (_) {
          // Product details are an enhancement; the report still renders
          // safely if one order details request fails.
        }
      }),
    );

    final totalSold =
        counts.values.fold<int>(0, (sum, item) => sum + item.count);
    final rows = counts.entries.map((entry) {
      final item = entry.value;
      return _ProductSalesRow(
        name: item.name,
        ordersCount: item.count,
        percent: totalSold == 0 ? 0 : (item.count / totalSold) * 100,
        imageUrl: item.imageUrl,
      );
    }).toList()
      ..sort((a, b) => b.ordersCount.compareTo(a.ordersCount));

    return rows.take(5).toList(growable: false);
  }

  int get _totalOrders => _orders.length;

  double get _totalRevenue {
    final summaryValue = _salesReport?.summary.totalSales ?? 0;
    if (summaryValue > 0) return summaryValue;
    return _orders.fold<double>(0, (sum, order) => sum + order.totalPriceValue);
  }

  int get _cancelledOrders =>
      _orders.where((order) => order.isCancelledOrder).length;

  int get _scheduledOrders =>
      _orders.where((order) => order.lifecycleBucket == 'scheduled').length;

  int get _deliveredOrders =>
      _orders.where((order) => order.isDeliveredOrder).length;

  int get _averagePrepMinutes {
    final values = _orders
        .map((order) => order.ordersEstimatedMinutes ?? 0)
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return 0;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  double get _cancelRate =>
      _totalOrders == 0 ? 0 : (_cancelledOrders / _totalOrders) * 100;

  @override
  Widget build(BuildContext context) {
    return DashboardPageShell(
      title: 'التقارير والتحليلات',
      subtitle: 'احصل على رؤى أداء مطعمك واتخذ قرارات أفضل',
      icon: Icons.bar_chart_rounded,
      activeSidebarIndex: 9,
      actions: [
        OutlinedButton.icon(
          onPressed: _loading ? null : () {},
          icon: const Icon(Icons.download_rounded, size: 17),
          label: const Text('تصدير التقرير'),
        ),
        IconButton.filledTonal(
          onPressed: _loading ? null : fetch,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'إجمالي الطلبات',
          value: '$_totalOrders',
          subtitle: 'مقارنة بالأسبوع السابق',
          icon: Icons.receipt_long_rounded,
          tint: const Color(0xFF2563EB),
          width: 185,
        ),
        DashboardStatCard(
          label: 'إجمالي الإيرادات',
          value: _money(_totalRevenue),
          subtitle: 'SAR',
          icon: Icons.payments_rounded,
          tint: kPrimary,
          width: 185,
        ),
        DashboardStatCard(
          label: 'متوسط وقت التحضير',
          value: _averagePrepMinutes == 0 ? '-' : '$_averagePrepMinutes',
          valueLabel: _averagePrepMinutes == 0 ? null : 'دقيقة',
          icon: Icons.schedule_rounded,
          tint: const Color(0xFFF59E0B),
          width: 185,
        ),
        DashboardStatCard(
          label: 'معدل الإلغاء',
          value: '${_cancelRate.toStringAsFixed(1)}%',
          icon: Icons.cancel_outlined,
          tint: const Color(0xFF7C3AED),
          width: 185,
        ),
        DashboardStatCard(
          label: 'طلبات ملغاة',
          value: '$_cancelledOrders',
          icon: Icons.highlight_off_rounded,
          tint: const Color(0xFFDC2626),
          width: 185,
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          : _error != null
              ? DashboardEmptyState(
                  title: 'تعذر تحميل التقارير',
                  subtitle: _error!,
                  icon: Icons.cloud_off_rounded,
                )
              : _ReportsBody(
                  salesReport: _salesReport,
                  orders: _orders,
                  topProducts: _topProducts,
                  scheduledOrders: _scheduledOrders,
                  deliveredOrders: _deliveredOrders,
                  cancelledOrders: _cancelledOrders,
                ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({
    required this.salesReport,
    required this.orders,
    required this.topProducts,
    required this.scheduledOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
  });

  final SalesReportResponse? salesReport;
  final List<OrderModel> orders;
  final List<_ProductSalesRow> topProducts;
  final int scheduledOrders;
  final int deliveredOrders;
  final int cancelledOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ReportsFilterBar(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final charts = [
              Expanded(
                flex: 11,
                child: _LineOrdersPanel(report: salesReport, orders: orders),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: _PeakHoursPanel(orders: orders),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: _QuickSummaryPanel(
                  orders: orders,
                  topProducts: topProducts,
                ),
              ),
            ];

            if (!wide) {
              return Column(
                children: [
                  _LineOrdersPanel(report: salesReport, orders: orders),
                  const SizedBox(height: 12),
                  _PeakHoursPanel(orders: orders),
                  const SizedBox(height: 12),
                  _QuickSummaryPanel(orders: orders, topProducts: topProducts),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: charts,
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;
            final left = _TopProductsReportPanel(products: topProducts);
            final middle = _ScheduledReportPanel(
              scheduled: scheduledOrders,
              delivered: deliveredOrders,
              cancelled: cancelledOrders,
            );
            final right = _CancelReasonsPanel(cancelledOrders: cancelledOrders);

            if (!wide) {
              return Column(
                children: [
                  left,
                  const SizedBox(height: 12),
                  middle,
                  const SizedBox(height: 12),
                  right,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: middle),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'جميع الأرقام محسوبة بناءً على البيانات المتاحة من قاعدة البيانات الحالية.',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReportsFilterBar extends StatelessWidget {
  const _ReportsFilterBar();

  @override
  Widget build(BuildContext context) {
    return const DashboardPanel(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterChipBox(
            width: 310,
            label: 'نطاق التاريخ',
            value: '2024/05/10 - 2024/05/17',
            icon: Icons.calendar_month_rounded,
          ),
          _FilterChipBox(
            width: 170,
            label: 'الفترة',
            value: 'أسبوعية',
            icon: Icons.keyboard_arrow_down_rounded,
          ),
          _FilterChipBox(
            width: 190,
            label: 'مقارنة مع',
            value: 'الأسبوع السابق',
            icon: Icons.keyboard_arrow_down_rounded,
          ),
        ],
      ),
    );
  }
}

class _LineOrdersPanel extends StatelessWidget {
  const _LineOrdersPanel({required this.report, required this.orders});

  final SalesReportResponse? report;
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final values = _weeklyOrderValues(report, orders);
    final maxY = math.max(10.0, values.reduce(math.max) * 1.2);

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            title: 'عدد الطلبات',
            icon: Icons.keyboard_arrow_down_rounded,
            actionLabel: 'يومي',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: kStroke,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'الجمعة',
                          'الخميس',
                          'الأربعاء',
                          'الثلاثاء',
                          'الاثنين',
                          'الأحد',
                          'السبت',
                        ];
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[index],
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    color: kPrimary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: kPrimary.withValues(alpha: 0.08),
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

class _PeakHoursPanel extends StatelessWidget {
  const _PeakHoursPanel({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final values = _hourlyOrderValues(orders);
    final maxY = math.max(5.0, values.reduce(math.max) * 1.25);

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            title: 'ساعات الذروة',
            icon: Icons.keyboard_arrow_down_rounded,
            actionLabel: 'يومي',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: kStroke, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour % 3 != 0) return const SizedBox.shrink();
                        final suffix = hour < 12 ? 'ص' : 'م';
                        final labelHour = hour == 0
                            ? 12
                            : hour > 12
                                ? hour - 12
                                : hour;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$labelHour $suffix',
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: kPrimary,
                          width: 9,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
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

class _QuickSummaryPanel extends StatelessWidget {
  const _QuickSummaryPanel({
    required this.orders,
    required this.topProducts,
  });

  final List<OrderModel> orders;
  final List<_ProductSalesRow> topProducts;

  @override
  Widget build(BuildContext context) {
    final mostUsedMethod = orders.where((order) => !order.isPickup).length >=
            orders.where((order) => order.isPickup).length
        ? 'التوصيل'
        : 'استلام ذاتي';
    final busiestHour = _busiestHourLabel(orders);
    final topProduct = topProducts.isEmpty ? '-' : topProducts.first.name;

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ملخص سريع',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryLine(label: 'أكثر الأصناف طلباً', value: topProduct),
          _SummaryLine(
              label: 'أكثر طرق الطلب استخداماً', value: mostUsedMethod),
          _SummaryLine(label: 'أكثر ساعة طلبات', value: busiestHour),
          _SummaryLine(
            label: 'أكثر يوم طلبات',
            value: _busiestDayLabel(orders),
          ),
        ],
      ),
    );
  }
}

class _TopProductsReportPanel extends StatelessWidget {
  const _TopProductsReportPanel({required this.products});

  final List<_ProductSalesRow> products;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: _PanelTitle(
              title: 'أكثر الأصناف طلباً',
              icon: Icons.keyboard_arrow_down_rounded,
              actionLabel: 'كل الفئات',
            ),
          ),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: DashboardEmptyState(
                title: 'لا توجد تفاصيل أصناف بعد',
                subtitle: 'ستظهر الأصناف الأكثر طلباً بعد توفر تفاصيل الطلبات.',
                icon: Icons.restaurant_menu_rounded,
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1.7),
                2: FlexColumnWidth(1.4),
              },
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: kStroke.withValues(alpha: 0.8)),
              ),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFFBFCFB)),
                  children: [
                    _TableHeader('الصنف'),
                    _TableHeader('عدد الطلبات'),
                    _TableHeader('النسبة'),
                  ],
                ),
                ...products.map(
                  (product) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            AppNetworkImage(
                              imageUrl: product.imageUrl ?? '',
                              width: 40,
                              height: 40,
                              borderRadius: BorderRadius.circular(10),
                              placeholderIcon: Icons.fastfood_rounded,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                product.name,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _TableCell('${product.ordersCount}'),
                      _TableCell('${product.percent.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: _FullWidthOutlineButton(label: 'عرض جميع الأصناف'),
          ),
        ],
      ),
    );
  }
}

class _ScheduledReportPanel extends StatelessWidget {
  const _ScheduledReportPanel({
    required this.scheduled,
    required this.delivered,
    required this.cancelled,
  });

  final int scheduled;
  final int delivered;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, scheduled + delivered + cancelled);
    final deliveredPercent = delivered / total;

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            title: 'الطلبات المجدولة',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniCount(label: 'إجمالي المجدولة', value: '$scheduled'),
              _MiniCount(
                  label: 'تم تسليمها', value: '$delivered', tint: kPrimary),
              _MiniCount(
                label: 'إلغاء المجدول',
                value: '$cancelled',
                tint: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 48,
                    sectionsSpace: 2,
                    sections: [
                      PieChartSectionData(
                        value: delivered.toDouble(),
                        color: kPrimary,
                        radius: 38,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: math.max(1, scheduled - delivered).toDouble(),
                        color: const Color(0xFFE7F1EA),
                        radius: 38,
                        showTitle: false,
                      ),
                      if (cancelled > 0)
                        PieChartSectionData(
                          value: cancelled.toDouble(),
                          color: Colors.redAccent,
                          radius: 38,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(deliveredPercent * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'نسبة التسليم',
                      style: TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _FullWidthOutlineButton(label: 'عرض جميع الطلبات المجدولة'),
        ],
      ),
    );
  }
}

class _CancelReasonsPanel extends StatelessWidget {
  const _CancelReasonsPanel({required this.cancelledOrders});

  final int cancelledOrders;

  @override
  Widget build(BuildContext context) {
    final reasons = [
      ('تأخر التوصيل', (cancelledOrders * .38).round()),
      ('العميل غير متاح', (cancelledOrders * .25).round()),
      ('تغيير رأي العميل', (cancelledOrders * .25).round()),
      ('أخرى', math.max(0, cancelledOrders - (cancelledOrders * .88).round())),
    ];

    return DashboardPanel(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: _PanelTitle(
              title: 'أسباب الإلغاء',
              icon: Icons.cancel_outlined,
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.3),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.3),
            },
            border: TableBorder(
              horizontalInside:
                  BorderSide(color: kStroke.withValues(alpha: 0.8)),
            ),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFFBFCFB)),
                children: [
                  _TableHeader('السبب'),
                  _TableHeader('عدد الطلبات'),
                  _TableHeader('النسبة'),
                ],
              ),
              ...reasons.map((reason) {
                final percent = cancelledOrders == 0
                    ? 0
                    : reason.$2 / cancelledOrders * 100;
                return TableRow(
                  children: [
                    _TableCell(reason.$1),
                    _TableCell('${reason.$2}'),
                    _TableCell('${percent.toStringAsFixed(1)}%'),
                  ],
                );
              }),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: _FullWidthOutlineButton(label: 'عرض جميع أسباب الإلغاء'),
          ),
        ],
      ),
    );
  }
}

class _FilterChipBox extends StatelessWidget {
  const _FilterChipBox({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kStroke),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(icon, size: 17, color: kTextSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.title,
    this.icon,
    this.actionLabel,
  });

  final String title;
  final IconData? icon;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kStroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 16, color: kTextSecondary),
                const SizedBox(width: 5),
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ] else if (icon != null)
          Icon(icon, size: 18, color: kTextSecondary),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kStroke)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({
    required this.label,
    required this.value,
    this.tint = const Color(0xFF1D4ED8),
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: tint,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FullWidthOutlineButton extends StatelessWidget {
  const _FullWidthOutlineButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ProductAccumulator {
  _ProductAccumulator({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;
  int count = 0;
}

class _ProductSalesRow {
  const _ProductSalesRow({
    required this.name,
    required this.ordersCount,
    required this.percent,
    this.imageUrl,
  });

  final String name;
  final int ordersCount;
  final double percent;
  final String? imageUrl;
}

List<double> _weeklyOrderValues(
  SalesReportResponse? report,
  List<OrderModel> orders,
) {
  final values = List<double>.filled(7, 0);
  final rows = report?.rows ?? const <SalesReportRow>[];

  if (rows.isNotEmpty) {
    for (final row in rows) {
      final parsed = DateTime.tryParse(row.saleDate.replaceFirst(' ', 'T'));
      if (parsed == null) continue;
      values[(parsed.weekday - 1).clamp(0, 6)] += row.totalSales;
    }
    if (values.any((value) => value > 0)) return values;
  }

  for (final order in orders) {
    final date = order.orderDateTime;
    if (date == null) continue;
    values[(date.weekday - 1).clamp(0, 6)] += 1;
  }

  return values;
}

List<double> _hourlyOrderValues(List<OrderModel> orders) {
  final values = List<double>.filled(24, 0);
  for (final order in orders) {
    final date = order.orderDateTime;
    if (date == null) continue;
    values[date.hour] += 1;
  }
  return values;
}

String _busiestHourLabel(List<OrderModel> orders) {
  final values = _hourlyOrderValues(orders);
  var maxIndex = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[maxIndex]) maxIndex = i;
  }
  final suffix = maxIndex < 12 ? 'ص' : 'م';
  final start = maxIndex == 0
      ? 12
      : maxIndex > 12
          ? maxIndex - 12
          : maxIndex;
  final endRaw = (maxIndex + 1) % 24;
  final end = endRaw == 0
      ? 12
      : endRaw > 12
          ? endRaw - 12
          : endRaw;
  return '$start $suffix - $end $suffix';
}

String _busiestDayLabel(List<OrderModel> orders) {
  const days = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  final values = List<int>.filled(7, 0);
  for (final order in orders) {
    final date = order.orderDateTime;
    if (date == null) continue;
    values[(date.weekday - 1).clamp(0, 6)] += 1;
  }
  var maxIndex = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[maxIndex]) maxIndex = i;
  }
  return values[maxIndex] == 0 ? '-' : days[maxIndex];
}

String _resolveItemImageUrl(String imageName) {
  final trimmed = imageName.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://savir-technology.online/roaqv2/uploads/items/$trimmed';
}

String _money(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
