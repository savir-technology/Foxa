import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';
import 'package:tks/core/services/background_music_service.dart';
import 'package:tks/core/services/order_voice_call_service.dart';
import 'package:tks/core/services/voice_call_trace.dart';

class OrderVoiceCallScreen extends StatefulWidget {
  const OrderVoiceCallScreen.outgoing({
    super.key,
    required this.orderId,
    required this.myRole,
    required this.myId,
    required this.myName,
    required this.peerRole,
    required this.peerId,
    required this.peerName,
    this.autoAnswer = false,
  }) : incoming = false;

  const OrderVoiceCallScreen.incoming({
    super.key,
    required this.orderId,
    required this.myRole,
    required this.myId,
    required this.myName,
    required this.peerRole,
    required this.peerId,
    required this.peerName,
    this.autoAnswer = false,
  }) : incoming = true;

  final String orderId;
  final String myRole;
  final String myId;
  final String myName;
  final String peerRole;
  final String peerId;
  final String peerName;
  final bool incoming;
  final bool autoAnswer;

  @override
  State<OrderVoiceCallScreen> createState() => _OrderVoiceCallScreenState();
}

class _OrderVoiceCallScreenState extends State<OrderVoiceCallScreen> {
  static const MethodChannel _voiceCallIntentChannel =
      MethodChannel('voice_call_intent');
  late final OrderVoiceCallService _service;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  final Set<String> _seenRemoteCandidateKeys = <String>{};

  StreamSubscription<OrderVoiceCallSession?>? _sessionSub;
  Timer? _ringTimeoutTimer;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _ownsRemoteStream = false;
  OrderVoiceCallSession? _session;

  bool _initializing = true;
  bool _muted = false;
  bool _connected = false;
  bool _answering = false;
  bool _ending = false;
  bool _remoteDescriptionApplied = false;
  bool _iceRecoveryAttempted = false;
  bool _iceRecoveryInProgress = false;
  bool _pausedBackgroundMusic = false;
  bool _ringbackPlaying = false;
  String? _lastSessionStateKey;
  String _statusText = 'Connecting...';

  bool get _isCaller => !widget.incoming;
  bool get _isArabic => Get.locale?.languageCode == 'ar';

  String get _peerDisplayName {
    final name = widget.peerName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return _roleLabel(widget.peerRole);
  }

  String get _myDisplayName {
    final name = widget.myName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return _roleLabel(widget.myRole);
  }

