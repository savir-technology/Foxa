import 'dart:async';

import 'package:delvery/core/services/driver_order_voice_call_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/screens/order_voice_call_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';

class DriverOrderVoiceCallAlertService extends GetxService {
  static const MethodChannel _voiceCallIntentChannel = MethodChannel(
    'voice_call_intent',
  );

  final DriverOrdersService _ordersService = Get.find<DriverOrdersService>();
  final DriverSessionService _sessionService = Get.find<DriverSessionService>();
  final DriverOrderVoiceCallService _voiceCallService =
      Get.find<DriverOrderVoiceCallService>();

  StreamSubscription<OrderVoiceCallSession?>? _sessionSub;
  Worker? _activeOrderWorker;
  Worker? _incomingOrderWorker;
  Worker? _driverIdWorker;
  String? _watchedOrderId;
  String? _forcedOrderId;
  String? _lastIncomingSessionKey;
  String? _directOpenOrderId;
  String? _openingScreenOrderId;
  bool _promptOpen = false;
  bool _tonePlaying = false;
  bool _restoredStoredOrder = false;

  @override
  void onInit() {
    super.onInit();
    _activeOrderWorker = ever<DriverOrder?>(
      _ordersService.activeOrder,
      (_) => _syncWatcher(),
    );
    _incomingOrderWorker = ever<DriverOrder?>(
      _ordersService.incomingOrder,
      (_) => _syncWatcher(),
    );
    _driverIdWorker = ever<int?>(_sessionService.driverId, (_) {
      _syncWatcher();
      unawaited(_recheckCurrentSession());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreStoredOrderBinding());
      _syncWatcher();
    });
  }

  void _syncWatcher() {
    final resolvedOrderId = _resolveOrderId();
    debugPrint(
      '[VOICE CALL] _syncWatcher() resolvedOrderId=$resolvedOrderId watchedOrderId=$_watchedOrderId forcedOrderId=$_forcedOrderId',
    );
    if (resolvedOrderId.isEmpty) {
      _watchedOrderId = null;
      unawaited(_sessionSub?.cancel());
      _sessionSub = null;
      _lastIncomingSessionKey = null;
      unawaited(_stopTone());
      _dismissPromptIfOpen();
      return;
    }

    if (_watchedOrderId == resolvedOrderId) {
      return;
    }

    _watchedOrderId = resolvedOrderId;
    unawaited(_sessionSub?.cancel());
    _sessionSub = null;
    _lastIncomingSessionKey = null;
    unawaited(_stopTone());
    _dismissPromptIfOpen();

    _sessionSub = _voiceCallService.watchSession(resolvedOrderId).listen((
      session,
    ) {
      unawaited(_handleSessionUpdate(session));
    });
  }

  String _resolveOrderId() {
    final forcedOrderId = _forcedOrderId?.trim();
    if (forcedOrderId != null &&
        forcedOrderId.isNotEmpty &&
        forcedOrderId != '0') {
      return forcedOrderId;
    }

    final activeOrderId = _ordersService.activeOrder.value?.id
        .toString()
        .trim();
    if (activeOrderId != null &&
        activeOrderId.isNotEmpty &&
        activeOrderId != '0') {
      return activeOrderId;
    }

    final incomingOrderId = _ordersService.incomingOrder.value?.id
        .toString()
        .trim();
    if (incomingOrderId != null &&
        incomingOrderId.isNotEmpty &&
        incomingOrderId != '0') {
      return incomingOrderId;
    }

    return '';
  }

  Future<void> _restoreStoredOrderBinding() async {
    if (_restoredStoredOrder) {
      return;
    }
    for (var attempt = 0; attempt < 20; attempt++) {
      final storedOrderId =
          _sessionService.voiceCallActiveOrderId?.trim() ?? '';
      if (storedOrderId.isNotEmpty && storedOrderId != _forcedOrderId) {
        _restoredStoredOrder = true;
        debugPrint(
          '[VOICE CALL] _restoreStoredOrderBinding() restoredOrderId=$storedOrderId',
        );
        _forcedOrderId = storedOrderId;
        _syncWatcher();
        unawaited(_recheckCurrentSession());
        return;
      }

      await Future.delayed(const Duration(milliseconds: 120));
    }

    _restoredStoredOrder = true;
  }

  Future<void> _handleSessionUpdate(OrderVoiceCallSession? session) async {
    if (session == null) {
      return;
    }

    debugPrint(
      '[VOICE CALL] _handleSessionUpdate() orderId=${session.orderId} status=${session.status} key=${session.stateKey}',
    );
    if (session.isEnded || session.isActive) {
      _lastIncomingSessionKey = null;
      _directOpenOrderId = null;
      await _stopTone();
      _dismissPromptIfOpen();
      if (session.isEnded) {
        unawaited(_sessionService.setVoiceCallActiveOrderId(null));
        // إعادة مزامنة المشاهدة بعد انتهاء المكالمة
        unawaited(Future.microtask(_syncWatcher));
      }
      return;
    }

    final driverId = _sessionService.driverId.value ?? 0;
    if (driverId <= 0) {
      return;
    }

    final sessionKey =
        '${session.orderId}:${session.createdAtMs}:${session.callerId}:${session.calleeId}';
    final isIncoming =
        session.status == 'ringing' &&
        session.isIncomingFor('driver', driverId.toString());

    if (_directOpenOrderId == session.orderId && isIncoming) {
      _lastIncomingSessionKey = sessionKey;
      return;
    }

    if (isIncoming && !_promptOpen && _lastIncomingSessionKey != sessionKey) {
      _lastIncomingSessionKey = sessionKey;
      await _startTone();
      unawaited(_showIncomingVoiceCallSheet(session, driverId: driverId));
      return;
    }

    if (session.status != 'ringing') {
      _lastIncomingSessionKey = null;
      await _stopTone();
      _dismissPromptIfOpen();
    }
  }

  Future<void> _recheckCurrentSession() async {
    final orderId = _resolveOrderId();
    if (orderId.isEmpty) {
      return;
    }

    final session = await _voiceCallService.loadSession(orderId);
    if (session != null) {
      await _handleSessionUpdate(session);
    }
  }

  Future<void> handleVoiceCallSignal({required String orderId}) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      return;
    }

    debugPrint(
      '[VOICE CALL] handleVoiceCallSignal() start orderId=$normalizedOrderId',
    );
    try {
      _forcedOrderId = normalizedOrderId;
      unawaited(_sessionService.setVoiceCallActiveOrderId(normalizedOrderId));
      _syncWatcher();

      final session = await _voiceCallService.loadSession(normalizedOrderId);
      if (session != null) {
        debugPrint(
          '[VOICE CALL] handleVoiceCallSignal() session loaded orderId=$normalizedOrderId status=${session.status}',
        );
        await _handleSessionUpdate(session);
      } else {
        await _recheckCurrentSession();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[VOICE CALL] handleVoiceCallSignal() failed orderId=$normalizedOrderId error=$error',
      );
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> handleNativeIncomingCallIntent(
    Map<String, dynamic> payload,
  ) async {
    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) {
      return;
    }
    debugPrint('[VOICE CALL] session id received orderId=$orderId');

    final action =
        payload['incoming_call_action']?.toString().trim().toLowerCase() ?? '';

    debugPrint(
      '[VOICE CALL] handleNativeIncomingCallIntent() start orderId=$orderId action=$action',
    );
    debugPrint(
      '[VOICE CALL] Flutter opened for native voice call orderId=$orderId action=$action',
    );
    try {
      await _stopTone();
      await _stopNativeRinging();
      _dismissPromptIfOpen();

      if (action == 'reject') {
        _directOpenOrderId = null;
        _forcedOrderId = null;
        unawaited(_sessionService.setVoiceCallActiveOrderId(null));
        _syncWatcher();
        return;
      }

      _forcedOrderId = orderId;
      unawaited(_sessionService.setVoiceCallActiveOrderId(orderId));
      _syncWatcher();

      if (action == 'accept') {
        _directOpenOrderId = orderId;
        try {
          debugPrint(
            '[VOICE CALL] handleNativeIncomingCallIntent() opening call screen directly from native payload orderId=$orderId',
          );
          await _openIncomingCallScreenFromPayload(payload);
        } finally {
          _directOpenOrderId = null;
        }
        return;
      }

      final session = await _waitForSession(orderId);
      if (session == null) {
        await _recheckCurrentSession();
        return;
      }

      await _handleSessionUpdate(session);
    } catch (error, stackTrace) {
      debugPrint(
        '[VOICE CALL] handleNativeIncomingCallIntent() failed orderId=$orderId error=$error',
      );
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  String _extractOrderId(Map<String, dynamic> payload) {
    final candidates = <Object?>[
      payload['order_id'],
      payload['ref_id'],
      payload['notification_ref_id'],
      payload['orderId'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '0' && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '';
  }

  String _payloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '';
  }

  String _normalizeRole(String? value, String fallback) {
    final role = value?.trim().toLowerCase() ?? '';
    if (role.isEmpty || role == 'null') {
      return fallback;
    }
    if (role == 'customer') {
      return 'user';
    }
    return role;
  }

  Future<void> _openIncomingCallScreenFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) {
      return;
    }
    if (_openingScreenOrderId == orderId) {
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreenFromPayload() skipped duplicate orderId=$orderId',
      );
      return;
    }

    _openingScreenOrderId = orderId;
    try {
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreenFromPayload() start orderId=$orderId',
      );
      final driverId = _sessionService.driverId.value ?? 0;
      final driverName = _sessionService.profile.value.name.trim().isNotEmpty
          ? _sessionService.profile.value.name.trim()
          : (Get.locale?.languageCode == 'ar' ? 'السائق' : 'Driver');
      final myRole = _normalizeRole(
        payload['callee_role']?.toString(),
        'driver',
      );
      final peerRole = _normalizeRole(
        payload['caller_role']?.toString(),
        myRole == 'driver' ? 'user' : 'driver',
      );
      final peerId = _payloadString(payload, <String>[
        'caller_ref_id',
        'caller_id',
        'peer_ref_id',
        'peer_id',
      ]);
      final peerName = _payloadString(payload, <String>[
        'caller_name',
        'peer_name',
      ]);

      if (!await _waitForNavigatorReady()) {
        debugPrint(
          '[VOICE CALL] _openIncomingCallScreenFromPayload() navigator not ready orderId=$orderId',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_openIncomingCallScreenFromPayload(payload));
        });
        return;
      }

      debugPrint('[VOICE CALL] call screen opening orderId=$orderId');
      await Get.to(
        () => OrderVoiceCallScreen.incoming(
          orderId: orderId,
          myRole: myRole,
          myId: driverId.toString(),
          myName: driverName,
          peerRole: peerRole,
          peerId: peerId,
          peerName: peerName.isNotEmpty
              ? peerName
              : (peerRole == 'driver'
                    ? (Get.locale?.languageCode == 'ar' ? 'السائق' : 'Driver')
                    : (Get.locale?.languageCode == 'ar'
                          ? 'العميل'
                          : 'Customer')),
          autoAnswer: true,
        ),
      );
      debugPrint('[VOICE CALL] navigation completed orderId=$orderId');
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreenFromPayload() route returned orderId=$orderId',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreenFromPayload() failed orderId=$orderId error=$error',
      );
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      if (_openingScreenOrderId == orderId) {
        _openingScreenOrderId = null;
      }
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreenFromPayload() done orderId=$orderId',
      );
    }
  }

  Future<void> _openIncomingCallScreen(OrderVoiceCallSession session) async {
    final orderId = session.orderId.trim();
    if (orderId.isEmpty) {
      return;
    }
    debugPrint('[VOICE CALL] session id received orderId=$orderId');
    if (_openingScreenOrderId == orderId) {
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreen() skipped duplicate orderId=$orderId',
      );
      return;
    }
    _openingScreenOrderId = orderId;
    try {
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreen() start orderId=$orderId',
      );
      final driverId = _sessionService.driverId.value ?? 0;
      final driverName = _sessionService.profile.value.name.trim().isNotEmpty
          ? _sessionService.profile.value.name.trim()
          : (Get.locale?.languageCode == 'ar'
                ? '\u0627\u0644\u0633\u0627\u0626\u0642'
                : 'Driver');
      final myRole = session.calleeRole.trim().isNotEmpty
          ? session.calleeRole.trim()
          : 'driver';
      final peerRole = session.callerRole.trim().isNotEmpty
          ? session.callerRole.trim()
          : (myRole == 'driver' ? 'user' : 'driver');
      final peerId = session.callerId.trim().isNotEmpty
          ? session.callerId.trim()
          : session.calleeId.trim();
      final peerName = session.callerName.trim().isNotEmpty
          ? session.callerName.trim()
          : (peerRole == 'driver'
                ? (Get.locale?.languageCode == 'ar'
                      ? '\u0627\u0644\u0633\u0627\u0626\u0642'
                      : 'Driver')
                : (Get.locale?.languageCode == 'ar'
                      ? '\u0627\u0644\u0639\u0645\u064a\u0644'
                      : 'Customer'));

      if (!await _waitForNavigatorReady()) {
        debugPrint(
          '[VOICE CALL] _openIncomingCallScreen() navigator not ready orderId=$orderId',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_openIncomingCallScreen(session));
        });
        return;
      }

      debugPrint('[VOICE CALL] call screen opening orderId=$orderId');
      await Get.to(
        () => OrderVoiceCallScreen.incoming(
          orderId: session.orderId,
          myRole: myRole,
          myId: driverId.toString(),
          myName: driverName,
          peerRole: peerRole,
          peerId: peerId,
          peerName: peerName,
        ),
      );
      debugPrint('[VOICE CALL] navigation completed orderId=$orderId');
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreen() route returned orderId=$orderId',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreen() failed orderId=$orderId error=$error',
      );
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      if (_openingScreenOrderId == orderId) {
        _openingScreenOrderId = null;
      }
      debugPrint(
        '[VOICE CALL] _openIncomingCallScreen() done orderId=$orderId',
      );
    }
  }

  Future<bool> _waitForNavigatorReady() async {
    for (var index = 0; index < 20; index++) {
      if (Get.key.currentState != null) {
        return true;
      }

      await Future.delayed(const Duration(milliseconds: 150));
    }

    return false;
  }

  Future<OrderVoiceCallSession?> _waitForSession(String orderId) async {
    OrderVoiceCallSession? session;
    for (var index = 0; index < 12; index++) {
      session = await _voiceCallService.loadSession(orderId);
      if (session != null) {
        return session;
      }

      await Future.delayed(const Duration(milliseconds: 250));
    }

    return null;
  }

  Future<void> _stopNativeRinging() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _voiceCallIntentChannel.invokeMethod<bool>('stopRinging');
    } catch (_) {
      // Native ringtone is best-effort only.
    }
  }

  Future<void> _startTone() async {
    if (_tonePlaying) {
      return;
    }

    try {
      debugPrint('[VOICE CALL] _startTone() start');
      await FlutterRingtonePlayer().playRingtone(
        volume: 1,
        looping: true,
        asAlarm: false,
      );
      _tonePlaying = true;
      debugPrint('[VOICE CALL] _startTone() playing');
    } catch (error) {
      debugPrint('Failed to start driver voice call tone: $error');
      _tonePlaying = false;
    }
  }

  Future<void> _stopTone() async {
    if (!_tonePlaying) {
      return;
    }

    try {
      debugPrint('[VOICE CALL] _stopTone() start');
      await FlutterRingtonePlayer().stop();
    } catch (error) {
      debugPrint('Failed to stop driver voice call tone: $error');
    } finally {
      _tonePlaying = false;
      debugPrint('[VOICE CALL] _stopTone() done');
    }
  }

  void _dismissPromptIfOpen() {
    if (!_promptOpen) {
      return;
    }

    debugPrint('[VOICE CALL] _dismissPromptIfOpen()');
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    _promptOpen = false;
  }

  Future<void> _showIncomingVoiceCallSheet(
    OrderVoiceCallSession session, {
    required int driverId,
  }) async {
    if (_promptOpen) {
      debugPrint(
        '[VOICE CALL] _showIncomingVoiceCallSheet() skipped because prompt already open',
      );
      return;
    }

    final driverName = _sessionService.profile.value.name.trim().isNotEmpty
        ? _sessionService.profile.value.name.trim()
        : (Get.locale?.languageCode == 'ar' ? 'السائق' : 'Driver');

    _promptOpen = true;
    debugPrint(
      '[VOICE CALL] _showIncomingVoiceCallSheet() open orderId=${session.orderId}',
    );
    await Get.bottomSheet(
      Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isArabic = Get.locale?.languageCode == 'ar';
          final callerDisplayName = session.callerName.isNotEmpty
              ? session.callerName
              : (isArabic ? 'العميل' : 'Customer');

          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF08111E).withValues(alpha: 0.98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1D4ED8),
                    child: Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isArabic ? 'مكالمة واردة' : 'Incoming call',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    callerDisplayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'يريد $callerDisplayName التحدث معك الآن بخصوص الطلب #${session.orderId}.'
                        : 'The customer is calling you about order #${session.orderId}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isArabic
                        ? 'المكالمة ستصل إلى $driverName.'
                        : 'The call will ring for $driverName.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            debugPrint(
                              '[VOICE CALL] decline pressed orderId=${session.orderId}',
                            );
                            _dismissPromptIfOpen();
                            await _stopTone();
                            await _voiceCallService.markDeclined(
                              session.orderId,
                            );
                          },
                          icon: const Icon(Icons.call_end_rounded),
                          label: Text(isArabic ? 'رفض' : 'Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            debugPrint(
                              '[VOICE CALL] accept pressed orderId=${session.orderId}',
                            );
                            _dismissPromptIfOpen();
                            await _stopTone();
                            await _openIncomingCallScreen(session);
                          },
                          icon: const Icon(Icons.call_rounded),
                          label: Text(isArabic ? 'قبول' : 'Accept'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF59D98E),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      barrierColor: Colors.black87,
    ).whenComplete(() {
      _promptOpen = false;
    });
  }

  @override
  void onClose() {
    _activeOrderWorker?.dispose();
    _incomingOrderWorker?.dispose();
    _driverIdWorker?.dispose();
    unawaited(_sessionSub?.cancel());
    unawaited(_stopTone());
    super.onClose();
  }
}
