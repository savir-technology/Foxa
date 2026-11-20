import 'dart:math';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/model/admin_notification_model.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/model/restaurant_settings_model.dart';
import 'package:admin_tks/notifications_page.dart';
import 'package:admin_tks/remote/admin_notifications_data.dart';
import 'package:admin_tks/remote/restaurant_settings_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_map_box.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOperationsPage extends StatefulWidget {
  const DeliveryOperationsPage({
    super.key,
    this.sidebarItems,
    this.activeSidebarIndex,
  });

  final List<Map<String, dynamic>>? sidebarItems;
  final int? activeSidebarIndex;

  @override
  State<DeliveryOperationsPage> createState() => _DeliveryOperationsPageState();
}

class _DeliveryOperationsPageState extends State<DeliveryOperationsPage> {
  static const int _rowsPerPage = 5;

  final TextEditingController _searchController = TextEditingController();
  final AdminNotificationsData _notificationsData = AdminNotificationsData();
  final RestaurantSettingsData _settingsData = RestaurantSettingsData();

  AdminNotificationSummary? _notificationSummary;
  RestaurantSettingsSnapshot? _settings;
  bool _metaLoading = true;
  int _currentPage = 0;
  String _statusFilter = 'all';
  String _batchFilter = 'all';

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  OrderController get _orderController => Get.isRegistered<OrderController>()
      ? Get.find<OrderController>()
      : Get.put(OrderController(), permanent: true);

  @override
  void initState() {
    super.initState();
    _orderController.fetchOrders(forceRefresh: false);
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

  List<OrderModel> _activeOrders(List<OrderModel> orders) {
    final active = orders
        .where((order) => !order.isDeliveredOrder && !order.isCancelledOrder)
        .toList();
    active.sort(_compareOrders);
    return active;
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _activeOrders(orders).where((order) {
      final matchesQuery =
          query.isEmpty || _searchHaystack(order).contains(query);
      final matchesStatus = _matchesStatusFilter(order);
      final matchesBatch = _matchesBatchFilter(order);
      return matchesQuery && matchesStatus && matchesBatch;
    }).toList();

    filtered.sort(_compareOrders);
    return filtered;
  }

  String _searchHaystack(OrderModel order) {
    return [
      order.ordersId?.toString() ?? '',
      order.usersName ?? '',
      order.usersEmail ?? '',
      order.addressPhone ?? '',
      order.addressCity ?? '',
      order.driverName ?? '',
      order.driverPhone ?? '',
      order.deliveryCode ?? '',
      order.storeName ?? '',
      order.vendorName ?? '',
      order.ordersGiftMessage ?? '',
      order.ordersDeliveryNote ?? '',
    ].join(' ').toLowerCase();
  }

  bool _matchesStatusFilter(OrderModel order) {
    switch (_statusFilter) {
      case 'pickup':
        return order.isPickup;
      case 'delivery':
        return !order.isPickup;
      case 'ready':
        return order.flowStatusKey == 'arrived_at_restaurant';
      case 'picked_up':
        return order.flowStatusKey == 'picked_up';
      case 'on_route':
        return order.flowStatusKey == 'heading_to_customer';
      case 'arrived':
        return order.flowStatusKey == 'arrived_at_customer';
      case 'in_delivery':
        return order.deliveryId != null &&
            order.deliveryId! > 0 &&
            !order.isDeliveredOrder &&
            !order.isCancelledOrder;
      default:
        return true;
    }
  }

  bool _matchesBatchFilter(OrderModel order) {
    switch (_batchFilter) {
      case 'assigned':
        return (order.deliveryId ?? 0) > 0;
      case 'unassigned':
        return (order.deliveryId ?? 0) <= 0;
      case 'late':
        return _lateMinutes(order) > 0;
      case 'pickup':
        return order.isPickup;
      case 'delivery':
        return !order.isPickup;
      default:
        return true;
    }
  }

  int _compareOrders(OrderModel a, OrderModel b) {
    final aPriority = _statusPriority(a);
    final bPriority = _statusPriority(b);
    if (aPriority != bPriority) return aPriority.compareTo(bPriority);

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

  int _statusPriority(OrderModel order) {
    switch (order.flowStatusKey) {
      case 'arrived_at_restaurant':
        return 0;
      case 'picked_up':
        return 1;
      case 'heading_to_customer':
        return 2;
      case 'arrived_at_customer':
        return 3;
      case 'delivered':
        return 4;
      case 'accepted':
      case 'assigned':
      default:
        return 5;
    }
  }

  int _lateMinutes(OrderModel order) {
    final dateTime = order.orderDateTime ?? order.scheduledDateTime;
    final prepMinutes = order.ordersEstimatedMinutes ?? 0;
    if (dateTime == null || prepMinutes <= 0) {
      return 0;
    }

    final dueAt = dateTime.add(Duration(minutes: prepMinutes));
    return DateTime.now().difference(dueAt).inMinutes;
  }

  int _remainingMinutes(OrderModel order) {
    final dateTime = order.orderDateTime ?? order.scheduledDateTime;
    final prepMinutes = order.ordersEstimatedMinutes ?? 0;
    if (dateTime == null || prepMinutes <= 0) {
      return prepMinutes;
    }

    final dueAt = dateTime.add(Duration(minutes: prepMinutes));
    return dueAt.difference(DateTime.now()).inMinutes;
  }

  String _formatClock(DateTime? value) {
    if (value == null) return '--:--';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $suffix';
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

  String _statusLabel(OrderModel order) {
    switch (order.flowStatusKey) {
      case 'arrived_at_restaurant':
        return 'وصل للمطعم';
      case 'picked_up':
        return 'استلم الطلب';
      case 'heading_to_customer':
        return 'على الطريق';
      case 'arrived_at_customer':
        return 'وصل للسائق';
      case 'delivered':
        return 'تم التسليم';
      case 'accepted':
      case 'assigned':
        return 'قيد التجهيز';
      default:
        return order.isPickup ? 'استلام' : 'توصيل';
    }
  }

  Color _statusTint(OrderModel order) {
    switch (order.flowStatusKey) {
      case 'arrived_at_restaurant':
        return const Color(0xFFF59E0B);
      case 'picked_up':
        return const Color(0xFF10B981);
      case 'heading_to_customer':
        return const Color(0xFF3B82F6);
      case 'arrived_at_customer':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF14B8A6);
      case 'accepted':
      case 'assigned':
        return const Color(0xFF1B7A3A);
      default:
        return kPrimary;
    }
  }

  IconData _statusIcon(OrderModel order) {
    switch (order.flowStatusKey) {
      case 'arrived_at_restaurant':
        return Icons.store_rounded;
      case 'picked_up':
        return Icons.shopping_bag_rounded;
      case 'heading_to_customer':
        return Icons.delivery_dining_rounded;
      case 'arrived_at_customer':
        return Icons.location_on_rounded;
      case 'delivered':
        return Icons.verified_rounded;
      case 'accepted':
      case 'assigned':
        return Icons.schedule_rounded;
      default:
        return order.isPickup
            ? Icons.directions_walk_rounded
            : Icons.home_rounded;
    }
  }

  double _progressValue(OrderModel order) {
    final prepMinutes = order.ordersEstimatedMinutes ?? 0;
    final remaining = _remainingMinutes(order);
    if (prepMinutes <= 0) {
      return 0.0;
    }

    final elapsed = prepMinutes - remaining;
    final ratio = elapsed / prepMinutes;
    return ratio.clamp(0.0, 1.0);
  }

  String _driverLabel(OrderModel order) {
    final name = (order.driverName ?? '').trim();
    if (name.isNotEmpty) return name;
    final id = order.deliveryId ?? 0;
    if (id > 0) return 'مندوب #$id';
    return 'لم يتم التعيين';
  }

  Future<void> _openOrderDetails(OrderModel order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryOrderDetailsPage(
          order: order,
          controller: _orderController,
          sidebarItems: widget.sidebarItems,
          activeSidebarIndex: widget.activeSidebarIndex,
        ),
      ),
    );
    await _orderController.fetchOrders();
  }

