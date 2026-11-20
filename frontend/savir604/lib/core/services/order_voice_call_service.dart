import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:tks/core/services/voice_call_trace.dart';
import 'package:tks/linkapi/linkapi.dart';

class OrderVoiceCallSession {
  const OrderVoiceCallSession({
    required this.orderId,
    required this.status,
    required this.callerRole,
    required this.callerId,
    required this.callerName,
    required this.calleeRole,
    required this.calleeId,
    required this.calleeName,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.offer,
    this.answer,
    this.callerCandidates = const <Map<String, dynamic>>[],
    this.calleeCandidates = const <Map<String, dynamic>>[],
  });

  final String orderId;
  final String status;
  final String callerRole;
  final String callerId;
  final String callerName;
  final String calleeRole;
  final String calleeId;
  final String calleeName;
  final int createdAtMs;
  final int updatedAtMs;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final List<Map<String, dynamic>> callerCandidates;
  final List<Map<String, dynamic>> calleeCandidates;

  bool get isRinging => status == 'ringing';
  bool get isActive => status == 'active';
  bool get isFailed => status == 'failed';
  bool get isEnded =>
      status.toLowerCase() == 'ended' ||
      status.toLowerCase() == 'declined' ||
      status.toLowerCase() == 'missed' ||
      status.toLowerCase() == 'failed';

  bool isForRole(String role) => role == callerRole || role == calleeRole;

  bool isIncomingFor(String role, String myId) {
    if (!isRinging) {
      return false;
    }
    
    // التحقق من أن دور المستخدم يتطابق مع دور المتلقى
    final normalizedRole = role.trim().toLowerCase();
    final normalizedCalleeRole = calleeRole.trim().toLowerCase();
    if (normalizedRole != normalizedCalleeRole && normalizedRole != 'user' && normalizedCalleeRole != 'user') {
      return false;
    }
    
    // التحقق من أن المستخدم هو المتلقى
    final targetId = calleeId.trim();
    if (targetId.isEmpty ||
        targetId == '0' ||
        targetId.toLowerCase() == 'null' ||
        targetId == myId.trim()) {
      return true;
    }
    return false;
  }

  List<Map<String, dynamic>> remoteCandidatesFor(String role) {
    final normalizedRole = role.trim().toLowerCase();
    final normalizedCallerRole = callerRole.trim().toLowerCase();
    final normalizedCalleeRole = calleeRole.trim().toLowerCase();

    if (normalizedRole.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    if (normalizedRole == normalizedCallerRole) {
      return calleeCandidates;
    }

    if (normalizedRole == normalizedCalleeRole) {
      return callerCandidates;
    }

    if (normalizedRole == 'driver') {
      return calleeCandidates;
    }

    return callerCandidates;
  }

  String get stateKey {
    final offerType = offer?['type']?.toString() ?? '';
    final offerSdp = offer?['sdp']?.toString() ?? '';
    final answerType = answer?['type']?.toString() ?? '';
    final answerSdp = answer?['sdp']?.toString() ?? '';
    final callerCandidateTail = callerCandidates.isNotEmpty
        ? callerCandidates.last['candidateId']?.toString() ??
            callerCandidates.last['timestampMs']?.toString() ??
            callerCandidates.length.toString()
        : '';
    final calleeCandidateTail = calleeCandidates.isNotEmpty
        ? calleeCandidates.last['candidateId']?.toString() ??
            calleeCandidates.last['timestampMs']?.toString() ??
            calleeCandidates.length.toString()
        : '';

    return <String>[
      status,
      createdAtMs.toString(),
      updatedAtMs.toString(),
      offerType,
      offerSdp,
      answerType,
      answerSdp,
      callerCandidates.length.toString(),
      calleeCandidates.length.toString(),
      callerCandidateTail,
      calleeCandidateTail,
    ].join('|');
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'status': status,
      'callerRole': callerRole,
      'callerId': callerId,
      'callerName': callerName,
      'calleeRole': calleeRole,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      if (offer != null) 'offer': offer,
      if (answer != null) 'answer': answer,
      'callerCandidates': callerCandidates,
      'calleeCandidates': calleeCandidates,
    };
  }

