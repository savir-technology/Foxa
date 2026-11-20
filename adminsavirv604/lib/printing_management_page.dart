import 'package:admin_tks/core/services/dashboard_print_service.dart';
import 'package:admin_tks/model/printing_model.dart';
import 'package:admin_tks/remote/printing_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class PrintingManagementPage extends StatefulWidget {
  const PrintingManagementPage({super.key});

  @override
  State<PrintingManagementPage> createState() => _PrintingManagementPageState();
}

class _PrintingManagementPageState extends State<PrintingManagementPage> {
  final PrintingData _printingData = PrintingData();

  PrintingDashboardSnapshot? _snapshot;
  PrintSettings _settings = const PrintSettings(
    direction: 'rtl_ar',
    fontSize: 'medium',
    invoiceCopies: 1,
    printLogo: true,
  );
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrinting();
  }

  Future<void> _loadPrinting() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snapshot = await _printingData.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _settings = snapshot.settings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(error);
        _loading = false;
      });
    }
  }

  Future<void> _savePrinter(VendorPrinter printer) async {
    await _runMutation(
      () => _printingData.savePrinter(printer),
      successMessage: 'تم حفظ الطابعة',
    );
  }

  Future<void> _deletePrinter(VendorPrinter printer) async {
    final confirmed = await _confirm(
      title: 'حذف الطابعة',
      message: 'هل تريد حذف ${printer.name} من إعدادات الطباعة؟',
    );
    if (!confirmed) return;

    await _runMutation(
      () => _printingData.deletePrinter(printer.id),
      successMessage: 'تم حذف الطابعة',
    );
  }

  Future<void> _saveTemplate(InvoiceTemplate template) async {
    await _runMutation(
      () => _printingData.saveTemplate(template),
      successMessage: 'تم حفظ القالب',
    );
  }

  Future<void> _deleteTemplate(InvoiceTemplate template) async {
    final confirmed = await _confirm(
      title: 'حذف القالب',
      message: 'هل تريد حذف ${template.name} من قوالب الفواتير؟',
    );
    if (!confirmed) return;

    await _runMutation(
      () => _printingData.deleteTemplate(template.id),
      successMessage: 'تم حذف القالب',
    );
  }

  Future<void> _saveSettings() async {
    await _runMutation(
      () => _printingData.saveSettings(_settings),
      successMessage: 'تم حفظ إعدادات الطباعة',
    );
  }

  Future<void> _testPrinter(VendorPrinter printer) async {
    await _runMutation(
      () => _printingData.recordPrintJob(
        printerId: printer.id,
        jobType: 'test',
        payload: {
          'source': 'restaurant_dashboard',
          'printer_name': printer.name,
        },
      ),
      successMessage: 'تم تسجيل اختبار الطباعة',
      afterSuccess: triggerDashboardPrint,
    );
  }

  Future<void> _runMutation(
    Future<PrintingDashboardSnapshot> Function() action, {
    required String successMessage,
    VoidCallback? afterSuccess,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final snapshot = await action();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _settings = snapshot.settings;
        _saving = false;
      });
      afterSuccess?.call();
      _showSnack(successMessage);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack(_cleanError(error), error: true);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: error ? Colors.redAccent : kPrimary,
      ),
    );
  }

  Future<void> _openPrinterDialog([VendorPrinter? printer]) async {
    final result = await showDialog<VendorPrinter>(
      context: context,
      builder: (context) => _PrinterDialog(printer: printer),
    );
    if (result != null) {
      await _savePrinter(result);
    }
  }

  Future<void> _openTemplateDialog([InvoiceTemplate? template]) async {
    final result = await showDialog<InvoiceTemplate>(
      context: context,
      builder: (context) => _TemplateDialog(template: template),
    );
    if (result != null) {
      await _saveTemplate(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _snapshot?.summary ??
        const PrintSummary(
          printedToday: 0,
          templateTypes: 0,
          disconnectedPrinters: 0,
          connectedPrinters: 0,
          totalPrinters: 0,
        );

    return DashboardPageShell(
      title: 'الطباعة',
      subtitle: 'إدارة طابعات المطعم والفواتير',
      icon: Icons.print_rounded,
      activeSidebarIndex: 10,
      actions: [
        FilledButton.icon(
          onPressed: _saving ? null : () => _openPrinterDialog(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة طابعة جديدة'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'فواتير مطبوعة اليوم',
          value: summary.printedToday.toString(),
          icon: Icons.layers_rounded,
          tint: const Color(0xFF2563EB),
          width: 190,
        ),
        DashboardStatCard(
          label: 'أنواع الفواتير',
          value: summary.templateTypes.toString(),
          icon: Icons.description_rounded,
          tint: const Color(0xFF7C3AED),
          width: 180,
        ),
        DashboardStatCard(
          label: 'غير متصلة',
          value: summary.disconnectedPrinters.toString(),
          icon: Icons.warning_amber_rounded,
          tint: const Color(0xFFF59E0B),
          width: 180,
        ),
        DashboardStatCard(
          label: 'متصلة',
          value: summary.connectedPrinters.toString(),
          icon: Icons.check_circle_outline_rounded,
          tint: kPrimary,
          width: 180,
        ),
        DashboardStatCard(
          label: 'إجمالي الطابعات',
          value: summary.totalPrinters.toString(),
          icon: Icons.print_rounded,
          tint: const Color(0xFF1D4ED8),
          width: 180,
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const DashboardPanel(
        child: SizedBox(
          height: 260,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return DashboardPanel(
        child: SizedBox(
          height: 260,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Colors.redAccent, size: 34),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _loadPrinting,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrintersTable(
          printers: snapshot.printers,
          saving: _saving,
          onTest: _testPrinter,
          onEdit: _openPrinterDialog,
          onDelete: _deletePrinter,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;
            final templates = _InvoiceTemplatesTable(
              templates: snapshot.templates,
              saving: _saving,
              onAddTemplate: () => _openTemplateDialog(),
              onEdit: _openTemplateDialog,
              onDelete: _deleteTemplate,
            );
            final settings = _GeneralPrintSettings(
              settings: _settings,
              saving: _saving,
              onChanged: (settings) => setState(() => _settings = settings),
              onSave: _saveSettings,
            );

            if (!wide) {
              return Column(
                children: [
                  templates,
                  const SizedBox(height: 12),
                  settings,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: templates),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: settings),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PrintersTable extends StatelessWidget {
  const _PrintersTable({
    required this.printers,
    required this.saving,
    required this.onTest,
    required this.onEdit,
    required this.onDelete,
  });

  final List<VendorPrinter> printers;
  final bool saving;
  final ValueChanged<VendorPrinter> onTest;
  final ValueChanged<VendorPrinter> onEdit;
  final ValueChanged<VendorPrinter> onDelete;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              'الطابعات',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (printers.isEmpty)
            const _EmptyPrintState(
              icon: Icons.print_disabled_rounded,
              title: 'لا توجد طابعات مضافة',
              message: 'أضف طابعة حتى تظهر هنا ويتم حفظها في قاعدة البيانات.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 980
                          ? 980
                          : constraints.maxWidth,
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.4),
                        1: FlexColumnWidth(1.1),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(1.35),
                        4: FlexColumnWidth(1.1),
                        5: FlexColumnWidth(1.2),
                        6: FlexColumnWidth(1.6),
                      },
                      border: TableBorder(
                        horizontalInside:
                            BorderSide(color: kStroke.withValues(alpha: .8)),
                        verticalInside:
                            BorderSide(color: kStroke.withValues(alpha: .55)),
                      ),
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFFBFCFB)),
                          children: [
                            _PrintHeader('الطابعة'),
                            _PrintHeader('النوع'),
                            _PrintHeader('الأقسام المرتبطة'),
                            _PrintHeader('الموقع'),
                            _PrintHeader('الحالة'),
                            _PrintHeader('آخر طباعة'),
                            _PrintHeader('الإجراءات'),
                          ],
                        ),
                        ...printers.map(
                          (printer) => _PrinterTableRow(
                            printer: printer,
                            saving: saving,
                            onTest: onTest,
                            onEdit: onEdit,
                            onDelete: onDelete,
                          ).toTableRow(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InvoiceTemplatesTable extends StatelessWidget {
  const _InvoiceTemplatesTable({
    required this.templates,
    required this.saving,
    required this.onAddTemplate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InvoiceTemplate> templates;
  final bool saving;
  final VoidCallback onAddTemplate;
  final ValueChanged<InvoiceTemplate> onEdit;
  final ValueChanged<InvoiceTemplate> onDelete;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Expanded(
                  child: Text(
                    'قوالب الفواتير',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : onAddTemplate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة قالب جديد'),
                ),
              ],
            ),
          ),
          if (templates.isEmpty)
            const _EmptyPrintState(
              icon: Icons.description_outlined,
              title: 'لا توجد قوالب فواتير',
              message: 'أضف قالبًا ليتم استخدامه في الطباعة وحفظه للمطعم.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 720
                          ? 720
                          : constraints.maxWidth,
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.3),
                        4: FlexColumnWidth(1.7),
                        5: FlexColumnWidth(1.4),
                      },
                      border: TableBorder(
                        horizontalInside:
                            BorderSide(color: kStroke.withValues(alpha: .8)),
                        verticalInside:
                            BorderSide(color: kStroke.withValues(alpha: .55)),
                      ),
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFFBFCFB)),
                          children: [
                            _PrintHeader('القالب'),
                            _PrintHeader('النوع'),
                            _PrintHeader('العرض (مم)'),
                            _PrintHeader('الارتفاع (مم)'),
                            _PrintHeader('الاستخدام'),
                            _PrintHeader('إجراءات'),
                          ],
                        ),
                        ...templates.map(
                          (template) => _TemplateTableRow(
                            template: template,
                            saving: saving,
                            onEdit: onEdit,
                            onDelete: onDelete,
                          ).toTableRow(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GeneralPrintSettings extends StatelessWidget {
  const _GeneralPrintSettings({
    required this.settings,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  final PrintSettings settings;
  final bool saving;
  final ValueChanged<PrintSettings> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.settings_rounded, color: kTextSecondary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إعدادات الطباعة العامة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsDropDown(
            label: 'التنسيق الافتراضي',
            value: settings.direction,
            items: const {
              'rtl_ar': 'عربي (يمين لليسار)',
              'ltr_en': 'English (LTR)',
            },
            onChanged: (value) {
              if (value != null) {
                onChanged(settings.copyWith(direction: value));
              }
            },
          ),
          const SizedBox(height: 12),
          _SettingsDropDown(
            label: 'حجم الخط الافتراضي',
            value: settings.fontSize,
            items: const {
              'small': 'صغير',
              'medium': 'متوسط',
              'large': 'كبير',
            },
            onChanged: (value) {
              if (value != null) {
                onChanged(settings.copyWith(fontSize: value));
              }
            },
          ),
          const SizedBox(height: 12),
          _SettingsDropDown(
            label: 'عدد نسخ الفاتورة',
            value: settings.invoiceCopies.toString(),
            items: const {
              '1': '1',
              '2': '2',
              '3': '3',
              '4': '4',
              '5': '5',
            },
            onChanged: (value) {
              final copies = int.tryParse(value ?? '');
              if (copies != null) {
                onChanged(settings.copyWith(invoiceCopies: copies));
              }
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: settings.printLogo,
            onChanged: saving
                ? null
                : (value) => onChanged(settings.copyWith(printLogo: value)),
            title: const Text(
              'طباعة الشعار في الفواتير',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('حفظ إعدادات الطباعة'),
          ),
        ],
      ),
    );
  }
}

class _PrinterTableRow {
  const _PrinterTableRow({
    required this.printer,
    required this.saving,
    required this.onTest,
    required this.onEdit,
    required this.onDelete,
  });

  final VendorPrinter printer;
  final bool saving;
  final ValueChanged<VendorPrinter> onTest;
  final ValueChanged<VendorPrinter> onEdit;
  final ValueChanged<VendorPrinter> onDelete;

  TableRow toTableRow() {
    final typeMeta = _typeMeta(printer.type);
    return TableRow(
      children: [
        _PrinterCell(name: printer.name, model: printer.model),
        _BadgeCell(
          label: typeMeta.label,
          icon: typeMeta.icon,
          tint: typeMeta.tint,
        ),
        _PrintCell(
          printer.sections.isEmpty ? 'غير مرتبطة' : printer.sections.join('\n'),
        ),
        _PrintCell(printer.location.isEmpty ? '-' : printer.location),
        _StatusCell(connected: printer.connected),
        _PrintCell(_formatLastPrint(printer.lastPrintAt)),
        _ActionCell(
          saving: saving,
          onTest: () => onTest(printer),
          onEdit: () => onEdit(printer),
          onDelete: () => onDelete(printer),
        ),
      ],
    );
  }
}

class _TemplateTableRow {
  const _TemplateTableRow({
    required this.template,
    required this.saving,
    required this.onEdit,
    required this.onDelete,
  });

  final InvoiceTemplate template;
  final bool saving;
  final ValueChanged<InvoiceTemplate> onEdit;
  final ValueChanged<InvoiceTemplate> onDelete;

  TableRow toTableRow() {
    final typeMeta = _typeMeta(template.type);
    return TableRow(
      children: [
        _PrintCell(template.name),
        _BadgeCell(
          label: typeMeta.label,
          icon: typeMeta.icon,
          tint: typeMeta.tint,
        ),
        _PrintCell(template.paperWidthMm.toString()),
        _PrintCell(template.paperHeightMm?.toString() ?? 'غير محدد'),
        _PrintCell(template.usage.isEmpty ? '-' : template.usage),
        _TemplateActionCell(
          saving: saving,
          onEdit: () => onEdit(template),
          onDelete: () => onDelete(template),
        ),
      ],
    );
  }
}

class _PrintHeader extends StatelessWidget {
  const _PrintHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrintCell extends StatelessWidget {
  const _PrintCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 11,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrinterCell extends StatelessWidget {
  const _PrinterCell({required this.name, required this.model});

  final String name;
  final String model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 42,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.print_rounded, color: kTextPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name.isEmpty ? '-' : name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  model.isEmpty ? 'غير محدد' : model,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _BadgeCell extends StatelessWidget {
  const _BadgeCell({
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 15, color: tint),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: connected ? kPrimary : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            connected ? 'متصلة' : 'غير متصلة',
            style: TextStyle(
              color: connected ? kPrimary : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.saving,
    required this.onTest,
    required this.onEdit,
    required this.onDelete,
  });

  final bool saving;
  final VoidCallback onTest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Wrap(
        spacing: 6,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: saving ? null : onTest,
            icon: const Icon(Icons.print_rounded, size: 15),
            label: const Text('اختبار'),
          ),
          IconButton.outlined(
            onPressed: saving ? null : onEdit,
            icon: const Icon(Icons.settings_rounded, size: 16),
            color: kTextPrimary,
          ),
          IconButton.outlined(
            onPressed: saving ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _TemplateActionCell extends StatelessWidget {
  const _TemplateActionCell({
    required this.saving,
    required this.onEdit,
    required this.onDelete,
  });

  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Wrap(
        spacing: 6,
        alignment: WrapAlignment.center,
        children: [
          IconButton.outlined(
            onPressed: saving ? null : onEdit,
            icon: const Icon(Icons.edit_rounded, size: 16),
            color: const Color(0xFFF97316),
          ),
          IconButton.outlined(
            onPressed: saving ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _SettingsDropDown extends StatelessWidget {
  const _SettingsDropDown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.containsKey(value) ? value : items.keys.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          items: items.entries
              .map((item) => DropdownMenuItem(
                    value: item.key,
                    child: Text(item.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EmptyPrintState extends StatelessWidget {
  const _EmptyPrintState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kStroke),
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterDialog extends StatefulWidget {
  const _PrinterDialog({this.printer});

  final VendorPrinter? printer;

  @override
  State<_PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<_PrinterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late final TextEditingController _locationController;
  late final TextEditingController _sectionsController;
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late String _type;
  late bool _connected;

  @override
  void initState() {
    super.initState();
    final printer = widget.printer;
    _nameController = TextEditingController(text: printer?.name ?? '');
    _modelController = TextEditingController(text: printer?.model ?? '');
    _locationController = TextEditingController(text: printer?.location ?? '');
    _sectionsController =
        TextEditingController(text: printer?.sections.join('\n') ?? '');
    _ipController = TextEditingController(text: printer?.ip ?? '');
    _portController =
        TextEditingController(text: printer?.port?.toString() ?? '');
    _type = printer?.type ?? 'invoice';
    _connected = printer?.connected ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _locationController.dispose();
    _sectionsController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.printer == null ? 'إضافة طابعة' : 'تعديل طابعة',
        textAlign: TextAlign.right,
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'اسم الطابعة'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اسم الطابعة مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _modelController,
                    decoration:
                        const InputDecoration(labelText: 'موديل الطابعة'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: _printerTypeOptions.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'الموقع'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _sectionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الأقسام المرتبطة',
                      hintText: 'كل قسم في سطر منفصل',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP الطابعة',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Port'),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    value: _connected,
                    onChanged: (value) => setState(() => _connected = value),
                    title: const Text('الطابعة متصلة'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.start,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      VendorPrinter(
        id: widget.printer?.id ?? 0,
        name: _nameController.text.trim(),
        model: _modelController.text.trim(),
        type: _type,
        location: _locationController.text.trim(),
        sections: _sectionsController.text
            .split(RegExp(r'\r\n|\r|\n|,'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        ip: _ipController.text.trim(),
        port: int.tryParse(_portController.text.trim()),
        connected: _connected,
        active: true,
        lastPrintAt: widget.printer?.lastPrintAt,
      ),
    );
  }
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.template});

  final InvoiceTemplate? template;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _usageController;
  late String _type;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _nameController = TextEditingController(text: template?.name ?? '');
    _widthController =
        TextEditingController(text: (template?.paperWidthMm ?? 80).toString());
    _heightController =
        TextEditingController(text: template?.paperHeightMm?.toString() ?? '');
    _usageController = TextEditingController(text: template?.usage ?? '');
    _type = template?.type ?? 'invoice';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.template == null ? 'إضافة قالب' : 'تعديل قالب',
        textAlign: TextAlign.right,
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم القالب'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اسم القالب مطلوب'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'نوع القالب'),
                  items: _printerTypeOptions.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'العرض (مم)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'الارتفاع (مم)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _usageController,
                  decoration: const InputDecoration(labelText: 'الاستخدام'),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.start,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      InvoiceTemplate(
        id: widget.template?.id ?? 0,
        name: _nameController.text.trim(),
        type: _type,
        paperWidthMm: int.tryParse(_widthController.text.trim()) ?? 80,
        paperHeightMm: int.tryParse(_heightController.text.trim()),
        usage: _usageController.text.trim(),
        active: true,
      ),
    );
  }
}

const _printerTypeOptions = {
  'kitchen': 'مطبخ',
  'bar': 'بار',
  'delivery': 'توصيل',
  'invoice': 'فواتير',
  'backup': 'احتياطية',
};

class _TypeMeta {
  const _TypeMeta(this.label, this.icon, this.tint);

  final String label;
  final IconData icon;
  final Color tint;
}

_TypeMeta _typeMeta(String type) {
  switch (type) {
    case 'kitchen':
      return const _TypeMeta(
        'مطبخ',
        Icons.soup_kitchen_rounded,
        kPrimary,
      );
    case 'bar':
      return const _TypeMeta(
        'بار',
        Icons.local_bar_rounded,
        Color(0xFF7C3AED),
      );
    case 'delivery':
      return const _TypeMeta(
        'توصيل',
        Icons.delivery_dining_rounded,
        Color(0xFF2563EB),
      );
    case 'backup':
      return const _TypeMeta(
        'احتياطية',
        Icons.verified_user_outlined,
        kTextSecondary,
      );
    case 'invoice':
    default:
      return const _TypeMeta(
        'فواتير',
        Icons.receipt_long_rounded,
        Color(0xFFF59E0B),
      );
  }
}

String _formatLastPrint(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final now = DateTime.now();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final time = '$hour:$minute';
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'اليوم\n$time';
  }

  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}/$month/$day\n$time';
}

String _cleanError(Object error) {
  final text = error.toString();
  return text.replaceFirst('Exception: ', '').trim();
}