  Future<void> _callDriver(OrderModel order) async {
    final phone = (order.driverPhone ?? '').trim();
    if (phone.isEmpty) {
      _showSnack('رقم السائق غير متوفر');
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('تعذر فتح الاتصال');
    }
  }

  Future<void> _chatDriver(OrderModel order) async {
    final phone = (order.driverPhone ?? '').trim();
    if (phone.isEmpty) {
      _showSnack('رقم السائق غير متوفر');
      return;
    }

    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = sanitized.isEmpty
        ? Uri.parse('https://wa.me')
        : Uri.parse('https://wa.me/${sanitized.replaceFirst('+', '')}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openExternalLocation(OrderModel order) async {
    final lat = order.ordersRecipientLat ?? order.storeLatitude;
    final lng = order.ordersRecipientLng ?? order.storeLongitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      _showSnack('الموقع غير متوفر حالياً');
      return;
    }

    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareLocation(OrderModel order) async {
    final lat = order.ordersRecipientLat ?? order.storeLatitude;
    final lng = order.ordersRecipientLng ?? order.storeLongitude;
    if (!dashboardHasMapCoordinates(lat, lng)) {
      _showSnack('الموقع غير متوفر حالياً');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final mapHeight = min(
          MediaQuery.sizeOf(dialogContext).height * 0.56,
          420.0,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.map_rounded, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          order.isPickup ? 'موقع المطعم' : 'موقع العميل',
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DashboardMapBox(
                      latitude: lat,
                      longitude: lng,
                      title: order.isPickup ? 'موقع المطعم' : 'موقع العميل',
                      subtitle: order.isPickup
                          ? (order.storeName ?? order.vendorName ?? '')
                          : _addressLabel(order),
                      height: mapHeight,
                      zoom: 15.4,
                      interactive: true,
                      onOpenExternal: () {
                        _openExternalLocation(order);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _assignDriver(OrderModel order) async {
    final vendorId = order.vendorId ?? _auth.vendorId;
    if (vendorId <= 0) {
      _showSnack('تعذر تحديد المطعم الخاص بالطلب');
      return;
    }

    try {
      final drivers = await _orderController.fetchAvailableDrivers(
        vendorId: vendorId,
        restaurantLatitude: order.storeLatitude,
        restaurantLongitude: order.storeLongitude,
        onlyAvailable: true,
      );

      if (!mounted) return;

      if (drivers.isEmpty) {
        _showSnack('لا يوجد سائقون متاحون حالياً');
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
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      'تعيين مندوب للطلب #${order.ordersId ?? '-'}',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اختر سائقاً متاحاً ليتم إرسال الطلب إليه مباشرة.',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    for (final driver in drivers) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await _orderController.assignOrderToDriver(
                            orderId: order.ordersId ?? 0,
                            driverId: driver.id,
                            vendorId: vendorId,
                          );
                          if (!mounted) return;
                          _showSnack('تم تعيين ${driver.name} للطلب بنجاح');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    kPrimary.withValues(alpha: 0.12),
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
                    ],
                  ],
                ),
              );
            },
          );
        },
      );

