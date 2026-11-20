import 'dart:convert';

import 'package:delvery/core/localization/driver_text.dart';

class DriverNotificationSummary {
  const DriverNotificationSummary({
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
    required this.ordersCount,
    required this.supportCount,
    required this.systemCount,
  });

  factory DriverNotificationSummary.fromJson(Map<String, dynamic> json) {
    return DriverNotificationSummary(
      totalCount: int.tryParse(json['total_count']?.toString() ?? '') ?? 0,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      readCount: int.tryParse(json['read_count']?.toString() ?? '') ?? 0,
      ordersCount: int.tryParse(json['orders_count']?.toString() ?? '') ?? 0,
      supportCount: int.tryParse(json['support_count']?.toString() ?? '') ?? 0,
      systemCount: int.tryParse(json['system_count']?.toString() ?? '') ?? 0,
    );
  }

  final int totalCount;
  final int unreadCount;
  final int readCount;
  final int ordersCount;
  final int supportCount;
  final int systemCount;
}

class DriverNotificationItem {
  const DriverNotificationItem({
    required this.notificationId,
    required this.driverId,
    required this.type,
    required this.title,
    required this.body,
    required this.refType,
    required this.refId,
    required this.payload,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverNotificationItem.fromJson(Map<String, dynamic> json) {
    return DriverNotificationItem(
      notificationId:
          int.tryParse(json['notification_id']?.toString() ?? '') ?? 0,
      driverId: int.tryParse(json['driver_id']?.toString() ?? '') ?? 0,
      type: json['notification_type']?.toString() ?? 'general',
      title: json['notification_title']?.toString() ?? tx('إشعار'),
      body: json['notification_body']?.toString() ?? '',
      refType: json['notification_ref_type']?.toString() ?? '',
      refId: int.tryParse(json['notification_ref_id']?.toString() ?? '') ?? 0,
      payload: _decodePayload(json['notification_payload']),
      isRead: (json['notification_is_read']?.toString() ?? '0') == '1',
      createdAt: DateTime.tryParse(
        json['notification_created_at']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        json['notification_updated_at']?.toString() ?? '',
      ),
    );
  }

  final int notificationId;
  final int driverId;
  final String type;
  final String title;
  final String body;
  final String refType;
  final int refId;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isUnread => !isRead;

  bool get isSupport =>
      type.toLowerCase().contains('support') ||
      refType.toLowerCase() == 'support';

  bool get isOrder =>
      type.toLowerCase().contains('order') ||
      type.toLowerCase().contains('delivery') ||
      refType.toLowerCase() == 'order';

  String get displayRefLabel {
    if (isSupport) {
      return tx('الدعم الفني');
    }
    if (isOrder && refId > 0) {
      return trParam('طلب #{id}', 'Order #{id}', {'id': refId});
    }
    if (refType.trim().isNotEmpty) {
      return refType.trim();
    }
    return tx('تحديث عام');
  }

  String get displayBody {
    final trimmed = body.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    if (payload.isNotEmpty) {
      return payload.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(isDriverArabic ? ' • ' : ' • ');
    }

    return title;
  }
}

class DriverSupportMessage {
  const DriverSupportMessage({
    required this.supportMessageId,
    required this.driverId,
    required this.senderRole,
    required this.message,
    required this.audioUrl,
    required this.isReadByDriver,
    required this.isReadByAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverSupportMessage.fromJson(Map<String, dynamic> json) {
    return DriverSupportMessage(
      supportMessageId:
          int.tryParse(json['support_message_id']?.toString() ?? '') ?? 0,
      driverId: int.tryParse(json['driver_id']?.toString() ?? '') ?? 0,
      senderRole: json['sender_role']?.toString() ?? 'driver',
      message: json['message']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString(),
      isReadByDriver: (json['is_read_by_driver']?.toString() ?? '0') == '1',
      isReadByAdmin: (json['is_read_by_admin']?.toString() ?? '0') == '1',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  final int supportMessageId;
  final int driverId;
  final String senderRole;
  final String message;
  final String? audioUrl;
  final bool isReadByDriver;
  final bool isReadByAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFromDriver => senderRole.toLowerCase() == 'driver';
  bool get isFromAdmin => senderRole.toLowerCase() == 'admin';
  bool get hasAudio =>
      audioUrl != null && audioUrl!.trim().isNotEmpty;
  bool get hasText => message.trim().isNotEmpty;
}

Map<String, dynamic> _decodePayload(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', value));
  }
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {}
  }
  return <String, dynamic>{};
}
