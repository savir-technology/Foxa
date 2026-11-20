// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _PrintingInvoicesWorkspace extends StatelessWidget {
  const _PrintingInvoicesWorkspace({
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
    required this.selectedOrderKey,
    required this.onOrderSelected,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
    required this.onSavePrintingSettings,
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
  final String? selectedOrderKey;
  final ValueChanged<_MasterOrderRowData> onOrderSelected;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final Future<void> Function(int copies, bool printLogo)
  onSavePrintingSettings;

  @override
  Widget build(BuildContext context) {
    final selectedOrder = _selectedPrintingOrder(data, selectedOrderKey);
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'الطباعة والفواتير',
          subtitle: 'طباعة الإيصالات والفواتير لجميع أنواع الطلبات',
          icon: Icons.print_outlined,
        ),
        const SizedBox(height: 8),
        _OrdersStatsStrip(cards: _printingInvoicesStats(data)),
        const SizedBox(height: 8),
        _PrintingInvoicesToolbar(
          data: data,
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
        Expanded(
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 210,
                child: _PrintingOptionsPanel(
                  data: data,
                  onSave: onSavePrintingSettings,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PrintingOrdersTablePanel(
                  data: data,
                  selectedOrderKey: selectedOrder == null
                      ? null
                      : _orderSelectionKey(selectedOrder),
                  onOrderSelected: onOrderSelected,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 260,
                child: _PrintingPreviewPanel(
                  order: selectedOrder,
                  printing: data.printing,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrintingInvoicesToolbar extends StatelessWidget {
  const _PrintingInvoicesToolbar({
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
          onPressed: onReload,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(74, 40),
            side: const BorderSide(color: Color(0xFFE7ECE8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('تحديث'),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: () => _exportOrdersToClipboard(context, data, 'الفواتير'),
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
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: () => _showOrdersPrintSheet(context, data, 'الفواتير'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(112, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.expand_more_rounded, size: 16),
          label: const Text('طباعة متعددة'),
        ),
      ],
    );
  }
}

class _PrintingOptionsPanel extends StatefulWidget {
  const _PrintingOptionsPanel({required this.data, required this.onSave});

  final _MasterOrdersData data;
  final Future<void> Function(int copies, bool printLogo) onSave;

  @override
  State<_PrintingOptionsPanel> createState() => _PrintingOptionsPanelState();
}

class _PrintingOptionsPanelState extends State<_PrintingOptionsPanel> {
  String _documentType = 'receipt';
  String _template = 'القالب الافتراضي';
  String _paperSize = '80mm (إيصال)';
  late int _copies;
  late bool _printLogo;
  bool _printAddress = true;
  bool _printQr = true;
  bool _printNotes = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _copies = widget.data.printing.invoiceCopies;
    _printLogo = widget.data.printing.printLogo;
  }

  @override
  void didUpdateWidget(covariant _PrintingOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.printing.invoiceCopies !=
        widget.data.printing.invoiceCopies) {
      _copies = widget.data.printing.invoiceCopies;
    }
    if (oldWidget.data.printing.printLogo != widget.data.printing.printLogo) {
      _printLogo = widget.data.printing.printLogo;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? activePrinter;
    for (final printer in widget.data.printing.printers) {
      if (printer.isActive) {
        activePrinter = printer.displayLabel;
        break;
      }
    }
    return ListView(
      children: [
        _OrdersSideCard(
          title: 'خيارات الطباعة',
          children: [
            _PrintingRadioLine(
              label: 'إيصال طلب',
              selected: _documentType == 'receipt',
              onTap: () => setState(() => _documentType = 'receipt'),
            ),
            _PrintingRadioLine(
              label: 'فاتورة ضريبية',
              selected: _documentType == 'tax',
              onTap: () => setState(() => _documentType = 'tax'),
            ),
            _PrintingRadioLine(
              label: 'فاتورة مبسطة',
              selected: _documentType == 'simple',
              onTap: () => setState(() => _documentType = 'simple'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'قالب الطباعة',
          children: [
            _PrintingSelectLine(
              label: _template,
              options: widget.data.printing.templates.isEmpty
                  ? const ['القالب الافتراضي', 'قالب مطعم', 'قالب مختصر']
                  : widget.data.printing.templates,
              onSelected: (value) => setState(() => _template = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'الطابعة',
          children: [
            _PrintingSelectLine(label: activePrinter ?? 'لا توجد طابعة نشطة'),
            const SizedBox(height: 5),
            _PrintingConnectedLabel(
              label: '${widget.data.printing.connectedPrinters} متصلة',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'عدد النسخ',
          children: [
            _PrintingCopiesStepper(
              value: _copies,
              onChanged: (value) => setState(() => _copies = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'حجم الورق',
          children: [
            _PrintingSelectLine(
              label: _paperSize,
              options: const ['80mm (إيصال)', 'A4', 'A5'],
              onSelected: (value) => setState(() => _paperSize = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'خيارات إضافية',
          children: [
            _PrintingCheckLine(
              label: 'طباعة شعار',
              selected: _printLogo,
              onChanged: (value) => setState(() => _printLogo = value),
            ),
            _PrintingCheckLine(
              label: 'طباعة العنوان',
              selected: _printAddress,
              onChanged: (value) => setState(() => _printAddress = value),
            ),
            _PrintingCheckLine(
              label: 'طباعة QR للطلب',
              selected: _printQr,
              onChanged: (value) => setState(() => _printQr = value),
            ),
            _PrintingCheckLine(
              label: 'طباعة ملاحظات العميل',
              selected: _printNotes,
              onChanged: (value) => setState(() => _printNotes = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await widget.onSave(_copies, _printLogo);
                  } catch (error) {
                    if (context.mounted) {
                      _showMasterSnack(context, error.toString());
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات'),
        ),
      ],
    );
  }
}

class _PrintingRadioLine extends StatelessWidget {
  const _PrintingRadioLine({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 15,
              color: selected ? _kPrimaryGreen : const Color(0xFF9AA1AA),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10.5,
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

class _PrintingCheckLine extends StatelessWidget {
  const _PrintingCheckLine({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Checkbox(
            value: selected,
            onChanged: (value) => onChanged(value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintingSelectLine extends StatelessWidget {
  const _PrintingSelectLine({
    required this.label,
    this.options = const [],
    this.onSelected,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            size: 15,
            color: Color(0xFF4E5660),
          ),
        ],
      ),
    );
    if (options.isEmpty || onSelected == null) {
      return content;
    }
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option,
            child: Text(option, textAlign: TextAlign.right),
          ),
      ],
      child: content,
    );
  }
}

class _PrintingConnectedLabel extends StatelessWidget {
  const _PrintingConnectedLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        const Icon(Icons.circle, size: 7, color: _kPrimaryGreen),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: _kPrimaryGreen,
          ),
        ),
      ],
    );
  }
}

class _PrintingCopiesStepper extends StatelessWidget {
  const _PrintingCopiesStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PrintingMiniButton(
          icon: Icons.remove_rounded,
          onTap: () => onChanged(math.max(1, value - 1)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _PrintingMiniButton(
          icon: Icons.add_rounded,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _PrintingMiniButton extends StatelessWidget {
  const _PrintingMiniButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFB),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Icon(icon, size: 15, color: const Color(0xFF4E5660)),
      ),
    );
  }
}

class _PrintingOrdersTablePanel extends StatelessWidget {
  const _PrintingOrdersTablePanel({
    required this.data,
    required this.selectedOrderKey,
    required this.onOrderSelected,
  });

  final _MasterOrdersData data;
  final String? selectedOrderKey;
  final ValueChanged<_MasterOrderRowData> onOrderSelected;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.description_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  'قائمة الطلبات للطباعة (${data.total})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const _PrintingOrdersTableHeader(),
          Expanded(
            child: data.orders.isEmpty
                ? const Center(child: Text('لا توجد طلبات للطباعة الآن'))
                : ListView.separated(
                    itemCount: data.orders.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = data.orders[index];
                      return _PrintingOrdersTableRow(
                        order: order,
                        selected: _orderSelectionKey(order) == selectedOrderKey,
                        onSelected: () => onOrderSelected(order),
                      );
                    },
                  ),
          ),
          _OrdersPaginationBar(data: data),
        ],
      ),
    );
  }
}

class _PrintingOrdersTableHeader extends StatelessWidget {
  const _PrintingOrdersTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: Color(0xFF6F7680),
    );
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(color: Color(0xFFFBFCFB)),
      child: Row(
        textDirection: TextDirection.rtl,
        children: const [
          _OrdersTableCell(
            flex: 7,
            child: Text('اختيار', style: style, textAlign: TextAlign.center),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('رقم الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 14,
            child: Text('العميل', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 16,
            child: Text('المطعم', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 11,
            child: Text('الحالة', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('المبلغ', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 10,
            child: Text('وقت الطلب', style: style, textAlign: TextAlign.right),
          ),
          _OrdersTableCell(
            flex: 9,
            child: Text('المستند', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _PrintingOrdersTableRow extends StatelessWidget {
  const _PrintingOrdersTableRow({
    required this.order,
    required this.selected,
    required this.onSelected,
  });

  final _MasterOrderRowData order;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF5ED) : Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _OrdersTableCell(
                flex: 7,
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onSelected(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              _OrdersTableCell(
                flex: 10,
                child: _OrdersTwoLine(title: order.orderNo, subtitle: ''),
              ),
              _OrdersTableCell(
                flex: 14,
                child: _OrdersTwoLine(
                  title: order.customer,
                  subtitle: order.phone,
                ),
              ),
              _OrdersTableCell(
                flex: 16,
                child: _OrdersRestaurantCell(order: order),
              ),
              _OrdersTableCell(
                flex: 11,
                child: _OrdersStatusPill(order: order),
              ),
              _OrdersTableCell(
                flex: 10,
                child: _OrdersTwoLine(title: order.amountLabel, subtitle: ''),
              ),
              _OrdersTableCell(
                flex: 10,
                child: _OrdersTwoLine(
                  title: order.timeLabel,
                  subtitle: order.relativeLabel,
                ),
              ),
              _OrdersTableCell(
                flex: 9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Color(0xFF4E5660),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.paymentKey == 'cash' ? 'إيصال' : 'فاتورة',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF59616B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _orderSelectionKey(_MasterOrderRowData order) {
  if (order.orderId > 0) {
    return 'id:${order.orderId}';
  }
  return 'no:${order.orderNo}';
}

_MasterOrderRowData? _selectedPrintingOrder(
  _MasterOrdersData data,
  String? selectedOrderKey,
) {
  if (data.orders.isEmpty) {
    return null;
  }
  if (selectedOrderKey != null) {
    for (final order in data.orders) {
      if (_orderSelectionKey(order) == selectedOrderKey) {
        return order;
      }
    }
  }
  return data.orders.first;
}

class _PrintingPreviewPanel extends StatelessWidget {
  const _PrintingPreviewPanel({required this.order, required this.printing});

  final _MasterOrderRowData? order;
  final _OrdersPrintingData printing;

  @override
  Widget build(BuildContext context) {
    final printers = printing.printers;
    return ListView(
      children: [
        _OrdersSideCard(
          title: 'معاينة المستند',
          children: [
            _PrintingReceiptPreview(order: order),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: order == null
                    ? null
                    : () => _printOrderFromPreview(context, order!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('طباعة المستند'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'طابعات متصلة',
          children: [
            if (printers.isEmpty)
              const Text(
                'لا توجد طابعات مسجلة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A919A),
                ),
              )
            else
              for (final printer in printers.take(5))
                _PrintingPrinterLine(
                  label: printer.displayLabel,
                  isActive: printer.isActive,
                ),
            const SizedBox(height: 6),
            _PrintingManagePrintersButton(printers: printers),
          ],
        ),
      ],
    );
  }
}

class _PrintingReceiptPreview extends StatelessWidget {
  const _PrintingReceiptPreview({required this.order});

  final _MasterOrderRowData? order;

  @override
  Widget build(BuildContext context) {
    final activeOrder = order;
    final orderNo = activeOrder?.orderNo ?? '#----';
    final restaurant = activeOrder?.restaurant ?? 'FOXA';
    final amount = activeOrder?.amountLabel ?? '0 س';
    final type = activeOrder?.typeLabel ?? 'طلب';
    final items = activeOrder?.items ?? const <_OrderReceiptItemData>[];
    final qrData = _orderQrPayload(activeOrder);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'FOXA',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            restaurant,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            '$type - إيصال طلب',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const _PrintingDashedLine(),
          const SizedBox(height: 8),
          _PrintingReceiptLine(label: 'رقم الطلب', value: orderNo),
          _PrintingReceiptLine(
            label: 'الوقت',
            value: activeOrder?.timeLabel ?? '--:--',
          ),
          const SizedBox(height: 8),
          const _PrintingDashedLine(),
          const SizedBox(height: 8),
          if (items.isEmpty) ...[
            const _PrintingReceiptLine(label: 'الصنف', value: 'طلب من المطعم'),
            const _PrintingReceiptLine(label: 'الكمية', value: '1'),
            _PrintingReceiptLine(label: 'السعر', value: amount),
          ] else ...[
            for (final item in items.take(4))
              _PrintingReceiptLine(
                label: '${item.name} x${item.quantity}',
                value: item.total.isEmpty ? item.unitPrice : item.total,
              ),
          ],
          const SizedBox(height: 8),
          const _PrintingDashedLine(),
          const SizedBox(height: 8),
          _PrintingReceiptLine(label: 'الإجمالي', value: amount, strong: true),
          const SizedBox(height: 10),
          const Text(
            'شكرا لثقتكم بنا',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              padding: const EdgeInsets.all(4),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'امسح الكود لتتبع طلبك',
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PrintingReceiptLine extends StatelessWidget {
  const _PrintingReceiptLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: strong ? 10.5 : 9.2,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
      color: const Color(0xFF1E232A),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(label, textAlign: TextAlign.right, style: style),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

String _orderQrPayload(_MasterOrderRowData? order) {
  if (order == null) {
    return 'https://savir-technology.online/roaqv2/';
  }
  if (order.trackingUrl.trim().isNotEmpty) {
    return order.trackingUrl.trim();
  }
  if (order.shareToken.trim().isNotEmpty) {
    return 'https://savir-technology.online/roaqv2/track.php?token=${Uri.encodeComponent(order.shareToken.trim())}';
  }
  if (order.orderId > 0) {
    return 'https://savir-technology.online/roaqv2/orders/details.php?id=${order.orderId}';
  }
  final orderNo = order.orderNo.replaceAll('#', '').trim();
  return orderNo.isEmpty
      ? 'https://savir-technology.online/roaqv2/'
      : 'https://savir-technology.online/roaqv2/orders/details.php?id=$orderNo';
}

class _PrintingDashedLine extends StatelessWidget {
  const _PrintingDashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 7).floor();
        return Row(
          children: List.generate(
            dashCount,
            (index) => Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: const Color(0xFF9AA1AA),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrintingPrinterLine extends StatelessWidget {
  const _PrintingPrinterLine({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.print_outlined,
            size: 14,
            color: isActive ? _kPrimaryGreen : const Color(0xFF9AA1AA),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            isActive ? 'متصلة' : 'غير نشطة',
            style: TextStyle(
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
              color: isActive ? _kPrimaryGreen : const Color(0xFF9AA1AA),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintingManagePrintersButton extends StatelessWidget {
  const _PrintingManagePrintersButton({required this.printers});

  final List<_OrdersPrinterData> printers;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إدارة الطابعات'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (printers.isEmpty)
                      const Text('لا توجد طابعات مسجلة في قاعدة البيانات')
                    else
                      for (final printer in printers)
                        _PrintingPrinterLine(
                          label: printer.displayLabel,
                          isActive: printer.isActive,
                        ),
                  ],
                ),
              ),
            );
          },
        );
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE7ECE8)),
        foregroundColor: const Color(0xFF4E5660),
      ),
      icon: const Icon(Icons.settings_outlined, size: 15),
      label: const Text('إدارة الطابعات', style: TextStyle(fontSize: 10.5)),
    );
  }
}

List<_OperationsStatCardData> _printingInvoicesStats(_MasterOrdersData data) {
  final canceled = data.orders
      .where((order) => order.statusLabel.contains('ملغ'))
      .length;
  return [
    _printingStat(
      title: 'طابعات متصلة',
      value: '${data.printing.connectedPrinters}',
      icon: Icons.print_outlined,
      color: const Color(0xFF4E5660),
      caption: 'متصلة الآن',
    ),
    _printingStat(
      title: 'ملغاة',
      value: '$canceled',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFD92C2C),
      positive: false,
    ),
    _printingStat(
      title: 'طلبات اليوم',
      value: '${data.total}',
      icon: Icons.receipt_long_outlined,
      color: _kPrimaryGreen,
    ),
    _printingStat(
      title: 'فواتير مطبوعة',
      value: '${data.printing.printedInvoices}',
      icon: Icons.description_outlined,
      color: const Color(0xFFF59E0B),
    ),
    _printingStat(
      title: 'إيصالات مطبوعة',
      value: '${data.printing.printedReceipts}',
      icon: Icons.assignment_outlined,
      color: const Color(0xFF2563EB),
    ),
    _printingStat(
      title: 'إجمالي مطبوعات اليوم',
      value: '${data.printing.printedToday}',
      icon: Icons.print_rounded,
      color: const Color(0xFF7C3AED),
    ),
  ];
}

_OperationsStatCardData _printingStat({
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
