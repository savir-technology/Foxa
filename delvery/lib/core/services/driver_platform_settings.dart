import 'dart:convert';

import 'package:http/http.dart' as http;

class DriverPlatformSettings {
  static String currencyCode = 'SAR';
  static String currencySymbol = 'ر.س';

  static Future<void> load() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://savir-technology.online/roaqv2/settings/public.php',
            ),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map ? decoded['data'] : null;
      final code = data is Map
          ? '${data['default_currency_code'] ?? ''}'.trim()
          : '';
      final symbol = data is Map
          ? '${data['default_currency_symbol'] ?? ''}'.trim()
          : '';
      if (code.isNotEmpty) currencyCode = code;
      if (symbol.isNotEmpty) currencySymbol = symbol;
    } catch (_) {
      // Keep the safe default if the public settings API is unavailable.
    }
  }
}
