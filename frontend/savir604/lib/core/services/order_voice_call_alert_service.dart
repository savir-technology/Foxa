import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:tks/core/services/order_voice_call_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/view/screen/order_voice_call_screen.dart';

/// Keeps the active order voice-call session synchronized with the UI.
///
/// This service is intentionally small and owns only alert/navigation state;
/// the WebRTC implementation remains in [OrderVoiceCallService].
class OrderVoiceCallAlertService extends GetxService {
  static const MethodChannel _voiceCallIntentChannel =
      MethodChannel('voice_call_intent');

  final OrderVoiceCallService _voiceCallService =
      Get.put(OrderVoiceCallService(), permanent: true);
  StreamSubscription<OrderVoiceCallSession?>? _sessionSubscription;
  String? _activeOrderId;
  String? _lastSessionKey;
  bool _promptOpen = false;
  bool _ringtonePlaying = false;

  String? get activeOrderId => _activeOrderId;

  @override
  void onClose() {
    unawaited(_sessionSubscription?.cancel());
    unawaited(_stopRingtone());
    super.onClose();
  }

  void bindActiveOrderId(String orderId) {
    final normalized = orderId.trim();
    if (normalized.isEmpty || normalized == '0') return;
    if (_activeOrderId == normalized && _sessionSubscription != null) return;

    _activeOrderId = normalized;
    _lastSessionKey = null;
    unawaited(_sessionSubscription?.cancel());
    _sessionSubscription = _voiceCallService.watchSession(normalized).listen(
      (session) => unawaited(_handleSession(session)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[VOICE CALL] session watcher error: $error');
      },
    );
    unawaited(_saveActiveOrderId(normalized));
  }

  Future<void> handleVoiceCallSignal({required String orderId}) async {
    bindActiveOrderId(orderId);
    final session = await _voiceCallService.loadSession(orderId.trim());
    await _handleSession(session);
  }

  Future<void> handleNativeIncomingCallIntent(
    Map<String, dynamic> payload,
  ) async {
    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) return;

    final action =
        payload['incoming_call_action']?.toString().trim().toLowerCase() ?? '';
    if (action == 'reject') {
      await _stopRingtone();
      await _voiceCallService.markDeclined(orderId);
      return;
    }

    bindActiveOrderId(orderId);
    if (action == 'accept') {
      final session = await _loadSessionWithRetry(orderId);
      if (session != null) {
        await _openIncomingCall(session, autoAnswer: true);
      } else {
        debugPrint('[VOICE CALL] opening from native payload orderId=$orderId');
        await _openIncomingCallFromPayload(payload);
      }
      return;
    }

