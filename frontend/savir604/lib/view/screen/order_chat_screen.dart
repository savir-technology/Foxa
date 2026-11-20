import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/order_chat_service.dart';
import 'package:tks/core/services/order_voice_call_alert_service.dart';
import 'package:tks/core/services/order_voice_call_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/screen/order_voice_call_screen.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';

class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({
    super.key,
    required this.order,
  });

  final OrdersModel order;

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  late final OrderChatService _chatService;
  late final OrderVoiceCallService _voiceCallService;
  late final MyServices _services;
  late final AudioPlayer _audioPlayer;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  StreamSubscription<OrderVoiceCallSession?>? _voiceCallSubscription;
  bool _loading = true;
  bool _sending = false;
  bool _voiceCallPromptOpen = false;
  String? _playingAudioUrl;
  String? _lastIncomingVoiceCallKey;
  List<OrderChatMessage> _messages = const [];

  bool get isArabic => Get.locale?.languageCode == 'ar';
  OrdersModel get order => widget.order;
  String get orderId => (order.ordersId ?? '').trim();
  int get userId => _services.sharedPreferences.getInt('id') ?? 0;
  String get userName =>
      _services.sharedPreferences.getString('username') ??
      (isArabic ? 'المستخدم' : 'User');
  int get driverId => int.tryParse((order.deliveryId ?? '').trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _chatService = OrderChatService();
    _voiceCallService = Get.find<OrderVoiceCallService>();
    _services = Get.find<MyServices>();
    _audioPlayer = AudioPlayer();
    _refresh();
    _listenForVoiceCalls();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _voiceCallSubscription?.cancel();
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }
    try {
      final messages = await _chatService.fetchMessages(
        orderId: orderId.isEmpty ? '0' : orderId,
        scope: 'order',
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage([String? presetMessage]) async {
    final text = (presetMessage ?? _messageController.text).trim();
    if (text.isEmpty || _sending || orderId.isEmpty || userId <= 0) {
      return;
    }

    setState(() => _sending = true);
    try {
      final ok = await _chatService.sendMessage(
        orderId: orderId,
        scope: 'order',
        senderId: userId,
        senderRole: 'user',
        message: text,
      );
      if (ok) {
        _messageController.clear();
        await _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _toggleAudio(String audioUrl) async {
    final resolved = AppLink.resolveUrl(audioUrl);
    if (resolved.isEmpty) return;

    if (_playingAudioUrl == audioUrl) {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() => _playingAudioUrl = null);
      }
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(resolved));
      if (mounted) {
        setState(() => _playingAudioUrl = audioUrl);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _playingAudioUrl = null);
      }
      Get.snackbar(
        isArabic ? 'الصوت' : 'Audio',
        isArabic
            ? 'تعذر تشغيل الرسالة الصوتية.'
            : 'Unable to play the voice note.',
      );
    }
  }

  void _listenForVoiceCalls() {
    if (orderId.isEmpty) {
      return;
    }

    if (Get.isRegistered<OrderVoiceCallAlertService>()) {
      Get.find<OrderVoiceCallAlertService>().bindActiveOrderId(orderId);
      return;
    }

    _voiceCallSubscription?.cancel();
    _voiceCallSubscription = _voiceCallService.watchSession(orderId).listen(
      (session) async {
        if (!mounted || session == null) {
          return;
        }

        final sessionKey =
            '${session.orderId}:${session.createdAtMs}:${session.callerId}:${session.calleeId}';

        if (session.status == 'ringing' &&
            session.isIncomingFor('user', userId.toString()) &&
            !_voiceCallPromptOpen &&
            _lastIncomingVoiceCallKey != sessionKey) {
          _lastIncomingVoiceCallKey = sessionKey;
          await _showIncomingCallPrompt(session);
          return;
        }

        if (session.status != 'ringing') {
          _lastIncomingVoiceCallKey = null;
          if (_voiceCallPromptOpen && Get.isBottomSheetOpen == true) {
            Get.back();
          }
          _voiceCallPromptOpen = false;
        }
      },
    );
  }

  Future<void> _showIncomingCallPrompt(OrderVoiceCallSession session) async {
    if (_voiceCallPromptOpen || !mounted) {
      return;
    }

    final callerDisplayName = session.callerName.isNotEmpty
        ? session.callerName
        : (isArabic ? 'السائق' : 'Driver');
    _voiceCallPromptOpen = true;
    await Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Directionality(
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.14),
                child: Icon(
                  Icons.call_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isArabic ? 'مكالمة واردة' : 'Incoming call',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                callerDisplayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'يريد $callerDisplayName التحدث معك بخصوص الطلب #$orderId.'
                    : 'Incoming voice call for order #$orderId.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.68),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _voiceCallService.markDeclined(session.orderId);
                        if (Get.isBottomSheetOpen == true) {
                          Get.back();
                        }
                        _voiceCallPromptOpen = false;
                      },
                      icon: const Icon(Icons.call_end_rounded),
                      label: Text(isArabic ? 'رفض' : 'Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD53F3F),
                        side: const BorderSide(color: Color(0xFFD53F3F)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (Get.isBottomSheetOpen == true) {
                          Get.back();
                        }
                        _voiceCallPromptOpen = false;
                        await Get.to(
                          () => OrderVoiceCallScreen.incoming(
                            orderId: session.orderId,
                            myRole: 'user',
                            myId: userId.toString(),
                            myName: userName,
                            peerRole: session.callerRole.isNotEmpty
                                ? session.callerRole
                                : 'driver',
                            peerId: session.callerId,
                            peerName: session.callerName.isNotEmpty
                                ? session.callerName
                                : (isArabic ? 'السائق' : 'Driver'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: Text(isArabic ? 'رد' : 'Answer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
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
    );

    _voiceCallPromptOpen = false;
  }

  Future<void> _callDriver() async {
    if (orderId.isEmpty || driverId <= 0 || userId <= 0) {
      Get.snackbar(
        isArabic ? 'المكالمة' : 'Call',
        isArabic
            ? 'لا يمكن بدء المكالمة قبل تعيين السائق للطلب.'
            : 'The driver must be assigned before starting a call.',
      );
      return;
    }

    await Get.to(
      () => OrderVoiceCallScreen.outgoing(
        orderId: orderId,
        myRole: 'user',
        myId: userId.toString(),
        myName: userName,
        peerRole: 'driver',
        peerId: driverId.toString(),
        peerName: isArabic ? 'السائق' : 'Driver',
      ),
    );
  }

  void _openTracking() {
    if (orderId.isEmpty) {
      Get.snackbar(
        isArabic ? 'التتبع' : 'Tracking',
        isArabic
            ? 'لا يمكن فتح التتبع بدون رقم طلب.'
            : 'Tracking requires an order number.',
      );
      return;
    }

    Get.toNamed(
      AppRoutes.orderTracking,
      arguments: order.toJson(),
    );
  }

  void _openQuickActions() {
    Get.bottomSheet(
      Directionality(
        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              _ActionSheetItem(
                icon: Icons.call_rounded,
                title: isArabic ? 'اتصال بالسائق' : 'Call driver',
                subtitle: isArabic
                    ? 'بدء مكالمة صوتية مباشرة داخل التطبيق.'
                    : 'Start an in-app voice call.',
                color: const Color(0xFFFF6500),
                onTap: () async {
                  if (Get.isBottomSheetOpen == true) {
                    Get.back();
                  }
                  await _callDriver();
                },
              ),
              const SizedBox(height: 10),
              _ActionSheetItem(
                icon: Icons.route_outlined,
                title: isArabic ? 'تتبع الطلب' : 'Track order',
                subtitle: isArabic
                    ? 'الانتقال إلى صفحة التتبع على الخريطة.'
                    : 'Open the live tracking map.',
                color: const Color(0xFFFF6500),
                onTap: () {
                  if (Get.isBottomSheetOpen == true) {
                    Get.back();
                  }
                  _openTracking();
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String get _statusLabel {
    final status = (order.status ?? order.ordersStatus ?? 'pending')
        .toString()
        .toLowerCase()
        .trim();
    switch (status) {
      case '0':
      case 'pending':
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case '1':
      case 'accepted':
      case 'approved':
        return isArabic ? 'تم القبول' : 'Accepted';
      case '2':
      case 'preparing':
        return isArabic ? 'قيد التحضير' : 'Preparing';
      case '3':
      case 'on_the_way':
      case 'delivering':
        return isArabic ? 'في الطريق' : 'On the way';
      case '4':
      case 'delivered':
      case 'completed':
        return isArabic ? 'تم التوصيل' : 'Delivered';
      default:
        return status.isEmpty ? (isArabic ? 'الطلب' : 'Order') : status;
    }
  }

  String get _orderTimeLabel {
    final raw = (order.ordersDatetime ?? '').trim();
    if (raw.isEmpty) {
      return isArabic ? 'اليوم' : 'Today';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final locale = isArabic ? 'ar' : 'en';
    return DateFormat('h:mm a', locale).format(parsed);
  }

  String get _addressLabel {
    final parts = <String>[
      (order.deliveryDisplayAddress).trim(),
      (order.ordersRecipientAddressName ?? '').trim(),
      (order.ordersRecipientAddressLine ?? '').trim(),
      (order.ordersRecipientLocationNote ?? '').trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return isArabic ? 'العنوان غير متوفر' : 'Address not available';
    }
    return parts.first;
  }

  List<_FeedItem> _buildFeedItems() {
    final items = <_FeedItem>[];
    DateTime? lastDate;
    final today = DateTime.now();

    for (final message in _messages) {
      final createdAt = message.createdAt;
      if (createdAt != null) {
        final currentDate =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (lastDate == null || currentDate != lastDate) {
          items.add(
            _FeedItem.date(
              _formatDateLabel(
                createdAt,
                today: today,
              ),
            ),
          );
          lastDate = currentDate;
        }
      }

      items.add(_FeedItem.message(message));
    }

    return items;
  }

  String _formatDateLabel(
    DateTime date, {
    required DateTime today,
  }) {
    final locale = isArabic ? 'ar' : 'en';
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));
    if (dateOnly == todayOnly) {
      return isArabic ? 'اليوم' : 'Today';
    }
    if (dateOnly == yesterdayOnly) {
      return isArabic ? 'أمس' : 'Yesterday';
    }
    return DateFormat('d MMM', locale).format(date);
  }

  List<String> _quickReplies() {
    if (isArabic) {
      return const [
        'شكراً لكم',
        'أين طلبي؟',
        'مشكلة في الطلب',
        'إلغاء الطلب',
      ];
    }

    return const [
      'Thank you',
      'Where is my order?',
      'Problem with the order',
      'Cancel order',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textDirection =
        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final feedItems = _buildFeedItems();
    final imageUrls = <String>[
      if (_cleanDisplayText(order.storeBannerUrl).isNotEmpty)
        AppLink.resolveUrl(_cleanDisplayText(order.storeBannerUrl)),
      if (_cleanDisplayText(order.vendorLogo).isNotEmpty)
        AppLink.resolveUrl(_cleanDisplayText(order.vendorLogo)),
    ];

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                _TopBar(
                  isArabic: isArabic,
                  onBack: Get.back,
                  onMenuTap: _openQuickActions,
                ),
                const SizedBox(height: 14),
                _OrderSummaryCard(
                  isArabic: isArabic,
                  imageUrls: imageUrls,
                  storeName: _cleanDisplayText(order.restaurantDisplayName),
                  orderId: orderId,
                  statusLabel: _statusLabel,
                  addressLabel: _addressLabel,
                  timeLabel: _orderTimeLabel,
                  onTrackTap: _openTracking,
                ),
                const SizedBox(height: 12),
                _ActionStrip(
                  isArabic: isArabic,
                  onTrackTap: _openTracking,
                  onCallTap: _callDriver,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: feedItems.length,
                            itemBuilder: (context, index) {
                              final item = feedItems[index];
                              if (item.kind == _FeedItemKind.date) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: _DateChip(label: item.label ?? ''),
                                  ),
                                );
                              }

                              final message = item.message!;
                              final isMine = message.isFromUser;
                              final senderLabel =
                                  _senderLabel(message.senderRole);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: isMine
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMine) ...[
                                      _MessageAvatar(label: senderLabel),
                                      const SizedBox(width: 10),
                                    ],
                                    Flexible(
                                      child: _MessageBubble(
                                        message: message,
                                        isMine: isMine,
                                        senderLabel: senderLabel,
                                        isArabic: isArabic,
                                        onPlayAudio: _toggleAudio,
                                        playingAudioUrl: _playingAudioUrl,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final reply in _quickReplies()) ...[
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 10),
                          child: _QuickReplyChip(
                            label: reply,
                            onTap: () => _sendMessage(reply),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ComposerBar(
                  isArabic: isArabic,
                  messageController: _messageController,
                  sending: _sending,
                  onAddTap: _openQuickActions,
                  onEmojiTap: () {
                    Get.snackbar(
                      isArabic ? 'قريباً' : 'Soon',
                      isArabic
                          ? 'إضافة الرموز التعبيرية ستكون في تحديث قادم.'
                          : 'Emoji support will be added in a future update.',
                    );
                  },
                  onSendTap: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _senderLabel(String senderRole) {
    switch (senderRole.toLowerCase().trim()) {
      case 'driver':
        return isArabic ? 'السائق' : 'Driver';
      case 'vendor':
        return isArabic ? 'المتجر' : 'Store';
      case 'support':
        return isArabic ? 'الدعم' : 'Support';
      default:
        return isArabic ? 'الطرف الآخر' : 'Other';
    }
  }

  String _cleanDisplayText(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isArabic,
    required this.onBack,
    required this.onMenuTap,
  });

  final bool isArabic;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _CircleActionButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
          backgroundColor: theme.cardColor,
          iconColor: theme.colorScheme.onSurface,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Text(
                isArabic ? 'دردشة الطلب' : 'Order chat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic ? 'محادثة مرتبطة بالطلب' : 'Order-linked conversation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 12.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleActionButton(
          icon: Icons.more_horiz_rounded,
          onTap: onMenuTap,
          backgroundColor: theme.cardColor,
          iconColor: theme.colorScheme.onSurface,
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.isArabic,
    required this.imageUrls,
    required this.storeName,
    required this.orderId,
    required this.statusLabel,
    required this.addressLabel,
    required this.timeLabel,
    required this.onTrackTap,
  });

  final bool isArabic;
  final List<String> imageUrls;
  final String storeName;
  final String orderId;
  final String statusLabel;
  final String addressLabel;
  final String timeLabel;
  final VoidCallback onTrackTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RestaurantLogo(
                imageUrls: imageUrls,
                label: storeName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            storeName.isEmpty
                                ? (isArabic ? 'المطعم' : 'Restaurant')
                                : storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusPill(label: statusLabel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '#${orderId.isEmpty ? '-' : orderId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.62),
                            fontSize: 12.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFFFF6500),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            addressLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.72),
                                  height: 1.25,
                                  fontSize: 12.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: Color(0xFFFF6500),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.72),
                                    fontSize: 12.5,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onTrackTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6500),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isArabic ? 'تتبع الطلب' : 'Track order',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.isArabic,
    required this.onTrackTap,
    required this.onCallTap,
  });

  final bool isArabic;
  final VoidCallback onTrackTap;
  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTrackTap,
            icon: const Icon(Icons.route_outlined, size: 18),
            label: Text(isArabic ? 'تتبع الطلب' : 'Track order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6500),
              side: const BorderSide(color: Color(0xFFBFD7C8)),
              backgroundColor: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onCallTap,
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text(isArabic ? 'اتصال مباشر' : 'Call driver'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6500),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
      ),
    );
  }
}

class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        label.toLowerCase() == 'driver'
            ? Icons.delivery_dining_rounded
            : Icons.headset_mic_rounded,
        color: Theme.of(context).cardColor,
        size: 18,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.senderLabel,
    required this.isArabic,
    required this.onPlayAudio,
    required this.playingAudioUrl,
  });

  final OrderChatMessage message;
  final bool isMine;
  final String senderLabel;
  final bool isArabic;
  final Future<void> Function(String audioUrl) onPlayAudio;
  final String? playingAudioUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.14)
        : theme.cardColor;
    final borderColor = isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.30)
        : theme.dividerColor;
    final timeLabel = _formatTime(message.createdAt);
    final hasAudio = (message.audioUrl ?? '').trim().isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            Text(
              senderLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message.message.isEmpty
                ? (isArabic ? 'رسالة صوتية' : 'Voice note')
                : message.message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                  fontSize: 15,
                ),
          ),
          if (hasAudio) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => onPlayAudio(message.audioUrl!),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      playingAudioUrl == message.audioUrl
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      playingAudioUrl == message.audioUrl
                          ? (isArabic ? 'إيقاف الصوت' : 'Stop audio')
                          : (isArabic ? 'تشغيل الصوت' : 'Play audio'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      fontSize: 11,
                    ),
              ),
              if (isMine) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  color: Color(0xFFFF6500),
                  size: 15,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    return DateFormat('h:mm a', isArabic ? 'ar' : 'en').format(value);
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).dividerColor),
        backgroundColor: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.isArabic,
    required this.messageController,
    required this.sending,
    required this.onAddTap,
    required this.onEmojiTap,
    required this.onSendTap,
  });

  final bool isArabic;
  final TextEditingController messageController;
  final bool sending;
  final VoidCallback onAddTap;
  final VoidCallback onEmojiTap;
  final Future<void> Function([String? presetMessage]) onSendTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7ECE7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleActionButton(
            icon: Icons.add_rounded,
            onTap: onAddTap,
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSendTap(),
              decoration: InputDecoration(
                hintText:
                    isArabic ? 'اكتب رسالتك هنا...' : 'Write your message...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFBFD7C8)),
                ),
                suffixIcon: IconButton(
                  onPressed: onEmojiTap,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleActionButton(
            icon: sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
            onTap: sending ? () {} : () => onSendTap(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _ActionSheetItem extends StatelessWidget {
  const _ActionSheetItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.68),
                          height: 1.3,
                          fontSize: 11.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_left_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
      ),
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({
    required this.imageUrls,
    required this.label,
  });

  final List<String> imageUrls;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE7)),
      ),
      child: FallbackNetworkImage(
        imageUrls: imageUrls,
        label: label,
        fit: BoxFit.cover,
        placeholder: Container(
          color: const Color(0xFFF3F4F3),
          alignment: Alignment.center,
          child: const Icon(
            Icons.storefront_outlined,
            color: Color(0xFFFF6500),
            size: 24,
          ),
        ),
        errorWidget: Container(
          color: const Color(0xFFF3F4F3),
          alignment: Alignment.center,
          child: const Icon(
            Icons.storefront_outlined,
            color: Color(0xFFFF6500),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem.date(this.label)
      : kind = _FeedItemKind.date,
        message = null;

  const _FeedItem.message(this.message)
      : kind = _FeedItemKind.message,
        label = null;

  final _FeedItemKind kind;
  final String? label;
  final OrderChatMessage? message;
}

enum _FeedItemKind { date, message }
