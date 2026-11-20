import 'package:delvery/core/services/driver_api_service.dart';

class OrderChatMessage {
  const OrderChatMessage({
    required this.chatId,
    required this.orderId,
    required this.chatScope,
    required this.senderRole,
    required this.senderRefId,
    required this.message,
    required this.audioUrl,
    required this.createdAt,
  });

  final int chatId;
  final int orderId;
  final String chatScope;
  final String senderRole;
  final int senderRefId;
  final String message;
  final String? audioUrl;
  final DateTime? createdAt;

  bool get isFromDriver => senderRole.toLowerCase() == 'driver';

  factory OrderChatMessage.fromJson(Map<String, dynamic> json) {
    return OrderChatMessage(
      chatId: int.tryParse(json['chat_id']?.toString() ?? '') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '') ?? 0,
      chatScope: json['chat_scope']?.toString() ?? 'order',
      senderRole: json['sender_role']?.toString() ?? '',
      senderRefId: int.tryParse(json['sender_ref_id']?.toString() ?? '') ?? 0,
      message: json['message']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class DriverOrderChatService {
  DriverOrderChatService(this.api);

  final DriverApiService api;

  Future<List<OrderChatMessage>> fetchMessages({
    required int orderId,
    required String scope,
  }) async {
    final response = await api.fetchOrderChat(orderId: orderId, scope: scope);
    final status = (response['status'] ?? '').toString().toLowerCase();
    if (status != 'success') {
      return const [];
    }

    final raw = response['data'];
    final List<dynamic> data = raw is List ? raw : const <dynamic>[];
    return data
        .whereType<Map>()
        .map((item) => OrderChatMessage.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<bool> sendMessage({
    required int orderId,
    required String scope,
    required int senderId,
    required String senderRole,
    required String message,
    String? audioFilePath,
  }) async {
    final response = await api.sendOrderChatMessage(
      orderId: orderId,
      scope: scope,
      senderId: senderId,
      senderRole: senderRole,
      message: message,
      audioFilePath: audioFilePath,
    );
    return (response['status'] ?? '').toString().toLowerCase() == 'success';
  }
}
