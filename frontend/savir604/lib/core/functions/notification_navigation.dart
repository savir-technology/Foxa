import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/view/screen/support.dart';
import 'package:tks/view/screen/video_feed_page.dart';

void openNotificationDestination({
  required String type,
  String refType = '',
  String refId = '',
  Map<String, dynamic> payload = const {},
  bool fallbackToInbox = true,
}) {
  final currentUserId = Get.find<MyServices>().sharedPreferences.getInt('id') ?? 0;
  final resolvedOrderId =
      refId.trim().isNotEmpty ? refId.trim() : '${payload['order_id'] ?? ''}'.trim();

  if (type == 'admin_chat') {
    Get.to(() => SupportHome(userId: currentUserId));
    return;
  }

  if (type == 'new_video' || type == 'comment_reply' || type == 'comment_like') {
    Get.to(() => const VideoFeedPage());
    return;
  }

  if (type == 'new_product') {
    Get.toNamed(AppRoutes.homepage);
    return;
  }

  if (type == 'order_chat_message' ||
      refType == 'order_chat' ||
      '${payload['screen'] ?? ''}' == 'order_chat') {
    if (resolvedOrderId.isNotEmpty) {
      debugPrint(
        '[FCM] open order chat notification orderId=$resolvedOrderId type=$type refType=$refType',
      );
      final orderArgs = <String, dynamic>{...payload};
      orderArgs['orders_id'] = resolvedOrderId;
      Get.toNamed(
        AppRoutes.orderChat,
        arguments: orderArgs,
      );
      return;
    }
  }

  if (type == 'order_status' ||
      type == 'payment_status' ||
      type == 'delivery_update' ||
      refType == 'order') {
    if (resolvedOrderId.isNotEmpty) {
      Get.toNamed(
        AppRoutes.orderTracking,
        arguments: {
          'orders_id': resolvedOrderId,
          'orders_status':
              '${payload['status'] ?? payload['order_status'] ?? 'pending'}',
          'orders_totalprice': '${payload['total'] ?? payload['amount'] ?? '0'}',
          'orders_share_token': '${payload['share_token'] ?? ''}',
          'orders_estimated_minutes': '${payload['estimated_minutes'] ?? '45'}',
          'orders_type': '${payload['orders_type'] ?? '0'}',
          'orders_recipient_name': '${payload['recipient_name'] ?? ''}',
          'orders_gift_message': '${payload['gift_message'] ?? ''}',
          'orders_delivery_note': '${payload['delivery_note'] ?? ''}',
        },
      );
      return;
    }

    Get.toNamed(AppRoutes.ordersarchive_page);
    return;
  }

  if (fallbackToInbox) {
    Get.toNamed(AppRoutes.notificationPage);
  }
}
