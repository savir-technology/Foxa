import 'package:admin_tks/model/store_operations_model.dart';
import 'package:admin_tks/remote/store_operations_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class StoreOperationsPage extends StatefulWidget {
  const StoreOperationsPage({super.key});

  @override
  State<StoreOperationsPage> createState() => _StoreOperationsPageState();
}

class _StoreOperationsPageState extends State<StoreOperationsPage> {
  static const List<_VendorToolkitItem> _toolkitItems = [
    _VendorToolkitItem(
      title: 'تنبيهات المخزون',
      description:
          'مراقبة المنتجات القريبة من الحد الأدنى مع اقتراح إعادة الطلب.',
      icon: Icons.warning_amber_rounded,
      tint: Color(0xFFF59E0B),
    ),
    _VendorToolkitItem(
      title: 'استيراد وتصدير',
      description: 'إدارة ملفات Excel وCSV لتحديث الكتالوج بكميات كبيرة.',
      icon: Icons.file_upload_rounded,
      tint: Color(0xFF3B82F6),
    ),
    _VendorToolkitItem(
      title: 'العروض والكوبونات',
      description: 'تشغيل حملات خصم سريعة مع قياس مباشر للأثر على الطلبات.',
      icon: Icons.local_offer_rounded,
      tint: Color(0xFFEC4899),
    ),
    _VendorToolkitItem(
      title: 'الفواتير والتجهيز',
      description: 'طباعة فاتورة وPacking Slip لكل طلب جاهز للشحن.',
      icon: Icons.print_rounded,
      tint: Color(0xFF14B8A6),
    ),
    _VendorToolkitItem(
      title: 'المرتجعات والاستبدال',
      description: 'قائمة متابعة لحالات الإرجاع والاستبدال مع سبب الحالة.',
      icon: Icons.keyboard_return_rounded,
      tint: Color(0xFF8B5CF6),
    ),
    _VendorToolkitItem(
      title: 'تقارير مجدولة',
      description: 'إرسال ملخص يومي أو أسبوعي تلقائيًا لفريق المتجر.',
      icon: Icons.schedule_send_rounded,
      tint: Color(0xFF10B981),
    ),
  ];

  final StoreOperationsData _api = StoreOperationsData();

  StoreOperationsOverview? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final overview = await _api.getOverview();
    if (!mounted) return;

