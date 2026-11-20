import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tks/core/services/services.dart';
import 'package:tks/linkapi/linkapi.dart';

class CookieConsentOptionPayload {
  const CookieConsentOptionPayload({
    required this.optionKey,
    required this.profileKey,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.badgeAr,
    required this.badgeEn,
    required this.iconName,
    required this.badgeColor,
    required this.isLocked,
    required this.defaultEnabled,
    required this.sortOrder,
    required this.preferenceKeys,
    required this.isActive,
  });

  final String optionKey;
  final String profileKey;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? badgeAr;
  final String? badgeEn;
  final String iconName;
  final String badgeColor;
  final bool isLocked;
  final bool defaultEnabled;
  final int sortOrder;
  final List<String> preferenceKeys;
  final bool isActive;

  factory CookieConsentOptionPayload.fromJson(Map<String, dynamic> json) {
    return CookieConsentOptionPayload(
      optionKey: (json['option_key'] ?? '').toString(),
      profileKey: (json['profile_key'] ?? '').toString(),
      titleAr: (json['title_ar'] ?? '').toString(),
      titleEn: (json['title_en'] ?? '').toString(),
      descriptionAr: (json['description_ar'] ?? '').toString(),
      descriptionEn: (json['description_en'] ?? '').toString(),
      badgeAr: _nullableText(json['badge_ar']),
      badgeEn: _nullableText(json['badge_en']),
      iconName: (json['icon_name'] ?? 'policy').toString(),
      badgeColor: (json['badge_color'] ?? '#1B7A3A').toString(),
      isLocked: '${json['is_locked'] ?? 0}' == '1',
      defaultEnabled: '${json['default_enabled'] ?? 0}' == '1',
      sortOrder: int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
      preferenceKeys: _stringList(json['preference_keys']),
      isActive: '${json['is_active'] ?? 1}' == '1',
    );
  }
}

class CookieConsentProfilePayload {
  const CookieConsentProfilePayload({
    required this.profileKey,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.acceptAllLabelAr,
    required this.acceptAllLabelEn,
    required this.customizeLabelAr,
    required this.customizeLabelEn,
    required this.rejectOptionalLabelAr,
    required this.rejectOptionalLabelEn,
    required this.footerNoteAr,
    required this.footerNoteEn,
    required this.versionLabel,
    required this.accentColor,
    required this.isActive,
    required this.options,
  });

  final String profileKey;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String? bodyAr;
  final String? bodyEn;
  final String? acceptAllLabelAr;
  final String? acceptAllLabelEn;
  final String? customizeLabelAr;
  final String? customizeLabelEn;
  final String? rejectOptionalLabelAr;
  final String? rejectOptionalLabelEn;
  final String? footerNoteAr;
  final String? footerNoteEn;
  final String versionLabel;
  final String accentColor;
  final bool isActive;
  final List<CookieConsentOptionPayload> options;

  factory CookieConsentProfilePayload.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <CookieConsentOptionPayload>[];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          options.add(CookieConsentOptionPayload.fromJson(item));
        } else if (item is Map) {
          options.add(CookieConsentOptionPayload.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }

    return CookieConsentProfilePayload(
      profileKey: (json['profile_key'] ?? '').toString(),
      titleAr: (json['title_ar'] ?? '').toString(),
      titleEn: (json['title_en'] ?? '').toString(),
      subtitleAr: (json['subtitle_ar'] ?? '').toString(),
      subtitleEn: (json['subtitle_en'] ?? '').toString(),
      bodyAr: _nullableText(json['body_ar']),
      bodyEn: _nullableText(json['body_en']),
      acceptAllLabelAr: _nullableText(json['accept_all_label_ar']),
      acceptAllLabelEn: _nullableText(json['accept_all_label_en']),
      customizeLabelAr: _nullableText(json['customize_label_ar']),
      customizeLabelEn: _nullableText(json['customize_label_en']),
      rejectOptionalLabelAr: _nullableText(json['reject_optional_label_ar']),
      rejectOptionalLabelEn: _nullableText(json['reject_optional_label_en']),
      footerNoteAr: _nullableText(json['footer_note_ar']),
      footerNoteEn: _nullableText(json['footer_note_en']),
      versionLabel: (json['version_label'] ?? 'v1').toString(),
      accentColor: (json['accent_color'] ?? '#F97316').toString(),
      isActive: '${json['is_active'] ?? 1}' == '1',
      options: options,
    );
  }
}