      await _orderController.fetchOrders();
    } catch (e) {
      _showSnack('تعذر تعيين السائق: $e');
    }
  }

  void _showFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurfaceElevated,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تصفية الطلبات',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: _batchFilter == 'all',
                        onTap: () => setModalState(() => _batchFilter = 'all'),
                      ),
                      _FilterChip(
                        label: 'بمُندوب',
                        selected: _batchFilter == 'assigned',
                        onTap: () =>
                            setModalState(() => _batchFilter = 'assigned'),
                      ),
                      _FilterChip(
                        label: 'بدون مندوب',
                        selected: _batchFilter == 'unassigned',
                        onTap: () =>
                            setModalState(() => _batchFilter = 'unassigned'),
                      ),
                      _FilterChip(
                        label: 'متأخر',
                        selected: _batchFilter == 'late',
                        onTap: () => setModalState(() => _batchFilter = 'late'),
                      ),
                      _FilterChip(
                        label: 'توصيل',
                        selected: _batchFilter == 'delivery',
                        onTap: () =>
                            setModalState(() => _batchFilter = 'delivery'),
                      ),
                      _FilterChip(
                        label: 'استلام ذاتي',
                        selected: _batchFilter == 'pickup',
                        onTap: () =>
                            setModalState(() => _batchFilter = 'pickup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                      child: const Text('تطبيق الفلاتر'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSidebarTap(int index) {
    final items = widget.sidebarItems;
    if (items == null || index < 0 || index >= items.length) {
      return;
    }
    if (widget.activeSidebarIndex != null &&
        index == widget.activeSidebarIndex) {
      return;
    }

    final item = items[index];
    final route = item['route']?.toString().trim() ?? '';
    if (route.isNotEmpty) {
      Get.offNamed(
        route,
        arguments: item['arguments'],
        preventDuplicates: false,
      );
      return;
    }

    final pageBuilder = item['page'] as Widget Function()?;
    final page = pageBuilder?.call();
    if (page == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _previousPage(int totalPages) {
    if (_currentPage <= 0) return;
    setState(() {
      _currentPage = max(0, _currentPage - 1);
    });
  }

  void _nextPage(int totalPages) {
    if (_currentPage >= totalPages - 1) return;
    setState(() {
      _currentPage = min(totalPages - 1, _currentPage + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allOrders = _orderController.orders.toList(growable: false);
      final activeOrders = _activeOrders(allOrders);
      final latestOrder = activeOrders.isEmpty ? null : activeOrders.first;
      final filteredOrders = _filteredOrders(allOrders);
      final totalPages = filteredOrders.isEmpty
          ? 1
          : ((filteredOrders.length + _rowsPerPage - 1) / _rowsPerPage).ceil();
      final safePage = _currentPage.clamp(0, max(0, totalPages - 1)).toInt();
      if (safePage != _currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _currentPage = safePage);
          }
        });
      }
      final startIndex = safePage * _rowsPerPage;
      final pageOrders = filteredOrders
          .skip(startIndex)
          .take(_rowsPerPage)
          .toList(growable: false);

      final totalDelivery = allOrders
          .where((order) =>
              (order.deliveryId ?? 0) > 0 &&
              !order.isDeliveredOrder &&
              !order.isCancelledOrder)
          .length;
      final onRoute = allOrders
          .where((order) => order.flowStatusKey == 'heading_to_customer')
          .length;
      final pickedUp =
          allOrders.where((order) => order.flowStatusKey == 'picked_up').length;
      final arrivedCustomer = allOrders
          .where((order) => order.flowStatusKey == 'arrived_at_customer')
          .length;
      final arrivedRestaurant = allOrders
          .where((order) => order.flowStatusKey == 'arrived_at_restaurant')
          .length;

      final statusMetrics = <_DeliveryStatusMetric>[
        _DeliveryStatusMetric(
          label: 'وصل للمطعم',
          count: arrivedRestaurant,
          icon: Icons.storefront_outlined,
        ),
        _DeliveryStatusMetric(
          label: 'وصل للسائق',
          count: arrivedCustomer,
          icon: Icons.delivery_dining_rounded,
        ),
        _DeliveryStatusMetric(
          label: 'استلم الطلب',
          count: pickedUp,
          icon: Icons.groups_2_outlined,
        ),
        _DeliveryStatusMetric(
          label: 'على الطريق',
          count: onRoute,
          icon: Icons.location_on_outlined,
        ),
        _DeliveryStatusMetric(
          label: 'قيد التسليم',
          count: totalDelivery,
          icon: Icons.local_shipping_outlined,
        ),
      ];

      final latestChip = latestOrder == null
          ? null
          : _HeaderOrderChip(
              orderNumber: '#${latestOrder.ordersId ?? '-'}',
              statusLabel: _statusLabel(latestOrder),
              timeLabel: _relativeTimeLabel(latestOrder.orderDateTime),
            );

      return DashboardPageShell(
        title: 'إدارة التسليم والاستلام',
        subtitle: 'تابع حالة التسليم والاستلام للطلبات',
        icon: Icons.delivery_dining_rounded,
        sidebarItems: widget.sidebarItems,
        activeSidebarIndex: widget.activeSidebarIndex,
        onSidebarItemTap: _handleSidebarTap,
        profileName:
            _auth.displayName.isNotEmpty ? _auth.displayName : _auth.storeName,
        profileSubtitle: _settings == null
            ? 'جاري تحميل حالة المطعم'
            : (_settings!.isOpen ? 'المطعم مفتوح الآن' : 'المطعم مغلق الآن'),
        profileAvatarUrl: _settings?.vendorLogo,
        actions: [
          if (latestChip != null) latestChip,
          IconButton.filledTonal(
            onPressed: () => Get.to(() => const NotificationsPage()),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded),
                if ((_notificationSummary?.unreadCount ?? 0) > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${_notificationSummary?.unreadCount ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        body: _metaLoading && _orderController.isLoading.value
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeliveryStatusStrip(metrics: statusMetrics),
                  const SizedBox(height: 14),
                  _buildFiltersRow(),
                  const SizedBox(height: 12),
                  if (pageOrders.isEmpty)
                    const DashboardEmptyState(
                      title: 'لا توجد طلبات نشطة مطابقة',
                      subtitle:
                          'جرّب تغيير البحث أو الفلاتر لمشاهدة الطلبات الجارية والتسليمات الحالية.',
                      icon: Icons.inbox_rounded,
                    )
                  else ...[
                    const _DeliveryTableHeader(),
                    const SizedBox(height: 6),
                    for (final order in pageOrders) ...[
                      _DeliveryOrderRowCard(
                        order: order,
                        onOpenDetails: () => _openOrderDetails(order),
                        onCallDriver: () => _callDriver(order),
                        onChatDriver: () => _chatDriver(order),
                        onShareLocation: () => _shareLocation(order),
                        onAssignDriver: () => _assignDriver(order),
                        statusLabel: _statusLabel(order),
                        statusTint: _statusTint(order),
                        statusIcon: _statusIcon(order),
                        driverLabel: _driverLabel(order),
                        timeLabel: _formatClock(order.orderDateTime),
                        relativeTimeLabel:
                            _relativeTimeLabel(order.orderDateTime),
                        lateLabel: _lateMinutes(order) > 0
                            ? 'متأخر ${_lateMinutes(order)} دقيقة'
                            : null,
                        progressValue: _progressValue(order),
                        driverStatusLabel:
                            (order.driverStatus ?? '').trim().isNotEmpty
                                ? order.driverStatus!.trim()
                                : null,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  const SizedBox(height: 6),
                  _PaginationBar(
                    currentPage: safePage + 1,
                    totalPages: totalPages,
                    totalItems: filteredOrders.length,
                    startIndex: filteredOrders.isEmpty ? 0 : startIndex + 1,
                    endIndex: min(filteredOrders.length,
                            startIndex + pageOrders.length)
                        .toInt(),
                    onPrevious: () => _previousPage(totalPages),
                    onNext: () => _nextPage(totalPages),
                    onPageSelected: (page) =>
                        setState(() => _currentPage = page - 1),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildFiltersRow() {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: kStroke),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final searchField = SizedBox(
          height: 44,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 0),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'ابحث برقم الطلب أو اسم العميل أو رقم السائق...',
                suffixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder.copyWith(
                  borderSide: const BorderSide(color: kPrimary, width: 1.2),
                ),
              ),
            ),
          ),
        );

        final dropdown = SizedBox(
          width: stacked ? double.infinity : 220,
          height: 44,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder.copyWith(
                  borderSide: const BorderSide(color: kPrimary, width: 1.2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                DropdownMenuItem(
                    value: 'in_delivery', child: Text('قيد التسليم')),
                DropdownMenuItem(value: 'on_route', child: Text('على الطريق')),
                DropdownMenuItem(
                    value: 'picked_up', child: Text('استلم الطلب')),
                DropdownMenuItem(value: 'ready', child: Text('وصل للمطعم')),
                DropdownMenuItem(value: 'arrived', child: Text('وصل للسائق')),
                DropdownMenuItem(value: 'pickup', child: Text('استلام ذاتي')),
                DropdownMenuItem(value: 'delivery', child: Text('توصيل')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _statusFilter = value;
                  _currentPage = 0;
                });
              },
            ),
          ),
        );

        final filterButton = SizedBox(
          width: stacked ? double.infinity : 190,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _showFiltersSheet,
            icon: const Icon(Icons.tune_rounded, size: 17),
            label: const Text('فلتر الطلبات'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: const BorderSide(color: kStroke),
              foregroundColor: kTextPrimary,
              backgroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              dropdown,
              const SizedBox(height: 10),
              filterButton,
            ],
          );
        }

        return Row(
          textDirection: TextDirection.ltr,
          children: [
            filterButton,
            const SizedBox(width: 16),
            dropdown,
            const SizedBox(width: 16),
            Expanded(child: searchField),
          ],
        );
      },
    );
  }
}

