import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:admin_tks/linkchat.dart';

class AdminChatRoom extends StatefulWidget {
  final int userId;
  const AdminChatRoom({super.key, required this.userId});

  @override
  State<AdminChatRoom> createState() => _AdminChatRoomState();
}

class _AdminChatRoomState extends State<AdminChatRoom>
    with SingleTickerProviderStateMixin {
  List messages = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  bool isRecording = false;
  bool showEmojiPicker = false;

  final record = AudioRecorder();
  final player = AudioPlayer();
  Timer? _refreshTimer;
  Timer? _recordTimer;
  int recordSeconds = 0;

  double barProgress = 0.0;

  // 🔊 للتحكم في الصوت أثناء التشغيل
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? playingUrl;

  // 🧩 جلب الرسائل
  Future<void> getMessages() async {
    try {
      var res = await http.post(
        Uri.parse(AppLink.getMessages),
        body: {'user_id': widget.userId.toString()},
      );
      var data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() => messages = data['data']);
      }
    } catch (e) {
      debugPrint("Error in getMessages: $e");
    }
  }

  // ✉️ إرسال رسالة نصية
  Future<void> sendMessage(String msg) async {
    if (msg.trim().isEmpty) return;
    setState(() => isLoading = true);
    try {
      await http.post(
        Uri.parse(AppLink.sendMessage),
        body: {
          'user_id': widget.userId.toString(),
          'sender_type': 'admin',
          'message': msg,
        },
      );
      _controller.clear();
      await getMessages();
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🎙️ بدء التسجيل
  Future<void> startRecording() async {
    if (await record.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/admin_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await record.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        isRecording = true;
        recordSeconds = 0;
        barProgress = 0.0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          recordSeconds++;
          barProgress += 0.08;
          if (barProgress > 1.0) barProgress = 0.0;
        });
      });
    }
  }

  // 🛑 إيقاف التسجيل
  Future<void> stopRecording() async {
    final path = await record.stop();
    _recordTimer?.cancel();
    setState(() {
      isRecording = false;
      barProgress = 0.0;
    });

    if (path != null) await sendAudio(File(path));
  }

  // 📤 إرسال الصوت
  Future<void> sendAudio(File file) async {
    setState(() => isLoading = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppLink.sendMessage),
      );
      request.fields['user_id'] = widget.userId.toString();
      request.fields['sender_type'] = 'admin';
      request.fields['message'] = '';
      request.files.add(await http.MultipartFile.fromPath('audio', file.path));

      var response = await request.send();
      if (response.statusCode == 200) await getMessages();
    } catch (e) {
      debugPrint("Error sending audio: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🎧 تشغيل الصوت مع التراك
  Future<void> playAudio(String audioUrl) async {
    if (playingUrl == audioUrl) {
      await player.pause();
      setState(() => playingUrl = null);
    } else {
      await player.stop();
      await player.play(UrlSource("${AppLink.server}/$audioUrl"));
      setState(() => playingUrl = audioUrl);
    }
  }

  // 🕒 تنسيق الوقت
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    getMessages();

    // تحديث الرسائل
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) => getMessages());

    // مراقبة الصوت
    player.onDurationChanged.listen((d) {
      setState(() => duration = d);
    });

    player.onPositionChanged.listen((p) {
      setState(() => position = p);
    });

    player.onPlayerComplete.listen((_) {
      setState(() {
        position = Duration.zero;
        playingUrl = null;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _recordTimer?.cancel();
    player.dispose();
    record.dispose();
    super.dispose();
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.primaryColor, // use primary color for chat header
        title: Text("الدعم السريع للمستخدم",
            style: TextStyle(
                color: theme.appBarTheme.foregroundColor ?? Colors.white)),
      ),
      body: Column(
        children: [
          // 🧩 الرسائل
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isAdmin = msg['sender_type'] == 'admin';
                final timestamp = msg['timestamp'] ?? '';
                final audioUrl = msg['audio_url'];

                return Align(
                  alignment:
                      isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? theme.primaryColor
                          : theme.inputDecorationTheme.fillColor ??
                              Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (audioUrl != null && audioUrl.toString().isNotEmpty)
                          Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      playingUrl == audioUrl
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: isAdmin
                                          ? Colors.white
                                          : theme.primaryColor,
                                      size: 30,
                                    ),
                                    onPressed: () => playAudio(audioUrl),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: playingUrl == audioUrl
                                          ? position.inMilliseconds.toDouble()
                                          : 0,
                                      max: duration.inMilliseconds > 0
                                          ? duration.inMilliseconds.toDouble()
                                          : 1,
                                      onChanged: (value) async {
                                        if (playingUrl == audioUrl) {
                                          await player.seek(Duration(
                                              milliseconds: value.toInt()));
                                        }
                                      },
                                      activeColor: isAdmin
                                          ? Colors.white
                                          : theme.primaryColor,
                                      inactiveColor: theme.dividerColor,
                                    ),
                                  ),
                                  Text(
                                    playingUrl == audioUrl
                                        ? _formatDuration(position)
                                        : "00:00",
                                    style: TextStyle(
                                      color: isAdmin
                                          ? Colors.white
                                          : theme.textTheme.bodyLarge?.color ??
                                              Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Text(
                            msg['message'] ?? '',
                            style: TextStyle(
                              color: isAdmin
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color ??
                                      Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          timestamp.toString().substring(0, 16),
                          style: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.85) ??
                                  Colors.grey.shade600,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 🎙️ التسجيل + الكتابة
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: theme.cardColor,
                  child: isRecording
                      ? Row(
                          children: [
                            Icon(Icons.graphic_eq,
                                color: theme.primaryColor, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.dividerColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: barProgress,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatTime(recordSeconds),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.stop_circle,
                                  color: theme.colorScheme.error),
                              onPressed: stopRecording,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.mic, color: theme.primaryColor),
                              onPressed: startRecording,
                            ),
                            IconButton(
                              icon: Icon(
                                showEmojiPicker
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions_outlined,
                                color: theme.primaryColor,
                              ),
                              onPressed: () => setState(
                                  () => showEmojiPicker = !showEmojiPicker),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: "اكتب الرد...",
                                  fillColor:
                                      theme.inputDecorationTheme.fillColor ??
                                          Colors.grey[100],
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            isLoading
                                ? SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.primaryColor),
                                  )
                                : IconButton(
                                    onPressed: () =>
                                        sendMessage(_controller.text),
                                    icon: Icon(Icons.send,
                                        color: theme.primaryColor),
                                  ),
                          ],
                        ),
                ),

                // 😍 الإيموجي
                Offstage(
                  offstage: !showEmojiPicker,
                  child: SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      textEditingController: _controller,
                      config: Config(
                        height: 256,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 28,
                          columns: 7,
                          backgroundColor:
                              theme.inputDecorationTheme.fillColor ??
                                  theme.scaffoldBackgroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
