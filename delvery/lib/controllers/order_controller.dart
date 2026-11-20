import 'dart:async';
import 'dart:convert';

import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_order_voice_call_alert_service.dart';
import 'package:delvery/core/services/driver_order_voice_call_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:delvery/screens/order_voice_call_screen.dart';
import 'package:delvery/screens/tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delvery/core/localization/driver_text.dart';

class OrderController extends GetxController {
  OrderController(this.sessionService, this.ordersService);

  final DriverSessionService sessionService;
  final DriverOrdersService ordersService;
  final DriverOrderVoiceCallService _voiceCallService = Get.find();

  final RxString selectedQuickReply = tx('أنا في الطريق.').obs;
  final RxString deliveryError = ''.obs;
  final RxString deliveryProgressLabel = tx('مكلف').obs;

  StreamSubscription<OrderVoiceCallSession?>? _voiceCallSubscription;
  bool _voiceCallPromptOpen = false;
  String? _lastIncomingVoiceCallKey;
  bool _sendingEmergency = false;

  DriverOrder? get order => ordersService.activeOrder.value;

  @override
  void onInit() {
    super.onInit();
    ever<DriverOrder?>(ordersService.activeOrder, (order) {
      deliveryProgressLabel.value = _labelForStatus(order?.status);
      _setupVoiceCallMonitoring(order);
    });
    ever<int?>(sessionService.driverId, (_) {
      _setupVoiceCallMonitoring(ordersService.activeOrder.value);
    });
    _setupVoiceCallMonitoring(ordersService.activeOrder.value);
  }

  Future<void> goToRestaurant() async {
    final updated = await ordersService.updateActiveOrder(
      DriverOrderStatus.headingToRestaurant,
    );
    if (updated) {
      openTrackingMap();
    }
  }

  Future<void> markArrivedAtRestaurant() async {
    await ordersService.updateActiveOrder(
      DriverOrderStatus.arrivedAtRestaurant,
    );
  }

  Future<void> markPickedUp() async {
    await ordersService.updateActiveOrder(DriverOrderStatus.pickedUp);
  }

  Future<void> goToCustomer() async {
    final updated = await ordersService.updateActiveOrder(
      DriverOrderStatus.headingToCustomer,
    );
    if (updated) {
      openTrackingMap();
    }
  }

  Future<void> markArrivedAtCustomer() async {
    await ordersService.updateActiveOrder(DriverOrderStatus.arrivedAtCustomer);
  }

  void openTracking() {
    Get.toNamed(AppRoutes.currentOrder);
  }

  void openTrackingMap([DriverOrder? targetOrder]) {
    Get.to(() => TrackingScreen(order: targetOrder ?? order));
  }

  Future<void> callCustomer() async {
    final currentOrder = order;
    final driverId = sessionService.driverId.value ?? 0;
    if (currentOrder == null || driverId <= 0) {
      return;
    }

    final rawCustomerPeerId = currentOrder.customerUserId.trim();
    final customerPeerId =
        rawCustomerPeerId.isEmpty ||
            rawCustomerPeerId == '0' ||
            rawCustomerPeerId.toLowerCase() == 'null'
        ? ''
        : rawCustomerPeerId;

    await Get.to(
      () => OrderVoiceCallScreen.outgoing(
        orderId: currentOrder.id.toString(),
        myRole: 'driver',
        myId: driverId.toString(),
        myName: sessionService.profile.value.name,
        peerRole: 'user',
        peerId: customerPeerId,
        peerName: currentOrder.customerName.isNotEmpty
            ? currentOrder.customerName
            : 'Customer',
      ),
    );
  }

