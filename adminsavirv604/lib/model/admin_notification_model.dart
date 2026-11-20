class AdminNotification {
  AdminNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      notificationId: int.tryParse(json['notification_id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['notification_userid']?.toString() ?? '') ?? 0,
      type: json['notification_type']?.toString() ?? 'general',
      title: json['notification_title']?.toString() ?? 'إشعار',
      body: json['notification_body']?.toString() ?? '',
      isRead: (int.tryParse(json['notification_is_read']?.toString() ?? '') ?? 0) == 1,
      createdAt: json['notification_created_at']?.toString() ?? '',
    );
  }

  final int notificationId;
  final int userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;
}

class AdminNotificationSummary {
  AdminNotificationSummary({
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
  });

  factory AdminNotificationSummary.fromJson(Map<String, dynamic> json) {
    return AdminNotificationSummary(
      totalCount: int.tryParse(json['total_count']?.toString() ?? '') ?? 0,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      readCount: int.tryParse(json['read_count']?.toString() ?? '') ?? 0,
    );
  }

  final int totalCount;
  final int unreadCount;
  final int readCount;
}

class AdminNotificationResponse {
  AdminNotificationResponse({
    required this.summary,
    required this.rows,
  });

  final AdminNotificationSummary summary;
  final List<AdminNotification> rows;
}

