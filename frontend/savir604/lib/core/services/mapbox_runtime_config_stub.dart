import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxRuntimeConfig {
  static const String standardStyleUri = MapboxStyles.STANDARD;
  static const String standardStyleImportId = 'basemap';

  static const String _accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue:
        'pk.eyJ1IjoiaXNsYW04ODkwIiwiYSI6ImNtcTVwdnlpczAwcjQycnNrcTZkYnNqa3IifQ.NY-wxxxpO5XoCZTD9v7kiQ',
  );

  static String get accessToken => _accessToken.trim();

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
      return;
    }

    final token = accessToken;
    if (token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
    }
  }
}
