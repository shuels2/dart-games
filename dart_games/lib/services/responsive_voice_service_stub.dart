import 'dart:async';

/// Non-web implementation of [ResponsiveVoiceService].
///
/// ResponsiveVoice is a browser library; off the web there is nothing to talk
/// to, so this reports "not ready" and every call is a no-op that resolves
/// immediately. Callers already handle the not-ready case — it is the same
/// path taken on the web before the JS library finishes loading.
///
/// This exists so `dart:js_interop` stays out of the VM's import graph.
/// Importing the web version unconditionally made every library that reaches
/// `DartAnnouncerService` uncompilable under `flutter test`, which is why the
/// announcement services had no unit tests at all.
class ResponsiveVoiceService {
  /// Available ResponsiveVoice voices (natural sounding).
  ///
  /// Kept in the stub so settings screens can list them off-web.
  static const List<Map<String, String>> defaultVoices = [
    {'name': 'US English Female', 'description': 'US Female (Natural)'},
    {'name': 'US English Male', 'description': 'US Male (Natural)'},
    {'name': 'UK English Female', 'description': 'UK Female (Natural)'},
    {'name': 'UK English Male', 'description': 'UK Male (Natural)'},
    {'name': 'Australian Female', 'description': 'Australian Female'},
    {'name': 'Australian Male', 'description': 'Australian Male'},
  ];

  bool isReady() => false;

  Future<void> speak(
    String text, {
    String voiceName = 'US English Female',
    double pitch = 1.0,
    double rate = 1.0,
    double volume = 1.0,
  }) =>
      Future<void>.value();

  void cancel() {}

  List<String> getVoices() => const [];
}
