import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tks/controler/notification_con.dart';
import 'package:tks/core/functions/notification_navigation.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('notifications_title'.tr),
        actions: [
          Obx(() {
            if (controller.unreadCount == 0) {
              return const SizedBox.shrink();
            }

            return TextButton(
              onPressed: controller.markAllAsRead,
              child: Text(
                'Mark all read',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = controller.notifications;
        if (items.isEmpty) {
          return Center(
            child: Text(
              'no_notifications_yet'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await controller.markAsRead(item.id);
                  _openNotification(item);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? theme.cardColor
                        : colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.isRead
                          ? theme.dividerColor.withValues(alpha: 0.5)
                          : colors.primary.withValues(alpha: 0.30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                                color: colors.onSurface.withValues(alpha: 0.82),
                              ),
                            ),
                            if (item.createdAt.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(item.createdAt),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatDate(String value) {
    try {
      final parsed = DateTime.parse(value).toLocal();
      return DateFormat('yyyy-MM-dd hh:mm a').format(parsed);
    } catch (_) {
      return value;
    }
  }

  void _openNotification(AppNotificationItem item) {
    openNotificationDestination(
      type: item.type,
      refType: item.refType,
      refId: item.refId,
      payload: item.payload,
      fallbackToInbox: false,
    );
  }
}
