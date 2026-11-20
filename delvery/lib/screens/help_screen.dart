import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:delvery/core/services/driver_api_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_inbox_models.dart';
import 'package:delvery/core/services/voice_note_audio_service.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:delvery/core/localization/driver_text.dart';

String _friendlyHelpErrorMessage(String message, String fallback) {
  final normalized = message.trim();
  if (normalized.isEmpty) {
    return fallback;
  }
  if (normalized.startsWith('Bad state:')) {
    return normalized.replaceFirst('Bad state:', '').trim();
  }
  if (normalized.startsWith('Exception:')) {
    return normalized.replaceFirst('Exception:', '').trim();
  }
  return normalized;
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late final DriverApiService _api;
  late final DriverSessionService _session;
  late final AudioRecorder _recorder;
  late final AudioPlayer _player;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;
  Timer? _recordTimer;
  bool _loading = true;
  bool _sending = false;
  bool _recording = false;
  String? _playingAudioUrl;
  String? _errorMessage;
  int _unreadByDriver = 0;
  int _recordSeconds = 0;
  List<DriverSupportMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _api = Get.find<DriverApiService>();
    _session = Get.find<DriverSessionService>();
    _recorder = AudioRecorder();
    _player = AudioPlayer();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    _player.dispose();
    _recorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final driverId = _session.driverId.value ?? 0;
    if (driverId <= 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = tx('لم يتم ربط حساب السائق بعد.');
      });
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _api.fetchDriverSupportMessages(
        driverId: driverId,
        markRead: true,
      );
      final status = (response['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMessage = _friendlyHelpErrorMessage(
            (response['message'] ?? tx('تعذر تحميل الدعم الفني')).toString(),
            tx('تعذر تحميل الدعم الفني حالياً.'),
          );
        });
        return;
      }

      final summary =
          (response['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
      final raw = response['data'];
      final data = raw is List ? raw : const <dynamic>[];
      final messages = data
          .whereType<Map>()
          .map(
            (item) =>
                DriverSupportMessage.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _messages = messages;
        _unreadByDriver =
            int.tryParse(summary['unread_by_driver']?.toString() ?? '') ?? 0;
        _loading = false;
        _errorMessage = null;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _friendlyHelpErrorMessage(
          error.toString(),
          tx('تعذر تحميل الدعم الفني حالياً.'),
        );
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final driverId = _session.driverId.value ?? 0;
    if (driverId <= 0) {
      return;
    }

    setState(() => _sending = true);
    try {
      final response = await _api.sendDriverSupportMessage(
        driverId: driverId,
        message: text,
      );
      if ((response['status'] ?? '').toString().toLowerCase() == 'success') {
        _messageController.clear();
        await _refresh(silent: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      if (mounted) {
        setState(() {
          _recording = false;
          _recordSeconds = 0;
        });
      }
      if (path != null) {
        await _sendAudio(path);
      }
      return;
    }

    final granted = await _recorder.hasPermission();
    if (!granted) {
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/driver_support_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _recording = true;
      _recordSeconds = 0;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_recording || !mounted) {
        timer.cancel();
        return;
      }
      setState(() => _recordSeconds++);
    });
  }

  Future<void> _sendAudio(String path) async {
    final driverId = _session.driverId.value ?? 0;
    if (driverId <= 0) {
      return;
    }

    setState(() => _sending = true);
    try {
      final response = await _api.sendDriverSupportMessage(
        driverId: driverId,
        message: '',
        audioFilePath: path,
      );
      if ((response['status'] ?? '').toString().toLowerCase() == 'success') {
        await _refresh(silent: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _togglePlayback(String audioUrl) async {
    final resolvedUrl = _api.resolveUrl(audioUrl);
    if (resolvedUrl.isEmpty) {
      return;
    }

    if (_playingAudioUrl == audioUrl) {
      await _player.stop();
      if (mounted) {
        setState(() => _playingAudioUrl = null);
      }
      return;
    }

    try {
      debugPrint(
        '[VOICE NOTE] driver support playback start | {"sourceUrl":"$resolvedUrl"}',
      );
      await _player.stop();
      final cachedPath = await VoiceNoteAudioService.cacheRemoteAudio(
        resolvedUrl,
        cachePrefix: 'driver_support',
      );
      final source = cachedPath != null
          ? DeviceFileSource(cachedPath)
          : UrlSource(resolvedUrl);
      debugPrint(
        '[VOICE NOTE] driver support playback source | {"mode":"${cachedPath != null ? 'local' : 'remote'}","cachedPath":"${cachedPath ?? ''}"}',
      );
      await _player.play(source, ctx: VoiceNoteAudioService.playbackContext);
      if (mounted) {
        setState(() => _playingAudioUrl = audioUrl);
      }
      debugPrint('[VOICE NOTE] driver support playback ready');
    } catch (error) {
      if (!mounted) return;
      setState(() => _playingAudioUrl = null);
      Get.snackbar(
        tx('تعذر تشغيل الصوت'),
        tx('حاول مرة أخرى أو تأكد من اتصالك بالإنترنت.'),
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Support audio playback failed for $resolvedUrl: $error');
    }
  }

  void _applyQuickReply(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _session.profile.value;
    final isEmbed = widget.embedInShell;
    final driverName = profile.name.trim();
    final driverEmail = profile.email.trim();
    final driverVehicle =
        profile.vehicleType.isNotEmpty && profile.vehicleNumber.isNotEmpty
        ? '${profile.vehicleType} - ${profile.vehicleNumber}'
        : profile.vehicleType.isNotEmpty
        ? profile.vehicleType
        : profile.vehicleNumber.isNotEmpty
        ? profile.vehicleNumber
        : tx('غير محددة');
    final totalMessages = _messages.length;
    final adminReplies = _messages
        .where((message) => message.isFromAdmin)
        .length;
    final audioMessages = _messages.where((message) => message.hasAudio).length;

    return Scaffold(
      backgroundColor: DriverUi.background,
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 3,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: [
                  DriverHeaderBar(
                    leadingIcon: isEmbed
                        ? Icons.support_agent_rounded
                        : Icons.arrow_back_rounded,
                    trailingIcon: Icons.refresh_rounded,
                    onLeadingTap: isEmbed
                        ? () {}
                        : () => Navigator.of(context).maybePop(),
                    onTrailingTap: _loading ? null : () => _refresh(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DriverUi.surface, Color(0xFFFFF8F3)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: DriverUi.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: DriverUi.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: DriverUi.primary,
                              ),
                            ),
                            const Spacer(),
                            _SupportStatusPill(
                              label: tx('متاح الآن'),
                              icon: Icons.check_circle_rounded,
                              color: DriverUi.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tx('الدعم الفني'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: DriverUi.text,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tx(
                            'قناة رسمية لمتابعة الطلبات والدعم والرسائل الصوتية بشكل واضح وسريع.',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: DriverUi.mutedText,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SupportMetricTile(
                                label: tx('الرسائل'),
                                value: '$totalMessages',
                                backgroundColor: DriverUi.surface,
                                valueColor: DriverUi.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SupportMetricTile(
                                label: tx('غير المقروء'),
                                value: '$_unreadByDriver',
                                backgroundColor: const Color(0xFFF9F6EE),
                                valueColor: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SupportMetricTile(
                                label: tx('ردود الإدارة'),
                                value: '$adminReplies',
                                backgroundColor: const Color(0xFFF1F5FF),
                                valueColor: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SupportMetricTile(
                                label: tx('رسائل صوتية'),
                                value: '$audioMessages',
                                backgroundColor: const Color(0xFFF0FAF4),
                                valueColor: DriverUi.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tx(
                            'كل الرسائل محفوظة داخل القناة الرسمية ويظهر التحديث هنا مباشرة.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: DriverUi.mutedText,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DriverCard(
                    color: DriverUi.surfaceWarm,
                    borderColor: DriverUi.line,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: DriverUi.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: DriverUi.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx('المسار المخصص للدعم'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: DriverUi.text,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tx(
                                  'يرى فريق الدعم هذه الرسائل مباشرة ويرد عليها من نفس القناة.',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: DriverUi.mutedText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _SupportStatusPill(
                          label: driverName.isEmpty
                              ? tx('الملف يحتاج استكمال')
                              : tx('الملف جاهز'),
                          icon: driverName.isEmpty
                              ? Icons.person_outline_rounded
                              : Icons.verified_rounded,
                          color: driverName.isEmpty
                              ? const Color(0xFFB45309)
                              : DriverUi.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DriverCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx('بيانات السائق'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: DriverUi.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 14),
                        DriverInfoRow(
                          label: tx('الاسم'),
                          value: driverName.isNotEmpty
                              ? driverName
                              : tx('غير متاح'),
                          icon: Icons.badge_rounded,
                        ),
                        DriverInfoRow(
                          label: tx('البريد'),
                          value: driverEmail.isNotEmpty
                              ? driverEmail
                              : tx('غير متاح'),
                          icon: Icons.email_outlined,
                        ),
                        DriverInfoRow(
                          label: tx('الهاتف'),
                          value: profile.phone.isNotEmpty
                              ? profile.phone
                              : tx('غير متاح'),
                          icon: Icons.phone_rounded,
                        ),
                        DriverInfoRow(
                          label: tx('المركبة'),
                          value: driverVehicle,
                          icon: Icons.two_wheeler_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_unreadByDriver > 0)
                    DriverCard(
                      color: const Color(0xFFF2F8F2),
                      borderColor: const Color(0xFFD9EAD8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: DriverUi.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_chat_unread_rounded,
                              color: DriverUi.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              trParam(
                                'لديك {count} رسالة دعم غير مقروءة.',
                                'You have {count} unread support messages.',
                                {'count': _unreadByDriver},
                              ),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: DriverUi.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DriverCard(
                      color: const Color(0xFFFFF8F3),
                      borderColor: const Color(0xFFF0D8CA),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: DriverUi.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: DriverUi.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tx(
                                'القناة جاهزة، ويمكنك كتابة أي ملاحظة أو إرسال رسالة صوتية الآن.',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: DriverUi.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _QuickReplyChip(
                          label: tx('أحتاج مساعدة'),
                          onTap: () =>
                              _applyQuickReply(tx('أحتاج مساعدة بخصوص الطلب.')),
                        ),
                        const SizedBox(width: 10),
                        _QuickReplyChip(
                          label: tx('تم الحل'),
                          onTap: () =>
                              _applyQuickReply(tx('تم حل المشكلة، شكراً لكم.')),
                        ),
                        const SizedBox(width: 10),
                        _QuickReplyChip(
                          label: tx('المشكلة ما زالت'),
                          onTap: () => _applyQuickReply(
                            tx('المشكلة ما زالت موجودة، أحتاج متابعة.'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _QuickReplyChip(
                          label: tx('شكراً'),
                          onTap: () => _applyQuickReply(
                            tx('شكراً لكم على الدعم السريع.'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: _loading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _messages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: DriverEmptyStateCard(
                        icon: Icons.cloud_off_rounded,
                        title: tx('تعذر تحميل الدعم'),
                        subtitle: _errorMessage!,
                        actionLabel: tx('إعادة المحاولة'),
                        onAction: _refresh,
                      ),
                    )
                  : RefreshIndicator(
                      color: DriverUi.primary,
                      onRefresh: _refresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        itemCount: _messages.isEmpty ? 1 : _messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (_messages.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: DriverEmptyStateCard(
                                icon: Icons.forum_outlined,
                                title: tx('ابدأ محادثة مع الدعم'),
                                subtitle: tx(
                                  'اكتب رسالتك أو أرسل رسالة صوتية، وسيظهر الرد هنا مباشرة.',
                                ),
                              ),
                            );
                          }

                          final message = _messages[index];
                          return _SupportMessageBubble(
                            message: message,
                            onPlayAudio: message.hasAudio
                                ? () => _togglePlayback(message.audioUrl!)
                                : null,
                            playingAudioUrl: _playingAudioUrl,
                          );
                        },
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  color: DriverUi.background,
                  child: DriverCard(
                    padding: const EdgeInsets.all(14),
                    child: _recording
                        ? Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: DriverUi.dangerSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: DriverUi.danger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tx('جار تسجيل رسالة صوتية للدعم'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: DriverUi.text,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDuration(_recordSeconds),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: DriverUi.mutedText),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        minHeight: 4,
                                        value: (_recordSeconds % 20) / 20.0,
                                        color: DriverUi.danger,
                                        backgroundColor: DriverUi.dangerSoft
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: DriverUi.dangerSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _sending ? null : _toggleRecording,
                                  icon: const Icon(Icons.stop_rounded),
                                  color: DriverUi.danger,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: DriverUi.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: _sending
                                          ? null
                                          : _toggleRecording,
                                      icon: const Icon(Icons.mic_none_rounded),
                                      color: DriverUi.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8F4),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: DriverUi.line,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        minLines: 1,
                                        maxLines: 4,
                                        textInputAction: TextInputAction.send,
                                        decoration: InputDecoration(
                                          hintText: tx('اكتب رسالتك هنا...'),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                        ),
                                        onSubmitted: (_) => _sendText(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: DriverUi.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: DriverUi.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: _sending
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : IconButton(
                                            onPressed: _sendText,
                                            icon: const Icon(
                                              Icons.send_rounded,
                                            ),
                                            color: Colors.white,
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: DriverUi.mutedText.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tx(
                                        'الرسائل تُحفظ داخل القناة الرسمية وتظهر لفريق الدعم مباشرة.',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: DriverUi.mutedText,
                                            height: 1.35,
                                          ),
                                    ),
                                  ),
                                ],
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
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _SupportStatusPill extends StatelessWidget {
  const _SupportStatusPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportMetricTile extends StatelessWidget {
  const _SupportMetricTile({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: valueColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DriverUi.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: DriverUi.primary,
      ),
      label: Text(label),
      backgroundColor: DriverUi.surface,
      side: BorderSide(color: DriverUi.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: DriverUi.primary,
        fontWeight: FontWeight.w800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelPadding: const EdgeInsets.only(left: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SupportMessageBubble extends StatelessWidget {
  const _SupportMessageBubble({
    required this.message,
    required this.onPlayAudio,
    required this.playingAudioUrl,
  });

  final DriverSupportMessage message;
  final VoidCallback? onPlayAudio;
  final String? playingAudioUrl;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isFromDriver;
    final audioActive =
        playingAudioUrl != null &&
        playingAudioUrl!.trim().isNotEmpty &&
        playingAudioUrl == message.audioUrl;
    final bubbleColor = isMine ? DriverUi.primarySoft : DriverUi.surface;
    final borderColor = isMine
        ? DriverUi.primary.withValues(alpha: 0.12)
        : DriverUi.line;
    final avatarBackground = isMine
        ? DriverUi.primary.withValues(alpha: 0.10)
        : const Color(0xFFFFF0E6);
    final avatarColor = isMine ? DriverUi.primary : const Color(0xFF0F766E);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMine
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMine) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: avatarBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      Icons.headset_mic_rounded,
                      size: 18,
                      color: avatarColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMine ? tx('أنت') : tx('فريق الدعم'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isMine
                              ? DriverUi.primary
                              : const Color(0xFF0F766E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMine ? 18 : 6),
                            bottomRight: Radius.circular(isMine ? 6 : 18),
                          ),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.hasText)
                              Text(
                                message.message,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: DriverUi.text,
                                      height: 1.5,
                                    ),
                              )
                            else
                              Text(
                                tx('رسالة صوتية'),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: DriverUi.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            if (message.hasAudio) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: onPlayAudio,
                                icon: Icon(
                                  audioActive
                                      ? Icons.stop_circle_outlined
                                      : Icons.play_circle_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  audioActive
                                      ? tx('إيقاف الصوت')
                                      : tx('تشغيل الصوت'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: DriverUi.primary,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.55,
                                  ),
                                  side: BorderSide(
                                    color: DriverUi.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DriverUi.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: avatarBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: avatarColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime? createdAt) {
    if (createdAt == null) {
      return tx('الآن');
    }

    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
