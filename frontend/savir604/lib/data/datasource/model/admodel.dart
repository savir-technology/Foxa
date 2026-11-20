import 'package:tks/linkapi/linkapi.dart';

enum AdMediaType { image, gif, video }

class AdModel {
  final String id;
  final String title;
  final String mediaUrl;
  final String thumbnailUrl;
  final String linkUrl;
  final String targetType;
  final String targetId;
  final String placement;
  final AdMediaType mediaType;
  final int displaySeconds;
  final bool isActive;
  final bool openInWebView;

  const AdModel({
    required this.id,
    required this.title,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.linkUrl,
    required this.targetType,
    required this.targetId,
    required this.placement,
    required this.mediaType,
    required this.displaySeconds,
    required this.isActive,
    required this.openInWebView,
  });

  bool get hasInternalTarget {
    final type = normalizedTargetType;
    if (!const {'product', 'item', 'restaurant'}.contains(type)) {
      return false;
    }
    return targetIdValue > 0;
  }

  bool get hasLink => hasInternalTarget;

  String get normalizedTargetType => targetType.trim().toLowerCase();

  int get targetIdValue => int.tryParse(targetId.trim()) ?? 0;

  bool get isVideo => mediaType == AdMediaType.video;

  bool get isGif => mediaType == AdMediaType.gif;

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final mediaUrl = _normalizeMediaUrl(
      _firstNonEmpty(
        json['media_url'],
        json['image_url'],
        json['video_url'],
        json['file_url'],
        json['banner_url'],
        json['ad_url'],
      ),
    );

    final linkUrl = _normalizeLink(
      _firstNonEmpty(
        json['link_url'],
        json['target_url'],
        json['redirect_url'],
        json['url'],
      ),
    );

    final thumbnailUrl = _normalizeMediaUrl(
      _firstNonEmpty(
        json['thumbnail_url'],
        json['cover_url'],
        json['preview_image'],
      ),
    );

    final internalTarget = _parseInternalTarget(linkUrl);
    var targetType = _firstNonEmpty(
      json['target_type'],
      json['target'],
      json['action_type'],
    ).toLowerCase();
    var targetId = _firstNonEmpty(
      json['target_id'],
      json['item_id'],
      json['restaurant_id'],
      json['reference_id'],
    );

    if (internalTarget != null) {
      final parsedType = internalTarget['type'] as String? ?? '';
      final parsedId = internalTarget['id']?.toString() ?? '';
      final targetIdValue = int.tryParse(targetId.trim()) ?? 0;
      if (targetType.isEmpty ||
          targetType == 'url' ||
          targetIdValue <= 0 ||
          !const {'product', 'item', 'restaurant'}.contains(targetType)) {
        targetType = parsedType;
        targetId = parsedId;
      }
    }

    return AdModel(
      id: _firstNonEmpty(json['id'], json['ads_id'], json['ad_id']),
      title: _firstNonEmpty(
        json['title'],
        json['ads_title'],
        json['name'],
        json['description'],
      ),
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      linkUrl: linkUrl,
      targetType: targetType,
      targetId: targetId,
      placement: _firstNonEmpty(
        json['placement'],
        json['slot'],
        json['screen'],
      ).toLowerCase(),
      mediaType: _parseMediaType(
        _firstNonEmpty(
          json['media_type'],
          json['type'],
          json['ad_type'],
        ),
        mediaUrl,
      ),
      displaySeconds: _parseInt(
        json['display_seconds'],
        json['duration_seconds'],
        json['duration'],
      ),
      isActive: _parseBool(
        json['is_active'],
        json['active'],
        json['status'],
      ),
      openInWebView: _parseBool(
        json['open_in_webview'],
        json['open_inside_app'],
        json['in_app_browser'],
        true,
      ),
    );
  }

  static String _firstNonEmpty(
    dynamic a, [
    dynamic b,
    dynamic c,
    dynamic d,
    dynamic e,
    dynamic f,
  ]) {
    for (final value in [a, b, c, d, e, f]) {
      final text = '${value ?? ''}'.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  static String _normalizeMediaUrl(String value) {
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return AppLink.normalizeUrl(value);
    }

    var relative = value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    if (relative.startsWith('roaq/')) {
      relative = relative.substring('roaq/'.length);
    }

    // Master uploads may be returned as a full relative path or as only the
    // generated filename. Support both formats for old and new records.
    if (!relative.contains('/')) {
      relative = 'ads/uploud/img/$relative';
    } else if (relative.startsWith('uploud/img/')) {
      relative = 'ads/$relative';
    }

    return AppLink.normalizeUrl('${AppLink.server}/$relative');
  }

  static String _normalizeLink(String value) {
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return AppLink.normalizeUrl(value);
    }
    return AppLink.normalizeUrl(
      'https://${value.replaceFirst(RegExp(r'^/+'), '')}',
    );
  }

  static Map<String, Object>? _parseInternalTarget(String value) {
    final match = RegExp(
      r'^(product|item|restaurant):\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    final type = match.group(1)!.toLowerCase();
    return {
      'type': type == 'item' ? 'product' : type,
      'id': int.tryParse(match.group(2) ?? '') ?? 0,
    };
  }

  static AdMediaType _parseMediaType(String rawType, String mediaUrl) {
    final type = rawType.trim().toLowerCase();
    if (type == 'video') return AdMediaType.video;
    if (type == 'gif') return AdMediaType.gif;
    if (type == 'image' || type == 'banner' || type == 'photo') {
      return AdMediaType.image;
    }

    final lowerUrl = mediaUrl.toLowerCase();
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.m3u8')) {
      return AdMediaType.video;
    }
    if (lowerUrl.endsWith('.gif')) {
      return AdMediaType.gif;
    }
    return AdMediaType.image;
  }

  static int _parseInt(dynamic a, [dynamic b, dynamic c]) {
    for (final value in [a, b, c]) {
      final parsed = int.tryParse('${value ?? ''}');
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return 8;
  }

  static bool _parseBool(
    dynamic a, [
    dynamic b,
    dynamic c,
    bool fallback = true,
  ]) {
    for (final value in [a, b, c]) {
      final normalized = '${value ?? ''}'.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (['1', 'true', 'yes', 'active', 'enabled'].contains(normalized)) {
        return true;
      }
      if (['0', 'false', 'no', 'inactive', 'disabled'].contains(normalized)) {
        return false;
      }
    }
    return fallback;
  }
}