class DeliveryOrderDetailsPage extends StatefulWidget {
  const DeliveryOrderDetailsPage({
    super.key,
    required this.order,
    required this.controller,
    this.sidebarItems,
    this.activeSidebarIndex,
  });

  final OrderModel order;
  final OrderController controller;
  final List<Map<String, dynamic>>? sidebarItems;
  final int? activeSidebarIndex;

  @override
  State<DeliveryOrderDetailsPage> createState() =>
      _DeliveryOrderDetailsPageState();
}

class _DeliveryOrderDetailsPageState extends State<DeliveryOrderDetailsPage> {
  late Future<List<OrderItemDetail>> _itemsFuture;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  int get _vendorId => widget.order.vendorId ?? _auth.vendorId;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.controller.fetchOrderDetails(
      widget.order.ordersId ?? 0,
      vendorId: _vendorId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = widget.controller.fetchOrderDetails(
        widget.order.ordersId ?? 0,
        vendorId: _vendorId,
        forceRefresh: true,
      );
    });
    await widget.controller.fetchOrders();
  }

  void _handleSidebarTap(int index) {
    final items = widget.sidebarItems;
    if (items == null || index < 0 || index >= items.length) {
      return;
    }
    if (widget.activeSidebarIndex != null &&
        index == widget.activeSidebarIndex) {
      return;
    }

    final item = items[index];
    final route = item['route']?.toString().trim() ?? '';
    if (route.isNotEmpty) {
      Get.offNamed(
        route,
        arguments: item['arguments'],
        preventDuplicates: false,
      );
      return;
    }

    final pageBuilder = item['page'] as Widget Function()?;
    final page = pageBuilder?.call();
    if (page == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _callDriver() async {
    final phone = (widget.order.driverPhone ?? '').trim();
    if (phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _messageDriver() async {
    final phone = (widget.order.driverPhone ?? '').trim();
    if (phone.isEmpty) return;
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = sanitized.isEmpty
        ? Uri.parse('https://wa.me')
        : Uri.parse('https://wa.me/${sanitized.replaceFirst('+', '')}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openExternalLocation() async {
    final lat = widget.order.ordersRecipientLat ?? widget.order.storeLatitude;
    final lng = widget.order.ordersRecipientLng ?? widget.order.storeLongitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      return;
    }

    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareLocation() async {
    final order = widget.order;
    final lat = order.ordersRecipientLat ?? order.storeLatitude;
    final lng = order.ordersRecipientLng ?? order.storeLongitude;
    if (!dashboardHasMapCoordinates(lat, lng)) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final mapHeight = min(
          MediaQuery.sizeOf(dialogContext).height * 0.56,
          420.0,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.map_rounded, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          order.isPickup ? 'موقع المطعم' : 'موقع العميل',
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DashboardMapBox(
                      latitude: lat,
                      longitude: lng,
                      title: order.isPickup ? 'موقع المطعم' : 'موقع العميل',
                      subtitle: order.isPickup
                          ? (order.storeName ?? order.vendorName ?? '')
                          : _addressLabel(order),
                      height: mapHeight,
                      zoom: 15.4,
                      interactive: true,
                      onOpenExternal: _openExternalLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _assignDriver() async {
    final vendorId = _vendorId;
    if (vendorId <= 0) return;

    try {
      final drivers = await widget.controller.fetchAvailableDrivers(
        vendorId: vendorId,
        restaurantLatitude: widget.order.storeLatitude,
        restaurantLongitude: widget.order.storeLongitude,
        onlyAvailable: true,
      );

      if (!mounted) return;
      if (drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد سائقون متاحون حالياً')),
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
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      'تعيين مندوب للطلب #${widget.order.ordersId ?? '-'}',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اختر سائقاً متاحاً ليتم إرسال الطلب إليه مباشرة.',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    for (final driver in drivers) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await widget.controller.assignOrderToDriver(
                            orderId: widget.order.ordersId ?? 0,
                            driverId: driver.id,
                            vendorId: vendorId,
                          );
                          if (!mounted) return;
                          await _refresh();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    kPrimary.withValues(alpha: 0.12),
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
                    ],
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تعيين السائق: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final mapLatitude = order.ordersRecipientLat ?? order.storeLatitude;
    final mapLongitude = order.ordersRecipientLng ?? order.storeLongitude;
    final mapTitle = order.isPickup ? 'موقع المطعم' : 'موقع العميل';
    final mapSubtitle = order.isPickup
        ? (order.storeName ?? order.vendorName ?? _addressLabel(order))
        : _addressLabel(order);

    return DashboardPageShell(
      title: 'إدارة التسليم والاستلام',
      subtitle: 'تفاصيل حالة الطلب وحركة السائق',
      icon: Icons.delivery_dining_rounded,
      topPadding: 12,
      sidebarItems: widget.sidebarItems,
      activeSidebarIndex: widget.activeSidebarIndex,
      onSidebarItemTap: _handleSidebarTap,
      actions: [
        _MiniHeaderChip(
          icon: Icons.confirmation_number_rounded,
          label: '#${order.ordersId ?? '-'}',
        ),
        IconButton.filledTonal(
          onPressed: () => Get.to(() => const NotificationsPage()),
          icon: const Icon(Icons.notifications_rounded),
        ),
      ],
      body: FutureBuilder<List<OrderItemDetail>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <OrderItemDetail>[];
          final itemCount = order.ordersItemsCount ?? items.length;
          final orderTypeLabel = order.orderTypeLabel;
          final totalPrice = order.totalPriceValue.toStringAsFixed(0);
          final deliveryCode = (order.deliveryCode ?? '').trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 760;
                  final summaryCard = DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _DeliveryBadge(
                              label: _statusLabel(order),
                              tint: _statusTint(order),
                            ),
                            const Spacer(),
                            Text(
                              '#${order.ordersId ?? '-'}',
                              style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          order.usersName ?? 'عميل غير معروف',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _MiniInfoPill(
                              icon: Icons.shopping_bag_outlined,
                              label: '$itemCount أصناف',
                            ),
                            _MiniInfoPill(
                              icon: Icons.payments_rounded,
                              label: '$totalPrice SAR',
                            ),
                            _MiniInfoPill(
                              icon: order.isPickup
                                  ? Icons.directions_walk_rounded
                                  : Icons.delivery_dining_rounded,
                              label: orderTypeLabel,
                            ),
                            if ((order.addressCity ?? '').trim().isNotEmpty)
                              _MiniInfoPill(
                                icon: Icons.location_on_outlined,
                                label: _addressLabel(order),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );

                  final driverCard = DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بيانات السائق',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: kPrimary.withValues(alpha: 0.1),
                              child: Icon(
                                order.deliveryId != null &&
                                        order.deliveryId! > 0
                                    ? Icons.person_rounded
                                    : Icons.person_off_rounded,
                                size: 28,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.driverName ?? 'لم يتم تعيين سائق',
                                    style: const TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.driverPhone ?? 'رقم السائق غير متوفر',
                                    style: const TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.driverStatus == null ||
                                            order.driverStatus!.trim().isEmpty
                                        ? 'الحالة غير معروفة'
                                        : 'حالة السائق: ${order.driverStatus}',
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MiniInfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'وقت الوصول المتوقع',
                          value: _remainingMinutes(order) > 0
                              ? 'يبقى ${_remainingMinutes(order)} دقيقة'
                              : 'متأخر ${_remainingMinutes(order).abs()} دقيقة',
                          valueColor: _remainingMinutes(order) > 0
                              ? kPrimary
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 8),
                        _MiniInfoRow(
                          icon: Icons.receipt_long_rounded,
                          label: 'وقت الطلب',
                          value: _relativeTimeLabel(order.orderDateTime),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _progressValue(order),
                          minHeight: 4,
                          backgroundColor: kStroke,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progressValue(order) >= 0.95
                                ? const Color(0xFFEF4444)
                                : kPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _progressValue(order) >= 0.95
                                ? 'الطلب تجاوز وقت التحضير المتوقع'
                                : 'يتابع النظام الرحلة لحظياً',
                            style: TextStyle(
                              color: _progressValue(order) >= 0.95
                                  ? const Color(0xFFEF4444)
                                  : kTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  final actionCard = DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            if ((order.driverPhone ?? '').trim().isEmpty) {
                              _assignDriver();
                              return;
                            }
                            _callDriver();
                          },
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: Text(
                            (order.deliveryId ?? 0) > 0
                                ? 'التواصل مع السائق'
                                : 'تعيين سائق',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _callDriver,
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('الاتصال بالسائق'),
                          style: _compactDetailsButtonStyle(),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _shareLocation,
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('عرض موقع السائق'),
                          style: _compactDetailsButtonStyle(),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _messageDriver,
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('مشاركة الموقع'),
                          style: _compactDetailsButtonStyle(),
                        ),
                        const SizedBox(height: 10),
                        DashboardMapBox(
                          latitude: mapLatitude,
                          longitude: mapLongitude,
                          title: mapTitle,
                          subtitle: mapSubtitle,
                          height: 145,
                          zoom: 15.4,
                          interactive: true,
                          onOpenExternal: _openExternalLocation,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBF7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD9E8DC)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: kPrimary, size: 17),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'يمكن متابعة موقع السائق والطلب من هنا مباشرة.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summaryCard,
                        const SizedBox(height: 12),
                        driverCard,
                        const SizedBox(height: 12),
                        actionCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 38, child: summaryCard),
                      const SizedBox(width: 12),
                      Expanded(flex: 28, child: driverCard),
                      const SizedBox(width: 12),
                      Expanded(flex: 24, child: actionCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 760;
                  final itemsPanel = DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'مراحل الطلب',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OrderTimeline(
                          currentStatus: order.flowStatusKey,
                        ),
                      ],
                    ),
                  );

                  final qrPanel = DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          order.isPickup ? 'الاستلام الذاتي' : 'رمز التسليم',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kStroke),
                            ),
                            child: QrImageView(
                              data: deliveryCode.isNotEmpty
                                  ? deliveryCode
                                  : 'order-${order.ordersId ?? 0}',
                              size: 128,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          order.isPickup
                              ? 'بانتظار الاستلام'
                              : _statusLabel(order),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: order.isPickup
                                ? const Color(0xFFF59E0B)
                                : _statusTint(order),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.isPickup
                              ? 'يرجى مسح الرمز لاستلام الطلب من المطعم'
                              : 'تم تجهيز رمز التسليم لمتابعة حالة الطلب',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 10.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );

                  final proofImageUrl =
                      _resolveDeliveryProofImageUrl(order.proofImage);
                  final receiptPanel = DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'إثبات التسليم',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _DeliveryProofImage(
                          imageUrl: proofImageUrl,
                          height: 150,
                        ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: proofImageUrl == null
                              ? null
                              : () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) => Dialog(
                                      backgroundColor: kSurfaceElevated,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 760,
                                          maxHeight: 620,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: _DeliveryProofImage(
                                            imageUrl: proofImageUrl,
                                            height: 520,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.open_in_full_rounded),
                          label: const Text('عرض صورة أكبر'),
                          style: _compactDetailsButtonStyle(),
                        ),
                      ],
                    ),
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        itemsPanel,
                        const SizedBox(height: 12),
                        qrPanel,
                        const SizedBox(height: 12),
                        receiptPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 42, child: itemsPanel),
                      const SizedBox(width: 12),
                      Expanded(flex: 26, child: qrPanel),
                      const SizedBox(width: 12),
                      Expanded(flex: 30, child: receiptPanel),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<OrderItemDetail>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <OrderItemDetail>[];
                  if (items.isEmpty) {
                    return const DashboardEmptyState(
                      title: 'لا توجد عناصر لهذا الطلب',
                      subtitle:
                          'سيتم عرض العناصر بمجرد توفر بياناتها من الخادم.',
                      icon: Icons.shopping_bag_outlined,
                    );
                  }

                  return DashboardPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تفاصيل العناصر',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final item in items) ...[
                          _OrderItemRow(
                            item: item,
                            imageName: null,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تحديث الحالة والبيانات'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _remainingMinutes(OrderModel order) {
    final dateTime = order.orderDateTime ?? order.scheduledDateTime;
    final prepMinutes = order.ordersEstimatedMinutes ?? 0;
    if (dateTime == null || prepMinutes <= 0) {
      return prepMinutes;
    }

    final dueAt = dateTime.add(Duration(minutes: prepMinutes));
    return dueAt.difference(DateTime.now()).inMinutes;
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

  String _statusLabel(OrderModel order) {
    switch (order.flowStatusKey) {
      case 'arrived_at_restaurant':
        return 'وصل للمطعم';
      case 'picked_up':
        return 'استلم الطلب';
      case 'heading_to_customer':
        return 'على الطريق';
      case 'arrived_at_customer':
        return 'وصل للسائق';
      case 'delivered':
        return 'تم التسليم';
      case 'accepted':
      case 'assigned':
        return 'قيد التجهيز';
      default:
        return order.isPickup ? 'استلام' : 'توصيل';
    }
  }

  Color _statusTint(OrderModel order) {
    switch (order.flowStatusKey) {
      case 'arrived_at_restaurant':
        return const Color(0xFFF59E0B);
      case 'picked_up':
        return const Color(0xFF10B981);
      case 'heading_to_customer':
        return const Color(0xFF3B82F6);
      case 'arrived_at_customer':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF14B8A6);
      case 'accepted':
      case 'assigned':
        return const Color(0xFF1B7A3A);
      default:
        return kPrimary;
    }
  }

  double _progressValue(OrderModel order) {
    final prepMinutes = order.ordersEstimatedMinutes ?? 0;
    final remaining = _remainingMinutes(order);
    if (prepMinutes <= 0) {
      return 0.0;
    }

    final elapsed = prepMinutes - remaining;
    final ratio = elapsed / prepMinutes;
    return ratio.clamp(0.0, 1.0);
  }
}

String _addressLabel(OrderModel order) {
  final pieces = <String>[
    if ((order.addressStreet ?? '').trim().isNotEmpty)
      order.addressStreet!.trim(),
    if ((order.addressCity ?? '').trim().isNotEmpty) order.addressCity!.trim(),
  ];

  if (pieces.isEmpty) return 'العنوان غير متاح';
  return pieces.join('، ');
}

String? _resolveDeliveryProofImageUrl(String? rawPath) {
  final trimmed = rawPath?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    return null;
  }

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('data:image/')) {
    return trimmed;
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return Uri.encodeFull(trimmed);
  }

  final normalized =
      trimmed.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.startsWith('zahra/')) {
    return Uri.encodeFull(
      'https://savir-technology.online/roaqv2/${normalized.substring('zahra/'.length)}',
    );
  }
  if (normalized.startsWith('del/uploads/')) {
    return Uri.encodeFull('https://savir-technology.online/roaqv2/$normalized');
  }
  if (normalized.startsWith('uploads/proofs/')) {
    return Uri.encodeFull(
        'https://savir-technology.online/roaqv2/del/$normalized');
  }
  if (normalized.startsWith('uploads/') || normalized.startsWith('uploud/')) {
    return Uri.encodeFull('https://savir-technology.online/roaqv2/$normalized');
  }
  if (!normalized.contains('/')) {
    return Uri.encodeFull(
      'https://savir-technology.online/roaqv2/del/uploads/proofs/$normalized',
    );
  }

  return Uri.encodeFull('https://savir-technology.online/roaqv2/$normalized');
}