    await handleVoiceCallSignal(orderId: orderId);
  }

  Future<OrderVoiceCallSession?> _loadSessionWithRetry(String orderId) async {
    for (var attempt = 1; attempt <= 8; attempt++) {
      final session = await _voiceCallService.loadSession(orderId);
      if (session != null) {
        debugPrint(
          '[VOICE CALL] accept session loaded attempt=$attempt orderId=$orderId status=${session.status}',
        );
        return session;
      }
      if (attempt < 8) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    return null;
  }

  Future<void> _openIncomingCallFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final services = Get.find<MyServices>();
    final userId = services.sharedPreferences.getInt('id') ?? 0;
    final userName = services.sharedPreferences.getString('username') ?? '';
    final callerId = _payloadValue(payload, const [
      'caller_ref_id',
      'caller_id',
      'peer_ref_id',
      'peer_id',
    ]);
    final callerName = _payloadValue(payload, const [
      'caller_name',
      'peer_name',
    ]);
    await Get.to(() => OrderVoiceCallScreen.incoming(
          orderId: _extractOrderId(payload),
          myRole: 'user',
          myId: userId.toString(),
          myName: userName,
          peerRole: payload['caller_role']?.toString().trim().isNotEmpty == true
              ? payload['caller_role'].toString()
              : 'driver',
          peerId: callerId,
          peerName: callerName,
          autoAnswer: true,
        ));
  }

  String _payloadValue(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  Future<void> _handleSession(OrderVoiceCallSession? session) async {
    if (session == null) return;

    if (session.isEnded || session.isActive) {
      await _stopRingtone();
      _closePrompt();
      if (session.isEnded) {
        _lastSessionKey = null;
        await _clearActiveOrderId();
      }
      return;
    }

    final userId = Get.find<MyServices>().sharedPreferences.getInt('id') ?? 0;
    final sessionKey =
        '${session.orderId}:${session.createdAtMs}:${session.callerId}:${session.calleeId}';
    if (session.status == 'ringing' &&
        session.isIncomingFor('user', userId.toString()) &&
        !_promptOpen &&
        _lastSessionKey != sessionKey) {
      _lastSessionKey = sessionKey;
      await _startRingtone();
      unawaited(_showIncomingCallPrompt(session));
    } else if (session.status != 'ringing') {
      _lastSessionKey = null;
      await _stopRingtone();
      _closePrompt();
    }
  }

  Future<void> _showIncomingCallPrompt(OrderVoiceCallSession session) async {
    if (_promptOpen || Get.key.currentState == null) return;
    _promptOpen = true;
    final isArabic = Get.locale?.languageCode == 'ar';
    final callerName = session.callerName.trim().isNotEmpty
        ? session.callerName.trim()
        : (isArabic ? 'السائق' : 'Driver');
    await Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.call_rounded, size: 30),
              ),
              const SizedBox(height: 12),
              Text(isArabic ? 'مكالمة واردة' : 'Incoming call',
                  style: Get.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(callerName),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        _closePrompt();
                        await _stopRingtone();
                        await _voiceCallService.markDeclined(session.orderId);
                      },
                      icon: const Icon(Icons.call_end),
                      label: Text(isArabic ? 'رفض' : 'Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        _closePrompt();
                        await _stopRingtone();
                        await _openIncomingCall(session);
                      },
                      icon: const Icon(Icons.call),
                      label: Text(isArabic ? 'قبول' : 'Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    ).whenComplete(() => _promptOpen = false);
  }

  Future<void> _openIncomingCall(
    OrderVoiceCallSession session, {
    bool autoAnswer = false,
  }) async {
    final services = Get.find<MyServices>();
    final userId = services.sharedPreferences.getInt('id') ?? 0;
    final userName = services.sharedPreferences.getString('username') ?? '';
    await Get.to(() => OrderVoiceCallScreen.incoming(
          orderId: session.orderId,
          myRole: 'user',
          myId: userId.toString(),
          myName: userName,
          peerRole: session.callerRole.trim().isNotEmpty
              ? session.callerRole
              : 'driver',
          peerId: session.callerId,
          peerName: session.callerName,
          autoAnswer: autoAnswer,
        ));
  }

  String _extractOrderId(Map<String, dynamic> payload) {
    for (final key in const ['order_id', 'ref_id', 'notification_ref_id', 'orderId']) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '0' && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  void _closePrompt() {
    if (_promptOpen && Get.isBottomSheetOpen == true) Get.back();
    _promptOpen = false;
  }

  Future<void> _startRingtone() async {
    if (_ringtonePlaying) return;
    try {
      await FlutterRingtonePlayer().playRingtone(looping: true, volume: 1);
      _ringtonePlaying = true;
    } catch (error) {
      debugPrint('[VOICE CALL] ringtone start failed: $error');
    }
  }

  Future<void> _stopRingtone() async {
    if (!_ringtonePlaying) return;
    try {
      await FlutterRingtonePlayer().stop();
    } catch (error) {
      debugPrint('[VOICE CALL] ringtone stop failed: $error');
    } finally {
      _ringtonePlaying = false;
    }
  }

  Future<void> _saveActiveOrderId(String orderId) async {
    if (Get.isRegistered<MyServices>()) {
      await Get.find<MyServices>().sharedPreferences.setString(
            MyServices.keyVoiceCallActiveOrderId,
            orderId,
          );
    }
  }

  Future<void> _clearActiveOrderId() async {
    _activeOrderId = null;
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    if (Get.isRegistered<MyServices>()) {
      await Get.find<MyServices>().sharedPreferences.remove(
            MyServices.keyVoiceCallActiveOrderId,
          );
    }
  }

  Future<void> _stopNativeRinging() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _voiceCallIntentChannel.invokeMethod<bool>('stopRinging');
    } catch (_) {}
  }
}
