class MapboxRuntimeConfig {
  static const String styleUri =
      'mapbox://styles/islam8890/cmq8r8wwz002s01queezn6u5v';

  static String get accessToken =>
      const String.fromEnvironment(
        'MAPBOX_ACCESS_TOKEN',
        defaultValue:
            'pk.eyJ1IjoiaXNsYW04ODkwIiwiYSI6ImNtcTVwdnlpczAwcjQycnNrcTZkYnNqa3IifQ.NY-wxxxpO5XoCZTD9v7kiQ',
      );

  static bool get isConfigured => false;

  static Future<void> initialize() async {}
}
