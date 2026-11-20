import 'dart:convert';

import 'package:http/http.dart' as http;

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

  bool get isFromVendor => senderRole.toLowerCase() == 'vendor';

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

class OrderChatData {
  OrderChatData({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _baseUrl = 'https://savir-technology.online/roaqv2';

  Future<List<OrderChatMessage>> fetchMessages({
    required int orderId,
    required String scope,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/chat/order/get_messages.php?order_id=$orderId&chat_scope=$scope',
    );
    final response = await _client.get(uri);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> ||
        (decoded['status'] ?? '').toString().toLowerCase() != 'success') {
      return const [];
    }

    final raw = decoded['data'];
    final List<dynamic> data = raw is List ? raw : const <dynamic>[];
    return data
        .whereType<Map>()
        .map((item) => OrderChatMessage.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<bool> sendMessage({
    required int orderId,
    required String scope,
    required int senderId,
    required String senderRole,
    required String message,
    String? audioFilePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/chat/order/send_message.php'),
    )
      ..fields['order_id'] = orderId.toString()
      ..fields['chat_scope'] = scope
      ..fields['sender_ref_id'] = senderId.toString()
      ..fields['sender_role'] = senderRole
      ..fields['message'] = message;

    if (audioFilePath != null && audioFilePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFilePath),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map<String, dynamic> &&
        (decoded['status'] ?? '').toString().toLowerCase() == 'success';
  }
}
