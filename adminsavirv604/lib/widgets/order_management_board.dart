import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class OrderManagementBoard extends StatefulWidget {
  const OrderManagementBoard({
    super.key,
    required this.orders,
    required this.selectedOrder,
    required this.controller,
    required this.itemImagesById,
    required this.isMaster,
    required this.vendorId,
    required this.onSelectOrder,
    required this.onAcceptOrder,
    required this.onRejectOrder,
    required this.onShowAllOrders,
    required this.onRefreshOrders,
    this.isStore = false,
  });

  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final OrderController controller;
  final Map<int, String> itemImagesById;
  final bool isMaster;
  final int vendorId;
  final ValueChanged<OrderModel> onSelectOrder;
  final Future<void> Function(OrderModel order, int estimatedMinutes)
      onAcceptOrder;
  final Future<void> Function(OrderModel order, String reason) onRejectOrder;
  final VoidCallback onShowAllOrders;
  final Future<void> Function() onRefreshOrders;
  final bool isStore;

  @override
  State<OrderManagementBoard> createState() => _OrderManagementBoardState();
}

class _OrderManagementBoardState extends State<OrderManagementBoard> {
  final TextEditingController _manualPrepController =
      TextEditingController(text: '25');
  final TextEditingController _otherReasonController = TextEditingController();

  bool _useManualPrep = false;
  int _selectedPrepMinutes = 25;
  String _selectedReason = 'منتج غير متوفر';

