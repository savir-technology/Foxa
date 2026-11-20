import 'package:tks/linkapi/linkapi.dart';

class AppVideoUrls {
  static List<String> candidates(String? videoPath) {
    final trimmed = videoPath?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const [];
    }

    final normalized = trimmed.replaceAll('\\', '/');
    final candidates = <String>[];

    void addCandidate(String value) {
      final clean = value.trim();
      if (clean.isNotEmpty && !candidates.contains(clean)) {
        candidates.add(clean);
      }
    }

    addCandidate(_canonicalUrl(normalized));
    addCandidate(_legacyUrl(normalized));

    return candidates;
  }

  static String _canonicalUrl(String value) {
    final fileName = _fileName(value);
    if (fileName.isEmpty) {
      return '';
    }

    return '${AppLink.server}/uploud/video/${Uri.encodeComponent(fileName)}';
  }

  static String _legacyUrl(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return AppLink.normalizeUrl(normalized);
    }

    final path = normalized.replaceFirst(RegExp(r'^/+'), '');
    return path.isEmpty ? '' : '${AppLink.server}/$path';
  }

  static String _fileName(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    final uri = Uri.tryParse(normalized);

    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }

    final segments =
        normalized.split('/').where((segment) => segment.isNotEmpty);
    if (segments.isEmpty) {
      return '';
    }

    return segments.last;
  }
}
