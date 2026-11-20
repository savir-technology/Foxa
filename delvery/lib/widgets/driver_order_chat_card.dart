import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:delvery/core/services/driver_order_chat_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/core/services/voice_note_audio_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:delvery/core/localization/driver_text.dart';

class DriverOrderChatCard extends StatefulWidget {
  const DriverOrderChatCard({super.key, required this.order});

  final DriverOrder order;

  @override
  State<DriverOrderChatCard> createState() => _DriverOrderChatCardState();
}

class _DriverOrderChatCardState extends State<DriverOrderChatCard>
    with SingleTickerProviderStateMixin {
  late final DriverOrderChatService _chatService;
  late final DriverSessionService _sessionService;
  late final AudioPlayer _audioPlayer;
  late final AudioRecorder _recorder;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;
  bool _loading = true;
  bool _recording = false;
  bool _refreshing = false;
  String? _playingAudioUrl;
  List<OrderChatMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _chatService = DriverOrderChatService(Get.find());
    _sessionService = Get.find<DriverSessionService>();
    _audioPlayer = AudioPlayer();
    _recorder = AudioRecorder();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String audioUrl) async {
    final sourceUrl = _chatService.api.resolveUrl(audioUrl);
    if (sourceUrl.isEmpty) return;
    if (_playingAudioUrl == audioUrl) {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() => _playingAudioUrl = null);
      }
      return;
    }
    try {
      debugPrint(
        '[VOICE NOTE] driver order chat playback start | {"orderId":"${widget.order.id}","sourceUrl":"$sourceUrl"}',
      );
      await _audioPlayer.stop();
      final cachedPath = await VoiceNoteAudioService.cacheRemoteAudio(
        sourceUrl,
        cachePrefix: 'driver_order_chat',
      );
      final source = cachedPath != null
          ? DeviceFileSource(cachedPath)
          : UrlSource(sourceUrl);
      debugPrint(
        '[VOICE NOTE] driver order chat playback source | {"orderId":"${widget.order.id}","mode":"${cachedPath != null ? 'local' : 'remote'}","cachedPath":"${cachedPath ?? ''}"}',
      );
      await _audioPlayer.play(
        source,
        ctx: VoiceNoteAudioService.playbackContext,
      );
      if (mounted) {
        setState(() => _playingAudioUrl = audioUrl);
      }
      debugPrint(
        '[VOICE NOTE] driver order chat playback ready | {"orderId":"${widget.order.id}"}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _playingAudioUrl = null);
      Get.snackbar(
        tx('فشل تشغيل الصوت'),
        tx('تعذر تشغيل المقطع الصوتي، حاول مرة أخرى.'),
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Driver chat audio playback failed for $sourceUrl: $error');
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) {
      setState(() => _loading = true);
    }
    try {
      final messages = await _chatService.fetchMessages(
        orderId: widget.order.id,
        scope: 'order',
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final driverId = _sessionService.driverId.value ?? 0;
    if (driverId <= 0) {
      return;
    }

    setState(() => _sending = true);
    try {
      final ok = await _chatService.sendMessage(
        orderId: widget.order.id,
        scope: 'order',
        senderId: driverId,
        senderRole: 'driver',
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

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      if (mounted) setState(() => _recording = false);
      if (path == null) return;
      await _sendAudio(path);
      return;
    }

    if (!await _recorder.hasPermission()) return;
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/driver_order_chat_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) setState(() => _recording = true);
  }

  Future<void> _sendAudio(String path) async {
    final driverId = _sessionService.driverId.value ?? 0;
    if (driverId <= 0) return;
    setState(() => _sending = true);
    try {
      final ok = await _chatService.sendMessage(
        orderId: widget.order.id,
        scope: 'order',
        senderId: driverId,
        senderRole: 'driver',
        message: '',
        audioFilePath: path,
      );
      if (ok) {
        await _refresh();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DriverUi.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DriverUi.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _sending ? null : _toggleRecording,
                icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_none),
                color: _recording ? DriverUi.danger : DriverUi.primary,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx('دردشة الطلب'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: DriverUi.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx('للطلب الحالي فقط'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DriverUi.mutedText),
                  ),
                ],
              ),
              const Spacer(),
              Chip(
                label: Text(tx('الطلب')),
                avatar: const Icon(Icons.chat_bubble_outline, size: 18),
                backgroundColor: DriverUi.primarySoft,
                side: BorderSide(color: DriverUi.line),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tx('هذه المحادثة مخصصة لتفاصيل الطلب فقط. للدعم الفني استخدم صفحة الدعم المنفصلة.'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DriverUi.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                tx('لا توجد رسائل بعد في هذه الغرفة.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMine = message.isFromDriver;
                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? DriverUi.primarySoft
                            : DriverUi.surfaceWarm,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: DriverUi.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message.isEmpty
                                ? tx('رسالة صوتية')
                                : message.message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: DriverUi.text, height: 1.45),
                          ),
                          if (message.audioUrl != null &&
                              message.audioUrl!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () => _toggleAudio(message.audioUrl!),
                              icon: Icon(
                                _playingAudioUrl == message.audioUrl
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline,
                                color: DriverUi.primary,
                              ),
                              label: Text(
                                _playingAudioUrl == message.audioUrl
                                    ? tx('إيقاف الصوت')
                                    : tx('تشغيل الصوت'),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: DriverUi.primary,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: DriverUi.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: tx('اكتب رسالتك هنا...'),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: DriverUi.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reply in [
                tx('أنا في الطريق.'),
                tx('سأصل خلال دقائق.'),
                tx('وصلت للموقع.'),
                tx('لم أتمكن من الوصول.'),
              ])
                ActionChip(
                  label: Text(reply),
                  onPressed: () {
                    _messageController.text = reply;
                    _sendMessage();
                  },
                  backgroundColor: DriverUi.primarySoft,
                  side: BorderSide(color: DriverUi.line),
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DriverUi.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
