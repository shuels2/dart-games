import 'package:shared_preferences/shared_preferences.dart';

/// Application settings service for storing API keys and preferences
class AppSettings {
  static const String _googleApiKeyKey = 'google_tts_api_key';
  static const String _voiceEngineKey = 'voice_engine';
  static const String _googleVoiceKey = 'google_voice_name';
  static const String _voiceEnabledKey = 'voice_enabled';

  /// Save Google Cloud TTS API key
  static Future<void> saveGoogleApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleApiKeyKey, apiKey);
  }

  /// Get saved Google Cloud TTS API key
  static Future<String?> getGoogleApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleApiKeyKey);
  }

  /// Clear Google Cloud TTS API key
  static Future<void> clearGoogleApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_googleApiKeyKey);
  }

  /// Save voice engine preference
  static Future<void> saveVoiceEngine(String engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceEngineKey, engine);
  }

  /// Get saved voice engine preference
  static Future<String?> getVoiceEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_voiceEngineKey);
  }

  /// Save selected Google voice
  static Future<void> saveGoogleVoice(String voiceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleVoiceKey, voiceName);
  }

  /// Get saved Google voice
  static Future<String?> getGoogleVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleVoiceKey);
  }

  /// Save voice enabled state
  static Future<void> saveVoiceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceEnabledKey, enabled);
  }

  /// Get voice enabled state
  static Future<bool> getVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceEnabledKey) ?? true;
  }
}
