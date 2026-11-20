// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations

import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class ScheduledOrdersBoard extends StatefulWidget {
  const ScheduledOrdersBoard({
    super.key,
    required this.orders,
    required this.selectedOrder,
    required this.controller,
    required this.itemImagesById,
    required this.vendorId,
    required this.onSelectOrder,
    required this.onConfirmScheduled,
    required this.onAdjustScheduled,
    required this.onCancelScheduled,
    required this.onShowAllOrders,
    required this.onRefreshOrders,
  });

  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final OrderController controller;
  final Map<int, String> itemImagesById;
  final int vendorId;
  final ValueChanged<OrderModel> onSelectOrder;
  final Future<void> Function(OrderModel order, int estimatedMinutes)
      onConfirmScheduled;
  final Future<void> Function(OrderModel order, int estimatedMinutes)
      onAdjustScheduled;
  final Future<void> Function(OrderModel order, String reason)
      onCancelScheduled;
  final VoidCallback onShowAllOrders;
  final Future<void> Function() onRefreshOrders;

  @override
  State<ScheduledOrdersBoard> createState() => _ScheduledOrdersBoardState();
}

class _ScheduledOrdersBoardState extends State<ScheduledOrdersBoard> {
  static const List<String> _windowOrder = ['all', 'today', 'tomorrow', 'week'];
  static const List<int> _minuteOptions = [10, 15, 20, 25, 30, 45];

  String _selectedWindow = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders(widget.orders);
    final selectedOrder = _selectedOrderFrom(filteredOrders);