  Future<void> callRestaurant() async {
    final phone = order?.restaurantPhone;
    if (phone == null || phone.isEmpty) {
      return;
    }
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _setupVoiceCallMonitoring(DriverOrder? currentOrder) {
    final orderId = currentOrder?.id.toString().trim() ?? '';
    if (orderId.isEmpty || orderId == '0') {
      _voiceCallSubscription?.cancel();
      _voiceCallSubscription = null;
      return;
    }

    if (Get.isRegistered<DriverOrderVoiceCallAlertService>()) {
      return;
    }

    _voiceCallSubscription?.cancel();
    _voiceCallSubscription = _voiceCallService.watchSession(orderId).listen((
      session,
    ) async {
      if (isClosed || session == null) {
        return;
      }

      final driverId = sessionService.driverId.value ?? 0;
      final driverName = sessionService.profile.value.name;

      final sessionKey =
          '${session.orderId}:${session.createdAtMs}:${session.callerId}:${session.calleeId}';

      if (session.status == 'ringing' &&
          session.isIncomingFor('driver', driverId.toString()) &&
          !_voiceCallPromptOpen &&
          _lastIncomingVoiceCallKey != sessionKey) {
        _lastIncomingVoiceCallKey = sessionKey;
        await _showIncomingVoiceCallSheet(
          session,
          driverId: driverId,
          driverName: driverName,
        );
        return;
      }

      if (session.status != 'ringing') {
        _lastIncomingVoiceCallKey = null;
        if (_voiceCallPromptOpen) {
          if (Get.isBottomSheetOpen == true) {
            Get.back();
          }
          _voiceCallPromptOpen = false;
        }
      }
    });
  }

  Future<void> _showIncomingVoiceCallSheet(
    OrderVoiceCallSession session, {
    required int driverId,
    required String driverName,
  }) async {
    _voiceCallPromptOpen = true;
    await Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              Text(
                'Incoming voice call',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.callerName.isNotEmpty ? session.callerName : 'Customer',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The customer is calling you about order #${session.orderId}.',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        _voiceCallPromptOpen = false;
                        if (Get.isBottomSheetOpen == true) {
                          Get.back();
                        }
                        await _voiceCallService.markDeclined(session.orderId);
                      },
                      icon: const Icon(Icons.call_end_rounded),
                      label: const Text('Decline'),
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
                        _voiceCallPromptOpen = false;
                        if (Get.isBottomSheetOpen == true) {
                          Get.back();
                        }
                        await Get.to(
                          () => OrderVoiceCallScreen.incoming(
                            orderId: session.orderId,
                            myRole: 'driver',
                            myId: driverId.toString(),
                            myName: driverName,
                            peerRole: session.callerRole.isNotEmpty
                                ? session.callerRole
                                : 'user',
                            peerId: session.callerId,
                            peerName: session.callerName.isNotEmpty
                                ? session.callerName
                                : 'Customer',
                          ),
                        );
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Accept'),
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
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      barrierColor: Colors.black54,
    ).whenComplete(() {
      _voiceCallPromptOpen = false;
    });
  }

