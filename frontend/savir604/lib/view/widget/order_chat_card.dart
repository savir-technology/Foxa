import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:tks/core/services/voice_note_audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/core/services/order_chat_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class OrderChatCard extends StatefulWidget {
  const OrderChatCard({
    super.key,
    required this.order,
    this.scope = 'order',
  });

  final OrdersModel order;
  final String scope;

  @override
  State<OrderChatCard> createState() => _OrderChatCardState();
}

class _OrderChatCardState extends State<OrderChatCard> {
  late final OrderChatService _chatService;
  late final MyServices _services;
  late final AudioPlayer _audioPlayer;
  late final AudioRecorder _recorder;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;
  bool _recording = false;
  bool _refreshing = false;
  String? _playingAudioUrl;
  List<OrderChatMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _chatService = OrderChatService();
    _services = Get.find<MyServices>();
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
    final sourceUrl = AppLink.resolveUrl(audioUrl);
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
        '[VOICE NOTE] order chat playback start | {"orderId":"${widget.order.ordersId ?? '0'}","sourceUrl":"$sourceUrl"}',
      );
      await _audioPlayer.stop();
      final cachedPath = await VoiceNoteAudioService.cacheRemoteAudio(
        sourceUrl,
        cachePrefix: 'customer_order_chat',
      );
      final source = cachedPath != null
          ? DeviceFileSource(cachedPath)
          : UrlSource(sourceUrl);
      debugPrint(
        '[VOICE NOTE] order chat playback source | {"mode":"${cachedPath != null ? 'local' : 'remote'}","cachedPath":"${cachedPath ?? ''}"}',
      );
      await _audioPlayer.play(
        source,
        ctx: VoiceNoteAudioService.playbackContext,
      );
      if (mounted) {
        setState(() => _playingAudioUrl = audioUrl);
      }
      debugPrint('[VOICE NOTE] order chat playback ready');
    } catch (error) {
      if (!mounted) return;
      setState(() => _playingAudioUrl = null);
      Get.snackbar(
        'Audio playback failed'.tr,
        'Could not play the voice clip, please try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Audio playback failed for $sourceUrl: $error');
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
        orderId: widget.order.ordersId ?? '0',
        scope: widget.scope,
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

    final userId = _services.sharedPreferences.getInt('id') ?? 0;
    if (userId <= 0) {
      return;
    }

    setState(() => _sending = true);
    try {
      final ok = await _chatService.sendMessage(
        orderId: widget.order.ordersId ?? '0',
        scope: widget.scope,
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

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() => _recording = false);
      }
      if (path == null) return;
      await _sendAudio(path);
      return;
    }

    if (!await _recorder.hasPermission()) return;
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/order_chat_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) {
      setState(() => _recording = true);
    }
  }

  Future<void> _sendAudio(String path) async {
    final userId = _services.sharedPreferences.getInt('id') ?? 0;
    if (userId <= 0) return;
    setState(() => _sending = true);
    try {
      final ok = await _chatService.sendMessage(
        orderId: widget.order.ordersId ?? '0',
        scope: widget.scope,
        senderId: userId,
        senderRole: 'user',
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
    final isDriverChat = widget.scope == 'order';
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final messagesHeight = (availableHeight * 0.34).clamp(220.0, 380.0);
    final title = widget.scope == 'support'
        ? 'support'.tr
        : isDriverChat
            ? 'Driver chat'.tr
            : 'Order chat'.tr;
    final subtitle = widget.scope == 'support'
        ? 'Chat with the support team inside the app.'.tr
        : isDriverChat
            ? 'This chat is between you and the driver assigned to this order.'
                .tr
            : 'Messages are linked directly to this order.'.tr;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Chip(
                label: Text(isDriverChat ? 'Driver'.tr : 'support'.tr),
                avatar: const Icon(Icons.chat_bubble_outline, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No messages yet in this conversation.'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            )
          else
            SizedBox(
              height: messagesHeight,
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMine = message.isFromUser;
                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? const Color(0xFF59D98E).withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message.isEmpty
                                ? 'Voice message'.tr
                                : message.message,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
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
                                color: Colors.white,
                              ),
                              label: Text(
                                _playingAudioUrl == message.audioUrl
                                    ? 'Stop audio'.tr
                                    : 'Play audio'.tr,
                                style: const TextStyle(color: Colors.white),
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
              IconButton(
                onPressed: _sending ? null : _toggleRecording,
                icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_none),
                color: _recording ? const Color(0xFFD53F3F) : Colors.white,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write a message for the order...'.tr,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _sending ? null : _sendMessage,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reply in _quickReplies())
                ActionChip(
                  label: Text(reply),
                  onPressed: () {
                    _messageController.text = reply;
                    _sendMessage();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _quickReplies() {
    if (widget.scope == 'support') {
      return [
        'I need help.'.tr,
        'I have an issue with the order.'.tr,
        'I want to track the order.'.tr,
        'Please contact me.'.tr,
      ];
    }

    return [
      'I am waiting for you.'.tr,
      'The address is correct.'.tr,
      'Call me upon arrival.'.tr,
      'You can leave the order at the door.'.tr,
    ];
  }
}
