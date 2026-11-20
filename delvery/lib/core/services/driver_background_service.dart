/// Compatibility stub for the legacy background service entrypoint.
///
/// The delivery app now relies on foreground polling, but some older
/// installations or cached isolates may still try to resolve this library.
class DriverBackgroundService {
  static Future<void> configure() async {
    return;
  }

  static Future<bool> start() async {
    return false;
  }

  static Future<void> stop() async {
    return;
  }
}

@pragma('vm:entry-point')
void onStart([dynamic service]) {}