class CookieConsentRecordPayload {
  const CookieConsentRecordPayload({
    required this.profileKey,
    required this.userId,
    required this.installationKey,
    required this.localeCode,
    required this.consentMode,
    required this.preferences,
    required this.recordSource,
    required this.createdAt,
    required this.updatedAt,
  });

  final String profileKey;
  final int? userId;
  final String installationKey;
  final String localeCode;
  final String consentMode;
  final Map<String, dynamic> preferences;
  final String recordSource;
  final String? createdAt;
  final String? updatedAt;

  factory CookieConsentRecordPayload.fromJson(Map<String, dynamic> json) {
    final rawPreferences = json['preferences'];
    Map<String, dynamic> preferences = {};
    if (rawPreferences is Map<String, dynamic>) {
      preferences = rawPreferences;
    } else if (rawPreferences is Map) {
      preferences = Map<String, dynamic>.from(rawPreferences);
    } else if (rawPreferences is String && rawPreferences.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPreferences);
        if (decoded is Map<String, dynamic>) {
          preferences = decoded;
        } else if (decoded is Map) {
          preferences = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        preferences = {};
      }
    }

    return CookieConsentRecordPayload(
      profileKey: (json['profile_key'] ?? '').toString(),
      userId:
          json['user_id'] == null ? null : int.tryParse('${json['user_id']}'),
      installationKey: (json['installation_key'] ?? '').toString(),
      localeCode: (json['locale_code'] ?? 'ar').toString(),
      consentMode: (json['consent_mode'] ?? '').toString(),
      preferences: preferences,
      recordSource: (json['record_source'] ?? 'app').toString(),
      createdAt: _nullableText(json['created_at']),
      updatedAt: _nullableText(json['updated_at']),
    );
  }
}

class CookieConsentData {
  const CookieConsentData();