ButtonStyle _compactDetailsButtonStyle() {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, 34),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    textStyle: const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
    ),
    side: const BorderSide(color: kStroke),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _DeliveryProofImage extends StatelessWidget {
  const _DeliveryProofImage({
    required this.imageUrl,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: url == null || url.isEmpty
            ? const _DeliveryProofPlaceholder(
                icon: Icons.add_a_photo_outlined,
                title: 'لم يرفع السائق صورة التسليم بعد',
              )
            : AppNetworkImage(
                imageUrl: url,
                width: double.infinity,
                height: height,
                fit: fit,
                placeholderIcon: Icons.receipt_long_rounded,
                errorReplacement: const _DeliveryProofPlaceholder(
                  icon: Icons.broken_image_outlined,
                  title: 'تعذر تحميل صورة التسليم',
                ),
              ),
      ),
    );
  }
}

class _DeliveryProofPlaceholder extends StatelessWidget {
  const _DeliveryProofPlaceholder({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: kTextSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? kPrimary : kTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: kPrimary.withValues(alpha: 0.16),
      side: BorderSide(color: selected ? kPrimary : kStroke),
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _HeaderOrderChip extends StatelessWidget {
  const _HeaderOrderChip({
    required this.orderNumber,
    required this.statusLabel,
    required this.timeLabel,
  });

  final String orderNumber;
  final String statusLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.waves_rounded, color: kPrimary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$orderNumber $statusLabel',
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
        ],
      ),
    );
  }
}

