import 'package:tks/linkapi/linkapi.dart';

class AppImageUrls {
  static final List<String> _itemBases = [
    AppLink.imagestItems,
    AppLink.imagestItemsAlt,
  ];

  static final List<String> _categoryBases = [AppLink.imagestCategories];

  static List<String> item(String? imagePath) =>
      _buildCandidates(imagePath, _itemBases);

  static List<String> category(
    String? imagePath, {
    String? nameEn,
    String? nameAr,
  }) {
    final candidates = <String>{..._buildCandidates(imagePath, _categoryBases)};
    for (final fileName in _categoryNameCandidates(nameEn, nameAr)) {
      candidates.addAll(_buildCandidates(fileName, _categoryBases));
    }
    return candidates.toList();
  }

  static List<String> _buildCandidates(
    String? imagePath,
    List<String> bases,
  ) {
    final trimmed = imagePath?.trim() ?? '';
    if (trimmed.isEmpty) return const [];

    final normalizedPath = trimmed.replaceAll('\\', '/');

    if (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://')) {
      final normalized = AppLink.normalizeUrl(normalizedPath);
      return [_encodeAbsoluteUrl(normalized)];
    }

    if (normalizedPath.startsWith('uploud/') ||
        normalizedPath.startsWith('uploads/')) {
      return [
        '${AppLink.server}/${_encodePath(normalizedPath)}',
      ];
    }

    final encodedPath = _encodePath(normalizedPath);
    return <String>{
      for (final base in bases) '$base/$encodedPath',
    }.toList();
  }

  static String _encodeAbsoluteUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(path: _encodePath(uri.path)).toString();
  }

  static String _encodePath(String path) {
    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
  }

  static List<String> _categoryNameCandidates(String? nameEn, String? nameAr) {
    final rawNames = [nameEn, nameAr]
        .map((e) => (e ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final candidates = <String>{};
    for (final name in rawNames) {
      final normalized = name.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.isEmpty) continue;

      if (normalized.contains('.')) {
        candidates.add(normalized);
      } else {
        for (final ext in const ['png', 'jpg', 'jpeg', 'webp']) {
          candidates.add('$normalized.$ext');
        }
      }
    }

    return candidates.toList();
  }
}