    if (selectedOrder == null) {
      return const DashboardEmptyState(
        title: 'لا توجد طلبات مجدولة الآن',
        subtitle:
            'سيظهر هنا أي طلب مجدول بمجرد وصوله إلى النظام أو عند تغيير الفلتر.',
        icon: Icons.event_available_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 1180;
        final queuePanel = _buildQueuePanel(filteredOrders, selectedOrder);
        final detailsPanel = _buildDetailsPanel(selectedOrder);
        final actionsPanel = _buildActionsPanel(selectedOrder);

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              queuePanel,
              const SizedBox(height: 16),
              detailsPanel,
              const SizedBox(height: 16),
              actionsPanel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 27, child: queuePanel),
            const SizedBox(width: 14),
            Expanded(flex: 38, child: detailsPanel),
            const SizedBox(width: 14),
            Expanded(flex: 35, child: actionsPanel),
          ],
        );
      },
    );
  }

  Widget _buildQueuePanel(List<OrderModel> orders, OrderModel selected) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CounterPill(count: orders.length),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'الطلبات المجدولة',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onRefreshOrders,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'تحديث الطلبات',
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'اليوم',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final window in _windowOrder)
                ChoiceChip(
                  selected: _selectedWindow == window,
                  label: Text(_windowLabel(window)),
                  labelStyle: TextStyle(
                    color: _selectedWindow == window ? kPrimary : kTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => setState(() => _selectedWindow = window),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _DateDisplayCard(date: DateTime.now()),
          const SizedBox(height: 14),
          for (final order in orders) ...[
            _ScheduledOrderCard(
              order: order,
              selected: selected.ordersId == order.ordersId,
              onTap: () => widget.onSelectOrder(order),
              scheduleLabel: _scheduleDayLabel(order.scheduledDateTime),
              scheduleTimeLabel: _scheduleShortTime(order.scheduledDateTime),
              occasionLabel: _occasionLabel(order),
              occasionIcon: _occasionIcon(order),
              occasionTint: _occasionTint(order),
              moneyLabel: _displayMoney(order.totalPriceValue),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onShowAllOrders,
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('عرض جميع الطلبات المجدولة'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                side: const BorderSide(color: kStroke),
                foregroundColor: kTextPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(OrderModel selected) {
    return DashboardPanel(
      child: FutureBuilder<List<OrderItemDetail>>(
        key: ValueKey(selected.ordersId),
        future: widget.controller.fetchOrderDetails(
          selected.ordersId ?? 0,
          vendorId: selected.vendorId ?? widget.vendorId,
        ),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <OrderItemDetail>[];
          final scheduledText =
              _scheduleBannerLabel(selected.scheduledDateTime);
          final occasionText = _occasionLabel(selected);
          final noteText = _firstNonEmpty([
            selected.ordersDeliveryNote,
            selected.ordersGiftMessage,
          ]);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _MiniPill(
                    label: _scheduleDayLabel(selected.scheduledDateTime),
                    color: kPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تفاصيل الطلب',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#${selected.ordersId ?? '-'}',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _BannerCard(
                background: const Color(0xFFF0F8F1),
                border: const Color(0xFFD9E8DC),
                icon: Icons.schedule_rounded,
                iconColor: kPrimary,
                text: 'موعد الاستلام المحدد: $scheduledText',
              ),
              const SizedBox(height: 10),
              _BannerCard(
                background: const Color(0xFFFCECEC),
                border: const Color(0xFFF3C2C2),
                icon: _occasionIcon(selected),
                iconColor: const Color(0xFFDD2F2F),
                text: 'مناسبة الطلب: $occasionText',
                textColor: const Color(0xFFCE1F1F),
              ),
              const SizedBox(height: 18),
              const _BoardSectionHeader(
                title: 'المنتجات',
                icon: Icons.shopping_cart_rounded,
              ),
              const SizedBox(height: 12),
              _InnerCard(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: LinearProgressIndicator(color: kPrimary),
                      )
                    : items.isEmpty
                        ? const DashboardEmptyState(
                            title: 'لا توجد منتجات بعد',
                            subtitle:
                                'سيظهر محتوى الطلب هنا بعد اكتمال تحميل تفاصيله.',
                            icon: Icons.shopping_bag_outlined,
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < items.length; i++) ...[
                                _ScheduledItemRow(
                                  item: items[i],
                                  imageName:
                                      widget.itemImagesById[items[i].itemId],
                                  moneyLabel: _displayMoney(items[i].lineTotal),
                                ),
                                if (i != items.length - 1)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                              ],
                            ],
                          ),
              ),
              const SizedBox(height: 18),
              const _BoardSectionHeader(
                title: 'الملاحظات',
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 12),
              _MutedCard(
                child: Text(
                  noteText.isNotEmpty ? noteText : 'بدون ملاحظات',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B4E1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionsPanel(OrderModel selected) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BoardSectionHeader(
            title: 'إجراءات الطلب',
            icon: Icons.settings_suggest_rounded,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showPrepTimeSheet(
                order: selected,
                title: 'تأكيد الطلب المجدول',
                subtitle:
                    'ثبت وقت الجاهزية قبل بدء التنفيذ حتى يظل المسار واضحًا للفريق.',
                confirmLabel: 'تأكيد الطلب',
                onConfirm: widget.onConfirmScheduled,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تأكيد الطلب'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showPrepTimeSheet(
                order: selected,
                title: 'تعديل الجاهزية',
                subtitle:
                    'غيّر مدة التحضير قبل الموعد المحدد إذا طرأ أي تغيير على تجهيز الطلب.',
                confirmLabel: 'حفظ التعديل',
                onConfirm: widget.onAdjustScheduled,
              ),
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('تعديل الجاهزية'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                backgroundColor: const Color(0xFFF4B63A),
                foregroundColor: const Color(0xFF8A5A00),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showCancelSheet(selected),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('إلغاء الطلب'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                backgroundColor: const Color(0xFFF97373),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatusCard(
            title: 'حالة الطلب',
            icon: Icons.calendar_month_rounded,
            accent: kPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                const Text(
                  'مجدول - محدد',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'مراحل الطلب',
            icon: Icons.timeline_rounded,
            accent: kPrimary,
            child: Column(
              children: [
                _StageTile(
                  title: 'تم تحديد موعد الاستلام',
                  subtitle: 'تم تحديد موعد الاستلام من قبل العميل',
                  icon: Icons.event_available_rounded,
                  active: true,
                ),
                _StageTile(
                  title: 'قيد التحضير',
                  subtitle: 'سيبدأ التحضير في الوقت المحدد',
                  icon: Icons.kitchen_rounded,
                  active: false,
                ),
                _StageTile(
                  title: 'جاهز للاستلام',
                  subtitle: 'الطلب جاهز في الوقت المحدد',
                  icon: Icons.inventory_2_outlined,
                  active: false,
                ),
                _StageTile(
                  title: 'مكتمل',
                  subtitle: 'تم استلام الطلب بنجاح',
                  icon: Icons.check_circle_outline_rounded,
                  active: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'معلومات إضافية',
            icon: Icons.info_outline_rounded,
            accent: kTextSecondary,
            child: Column(
              children: [
                _PairRow(
                    label: 'رقم الطلب', value: '#${selected.ordersId ?? '-'}'),
                const SizedBox(height: 10),
                _PairRow(
                  label: 'تاريخ إنشاء الطلب',
                  value: _formatCreationDate(selected.orderDateTime),
                ),
                const SizedBox(height: 10),
                _PairRow(label: 'طريقة الطلب', value: 'تطبيق العميل'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4DD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0D58B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFB87900)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يمكنك تعديل وقت الجاهزية أو إلغاء الطلب قبل موعد الاستلام بساعتين على الأقل.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8F6400),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
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

  Future<void> _showPrepTimeSheet({
    required OrderModel order,
    required String title,
    required String subtitle,
    required String confirmLabel,
    required Future<void> Function(OrderModel order, int estimatedMinutes)
        onConfirm,
  }) async {
    final controller = TextEditingController(
      text: (order.ordersEstimatedMinutes != null &&
              order.ordersEstimatedMinutes! > 0)
          ? order.ordersEstimatedMinutes.toString()
          : '25',
    );
    var selectedMinutes = int.tryParse(controller.text.trim()) ??
        (order.ordersEstimatedMinutes ?? 25);
    var useManual = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: kSurfaceElevated,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionSummaryCard(order: order, accent: kPrimary),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final minutes in _minuteOptions)
                            ChoiceChip(
                              selected:
                                  !useManual && selectedMinutes == minutes,
                              label: Text('$minutes دقيقة'),
                              onSelected: (_) {
                                setModalState(() {
                                  useManual = false;
                                  selectedMinutes = minutes;
                                  controller.text = minutes.toString();
                                });
                              },
                            ),
                          ChoiceChip(
                            selected: useManual,
                            label: const Text('إدخال يدوي'),
                            onSelected: (_) {
                              setModalState(() => useManual = true);
                            },
                          ),
                        ],
                      ),
                      if (useManual) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'مدة التحضير بالدقائق',
                            prefixIcon: Icon(Icons.timer_rounded),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value.trim());
                            if (parsed != null) {
                              selectedMinutes = parsed;
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final parsed = useManual
                                ? int.tryParse(controller.text.trim())
                                : selectedMinutes;
                            if (parsed == null || parsed <= 0) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text('أدخل مدة تحضير صحيحة'),
                                ),
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                            await onConfirm(order, parsed);
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showCancelSheet(OrderModel order) async {
    final reasonController = TextEditingController();
    var selectedReason = 'تغيير في الوقت';
    const reasons = [
      'تغيير في الوقت',
      'الطلب غير مناسب',
      'العميل طلب الإلغاء',
      'سبب آخر',
    ];

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: kSurfaceElevated,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return StatefulBuilder(
            builder: (context, setModalState) {
              final needsCustomReason = selectedReason == 'سبب آخر';
              return Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إلغاء الطلب المجدول',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'حدد سبب الإلغاء حتى يتم حفظه في السجل الداخلي وإرساله للعميل.',
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionSummaryCard(
                          order: order, accent: const Color(0xFFF97373)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final reason in reasons)
                            ChoiceChip(
                              selected: selectedReason == reason,
                              label: Text(reason),
                              onSelected: (_) {
                                setModalState(() => selectedReason = reason);
                              },
                            ),
                        ],
                      ),
                      if (needsCustomReason) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'اكتب سبب الإلغاء',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF97373),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final reason = needsCustomReason
                                ? reasonController.text.trim()
                                : selectedReason;
                            if (needsCustomReason && reason.isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text('اكتب سببًا واضحًا للإلغاء'),
                                ),
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                            await widget.onCancelScheduled(order, reason);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('إلغاء الطلب'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      reasonController.dispose();
    }
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final filtered = orders.where((order) {
      if (order.lifecycleBucket != 'scheduled') {
        return false;
      }
      switch (_selectedWindow) {
        case 'today':
          return _isSameDay(order.scheduledDateTime, DateTime.now());
        case 'tomorrow':
          return _isSameDay(
            order.scheduledDateTime,
            DateTime.now().add(const Duration(days: 1)),
          );
        case 'week':
          final now = DateTime.now();
          final from = DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 2));
          final to = from.add(const Duration(days: 6));
          final scheduled = order.scheduledDateTime;
          return scheduled != null &&
              !scheduled.isBefore(from) &&
              scheduled.isBefore(to.add(const Duration(days: 1)));
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      final aScheduled = a.scheduledDateTime;
      final bScheduled = b.scheduledDateTime;
      if (aScheduled != null && bScheduled != null) {
        final compare = aScheduled.compareTo(bScheduled);
        if (compare != 0) return compare;
      } else if (aScheduled != null) {
        return -1;
      } else if (bScheduled != null) {
        return 1;
      }
      return (b.ordersId ?? 0).compareTo(a.ordersId ?? 0);
    });

    return filtered;
  }

  OrderModel? _selectedOrderFrom(List<OrderModel> orders) {
    if (orders.isEmpty) return null;
    if (widget.selectedOrder != null) {
      for (final order in orders) {
        if (order.ordersId == widget.selectedOrder!.ordersId) {
          return order;
        }
      }
    }
    return orders.first;
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _windowLabel(String window) {
    switch (window) {
      case 'today':
        return 'اليوم';
      case 'tomorrow':
        return 'غدًا';
      case 'week':
        return 'هذا الأسبوع';
      default:
        return 'الكل';
    }
  }

  String _scheduleDayLabel(DateTime? dateTime) {
    if (dateTime == null) return 'بدون موعد';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (_isSameDay(dateTime, today)) return 'اليوم';
    if (_isSameDay(dateTime, tomorrow)) return 'غدًا';
    if (dateOnly.isAfter(tomorrow) &&
        dateOnly.isBefore(today.add(const Duration(days: 8)))) {
      return 'هذا الأسبوع';
    }
    return _formatArabicDate(dateTime);
  }

  String _scheduleShortTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return '${_formatHour(dateTime.hour)}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'م' : 'ص'}';
  }

  String _scheduleBannerLabel(DateTime? dateTime) {
    if (dateTime == null) return 'غير محدد';
    return '${_scheduleDayLabel(dateTime)}، ${_formatHour(dateTime.hour)}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'مساء' : 'صباح'}';
  }

  String _formatCreationDate(DateTime? dateTime) {
    if (dateTime == null) return 'غير متاح';
    final hour = _formatHour(dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'م' : 'ص';
    return '${dateTime.day} ${_arabicMonthName(dateTime.month)} ${dateTime.year} - $hour:$minute $suffix';
  }

  String _formatArabicDate(DateTime dateTime) {
    return '${dateTime.day} ${_arabicMonthName(dateTime.month)} ${dateTime.year}';
  }

  String _formatHour(int hour) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return hour12.toString();
  }

  String _arabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  String _occasonlessFallback() => 'بدون مناسبة محددة';

  String _occasionLabel(OrderModel order) {
    final raw = (order.ordersGiftMessage ?? '').trim();
    return raw.isNotEmpty ? raw : _occasonlessFallback();
  }

  IconData _occasionIcon(OrderModel order) {
    final text = _occasionLabel(order);
    if (text.contains('ميلاد') || text.contains('عيد')) {
      return Icons.cake_rounded;
    }
    if (text.contains('اجتماع')) {
      return Icons.groups_rounded;
    }
    if (text.contains('رومان')) {
      return Icons.favorite_rounded;
    }
    if (text.contains('تخرج')) {
      return Icons.school_rounded;
    }
    if (text.contains('عائلي')) {
      return Icons.family_restroom_rounded;
    }
    return Icons.event_available_rounded;
  }

  Color _occasionTint(OrderModel order) {
    final text = _occasionLabel(order);
    if (text.contains('ميلاد') || text.contains('عيد')) {
      return const Color(0xFFB91C1C);
    }
    if (text.contains('اجتماع')) {
      return const Color(0xFFF59E0B);
    }
    if (text.contains('رومان')) {
      return const Color(0xFFEF476F);
    }
    if (text.contains('تخرج')) {
      return const Color(0xFF6D28D9);
    }
    if (text.contains('عائلي')) {
      return const Color(0xFF2563EB);
    }
    return kPrimary;
  }

  String _displayMoney(double value) {
    final formatted = value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$formatted SAR';
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: kPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DateDisplayCard extends StatelessWidget {
  const _DateDisplayCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.calendar_month_rounded, color: kTextSecondary),
          Text(
            '${date.day} ${_ScheduleDateHelper.arabicMonth(date.month)} ${date.year}',
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledOrderCard extends StatelessWidget {
  const _ScheduledOrderCard({
    required this.order,
    required this.selected,
    required this.onTap,
    required this.scheduleLabel,
    required this.scheduleTimeLabel,
    required this.occasionLabel,
    required this.occasionIcon,
    required this.occasionTint,
    required this.moneyLabel,
  });

  final OrderModel order;
  final bool selected;
  final VoidCallback onTap;
  final String scheduleLabel;
  final String scheduleTimeLabel;
  final String occasionLabel;
  final IconData occasionIcon;
  final Color occasionTint;
  final String moneyLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FAF5) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? kPrimary : kStroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: occasionTint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(occasionIcon, color: occasionTint, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MiniPill(
                        label: scheduleLabel,
                        color: selected ? kPrimary : const Color(0xFFB9D6C0),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            scheduleTimeLabel,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          occasionLabel,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.usersName?.trim().isNotEmpty == true
                              ? order.usersName!.trim()
                              : 'عميل غير معروف',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        moneyLabel,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${order.ordersId ?? '-'}',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.background,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.textColor = kPrimary,
  });

  final Color background;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: iconColor),
        ],
      ),
    );
  }
}

class _BoardSectionHeader extends StatelessWidget {
  const _BoardSectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, color: kTextSecondary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active ? const Color(0xFFF3FAF4) : Colors.white;
    final border = active ? kPrimary : kStroke;
    final accent = active ? kPrimary : kTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
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

class _PairRow extends StatelessWidget {
  const _PairRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InnerCard extends StatelessWidget {
  const _InnerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: child,
    );
  }
}

class _MutedCard extends StatelessWidget {
  const _MutedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1E2B8)),
      ),
      child: child,
    );
  }
}

class _ScheduledItemRow extends StatelessWidget {
  const _ScheduledItemRow({
    required this.item,
    required this.imageName,
    required this.moneyLabel,
  });

  final OrderItemDetail item;
  final String? imageName;
  final String moneyLabel;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageName?.trim().isNotEmpty == true;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kStroke),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AppNetworkImage(
                    imageUrl: imageName!,
                    fit: BoxFit.cover,
                    width: 58,
                    height: 58,
                    placeholderIcon: Icons.fastfood_outlined,
                  ),
                )
              : const Icon(Icons.fastfood_outlined, color: kTextSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الكمية: ${item.quantity}',
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          moneyLabel,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActionSummaryCard extends StatelessWidget {
  const _ActionSummaryCard({
    required this.order,
    required this.accent,
  });

  final OrderModel order;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final chips = <_SummaryChipData>[
      _SummaryChipData(label: 'الطلب', value: '#${order.ordersId ?? '-'}'),
      _SummaryChipData(
        label: 'العميل',
        value: order.usersName?.trim().isNotEmpty == true
            ? order.usersName!.trim()
            : 'غير معروف',
      ),
      _SummaryChipData(label: 'نوع الطلب', value: order.orderTypeLabel),
      _SummaryChipData(
        label: 'الموعد',
        value: _ScheduleDateHelper.scheduleChipText(order.scheduledDateTime),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips
            .map(
              (chip) => _SummaryChip(data: chip, accent: accent),
            )
            .toList(),
      ),
    );
  }
}

class _SummaryChipData {
  const _SummaryChipData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.data,
    required this.accent,
  });

  final _SummaryChipData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: TextStyle(
              color: accent.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDateHelper {
  static String arabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  static String scheduleChipText(DateTime? dateTime) {
    if (dateTime == null) return 'غير محدد';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (dateOnly == today) return 'اليوم';
    if (dateOnly == tomorrow) return 'غدًا';
    if (dateOnly.isAfter(tomorrow) &&
        dateOnly.isBefore(today.add(const Duration(days: 8)))) {
      return 'هذا الأسبوع';
    }
    return '${dateTime.day} ${arabicMonth(dateTime.month)}';
  }
}
