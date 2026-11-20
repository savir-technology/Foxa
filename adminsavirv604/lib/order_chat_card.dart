import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/remote/order_chat_data.dart';
import 'package:flutter/material.dart';
import 'package:admin_tks/linkchat.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class OrderChatCard extends StatefulWidget {
  const OrderChatCard({
    super.key,
    required this.order,
    this.scope = 'order',
  });

  final OrderModel order;
  final String scope;

  @override
  State<OrderChatCard> createState() => _OrderChatCardState();
}

class _OrderChatCardState extends State<OrderChatCard> {
  late final OrderChatData _chatData;
  late final AudioPlayer _audioPlayer;
  late final AudioRecorder _recorder;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _loading = true;
  bool _sending = false;
  bool _recording = false;
  int _vendorId = 0;
  String? _playingAudioUrl;
  List<OrderChatMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _chatData = OrderChatData();
    _audioPlayer = AudioPlayer();
    _recorder = AudioRecorder();
    _bootstrap();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _refresh(silent: true);
      }
    });
  }

  Future<void> _bootstrap() async {
    final session = await DashboardSessionService.instance.loadSession();
    _vendorId = session?.vendorId ?? 0;
    await _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String audioUrl) async {
    if (audioUrl.trim().isEmpty) return;
    if (_playingAudioUrl == audioUrl) {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() => _playingAudioUrl = null);
      }
      return;
    }
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource('${AppLink.server}/$audioUrl'));
    if (mounted) {
      setState(() => _playingAudioUrl = audioUrl);
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_vendorId <= 0) {
      return;
    }
    if (!silent && mounted) {
      setState(() => _loading = true);
    }
    try {
      final messages = await _chatData.fetchMessages(
        orderId: widget.order.ordersId ?? 0,
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
    }
  }

  Future<void> _sendMessage() async {
    if (_vendorId <= 0) {
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      final ok = await _chatData.sendMessage(
        orderId: widget.order.ordersId ?? 0,
        scope: widget.scope,
        senderId: _vendorId,
        senderRole: 'vendor',
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
    final session = await DashboardSessionService.instance.loadSession();
    final vendorId = session?.vendorId ?? _vendorId;
    if (vendorId <= 0) return;

    setState(() => _sending = true);
    try {
      final ok = await _chatData.sendMessage(
        orderId: widget.order.ordersId ?? 0,
        scope: widget.scope,
        senderId: vendorId,
        senderRole: 'vendor',
        message: '',
        audioFilePath: path,
      );
      if (ok) {
        await _refresh();
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11161A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _sending ? null : _toggleRecording,
                icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_none),
                color: _recording ? const Color(0xFFD53F3F) : Colors.white,
              ),
              Text(
                'محادثة الطلب',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Chip(
                label: Text(widget.scope),
                avatar: const Icon(Icons.chat_bubble_outline, size: 18),
              ),
            ],
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
                'لا توجد رسائل بعد في هذا الطلب.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMine = message.isFromVendor;
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
                                ? 'رسالة صوتية'
                                : message.message,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                    ? 'إيقاف الصوت'
                                    : 'تشغيل الصوت',
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
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة للطلب...',
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
              for (final reply in const [
                'الطلب قيد التحضير.',
                'الرجاء الانتظار قليلاً.',
                'يمكن إرسال السائق الآن.',
                'الطلب جاهز للاستلام.',
              ])
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
}
