import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'order_voice_call_service.dart';
import 'order_voice_call_alert_service.dart';
import 'voice_call_notification_service.dart';

class VoiceCallBackgroundService {
  static VoiceCallBackgroundService? _instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final OrderVoiceCallService _voiceCallService;
  final OrderVoiceCallAlertService _alertService;
  final VoiceCallNotificationService _notificationService;

  Timer? _periodicCheckTimer;
  bool _isRunning = false;

  VoiceCallBackgroundService._internal(
    this._voiceCallService,
    this._alertService,
    this._notificationService,
  );

  static VoiceCallBackgroundService getInstance({
    required OrderVoiceCallService voiceCallService,
    required OrderVoiceCallAlertService alertService,
    required VoiceCallNotificationService notificationService,
  }) {
    _instance ??= VoiceCallBackgroundService._internal(
      voiceCallService,
      alertService,
      notificationService,
    );
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isRunning) return;

    // إعداد خدمة الخلفية
    await _setupBackgroundService();

    // بدء خدمة الخلفية
    await _startBackgroundService();

    // إعداد الموقت للتحقق الدوري من المكالمات
    _setupPeriodicCheck();

    _isRunning = true;
  }

  Future<void> _setupBackgroundService() async {
    // إعداد الإشعارات للخدمة في الخلفية
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: settings);

    // إنشاء قناة الإشعارات للخدمة في الخلفية
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'voice_call_background_service',
        'خدمة المكالمات في الخلفية',
        description: 'خدمة المكالمات في الخلفية',
        importance: Importance.low,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _startBackgroundService() async {
    if (Platform.isAndroid) {
      // بدء خدمة الخلفية على Android
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'voice_call_background_service',
          initialNotificationTitle: 'خدمة المكالمات نشطة',
          initialNotificationContent: 'التحقق من وجود مكالمات واردة',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: _onIosForeground,
          onBackground: _onIosBackground,
        ),
      );

      await service.startService();
    }
  }

  Future<bool> _onStart(ServiceInstance service) async {
    // إعداد إشعار الخدمة في الخلفية
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'خدمة المكالمات نشطة',
        content: 'التحقق من وجود مكالمات واردة',
      );
    }

    // بدء فحص دوري للمكالمات
    _startPeriodicCheck();

    // استمع إلى الأحداث من الخدمة
    service.on('stopService').listen((event) {
      _stopBackgroundService();
    });

    return true;
  }
  Future<bool> _onIosForeground(ServiceInstance service) async {
    // إعداد إشعار الخدمة في الخلفية على iOS
    await _notificationsPlugin.show(
      id: 888,
      title: 'خدمة المكالمات نشطة',
      body: 'التحقق من وجود مكالمات واردة',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'voice_call_background_service',
          'خدمة المكالمات في الخلفية',
        ),
      ),
    );

    return true;
  }

  Future<bool> _onIosBackground(ServiceInstance service) async {
    // معالجة الخدمة في الخلفية على iOS
    // يمكن إضافة منطق هنا للتحقق من المكالمات
    return true;
  }

  void _setupPeriodicCheck() {
    // إعداد فحص دوري للمكالمات
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForIncomingCalls();
    });
  }

  void _startPeriodicCheck() {
    if (_periodicCheckTimer == null) {
      _setupPeriodicCheck();
    }
  }

  void _stopPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  Future<void> _checkForIncomingCalls() async {
    try {
      // الحصول على الطلب النشط إذا كان موجودًا
      final activeOrderId = _alertService.activeOrderId;
      if (activeOrderId != null && activeOrderId.isNotEmpty) {
        final session = await _voiceCallService.loadSession(activeOrderId);
        if (session != null && session.status == 'ringing') {
          // عرض إشعار بالمكالمة الواردة
          await _notificationService.showCallNotification(
            orderId: session.orderId,
            callerName: session.callerName.isNotEmpty
                ? session.callerName
                : (session.callerRole == 'driver' ? 'السائق' : 'العميل'),
            title: 'مكالمة واردة',
            body: '${session.callerName} يتصل بخصوص الطلب #${session.orderId}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for incoming calls in background: $e');
    }
  }

  Future<void> _stopBackgroundService() async {
    // إيقاف خدمة الخلفية
    _stopPeriodicCheck();
    _isRunning = false;

    if (Platform.isAndroid) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
    }
  }

  Future<void> restart() async {
    // إعادة تشغيل خدمة الخلفية
    await _stopBackgroundService();
    await initialize();
  }
}
