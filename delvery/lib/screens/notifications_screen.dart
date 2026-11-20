import 'dart:async';

import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_api_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_inbox_models.dart';
import 'package:delvery/screens/help_screen.dart';
import 'package:delvery/screens/order_chat_screen.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:delvery/core/localization/driver_text.dart';

String _friendlyNotificationErrorMessage(String message, String fallback) {
  final normalized = message.trim();
  if (normalized.isEmpty) {
    return fallback;
  }
  if (normalized.startsWith('Bad state:')) {
    return normalized.replaceFirst('Bad state:', '').trim();
  }
  if (normalized.startsWith('Exception:')) {
    return normalized.replaceFirst('Exception:', '').trim();
  }
  return normalized;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final DriverApiService _api;
  late final DriverSessionService _session;
  Timer? _pollTimer;

  final List<DriverNotificationItem> _items = [];
  DriverNotificationSummary _summary = const DriverNotificationSummary(
    totalCount: 0,
    unreadCount: 0,
    readCount: 0,
    ordersCount: 0,
    supportCount: 0,
    systemCount: 0,
  );
  String _filter = 'all';
  bool _loading = true;
  bool _markingAll = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = Get.find<DriverApiService>();
    _session = Get.find<DriverSessionService>();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        _refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final driverId = _session.driverId.value ?? 0;
    if (driverId <= 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = tx('لم يتم العثور على هوية السائق بعد.');
        _items.clear();
      });
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _api.fetchDriverNotifications(driverId: driverId);
      final status = (response['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMessage = _friendlyNotificationErrorMessage(
            (response['message'] ?? tx('تعذر تحميل الإشعارات')).toString(),
            tx('تعذر تحميل الإشعارات حالياً.'),
          );
        });
        return;
      }

      final summaryMap =
          (response['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
      final raw = response['data'];
      final data = raw is List ? raw : const <dynamic>[];
      final items = data
          .whereType<Map>()
          .map(
            (item) => DriverNotificationItem.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _summary = DriverNotificationSummary.fromJson(summaryMap);
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _friendlyNotificationErrorMessage(
          error.toString(),
          tx('تعذر تحميل الإشعارات حالياً.'),
        );
      });
    }
  }

  Future<void> _markNotificationRead(DriverNotificationItem item) async {
    if (item.isRead) {
      return;
    }

    final driverId = _session.driverId.value ?? 0;
    if (driverId <= 0) {
      return;
    }

    try {
      await _api.markDriverNotificationRead(
        driverId: driverId,
        notificationId: item.notificationId,
      );
      await _refresh(silent: true);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _summary.unreadCount <= 0) {
      return;
    }

    final driverId = _session.driverId.value ?? 0;
    if (driverId <= 0) {
      return;
    }

    setState(() => _markingAll = true);
    try {
      await _api.markAllDriverNotificationsRead(driverId: driverId);
      await _refresh(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tx('تم تحديد كل الإشعارات كمقروءة'))),
      );
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  List<DriverNotificationItem> get _filteredItems {
    return _items.where((item) {
      switch (_filter) {
        case 'orders':
          return item.isOrder;
        case 'support':
          return item.isSupport;
        case 'system':
          return !item.isOrder && !item.isSupport;
        default:
          return true;
      }
    }).toList(growable: false);
  }

  String _filterLabel(String key) {
    switch (key) {
      case 'orders':
        return tx('الطلبات');
      case 'support':
        return tx('الدعم');
      case 'system':
        return tx('النظام');
      default:
        return tx('الكل');
    }
  }

  bool _isOrderChatNotification(DriverNotificationItem item) {
    final type = item.type.toLowerCase();
    final refType = item.refType.toLowerCase();
    final screen = item.payload['screen']?.toString().toLowerCase() ?? '';
    return type == 'order_chat_message' ||
        refType == 'order_chat' ||
        screen == 'order_chat';
  }

  Future<void> _openNotification(DriverNotificationItem item) async {
    await _markNotificationRead(item);
    if (!mounted) {
      return;
    }

    if (_isOrderChatNotification(item)) {
      final ordersService = Get.find<DriverOrdersService>();
      final activeOrder = ordersService.activeOrder.value;
      if (activeOrder != null) {
        debugPrint(
          '[FCM] Driver notifications screen opening order chat orderId=${activeOrder.id} notificationId=${item.notificationId}',
        );
        Get.to(() => OrderChatScreen(order: activeOrder));
      } else {
        debugPrint(
          '[FCM] Driver notifications screen falling back to current order for chat notificationId=${item.notificationId}',
        );
        Get.toNamed(AppRoutes.currentOrder);
      }
      return;
    }

    if (item.isSupport) {
      Get.to(() => const HelpScreen(embedInShell: true));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: DriverUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _tintFor(item).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFor(item), color: _tintFor(item)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: DriverUi.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.displayRefLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: DriverUi.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.displayBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DriverUi.text,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatWhen(item.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DriverUi.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              if (item.isOrder)
                DriverPrimaryButton(
                  label: tx('فهمت'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.check_rounded,
                  minHeight: 52,
                )
              else
                DriverSecondaryButton(
                  label: tx('إغلاق'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.close_rounded,
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final isCompact = MediaQuery.of(context).size.width < 420;

    return Scaffold(
      backgroundColor: DriverUi.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: DriverUi.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              DriverHeaderBar(
                leadingIcon: widget.embedInShell
                    ? Icons.notifications_none_rounded
                    : Icons.arrow_back_rounded,
                trailingIcon: Icons.refresh_rounded,
                onLeadingTap: widget.embedInShell
                    ? () {}
                    : () => Navigator.of(context).maybePop(),
                onTrailingTap: _loading ? null : () => _refresh(),
              ),
              const SizedBox(height: 14),
              DriverPageHeader(
                title: tx('الإشعارات'),
                subtitle: tx('متابعة دقيقة لكل ما يحدث على الطلبات والدعم وحساب السائق.'),
              ),
              const SizedBox(height: 18),
              DriverCard(
                color: DriverUi.surfaceWarm,
                borderColor: DriverUi.line,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: DriverUi.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                color: DriverUi.primary,
                              ),
                              if (_summary.unreadCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE24B4B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trParam(
                                  '{count} إشعار غير مقروء',
                                  '{count} unread notifications',
                                  {'count': _summary.unreadCount},
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: DriverUi.text,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trParam(
                                  'إجمالي {count} عنصر داخل المركز',
                                  '{count} total items in the center',
                                  {'count': _summary.totalCount},
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: DriverUi.mutedText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed:
                              _summary.unreadCount > 0 && !_markingAll
                                  ? _markAllRead
                                  : null,
                          child: Text(
                            _markingAll ? tx('جارٍ...') : tx('تحديد الكل'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricChip(
                          label: tx('الطلبات'),
                          value: _summary.ordersCount,
                          color: const Color(0xFF0F766E),
                        ),
                        _MetricChip(
                          label: tx('الدعم'),
                          value: _summary.supportCount,
                          color: const Color(0xFFB45309),
                        ),
                        _MetricChip(
                          label: tx('النظام'),
                          value: _summary.systemCount,
                          color: const Color(0xFF2563EB),
                        ),
                        _MetricChip(
                          label: tx('المقروء'),
                          value: _summary.readCount,
                          color: const Color(0xFF166534),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterChip(
                    label: _filterLabel('all'),
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  _FilterChip(
                    label: _filterLabel('orders'),
                    selected: _filter == 'orders',
                    onTap: () => setState(() => _filter = 'orders'),
                  ),
                  _FilterChip(
                    label: _filterLabel('support'),
                    selected: _filter == 'support',
                    onTap: () => setState(() => _filter = 'support'),
                  ),
                  _FilterChip(
                    label: _filterLabel('system'),
                    selected: _filter == 'system',
                    onTap: () => setState(() => _filter = 'system'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading && _items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 72),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                DriverEmptyStateCard(
                  icon: Icons.cloud_off_rounded,
                  title: tx('تعذر تحميل الإشعارات'),
                  subtitle: _errorMessage!,
                  actionLabel: tx('إعادة المحاولة'),
                  onAction: _refresh,
                )
              else if (items.isEmpty)
                DriverEmptyStateCard(
                  icon: Icons.notifications_off_rounded,
                  title: tx('لا توجد إشعارات حالياً'),
                  subtitle:
                      tx('عندما تصل تحديثات جديدة على الطلبات أو الدعم ستظهر هنا بشكل مرتب وواضح.'),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      item: item,
                      onTap: () => _openNotification(item),
                      icon: _iconFor(item),
                      tint: _tintFor(item),
                      relativeTime: _formatWhen(item.createdAt),
                    ),
                  ),
                ),
              if (!isCompact) const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(DriverNotificationItem item) {
    if (item.isSupport) {
      return Icons.headset_mic_rounded;
    }
    if (item.isOrder) {
      return Icons.local_shipping_rounded;
    }

    final type = item.type.toLowerCase();
    if (type.contains('security')) {
      return Icons.shield_rounded;
    }
    if (type.contains('system') || type.contains('update')) {
      return Icons.system_update_alt_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _tintFor(DriverNotificationItem item) {
    if (item.isSupport) {
      return const Color(0xFFB45309);
    }
    if (item.isOrder) {
      return DriverUi.primary;
    }
    final type = item.type.toLowerCase();
    if (type.contains('security')) {
      return const Color(0xFFB91C1C);
    }
    if (type.contains('system')) {
      return const Color(0xFF2563EB);
    }
    return DriverUi.primaryMuted;
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
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor:
          selected ? DriverUi.primary.withValues(alpha: 0.12) : DriverUi.surface,
      side: BorderSide(
        color: selected ? DriverUi.primary : DriverUi.line,
        width: selected ? 1.2 : 1,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? DriverUi.primary : DriverUi.mutedText,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DriverUi.mutedText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.icon,
    required this.tint,
    required this.relativeTime,
  });

  final DriverNotificationItem item;
  final VoidCallback onTap;
  final IconData icon;
  final Color tint;
  final String relativeTime;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: DriverUi.text,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          if (item.isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE24B4B),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.displayBody,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: item.isUnread
                                  ? DriverUi.text
                                  : DriverUi.mutedText,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniTag(label: item.displayRefLabel),
                          _MiniTag(label: relativeTime),
                          _MiniTag(
                            label: item.isUnread ? tx('غير مقروء') : tx('مقروء'),
                            tint: item.isUnread
                                ? const Color(0xFFE24B4B)
                                : const Color(0xFF166534),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left_rounded,
                  color: DriverUi.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    this.tint,
  });

  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? DriverUi.primaryMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _formatWhen(DateTime? dateTime) {
  if (dateTime == null) {
    return tx('الآن');
  }

  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) {
    return tx('الآن');
  }
  if (diff.inMinutes < 60) {
    return trParam(
      'منذ {count} دقيقة',
      '{count} minutes ago',
      {'count': diff.inMinutes},
    );
  }
  if (diff.inHours < 24) {
    return trParam(
      'منذ {count} ساعة',
      '{count} hours ago',
      {'count': diff.inHours},
    );
  }
  if (diff.inDays < 7) {
    return trParam(
      'منذ {count} يوم',
      '{count} days ago',
      {'count': diff.inDays},
    );
  }

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month';
}
