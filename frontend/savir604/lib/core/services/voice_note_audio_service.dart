import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VoiceNoteAudioService {
  VoiceNoteAudioService._();

  static final AudioContext playbackContext = AudioContextConfig(
    route: AudioContextConfigRoute.speaker,
    focus: AudioContextConfigFocus.gain,
    respectSilence: false,
    stayAwake: false,
  ).build();

  static Future<String?> cacheRemoteAudio(
    String sourceUrl, {
    required String cachePrefix,
  }) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      if (response.bodyBytes.isEmpty) {
        return null;
      }

      final directory = await getTemporaryDirectory();
      final fileName = _buildFileName(uri, cachePrefix);
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static String _buildFileName(Uri uri, String cachePrefix) {
    final rawName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final cleanedName = rawName
        .split('?')
        .first
        .split('#')
        .first
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final extensionIndex = cleanedName.lastIndexOf('.');
    final extension = extensionIndex >= 0 && extensionIndex < cleanedName.length - 1
        ? cleanedName.substring(extensionIndex)
        : '.m4a';
    final safePrefix = cachePrefix.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]+'),
      '_',
    );
    return '${safePrefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
  }
}
