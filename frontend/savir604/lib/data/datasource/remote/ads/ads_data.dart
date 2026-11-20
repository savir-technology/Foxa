import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tks/data/datasource/model/admodel.dart';
import 'package:tks/linkapi/linkapi.dart';

class AdsData {
  static final http.Client _sharedClient = http.Client();
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _AdsCacheEntry> _cache = {};

  final http.Client _client;

  AdsData({http.Client? client}) : _client = client ?? _sharedClient;

  /// Fetch ads for a specific placement
  /// placement='home' → calls ads2.php (primary slider)
  /// placement='home_middle' → calls ads.php (secondary slider)
  Future<List<AdModel>> fetchAds({
    String? placement,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(placement);
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && cached.isFresh(_cacheTtl)) {
        return cached.ads;
      }
    }

    // Choose endpoint based on placement
    final endpoint = _selectEndpoint(placement);
    final ads = await _fetchFromEndpoint(endpoint, placement: placement);
    
    final normalizedAds = List<AdModel>.unmodifiable(ads);
    _cache[cacheKey] = _AdsCacheEntry(
      ads: normalizedAds,
      fetchedAt: DateTime.now(),
    );
    return normalizedAds;
  }

  /// Select which endpoint to use based on placement
  String _selectEndpoint(String? placement) {
    final normalized = placement?.trim().toLowerCase() ?? '';
    
    // Primary slider uses ads2.php
    if (normalized == 'home') {
      return AppLink.adsCarousel; // ads2.php
    }
    
    // Secondary slider uses ads.php
    if (normalized == 'home_middle') {
      return AppLink.ads; // ads.php
    }
    
    // Default to ads2.php
    return AppLink.adsCarousel;
  }

  static void clearCache({String? placement}) {
    if (placement == null || placement.trim().isEmpty) {
      _cache.clear();
      return;
    }

    _cache.remove(_cacheKey(placement));
  }

  Future<List<AdModel>> _fetchFromEndpoint(
    String endpoint, {
    String? placement,
  }) async {
    try {
      final uri = _buildUri(endpoint, placement: placement);
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return const <AdModel>[];
      }

      final decoded = jsonDecode(response.body);
      final records = _extractRecords(decoded);
      final ads = records
          .map((item) => AdModel.fromJson(item))
          .where((ad) => ad.isActive && ad.mediaUrl.isNotEmpty)
          .toList();

      return ads;
    } catch (_) {
      return const <AdModel>[];
    }
  }

  Uri _buildUri(String endpoint, {String? placement}) {
    final uri = Uri.parse(endpoint);
    if (placement == null || placement.trim().isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'placement': placement,
      },
    );
  }

  static String _cacheKey(String? placement) {
    final normalized = placement?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ? 'placement:all' : 'placement:$normalized';
  }

  List<Map<String, dynamic>> _extractRecords(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final candidates = [decoded['data'], decoded['ads'], decoded['items']];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (decoded.isNotEmpty) {
        return [decoded];
      }
    }

    return const <Map<String, dynamic>>[];
  }
}

class _AdsCacheEntry {
  const _AdsCacheEntry({
    required this.ads,
    required this.fetchedAt,
  });

  final List<AdModel> ads;
  final DateTime fetchedAt;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(fetchedAt) <= ttl;
  }
}
