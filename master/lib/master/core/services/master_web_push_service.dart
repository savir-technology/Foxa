import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MasterWebPushService {
  static const _requestTimeout = Duration(seconds: 20);
  static const _vapidKey =
      'BFHRbJJ6THR9RvDiWRWGKLg-EcOJ1cYRL9ZZcVUvwuF8VANlON9H4EADZpEf2Yr2iQaWQ2_Q_3IRQtNx4LQ-D7Y';
  static const _saveTokenUrl =
      'https://savir-technology.online/roaqv2/dash/notifications/save_web_push_token.php';

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _initialized = false;

  Future<void> initialize(String authToken) async {
    if (!kIsWeb || _initialized || authToken.trim().isEmpty) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken(vapidKey: _vapidKey);
    if (token != null && token.trim().isNotEmpty) {
      await http
          .post(
            Uri.parse(_saveTokenUrl),
            headers: {
              'Authorization': 'Bearer ${authToken.trim()}',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({'token': token, 'platform': 'web'}),
          )
          .timeout(_requestTimeout);
    }

    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_playAlert());
    });
  }

  Future<void> _playAlert() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/notification.wav'));
    } catch (error) {
      debugPrint('Master web notification sound failed: $error');
    }
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _player.dispose();
  }
}