  factory OrderVoiceCallSession.fromMap(Map<String, dynamic> map) {
    return OrderVoiceCallSession(
      orderId: map['orderId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'idle',
      callerRole: map['callerRole']?.toString() ?? '',
      callerId: map['callerId']?.toString() ?? '',
      callerName: map['callerName']?.toString() ?? '',
      calleeRole: map['calleeRole']?.toString() ?? '',
      calleeId: map['calleeId']?.toString() ?? '',
      calleeName: map['calleeName']?.toString() ?? '',
      createdAtMs: int.tryParse(map['createdAtMs']?.toString() ?? '') ?? 0,
      updatedAtMs: int.tryParse(map['updatedAtMs']?.toString() ?? '') ?? 0,
      offer: _mapOrNull(map['offer']),
      answer: _mapOrNull(map['answer']),
      callerCandidates: _listOfMaps(
        map['callerCandidates'] ?? map['caller_candidates'],
      ),
      calleeCandidates: _listOfMaps(
        map['calleeCandidates'] ?? map['callee_candidates'],
      ),
    );
  }

  static Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, innerValue) => MapEntry('$key', innerValue));
    }
    return null;
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList(growable: false);
    }

    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList(growable: false);
    }

    return const <Map<String, dynamic>>[];
  }
}

class OrderVoiceCallService {
  OrderVoiceCallService();

  static final Uri _endpoint = Uri.parse(
    '${AppLink.server}/calls/order_voice_call_events.php',
  );
  static const Duration _pollInterval = Duration(milliseconds: 800);

  Map<String, Object?> _sessionSummary(OrderVoiceCallSession session) {
    return <String, Object?>{
      'orderId': session.orderId,
      'status': session.status,
      'callerRole': session.callerRole,
      'callerId': session.callerId,
      'calleeRole': session.calleeRole,
      'calleeId': session.calleeId,
      'createdAtMs': session.createdAtMs,
      'updatedAtMs': session.updatedAtMs,
      'hasOffer': session.offer != null,
      'hasAnswer': session.answer != null,
      'callerCandidateCount': session.callerCandidates.length,
      'calleeCandidateCount': session.calleeCandidates.length,
    };
  }

  Map<String, Object?> _candidateSummary(RTCIceCandidate candidate) {
    return <String, Object?>{
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };
  }

  Future<OrderVoiceCallSession?> loadSession(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      return null;
    }

    try {
      VoiceCallTrace.log(
        'loadSession() request',
        data: <String, Object?>{
          'orderId': normalizedOrderId,
          'endpoint': _endpoint.toString(),
        },
      );
      final response = await http
          .get(
            _endpoint.replace(
              queryParameters: <String, String>{'order_id': normalizedOrderId},
            ),
          )
          .timeout(const Duration(seconds: 15));

      VoiceCallTrace.log(
        'loadSession() response',
        data: <String, Object?>{
          'orderId': normalizedOrderId,
          'statusCode': response.statusCode,
          'bodyLength': response.body.length,
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }

      final payload = decoded.map((key, value) => MapEntry('$key', value));
      if (payload['status']?.toString().toLowerCase() != 'success') {
        return null;
      }

      final rawData = payload['data'];
      if (rawData is! Map) {
        return null;
      }

      final data = rawData.map((key, value) => MapEntry('$key', value));
      final sessionRaw = data['session'];
      if (sessionRaw is! Map) {
        return null;
      }

      final session = OrderVoiceCallSession.fromMap(
        sessionRaw.map((key, value) => MapEntry('$key', value)),
      );
      VoiceCallTrace.log(
        'loadSession() parsed session',
        data: _sessionSummary(session),
      );
      return session;
    } catch (error, stackTrace) {
      VoiceCallTrace.error(
        'loadSession() failed',
        error,
        stackTrace,
        data: <String, Object?>{'orderId': normalizedOrderId},
      );
      return null;
    }
  }

  Stream<OrderVoiceCallSession?> watchSession(String orderId) async* {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      return;
    }

