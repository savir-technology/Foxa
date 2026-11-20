import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:tks/core/services/voice_note_audio_service.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/linkapi/linkapi.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final List<dynamic> messages = [];
  final TextEditingController controller = TextEditingController();
  final AudioRecorder recorder = AudioRecorder();
  final AudioPlayer player = AudioPlayer();

  bool isLoading = false;
  bool isRecording = false;
  bool showEmojiPicker = false;
  String? playingUrl;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _bindPlayer();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    controller.dispose();
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.post(
        Uri.parse('${AppLink.server}/chat/get_messages.php'),
        body: {'user_id': widget.userId.toString()},
      );
      final decoded = jsonDecode(response.body);
      if (decoded['status'] == 'success' && mounted) {
        setState(() {
          messages
            ..clear()
            ..addAll(decoded['data'] as List? ?? const []);
        });
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await http.post(
        Uri.parse('${AppLink.server}/chat/send_message.php'),
        body: {
          'user_id': widget.userId.toString(),
          'sender_type': 'user',
          'message': text,
        },
      );
      controller.clear();
      await _loadMessages();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    if (!await recorder.hasPermission()) return;
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/support_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) {
      setState(() => isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await recorder.stop();
    if (mounted) setState(() => isRecording = false);
    if (path == null) return;

    setState(() => isLoading = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppLink.server}/chat/send_message.php'),
      );
      request.fields['user_id'] = widget.userId.toString();
      request.fields['sender_type'] = 'user';
      request.fields['message'] = '';
      request.files.add(await http.MultipartFile.fromPath('audio', path));
      final response = await request.send();
      if (response.statusCode == 200) {
        await _loadMessages();
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _bindPlayer() {
    player.onPositionChanged.listen((value) {
      if (mounted) setState(() => position = value);
    });
    player.onDurationChanged.listen((value) {
      if (mounted) setState(() => duration = value);
    });
    player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          position = Duration.zero;
          duration = Duration.zero;
          playingUrl = null;
        });
      }
    });
  }

  Future<void> _toggleAudio(String audioUrl) async {
    final sourceUrl = AppLink.resolveUrl(audioUrl);
    if (sourceUrl.isEmpty) return;

    if (playingUrl == audioUrl) {
      await player.pause();
      if (mounted) setState(() => playingUrl = null);
      return;
    }

    try {
      await player.stop();
      final cachedPath = await VoiceNoteAudioService.cacheRemoteAudio(
        sourceUrl,
        cachePrefix: 'customer_support',
      );
      final source = cachedPath != null
          ? DeviceFileSource(cachedPath)
          : UrlSource(sourceUrl);
      debugPrint(
        '[VOICE NOTE] support playback source | {"mode":"${cachedPath != null ? 'local' : 'remote'}","cachedPath":"${cachedPath ?? ''}"}',
      );
      await player.play(
        source,
        ctx: VoiceNoteAudioService.playbackContext,
      );
      if (mounted) {
        setState(() => playingUrl = audioUrl);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => playingUrl = null);
      Get.snackbar(
        'Audio playback failed'.tr,
        'Could not play the voice clip, please try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Support audio playback failed for $sourceUrl: $error');
    }
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SupportHeader(
              title: 'Support chat',
              subtitle: 'Fast answers for order, payment, and delivery issues.',
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.homepage,
                    (route) => false,
                  );
                }
              },
            ),
            Expanded(
              child: messages.isEmpty
                  ? _EmptySupportState(isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            Map<String, dynamic>.from(messages[index] as Map);
                        final isUser = '${message['sender_type']}' == 'user';
                        final audioUrl = '${message['audio_url'] ?? ''}';
                        final text = '${message['message'] ?? ''}';
                        final timestamp = '${message['timestamp'] ?? ''}';
                        return _MessageBubble(
                          isUser: isUser,
                          message: text,
                          audioUrl: audioUrl,
                          timestamp: timestamp.length >= 16
                              ? timestamp.substring(0, 16)
                              : timestamp,
                          isPlaying: playingUrl == audioUrl,
                          playbackText: _formatDuration(
                            playingUrl == audioUrl ? position : Duration.zero,
                          ),
                          sliderValue: playingUrl == audioUrl
                              ? position.inMilliseconds.toDouble()
                              : 0,
                          sliderMax: duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1,
                          onPlayPause: audioUrl.isEmpty
                              ? null
                              : () => _toggleAudio(audioUrl),
                          onSeek: audioUrl.isEmpty
                              ? null
                              : (value) => player.seek(
                                    Duration(milliseconds: value.toInt()),
                                  ),
                        );
                      },
                    ),
            ),
            _Composer(
              controller: controller,
              isLoading: isLoading,
              isRecording: isRecording,
              showEmojiPicker: showEmojiPicker,
              onToggleEmoji: () {
                FocusScope.of(context).unfocus();
                setState(() => showEmojiPicker = !showEmojiPicker);
              },
              onMicTap: isRecording ? _stopRecording : _startRecording,
              onSend: _sendMessage,
            ),
            Offstage(
              offstage: !showEmojiPicker,
              child: SizedBox(
                height: 250,
                child: EmojiPicker(
                  textEditingController: controller,
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28,
                      columns: 7,
                      backgroundColor: theme.cardColor,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: theme.cardColor,
                      indicatorColor: theme.colorScheme.primary,
                      iconColor: theme.iconTheme.color ?? Colors.grey,
                      iconColorSelected: theme.colorScheme.primary,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: theme.cardColor,
                      hintText: 'Search emoji...'.tr,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      enabled: true,
                      backgroundColor: theme.cardColor,
                    ),
                    skinToneConfig: const SkinToneConfig(enabled: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportHome extends StatelessWidget {
  const SupportHome({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _SupportHeader(
              title: 'Support',
              subtitle: 'Chat with us about an order, payment, or delivery issue.',
              onBack: () {
                if (Get.previousRoute.isNotEmpty) {
                  Get.back();
                } else {
                  Get.offAllNamed(AppRoutes.homepage);
                }
              },
            ),
            const SizedBox(height: 18),
            _SupportActionCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Start a conversation',
              subtitle: 'Open the in-app support chat and send a text or voice message.',
              onTap: () => Get.to(() => ComplaintScreen(userId: userId)),
            ),
            const SizedBox(height: 12),
            _SupportActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Current orders',
              subtitle: 'Track active orders and open help from each order directly.',
              onTap: () => Get.toNamed(AppRoutes.orderspending),
            ),
            const SizedBox(height: 12),
            _SupportActionCard(
              icon: Icons.help_outline_rounded,
              title: 'Help center',
              subtitle: 'Read the FAQ, privacy summary, and usage terms.',
              onTap: () => Get.toNamed(AppRoutes.helpCenter),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.tr, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle.tr, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySupportState extends StatelessWidget {
  const _EmptySupportState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF242424)
                        : const Color(0xFFF3F3F3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start a support conversation'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message and our team will reply as soon as possible.'
                      .tr,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isUser,
    required this.message,
    required this.audioUrl,
    required this.timestamp,
    required this.isPlaying,
    required this.playbackText,
    required this.sliderValue,
    required this.sliderMax,
    required this.onPlayPause,
    required this.onSeek,
  });

  final bool isUser;
  final String message;
  final String audioUrl;
  final String timestamp;
  final bool isPlaying;
  final String playbackText;
  final double sliderValue;
  final double sliderMax;
  final VoidCallback? onPlayPause;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        isUser ? const Color(0xFFF3F3F3) : const Color(0xFF171717);
    final textColor = isUser ? const Color(0xFF111111) : Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (audioUrl.isNotEmpty)
              Row(
                children: [
                  InkWell(
                    onTap: onPlayPause,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 4),
                      ),
                      child: Slider(
                        value: sliderValue.clamp(0, sliderMax),
                        max: sliderMax <= 0 ? 1 : sliderMax,
                        onChanged: onSeek,
                        activeColor: textColor,
                        inactiveColor: textColor.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  Text(
                    playbackText,
                    style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                  ),
                ],
              )
            else
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                timestamp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isLoading,
    required this.isRecording,
    required this.showEmojiPicker,
    required this.onToggleEmoji,
    required this.onMicTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isRecording;
  final bool showEmojiPicker;
  final VoidCallback onToggleEmoji;
  final VoidCallback onMicTap;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _ComposerButton(
              icon: showEmojiPicker
                  ? Icons.keyboard_rounded
                  : Icons.mood_rounded,
              onTap: onToggleEmoji,
              background:
                  isDark ? const Color(0xFF242424) : const Color(0xFFF3F3F3),
              foreground: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            _ComposerButton(
              icon: isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              onTap: onMicTap,
              background:
                  isRecording ? const Color(0xFFD53F3F) : const Color(0xFFF3F3F3),
              foreground: isRecording ? Colors.white : const Color(0xFF111111),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Write your message...'.tr,
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF242424) : const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: isLoading ? null : onSend,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF171717),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerButton extends StatelessWidget {
  const _ComposerButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: 20),
      ),
    );
  }
}