  String _roleLabel(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'driver') {
      return _isArabic ? 'السائق' : 'Driver';
    }
    if (normalized == 'user' || normalized == 'customer') {
      return _isArabic ? 'العميل' : 'Customer';
    }
    return role.trim().isNotEmpty
        ? role.trim()
        : (_isArabic ? 'الطرف الآخر' : 'Peer');
  }

  String get _localizedStatus {
    final normalized = _statusText.trim().toLowerCase();
    if (_connected) {
      return _isArabic ? 'متصل الآن' : 'Connected';
    }

    switch (normalized) {
      case 'connecting...':
        return _isArabic ? 'جاري تجهيز المكالمة' : 'Preparing call';
      case 'ringing...':
        return _isArabic ? 'جاري الرنين' : 'Ringing';
      case 'answer sent':
        return _isArabic ? 'تم قبول المكالمة' : 'Answer sent';
      case 'answer received':
        return _isArabic ? 'تم الرد' : 'Answer received';
      case 'answering...':
        return _isArabic ? 'جاري الرد' : 'Answering';
      case 'no answer':
        return _isArabic ? 'لا يوجد رد' : 'No answer';
      case 'call ended':
        return _isArabic ? 'تم إنهاء المكالمة' : 'Call ended';
      case 'connection failed':
      case 'ice failed':
        return _isArabic ? 'تعذر الاتصال' : 'Connection failed';
      case 'connection lost':
      case 'ice disconnected':
        return _isArabic ? 'انقطع الاتصال' : 'Connection lost';
    }

    if (normalized.contains('microphone permission')) {
      return _isArabic
          ? 'يجب السماح بالميكروفون'
          : 'Microphone permission required';
    }
    if (normalized.contains('offer is missing')) {
      return _isArabic ? 'تعذر بدء المكالمة' : 'Unable to start call';
    }
    return _statusText;
  }

  Color get _statusColor {
    final normalized = _statusText.trim().toLowerCase();
    if (_connected) {
      return const Color(0xFF4DA3FF);
    }
    if (normalized.contains('failed') ||
        normalized.contains('lost') ||
        normalized.contains('disconnected') ||
        normalized.contains('missing') ||
        normalized.contains('permission') ||
        normalized.contains('no answer')) {
      return const Color(0xFFFF5C69);
    }
    return const Color(0xFF72A7FF);
  }

  IconData get _statusIcon {
    final normalized = _statusText.trim().toLowerCase();
    if (_connected) {
      return Icons.wifi_tethering_rounded;
    }
    if (normalized.contains('failed') ||
        normalized.contains('lost') ||
        normalized.contains('disconnected') ||
        normalized.contains('missing') ||
        normalized.contains('permission') ||
        normalized.contains('no answer')) {
      return Icons.signal_wifi_connected_no_internet_4_rounded;
    }
    return Icons.graphic_eq_rounded;
  }

  Map<String, dynamic> get _sdpReceiveConstraints => <String, dynamic>{
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      };

  Map<String, Object?> _traceState({
    String? event,
    Map<String, Object?>? extra,
  }) {
    return <String, Object?>{
      'event': event,
      'orderId': widget.orderId,
      'incoming': widget.incoming,
      'myRole': widget.myRole,
      'peerRole': widget.peerRole,
      'statusText': _statusText,
      'connected': _connected,
      'answering': _answering,
      'ending': _ending,
      'remoteDescriptionApplied': _remoteDescriptionApplied,
      'sessionStatus': _session?.status,
      'sessionStateKey': _session?.stateKey,
      'pendingRemoteCandidates': _pendingRemoteCandidates.length,
      'seenRemoteCandidates': _seenRemoteCandidateKeys.length,
      'localAudioTracks': _localStream?.getAudioTracks().length ?? 0,
      'remoteAudioTracks': _remoteStream?.getAudioTracks().length ?? 0,
      'ownsRemoteStream': _ownsRemoteStream,
      'pcConnectionState': _peerConnection?.connectionState.toString(),
      'pcIceState': _peerConnection?.iceConnectionState.toString(),
      'pcSignalingState': _peerConnection?.signalingState.toString(),
      'pcGatheringState': _peerConnection?.iceGatheringState.toString(),
      if (extra != null) ...extra,
    };
  }

  void _trace(
    String message, {
    Map<String, Object?>? extra,
  }) {
    VoiceCallTrace.log(
      message,
      data: _traceState(extra: extra),
    );
  }

  void _traceError(
    String message,
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? extra,
  }) {
    VoiceCallTrace.error(
      message,
      error,
      stackTrace,
      data: _traceState(extra: extra),
    );
  }

  @override
  void initState() {
    super.initState();
    _service = Get.find<OrderVoiceCallService>();
    _trace('initState()');
    _trace('call screen opened');
    _trace(
      'session id received',
      extra: <String, Object?>{'sessionId': widget.orderId},
    );
    unawaited(_stopNativeRinging());
    _bootstrap();
  }

  @override
  void dispose() {
    _trace('dispose() start');
    _cancelRingTimeout();
    _sessionSub?.cancel();
    _closeLocalResources();
    unawaited(_stopNativeRinging());
    unawaited(_stopRingbackTone());
    _remoteRenderer.dispose();
    _trace('dispose() renderer disposed');
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _trace('bootstrap() start');
      await _configureAudioSession();
      _trace('bootstrap() audio configured');
      await _remoteRenderer.initialize();
      _trace('bootstrap() renderer initialized');
      await _preparePeerConnection();
      _trace('bootstrap() peer connection prepared');

      if (widget.incoming) {
        if (widget.autoAnswer) {
          _trace('bootstrap() incoming call auto-answer requested');
          await _answerIncomingCall();
        } else {
          _trace('bootstrap() incoming call waiting for manual answer');
        }
      } else {
        _trace('bootstrap() starting outgoing call');
        await _startOutgoingCall();
      }

      if (mounted) {
        setState(() {
          _initializing = false;
          if (widget.incoming && !widget.autoAnswer) {
            _statusText = 'Ringing...';
          }
        });
      }

      _trace('bootstrap() listening to session');
      _listenToSession();
      _trace('bootstrap() completed');
    } catch (error) {
      _traceError('bootstrap() failed', error, StackTrace.current);
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _statusText = error.toString();
      });
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      _trace('configureAudioSession() start');
      await _pauseBackgroundMusicIfNeeded();
      if (WebRTC.platformIsAndroid) {
        _trace('configureAudioSession() android mode', extra: <String, Object?>{
          'mode': 'communication',
          'speakerphone': true,
        });
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
        await Helper.setSpeakerphoneOn(true);
      } else if (WebRTC.platformIsIOS) {
        _trace('configureAudioSession() ios mode', extra: <String, Object?>{
          'mode': 'localAndRemote',
          'preferSpeakerOutput': true,
        });
        await Helper.ensureAudioSession();
        await Helper.setAppleAudioIOMode(
          AppleAudioIOMode.localAndRemote,
          preferSpeakerOutput: true,
        );
      }
      _trace('configureAudioSession() done');
    } catch (error, stackTrace) {
      _traceError('configureAudioSession() failed', error, stackTrace);
    }
  }

  Future<void> _restoreMediaAudioConfiguration() async {
    try {
      _trace('restoreMediaAudioConfiguration() start');
      if (WebRTC.platformIsAndroid) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.media,
        );
        await Helper.setSpeakerphoneOn(false);
        _trace('restoreMediaAudioConfiguration() android media restored');
      } else if (WebRTC.platformIsIOS) {
        await Helper.setAppleAudioIOMode(AppleAudioIOMode.remoteOnly);
        _trace('restoreMediaAudioConfiguration() ios playback restored');
      }
      _trace('restoreMediaAudioConfiguration() done');
    } catch (error, stackTrace) {
      _traceError(
        'restoreMediaAudioConfiguration() failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _stopNativeRinging() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _voiceCallIntentChannel.invokeMethod<bool>('stopRinging');
    } catch (_) {
      // Native ringtone is a best-effort bridge.
    }
  }

  Future<void> _pauseBackgroundMusicIfNeeded() async {
    if (_pausedBackgroundMusic || !Get.isRegistered<BackgroundMusicService>()) {
      return;
    }

    final musicService = Get.find<BackgroundMusicService>();
    if (!musicService.isEnabled.value) {
      return;
    }

    await musicService.pause();
    _pausedBackgroundMusic = true;
  }

  Future<void> _resumeBackgroundMusicIfNeeded() async {
    if (!_pausedBackgroundMusic ||
        !Get.isRegistered<BackgroundMusicService>()) {
      return;
    }

    _pausedBackgroundMusic = false;
    await Get.find<BackgroundMusicService>().toggle(true);
  }

  Future<void> _preparePeerConnection() async {
    _trace('preparePeerConnection() start');
    try {
      await _ensureMicrophonePermission();
      _trace('preparePeerConnection() microphone permission ready',
          extra: <String, Object?>{
            'permissionGranted': true,
          });

      _trace('preparePeerConnection() creating peer connection');
      _peerConnection = await createPeerConnection(<String, dynamic>{
        'iceServers': _buildIceServers(),
        'iceTransportPolicy': _iceTransportPolicy,
        'continualGatheringPolicy': 'gather_continually',
        'iceCandidatePoolSize': 4,
        'sdpSemantics': 'unified-plan',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      });
      _trace('preparePeerConnection() peer connection created');

      _peerConnection!.onConnectionState = (state) {
        _trace(
          'onConnectionState',
          extra: <String, Object?>{'state': state.toString()},
        );
        if (!mounted) {
          return;
        }
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          setState(() {
            _connected = true;
            _statusText = 'Connected';
          });
          unawaited(_stopRingbackTone());
          if (WebRTC.platformIsAndroid) {
            unawaited(Helper.setSpeakerphoneOn(true));
          }
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          if (mounted) {
            setState(() {
              _statusText = 'Connection failed';
            });
          }
          unawaited(_recoverOrFailIce('connection_state_failed'));
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          if (mounted) {
            setState(() {
              _statusText = 'Connection lost';
            });
          }
          unawaited(_stopRingbackTone());
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        _trace(
          'onIceConnectionState',
          extra: <String, Object?>{'state': state.toString()},
        );
        if (!mounted) {
          return;
        }
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          setState(() {
            _connected = true;
            _statusText = 'Connected';
          });
          unawaited(_stopRingbackTone());
          if (WebRTC.platformIsAndroid) {
            unawaited(Helper.setSpeakerphoneOn(true));
          }
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          if (mounted) {
            setState(() {
              _statusText = 'ICE failed';
            });
          }
          unawaited(_recoverOrFailIce('ice_connection_failed'));
        } else if (state ==
            RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          if (mounted) {
            setState(() {
              _statusText = 'ICE disconnected';
            });
          }
          unawaited(_stopRingbackTone());
        }
      };

      _peerConnection!.onIceCandidate = (candidate) {
        _trace(
          'onIceCandidate',
          extra: <String, Object?>{
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
        if (candidate.candidate == null ||
            candidate.candidate!.trim().isEmpty) {
          return;
        }
        final bucket = _isCaller ? 'callerCandidates' : 'calleeCandidates';
        _trace(
          'onIceCandidate() sending',
          extra: <String, Object?>{'bucket': bucket},
        );
        unawaited(
          _service.addCandidate(
            orderId: widget.orderId,
            bucket: bucket,
            candidate: candidate,
          ),
        );
      };

      _peerConnection!.onTrack = (event) {
        _trace(
          'onTrack',
          extra: <String, Object?>{
            'trackKind': event.track.kind,
            'streamCount': event.streams.length,
          },
        );
        unawaited(_attachRemoteTrack(event));
      };

      _peerConnection!.onAddTrack = (stream, track) {
        _trace(
          'onAddTrack',
          extra: <String, Object?>{
            'trackKind': track.kind,
            'streamId': stream.id,
            'streamTracks': stream.getAudioTracks().length,
          },
        );
        if (track.kind != 'audio') {
          return;
        }
        unawaited(_attachRemoteStream(stream));
      };

      _peerConnection!.onAddStream = (stream) {
        _trace(
          'onAddStream',
          extra: <String, Object?>{
            'streamId': stream.id,
            'audioTracks': stream.getAudioTracks().length,
          },
        );
        unawaited(_attachRemoteStream(stream));
      };

      _trace('preparePeerConnection() calling getUserMedia');
      _localStream =
          await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': <String, dynamic>{
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'channelCount': 1,
        },
        'video': false,
      });
      _trace('preparePeerConnection() local stream acquired',
          extra: <String, Object?>{
            'streamId': _localStream?.id,
            'audioTracks': _localStream?.getAudioTracks().length ?? 0,
          });

      for (final track in _localStream!.getAudioTracks()) {
        _trace(
          'preparePeerConnection() adding local track',
          extra: <String, Object?>{
            'trackId': track.id,
            'enabled': track.enabled,
          },
        );
        track.enabled = true;
        if (WebRTC.platformIsAndroid) {
          try {
            track.enableSpeakerphone(true);
          } catch (error, stackTrace) {
            _traceError(
              'track.enableSpeakerphone() failed',
              error,
              stackTrace,
              extra: <String, Object?>{'trackId': track.id},
            );
          }
        }
        await Helper.setMicrophoneMute(false, track);
        await _peerConnection!.addTrack(track, _localStream!);
        _trace(
          'preparePeerConnection() local track added',
          extra: <String, Object?>{
            'trackId': track.id,
            'localTrackCount': _localStream!.getAudioTracks().length,
          },
        );
      }

      if (WebRTC.platformIsAndroid) {
        await Helper.setSpeakerphoneOn(true);
        _trace('preparePeerConnection() speakerphone enabled');
      }
    } catch (error, stackTrace) {
      _traceError('preparePeerConnection() failed', error, stackTrace);
      rethrow;
    }
  }

  List<Map<String, dynamic>> _buildIceServers() {
    const stunUrls = String.fromEnvironment('VOICE_STUN_URLS');
    final resolvedStunUrls = _splitIceUrls(stunUrls);
    final servers = <Map<String, dynamic>>[
      <String, dynamic>{
        'urls': resolvedStunUrls.isNotEmpty
            ? resolvedStunUrls
            : <String>[
                'stun:stun.l.google.com:19302',
                'stun:stun1.l.google.com:19302',
                'stun:stun2.l.google.com:19302',
                'stun:stun.relay.metered.ca:80',
              ],
      },
    ];

    const turnUrls = String.fromEnvironment('VOICE_TURN_URLS');
    const turnUrl = String.fromEnvironment('VOICE_TURN_URL');
    const turnUsername = String.fromEnvironment(
      'VOICE_TURN_USERNAME',
      defaultValue: '',
    );
    const turnCredential = String.fromEnvironment(
      'VOICE_TURN_CREDENTIAL',
      defaultValue: '',
    );

    final configuredTurnUrls = _splitIceUrls(turnUrls);
    final resolvedTurnUrls = configuredTurnUrls.isNotEmpty
        ? configuredTurnUrls
        : (turnUrl.isNotEmpty
            ? _splitIceUrls(turnUrl)
            : <String>[
                'turn:openrelay.metered.ca:80',
                'turn:openrelay.metered.ca:80?transport=udp',
                'turn:openrelay.metered.ca:80?transport=tcp',
                'turn:openrelay.metered.ca:443',
                'turn:openrelay.metered.ca:443?transport=tcp',
                'turns:openrelay.metered.ca:443?transport=tcp',
              ]);
    final resolvedTurnUsername =
        turnUsername.isNotEmpty ? turnUsername : 'openrelayproject';
    final resolvedTurnCredential =
        turnCredential.isNotEmpty ? turnCredential : 'openrelayproject';

    if (resolvedTurnUrls.isNotEmpty &&
        resolvedTurnUsername.isNotEmpty &&
        resolvedTurnCredential.isNotEmpty) {
      servers.add(<String, dynamic>{
        'urls': resolvedTurnUrls,
        'username': resolvedTurnUsername,
        'credential': resolvedTurnCredential,
      });
    }

    _trace(
      'buildIceServers()',
      extra: <String, Object?>{
        'serverCount': servers.length,
        'hasTurn': resolvedTurnUrls.isNotEmpty &&
            resolvedTurnUsername.isNotEmpty &&
            resolvedTurnCredential.isNotEmpty,
        'turnUrlCount': resolvedTurnUrls.length,
        'iceTransportPolicy': _iceTransportPolicy,
      },
    );
    return servers;
  }

  String get _iceTransportPolicy {
    const policy = String.fromEnvironment(
      'VOICE_ICE_TRANSPORT_POLICY',
      defaultValue: 'all',
    );
    return policy == 'relay' ? 'relay' : 'all';
  }

  List<String> _splitIceUrls(String raw) {
    return raw
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _recoverOrFailIce(String reason) async {
    if (_ending) {
      return;
    }

    if (_iceRecoveryInProgress) {
      _trace(
        'recoverOrFailIce() already in progress',
        extra: <String, Object?>{'reason': reason},
      );
      return;
    }

    if (_iceRecoveryAttempted) {
      _trace(
        'recoverOrFailIce() already attempted; failing call',
        extra: <String, Object?>{'reason': reason},
      );
      await _stopRingbackTone();
      await _failCall();
      return;
    }

    _iceRecoveryAttempted = true;
    _iceRecoveryInProgress = true;
    _trace(
      'recoverOrFailIce() restarting ICE',
      extra: <String, Object?>{'reason': reason},
    );
    if (mounted) {
      setState(() {
        _statusText = 'Reconnecting...';
      });
    }

    try {
      await _peerConnection?.restartIce();
      await Future<void>.delayed(const Duration(seconds: 8));
      final state = _peerConnection?.iceConnectionState;
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted ||
          _connected ||
          _ending) {
        _trace(
          'recoverOrFailIce() recovered',
          extra: <String, Object?>{'state': state.toString()},
        );
        return;
      }
    } catch (error, stackTrace) {
      _traceError(
        'recoverOrFailIce() restart failed',
        error,
        stackTrace,
        extra: <String, Object?>{'reason': reason},
      );
    } finally {
      _iceRecoveryInProgress = false;
    }

    await _stopRingbackTone();
    await _failCall();
  }

  Future<void> _ensureMicrophonePermission() async {
    if (WebRTC.platformIsWeb) {
      _trace('ensureMicrophonePermission() skipped for web');
      return;
    }

    _trace('ensureMicrophonePermission() start');
    final status = await Permission.microphone.status;
    _trace(
      'ensureMicrophonePermission() status',
      extra: <String, Object?>{
        'isGranted': status.isGranted,
        'isDenied': status.isDenied,
        'isPermanentlyDenied': status.isPermanentlyDenied,
      },
    );
    if (status.isGranted) {
      return;
    }

    final result = await Permission.microphone.request();
    _trace(
      'ensureMicrophonePermission() request result',
      extra: <String, Object?>{
        'isGranted': result.isGranted,
        'isDenied': result.isDenied,
        'isPermanentlyDenied': result.isPermanentlyDenied,
      },
    );
    if (!result.isGranted) {
      throw StateError('Microphone permission is required for voice calls');
    }
  }

  Future<void> _attachRemoteStream(MediaStream stream) async {
    _trace(
      'attachRemoteStream() start',
      extra: <String, Object?>{
        'streamId': stream.id,
        'audioTracks': stream.getAudioTracks().length,
      },
    );
    _remoteStream = stream;
    _ownsRemoteStream = false;
    _remoteRenderer.srcObject = stream;
    await _remoteRenderer.setVolume(1.0);
    unawaited(_configureAudioSession());
    for (final track in stream.getAudioTracks()) {
      track.enabled = true;
      if (WebRTC.platformIsAndroid) {
        try {
          track.enableSpeakerphone(true);
        } catch (_) {}
      }
      await Helper.setVolume(1.0, track);
    }
    if (WebRTC.platformIsAndroid) {
      await Helper.setSpeakerphoneOn(true);
    }
    if (mounted) {
      setState(() {
        _connected = true;
        _statusText = 'Connected';
      });
    }
    _trace('attachRemoteStream() done');
  }

  Future<void> _attachRemoteTrack(RTCTrackEvent event) async {
    _trace(
      'attachRemoteTrack() start',
      extra: <String, Object?>{
        'trackKind': event.track.kind,
        'streamCount': event.streams.length,
      },
    );
    if (event.track.kind != 'audio') {
      return;
    }

    final eventStream = event.streams.isNotEmpty ? event.streams.first : null;
    if (eventStream != null) {
      await _attachRemoteStream(eventStream);
      return;
    }

    var remoteStream = _remoteStream;
    if (remoteStream == null || !_ownsRemoteStream) {
      remoteStream = await createLocalMediaStream('remote_${widget.orderId}');
      _remoteStream = remoteStream;
      _ownsRemoteStream = true;
    }

    final alreadyAttached = remoteStream.getAudioTracks().any(
          (track) => track.id == event.track.id,
        );
    if (!alreadyAttached) {
      event.track.enabled = true;
      if (WebRTC.platformIsAndroid) {
        try {
          event.track.enableSpeakerphone(true);
        } catch (_) {}
      }
      await remoteStream.addTrack(event.track);
    }

    _remoteRenderer.srcObject = remoteStream;
    await _remoteRenderer.setVolume(1.0);
    unawaited(_configureAudioSession());
    await Helper.setVolume(1.0, event.track);
    if (WebRTC.platformIsAndroid) {
      await Helper.setSpeakerphoneOn(true);
    }
    if (mounted) {
      setState(() {
        _connected = true;
        _statusText = 'Connected';
      });
    }
    _trace('attachRemoteTrack() done');
  }

  Future<void> _startOutgoingCall() async {
    _trace('startOutgoingCall() start');
    try {
      await _service.clearSession(widget.orderId);
      _trace('startOutgoingCall() session cleared');
      final offer = await _peerConnection!.createOffer(_sdpReceiveConstraints);
      _trace(
        'startOutgoingCall() offer created',
        extra: <String, Object?>{
          'type': offer.type,
          'sdpLength': offer.sdp?.length ?? 0,
        },
      );
      await _peerConnection!.setLocalDescription(offer);
      _trace('startOutgoingCall() local description set');
      final now = DateTime.now().millisecondsSinceEpoch;

      // تحديد المتصل والمستقبل بشكل صحيح
      final isCaller = widget.myRole == 'user';
      _session = OrderVoiceCallSession(
        orderId: widget.orderId,
        status: 'ringing',
        callerRole: isCaller ? widget.myRole : widget.peerRole,
        callerId: isCaller ? widget.myId : widget.peerId,
        callerName: isCaller ? widget.myName : widget.peerName,
        calleeRole: isCaller ? widget.peerRole : widget.myRole,
        calleeId: isCaller ? widget.peerId : widget.myId,
        calleeName: isCaller ? widget.peerName : widget.myName,
        createdAtMs: now,
        updatedAtMs: now,
        offer: <String, dynamic>{'type': offer.type, 'sdp': offer.sdp},
      );
      await _service.createSession(_session!);
      _trace('startOutgoingCall() session created');

      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _statusText = 'Ringing...';
      });
      _startRingTimeout();
      _trace('startOutgoingCall() done');
    } catch (error, stackTrace) {
      _traceError('startOutgoingCall() failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> _joinIncomingCall() async {
    _trace('joinIncomingCall() start');
    try {
      _session = await _waitForIncomingSessionOffer();
      _trace(
        'joinIncomingCall() session loaded',
        extra: <String, Object?>{
          'hasOffer': _session?.offer != null,
          'status': _session?.status,
        },
      );
      final offer = _session?.offer;
      if (offer == null || (offer['sdp'] ?? '').toString().trim().isEmpty) {
        throw StateError('Call offer is missing');
      }

      _trace(
        'joinIncomingCall() applying remote description',
        extra: <String, Object?>{
          'type': offer['type']?.toString() ?? 'offer',
          'sdpLength': offer['sdp']?.toString().length ?? 0,
        },
      );
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          offer['sdp']?.toString(),
          offer['type']?.toString() ?? 'offer',
        ),
      );
      _remoteDescriptionApplied = true;
      _trace('joinIncomingCall() remote description applied');

      _trace('joinIncomingCall() creating answer');
      final answer =
          await _peerConnection!.createAnswer(_sdpReceiveConstraints);
      _trace(
        'joinIncomingCall() answer created',
        extra: <String, Object?>{
          'type': answer.type,
          'sdpLength': answer.sdp?.length ?? 0,
        },
      );
      await _peerConnection!.setLocalDescription(answer);
      _trace('joinIncomingCall() local answer set');
      await _service.updateAnswer(
        orderId: widget.orderId,
        answer: <String, dynamic>{'type': answer.type, 'sdp': answer.sdp},
      );
      _trace('backend updated', extra: <String, Object?>{
        'operation': 'updateAnswer',
        'status': 'active',
      });
      _trace('joinIncomingCall() answer sent');

      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _statusText = 'Answer sent';
        _connected = false;
      });

      await _processRemoteCandidates(_session!);
      await _flushPendingRemoteCandidates();
      _trace('joinIncomingCall() done');
    } catch (error, stackTrace) {
      _traceError('joinIncomingCall() failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> _answerIncomingCall() async {
    if (_answering || _connected || _ending) {
      _trace('answerIncomingCall() skipped');
      return;
    }

    _trace('answerIncomingCall() start');
    if (mounted) {
      setState(() {
        _answering = true;
        _statusText = 'Answering...';
      });
    }

    try {
      await _stopNativeRinging();
      await _stopRingbackTone();
      await _joinIncomingCall();
      _trace('answerIncomingCall() done');
    } catch (error, stackTrace) {
      _traceError('answerIncomingCall() failed', error, stackTrace);
      if (mounted) {
        setState(() {
          _statusText = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _answering = false;
        });
      } else {
        _answering = false;
      }
    }
  }

  Future<OrderVoiceCallSession> _waitForIncomingSessionOffer() async {
    const attempts = 20;
    const delay = Duration(milliseconds: 250);

    OrderVoiceCallSession? session;
    for (var index = 0; index < attempts; index++) {
      session = await _service.loadSession(widget.orderId);
      final offer = session?.offer;
      if (offer != null && (offer['sdp'] ?? '').toString().trim().isNotEmpty) {
        return session!;
      }

      await Future.delayed(delay);
    }

    throw StateError('Call offer is missing');
  }

  void _startRingTimeout() {
    if (!_isCaller) {
      return;
    }

    _cancelRingTimeout();
    _ringTimeoutTimer = Timer(const Duration(seconds: 30), () {
      unawaited(_handleRingTimeout());
    });
  }

  Future<void> _handleRingTimeout() async {
    if (!mounted || _connected || _ending) {
      return;
    }

    final session = _session;
    if (session == null || session.isEnded || session.isActive) {
      return;
    }

    if (mounted) {
      setState(() {
        _statusText = 'No answer';
      });
    }

    await _stopRingbackTone();
    await _service.markMissed(widget.orderId);
    _trace('backend updated', extra: <String, Object?>{
      'operation': 'markMissed',
      'status': 'missed',
    });

    await _cleanupAndClose(popScreen: true, removeSession: false);
  }

  void _cancelRingTimeout() {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
  }

  void _listenToSession() {
    _sessionSub?.cancel();
    _trace('listenToSession() start');
    _sessionSub = _service.watchSession(widget.orderId).listen((session) async {
      if (!mounted || session == null) {
        _trace(
          'listenToSession() skip',
          extra: <String, Object?>{
            'mounted': mounted,
            'sessionNull': session == null,
          },
        );
        return;
      }

      final stateKey = session.stateKey;
      _trace(
        'listenToSession() received',
        extra: <String, Object?>{
          'status': session.status,
          'stateKey': stateKey,
          'previousStateKey': _lastSessionStateKey,
          'hasOffer': session.offer != null,
          'hasAnswer': session.answer != null,
          'callerCandidates': session.callerCandidates.length,
          'calleeCandidates': session.calleeCandidates.length,
        },
      );
      if (_lastSessionStateKey == stateKey) {
        _trace('listenToSession() duplicate state ignored');
        return;
      }
      _lastSessionStateKey = stateKey;

      _session = session;

      try {
        if (session.isEnded) {
          _trace('listenToSession() ended session received');
          _cancelRingTimeout();
          await _stopRingbackTone();
          if (mounted) {
            setState(() {
              _statusText =
                  session.isFailed ? 'Connection failed' : 'Call ended';
              _connected = false;
            });
          }
          await _cleanupAndClose(popScreen: true, removeSession: false);
          return;
        }

        if (!_isCaller && !_remoteDescriptionApplied && session.offer != null) {
          _trace(
            'listenToSession() incoming offer ready',
            extra: <String, Object?>{
              'hasOffer': true,
              'waitingForManualAnswer': true,
            },
          );
        }

        if (_isCaller && !_remoteDescriptionApplied && session.answer != null) {
          final answer = session.answer!;
          _trace(
            'receiveAnswer()',
            extra: <String, Object?>{
              'type': answer['type']?.toString() ?? 'answer',
              'sdpLength': answer['sdp']?.toString().length ?? 0,
            },
          );
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(
              answer['sdp']?.toString(),
              answer['type']?.toString() ?? 'answer',
            ),
          );
          _remoteDescriptionApplied = true;
          _trace('setRemoteDescription(answer) done');
          await _flushPendingRemoteCandidates();
          await _stopRingbackTone();
          await _configureAudioSession();
          _cancelRingTimeout();
          if (mounted) {
            setState(() {
              _statusText = 'Answer received';
            });
          }
        }

        await _processRemoteCandidates(session);
      } catch (error, stackTrace) {
        _traceError('listenToSession() failed', error, stackTrace);
        if (!mounted) {
          return;
        }
        setState(() {
          _statusText = error.toString();
        });
      }
    });
  }

  Future<void> _processRemoteCandidates(OrderVoiceCallSession session) async {
    _trace(
      'processRemoteCandidates() start',
      extra: <String, Object?>{
        'role': widget.myRole,
        'remoteCount': session.remoteCandidatesFor(widget.myRole).length,
      },
    );
    final remoteCandidates = session.remoteCandidatesFor(widget.myRole);
    if (remoteCandidates.isEmpty) {
      _trace('processRemoteCandidates() no remote candidates');
      return;
    }

    for (final rawCandidate in remoteCandidates) {
      final candidateKey = _candidateKey(rawCandidate);
      if (!_seenRemoteCandidateKeys.add(candidateKey)) {
        _trace(
          'processRemoteCandidates() duplicate ignored',
          extra: <String, Object?>{'candidateKey': candidateKey},
        );
        continue;
      }

      final candidate = _service.candidateFromMap(rawCandidate);
      if (candidate == null) {
        _trace(
          'processRemoteCandidates() invalid candidate ignored',
          extra: <String, Object?>{'candidateKey': candidateKey},
        );
        continue;
      }

      if (!_remoteDescriptionApplied) {
        _trace(
          'processRemoteCandidates() queued until remote description',
          extra: <String, Object?>{'candidateKey': candidateKey},
        );
        _pendingRemoteCandidates.add(candidate);
        continue;
      }

      try {
        _trace(
          'addCandidate()',
          extra: <String, Object?>{'candidateKey': candidateKey},
        );
        await _peerConnection?.addCandidate(candidate);
        _trace(
          'addCandidate() done',
          extra: <String, Object?>{'candidateKey': candidateKey},
        );
      } catch (_) {
        _trace(
          'addCandidate() failed; queued',
          extra: <String, Object?>{'candidateKey': candidateKey},
        );
        _pendingRemoteCandidates.add(candidate);
      }
    }
  }

  String _candidateKey(Map<String, dynamic> candidate) {
    final candidateId = candidate['candidateId']?.toString().trim() ?? '';
    if (candidateId.isNotEmpty) {
      return candidateId;
    }

    return <String>[
      candidate['candidate']?.toString().trim() ?? '',
      candidate['sdpMid']?.toString().trim() ?? '',
      candidate['sdpMLineIndex']?.toString().trim() ?? '',
      candidate['timestampMs']?.toString().trim() ?? '',
    ].join('|');
  }

  Future<void> _flushPendingRemoteCandidates() async {
    if (!_remoteDescriptionApplied || _pendingRemoteCandidates.isEmpty) {
      _trace(
        'flushPendingRemoteCandidates() skipped',
        extra: <String, Object?>{
          'remoteDescriptionApplied': _remoteDescriptionApplied,
          'pendingCount': _pendingRemoteCandidates.length,
        },
      );
      return;
    }

    _trace(
      'flushPendingRemoteCandidates() start',
      extra: <String, Object?>{'pendingCount': _pendingRemoteCandidates.length},
    );
    final candidates = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    for (final candidate in candidates) {
      try {
        _trace(
          'flushPendingRemoteCandidates() addCandidate()',
          extra: <String, Object?>{
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
        await _peerConnection?.addCandidate(candidate);
        _trace(
          'flushPendingRemoteCandidates() addCandidate() done',
          extra: <String, Object?>{
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      } catch (_) {
        _trace(
          'flushPendingRemoteCandidates() addCandidate() failed; requeue',
          extra: <String, Object?>{
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
        _pendingRemoteCandidates.add(candidate);
      }
    }
  }

  Future<void> _toggleMute() async {
    _trace('toggleMute() start');
    try {
      final tracks = _localStream?.getAudioTracks() ?? const [];
      if (tracks.isEmpty) {
        _trace('toggleMute() no audio tracks');
        return;
      }

      _muted = !_muted;
      _trace(
        'toggleMute() state changed',
        extra: <String, Object?>{
          'muted': _muted,
          'trackCount': tracks.length,
        },
      );
      for (final track in tracks) {
        track.enabled = !_muted;
        _trace(
          'toggleMute() applying microphone state',
          extra: <String, Object?>{
            'trackId': track.id,
            'trackEnabled': track.enabled,
          },
        );
        await Helper.setMicrophoneMute(_muted, track);
      }
      if (mounted) {
        setState(() {});
      }
      _trace('toggleMute() done');
    } catch (error, stackTrace) {
      _traceError('toggleMute() failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> _hangUp() async {
    _trace('hangUp() start');
    await _endCallWithStatus('ended');
  }

  Future<void> _failCall() async {
    _trace('failCall() start');
    await _endCallWithStatus('failed');
  }

  Future<void> _endCallWithStatus(String status) async {
    if (_ending) {
      _trace(
        'endCallWithStatus() skipped because already ending',
        extra: <String, Object?>{'status': status},
      );
      return;
    }
    _ending = true;
    _trace(
      'endCallWithStatus() start',
      extra: <String, Object?>{'status': status},
    );
    try {
      if (status == 'failed') {
        await _service.markFailed(widget.orderId);
      } else {
        await _service.markEnded(widget.orderId);
      }
      _trace('backend updated', extra: <String, Object?>{
        'operation': status == 'failed' ? 'markFailed' : 'markEnded',
        'status': status,
      });
      _trace(
        'endCallWithStatus() status persisted',
        extra: <String, Object?>{'status': status},
      );
      await _cleanupAndClose(popScreen: true, removeSession: false);
      _trace(
        'endCallWithStatus() done',
        extra: <String, Object?>{'status': status},
      );
    } catch (error, stackTrace) {
      _traceError(
        'endCallWithStatus() failed',
        error,
        stackTrace,
        extra: <String, Object?>{'status': status},
      );
      rethrow;
    }
  }

  Future<void> _cleanupAndClose({
    required bool popScreen,
    required bool removeSession,
  }) async {
    _trace(
      'cleanupAndClose() start',
      extra: <String, Object?>{
        'popScreen': popScreen,
        'removeSession': removeSession,
      },
    );
    try {
      _cancelRingTimeout();
      _sessionSub?.cancel();
      _sessionSub = null;
      await _stopRingbackTone();

      final pc = _peerConnection;
      _peerConnection = null;
      if (pc != null) {
        _trace('cleanupAndClose() closing peer connection');
        await pc.close();
        _trace('cleanupAndClose() peer connection closed');
      }

      final stream = _localStream;
      _localStream = null;
      if (stream != null) {
        _trace(
          'cleanupAndClose() disposing local stream',
          extra: <String, Object?>{'streamId': stream.id},
        );
        for (final track in stream.getTracks()) {
          track.stop();
        }
        stream.dispose();
      }
      final remoteStream = _remoteStream;
      _remoteStream = null;
      if (remoteStream != null && _ownsRemoteStream) {
        _trace(
          'cleanupAndClose() disposing owned remote stream',
          extra: <String, Object?>{'streamId': remoteStream.id},
        );
        await remoteStream.dispose();
      }
      _remoteRenderer.srcObject = null;
      _trace('cleanupAndClose() remote renderer cleared');

      if (WebRTC.platformIsAndroid) {
        await Helper.clearAndroidCommunicationDevice();
        _trace('cleanupAndClose() android communication device cleared');
      }

      await _restoreMediaAudioConfiguration();
      await _resumeBackgroundMusicIfNeeded();

      if (removeSession) {
        _trace('cleanupAndClose() clearing session');
        await _service.clearSession(widget.orderId);
      }

      if (!mounted || !popScreen) {
        _trace(
          'cleanupAndClose() finished without pop',
          extra: <String, Object?>{
            'mounted': mounted,
            'popScreen': popScreen,
          },
        );
        return;
      }

      if (Get.key.currentState?.canPop() ?? false) {
        _trace('cleanupAndClose() popping route');
        Get.back();
      }
      _trace('cleanupAndClose() done');
    } catch (error, stackTrace) {
      _traceError(
        'cleanupAndClose() failed',
        error,
        stackTrace,
        extra: <String, Object?>{
          'popScreen': popScreen,
          'removeSession': removeSession,
        },
      );
      rethrow;
    }
  }

  void _closeLocalResources() {
    _trace('closeLocalResources() start');
    _cancelRingTimeout();
    unawaited(_sessionSub?.cancel());
    _sessionSub = null;
    unawaited(_stopRingbackTone());

    final pc = _peerConnection;
    _peerConnection = null;
    if (pc != null) {
      _trace('closeLocalResources() closing peer connection');
    }
    unawaited(pc?.close());

    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      _trace(
        'closeLocalResources() disposing local stream',
        extra: <String, Object?>{'streamId': stream.id},
      );
      for (final track in stream.getTracks()) {
        track.stop();
      }
      stream.dispose();
    }
    final remoteStream = _remoteStream;
    _remoteStream = null;
    if (remoteStream != null && _ownsRemoteStream) {
      _trace(
        'closeLocalResources() disposing owned remote stream',
        extra: <String, Object?>{'streamId': remoteStream.id},
      );
      unawaited(remoteStream.dispose());
    }
    _remoteRenderer.srcObject = null;
    _trace('closeLocalResources() remote renderer cleared');

    if (WebRTC.platformIsAndroid) {
      unawaited(Helper.clearAndroidCommunicationDevice());
      _trace('closeLocalResources() android communication device cleared');
    }

    unawaited(_restoreMediaAudioConfiguration());
    unawaited(_resumeBackgroundMusicIfNeeded());
    _trace('closeLocalResources() done');
  }

  Future<void> _stopRingbackTone() async {
    if (!_ringbackPlaying) {
      _trace('stopRingbackTone() skipped because not playing');
      return;
    }

    try {
      _trace('stopRingbackTone() start');
      await FlutterRingtonePlayer().stop();
    } catch (error) {
      _traceError('stopRingbackTone() failed', error, StackTrace.current);
    } finally {
      _ringbackPlaying = false;
      _trace('stopRingbackTone() done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.incoming
        ? (_isArabic ? 'مكالمة واردة' : 'Incoming voice call')
        : (_isArabic ? 'مكالمة صوتية' : 'Voice call');
    final subtitle = widget.incoming
        ? (_isArabic
            ? 'يريد $_peerDisplayName التحدث معك بخصوص الطلب #${widget.orderId}'
            : '$_peerDisplayName wants to talk about order #${widget.orderId}')
        : (_isArabic
            ? 'جاري الاتصال بـ $_peerDisplayName بخصوص الطلب #${widget.orderId}'
            : 'Calling $_peerDisplayName about order #${widget.orderId}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_hangUp());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07111E),
        body: Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            children: [
              const Positioned.fill(child: _VoiceCallBackdrop()),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: 0.01,
                    child: SizedBox(
                      width: 1,
                      height: 1,
                      child: RTCVideoView(_remoteRenderer),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 680;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        compact ? 12 : 20,
                        20,
                        compact ? 14 : 24,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _RoundIconButton(
                                icon: Icons.close_rounded,
                                onTap: _hangUp,
                              ),
                              const Spacer(),
                              _ConnectionStatusBadge(
                                label: _localizedStatus,
                                icon: _statusIcon,
                                color: _statusColor,
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 18 : 34),
                          _SecureCallPill(
                            text: _isArabic
                                ? 'مكالمة داخلية آمنة'
                                : 'Secure in-app call',
                          ),
                          const Spacer(),
                          _CallAvatar(
                            name: _peerDisplayName,
                            connected: _connected,
                            color: _statusColor,
                          ),
                          SizedBox(height: compact ? 18 : 28),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.74),
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 18 : 30),
                          _CallParticipantsCard(
                            meLabel: _isArabic ? 'أنت' : 'You',
                            meName: _myDisplayName,
                            peerLabel: _roleLabel(widget.peerRole),
                            peerName: _peerDisplayName,
                            peerActive: _connected,
                            connectedText: _isArabic ? 'متصل' : 'Connected',
                            waitingText:
                                _isArabic ? 'بانتظار الاتصال' : 'Waiting',
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CallActionButton(
                                icon: widget.incoming && !_connected
                                    ? (_answering
                                        ? Icons.hourglass_top_rounded
                                        : Icons.call_rounded)
                                    : (_muted
                                        ? Icons.mic_off_rounded
                                        : Icons.mic_rounded),
                                label: widget.incoming && !_connected
                                    ? (_answering
                                        ? (_isArabic
                                            ? 'جاري الرد'
                                            : 'Answering')
                                        : (_isArabic ? 'رد' : 'Answer'))
                                    : (_muted
                                        ? (_isArabic ? 'تشغيل' : 'Unmute')
                                        : (_isArabic ? 'كتم' : 'Mute')),
                                backgroundColor: widget.incoming && !_connected
                                    ? const Color(0xFF59D98E)
                                        .withValues(alpha: 0.20)
                                    : Colors.white.withValues(alpha: 0.10),
                                borderColor: widget.incoming && !_connected
                                    ? const Color(0xFF59D98E)
                                        .withValues(alpha: 0.30)
                                    : Colors.white.withValues(alpha: 0.12),
                                onTap: widget.incoming && !_connected
                                    ? _answerIncomingCall
                                    : _toggleMute,
                              ),
                              const SizedBox(width: 18),
                              _CallActionButton(
                                icon: Icons.call_end_rounded,
                                label: _isArabic ? 'إنهاء' : 'End',
                                backgroundColor: const Color(0xFFE53935),
                                borderColor: const Color(0xFFFF8A80)
                                    .withValues(alpha: 0.30),
                                onTap: _hangUp,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_initializing)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.34),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isArabic
                                  ? 'جاري تجهيز الصوت...'
                                  : 'Preparing audio...',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceCallBackdrop extends StatelessWidget {
  const _VoiceCallBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.25,
          colors: [
            Color(0xFF224DFF),
            Color(0xFF0E1A3D),
            Color(0xFF030814),
          ],
          stops: [0, 0.42, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _BlurOrb(
              size: 230,
              color: const Color(0xFF4DA3FF).withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _BlurOrb(
              size: 280,
              color: const Color(0xFF6BE4FF).withValues(alpha: 0.14),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _CallWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 70,
            spreadRadius: 28,
          ),
        ],
      ),
    );
  }
}

class _CallWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.18 + i * 0.12);
      final path = Path()..moveTo(0, y);
      path.cubicTo(
        size.width * 0.25,
        y - 34,
        size.width * 0.62,
        y + 38,
        size.width,
        y - 6,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _ConnectionStatusBadge extends StatelessWidget {
  const _ConnectionStatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _SecureCallPill extends StatelessWidget {
  const _SecureCallPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: Color(0xFF4DA3FF),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CallAvatar extends StatelessWidget {
  const _CallAvatar({
    required this.name,
    required this.connected,
    required this.color,
  });

  final String name;
  final bool connected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.88, end: connected ? 1.0 : 1.08),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 184 * value,
              height: 184 * value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
            ),
            Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    color.withValues(alpha: 0.20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: connected ? 0.30 : 0.16),
                    blurRadius: 46,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  connected ? Icons.graphic_eq_rounded : Icons.call_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CallParticipantsCard extends StatelessWidget {
  const _CallParticipantsCard({
    required this.meLabel,
    required this.meName,
    required this.peerLabel,
    required this.peerName,
    required this.peerActive,
    required this.connectedText,
    required this.waitingText,
  });

  final String meLabel;
  final String meName;
  final String peerLabel;
  final String peerName;
  final bool peerActive;
  final String connectedText;
  final String waitingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ParticipantTile(
              label: meLabel,
              name: meName,
              status: connectedText,
              active: true,
            ),
          ),
          Container(
            width: 1,
            height: 58,
            color: Colors.white.withValues(alpha: 0.10),
          ),
          Expanded(
            child: _ParticipantTile(
              label: peerLabel,
              name: peerName,
              status: peerActive ? connectedText : waitingText,
              active: peerActive,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.label,
    required this.name,
    required this.status,
    required this.active,
  });

  final String label;
  final String name;
  final String status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF4DA3FF) : const Color(0xFFFFC857);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: 118,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
