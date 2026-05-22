import 'api/api_client.dart';

/// Application settings service for storing API keys and preferences.
///
/// Uses the backend API via [ApiClient] for persistent storage.
/// Call [initialize] once at app startup before using any other methods.
class AppSettings {
  static ApiClient? _client;

  /// Set the API client. Call once at app startup.
  static void initialize(ApiClient client) {
    _client = client;
  }

  static ApiClient get _api {
    if (_client == null) {
      throw StateError(
          'AppSettings not initialized. Call AppSettings.initialize() first.');
    }
    return _client!;
  }

  /// For testing: allow injecting a mock client.
  static set client(ApiClient? c) => _client = c;

  /// Save Google Cloud TTS API key
  static Future<void> saveGoogleApiKey(String apiKey) async {
    await _api.putSetting('google_tts_api_key', apiKey);
  }

  /// Get saved Google Cloud TTS API key
  static Future<String?> getGoogleApiKey() async {
    return await _api.getSetting('google_tts_api_key');
  }

  /// Clear Google Cloud TTS API key
  static Future<void> clearGoogleApiKey() async {
    await _api.deleteSetting('google_tts_api_key');
  }

  /// Save voice engine preference
  static Future<void> saveVoiceEngine(String engine) async {
    await _api.putSetting('voice_engine', engine);
  }

  /// Get saved voice engine preference
  static Future<String?> getVoiceEngine() async {
    return await _api.getSetting('voice_engine');
  }

  /// Save selected Google voice
  static Future<void> saveGoogleVoice(String voiceName) async {
    await _api.putSetting('google_voice_name', voiceName);
  }

  /// Get saved Google voice
  static Future<String?> getGoogleVoice() async {
    return await _api.getSetting('google_voice_name');
  }

  /// Save voice enabled state
  static Future<void> saveVoiceEnabled(bool enabled) async {
    await _api.putSetting('voice_enabled', enabled.toString());
  }

  /// Get voice enabled state (defaults to true if not set)
  static Future<bool> getVoiceEnabled() async {
    final value = await _api.getSetting('voice_enabled');
    if (value == null) return true; // default
    return value == 'true';
  }

  /// Save announcer style preference
  static Future<void> saveAnnouncerStyle(String style) async {
    await _api.putSetting('announcer_style', style);
  }

  /// Get saved announcer style preference
  static Future<String?> getAnnouncerStyle() async {
    return await _api.getSetting('announcer_style');
  }

  /// Save system voice preference
  static Future<void> saveSystemVoice(String voice) async {
    await _api.putSetting('system_voice', voice);
  }

  /// Get saved system voice preference
  static Future<String?> getSystemVoice() async {
    return await _api.getSetting('system_voice');
  }

  /// Save ResponsiveVoice preference
  static Future<void> saveResponsiveVoice(String voice) async {
    await _api.putSetting('responsive_voice', voice);
  }

  /// Get saved ResponsiveVoice preference
  static Future<String?> getResponsiveVoice() async {
    return await _api.getSetting('responsive_voice');
  }

  /// Save voice playback rate (1.0 = normal). Range typically 0.7-1.5 in the
  /// settings UI; clients should clamp.
  static Future<void> saveVoicePlaybackRate(double rate) async {
    await _api.putSetting('voice_playback_rate', rate.toString());
  }

  /// Get voice playback rate (defaults to 1.0 if not set / unparseable).
  static Future<double> getVoicePlaybackRate() async {
    final value = await _api.getSetting('voice_playback_rate');
    if (value == null) return 1.0;
    return double.tryParse(value) ?? 1.0;
  }

  // ---- Gameplay settings ----

  /// Save the "per-dart score announcements" toggle. When false (the
  /// default), games suppress the generic per-dart score readout
  /// (Carnival Derby "Single 20", Target Tag "Single 20", Monster Mash
  /// "Single 20") that previously fired on every dart with no other
  /// special game effect. Dart-hit SFX and game-specific announcements
  /// (attacks, eliminations, taglines, etc.) still play.
  static Future<void> savePerDartScoreAnnouncements(bool enabled) async {
    await _api.putSetting('per_dart_score_announcements', enabled.toString());
  }

  /// Get the "per-dart score announcements" toggle. Defaults to false
  /// (no per-dart score readout) — chosen to keep the per-turn audio
  /// short by default. Users who want the readouts back can re-enable
  /// from System Settings → Gameplay.
  static Future<bool> getPerDartScoreAnnouncements() async {
    final value = await _api.getSetting('per_dart_score_announcements');
    if (value == null) return false;
    return value == 'true';
  }
}
