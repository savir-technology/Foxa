import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tks/linkapi/linkapi.dart';

class LegalDocumentPayload {
  const LegalDocumentPayload({
    required this.documentKey,
    required this.documentType,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.contentAr,
    required this.contentEn,
    required this.accentColor,
    required this.heroIcon,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String documentKey;
  final String documentType;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final List<String> summaryAr;
  final List<String> summaryEn;
  final String contentAr;
  final String contentEn;
  final String? accentColor;
  final String? heroIcon;
  final int sortOrder;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory LegalDocumentPayload.fromJson(Map<String, dynamic> json) {
    return LegalDocumentPayload(
      documentKey: (json['document_key'] ?? '').toString(),
      documentType: (json['document_type'] ?? 'policy').toString(),
      titleAr: (json['title_ar'] ?? '').toString(),
      titleEn: (json['title_en'] ?? '').toString(),
      subtitleAr: (json['subtitle_ar'] ?? '').toString(),
      subtitleEn: (json['subtitle_en'] ?? '').toString(),
      summaryAr: _stringList(json['summary_ar']),
      summaryEn: _stringList(json['summary_en']),
      contentAr: (json['content_ar'] ?? '').toString(),
      contentEn: (json['content_en'] ?? '').toString(),
      accentColor: _nullableText(json['accent_color']),
      heroIcon: _nullableText(json['hero_icon']),
      sortOrder: int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
      isActive: '${json['is_active'] ?? 1}' == '1',
      createdAt: _nullableText(json['created_at']),
      updatedAt: _nullableText(json['updated_at']),
    );
  }

  String localizedTitle(bool isArabic) =>
      isArabic ? titleAr : (titleEn.isNotEmpty ? titleEn : titleAr);

  String localizedSubtitle(bool isArabic) =>
      isArabic ? subtitleAr : (subtitleEn.isNotEmpty ? subtitleEn : subtitleAr);

  List<String> localizedSummary(bool isArabic) =>
      isArabic ? summaryAr : (summaryEn.isNotEmpty ? summaryEn : summaryAr);

  String localizedContent(bool isArabic) {
    if (isArabic) {
      return contentAr.isNotEmpty ? contentAr : contentEn;
    }

    if (contentEn.isNotEmpty) {
      return contentEn;
    }

    return contentAr;
  }
}

class LegalContentData {
  const LegalContentData();

  Future<LegalDocumentPayload?> fetchDocument(String documentKey) async {
    final key = documentKey.trim();
    if (key.isEmpty) return null;

    final url = Uri.parse(
      '${AppLink.legalDocuments}?key=${Uri.encodeQueryComponent(key)}',
    );

    try {
      final response = await http.get(
        url,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);

      final dynamic rawDocument = payload['document'] ?? payload['data'];
      if (rawDocument is Map<String, dynamic>) {
        return LegalDocumentPayload.fromJson(rawDocument);
      }
      if (rawDocument is Map) {
        return LegalDocumentPayload.fromJson(
            Map<String, dynamic>.from(rawDocument));
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = json.decode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    } catch (_) {
      return [value];
    }
  }

  return const [];
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