    VoiceCallTrace.log(
      'watchSession() start',
      data: <String, Object?>{
        'orderId': normalizedOrderId,
        'pollIntervalMs': _pollInterval.inMilliseconds,
      },
    );
    OrderVoiceCallSession? lastSession;
    while (true) {
      final current = await loadSession(normalizedOrderId);
      if (current?.stateKey != lastSession?.stateKey) {
        VoiceCallTrace.log(
          'watchSession() update',
          data: <String, Object?>{
            'orderId': normalizedOrderId,
            'previousStatus': lastSession?.status,
            'currentStatus': current?.status,
            'previousKey': lastSession?.stateKey,
            'currentKey': current?.stateKey,
          },
        );
        yield current;
        lastSession = current;
      }
      await Future.delayed(_pollInterval);
    }
  }

  Future<void> createSession(OrderVoiceCallSession session) async {
    VoiceCallTrace.log(
      'createSession() request',
      data: _sessionSummary(session),
    );
    await _sendForm(
      <String, String>{
        'action': 'session_upsert',
        'order_id': session.orderId.trim(),
        'status': session.status,
        'caller_role': session.callerRole,
        'caller_ref_id': session.callerId,
        'caller_name': session.callerName,
        'callee_role': session.calleeRole,
        'callee_ref_id': session.calleeId,
        'callee_name': session.calleeName,
        'created_at_ms': session.createdAtMs.toString(),
        'updated_at_ms': session.updatedAtMs.toString(),
        'offer_json': jsonEncode(session.offer ?? const <String, dynamic>{}),
      },
      extraBody: {
        if (session.answer != null)
          'answer_json':
              jsonEncode(session.answer ?? const <String, dynamic>{}),
      },
    );
    VoiceCallTrace.log(
      'createSession() sent',
      data: _sessionSummary(session),
    );

    unawaited(
      _logEvent(
        orderId: session.orderId,
        eventType: 'created',
        status: session.status,
        callerRole: session.callerRole,
        callerId: session.callerId,
        callerName: session.callerName,
        calleeRole: session.calleeRole,
        calleeId: session.calleeId,
        calleeName: session.calleeName,
        eventAtMs: session.createdAtMs,
      ),
    );
  }

  Future<void> patchSession(
    String orderId,
    Map<String, dynamic> data,
  ) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      return;
    }

    final body = <String, String>{
      'action': 'session_patch',
      'order_id': normalizedOrderId,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final status = data['status']?.toString().trim();
    if (status != null && status.isNotEmpty) {
      body['status'] = status;
    }

    if (data.containsKey('offer')) {
      body['offer_json'] =
          jsonEncode(data['offer'] ?? const <String, dynamic>{});
    }

    if (data.containsKey('answer')) {
      body['answer_json'] =
          jsonEncode(data['answer'] ?? const <String, dynamic>{});
    }

    VoiceCallTrace.log(
      'patchSession() request',
      data: <String, Object?>{
        'orderId': normalizedOrderId,
        'status': body['status'],
        'fields': body.keys.toList(growable: false),
      },
    );
    await _sendForm(body);
    VoiceCallTrace.log(
      'patchSession() sent',
      data: <String, Object?>{
        'orderId': normalizedOrderId,
        'status': body['status'],
      },
    );
  }

  Future<void> updateOffer({
    required String orderId,
    required Map<String, dynamic> offer,
  }) async {
    await patchSession(orderId, {'offer': offer});
  }

  Future<void> updateAnswer({
    required String orderId,
    required Map<String, dynamic> answer,
  }) async {
    VoiceCallTrace.log(
      'updateAnswer() request',
      data: <String, Object?>{
        'orderId': orderId.trim(),
        'hasSdp': (answer['sdp']?.toString().trim().isNotEmpty ?? false),
      },
    );
    await patchSession(orderId, {'answer': answer, 'status': 'active'});
    VoiceCallTrace.log(
      'updateAnswer() sent',
      data: <String, Object?>{'orderId': orderId.trim(), 'status': 'active'},
    );
    VoiceCallTrace.log(
      'backend updated',
      data: <String, Object?>{
        'orderId': orderId.trim(),
        'operation': 'updateAnswer',
        'status': 'active',
      },
    );
    unawaited(
      _logEvent(
        orderId: orderId,
        eventType: 'answered',
        status: 'active',
      ),
    );
  }

  Future<void> markEnded(String orderId) async {
    VoiceCallTrace.log(
      'markEnded() request',
      data: <String, Object?>{'orderId': orderId.trim()},
    );
    await patchSession(orderId, {'status': 'ended'});
    VoiceCallTrace.log(
      'markEnded() sent',
      data: <String, Object?>{'orderId': orderId.trim(), 'status': 'ended'},
    );
    VoiceCallTrace.log(
      'backend updated',
      data: <String, Object?>{
        'orderId': orderId.trim(),
        'operation': 'markEnded',
        'status': 'ended',
      },
    );
    unawaited(
      _logEvent(
        orderId: orderId,
        eventType: 'ended',
        status: 'ended',
      ),
    );
  }

  Future<void> markDeclined(String orderId) async {
    VoiceCallTrace.log(
      'markDeclined() request',
      data: <String, Object?>{'orderId': orderId.trim()},
    );
    await patchSession(orderId, {'status': 'declined'});
    VoiceCallTrace.log(
      'markDeclined() sent',
      data: <String, Object?>{'orderId': orderId.trim(), 'status': 'declined'},
    );
    VoiceCallTrace.log(
      'backend updated',
      data: <String, Object?>{
        'orderId': orderId.trim(),
        'operation': 'markDeclined',
        'status': 'declined',
      },
    );
    unawaited(
      _logEvent(
        orderId: orderId,
        eventType: 'declined',
        status: 'declined',
      ),
    );
  }

  Future<void> markMissed(String orderId) async {
    VoiceCallTrace.log(
      'markMissed() request',
      data: <String, Object?>{'orderId': orderId.trim()},
    );
    await patchSession(orderId, {'status': 'missed'});
    VoiceCallTrace.log(
      'markMissed() sent',
      data: <String, Object?>{'orderId': orderId.trim(), 'status': 'missed'},
    );
    VoiceCallTrace.log(
      'backend updated',
      data: <String, Object?>{
        'orderId': orderId.trim(),
        'operation': 'markMissed',
        'status': 'missed',
      },
    );
    unawaited(
      _logEvent(
        orderId: orderId,
        eventType: 'missed',
        status: 'missed',
      ),
    );
  }

  Future<void> markFailed(String orderId) async {
    VoiceCallTrace.log(
      'markFailed() request',
      data: <String, Object?>{'orderId': orderId.trim()},
    );
    await patchSession(orderId, {'status': 'failed'});
    VoiceCallTrace.log(
      'markFailed() sent',
      data: <String, Object?>{'orderId': orderId.trim(), 'status': 'failed'},
    );
    VoiceCallTrace.log(
      'backend updated',
      data: <String, Object?>{
        'orderId': orderId.trim(),
        'operation': 'markFailed',
        'status': 'failed',
      },
    );
    unawaited(
      _logEvent(
        orderId: orderId,
        eventType: 'failed',
        status: 'failed',
      ),
    );
  }

  Future<void> clearSession(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      return;
    }

    VoiceCallTrace.log(
      'clearSession() request',
      data: <String, Object?>{'orderId': normalizedOrderId},
    );
    await _sendForm({
      'action': 'session_clear',
      'order_id': normalizedOrderId,
    });
    VoiceCallTrace.log(
      'clearSession() sent',
      data: <String, Object?>{'orderId': normalizedOrderId},
    );
  }

  Future<void> addCandidate({
    required String orderId,
    required String bucket,
    required RTCIceCandidate candidate,
  }) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty ||
        candidate.candidate == null ||
        candidate.candidate!.trim().isEmpty) {
      return;
    }

    try {
      VoiceCallTrace.log(
        'addCandidate() request',
        data: <String, Object?>{
          'orderId': normalizedOrderId,
          'bucket': bucket,
          ..._candidateSummary(candidate),
        },
      );
      await _sendForm({
        'action': 'candidate_add',
        'order_id': normalizedOrderId,
        'bucket': bucket,
        'candidate_text': candidate.candidate ?? '',
        if (candidate.sdpMid != null) 'sdp_mid': candidate.sdpMid!,
        if (candidate.sdpMLineIndex != null)
          'sdp_m_line_index': candidate.sdpMLineIndex.toString(),
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      VoiceCallTrace.log(
        'addCandidate() sent',
        data: <String, Object?>{
          'orderId': normalizedOrderId,
          'bucket': bucket,
          ..._candidateSummary(candidate),
        },
      );
    } catch (error, stackTrace) {
      VoiceCallTrace.error(
        'addCandidate() failed',
        error,
        stackTrace,
        data: <String, Object?>{
          'orderId': normalizedOrderId,
          'bucket': bucket,
          ..._candidateSummary(candidate),
        },
      );
    }
  }

  Map<String, dynamic> candidateToMap(RTCIceCandidate candidate) {
    return <String, dynamic>{
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
    };
  }

  RTCIceCandidate? candidateFromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.map((key, value) => MapEntry('$key', value));
    final candidate = map['candidate']?.toString() ??
        map['candidate_text']?.toString() ??
        map['candidateText']?.toString() ??
        '';
    if (candidate.isEmpty) {
      return null;
    }
    final sdpMLineIndex = map['sdpMLineIndex'] ?? map['sdp_m_line_index'];
    return RTCIceCandidate(
      candidate,
      map['sdpMid']?.toString() ?? map['sdp_mid']?.toString(),
      sdpMLineIndex == null ? null : int.tryParse(sdpMLineIndex.toString()),
    );
  }

  Map<String, dynamic>? mapOrNull(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  Future<void> _logEvent({
    required String orderId,
    required String eventType,
    required String status,
    String? callerRole,
    String? callerId,
    String? callerName,
    String? calleeRole,
    String? calleeId,
    String? calleeName,
    int? eventAtMs,
  }) async {
    if (orderId.trim().isEmpty) {
      return;
    }

    try {
      VoiceCallTrace.log(
        '_logEvent() request',
        data: <String, Object?>{
          'orderId': orderId.trim(),
          'eventType': eventType,
          'status': status,
        },
      );
      await _sendForm({
        'order_id': orderId.trim(),
        'event_type': eventType.trim(),
        'status': status.trim(),
        if (callerRole != null && callerRole.trim().isNotEmpty)
          'caller_role': callerRole.trim(),
        if (callerId != null && callerId.trim().isNotEmpty)
          'caller_ref_id': callerId.trim(),
        if (callerName != null && callerName.trim().isNotEmpty)
          'caller_name': callerName.trim(),
        if (calleeRole != null && calleeRole.trim().isNotEmpty)
          'callee_role': calleeRole.trim(),
        if (calleeId != null && calleeId.trim().isNotEmpty)
          'callee_ref_id': calleeId.trim(),
        if (calleeName != null && calleeName.trim().isNotEmpty)
          'callee_name': calleeName.trim(),
        if (eventAtMs != null) 'event_at_ms': eventAtMs.toString(),
      });
      VoiceCallTrace.log(
        '_logEvent() sent',
        data: <String, Object?>{
          'orderId': orderId.trim(),
          'eventType': eventType,
          'status': status,
        },
      );
    } catch (error, stackTrace) {
      VoiceCallTrace.error(
        '_logEvent() failed',
        error,
        stackTrace,
        data: <String, Object?>{
          'orderId': orderId.trim(),
          'eventType': eventType,
          'status': status,
        },
      );
    }
  }

  Future<void> _sendForm(
    Map<String, String> fields, {
    Map<String, String>? extraBody,
  }) async {
    final body = <String, String>{
      ...fields,
      if (extraBody != null) ...extraBody
    };
    body.removeWhere((key, value) => value.trim().isEmpty);

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        VoiceCallTrace.log(
          '_sendForm() attempt',
          data: <String, Object?>{
            'endpoint': _endpoint.toString(),
            'attempt': attempt + 1,
            'keys': body.keys.toList(growable: false),
          },
        );
        final response = await http
            .post(
              _endpoint,
              body: body,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          VoiceCallTrace.log(
            '_sendForm() success',
            data: <String, Object?>{
              'endpoint': _endpoint.toString(),
              'statusCode': response.statusCode,
              'bodyLength': response.body.length,
            },
          );
          return;
        }
        lastError = StateError(
          'Voice call request failed (${response.statusCode})',
        );
        VoiceCallTrace.log(
          '_sendForm() bad status',
          data: <String, Object?>{
            'endpoint': _endpoint.toString(),
            'statusCode': response.statusCode,
            'bodyLength': response.body.length,
          },
        );
      } catch (error, stackTrace) {
        lastError = error;
        VoiceCallTrace.error(
          '_sendForm() exception',
          error,
          stackTrace,
          data: <String, Object?>{
            'endpoint': _endpoint.toString(),
            'attempt': attempt + 1,
          },
        );
      }

      if (attempt == 0) {
        await Future.delayed(const Duration(milliseconds: 350));
      }
    }

    throw StateError(lastError?.toString() ?? 'Voice call request failed');
  }
}