  Future<CookieConsentProfilePayload?> fetchProfile({
    String profileKey = _defaultProfileKey,
    String? installationKey,
  }) async {
    final url = Uri.parse(
      '${AppLink.cookieConsent}?profile_key=${Uri.encodeQueryComponent(profileKey)}'
      '${installationKey != null && installationKey.trim().isNotEmpty ? '&installation_key=${Uri.encodeQueryComponent(installationKey.trim())}' : ''}',
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

      final dynamic rawProfile = payload['profile'] ?? payload['data'];
      if (rawProfile is Map<String, dynamic>) {
        final profile = CookieConsentProfilePayload.fromJson(rawProfile);
        return CookieConsentProfilePayload(
          profileKey: profile.profileKey,
          titleAr: profile.titleAr,
          titleEn: profile.titleEn,
          subtitleAr: profile.subtitleAr,
          subtitleEn: profile.subtitleEn,
          bodyAr: profile.bodyAr,
          bodyEn: profile.bodyEn,
          acceptAllLabelAr: profile.acceptAllLabelAr,
          acceptAllLabelEn: profile.acceptAllLabelEn,
          customizeLabelAr: profile.customizeLabelAr,
          customizeLabelEn: profile.customizeLabelEn,
          rejectOptionalLabelAr: profile.rejectOptionalLabelAr,
          rejectOptionalLabelEn: profile.rejectOptionalLabelEn,
          footerNoteAr: profile.footerNoteAr,
          footerNoteEn: profile.footerNoteEn,
          versionLabel: profile.versionLabel,
          accentColor: profile.accentColor,
          isActive: profile.isActive,
          options: _optionsFromPayload(payload['options']),
        );
      }
      if (rawProfile is Map) {
        final profile = CookieConsentProfilePayload.fromJson(
          Map<String, dynamic>.from(rawProfile),
        );
        return CookieConsentProfilePayload(
          profileKey: profile.profileKey,
          titleAr: profile.titleAr,
          titleEn: profile.titleEn,
          subtitleAr: profile.subtitleAr,
          subtitleEn: profile.subtitleEn,
          bodyAr: profile.bodyAr,
          bodyEn: profile.bodyEn,
          acceptAllLabelAr: profile.acceptAllLabelAr,
          acceptAllLabelEn: profile.acceptAllLabelEn,
          customizeLabelAr: profile.customizeLabelAr,
          customizeLabelEn: profile.customizeLabelEn,
          rejectOptionalLabelAr: profile.rejectOptionalLabelAr,
          rejectOptionalLabelEn: profile.rejectOptionalLabelEn,
          footerNoteAr: profile.footerNoteAr,
          footerNoteEn: profile.footerNoteEn,
          versionLabel: profile.versionLabel,
          accentColor: profile.accentColor,
          isActive: profile.isActive,
          options: _optionsFromPayload(payload['options']),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CookieConsentRecordPayload?> syncStoredConsent(
      MyServices services) async {
    final hasConsent = (services.sharedPreferences
                .getString(MyServices.keyCookieConsentMode) ??
            '')
        .isNotEmpty;
    if (!hasConsent || services.cookieConsentBackendSynced) {
      return null;
    }

    final preferences = _currentPreferencesFromPrefs(services);
    if (preferences.isEmpty) {
      return null;
    }

    final record = await saveConsent(
      services: services,
      profileKey: _defaultProfileKey,
      consentMode: services.sharedPreferences
              .getString(MyServices.keyCookieConsentMode) ??
          'custom',
      localeCode: services.currentLanguage ?? 'ar',
      preferences: preferences,
      shouldMarkSynced: true,
    );

    return record;
  }

  Future<CookieConsentRecordPayload?> saveConsent({
    required MyServices services,
    required String profileKey,
    required String consentMode,
    required Map<String, bool> preferences,
    String? localeCode,
    bool shouldMarkSynced = false,
  }) async {
    final installationKey = await services.ensureCookieConsentInstallationId();
    final userId = services.sharedPreferences.getInt('id');
    final token = services.accessToken.trim();

    final body = <String, dynamic>{
      'profile_key': profileKey,
      'installation_key': installationKey,
      'locale_code': (localeCode ?? services.currentLanguage ?? 'ar').trim(),
      'consent_mode': consentMode,
      'preferences': preferences,
      'record_source': 'app',
    };

    if (userId != null && userId > 0) {
      body['user_id'] = userId;
    }

    try {
      final response = await http
          .post(
            Uri.parse(AppLink.saveCookieConsent),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
      if ((payload['status'] ?? '').toString() != 'success') {
        return null;
      }

      final recordData = payload['record'];
      if (shouldMarkSynced) {
        await services.sharedPreferences
            .setBool(MyServices.keyCookieConsentBackendSynced, true);
      }

      if (recordData is Map<String, dynamic>) {
        return CookieConsentRecordPayload.fromJson(recordData);
      }
      if (recordData is Map) {
        return CookieConsentRecordPayload.fromJson(
          Map<String, dynamic>.from(recordData),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

List<CookieConsentOptionPayload> _optionsFromPayload(dynamic payload) {
  final options = <CookieConsentOptionPayload>[];
  if (payload is List) {
    for (final item in payload) {
      if (item is Map<String, dynamic>) {
        options.add(CookieConsentOptionPayload.fromJson(item));
      } else if (item is Map) {
        options.add(CookieConsentOptionPayload.fromJson(
          Map<String, dynamic>.from(item),
        ));
      }
    }
  }
  return options;
}

Map<String, bool> _currentPreferencesFromPrefs(MyServices services) {
  return {
    MyServices.keyCookieConsentNecessary: true,
    MyServices.keyCookieConsentFunctional: services.sharedPreferences
            .getBool(MyServices.keyCookieConsentFunctional) ??
        false,
    MyServices.keyCookieConsentAnalytics: services.sharedPreferences
            .getBool(MyServices.keyCookieConsentAnalytics) ??
        false,
    MyServices.keyCookieConsentPerformance: services.sharedPreferences
            .getBool(MyServices.keyCookieConsentPerformance) ??
        false,
    MyServices.keyCookieConsentCommunication: services.sharedPreferences
            .getBool(MyServices.keyCookieConsentCommunication) ??
        false,
    MyServices.keyCookieConsentThirdParty: services.sharedPreferences
            .getBool(MyServices.keyCookieConsentThirdParty) ??
        false,
  };
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

const String _defaultProfileKey = 'first_launch_cookie_policy';