class _MiniHeaderChip extends StatelessWidget {
  const _MiniHeaderChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = kTextPrimary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPrimary, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.currentStatus});

  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _TimelineStep(
        title: 'السائق متجه للمطعم',
        icon: Icons.delivery_dining_rounded,
        statusKey: 'assigned',
      ),
      const _TimelineStep(
        title: 'السائق وصل للمطعم',
        icon: Icons.store_rounded,
        statusKey: 'arrived_at_restaurant',
      ),
      const _TimelineStep(
        title: 'تم استلام الطلب',
        icon: Icons.shopping_bag_rounded,
        statusKey: 'picked_up',
      ),
      const _TimelineStep(
        title: 'في الطريق',
        icon: Icons.route_rounded,
        statusKey: 'heading_to_customer',
      ),
      const _TimelineStep(
        title: 'تم التسليم',
        icon: Icons.verified_rounded,
        statusKey: 'delivered',
      ),
    ];

    final currentIndex = _currentTimelineIndex(currentStatus);

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: _TimelineNode(
              step: steps[index],
              isActive: index <= currentIndex,
              isLast: index == steps.length - 1,
              index: index + 1,
            ),
          ),
          if (index != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 16),
                color: index < currentIndex ? kPrimary : kStroke,
              ),
            ),
        ],
      ],
    );
  }

  int _currentTimelineIndex(String status) {
    switch (status) {
      case 'delivered':
        return 4;
      case 'arrived_at_customer':
        return 3;
      case 'heading_to_customer':
        return 3;
      case 'picked_up':
        return 2;
      case 'arrived_at_restaurant':
        return 1;
      case 'accepted':
      case 'assigned':
      default:
        return 0;
    }
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.icon,
    required this.statusKey,
  });

  final String title;
  final IconData icon;
  final String statusKey;
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.step,
    required this.isActive,
    required this.isLast,
    required this.index,
  });

  final _TimelineStep step;
  final bool isActive;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tint = isActive ? kPrimary : kTextSecondary;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? kPrimary.withValues(alpha: 0.12) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? kPrimary : kStroke, width: 2),
          ),
          child: Icon(step.icon, color: tint, size: 18),
        ),
        const SizedBox(height: 6),
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? kPrimary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? kPrimary : kStroke),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: isActive ? Colors.white : kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? kPrimary : kTextSecondary,
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            height: 1.4,
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
  });

  final OrderItemDetail item;
  final String? imageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 52,
              height: 52,
              color: const Color(0xFFF4F7FB),
              child: imageName == null || imageName!.trim().isEmpty
                  ? const Icon(Icons.fastfood_rounded, color: kTextSecondary)
                  : Image.asset(
                      'assets/img/restaurant.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fastfood_rounded,
                        color: kTextSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الكمية: ${item.quantity}',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.lineTotal.toStringAsFixed(2),
            style: const TextStyle(
              color: kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) {
      return const SizedBox.shrink();
    }

    final pageNumbers = List<int>.generate(totalPages, (index) => index + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: currentPage > 1 ? onPrevious : null,
                child: const Text('السابق'),
              ),
              const SizedBox(width: 8),
              for (final page in pageNumbers) ...[
                InkWell(
                  onTap: () => onPageSelected(page),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: page == currentPage ? kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: page == currentPage ? kPrimary : kStroke,
                      ),
                    ),
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color:
                            page == currentPage ? Colors.white : kTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              TextButton(
                onPressed: currentPage < totalPages ? onNext : null,
                child: const Text('التالي'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            'عرض $startIndex - $endIndex من $totalItems طلب',
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryOrderRowCard extends StatelessWidget {
  const _DeliveryOrderRowCard({
    required this.order,
    required this.onOpenDetails,
    required this.onCallDriver,
    required this.onChatDriver,
    required this.onShareLocation,
    required this.onAssignDriver,
    required this.statusLabel,
    required this.statusTint,
    required this.statusIcon,
    required this.driverLabel,
    required this.timeLabel,
    required this.relativeTimeLabel,
    required this.progressValue,
    this.lateLabel,
    this.driverStatusLabel,
  });

  final OrderModel order;
  final VoidCallback onOpenDetails;
  final VoidCallback onCallDriver;
  final VoidCallback onChatDriver;
  final VoidCallback onShareLocation;
  final VoidCallback onAssignDriver;
  final String statusLabel;
  final Color statusTint;
  final IconData statusIcon;
  final String driverLabel;
  final String timeLabel;
  final String relativeTimeLabel;
  final double progressValue;
  final String? lateLabel;
  final String? driverStatusLabel;

  int _remainingMinutes(OrderModel order) {
    final dateTime = order.orderDateTime ?? order.scheduledDateTime;
    final prepMinutes = order.ordersEstimatedMinutes ?? 0;
    if (dateTime == null || prepMinutes <= 0) return prepMinutes;
    return dateTime
        .add(Duration(minutes: prepMinutes))
        .difference(DateTime.now())
        .inMinutes;
  }

  String _distanceLabel(OrderModel order) {
    final storeLat = order.storeLatitude;
    final storeLng = order.storeLongitude;
    final clientLat = order.ordersRecipientLat;
    final clientLng = order.ordersRecipientLng;
    if (order.isPickup ||
        storeLat == null ||
        storeLng == null ||
        clientLat == null ||
        clientLng == null ||
        (storeLat == 0 && storeLng == 0) ||
        (clientLat == 0 && clientLng == 0)) {
      return relativeTimeLabel;
    }

    const earthRadiusKm = 6371.0;
    final dLat = (clientLat - storeLat) * pi / 180;
    final dLng = (clientLng - storeLng) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(storeLat * pi / 180) *
            cos(clientLat * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final distanceKm = earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
    return 'يبعد ${distanceKm.toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = order.ordersItemsCount ?? 0;
    final itemText = itemCount == 1 ? 'صنف واحد' : '$itemCount أصناف';
    final totalPrice = order.totalPriceValue.toStringAsFixed(0);
    final hasDriver = (order.deliveryId ?? 0) > 0;
    final remaining = max(0, _remainingMinutes(order));
    final etaLabel = lateLabel ?? '$remaining دقيقة';
    final etaColor = lateLabel == null ? kPrimary : const Color(0xFFDC2626);
    final distanceLabel = _distanceLabel(order);
    final typeIcon =
        order.isPickup ? Icons.directions_walk_rounded : Icons.home_rounded;
    final typeColor =
        order.isPickup ? const Color(0xFFF59E0B) : const Color(0xFF1B7A3A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kStroke),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final stacked = screenWidth < 900 && constraints.maxWidth < 760;

          final orderDetails = _DeliveryTableCell(
            flex: 30,
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(typeIcon, size: 25, color: typeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            '#${order.ordersId ?? '-'}',
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          _DeliveryRowStatusBadge(
                            label: statusLabel,
                            color: statusTint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.usersName ?? 'عميل غير معروف',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$itemText  •  $totalPrice SAR',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _DeliveryRowButton(
                        label: 'عرض التفاصيل',
                        icon: Icons.open_in_new_rounded,
                        onPressed: onOpenDetails,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final driver = _DeliveryTableCell(
            flex: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DeliveryDriverAvatar(hasDriver: hasDriver),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            driverLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.driverPhone ?? 'رقم غير متوفر',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (driverStatusLabel != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              driverStatusLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusTint,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _DeliveryRowButton(
                  label: hasDriver ? 'عرض على الخريطة' : 'تعيين',
                  icon: hasDriver ? Icons.map_outlined : Icons.add_rounded,
                  onPressed: hasDriver ? onShareLocation : onAssignDriver,
                ),
              ],
            ),
          );

          final eta = _DeliveryTableCell(
            flex: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  etaLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: etaColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 3,
                    backgroundColor: kStroke,
                    valueColor: AlwaysStoppedAnimation<Color>(etaColor),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  distanceLabel,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

          final status = _DeliveryTableCell(
            flex: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusTint, size: 22),
                const SizedBox(height: 7),
                Text(
                  statusLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusTint,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );

          final actions = _DeliveryTableCell(
            flex: 20,
            showDivider: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DeliveryRowButton(
                  label: hasDriver ? 'تواصل مع السائق' : 'تعيين سائق',
                  icon: hasDriver
                      ? Icons.support_agent_rounded
                      : Icons.person_add_alt_1_rounded,
                  onPressed: hasDriver ? onChatDriver : onAssignDriver,
                  filled: true,
                ),
                const SizedBox(height: 5),
                _DeliveryRowButton(
                  label: 'الاتصال بالسائق',
                  icon: Icons.call_rounded,
                  onPressed: hasDriver ? onCallDriver : onAssignDriver,
                ),
                const SizedBox(height: 5),
                _DeliveryRowButton(
                  label: 'مشاركة الموقع',
                  icon: Icons.share_location_rounded,
                  onPressed: onShareLocation,
                ),
              ],
            ),
          );

          if (stacked) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [orderDetails]),
                  const Divider(height: 16),
                  Row(children: [driver]),
                  const Divider(height: 16),
                  Row(children: [eta]),
                  const Divider(height: 16),
                  Row(children: [status]),
                  const Divider(height: 16),
                  Row(children: [actions]),
                ],
              ),
            );
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  orderDetails,
                  driver,
                  eta,
                  status,
                  actions,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryStatusMetric {
  const _DeliveryStatusMetric({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;
}

class _DeliveryStatusStrip extends StatelessWidget {
  const _DeliveryStatusStrip({required this.metrics});

  final List<_DeliveryStatusMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kStroke),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 9, 16, 0),
              child: Text(
                'حالات الطلب',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    Expanded(child: _DeliveryMetricTile(metric: metrics[i])),
                    if (i != metrics.length - 1)
                      Container(width: 1, height: 50, color: kStroke),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryMetricTile extends StatelessWidget {
  const _DeliveryMetricTile({required this.metric});

  final _DeliveryStatusMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: kPrimary, size: 14),
            const SizedBox(width: 5),
            Text(
              metric.label,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(metric.icon, color: kPrimary, size: 20),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '${metric.count}',
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DeliveryTableHeader extends StatelessWidget {
  const _DeliveryTableHeader();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            Expanded(flex: 30, child: _DeliveryHeaderText('تفاصيل الطلب')),
            Expanded(flex: 28, child: _DeliveryHeaderText('السائق')),
            Expanded(
                flex: 20, child: _DeliveryHeaderText('وقت الوصول المتوقع')),
            Expanded(flex: 18, child: _DeliveryHeaderText('الحالة')),
            Expanded(flex: 20, child: _DeliveryHeaderText('الإجراءات')),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHeaderText extends StatelessWidget {
  const _DeliveryHeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DeliveryTableCell extends StatelessWidget {
  const _DeliveryTableCell({
    required this.flex,
    required this.child,
    this.showDivider = true,
  });

  final int flex;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        constraints: const BoxConstraints(minHeight: 98),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: BorderDirectional(
            end: showDivider
                ? const BorderSide(color: kStroke)
                : BorderSide.none,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DeliveryDriverAvatar extends StatelessWidget {
  const _DeliveryDriverAvatar({required this.hasDriver});

  final bool hasDriver;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: hasDriver
          ? kPrimary.withValues(alpha: 0.10)
          : const Color(0xFFE5E7EB),
      child: Icon(
        hasDriver ? Icons.person_rounded : Icons.person_off_rounded,
        color: hasDriver ? kPrimary : kTextSecondary,
        size: 20,
      ),
    );
  }
}

class _DeliveryRowStatusBadge extends StatelessWidget {
  const _DeliveryRowStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DeliveryRowButton extends StatelessWidget {
  const _DeliveryRowButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
    const textStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w800);

    if (filled) {
      return SizedBox(
        height: 29,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            textStyle: textStyle,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 7),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 27,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kPrimary),
          textStyle: textStyle,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 7),
        ),
        child: child,
      ),
    );
  }
}