    setState(() {
      _overview = overview;
      _loading = false;
      _error =
          overview == null ? 'تعذر تحميل بيانات تشغيل المتجر من الخادم.' : null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showExportSnapshot() async {
    final snapshotPayload = await _api.exportSnapshot();
    if (!mounted) return;

    if (snapshotPayload == null) {
      _showMessage('تعذر إنشاء ملخص التصدير من الخادم.');
      return;
    }

    final snapshot =
        (snapshotPayload['snapshot'] as Map?)?.cast<String, dynamic>() ?? {};

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملخص التصدير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المتجر: ${snapshot['store_name'] ?? '-'}'),
            Text('وقت الإنشاء: ${snapshot['generated_at'] ?? '-'}'),
            Text('الطلبات المدفوعة: ${snapshot['paid_orders'] ?? 0}'),
            Text('تنبيهات المخزون: ${snapshot['low_stock_items'] ?? 0}'),
            Text('المرتجعات المفتوحة: ${snapshot['open_returns'] ?? 0}'),
            Text('التقارير النشطة: ${snapshot['active_reports'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeLowStock(LowStockRow row) async {
    final message = await _api.acknowledgeLowStock(row.itemId);
    if (!mounted) return;

    _showMessage(message ?? 'تعذر تسجيل متابعة المورد لهذا المنتج.');
    if (message != null) {
      await _fetch();
    }
  }

  Future<void> _updateReturnStatus(
    ReturnRequest request,
    String statusLabel,
  ) async {
    final message =
        await _api.updateReturnStatus(request.returnId, statusLabel);
    if (!mounted) return;

    _showMessage(message ?? 'تعذر تحديث حالة المرتجع.');
    if (message != null) {
      await _fetch();
    }
  }

  Future<void> _toggleReport(ScheduledReport report, bool isActive) async {
    final message = await _api.toggleReport(report.reportId, isActive);
    if (!mounted) return;

    _showMessage(message ?? 'تعذر تحديث حالة التقرير المجدول.');
    if (message != null) {
      await _fetch();
    }
  }

  Future<void> _updateDriverRequest(DriverRequest request, bool approve) async {
    final message = await _api.updateDriverRequest(request.id, approve);
    if (!mounted) return;
    _showMessage(message ?? 'تعذر تحديث طلب السائق.');
    if (message != null) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;

    return DashboardPageShell(
      title: 'مركز تشغيل المطعم',
      subtitle:
          'وحدة تشغيل متقدمة للمطعم تشمل المخزون، الاستيراد، العروض، الفريق، العملاء، والتقارير المجدولة.',
      icon: Icons.storefront_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: () {
            _fetch();
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: () {
            _showExportSnapshot();
          },
          /*
            'تم تجهيز مركز التصدير. يمكن ربطه بملفات CSV/Excel من الـ API أو التخزين المحلي.',
          ),
          */
          icon: const Icon(Icons.download_rounded),
          label: const Text('تصدير'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'تنبيهات المخزون',
          value: '${overview?.summary.lowStockCount ?? 0} منتجات',
          icon: Icons.warning_amber_rounded,
          tint: const Color(0xFFF59E0B),
        ),
        DashboardStatCard(
          label: 'مرتجعات مفتوحة',
          value: '${overview?.summary.openReturnsCount ?? 0} طلبات',
          icon: Icons.keyboard_return_rounded,
          tint: const Color(0xFF8B5CF6),
        ),
        DashboardStatCard(
          label: 'عملاء متكررون',
          value: '${overview?.summary.repeatCustomersCount ?? 0} عميل',
          icon: Icons.people_alt_rounded,
          tint: const Color(0xFF3B82F6),
        ),
        DashboardStatCard(
          label: 'تقارير تلقائية',
          value: '${overview?.summary.scheduledReportsCount ?? 0} مجدولة',
          icon: Icons.schedule_send_rounded,
          tint: const Color(0xFF10B981),
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(color: kPrimary),
              ),
            )
          : _error != null
              ? DashboardEmptyState(
                  title: 'تعذر تحميل البيانات',
                  subtitle: _error!,
                  icon: Icons.cloud_off_rounded,
                )
              : _OperationsContent(
                  overview: overview!,
                  toolkitItems: _toolkitItems,
                  onAcknowledgeLowStock: _acknowledgeLowStock,
                  onUpdateReturnStatus: _updateReturnStatus,
                  onToggleReport: _toggleReport,
                  onUpdateDriverRequest: _updateDriverRequest,
                ),
    );
  }
}

class _OperationsContent extends StatelessWidget {
  const _OperationsContent({
    required this.overview,
    required this.toolkitItems,
    required this.onAcknowledgeLowStock,
    required this.onUpdateReturnStatus,
    required this.onToggleReport,
    required this.onUpdateDriverRequest,
  });

  final StoreOperationsOverview overview;
  final List<_VendorToolkitItem> toolkitItems;
  final Future<void> Function(LowStockRow row) onAcknowledgeLowStock;
  final Future<void> Function(ReturnRequest item, String statusLabel)
      onUpdateReturnStatus;
  final Future<void> Function(ScheduledReport item, bool isActive)
      onToggleReport;
  final Future<void> Function(DriverRequest item, bool approve)
      onUpdateDriverRequest;

  @override
  Widget build(BuildContext context) {
    final highlightItems = _buildStoreToolkitItems(overview);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'ملخص مباشر من البيانات',
          subtitle:
              'هذه البطاقات تعرض مؤشرات حية من قاعدة البيانات الحالية، وليست وصفًا ثابتًا للخصائص.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: (highlightItems.isEmpty ? toolkitItems : highlightItems)
              .map((item) => _ToolkitCard(item: item))
              .toList(),
        ),
        const SizedBox(height: 18),
        DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(
                title: 'مراقبة الحد الأدنى للمخزون',
                subtitle:
                    'جدول سريع للمنتجات القريبة من النفاد مع إجراء مقترح لكل منتج.',
                action: TextButton.icon(
                  onPressed: null,
                  /*
                    'يمكن هنا لاحقًا إنشاء أمر شراء أو إرسال تنبيه آلي للمورد.',
                  ),
                  */
                  icon: const Icon(Icons.add_alert_rounded),
                  label: const Text('تنبيه المورد'),
                ),
              ),
              const SizedBox(height: 12),
              if (overview.lowStockRows.isEmpty)
                const Text(
                  'لا توجد منتجات تحت الحد الأدنى حاليًا.',
                  style: TextStyle(color: kTextSecondary),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('المنتج')),
                      DataColumn(label: Text('الحالي')),
                      DataColumn(label: Text('الحد الأدنى')),
                      DataColumn(label: Text('موعد التوريد')),
                      DataColumn(label: Text('الإجراء')),
                    ],
                    rows: overview.lowStockRows
                        .map(
                          (row) => DataRow(
                            cells: [
                              DataCell(Text(row.product)),
                              DataCell(Text('${row.currentStock}')),
                              DataCell(Text('${row.minimumStock}')),
                              DataCell(Text(row.supplierEta)),
                              DataCell(
                                OutlinedButton(
                                  onPressed: () {
                                    onAcknowledgeLowStock(row);
                                  },
                                  /*
                                    'تم تجهيز إجراء "${row.actionLabel}" لهذا المنتج.',
                                  ),
                                  */
                                  child: Text(row.actionLabel),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ResponsivePair(
          left: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  title: 'تحليل المبيعات',
                  subtitle: 'قراءة سريعة حسب المنتج والقسم والفترة والمدينة.',
                ),
                const SizedBox(height: 12),
                if (overview.salesBreakdowns.isEmpty)
                  const Text(
                    'لا توجد مبيعات مدفوعة كافية لإظهار تحليل مفصل حتى الآن.',
                    style: TextStyle(color: kTextSecondary),
                  )
                else
                  ...overview.salesBreakdowns.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProgressInsight(item: item),
                    ),
                  ),
              ],
            ),
          ),
          right: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  title: 'طلبات ربط السائقين',
                  subtitle: 'راجع السائقين الذين طلبوا الانضمام لهذا المتجر.',
                ),
                const SizedBox(height: 12),
                if (overview.driverRequests.isEmpty)
                  const Text('لا توجد طلبات ربط جديدة.',
                      style: TextStyle(color: kTextSecondary))
                else
                  ...overview.driverRequests.map(
                    (request) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.delivery_dining_outlined)),
                        title: Text(request.name),
                        subtitle: Text(
                            '${request.phone} • ${request.vehicle}\\nالحالة: ${request.status}'),
                        isThreeLine: true,
                        trailing: request.status == 'vendor_pending'
                            ? Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'موافقة مبدئية',
                                    onPressed: () =>
                                        onUpdateDriverRequest(request, true),
                                    icon: const Icon(Icons.check_circle_outline,
                                        color: Colors.green),
                                  ),
                                  IconButton(
                                    tooltip: 'رفض',
                                    onPressed: () =>
                                        onUpdateDriverRequest(request, false),
                                    icon: const Icon(Icons.cancel_outlined,
                                        color: Colors.red),
                                  ),
                                ],
                              )
                            : Text(request.status),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const _PanelHeader(
                  title: 'تحليل مصادر الطلبات',
                  subtitle:
                      'قراءة سريعة لتوزيع الطلبات المباشرة والمخفضة والمجدولة داخل المتجر.',
                ),
                const SizedBox(height: 12),
                if (overview.orderSources.isEmpty)
                  const Text(
                    'لا توجد بيانات كافية بعد لعرض مصادر الطلبات بشكل مفصل.',
                    style: TextStyle(color: kTextSecondary),
                  )
                else
                  ...overview.orderSources.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AttributionRow(item: item),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ResponsivePair(
          left: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelHeader(
                  title: 'المرتجعات والاستبدال',
                  subtitle:
                      'طابور متابعة للحالات المفتوحة مع سبب الإرجاع أو الاستبدال.',
                  action: TextButton.icon(
                    onPressed: null,
                    /*
                      'هذه الوحدة أصبحت مربوطة ببيانات backend ويمكن تطوير تحديث الحالة في الخطوة التالية.',
                    ),
                    */
                    icon: const Icon(Icons.sync_alt_rounded),
                    label: const Text('تحديث الحالات'),
                  ),
                ),
                const SizedBox(height: 12),
                if (overview.returnRequests.isEmpty)
                  const Text(
                    'لا توجد طلبات مرتجعات أو استبدال مسجلة لهذا المتجر حاليًا.',
                    style: TextStyle(color: kTextSecondary),
                  )
                else
                  ...overview.returnRequests.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReturnCard(
                        item: item,
                        onUpdateStatus: onUpdateReturnStatus,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          right: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  title: 'الفريق والصلاحيات',
                  subtitle:
                      'إدارة صلاحيات موظفي المتجر حسب الدور من قاعدة البيانات.',
                ),
                const SizedBox(height: 12),
                if (overview.teamMembers.isEmpty)
                  const Text(
                    'لا يوجد أعضاء فريق إضافيون مسجلون لهذا المتجر حتى الآن.',
                    style: TextStyle(color: kTextSecondary),
                  )
                else
                  ...overview.teamMembers.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TeamCard(item: item),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ResponsivePair(
          left: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  title: 'CRM مبسط للعملاء',
                  subtitle:
                      'عرض العملاء الأكثر شراءً والمتكررين والمعرضين للتسرب.',
                ),
                const SizedBox(height: 12),
                if (overview.customerInsights.isEmpty)
                  const Text(
                    'لا توجد بيانات عملاء مدفوعة كافية لبناء شرائح CRM حاليًا.',
                    style: TextStyle(color: kTextSecondary),
                  )
                else
                  ...overview.customerInsights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CustomerCard(item: item),
                    ),
                  ),
              ],
            ),
          ),
          right: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelHeader(
                  title: 'التقارير التلقائية',
                  subtitle:
                      'جدولة تقارير يومية أو أسبوعية تصل مباشرة إلى فريق المتجر.',
                  action: FilledButton.tonalIcon(
                    onPressed: null,
                    /*
                      'يمكن ربط هذه الوحدة بإرسال Email أو WhatsApp أو إشعار داخلي.',
                    ),
                    */
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('تحديث المصادر'),
                  ),
                ),
                const SizedBox(height: 12),
                if (overview.scheduledReports.isEmpty)
                  const Text(
                    'لا توجد تقارير مجدولة محفوظة لهذا المتجر حتى الآن.',
                    style: TextStyle(color: kTextSecondary),
                  )
                else
                  ...overview.scheduledReports.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReportCard(
                        item: item,
                        onToggleActive: onToggleReport,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1080;
        if (stacked) {
          return Column(
            children: [
              left,
              const SizedBox(height: 18),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

List<_VendorToolkitItem> _buildStoreToolkitItems(
  StoreOperationsOverview overview,
) {
  final lowStockCount = overview.lowStockRows.length;
  final salesWidgetsCount = overview.salesBreakdowns.length;
  final sourceCount = overview.orderSources.length;
  final returnCount = overview.returnRequests.length;
  final teamCount = overview.teamMembers.length;
  final customerCount = overview.customerInsights.length;
  final reportCount =
      overview.scheduledReports.where((item) => item.isActive).length;

  return [
    _VendorToolkitItem(
      title: 'تنبيهات المخزون',
      description:
          '$lowStockCount منتجًا تحت الحد الأدنى وفق البيانات الحالية.',
      icon: Icons.warning_amber_rounded,
      tint: const Color(0xFFF59E0B),
    ),
    _VendorToolkitItem(
      title: 'تحليل المبيعات',
      description:
          '$salesWidgetsCount مؤشرات تحليلية مشتقة من الطلبات المدفوعة.',
      icon: Icons.insights_rounded,
      tint: const Color(0xFF3B82F6),
    ),
    _VendorToolkitItem(
      title: 'مصادر الطلبات',
      description:
          '$sourceCount مصدر قراءة للطلبات المباشرة والمخفضة والمجدولة.',
      icon: Icons.route_rounded,
      tint: const Color(0xFFEC4899),
    ),
    _VendorToolkitItem(
      title: 'المرتجعات',
      description: '$returnCount حالة مرتجعات أو استبدال مسجلة لهذا المتجر.',
      icon: Icons.keyboard_return_rounded,
      tint: const Color(0xFF8B5CF6),
    ),
    _VendorToolkitItem(
      title: 'الفريق',
      description: '$teamCount حسابًا ظاهرًا داخل وحدة الفريق والصلاحيات.',
      icon: Icons.people_alt_rounded,
      tint: const Color(0xFF14B8A6),
    ),
    _VendorToolkitItem(
      title: 'تقارير العملاء',
      description: '$customerCount شريحة عميل مبنية من سجل الشراء الفعلي.',
      icon: Icons.groups_rounded,
      tint: const Color(0xFF0F766E),
    ),
    _VendorToolkitItem(
      title: 'التقارير المجدولة',
      description: '$reportCount تقريرًا نشطًا جاهزًا للإرسال أو المتابعة.',
      icon: Icons.schedule_send_rounded,
      tint: const Color(0xFF10B981),
    ),
  ];
}

class _VendorToolkitItem {
  const _VendorToolkitItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color tint;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}

class _ToolkitCard extends StatelessWidget {
  const _ToolkitCard({required this.item});

  final _VendorToolkitItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.tint),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressInsight extends StatelessWidget {
  const _ProgressInsight({required this.item});

  final SalesBreakdown item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                item.value,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: item.tint.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(item.tint),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributionRow extends StatelessWidget {
  const _AttributionRow({required this.item});

  final CampaignAttribution item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.source,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.orders} orders  •  ${item.conversion} conversion',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.revenue,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({
    required this.item,
    required this.onUpdateStatus,
  });

  final ReturnRequest item;
  final Future<void> Function(ReturnRequest item, String statusLabel)
      onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.assignment_return_rounded, color: item.tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.orderId} • ${item.customer}',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reason,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(label: item.status, tint: item.tint),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  onUpdateStatus(item, value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'Awaiting pickup',
                    child: Text('Awaiting pickup'),
                  ),
                  PopupMenuItem(
                    value: 'Approved',
                    child: Text('Approved'),
                  ),
                  PopupMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                  PopupMenuItem(
                    value: 'Rejected',
                    child: Text('Rejected'),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.more_horiz_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.item});

  final TeamMember item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: item.tint.withValues(alpha: 0.14),
                foregroundColor: item.tint,
                child:
                    Text(item.name.isEmpty ? '?' : item.name.substring(0, 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.role,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.permissions
                .map((permission) =>
                    _TagChip(label: permission, tint: item.tint))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.item});

  final CustomerInsight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: item.label, tint: item.tint),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.spend,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.item,
    required this.onToggleActive,
  });

  final ScheduledReport item;
  final Future<void> Function(ScheduledReport item, bool isActive)
      onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.isActive
                  ? Icons.summarize_rounded
                  : Icons.pause_circle_rounded,
              color: kAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.cadence,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.target,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: item.isActive,
            onChanged: (value) {
              onToggleActive(item, value);
            },
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
