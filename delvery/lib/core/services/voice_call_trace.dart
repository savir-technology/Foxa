import 'dart:convert';

import 'package:flutter/foundation.dart';

class VoiceCallTrace {
  static const String prefix = '[VOICE CALL]';

  static void log(
    String message, {
    Map<String, Object?>? data,
  }) {
    debugPrint(_format(message, data: data));
  }

  static void error(
    String message,
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? data,
  }) {
    debugPrint(_format(message, data: data));
    debugPrint('$prefix ERROR: $error');
    debugPrint(stackTrace.toString());
  }

  static String _format(
    String message, {
    Map<String, Object?>? data,
  }) {
    if (data == null || data.isEmpty) {
      return '$prefix $message';
    }

    return '$prefix $message | ${jsonEncode(_sanitize(data))}';
  }

  static Map<String, Object?> _sanitize(Map<String, Object?> data) {
    return data.map((key, value) {
      if (value is Map || value is List) {
        return MapEntry(key, value);
      }
      if (value is num || value is bool || value == null) {
        return MapEntry(key, value);
      }
      return MapEntry(key, value.toString());
    });
  }
}
