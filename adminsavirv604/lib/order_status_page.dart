import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/model/admin_notification_model.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/model/restaurant_settings_model.dart';
import 'package:admin_tks/notifications_page.dart';
import 'package:admin_tks/remote/admin_notifications_data.dart';
import 'package:admin_tks/remote/restaurant_settings_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({
    super.key,
    this.sidebarItems,
    this.activeSidebarIndex,
  });

  final List<Map<String, dynamic>>? sidebarItems;
  final int? activeSidebarIndex;

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final TextEditingController _searchController = TextEditingController();
  final AdminNotificationsData _notificationsData = AdminNotificationsData();
  final RestaurantSettingsData _settingsData = RestaurantSettingsData();

  AdminNotificationSummary? _notificationSummary;
  RestaurantSettingsSnapshot? _settings;
  bool _metaLoading = true;
  String _selectedStatusFilter = 'all';
  String _selectedTypeFilter = 'all';
  final Set<int> _busyOrderIds = <int>{};

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  OrderController get _orderController => Get.isRegistered<OrderController>()
      ? Get.find<OrderController>()
      : Get.put(OrderController(), permanent: true);

  @override
  void initState() {
    super.initState();
    _orderController.fetchOrders(
      scope: 'active',
      forceRefresh: false,
    );
    _loadMeta();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _metaLoading = true);
    try {
      final results = await Future.wait([
        _settingsData.getSettings(),
        _notificationsData.getAll(),
      ]);

      if (!mounted) return;
      setState(() {
        _settings = results[0] as RestaurantSettingsSnapshot?;
        _notificationSummary =
            (results[1] as AdminNotificationResponse?)?.summary;
        _metaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _metaLoading = false);
    }
  }

  List<OrderModel> _visibleOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = orders.where((order) {
      if (order.isCancelledOrder || order.isDeliveredOrder) {
        return false;
      }

      if (order.isScheduledOrder) {
        return false;
      }

      final matchesStatus = _selectedStatusFilter == 'all' ||
          _orderBucket(order) == _selectedStatusFilter;
      final matchesType = _matchesTypeFilter(order);

      final haystack = [
        order.ordersId?.toString() ?? '',
        order.usersName ?? '',
        order.usersEmail ?? '',
        order.addressPhone ?? '',
        order.addressCity ?? '',
        order.addressStreet ?? '',
        order.ordersGiftMessage ?? '',
        order.ordersDeliveryNote ?? '',
        order.deliveryCode ?? '',
        order.driverName ?? '',
      ].join(' ').toLowerCase();

      return matchesStatus &&
          matchesType &&
          (query.isEmpty || haystack.contains(query));
    }).toList();

    filtered.sort(_compareOrders);
    return filtered;
  }

  bool _matchesTypeFilter(OrderModel order) {
    switch (_selectedTypeFilter) {
      case 'delivery':
        return !order.isPickup;
      case 'pickup':
        return order.isPickup;
      default:
        return true;
    }
  }

  String _orderBucket(OrderModel order) {
    final status = order.flowStatusKey;
    final vendorStatus = (order.ordersStatus ?? '').trim().toLowerCase();

    if (order.isCancelledOrder || order.isDeliveredOrder) {
      return 'hidden';
    }

    if (status == 'arrived_at_restaurant') {
      return 'ready';
    }

    if (_lateMinutes(order) > 0) {
      return 'late';
    }

    if (vendorStatus == 'paid' ||
        const {'assigned', 'accepted', 'preparing'}.contains(status)) {
      return 'preparing';
    }

    return 'new';
  }

  int _lateMinutes(OrderModel order) {
    final baseTime = order.scheduledDateTime ?? order.orderDateTime;
    final estimated = order.ordersEstimatedMinutes ?? 0;
    if (baseTime == null || estimated <= 0) {
      return 0;
    }

    final dueAt = baseTime.add(Duration(minutes: estimated));
    final diff = DateTime.now().difference(dueAt).inMinutes;
    return diff > 0 ? diff : 0;
  }

  int _compareOrders(OrderModel a, OrderModel b) {
    final bucketA = _orderBucket(a);
    final bucketB = _orderBucket(b);
    if (bucketA == 'late' && bucketB == 'late') {
      final lateA = _lateMinutes(a);
      final lateB = _lateMinutes(b);
      if (lateA != lateB) {
        return lateB.compareTo(lateA);
      }
    }

    final aTime = a.orderDateTime ?? a.scheduledDateTime;
    final bTime = b.orderDateTime ?? b.scheduledDateTime;
    if (aTime != null && bTime != null) {
      final compare = bTime.compareTo(aTime);
      if (compare != 0) return compare;
    } else if (aTime != null) {
      return -1;
    } else if (bTime != null) {
      return 1;
    }

    return (b.ordersId ?? 0).compareTo(a.ordersId ?? 0);
  }

  Map<String, List<OrderModel>> _groupOrders(List<OrderModel> orders) {
    final groups = <String, List<OrderModel>>{
      'new': <OrderModel>[],
      'preparing': <OrderModel>[],
      'ready': <OrderModel>[],
      'late': <OrderModel>[],
    };

    for (final order in orders) {
      final bucket = _orderBucket(order);
      final list = groups[bucket];
      if (list == null) {
        continue;
      }
      list.add(order);
    }

    for (final list in groups.values) {
      list.sort(_compareOrders);
    }

    return groups;
  }

  String _clockLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return '--:--';
    }

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $suffix';
  }

  String _moneyLabel(double value) => value.toStringAsFixed(0);

  IconData _orderTypeIcon(OrderModel order) {
    if (order.isPickup) {
      return Icons.directions_walk_rounded;
    }
    if (order.isScheduledOrder) {
      return Icons.calendar_month_rounded;
    }
    return Icons.home_rounded;
  }

  String _orderTypeLabel(OrderModel order) {
    if (order.isPickup) {
      return 'استلام';
    }
    if (order.isScheduledOrder) {
      return 'مجدول';
    }
    return 'توصيل';
  }

  Future<void> _markReady(OrderModel order) async {
    final orderId = order.ordersId ?? 0;
    final vendorId = order.vendorId ?? _auth.vendorId;
    if (orderId <= 0 || vendorId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد بيانات الطلب')),
      );
      return;
    }

    setState(() => _busyOrderIds.add(orderId));
    try {
      await _orderController.updateOrderFlowStatus(
        orderId,
        vendorId,
        'arrived_at_restaurant',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الطلب بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث حالة الطلب: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _openOrderDetails(
    OrderModel order,
    _StatusBucketConfig config,
  ) async {
    final statusLabel = _statusChipLabel(order, config);
    final itemsCount = order.ordersItemsCount ?? 0;
    final totalPrice = _moneyLabel(order.totalPriceValue);
    final timeLabel =
        _clockLabel(order.orderDateTime ?? order.scheduledDateTime);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kStroke),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(config.icon, color: config.tint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تفاصيل الطلب #${order.ordersId ?? '-'}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SmallBadge(
                        label: statusLabel,
                        tint: config.tint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    label: 'اسم العميل',
                    value: order.usersName ?? '-',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'رقم الهاتف',
                    value: order.addressPhone ?? '-',
                    icon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'العنوان',
                    value: _fullAddress(order),
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'وقت الطلب',
                    value: timeLabel,
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'الأصناف',
                    value: '$itemsCount أصناف',
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'إجمالي الطلب',
                    value: '$totalPrice SAR',
                    icon: Icons.payments_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'طريقة الدفع',
                    value: order.resolvedPaymentLabel,
                    icon: order.resolvedPaymentKey == 'wallet'
                        ? Icons.account_balance_wallet_rounded
                        : Icons.payments_rounded,
                  ),
                  const SizedBox(height: 18),
                  if (config.key == 'preparing')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busyOrderIds.contains(order.ordersId ?? 0)
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await _markReady(order);
                              },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('تم التحضير'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: config.tint,
                          side: BorderSide(color: config.tint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  if (config.key == 'preparing') const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('إغلاق'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: kTextPrimary,
                        side: const BorderSide(color: kStroke),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fullAddress(OrderModel order) {
    final parts = <String>[
      if ((order.addressStreet ?? '').trim().isNotEmpty)
        order.addressStreet!.trim(),
      if ((order.addressCity ?? '').trim().isNotEmpty)
        order.addressCity!.trim(),
    ];

    if (parts.isEmpty) {
      return 'العنوان غير متاح';
    }

    return parts.join('، ');
  }

  String _statusChipLabel(OrderModel order, _StatusBucketConfig config) {
    if (config.key == 'late') {
      return 'متأخر ${_lateMinutes(order)} دقيقة';
    }
    if (config.key == 'ready') {
      return 'جاهز للاستلام';
    }
    if (config.key == 'preparing') {
      return 'قيد التحضير';
    }
    return 'طلب جديد';
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kStroke),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تصفية الطلبات',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _FilterOption(
                  label: 'كل الطلبات',
                  icon: Icons.grid_view_rounded,
                  selected: _selectedTypeFilter == 'all',
                  onTap: () {
                    setState(() => _selectedTypeFilter = 'all');
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 10),
                _FilterOption(
                  label: 'طلبات التوصيل',
                  icon: Icons.delivery_dining_rounded,
                  selected: _selectedTypeFilter == 'delivery',
                  onTap: () {
                    setState(() => _selectedTypeFilter = 'delivery');
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 10),
                _FilterOption(
                  label: 'طلبات الاستلام',
                  icon: Icons.directions_walk_rounded,
                  selected: _selectedTypeFilter == 'pickup',
                  onTap: () {
                    setState(() => _selectedTypeFilter = 'pickup');
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTypeFilter = 'all';
                      _selectedStatusFilter = 'all';
                    });
                    Navigator.of(sheetContext).pop();
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('إعادة ضبط التصفية'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: kTextPrimary,
                    side: const BorderSide(color: kStroke),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTopStats(Map<String, List<OrderModel>> groups) {
    return [
      DashboardStatCard(
        label: 'طلبات جديدة',
        subtitle: 'عدد الطلبات الجديدة',
        value: '${groups['new']?.length ?? 0} طلب',
        icon: Icons.add_shopping_cart_rounded,
        tint: const Color(0xFF1B7A3A),
        width: 240,
      ),
      DashboardStatCard(
        label: 'قيد التحضير',
        subtitle: 'عدد الطلبات قيد التحضير',
        value: '${groups['preparing']?.length ?? 0} طلب',
        icon: Icons.lunch_dining_rounded,
        tint: const Color(0xFFF59E0B),
        width: 240,
      ),
      DashboardStatCard(
        label: 'جاهزة للاستلام',
        subtitle: 'عدد الطلبات الجاهزة للاستلام',
        value: '${groups['ready']?.length ?? 0} طلب',
        icon: Icons.shopping_bag_outlined,
        tint: const Color(0xFF2563EB),
        width: 240,
      ),
      DashboardStatCard(
        label: 'متأخر عن وقت التحضير',
        subtitle: 'عدد الطلبات المتأخرة',
        value: '${groups['late']?.length ?? 0} طلب',
        icon: Icons.watch_later_outlined,
        tint: const Color(0xFFEF4444),
        width: 240,
      ),
    ];
  }

  Widget _buildBody(Map<String, List<OrderModel>> groups) {
    final configs = [
      _bucketConfig('new'),
      _bucketConfig('preparing'),
      _bucketConfig('ready'),
      _bucketConfig('late'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 1180;
        const columnSpacing = 14.0;
        final columnWidth = (constraints.maxWidth - (columnSpacing * 3)) / 4;
        final columns = configs
            .map(
              (config) => _buildStatusColumn(
                config,
                groups[config.key] ?? const <OrderModel>[],
                maxVisibleOrders: constraints.maxWidth < 880 ? 20 : 50,
              ),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilterRow(),
            const SizedBox(height: 16),
            if (_orderController.isLoading.value &&
                _visibleOrders(_orderController.orders).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              )
            else if (groups.values.every((list) => list.isEmpty))
              const DashboardEmptyState(
                title: 'لا توجد طلبات مطابقة',
                subtitle: 'جرّب تعديل البحث أو الفلاتر لعرض طلبات أخرى.',
                icon: Icons.receipt_long_rounded,
              )
            else if (isStacked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns.length; i++) ...[
                    columns[i],
                    if (i != columns.length - 1) const SizedBox(height: 14),
                  ],
                ],
              )
            else
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: columnSpacing,
                runSpacing: columnSpacing,
                children: [
                  for (final column in columns)
                    SizedBox(
                      width: columnWidth,
                      child: column,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    const statusItems = [
      DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
      DropdownMenuItem(value: 'new', child: Text('طلبات جديدة')),
      DropdownMenuItem(value: 'preparing', child: Text('قيد التحضير')),
      DropdownMenuItem(value: 'ready', child: Text('جاهزة للاستلام')),
      DropdownMenuItem(value: 'late', child: Text('متأخرة')),
    ];

    final searchField = TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: 'ابحث برقم الطلب أو اسم العميل...',
        hintStyle: const TextStyle(color: kTextSecondary),
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: kSurface,
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
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );

    final statusDropdown = DropdownButtonFormField<String>(
      initialValue: _selectedStatusFilter,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedStatusFilter = value);
      },
      items: statusItems,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: kSurface,
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
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );

    final filterButton = OutlinedButton.icon(
      onPressed: _openFilterSheet,
      icon: const Icon(Icons.filter_alt_outlined),
      label: const Text('تصفية الطلبات'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: kTextPrimary,
        side: const BorderSide(color: kStroke),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        const dropdownWidth = 220.0;
        const buttonWidth = 180.0;
        final searchWidth =
            constraints.maxWidth - dropdownWidth - buttonWidth - (gap * 2);

        if (constraints.maxWidth < 980 || searchWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              statusDropdown,
              const SizedBox(height: 12),
              filterButton,
            ],
          );
        }

        return Row(
          textDirection: TextDirection.rtl,
          children: [
            SizedBox(width: searchWidth, child: searchField),
            const SizedBox(width: gap),
            SizedBox(width: dropdownWidth, child: statusDropdown),
            const SizedBox(width: gap),
            SizedBox(width: buttonWidth, child: filterButton),
          ],
        );
      },
    );
  }

  Widget _buildStatusColumn(_StatusBucketConfig config, List<OrderModel> orders,
      {required int maxVisibleOrders}) {
    final visibleOrders = orders.take(maxVisibleOrders).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.tint.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.tint.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(config.icon, color: config.tint, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      config.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      config.subtitle,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CountBubble(
                label: '${orders.length}',
                tint: config.tint,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text(
                    config.emptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    config.emptySubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < visibleOrders.length; index++) ...[
                  _buildOrderCard(visibleOrders[index], config),
                  if (index != visibleOrders.length - 1)
                    const SizedBox(height: 12),
                ],
                if (visibleOrders.length < orders.length) ...[
                  const SizedBox(height: 10),
                  Text(
                    'يتم عرض ${visibleOrders.length} من ${orders.length} طلب نشط',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.offNamed(
                  DashboardRoutes.orders,
                  arguments: {
                    'sidebarIndex': 1,
                    'shellTitle': 'إدارة الطلبات',
                    'shellSubtitle':
                        'عرض الطلبات الجديدة والجارية والمكتملة من مكان واحد.',
                    'initialBucket': 'all',
                  },
                  preventDuplicates: false,
                );
              },
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('عرض جميع الطلبات'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: kTextPrimary,
                side: const BorderSide(color: kStroke),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, _StatusBucketConfig config) {
    final orderId = order.ordersId ?? 0;
    final bucket = _orderBucket(order);
    final isLate = bucket == 'late';
    final isReady = bucket == 'ready';
    final isPreparing = bucket == 'preparing';
    final lateMinutes = _lateMinutes(order);
    final statusLabel = _statusChipLabel(order, config);
    final totalPrice = _moneyLabel(order.totalPriceValue);
    final itemsCount = order.ordersItemsCount ?? 0;
    final paymentLabel = order.resolvedPaymentLabel;
    final paymentIcon = order.resolvedPaymentKey == 'wallet'
        ? Icons.account_balance_wallet_rounded
        : Icons.payments_rounded;
    final timeLabel =
        _clockLabel(order.orderDateTime ?? order.scheduledDateTime);
    final typeLabel = _orderTypeLabel(order);
    final typeIcon = _orderTypeIcon(order);
    final busy = _busyOrderIds.contains(orderId);

    final cardTint = isLate
        ? const Color(0xFFEF4444)
        : isReady
            ? const Color(0xFF2563EB)
            : isPreparing
                ? const Color(0xFFF59E0B)
                : const Color(0xFF1B7A3A);

    final actionLabel = isPreparing ? 'تم التحضير' : 'عرض التفاصيل';
    final actionTint = isPreparing
        ? const Color(0xFF2563EB)
        : isLate
            ? const Color(0xFFEF4444)
            : isReady
                ? const Color(0xFF2563EB)
                : const Color(0xFF1B7A3A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardTint.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                '#${order.ordersId ?? '-'}',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: kTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cardTint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(typeIcon, color: cardTint, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.usersName ?? '-',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemsCount أصناف • $totalPrice SAR',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: cardTint,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cardTint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  isLate ? Icons.error_outline_rounded : config.icon,
                  size: 18,
                  color: cardTint,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cardTint,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kStroke),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(paymentIcon, size: 18, color: kTextSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    paymentLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLate) ...[
            const SizedBox(height: 8),
            Text(
              'متأخر $lateMinutes دقيقة',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (isPreparing) {
                        await _markReady(order);
                      } else {
                        await _openOrderDetails(order, config);
                      }
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: actionTint,
                side: BorderSide(color: actionTint.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: busy && isPreparing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: actionTint,
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusBucketConfig _bucketConfig(String key) {
    return _statusBucketConfigs.firstWhere((config) => config.key == key);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = _visibleOrders(_orderController.orders);
      final groups = _groupOrders(orders);

      return DashboardPageShell(
        title: 'حالات الطلب',
        subtitle: 'متابعة جميع الطلبات حسب حالتها',
        icon: Icons.layers_rounded,
        activeSidebarIndex: widget.activeSidebarIndex,
        sidebarItems: widget.sidebarItems,
        actions: [
          _NotificationActionButton(
            count: _notificationSummary?.unreadCount ?? 0,
            onPressed: () => Get.to(() => const NotificationsPage()),
          ),
        ],
        onRefreshPressed: () {
          _orderController.fetchOrders();
          _loadMeta();
        },
        statusLabel: _metaLoading
            ? 'جارٍ تحميل بيانات المطعم'
            : (_settings?.isOpen == true
                ? 'المطعم مفتوح الآن'
                : 'المطعم مغلق الآن'),
        statusTint: _metaLoading
            ? kPrimary
            : (_settings?.isOpen == true
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444)),
        profileAvatarUrl: _settings?.vendorLogo,
        profileSubtitle: _settings?.vendorDescription?.trim().isNotEmpty == true
            ? _settings!.vendorDescription!.trim()
            : null,
        stats: _buildTopStats(groups),
        body: _buildBody(groups),
      );
    });
  }
}

class _StatusBucketConfig {
  const _StatusBucketConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.tint,
    required this.icon,
  });

  final String key;
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final Color tint;
  final IconData icon;
}

const List<_StatusBucketConfig> _statusBucketConfigs = [
  _StatusBucketConfig(
    key: 'late',
    title: 'متأخر عن وقت التحضير',
    subtitle: 'الطلبات التي تجاوزت الوقت المحدد',
    emptyTitle: 'لا توجد طلبات متأخرة',
    emptySubtitle: 'ستظهر الطلبات هنا عند تجاوز وقت التحضير.',
    tint: Color(0xFFEF4444),
    icon: Icons.watch_later_outlined,
  ),
  _StatusBucketConfig(
    key: 'ready',
    title: 'جاهزة للاستلام',
    subtitle: 'الطلبات الجاهزة بانتظار السائق',
    emptyTitle: 'لا توجد طلبات جاهزة الآن',
    emptySubtitle: 'ستظهر هنا الطلبات الجاهزة للاستلام.',
    tint: Color(0xFF2563EB),
    icon: Icons.shopping_bag_outlined,
  ),
  _StatusBucketConfig(
    key: 'preparing',
    title: 'قيد التحضير',
    subtitle: 'الطلبات التي ما زالت في المطبخ',
    emptyTitle: 'لا توجد طلبات قيد التحضير',
    emptySubtitle: 'الطلبات التي يتم تجهيزها ستظهر هنا.',
    tint: Color(0xFFF59E0B),
    icon: Icons.lunch_dining_rounded,
  ),
  _StatusBucketConfig(
    key: 'new',
    title: 'طلبات جديدة',
    subtitle: 'الطلبات الواردة حديثًا',
    emptyTitle: 'لا توجد طلبات جديدة الآن',
    emptySubtitle: 'الطلبات الجديدة ستظهر هنا فور وصولها.',
    tint: Color(0xFF1B7A3A),
    icon: Icons.add_shopping_cart_rounded,
  ),
];

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kStroke),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'الإشعارات',
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
          if (count > 0)
            Positioned(
              top: 7,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: kPrimary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
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
    final tint = selected ? kPrimary : kTextSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? kPrimary.withValues(alpha: 0.08)
                : const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? kPrimary : kStroke,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: tint,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
