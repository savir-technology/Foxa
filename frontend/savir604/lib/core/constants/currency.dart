import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tks/linkapi/linkapi.dart';

/// Runtime platform settings delivered by the Master dashboard.
/// Defaults keep the app usable while the public settings endpoint is offline.
class AppCurrency {
  static String code = 'SAR';
  static String symbol = 'ر.س';
  static String nameAr = 'الريال السعودي';
  static String nameEn = 'Saudi Riyal';
  static String supportPhone = '';
  static String supportEmail = '';

  static Future<void> load() async {
    try {
      final response = await http
          .get(Uri.parse(AppLink.platformSettings))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) return;

      final nextCode = '${data['default_currency_code'] ?? ''}'.trim();
      final nextSymbol = '${data['default_currency_symbol'] ?? ''}'.trim();
      final nextNameAr = '${data['default_currency_name'] ?? ''}'.trim();
      final nextNameEn = '${data['default_currency_name_en'] ?? ''}'.trim();
      final nextSupportPhone = '${data['support_phone'] ?? ''}'.trim();
      final nextSupportEmail = '${data['support_email'] ?? ''}'.trim();
      if (nextCode.isNotEmpty) code = nextCode;
      if (nextSymbol.isNotEmpty) symbol = nextSymbol;
      if (nextNameAr.isNotEmpty) nameAr = nextNameAr;
      if (nextNameEn.isNotEmpty) nameEn = nextNameEn;
      if (nextSupportPhone.isNotEmpty) supportPhone = nextSupportPhone;
      if (nextSupportEmail.isNotEmpty) supportEmail = nextSupportEmail;
    } catch (_) {
      // Keep safe defaults; prices and checkout remain available.
    }
  }

  static String label({required bool isArabic, bool useSymbol = false}) =>
      useSymbol ? symbol : (isArabic ? symbol : code);
}