  Future<void> sendQuickReply(String message) async {
    selectedQuickReply.value = message;
    ordersService.sendQuickReply(message);
    final uri = Uri.parse(
      'sms:${order?.customerPhone ?? ''}?body=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void showEmergencySheet() {
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DriverUi.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tx('الطوارئ'),
                style: Get.textTheme.titleLarge?.copyWith(
                  color: DriverUi.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tx('اختر السبب وسيتم إرساله تلقائيًا إلى العميل والمطعم والمستر.'),
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: DriverUi.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _reasonChip(tx('ازدحام')),
                  _reasonChip(tx('انتظار بالمطعم')),
                  _reasonChip(tx('خطأ بالعنوان')),
                  _reasonChip(tx('مشكلة بالمستلم')),
                  _reasonChip(tx('مشكلة بالمركبة')),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _reasonChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        unawaited(_handleEmergencyReason(label));
      },
      backgroundColor: DriverUi.primarySoft,
      side: BorderSide(color: DriverUi.line),
      labelStyle: const TextStyle(
        color: DriverUi.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Future<void> _handleEmergencyReason(String label) async {
    if (_sendingEmergency) {
      return;
    }

    _sendingEmergency = true;
    try {
      final ok = await ordersService.setEmergencyReason(label);
      if (!ok) {
        Get.snackbar(
          tx('تعذر الإرسال'),
          tx('لم يتم إرسال رسالة الطوارئ. حاول مرة أخرى.'),
        );
        return;
      }

      deliveryError.value = label;
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      Get.snackbar(
        tx('تم الإرسال'),
        tx('تم إرسال رسالة الطوارئ إلى شات العميل والمطعم والمستر.'),
      );
    } finally {
      _sendingEmergency = false;
    }
  }

  Future<bool> confirmDeliveryCode(String code) async {
    final current = order;
    if (current == null) {
      return false;
    }

    return ordersService.confirmDeliveryCode(code.trim());
  }

  Future<void> showDeliveryCodeDialog() async {
    final current = order;
    if (current == null) {
      return;
    }

    if (current.status != DriverOrderStatus.awaitingVerification) {
      Get.snackbar(
        tx('الرمز غير جاهز'),
        tx('يجب تصوير الطلب أولًا قبل إدخال رمز التحقق.'),
      );
      return;
    }

    final context = Get.context ?? Get.overlayContext;
    if (context == null) {
      return;
    }

    final codeController = TextEditingController();
    final enteredCode = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(tx('إدخال رمز التحقق')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tx('اطلب من العميل الرمز المكون من 4 أرقام ثم أدخله هنا لإكمال التسليم.'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 4,
                autofocus: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  counterText: '',
                  labelText: tx('رمز من 4 أرقام'),
                ),
                onSubmitted: (_) {
                  Navigator.of(
                    dialogContext,
                    rootNavigator: true,
                  ).pop(codeController.text);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              },
              child: Text(tx('إلغاء')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                  rootNavigator: true,
                ).pop(codeController.text);
              },
              child: Text(tx('تأكيد')),
            ),
          ],
        );
      },
    );

    codeController.dispose();

    final code = enteredCode?.trim() ?? '';
    if (code.isEmpty) {
      return;
    }

    final ok = await confirmDeliveryCode(code);
    if (!ok) {
      Get.snackbar(
        tx('فشل إثبات التسليم'),
        tx('تعذر التحقق من الرمز. تأكد من الرمز وحاول مرة أخرى.'),
      );
      return;
    }

    Get.offNamed(
      AppRoutes.deliverySuccess,
      arguments: {
        'orderId': current.id,
        'elapsedText': sessionService.shiftElapsedText,
      },
    );
    Get.snackbar(
      tx('تم التسليم'),
      trParam('تم تسليم الطلب #{id} بنجاح.', 'Order #{id} delivered successfully.', {
        'id': current.id,
      }),
    );
  }

  Future<void> markDelivered() async {
    await markDeliveredWithPhoto();
  }

  Future<void> markDeliveredWithPhoto() async {
    final current = order;
    if (current == null) {
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final ok = await ordersService.completeDeliveryWithPhoto(
        imageBase64: base64Encode(bytes),
        imageName: picked.name.isNotEmpty
            ? picked.name
            : 'delivery_${current.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (ok) {
        await showDeliveryCodeDialog();
      }
    } catch (error) {
      Get.snackbar(tx('فشل إثبات التسليم'), error.toString());
    }
  }

  String _labelForStatus(DriverOrderStatus? status) {
    switch (status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
        return tx('مكلف');
      case DriverOrderStatus.headingToRestaurant:
        return tx('في الطريق إلى المطعم');
      case DriverOrderStatus.arrivedAtRestaurant:
        return tx('في المطعم');
      case DriverOrderStatus.pickedUp:
        return tx('تم الاستلام');
      case DriverOrderStatus.headingToCustomer:
        return tx('في الطريق إلى المستلم');
      case DriverOrderStatus.arrivedAtCustomer:
        return tx('وصل إلى المستلم');
      case DriverOrderStatus.awaitingVerification:
        return tx('بانتظار رمز التحقق');
      case DriverOrderStatus.delivered:
        return tx('تم التسليم');
      case null:
        return tx('لا يوجد طلب نشط');
    }
  }
}
