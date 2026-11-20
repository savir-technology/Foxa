import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxRuntimeConfig {
  static const String standardStyleUri = MapboxStyles.STANDARD;
  static const String standardStyleImportId = 'basemap';

  static const String _accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue:
        'pk.eyJ1IjoiaXNsYW04ODkwIiwiYSI6ImNtcTVwdnlpczAwcjQycnNrcTZkYnNqa3IifQ.NY-wxxxpO5XoCZTD9v7kiQ',
  );

  static const MethodChannel _channel =
      MethodChannel('tks/mapbox_runtime_config');

  static String _runtimeAccessToken = '';

  static String get accessToken {
    final token = _runtimeAccessToken.trim();
    if (token.isNotEmpty) {
      return token;
    }
    return _accessToken.trim();
  }

  static bool get isConfigured => !kIsWeb && accessToken.isNotEmpty;

  static String get styleUri => standardStyleUri;

  static String styleUriForBrightness(Brightness brightness) {
    return standardStyleUri;
  }

  static Future<void> configureDetailedBasemapStyle(
    StyleManager style,
    Brightness brightness,
  ) async {
    final configs = <String, Object>{
      'lightPreset': brightness == Brightness.dark ? 'night' : 'day',
      'showPlaceLabels': true,
      'showPointOfInterestLabels': true,
      'showLandmarkIcons': true,
      'showLandmarkIconLabels': true,
      'densityPointOfInterestLabels': 5,
      'showRoadLabels': true,
      'showTransitLabels': true,
      'showPedestrianRoads': true,
      'showAdminBoundaries': true,
      'show3dObjects': false,
    };

    try {
      await style.setStyleImportConfigProperties(
        standardStyleImportId,
        configs,
      );
    } catch (_) {}
  }

  static Future<void> initialize() async {
    if (kIsWeb) {
      _runtimeAccessToken = '';
      return;
    }

    final envToken = _accessToken.trim();
    if (envToken.isNotEmpty) {
      _runtimeAccessToken = envToken;
      MapboxOptions.setAccessToken(envToken);
      return;
    }

    try {
      final nativeToken =
          (await _channel.invokeMethod<String>('getAccessToken'))?.trim() ?? '';
      if (nativeToken.isNotEmpty) {
        _runtimeAccessToken = nativeToken;
        MapboxOptions.setAccessToken(nativeToken);
      }
    } catch (_) {}
  }
}