  @override
  void dispose() {
    _manualPrepController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrder = widget.selectedOrder ??
        (widget.orders.isNotEmpty ? widget.orders.first : null);
    final queueOrders = widget.orders.take(5).toList(growable: false);

    if (selectedOrder == null || queueOrders.isEmpty) {
      return const DashboardEmptyState(
        title: 'لا توجد طلبات جديدة الآن',
        subtitle: 'سيظهر هنا أول طلب جديد أو مجدول بمجرد وصوله إلى المطعم.',
        icon: Icons.receipt_long_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 1180;
        final queuePanel = _buildQueuePanel(queueOrders, selectedOrder);
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
            Expanded(flex: 26, child: queuePanel),
            const SizedBox(width: 14),
            Expanded(flex: 44, child: detailsPanel),
            const SizedBox(width: 14),
            Expanded(flex: 30, child: actionsPanel),
          ],
        );
      },
    );
  }

  Widget _buildQueuePanel(List<OrderModel> queueOrders, OrderModel selected) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _QueueCountBubble(count: queueOrders.length),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'الطلبات الجديدة',
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
            'جديد',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (final order in queueOrders) ...[
            _QueueOrderCard(
              order: order,
              selected: selected.ordersId == order.ordersId,
              onTap: () => widget.onSelectOrder(order),
              displayMoney: _displayMoney,
              relativeTimeLabel: _relativeTimeLabel(order.orderDateTime),
              kindLabel: _orderKindLabel(order),
              kindIcon: _orderKindIcon(order),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onShowAllOrders,
              icon: const Icon(Icons.list_rounded),
              label: const Text('عرض كل الطلبات'),
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
          final extras = _collectExtras(items);
          final note = _firstNonEmpty([
            selected.ordersDeliveryNote,
            selected.ordersGiftMessage,
          ]);
          final rejectionReason = (selected.ordersRejectionReason ?? '').trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isStore) ...[
                DashboardPanel(
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: kPrimary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'طلب متجر — راجع المنتجات والكمية واللون والمقاس قبل التجهيز',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
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
                  const SizedBox(width: 8),
                  _MiniPill(
                    label:
                        '#${selected.ordersId ?? '-'} ${selected.lifecycleLabelAr}',
                    color: kPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FBF7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD9E8DC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: kPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'وصل طلب جديد وتم تفعيله، وهتظهر لك إشعاراته ومتابعة حالته فورًا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kPrimary.withValues(alpha: 0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.info_outline_rounded, color: kPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _BoardSectionHeader(
                title: 'نوع الطلب',
                icon: Icons.home_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OrderTypeTile(
                      label: 'استلام ذاتي',
                      icon: Icons.directions_walk_rounded,
                      active: selected.isPickup,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OrderTypeTile(
                      label: 'طلب مجدول',
                      icon: Icons.calendar_month_rounded,
                      active: selected.isScheduledOrder,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OrderTypeTile(
                      label: 'طلب عادي',
                      icon: Icons.home_rounded,
                      active: !selected.isPickup && !selected.isScheduledOrder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _BoardSectionHeader(
                title: 'الدفع',
                icon: Icons.payments_rounded,
              ),
              const SizedBox(height: 12),
              _InnerCard(
                child: _InfoRow(
                  label: 'طريقة الدفع',
                  value: selected.resolvedPaymentLabel,
                  icon: selected.resolvedPaymentKey == 'wallet'
                      ? Icons.account_balance_wallet_rounded
                      : Icons.payments_rounded,
                ),
              ),
              const SizedBox(height: 18),
              const _BoardSectionHeader(
                title: 'بيانات العميل',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _InnerCard(
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'الاسم الكامل',
                      value:
                          _safeText(selected.usersName, fallback: 'غير معروف'),
                      icon: Icons.person_rounded,
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      label: 'رقم الهاتف',
                      value: _safeText(selected.addressPhone,
                          fallback: 'غير متاح'),
                      icon: Icons.phone_rounded,
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      label: 'العنوان',
                      value: _detailAddress(selected),
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _BoardSectionHeader(
                title: 'المنتجات',
                icon: Icons.shopping_cart_outlined,
              ),
              const SizedBox(height: 12),
              _InnerCard(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(color: kPrimary),
                      )
                    : items.isEmpty
                        ? const DashboardEmptyState(
                            title: 'لا توجد منتجات بعد',
                            subtitle:
                                'ستظهر تفاصيل العناصر هنا بعد اكتمال تحميل الطلب.',
                            icon: Icons.shopping_bag_outlined,
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < items.length; i++) ...[
                                _OrderItemRow(
                                  item: items[i],
                                  imageName:
                                      widget.itemImagesById[items[i].itemId],
                                  displayMoney: _displayMoney,
                                  isStore: widget.isStore,
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
              _BoardSectionHeader(
                title: widget.isStore ? 'خصائص المنتجات' : 'الإضافات',
                icon: widget.isStore
                    ? Icons.tune_rounded
                    : Icons.add_circle_outline_rounded,
              ),
              const SizedBox(height: 12),
              _MutedCard(
                child: extras.isEmpty
                    ? Text(
                        widget.isStore ? 'بدون خصائص إضافية' : 'بدون إضافات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8B6A2B),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final extra in extras)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.brightness_1,
                                      size: 8, color: Color(0xFF8B6A2B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      extra,
                                      style: const TextStyle(
                                        color: Color(0xFF5E471B),
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              const _BoardSectionHeader(
                title: 'ملاحظات العميل',
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 12),
              _MutedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      note.isNotEmpty ? note : 'بدون ملاحظات',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B4E1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (rejectionReason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF5C6C6)),
                        ),
                        child: Text(
                          'سبب الرفض: $rejectionReason',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionsPanel(OrderModel selected) {
    final primaryLabel =
        selected.isScheduledOrder ? 'تأكيد الطلب' : 'قبول الطلب';
    const reasons = [
      'منتج غير متوفر',
      'ضغط عمل',
      'إغلاق المطعم',
      'سبب آخر',
    ];
    const minutesOptions = [10, 15, 20, 25, 30, 45];

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BoardSectionHeader(
            title: widget.isStore ? 'إجراءات المتجر' : 'إجراءات المطعم',
            icon: widget.isStore
                ? Icons.storefront_rounded
                : Icons.settings_suggest_rounded,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  widget.onAcceptOrder(selected, _resolvedPrepMinutes()),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(primaryLabel),
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
          const SizedBox(height: 14),
          Text(
            'حدد وقت القبول لإرسال إشعار:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _selectedPrepMinutes,
            items: minutesOptions
                .map(
                  (minutes) => DropdownMenuItem<int>(
                    value: minutes,
                    child: Text('$minutes دقيقة'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedPrepMinutes = value;
                _useManualPrep = false;
              });
            },
            decoration: InputDecoration(
              labelText: 'مدة التحضير المتوقعة',
              prefixIcon: const Icon(Icons.timer_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kPrimary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'خيارات:',
              style: TextStyle(
                color: kTextSecondary.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _prepChip(
                label: 'إدخال يدوي',
                active: _useManualPrep,
                icon: Icons.edit_outlined,
                onTap: () => setState(() => _useManualPrep = true),
              ),
              for (final minutes in minutesOptions)
                _prepChip(
                  label: '$minutes دقيقة',
                  active: !_useManualPrep && _selectedPrepMinutes == minutes,
                  onTap: () {
                    setState(() {
                      _selectedPrepMinutes = minutes;
                      _manualPrepController.text = minutes.toString();
                      _useManualPrep = false;
                    });
                  },
                ),
            ],
          ),
          if (_useManualPrep) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _manualPrepController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'اكتب مدة التحضير بالدقائق',
                prefixIcon: const Icon(Icons.schedule_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimary, width: 1.4),
                ),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed != null) {
                  _selectedPrepMinutes = parsed;
                }
              },
            ),
          ],
          const SizedBox(height: 18),
          _MutedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Color(0xFFD92D20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'رفض الطلب',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Color(0xFFD92D20),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'سبب الرفض (اختر سبب الرفض)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.95),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in reasons)
                      ChoiceChip(
                        selected: _selectedReason == reason,
                        label: Text(reason),
                        onSelected: (_) {
                          setState(() {
                            _selectedReason = reason;
                            if (reason != 'سبب آخر') {
                              _otherReasonController.clear();
                            }
                          });
                        },
                      ),
                  ],
                ),
                if (_selectedReason == 'سبب آخر') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otherReasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'اكتب سببًا آخر...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: kStroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: kStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFFD92D20), width: 1.4),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => widget.onRejectOrder(
                      selected,
                      _resolvedRejectionReason(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97373),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'رفض الطلب',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _BoardSectionHeader(
            title: 'سجل الأحداث',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 12),
          _InnerCard(
            child: Column(
              children: [
                _TimelineEntry(
                  title: 'تم إنشاء الطلب',
                  timeLabel: _relativeTimeLabel(selected.orderDateTime),
                  icon: Icons.add_task_rounded,
                  color: kPrimary,
                ),
                _TimelineEntry(
                  title: 'تم استلام الطلب في المطعم',
                  timeLabel: _relativeTimeLabel(
                    _parseDate(selected.acceptedAt),
                  ),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF059669),
                ),
                _TimelineEntry(
                  title: 'تم إرسال الطلب للسائق',
                  timeLabel: _relativeTimeLabel(
                    _parseDate(selected.assignedAt),
                  ),
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF2563EB),
                ),
                _TimelineEntry(
                  title: 'تم تسليم الطلب',
                  timeLabel: _relativeTimeLabel(
                    _parseDate(selected.deliveredAt),
                  ),
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prepChip({
    required String label,
    required bool active,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF3FAF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? kPrimary : kStroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: active ? kPrimary : kTextSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? kPrimary : kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _resolvedPrepMinutes() {
    if (_useManualPrep) {
      final parsed = int.tryParse(_manualPrepController.text.trim());
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return _selectedPrepMinutes > 0 ? _selectedPrepMinutes : 25;
  }

  String _resolvedRejectionReason() {
    if (_selectedReason == 'سبب آخر') {
      final custom = _otherReasonController.text.trim();
      if (custom.isNotEmpty) {
        return custom;
      }
    }
    return _selectedReason;
  }

  String _safeText(String? value, {required String fallback}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _detailAddress(OrderModel order) {
    final pieces = <String>[
      if ((order.addressStreet ?? '').trim().isNotEmpty)
        order.addressStreet!.trim(),
      if ((order.addressCity ?? '').trim().isNotEmpty)
        order.addressCity!.trim(),
    ];
    return pieces.isEmpty ? 'العنوان غير متاح' : pieces.join('، ');
  }

  List<String> _collectExtras(List<OrderItemDetail> items) {
    final extras = <String>[];
    for (final item in items) {
      final optionSummary = item.foodMenuOptionsSummary?.trim() ?? '';
      final note = item.foodItemNote?.trim() ?? '';
      if (optionSummary.isNotEmpty && !extras.contains(optionSummary)) {
        extras.add(optionSummary);
      }
      if (note.isNotEmpty && !extras.contains(note)) {
        extras.add(note);
      }
    }
    return extras;
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

  DateTime? _parseDate(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  String _relativeTimeLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return 'منذ لحظات';
    }

    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'منذ لحظات';
    }
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    }
    if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    }
    return 'منذ ${diff.inDays} يوم';
  }

  String _orderKindLabel(OrderModel order) {
    if (order.isPickup) {
      return 'استلام ذاتي';
    }
    if (order.isScheduledOrder) {
      return 'طلب مجدول';
    }
    return 'طلب عادي';
  }

  IconData _orderKindIcon(OrderModel order) {
    if (order.isPickup) {
      return Icons.directions_walk_rounded;
    }
    if (order.isScheduledOrder) {
      return Icons.calendar_month_rounded;
    }
    return Icons.home_rounded;
  }

  String _displayMoney(double value) {
    final formatted = value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$formatted SAR';
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

class _QueueCountBubble extends StatelessWidget {
  const _QueueCountBubble({required this.count});

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

class _QueueOrderCard extends StatelessWidget {
  const _QueueOrderCard({
    required this.order,
    required this.selected,
    required this.onTap,
    required this.displayMoney,
    required this.relativeTimeLabel,
    required this.kindLabel,
    required this.kindIcon,
  });

  final OrderModel order;
  final bool selected;
  final VoidCallback onTap;
  final String Function(double value) displayMoney;
  final String relativeTimeLabel;
  final String kindLabel;
  final IconData kindIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FAF5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kPrimary : kStroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected
                    ? kPrimary.withValues(alpha: 0.12)
                    : const Color(0xFFF6F8F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(kindIcon, color: kPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MiniPill(
                        label: order.lifecycleLabelAr,
                        color: selected ? kPrimary : const Color(0xFFB9D6C0),
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
                  const SizedBox(height: 8),
                  Text(
                    order.usersName?.trim().isNotEmpty == true
                        ? order.usersName!.trim()
                        : 'عميل غير معروف',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        displayMoney(order.totalPriceValue),
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        relativeTimeLabel,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kindLabel,
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _OrderTypeTile extends StatelessWidget {
  const _OrderTypeTile({
    required this.label,
    required this.icon,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF3FAF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? kPrimary : kStroke,
          width: active ? 1.3 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: active ? kPrimary : kTextSecondary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? kPrimary : kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPrimary, size: 20),
        const SizedBox(width: 12),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.imageName,
    required this.displayMoney,
    required this.isStore,
  });

  final OrderItemDetail item;
  final String? imageName;
  final String Function(double value) displayMoney;
  final bool isStore;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageName?.trim().isNotEmpty == true;
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
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
                    width: 54,
                    height: 54,
                    placeholderIcon: Icons.fastfood_outlined,
                  ),
                )
              : Icon(
                  isStore
                      ? Icons.shopping_bag_outlined
                      : Icons.fastfood_outlined,
                  color: kTextSecondary,
                ),
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
              if (isStore &&
                  (item.itemColor?.trim().isNotEmpty == true ||
                      item.itemSize?.trim().isNotEmpty == true ||
                      item.stockUnit?.trim().isNotEmpty == true)) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.itemColor?.trim().isNotEmpty == true)
                      'اللون: ${item.itemColor!.trim()}',
                    if (item.itemSize?.trim().isNotEmpty == true)
                      'المقاس: ${item.itemSize!.trim()}',
                    if (item.stockUnit?.trim().isNotEmpty == true)
                      'الوحدة: ${item.stockUnit!.trim()}',
                  ].join(' • '),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (!isStore &&
                  item.foodMenuOptionsSummary?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  item.foodMenuOptionsSummary!.trim(),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          displayMoney(item.lineTotal),
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

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.title,
    required this.timeLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String timeLabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
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
