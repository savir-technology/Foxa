// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:math';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/model/admin_notification_model.dart';
import 'package:admin_tks/model/driver_dispatch_model.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/model/restaurant_settings_model.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/remote/printing_data.dart';
import 'package:admin_tks/order_chat_card.dart';
import 'package:admin_tks/notifications_page.dart';
import 'package:admin_tks/remote/admin_notifications_data.dart';
import 'package:admin_tks/remote/restaurant_settings_data.dart';
import 'package:admin_tks/services/order_slip_pdf_service.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:admin_tks/widgets/order_management_board.dart';
import 'package:admin_tks/widgets/scheduled_orders_board.dart';
import 'package:admin_tks/core/services/mapbox_runtime_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class DispatchLocation {
  const DispatchLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum _OrderActionMode {
  accept,
  reject,
  confirmScheduled,
  adjustScheduled,
  cancelScheduled,
  generic,
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final OrderController orderController =
      Get.put(OrderController(), permanent: true);
  final TextEditingController searchController = TextEditingController();
  final ItemsData _itemsData = ItemsData();
  final PrintingData _printingData = PrintingData();
  final RestaurantSettingsData _settingsData = RestaurantSettingsData();
  final AdminNotificationsData _notificationsData = AdminNotificationsData();
  final OrderSlipPdfService _slipPdfService = const OrderSlipPdfService();
  String selectedBucket = 'all';
  String selectedScheduledWindow = 'all';
  bool _showAllOrders = false;
  int _visibleClassicOrders = 30;
  int? _selectedOrderId;
  Map<int, String> _itemImagesById = const {};
  RestaurantSettingsSnapshot? _restaurantSettings;
  AdminNotificationSummary? _notificationSummary;
  String? _lastRouteSyncSignature;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  Map<String, dynamic> _routeArgsMap() {
    final routeArgs = Get.arguments;
    if (routeArgs is Map) {
      return Map<String, dynamic>.from(routeArgs);
    }
    return const <String, dynamic>{};
  }

  int? _resolveSidebarIndex(Map<String, dynamic> routeArgs) {
    final rawValue = routeArgs['sidebarIndex'];
    if (rawValue is int) return rawValue;
    return int.tryParse(rawValue?.toString() ?? '');
  }

  String _resolveInitialBucket(Map<String, dynamic> routeArgs) {
    final explicitBucket = routeArgs['initialBucket']?.toString().trim() ?? '';
    if (explicitBucket.isNotEmpty) {
      return explicitBucket;
    }

    switch (_resolveSidebarIndex(routeArgs)) {
      case 2:
        return 'scheduled';
      case 3:
        return 'all';
      default:
        return 'all';
    }
  }

  String _resolveShellTitle(Map<String, dynamic> routeArgs) {
    final explicitTitle = routeArgs['shellTitle']?.toString().trim() ?? '';
    if (explicitTitle.isNotEmpty) {
      return explicitTitle;
    }

    switch (_resolveSidebarIndex(routeArgs)) {
      case 2:
        return 'الطلبات المجدولة';
      case 3:
        return 'حالات الطلب';
      default:
        return 'إدارة الطلبات';
    }
  }

  String _resolveShellSubtitle(Map<String, dynamic> routeArgs) {
    final explicitSubtitle =
        routeArgs['shellSubtitle']?.toString().trim() ?? '';
    if (explicitSubtitle.isNotEmpty) {
      return explicitSubtitle;
    }

    switch (_resolveSidebarIndex(routeArgs)) {
      case 2:
        return 'استعرض الطلبات المجدولة فقط مع متابعة تنفيذها.';
      case 3:
        return 'استعرض الطلبات حسب حالتها وحدّث الحالة مباشرة.';
      default:
        return _auth.isMaster
            ? 'عرض شامل لكل طلبات المتجر مع إجراءات الإدارة والمتابعة'
            : 'عرض مخصص لطلبات متجرك مع التتبع والإجراءات السريعة';
    }
  }

  String _buildRouteSyncSignature(Map<String, dynamic> routeArgs) {
    final sidebarIndex = _resolveSidebarIndex(routeArgs)?.toString() ?? '';
    final shellTitle = routeArgs['shellTitle']?.toString().trim() ?? '';
    final shellSubtitle = routeArgs['shellSubtitle']?.toString().trim() ?? '';
    final bucket = _resolveInitialBucket(routeArgs);
    return '$sidebarIndex|$shellTitle|$shellSubtitle|$bucket';
  }

  @override
  void initState() {
    super.initState();
    final routeArgs = _routeArgsMap();
    selectedBucket = _resolveInitialBucket(routeArgs);
    orderController.fetchOrders(
      scope: selectedBucket == 'scheduled' ? 'scheduled' : 'all',
      forceRefresh: false,
    );
    _lastRouteSyncSignature = _buildRouteSyncSignature(routeArgs);
    _loadItemImages();
    _loadRestaurantSettings();
    _loadNotificationsSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs = _routeArgsMap();
    final nextSignature = _buildRouteSyncSignature(routeArgs);
    if (_lastRouteSyncSignature == nextSignature) {
      return;
    }

    _lastRouteSyncSignature = nextSignature;
    final nextBucket = _resolveInitialBucket(routeArgs);
    if (selectedBucket != nextBucket) {
      setState(() => selectedBucket = nextBucket);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItemImages() async {
    try {
      final items = await _itemsData.getItems();
      if (!mounted || items == null) return;
      final mapped = <int, String>{};
      for (final ItemsModel item in items) {
        final id = int.tryParse(item.itemsId ?? '');
        final imageName = item.itemsImage?.trim() ?? '';
        if (id != null && imageName.isNotEmpty) {
          mapped[id] = imageName;
        }
      }
      setState(() => _itemImagesById = mapped);
    } catch (_) {}
  }

  Future<void> _loadRestaurantSettings() async {
    try {
      final snapshot = await _settingsData.getSettings();
      if (!mounted || snapshot == null) return;
      setState(() => _restaurantSettings = snapshot);
    } catch (_) {}
  }

  Future<void> _loadNotificationsSummary() async {
    try {
      final response = await _notificationsData.getAll();
      if (!mounted) return;
      setState(() => _notificationSummary = response?.summary);
    } catch (_) {}
  }

  OrderModel? _selectedOrderFrom(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return null;
    }

    if (_selectedOrderId != null) {
      for (final order in orders) {
        if (order.ordersId == _selectedOrderId) {
          return order;
        }
      }
    }

    return orders.first;
  }

  List<OrderModel> _boardOrders(List<OrderModel> orders) {
    final queue = orders
        .where((order) =>
            order.lifecycleBucket == 'new' ||
            order.lifecycleBucket == 'scheduled')
        .toList();
    queue.sort((a, b) => (b.ordersId ?? 0).compareTo(a.ordersId ?? 0));
    return queue;
  }

  List<OrderModel> _scheduledBoardOrders(List<OrderModel> orders) {
    final scheduled =
        orders.where((order) => order.lifecycleBucket == 'scheduled').toList();
    scheduled.sort((a, b) {
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
    return scheduled;
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

  String _detailAddress(OrderModel order) {
    final pieces = <String>[
      if ((order.addressStreet ?? '').trim().isNotEmpty)
        order.addressStreet!.trim(),
      if ((order.addressCity ?? '').trim().isNotEmpty)
        order.addressCity!.trim(),
    ];

    if (pieces.isEmpty) {
      return 'العنوان غير متاح';
    }

    return pieces.join('، ');
  }

  Future<void> _acceptSelectedOrder(
    OrderModel order,
    int estimatedMinutes,
  ) async {
    if (estimatedMinutes <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مدة تحضير صحيحة')),
      );
      return;
    }

    final success = await _updateOrderStatusWithFeedback(
      order,
      status: 'paid',
      estimatedMinutes: estimatedMinutes,
      successMessage: 'تم قبول الطلب بنجاح',
    );
    if (success && (order.deliveryId ?? 0) <= 0 && mounted) {
      await _showDriverSelectionBottomSheet(order);
    }
  }

  Future<void> _rejectSelectedOrder(
    OrderModel order,
    String reason,
  ) async {
    final customReason = reason.trim();
    if (customReason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب سببًا واضحًا للرفض')),
      );
      return;
    }

    await _updateOrderStatusWithFeedback(
      order,
      status: 'failed',
      reason: customReason,
      successMessage: 'تم رفض الطلب بنجاح',
      errorPrefix: 'تعذر تحديث حالة الطلب',
    );
  }

  Future<void> _confirmScheduledOrder(
    OrderModel order,
    int estimatedMinutes,
  ) async {
    if (estimatedMinutes <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مدة تحضير صحيحة')),
      );
      return;
    }

    await _updateOrderStatusWithFeedback(
      order,
      status: 'paid',
      estimatedMinutes: estimatedMinutes,
      successMessage: 'تم تأكيد الطلب المجدول بنجاح',
      errorPrefix: 'تعذر تأكيد الطلب المجدول',
    );
  }

  Future<void> _adjustScheduledOrder(
    OrderModel order,
    int estimatedMinutes,
  ) async {
    if (estimatedMinutes <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مدة تحضير صحيحة')),
      );
      return;
    }

    await _updateOrderStatusWithFeedback(
      order,
      status: 'paid',
      estimatedMinutes: estimatedMinutes,
      successMessage: 'تم تعديل جاهزية الطلب المجدول',
      errorPrefix: 'تعذر تعديل جاهزية الطلب المجدول',
    );
  }

  Future<void> _cancelScheduledOrder(
    OrderModel order,
    String reason,
  ) async {
    final customReason = reason.trim();
    if (customReason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب سببًا واضحًا للإلغاء')),
      );
      return;
    }

    await _updateOrderStatusWithFeedback(
      order,
      status: 'canceled',
      reason: customReason,
      successMessage: 'تم إلغاء الطلب المجدول بنجاح',
      errorPrefix: 'تعذر إلغاء الطلب المجدول',
    );
  }

  bool _isPendingOrder(OrderModel order) {
    final status = (order.ordersStatus ?? '').trim().toLowerCase();
    return order.lifecycleBucket == 'new' ||
        (status == 'pending' && order.lifecycleBucket != 'scheduled');
  }

  bool _isScheduledOrder(OrderModel order) =>
      order.lifecycleBucket == 'scheduled';

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesScheduledWindow(OrderModel order) {
    if (selectedBucket != 'scheduled' || selectedScheduledWindow == 'all') {
      return true;
    }

    final scheduledAt = order.scheduledDateTime;
    if (scheduledAt == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.add(const Duration(days: 2));
    final weekEnd = today.add(const Duration(days: 8));

    switch (selectedScheduledWindow) {
      case 'today':
        return _sameCalendarDay(scheduledAt, today);
      case 'tomorrow':
        return _sameCalendarDay(scheduledAt, tomorrow);
      case 'week':
        return !scheduledAt.isBefore(weekStart) &&
            scheduledAt.isBefore(weekEnd);
      default:
        return true;
    }
  }

  Future<bool> _updateOrderStatusWithFeedback(
    OrderModel order, {
    required String status,
    int? estimatedMinutes,
    String? reason,
    required String successMessage,
    String? errorPrefix,
  }) async {
    final orderId = order.ordersId ?? 0;
    final vendorId = order.vendorId ?? _auth.vendorId;
    if (orderId <= 0 || vendorId <= 0) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد بيانات الطلب')),
      );
      return false;
    }

    try {
      await orderController.updateOrderStatus(
        orderId,
        vendorId,
        status,
        estimatedMinutes: estimatedMinutes,
        reason: reason,
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      setState(() {});
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${errorPrefix ?? 'تعذر تحديث حالة الطلب'}: $e',
          ),
        ),
      );
      return false;
    }
  }

  Widget _buildClassicOrdersBody() {
    final allFilteredOrders = _filteredOrders;
    final isCompact = MediaQuery.sizeOf(context).width < 880;
    final visibleOrders = isCompact
        ? allFilteredOrders.take(_visibleClassicOrders).toList(growable: false)
        : allFilteredOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrdersQuickStats(orders: orderController.orders),
        const SizedBox(height: 16),
        _OrdersFilters(
          controller: searchController,
          selectedStatus: selectedBucket,
          selectedScheduledWindow: selectedScheduledWindow,
          onSearchChanged: (_) => setState(() {
            _visibleClassicOrders = 30;
          }),
          onStatusChanged: (value) {
            setState(() {
              selectedBucket = value;
              _visibleClassicOrders = 30;
              if (value != 'scheduled') {
                selectedScheduledWindow = 'all';
              }
            });
          },
          onScheduledWindowChanged: (value) {
            setState(() {
              selectedScheduledWindow = value;
              _visibleClassicOrders = 30;
            });
          },
        ),
        const SizedBox(height: 16),
        if (orderController.isLoading.value)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: CircularProgressIndicator(color: kPrimary),
            ),
          )
        else if (allFilteredOrders.isEmpty)
          const _EmptyOrdersState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _OrderCard(
              order: visibleOrders[index],
              isMaster: _auth.isMaster,
              controller: orderController,
              itemImagesById: _itemImagesById,
              onDelete: _showDeleteConfirmationDialog,
              onAction: _handleOrderAction,
              onAssignDriver: _showDriverSelectionBottomSheet,
              onChatOrder: _showOrderChatSheet,
              onCallDriver: _callDriverFromOrder,
              onPrintSlip: _showPrintOptions,
              onShowPickupQr: _showPickupQrDialog,
            ),
          ),
        if (isCompact && visibleOrders.length < allFilteredOrders.length) ...[
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _visibleClassicOrders += 30;
              }),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                'تحميل المزيد (${allFilteredOrders.length - visibleOrders.length})',
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<OrderModel> get _filteredOrders {
    final query = searchController.text.trim().toLowerCase();
    final filtered = orderController.orders.where((order) {
      final matchesBucket =
          selectedBucket == 'all' || order.lifecycleBucket == selectedBucket;
      final matchesScheduledWindow = _matchesScheduledWindow(order);

      final haystack = [
        order.ordersId?.toString() ?? '',
        order.usersName ?? '',
        order.usersEmail ?? '',
        order.addressPhone ?? '',
        order.addressCity ?? '',
        order.ordersGiftMessage ?? '',
        order.ordersDeliveryNote ?? '',
        order.deliveryCode ?? '',
      ].join(' ').toLowerCase();

      return matchesBucket &&
          matchesScheduledWindow &&
          (query.isEmpty || haystack.contains(query));
    }).toList();

    filtered.sort((a, b) {
      if (selectedBucket == 'scheduled') {
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
      }
      return (b.ordersId ?? 0).compareTo(a.ordersId ?? 0);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = _routeArgsMap();
    return Obx(() {
      final boardOrders = _boardOrders(orderController.orders);
      final scheduledBoardOrders =
          _scheduledBoardOrders(orderController.orders);
      final primaryBoardOrders =
          selectedBucket == 'scheduled' ? scheduledBoardOrders : boardOrders;
      final selectedOrder = _selectedOrderFrom(primaryBoardOrders);

      return LayoutBuilder(
        builder: (context, constraints) {
          final wideLayout = constraints.maxWidth >= 1280;
          final shellActions = <Widget>[
            _OrdersNotificationButton(
              unreadCount: _notificationSummary?.unreadCount ?? 0,
              onPressed: () => Get.to(() => const NotificationsPage()),
            ),
            if (wideLayout && !_showAllOrders && selectedOrder != null)
              _OrderHeaderLiveChip(
                order: selectedOrder,
                relativeLabel: _relativeTimeLabel(selectedOrder.orderDateTime),
                onPressed: () {
                  setState(() => _showAllOrders = true);
                },
              )
            else if (wideLayout && _showAllOrders)
              TextButton.icon(
                onPressed: () => setState(() => _showAllOrders = false),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('العودة للوحة'),
              ),
          ];

          final body = selectedBucket == 'scheduled' &&
                  !_showAllOrders &&
                  !_auth.isStore
              ? ScheduledOrdersBoard(
                  orders: scheduledBoardOrders,
                  selectedOrder: selectedOrder,
                  controller: orderController,
                  itemImagesById: _itemImagesById,
                  vendorId: _auth.vendorId,
                  onSelectOrder: (order) {
                    setState(() => _selectedOrderId = order.ordersId);
                  },
                  onConfirmScheduled: _confirmScheduledOrder,
                  onAdjustScheduled: _adjustScheduledOrder,
                  onCancelScheduled: _cancelScheduledOrder,
                  onShowAllOrders: () => setState(() => _showAllOrders = true),
                  onRefreshOrders: orderController.fetchOrders,
                )
              : (_auth.isStore || (wideLayout && !_showAllOrders))
                  ? OrderManagementBoard(
                      orders: boardOrders,
                      selectedOrder: selectedOrder,
                      controller: orderController,
                      itemImagesById: _itemImagesById,
                      isMaster: _auth.isMaster,
                      vendorId: _auth.vendorId,
                      onSelectOrder: (order) {
                        setState(() => _selectedOrderId = order.ordersId);
                      },
                      onAcceptOrder: (order, minutes) =>
                          _acceptSelectedOrder(order, minutes),
                      onRejectOrder: (order, reason) =>
                          _rejectSelectedOrder(order, reason),
                      onShowAllOrders: () =>
                          setState(() => _showAllOrders = true),
                      onRefreshOrders: orderController.fetchOrders,
                      isStore: _auth.isStore,
                    )
                  : _buildClassicOrdersBody();

          return DashboardPageShell(
            title: _resolveShellTitle(routeArgs),
            subtitle: _resolveShellSubtitle(routeArgs),
            icon: Icons.receipt_long_rounded,
            activeSidebarIndex: _resolveSidebarIndex(routeArgs),
            actions: shellActions,
            body: body,
            profileAvatarUrl: _restaurantSettings?.vendorLogo,
            profileSubtitle:
                _restaurantSettings?.vendorDescription?.trim().isNotEmpty ==
                        true
                    ? _restaurantSettings!.vendorDescription!.trim()
                    : null,
            statusLabel: _restaurantSettings == null
                ? (_auth.isStore
                    ? 'جاري تحميل بيانات المتجر'
                    : 'جاري تحميل بيانات المطعم')
                : (_restaurantSettings!.isOpen
                    ? (_auth.isStore
                        ? 'المتجر مفتوح الآن'
                        : 'المطعم مفتوح الآن')
                    : (_auth.isStore
                        ? 'المتجر مغلق الآن'
                        : 'المطعم مغلق الآن')),
            statusTint: _restaurantSettings == null
                ? kPrimary
                : (_restaurantSettings!.isOpen
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444)),
          );
        },
      );
    });
  }

  void _showDeleteConfirmationDialog(int orderId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceElevated,
        title: const Text('حذف الطلب'),
        content: const Text(
          'سيتم حذف هذا الطلب وكل تفاصيله بشكل نهائي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await orderController.deleteOrderByOrderId(orderId);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الطلب بنجاح')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('تعذر حذف الطلب: $e')),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOrderAction(
    OrderModel order,
    _OrderActionMode action,
  ) async {
    switch (action) {
      case _OrderActionMode.accept:
        await _showPrepTimeBottomSheet(
          order,
          title: 'قبول الطلب #${order.ordersId ?? '-'}',
          subtitle: 'اختر مدة التحضير المتوقعة قبل تحويله إلى قيد التنفيذ.',
          confirmLabel: 'قبول الطلب',
          successMessage: 'تم قبول الطلب بنجاح',
          openDriverDispatchAfterSuccess: true,
        );
        return;
      case _OrderActionMode.confirmScheduled:
        await _showPrepTimeBottomSheet(
          order,
          title: 'تأكيد الطلب المجدول #${order.ordersId ?? '-'}',
          subtitle: 'يمكنك تثبيت الجاهزية مع مدة التحضير المتوقعة.',
          confirmLabel: 'تأكيد الطلب',
          successMessage: 'تم تأكيد الطلب المجدول بنجاح',
        );
        return;
      case _OrderActionMode.adjustScheduled:
        await _showPrepTimeBottomSheet(
          order,
          title: 'تعديل جاهزية الطلب #${order.ordersId ?? '-'}',
          subtitle: 'غيّر مدة التحضير للطلب المجدول قبل تنفيذه.',
          confirmLabel: 'حفظ التعديل',
          successMessage: 'تم تحديث جاهزية الطلب المجدول',
        );
        return;
      case _OrderActionMode.reject:
        await _showRejectionBottomSheet(
          order,
          title: 'رفض الطلب #${order.ordersId ?? '-'}',
          subtitle: 'اختر سبب الرفض ليصل إلى المتابعة الداخلية والعميل.',
          confirmLabel: 'رفض الطلب',
          status: 'failed',
          successMessage: 'تم رفض الطلب بنجاح',
        );
        return;
      case _OrderActionMode.cancelScheduled:
        await _showRejectionBottomSheet(
          order,
          title: 'إلغاء الطلب المجدول #${order.ordersId ?? '-'}',
          subtitle: 'أضف سبب الإلغاء قبل تحديث الحالة.',
          confirmLabel: 'إلغاء الطلب',
          status: 'canceled',
          successMessage: 'تم إلغاء الطلب المجدول',
        );
        return;
      case _OrderActionMode.generic:
        _showUpdateStatusBottomSheet(order);
        return;
    }
  }

  Future<void> _showPrepTimeBottomSheet(
    OrderModel order, {
    required String title,
    required String subtitle,
    required String confirmLabel,
    required String successMessage,
    bool openDriverDispatchAfterSuccess = false,
  }) async {
    final minutesController = TextEditingController(
      text: (order.ordersEstimatedMinutes != null &&
              order.ordersEstimatedMinutes! > 0)
          ? order.ordersEstimatedMinutes.toString()
          : '15',
    );
    var selectedMinutes = int.tryParse(minutesController.text) ?? 15;
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
                      _ActionSummaryCard(
                        order: order,
                        accent: kPrimary,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final minutes in const [10, 15, 20, 30, 45])
                            ChoiceChip(
                              selected:
                                  !useManual && selectedMinutes == minutes,
                              label: Text('$minutes دقيقة'),
                              onSelected: (_) {
                                setModalState(() {
                                  useManual = false;
                                  selectedMinutes = minutes;
                                  minutesController.text = minutes.toString();
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
                          controller: minutesController,
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
                                ? int.tryParse(minutesController.text.trim())
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
                            final success =
                                await _updateOrderStatusWithFeedback(
                              order,
                              status: 'paid',
                              estimatedMinutes: parsed,
                              successMessage: '$successMessage ($parsed دقيقة)',
                            );
                            if (success &&
                                openDriverDispatchAfterSuccess &&
                                (order.deliveryId ?? 0) <= 0 &&
                                mounted) {
                              await _showDriverSelectionBottomSheet(order);
                            }
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
      minutesController.dispose();
    }
  }

  Future<void> _showRejectionBottomSheet(
    OrderModel order, {
    required String title,
    required String subtitle,
    required String confirmLabel,
    required String status,
    required String successMessage,
  }) async {
    final reasonController = TextEditingController();
    var selectedReason = 'منتج غير متوفر';
    const reasons = [
      'منتج غير متوفر',
      'ضغط عمل',
      'إغلاق المتجر',
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
                      _ActionSummaryCard(
                        order: order,
                        accent: const Color(0xFFEF4444),
                      ),
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
                            labelText: 'اكتب السبب باختصار',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                          onPressed: () async {
                            final reason = needsCustomReason
                                ? reasonController.text.trim()
                                : selectedReason;
                            if (needsCustomReason && reason.isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text('اكتب سببًا واضحًا للرفض'),
                                ),
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                            await _updateOrderStatusWithFeedback(
                              order,
                              status: status,
                              reason: reason,
                              successMessage: '$successMessage - $reason',
                              errorPrefix: 'تعذر تحديث حالة الطلب',
                            );
                          },
                          icon: const Icon(Icons.cancel_rounded),
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
      reasonController.dispose();
    }
  }

  void _showPickupQrDialog(OrderModel order) {
    final qrData = (order.deliveryCode ?? '').trim().isNotEmpty
        ? order.deliveryCode!.trim()
        : 'order-${order.ordersId ?? 0}';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: kSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'QR Code الخاص بالطلب',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الطلب #${order.ordersId ?? '-'}',
                style: const TextStyle(color: kTextSecondary),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: qrData,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                qrData,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'بانتظار الاستلام الذاتي',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateStatusBottomSheet(OrderModel order) {
    var currentStatus = order.ordersStatus ?? 'pending';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurfaceElevated,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: RadioGroup<String>(
            groupValue: currentStatus,
            onChanged: (value) {
              if (value != null) {
                setModalState(() => currentStatus = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحديث حالة الطلب #${order.ordersId}',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final option in const ['pending', 'paid', 'canceled'])
                  RadioListTile<String>(
                    value: option,
                    activeColor: kPrimary,
                    dense: true,
                    title: Text(_statusLabelAr(option)),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _updateOrderStatusWithFeedback(
                        order,
                        status: currentStatus,
                        successMessage: 'تم تحديث حالة الطلب',
                      );
                    },
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDriverSelectionBottomSheet(OrderModel order) async {
    final vendorId = order.vendorId ?? _auth.vendorId;
    if (vendorId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد المتجر الخاص بهذا الطلب')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurfaceElevated,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final restaurantLocation = _restaurantLocationForOrder(order);
        final future = orderController.fetchAvailableDrivers(
          vendorId: vendorId,
          restaurantLatitude: restaurantLocation?.latitude,
          restaurantLongitude: restaurantLocation?.longitude,
          onlyAvailable: true,
        );

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: FutureBuilder<List<DriverDispatchOption>>(
                future: future,
                builder: (context, snapshot) {
                  final customerLocation = _customerLocationForOrder(order);
                  final drivers = _sortDriversByDistance(
                    snapshot.data ?? const <DriverDispatchOption>[],
                    restaurantLocation,
                  );
                  final availableDrivers = drivers
                      .where((driver) => driver.canDispatch)
                      .toList(growable: false);
                  final nearestDriver = availableDrivers.isNotEmpty
                      ? availableDrivers.first
                      : null;

                  Widget buildScrollableBody(List<Widget> children) {
                    return ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: children,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return buildScrollableBody([
                      const SizedBox(height: 8),
                      Text(
                        'إرسال الطلب #${order.ordersId} إلى مندوب',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختر أي مندوب متاح لاستلام الطلب.',
                        style: TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              size: 18,
                              color: kPrimary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'جارٍ تحميل السائقين المتاحين من قاعدة البيانات...',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: CircularProgressIndicator(color: kPrimary),
                        ),
                      ),
                    ]);
                  }

                  if (snapshot.hasError) {
                    return buildScrollableBody([
                      const SizedBox(height: 8),
                      Text(
                        'إرسال الطلب #${order.ordersId} إلى مندوب',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختر أي مندوب متاح لاستلام الطلب.',
                        style: TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'تعذر تحميل المندوبين: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }

                  if (availableDrivers.isEmpty) {
                    return buildScrollableBody([
                      const SizedBox(height: 8),
                      Text(
                        'إرسال الطلب #${order.ordersId} إلى مندوب',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختر أي مندوب متاح لاستلام الطلب.',
                        style: TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'لا يوجد مندوب متاح حاليًا',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }

                  return buildScrollableBody([
                    const SizedBox(height: 8),
                    Text(
                      'إرسال الطلب #${order.ordersId} إلى مندوب',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اختر أي مندوب متاح لاستلام الطلب.',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: nearestDriver == null
                                ? null
                                : () async {
                                    Navigator.of(sheetContext).pop();
                                    await _assignDriverToOrder(
                                      order,
                                      nearestDriver,
                                      vendorId,
                                    );
                                  },
                            icon: const Icon(Icons.bolt_rounded),
                            label: const Text('تعيين الأقرب تلقائياً'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kPrimary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_searching_rounded,
                            size: 18,
                            color: kPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم العثور على ${availableDrivers.length} سائق متاح وموثوق من قاعدة البيانات.',
                              style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DriverDispatchMapPanel(
                      restaurantName: _restaurantSettings?.storeName ??
                          _restaurantSettings?.vendorName ??
                          'Store',
                      restaurantLocation: restaurantLocation,
                      customerLocation: customerLocation,
                      drivers: availableDrivers,
                    ),
                    const SizedBox(height: 16),
                    for (final driver in availableDrivers) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await _assignDriverToOrder(
                            order,
                            driver,
                            vendorId,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kStroke),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    kPrimary.withValues(alpha: 0.16),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.name,
                                      style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${driver.phone} • ${driver.vehicleLabel}',
                                      style: const TextStyle(
                                        color: kTextSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (driver.distanceKm != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${driver.distanceKm!.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          color: kPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignDriverToOrder(
    OrderModel order,
    DriverDispatchOption driver,
    int vendorId,
  ) async {
    try {
      await orderController.assignOrderToDriver(
        orderId: order.ordersId ?? 0,
        driverId: driver.id,
        vendorId: vendorId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال الطلب إلى ${driver.name} بنجاح')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال الطلب للمندوب: $e')),
      );
    }
  }

  void _showOrderChatSheet(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.82,
            child: OrderChatCard(order: order, scope: 'order'),
          ),
        );
      },
    );
  }

  Future<void> _launchPhoneNumber(String phone) async {
    final normalized = phone.trim();
    if (normalized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير متوفر')),
      );
      return;
    }

    final uri = Uri.parse('tel:$normalized');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الاتصال: $normalized')),
      );
    }
  }

  Future<void> _callDriverFromOrder(OrderModel order) async {
    await _launchPhoneNumber(order.driverPhone ?? '');
  }

  DispatchLocation? _restaurantLocationForOrder(OrderModel order) {
    final snapshot = _restaurantSettings;
    final lat = order.storeLatitude ?? snapshot?.storeLatitude;
    final lng = order.storeLongitude ?? snapshot?.storeLongitude;
    if (lat == null || lng == null) {
      return null;
    }
    if (lat == 0 || lng == 0) {
      return null;
    }
    return DispatchLocation(latitude: lat, longitude: lng);
  }

  DispatchLocation? _customerLocationForOrder(OrderModel order) {
    final lat = order.ordersRecipientLat;
    final lng = order.ordersRecipientLng;
    if (lat == null || lng == null) {
      return null;
    }
    if (lat == 0 || lng == 0) {
      return null;
    }
    return DispatchLocation(latitude: lat, longitude: lng);
  }

  List<DriverDispatchOption> _sortDriversByDistance(
    List<DriverDispatchOption> drivers,
    DispatchLocation? restaurantLocation,
  ) {
    final sorted = [...drivers];
    sorted.sort((a, b) {
      final aDistance = a.distanceKm ??
          (restaurantLocation == null
              ? null
              : _distanceBetweenForDriver(restaurantLocation, a));
      final bDistance = b.distanceKm ??
          (restaurantLocation == null
              ? null
              : _distanceBetweenForDriver(restaurantLocation, b));

      if (aDistance == null && bDistance == null) {
        return a.name.compareTo(b.name);
      }
      if (aDistance == null) return 1;
      if (bDistance == null) return -1;
      final compare = aDistance.compareTo(bDistance);
      return compare != 0 ? compare : a.name.compareTo(b.name);
    });
    return sorted;
  }

  double? _distanceBetweenForDriver(
    DispatchLocation restaurantLocation,
    DriverDispatchOption driver,
  ) {
    final driverLocation = _driverLocationOf(driver);
    if (driverLocation == null) {
      return null;
    }
    return _distanceBetween(
      restaurantLocation.latitude,
      restaurantLocation.longitude,
      driverLocation.latitude,
      driverLocation.longitude,
    );
  }

  DispatchLocation? _driverLocationOf(DriverDispatchOption driver) {
    final lat = driver.latitude;
    final lng = driver.longitude;
    if (lat == null || lng == null) {
      return null;
    }
    if (lat == 0 || lng == 0) {
      return null;
    }
    return DispatchLocation(latitude: lat, longitude: lng);
  }

  double _distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(max(0, 1 - a)));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  Future<void> _showPrintOptions(
    OrderModel order,
    List<OrderItemDetail> items,
  ) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurfaceElevated,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طباعة الطلب #${order.ordersId ?? '-'}',
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اختر النسخة المناسبة للتجهيز أو للعميل',
              style: TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _printKitchenSlip(order, items);
                },
                icon: const Icon(Icons.kitchen_rounded),
                label: const Text('ورقة التجهيز'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _printCustomerReceipt(order, items);
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('ورقة العميل'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printKitchenSlip(
    OrderModel order,
    List<OrderItemDetail> items,
  ) async {
    try {
      final bytes = await _slipPdfService.buildKitchenSlip(
        order: order,
        items: items,
      );
      final printed = await Printing.layoutPdf(
        name: 'kitchen-slip-${order.ordersId ?? 0}.pdf',
        onLayout: (_) async => bytes,
      );
      if (printed) {
        await _recordOrderPrint(order, 'kitchen');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء ورقة التجهيز: $e')),
      );
    }
  }

  Future<void> _printCustomerReceipt(
    OrderModel order,
    List<OrderItemDetail> items,
  ) async {
    try {
      final bytes = await _slipPdfService.buildCustomerReceipt(
        order: order,
        items: items,
      );
      final printed = await Printing.layoutPdf(
        name: 'customer-receipt-${order.ordersId ?? 0}.pdf',
        onLayout: (_) async => bytes,
      );
      if (printed) {
        await _recordOrderPrint(order, 'invoice');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء ورقة العميل: $e')),
      );
    }
  }

  Future<void> _recordOrderPrint(OrderModel order, String jobType) async {
    final orderId = order.ordersId;
    if (orderId == null) {
      return;
    }

    try {
      await _printingData.recordPrintJob(
        orderId: orderId,
        jobType: jobType,
        payload: {
          'source': 'order_page',
          'order_id': orderId,
        },
      );
    } catch (_) {
      // Printing should not fail just because audit logging is unavailable.
    }
  }
}

class _OrdersTopBar extends StatelessWidget {
  final bool isMobile;
  final bool isMaster;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _OrdersTopBar({
    required this.isMobile,
    required this.isMaster,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 16 : 24, 18, isMobile ? 16 : 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kStroke),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إدارة الطلبات',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMaster
                        ? 'عرض شامل لكل طلبات المتجر وتفاصيل العملاء'
                        : 'عرض مخصص لطلبات متجرك وتفاصيل العملاء',
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersQuickStats extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrdersQuickStats({required this.orders});

  @override
  Widget build(BuildContext context) {
    final newOrders = orders.where((o) => o.lifecycleBucket == 'new').length;
    final scheduled =
        orders.where((o) => o.lifecycleBucket == 'scheduled').length;
    final inProgress = orders.where((o) {
      return const {'preparing', 'in_delivery'}.contains(o.lifecycleBucket);
    }).length;
    final delivered =
        orders.where((o) => o.lifecycleBucket == 'delivered').length;
    final revenue =
        orders.fold<double>(0, (sum, order) => sum + order.totalPriceValue);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MiniStat(label: 'كل الطلبات', value: '${orders.length}'),
        _MiniStat(label: 'طلبات جديدة', value: '$newOrders'),
        _MiniStat(label: 'طلبات مجدولة', value: '$scheduled'),
        _MiniStat(label: 'قيد التنفيذ', value: '$inProgress'),
        _MiniStat(label: 'مكتملة', value: '$delivered'),
        _MiniStat(label: 'الإيراد', value: '${revenue.toStringAsFixed(0)} SAR'),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSummaryCard extends StatelessWidget {
  final OrderModel order;
  final Color accent;

  const _ActionSummaryCard({
    required this.order,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledText = (order.scheduledFor ?? '').trim();
    final pickupCode = (order.deliveryCode ?? '').trim();
    final chips = <_ActionSummaryChipData>[
      _ActionSummaryChipData(
        label: 'الطلب',
        value: '#${order.ordersId ?? '-'}',
      ),
      _ActionSummaryChipData(
        label: 'العميل',
        value: order.usersName?.trim().isNotEmpty == true
            ? order.usersName!.trim()
            : 'غير معروف',
      ),
      _ActionSummaryChipData(
        label: 'طريقة الطلب',
        value: order.orderTypeLabel,
      ),
      if (scheduledText.isNotEmpty)
        _ActionSummaryChipData(
          label: 'الموعد',
          value: _formatScheduleDisplay(scheduledText),
        ),
      if (pickupCode.isNotEmpty)
        _ActionSummaryChipData(
          label: 'رمز الاستلام',
          value: pickupCode,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips
            .map(
              (chip) => _ActionSummaryChip(
                data: chip,
                accent: accent,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActionSummaryChipData {
  final String label;
  final String value;

  const _ActionSummaryChipData({
    required this.label,
    required this.value,
  });
}

class _ActionSummaryChip extends StatelessWidget {
  final _ActionSummaryChipData data;
  final Color accent;

  const _ActionSummaryChip({
    required this.data,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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

class _OrdersFilters extends StatelessWidget {
  final TextEditingController controller;
  final String selectedStatus;
  final String selectedScheduledWindow;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onScheduledWindowChanged;

  const _OrdersFilters({
    required this.controller,
    required this.selectedStatus,
    required this.selectedScheduledWindow,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onScheduledWindowChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            cursorColor: kPrimary,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الطلب أو اسم العميل أو الهاتف',
              hintStyle: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              prefixIconColor: kTextSecondary,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: kStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: kStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: kPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const [
                'all',
                'new',
                'scheduled',
                'preparing',
                'in_delivery',
                'delivered',
                'canceled',
              ])
                ChoiceChip(
                  selected: selectedStatus == status,
                  label: Text(_statusLabelAr(status)),
                  labelStyle: TextStyle(
                    color: selectedStatus == status ? kPrimary : kTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onStatusChanged(status),
                ),
            ],
          ),
          if (selectedStatus == 'scheduled') ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'فرز الطلبات المجدولة',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final window in const ['all', 'today', 'tomorrow', 'week'])
                  ChoiceChip(
                    selected: selectedScheduledWindow == window,
                    label: Text(_scheduledWindowLabelAr(window)),
                    labelStyle: TextStyle(
                      color: selectedScheduledWindow == window
                          ? kPrimary
                          : kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => onScheduledWindowChanged(window),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverDispatchMapPanel extends StatefulWidget {
  const _DriverDispatchMapPanel({
    required this.restaurantName,
    required this.restaurantLocation,
    required this.customerLocation,
    required this.drivers,
  });

  final String restaurantName;
  final DispatchLocation? restaurantLocation;
  final DispatchLocation? customerLocation;
  final List<DriverDispatchOption> drivers;

  @override
  State<_DriverDispatchMapPanel> createState() =>
      _DriverDispatchMapPanelState();
}

class _DriverDispatchMapPanelState extends State<_DriverDispatchMapPanel> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _restaurantMarkerManager;
  CircleAnnotationManager? _driverMarkerManager;
  PolylineAnnotationManager? _routeManager;
  bool _styleLoaded = false;

  @override
  Widget build(BuildContext context) {
    final restaurantLocation = widget.restaurantLocation;
    final panelHeight =
        MediaQuery.of(context).size.height < 700 ? 180.0 : 220.0;
    final validDrivers = widget.drivers
        .where(
            (driver) => driver.canDispatch && _driverLocationOf(driver) != null)
        .toList(growable: false);
    final canShowStaticMap =
        MapboxRuntimeConfig.accessToken.trim().isNotEmpty &&
            (restaurantLocation != null ||
                widget.customerLocation != null ||
                validDrivers.isNotEmpty);
    final canShowNativeMap = !kIsWeb &&
        MapboxRuntimeConfig.isConfigured &&
        restaurantLocation != null &&
        validDrivers.isNotEmpty;
    final staticMapUrl = canShowStaticMap
        ? _buildStaticMapUrl(
            restaurantLocation: restaurantLocation,
            customerLocation: widget.customerLocation,
            drivers: validDrivers,
          )
        : null;

    return SizedBox(
      height: panelHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (canShowNativeMap)
              Positioned.fill(
                child: MapWidget(
                  key: ValueKey(
                    'dispatch-map-${widget.restaurantLocation.hashCode}-${widget.customerLocation.hashCode}-${validDrivers.length}',
                  ),
                  styleUri: MapboxRuntimeConfig.styleUri,
                  viewport: CameraViewportState(
                    center: Point(
                      coordinates: Position(
                        restaurantLocation.longitude,
                        restaurantLocation.latitude,
                      ),
                    ),
                    zoom: 12.8,
                    pitch: 0,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedListener: _onStyleLoaded,
                ),
              )
            else if (staticMapUrl != null)
              Positioned.fill(
                child: Image.network(
                  staticMapUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _mapFallback(context);
                  },
                ),
              )
            else
              _mapFallback(context),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.restaurantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (validDrivers.isNotEmpty)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'المندوبون: ${validDrivers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.66),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _locationSummary(
                    restaurantLocation: restaurantLocation,
                    customerLocation: widget.customerLocation,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Widget _mapFallback(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF172028), Color(0xFF0E1419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'الخريطة غير جاهزة أو لا توجد إحداثيات كافية بعد.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
      ),
    );
  }

  DispatchLocation? _driverLocationOf(DriverDispatchOption driver) {
    final lat = driver.latitude;
    final lng = driver.longitude;
    if (lat == null || lng == null) {
      return null;
    }
    if (lat == 0 || lng == 0) {
      return null;
    }
    return DispatchLocation(latitude: lat, longitude: lng);
  }

  String? _buildStaticMapUrl({
    required DispatchLocation? restaurantLocation,
    required DispatchLocation? customerLocation,
    required List<DriverDispatchOption> drivers,
  }) {
    final token = MapboxRuntimeConfig.accessToken.trim();
    if (token.isEmpty) {
      return null;
    }

    final nearestDriver =
        drivers.isNotEmpty ? _driverLocationOf(drivers.first) : null;
    final fallbackCenter =
        restaurantLocation ?? nearestDriver ?? customerLocation;
    if (fallbackCenter == null) {
      return null;
    }

    final centerLon = customerLocation?.longitude ??
        nearestDriver?.longitude ??
        fallbackCenter.longitude;
    final centerLat = customerLocation?.latitude ??
        nearestDriver?.latitude ??
        fallbackCenter.latitude;

    const width = 1200;
    const height = 440;
    const zoom = 12;
    const styleId = 'mapbox/streets-v12';

    final markers = <String>[
      if (restaurantLocation != null)
        'pin-s+16a34a(${restaurantLocation.longitude},${restaurantLocation.latitude})',
      if (nearestDriver != null)
        'pin-s+3b82f6(${nearestDriver.longitude},${nearestDriver.latitude})',
      if (customerLocation != null)
        'pin-s+f59e0b(${customerLocation.longitude},${customerLocation.latitude})',
    ];

    final markerPath = markers.join(',');
    final url = Uri.parse(
      'https://api.mapbox.com/styles/v1/$styleId/static/$markerPath/$centerLon,$centerLat,$zoom/${width}x$height@2x?access_token=$token',
    );
    return url.toString();
  }

  String _locationSummary({
    required DispatchLocation? restaurantLocation,
    required DispatchLocation? customerLocation,
  }) {
    final parts = <String>[];
    if (restaurantLocation != null) {
      parts.add(
        'المتجر: ${restaurantLocation.latitude.toStringAsFixed(5)}, ${restaurantLocation.longitude.toStringAsFixed(5)}',
      );
    }
    if (customerLocation != null) {
      parts.add(
        'العميل: ${customerLocation.latitude.toStringAsFixed(5)}, ${customerLocation.longitude.toStringAsFixed(5)}',
      );
    }
    if (parts.isEmpty) {
      return 'لا توجد إحداثيات كافية لعرض المسار';
    }
    return parts.join(' | ');
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    _styleLoaded = true;
    final mapboxMap = _mapboxMap;
    final restaurantLocation = widget.restaurantLocation;
    if (!_styleLoaded || mapboxMap == null || restaurantLocation == null) {
      return;
    }

    _restaurantMarkerManager ??=
        await mapboxMap.annotations.createCircleAnnotationManager();
    _driverMarkerManager ??=
        await mapboxMap.annotations.createCircleAnnotationManager();
    _routeManager ??=
        await mapboxMap.annotations.createPolylineAnnotationManager();

    await _restaurantMarkerManager?.deleteAll();
    await _driverMarkerManager?.deleteAll();
    await _routeManager?.deleteAll();

    await _restaurantMarkerManager?.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            restaurantLocation.longitude,
            restaurantLocation.latitude,
          ),
        ),
        circleColor: const Color(0xFF59D98E).toARGB32(),
        circleRadius: 12,
        circleStrokeColor: const Color(0xFFFFFFFF).toARGB32(),
        circleStrokeWidth: 4,
      ),
    );

    for (final driver in widget.drivers.where((driver) => driver.canDispatch)) {
      final driverLocation = _driverLocationOf(driver);
      if (driverLocation == null) {
        continue;
      }
      await _driverMarkerManager?.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              driverLocation.longitude,
              driverLocation.latitude,
            ),
          ),
          circleColor: const Color(0xFFFFC857).toARGB32(),
          circleRadius: 9,
          circleStrokeColor: const Color(0xFFFFFFFF).toARGB32(),
          circleStrokeWidth: 3,
        ),
      );
    }

    final routePoints = _buildRoutePoints();
    if (routePoints.length >= 2) {
      await _routeManager?.setLineCap(LineCap.ROUND);
      await _routeManager?.setLineJoin(LineJoin.ROUND);
      await _routeManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: const Color(0xFF5A8DEE).toARGB32(),
          lineWidth: 5,
        ),
      );
    }

    await _focusScene();
  }

  List<Position> _buildRoutePoints() {
    final restaurantLocation = widget.restaurantLocation;
    if (restaurantLocation == null) {
      return const [];
    }

    final points = <Position>[
      Position(
        restaurantLocation.longitude,
        restaurantLocation.latitude,
      ),
    ];

    DispatchLocation? nearestDriverLocation;
    for (final driver in widget.drivers.where((driver) => driver.canDispatch)) {
      nearestDriverLocation = _driverLocationOf(driver);
      if (nearestDriverLocation != null) {
        break;
      }
    }

    if (nearestDriverLocation != null) {
      points.add(
        Position(
          nearestDriverLocation.longitude,
          nearestDriverLocation.latitude,
        ),
      );
    }

    final customerLocation = widget.customerLocation;
    if (customerLocation != null) {
      points.add(
        Position(
          customerLocation.longitude,
          customerLocation.latitude,
        ),
      );
    }

    return points;
  }

  Future<void> _focusScene() async {
    final mapboxMap = _mapboxMap;
    final restaurantLocation = widget.restaurantLocation;
    if (mapboxMap == null || restaurantLocation == null) {
      return;
    }

    final validPoints = <Point>[
      Point(
        coordinates: Position(
          restaurantLocation.longitude,
          restaurantLocation.latitude,
        ),
      ),
      for (final driver in widget.drivers.where((driver) => driver.canDispatch))
        if (_driverLocationOf(driver) != null)
          Point(
            coordinates: Position(
              _driverLocationOf(driver)!.longitude,
              _driverLocationOf(driver)!.latitude,
            ),
          ),
      if (widget.customerLocation != null)
        Point(
          coordinates: Position(
            widget.customerLocation!.longitude,
            widget.customerLocation!.latitude,
          ),
        ),
    ];

    if (validPoints.isEmpty) {
      return;
    }

    if (validPoints.length > 1) {
      final camera = await mapboxMap.cameraForCoordinatesPadding(
        validPoints,
        CameraOptions(pitch: 0, bearing: 0),
        MbxEdgeInsets(top: 80, left: 60, bottom: 80, right: 60),
        14,
        null,
      );
      await mapboxMap.easeTo(
        CameraOptions(
          center: camera.center,
          zoom: camera.zoom,
          bearing: camera.bearing,
          pitch: camera.pitch,
          padding: camera.padding,
        ),
        MapAnimationOptions(duration: 700),
      );
      return;
    }

    await mapboxMap.easeTo(
      CameraOptions(
        center: validPoints.first,
        zoom: 13.8,
        pitch: 0,
        bearing: 0,
        padding: MbxEdgeInsets(top: 80, left: 60, bottom: 80, right: 60),
      ),
      MapAnimationOptions(duration: 700),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isMaster;
  final OrderController controller;
  final Map<int, String> itemImagesById;
  final ValueChanged<int> onDelete;
  final Future<void> Function(OrderModel order, _OrderActionMode action)
      onAction;
  final Future<void> Function(OrderModel order) onAssignDriver;
  final ValueChanged<OrderModel> onChatOrder;
  final Future<void> Function(OrderModel order) onCallDriver;
  final Future<void> Function(
    OrderModel order,
    List<OrderItemDetail> items,
  ) onPrintSlip;
  final ValueChanged<OrderModel> onShowPickupQr;

  const _OrderCard({
    required this.order,
    required this.isMaster,
    required this.controller,
    required this.itemImagesById,
    required this.onDelete,
    required this.onAction,
    required this.onAssignDriver,
    required this.onChatOrder,
    required this.onCallDriver,
    required this.onPrintSlip,
    required this.onShowPickupQr,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool detailsOpen = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPendingAction = _isPendingOrder(order);
    final isScheduledAction = _isScheduledOrder(order);
    final hasPickupQr =
        order.isPickup && (order.deliveryCode?.trim().isNotEmpty == true);
    return Container(
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<List<OrderItemDetail>>(
          // Loading details for every visible card made the orders page fire
          // one request per order. Fetch them only when the user opens a card.
          future: detailsOpen
              ? widget.controller.fetchOrderDetails(
                  order.ordersId ?? 0,
                  vendorId: order.vendorId ?? 0,
                )
              : null,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <OrderItemDetail>[];
            final summary = _orderSummary(items);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusBadge(status: order.ordersStatus ?? 'pending'),
                    Text(
                      'طلب #${order.ordersId}',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${order.totalPriceValue.toStringAsFixed(2)} SAR',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SimpleInfoRows(
                  order: order,
                  summary: summary,
                  isMaster: widget.isMaster,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OrderChip(label: summary.typeLabel, color: summary.color),
                    _OrderChip(
                      label: order.lifecycleLabelAr,
                      color: _lifecycleColor(order.lifecycleBucket),
                    ),
                    _OrderChip(
                        label:
                            '${items.length} item${items.length == 1 ? '' : 's'}',
                        color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: LinearProgressIndicator(color: kPrimary),
                  )
                else if (items.isNotEmpty)
                  _CompactItemsTable(
                    items: items,
                    itemImagesById: widget.itemImagesById,
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => detailsOpen = !detailsOpen),
                      icon: Icon(
                        detailsOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                      label:
                          Text(detailsOpen ? 'إخفاء التفاصيل' : 'عرض التفاصيل'),
                    ),
                    if (isPendingAction)
                      FilledButton.icon(
                        onPressed: () => widget.onAction(
                          order,
                          _OrderActionMode.accept,
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('قبول الطلب'),
                      ),
                    if (isPendingAction)
                      OutlinedButton.icon(
                        onPressed: () => widget.onAction(
                          order,
                          _OrderActionMode.reject,
                        ),
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('رفض الطلب'),
                      ),
                    if (isScheduledAction)
                      FilledButton.icon(
                        onPressed: () => widget.onAction(
                          order,
                          _OrderActionMode.confirmScheduled,
                        ),
                        icon: const Icon(Icons.schedule_send_rounded),
                        label: const Text('تأكيد الطلب'),
                      ),
                    if (isScheduledAction)
                      OutlinedButton.icon(
                        onPressed: () => widget.onAction(
                          order,
                          _OrderActionMode.adjustScheduled,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('تعديل الجاهزية'),
                      ),
                    if (isScheduledAction)
                      OutlinedButton.icon(
                        onPressed: () => widget.onAction(
                          order,
                          _OrderActionMode.cancelScheduled,
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('إلغاء'),
                      ),
                    if (!isPendingAction && !isScheduledAction)
                      OutlinedButton.icon(
                        onPressed: () => widget.onAction(
                          order,
                          _OrderActionMode.generic,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('الحالة'),
                      ),
                    if (!order.isCancelledOrder && !order.isDeliveredOrder) ...[
                      if (!isPendingAction)
                        OutlinedButton.icon(
                          onPressed: () => widget.onAssignDriver(order),
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: Text(
                            order.deliveryId != null && order.deliveryId! > 0
                                ? 'تغيير المندوب'
                                : 'إرسال للمندوب',
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => widget.onChatOrder(order),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('محادثة الطلب'),
                      ),
                    ],
                    if (hasPickupQr)
                      OutlinedButton.icon(
                        onPressed: () => widget.onShowPickupQr(order),
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('QR الاستلام'),
                      ),
                    OutlinedButton.icon(
                      onPressed: snapshot.hasData
                          ? () {
                              widget.onPrintSlip(order, items);
                            }
                          : null,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('طباعة'),
                    ),
                    if (widget.isMaster)
                      FilledButton.icon(
                        onPressed: () => widget.onDelete(order.ordersId ?? 0),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('حذف'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          order.deliveryId == null || order.deliveryId == 0
                              ? null
                              : () => widget.onCallDriver(order),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('اتصال المندوب'),
                    ),
                  ],
                ),
                if (detailsOpen && items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final item in items) ...[
                    _ExpandedOrderItem(
                      item: item,
                      imageName: widget.itemImagesById[item.itemId],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  _OrderSummaryData _orderSummary(List<OrderItemDetail> items) {
    if (items.isEmpty) {
      return const _OrderSummaryData(
        typeLabel: 'بدون عناصر',
        color: kSecondary,
      );
    }
    if (items.length == 1) {
      return const _OrderSummaryData(
        typeLabel: 'عنصر واحد',
        color: kPrimary,
      );
    }
    return const _OrderSummaryData(
      typeLabel: 'عدة عناصر',
      color: kAccent,
    );
  }
}

class _SimpleInfoRows extends StatelessWidget {
  final OrderModel order;
  final _OrderSummaryData summary;
  final bool isMaster;

  const _SimpleInfoRows({
    required this.order,
    required this.summary,
    required this.isMaster,
  });

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (isMaster)
        'المتجر: ${order.storeName?.isNotEmpty == true ? order.storeName : (order.vendorName ?? 'غير معروف')}',
      'العميل: ${order.usersName ?? 'غير معروف'}',
      'الهاتف: ${order.addressPhone ?? 'غير متاح'}',
      'المدينة: ${order.addressCity ?? 'غير متاح'}',
      'الوقت: ${order.ordersDatetime ?? 'غير متاح'}',
      if ((order.ordersGiftMessage ?? '').trim().isNotEmpty)
        'رسالة الإهداء: ${order.ordersGiftMessage}',
      if ((order.ordersDeliveryNote ?? '').trim().isNotEmpty)
        'ملاحظات التوصيل: ${order.ordersDeliveryNote}',
      if (order.scheduledFor?.trim().isNotEmpty == true)
        'موعد التنفيذ: ${_formatScheduleDisplay(order.scheduledFor!)}',
      if ((order.deliveryCode ?? '').trim().isNotEmpty == true)
        'رمز الطلب: ${order.deliveryCode}',
      if ((order.ordersEstimatedMinutes ?? 0) > 0)
        'الجاهزية: ${order.ordersEstimatedMinutes} دقيقة',
      if ((order.deliveryId ?? 0) > 0) 'المندوب: #${order.deliveryId}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CompactItemsTable extends StatelessWidget {
  final List<OrderItemDetail> items;
  final Map<int, String> itemImagesById;

  const _CompactItemsTable({
    required this.items,
    required this.itemImagesById,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Text('الصنف',
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 1,
                    child: Text('الكمية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 2,
                    child: Text('الإجمالي',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        _OrderItemThumbnail(
                          itemId: item.itemId,
                          imageName: itemImagesById[item.itemId],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      item.quantityWeight != null
                          ? '${item.quantityWeight!.toStringAsFixed(item.quantityWeight == item.quantityWeight!.roundToDouble() ? 0 : 2)} كجم'
                          : '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kTextPrimary, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.lineTotal.toStringAsFixed(2),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          color: kPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
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

class _ExpandedOrderItem extends StatelessWidget {
  final OrderItemDetail item;
  final String? imageName;

  const _ExpandedOrderItem({
    required this.item,
    this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderItemThumbnail(
                itemId: item.itemId,
                imageName: imageName,
                size: 68,
                borderRadius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.itemName,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'الإجمالي الفرعي: ${item.lineTotal.toStringAsFixed(2)} SAR',
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          if (item.hasFoodOptions) ...[
            const SizedBox(height: 6),
            Text(
              'المكونات والإضافات: ${item.foodMenuOptionsSummary!.trim()}',
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (item.hasFoodNote) ...[
            const SizedBox(height: 6),
            Text(
              'ملاحظة العميل: ${item.foodItemNote!.trim()}',
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemThumbnail extends StatelessWidget {
  final int? itemId;
  final String? imageName;
  final double size;
  final double borderRadius;

  const _OrderItemThumbnail({
    this.itemId,
    required this.imageName,
    this.size = 42,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageName != null && imageName!.trim().isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: kStroke),
      ),
      child: hasImage
          ? _FallbackOrderImage(
              itemId: itemId,
              imageName: imageName!,
              size: size,
              borderRadius: borderRadius,
            )
          : _GalleryOrderImage(
              itemId: itemId,
              size: size,
              borderRadius: borderRadius,
            ),
    );
  }
}

class _FallbackOrderImage extends StatelessWidget {
  final int? itemId;
  final String imageName;
  final double size;
  final double borderRadius;

  const _FallbackOrderImage({
    this.itemId,
    required this.imageName,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageName.trim();
    final candidates = <String>[
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
        trimmed,
      'https://savir-technology.online/roaqv2/uploud/items/$trimmed',
      'https://savir-technology.online/roaqv2/uploads/items/$trimmed',
      'https://savir-technology.online/roaqv2/dash/items/add/uploud/items/$trimmed',
    ];

    return _NetworkImageCandidate(
      urls: candidates,
      index: 0,
      size: size,
      borderRadius: borderRadius,
      itemId: itemId,
    );
  }
}

class _NetworkImageCandidate extends StatelessWidget {
  final List<String> urls;
  final int index;
  final double size;
  final double borderRadius;
  final int? itemId;

  const _NetworkImageCandidate({
    required this.urls,
    required this.index,
    required this.size,
    required this.borderRadius,
    this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    if (index >= urls.length) {
      return _GalleryOrderImage(
        itemId: itemId,
        size: size,
        borderRadius: borderRadius,
      );
    }

    return AppNetworkImage(
      imageUrl: urls[index],
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: BorderRadius.circular(borderRadius - 1),
      placeholderIcon: Icons.photo_camera_back_outlined,
      errorReplacement: _NetworkImageCandidate(
        urls: urls,
        index: index + 1,
        size: size,
        borderRadius: borderRadius,
        itemId: itemId,
      ),
    );
  }
}

class _GalleryOrderImage extends StatelessWidget {
  final int? itemId;
  final double size;
  final double borderRadius;

  const _GalleryOrderImage({
    required this.itemId,
    required this.size,
    required this.borderRadius,
  });

  static final Map<int, Future<String?>> _cache = <int, Future<String?>>{};

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    if (id == null || id <= 0) {
      return _fallbackIcon();
    }

    final future = _cache.putIfAbsent(id, () => _fetchFirstGalleryImage(id));

    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return AppNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(borderRadius - 1),
            placeholderIcon: Icons.photo_camera_back_outlined,
            errorReplacement: _fallbackIcon(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return _fallbackIcon();
      },
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.photo_camera_back_outlined,
      size: size * 0.46,
      color: kTextSecondary,
    );
  }

  static Future<String?> _fetchFirstGalleryImage(int itemId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://savir-technology.online/roaqv2/items/images.php?itemid=$itemId',
        ),
      );
      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      if (decoded is! Map || decoded['status'] != 'success') return null;

      final data = decoded['data'];
      if (data is! List || data.isEmpty) return null;

      final first = data.first;
      if (first is! Map) return null;

      final rawPath = first['img_path']?.toString().trim();
      if (rawPath == null || rawPath.isEmpty) return null;

      if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
        return rawPath;
      }

      final normalized =
          rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;

      return 'https://savir-technology.online/roaqv2/$normalized';
    } catch (_) {
      return null;
    }
  }
}

bool _isPendingOrder(OrderModel order) {
  final status = (order.ordersStatus ?? '').trim().toLowerCase();
  return order.lifecycleBucket == 'new' ||
      (status == 'pending' && order.lifecycleBucket != 'scheduled');
}

bool _isScheduledOrder(OrderModel order) =>
    order.lifecycleBucket == 'scheduled';

class _OrderSummaryData {
  final String typeLabel;
  final Color color;

  const _OrderSummaryData({
    required this.typeLabel,
    required this.color,
  });
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'paid'
        ? kAccent
        : normalized == 'pending'
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabelAr(normalized),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _statusLabelAr(String status) {
  switch (status.toLowerCase()) {
    case 'all':
      return 'الكل';
    case 'pending':
      return 'قيد المراجعة';
    case 'paid':
      return 'مؤكد';
    case 'failed':
      return 'فشل';
    case 'new':
      return 'جديد';
    case 'scheduled':
      return 'مجدول';
    case 'preparing':
      return 'قيد التحضير';
    case 'in_delivery':
      return 'في الطريق';
    case 'delivered':
      return 'مكتمل';
    case 'canceled':
      return 'ملغي';
    case 'assigned':
      return 'مُسند';
    case 'arrived_at_restaurant':
      return 'المندوب عند المتجر';
    case 'picked_up':
      return 'تم الاستلام';
    case 'heading_to_customer':
      return 'متجه للعميل';
    case 'arrived_at_customer':
      return 'وصل للعميل';
    default:
      return status;
  }
}

String _scheduledWindowLabelAr(String window) {
  switch (window.toLowerCase()) {
    case 'today':
      return 'اليوم';
    case 'tomorrow':
      return 'غدًا';
    case 'week':
      return 'الأسبوع القادم';
    default:
      return 'الكل';
  }
}

String _formatScheduleDisplay(String raw) {
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
  String dayLabel;
  if (dateOnly == today) {
    dayLabel = 'اليوم';
  } else if (dateOnly == today.add(const Duration(days: 1))) {
    dayLabel = 'غدًا';
  } else if (dateOnly.isAfter(today.add(const Duration(days: 1))) &&
      dateOnly.isBefore(today.add(const Duration(days: 8)))) {
    dayLabel = 'الأسبوع القادم';
  } else {
    dayLabel = '${parsed.year}/${parsed.month}/${parsed.day}';
  }

  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$dayLabel $hour:$minute';
}

Color _lifecycleColor(String status) {
  switch (status.toLowerCase()) {
    case 'scheduled':
      return const Color(0xFF8B5CF6);
    case 'preparing':
      return const Color(0xFFF59E0B);
    case 'in_delivery':
      return const Color(0xFF3B82F6);
    case 'delivered':
      return const Color(0xFF10B981);
    case 'canceled':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF14B8A6);
  }
}

class _OrderChip extends StatelessWidget {
  final String label;
  final Color color;

  const _OrderChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _OrdersNotificationButton extends StatelessWidget {
  const _OrdersNotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final showBadge = unreadCount > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kSurfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kStroke),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: kTextPrimary,
                  size: 22,
                ),
              ),
              if (showBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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

class _OrderHeaderLiveChip extends StatelessWidget {
  const _OrderHeaderLiveChip({
    required this.order,
    required this.relativeLabel,
    required this.onPressed,
  });

  final OrderModel order;
  final String relativeLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4FAF5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC8E4D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F3E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: kPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'طلب ${order.lifecycleLabelAr} #${order.ordersId ?? '-'}',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    relativeLabel,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: kTextSecondary),
          SizedBox(height: 12),
          Text(
            'No orders matched the current filters.',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a simpler search or another status filter.',
            style: TextStyle(color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}
