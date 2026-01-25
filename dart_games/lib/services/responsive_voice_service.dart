import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// ResponsiveVoice Service
/// Uses ResponsiveVoice JavaScript library for natural-sounding speech
/// No server required - works directly in the browser
class ResponsiveVoiceService {
  /// Available ResponsiveVoice voices (natural sounding)
  static const List<Map<String, String>> defaultVoices = [
    {'name': 'US English Female', 'description': 'US Female (Natural)'},
    {'name': 'US English Male', 'description': 'US Male (Natural)'},
    {'name': 'UK English Female', 'description': 'UK Female (Natural)'},
    {'name': 'UK English Male', 'description': 'UK Male (Natural)'},
    {'name': 'Australian Female', 'description': 'Australian Female'},
    {'name': 'Australian Male', 'description': 'Australian Male'},
  ];

  /// Check if ResponsiveVoice is loaded and ready
  bool isReady() {
    try {
      final responsiveVoice = js_util.getProperty(html.window, 'responsiveVoice');
      if (responsiveVoice == null) {
        print('ResponsiveVoice object not found on window');
        return false;
      }

      // Check if voiceSupport() returns true
      final voiceSupport = js_util.callMethod(responsiveVoice, 'voiceSupport', []);
      if (voiceSupport != true) {
        print('ResponsiveVoice not ready yet (voiceSupport returned false)');
        return false;
      }

      print('ResponsiveVoice is loaded and ready');
      return true;
    } catch (e) {
      print('ResponsiveVoice check error: $e');
      return false;
    }
  }

  /// Speak text using ResponsiveVoice
  void speak(String text, {
    String voiceName = 'US English Female',
    double pitch = 1.0,
    double rate = 1.0,
    double volume = 1.0,
  }) {
    try {
      if (!isReady()) {
        print('ResponsiveVoice not ready, cannot speak');
        return;
      }

      final responsiveVoice = js_util.getProperty(html.window, 'responsiveVoice');

      // Create options object
      final options = js_util.newObject();
      js_util.setProperty(options, 'pitch', pitch);
      js_util.setProperty(options, 'rate', rate);
      js_util.setProperty(options, 'volume', volume);

      // Call responsiveVoice.speak(text, voiceName, options)
      js_util.callMethod(responsiveVoice, 'speak', [text, voiceName, options]);
      print('Speaking: "$text" with voice: $voiceName');
    } catch (e) {
      print('ResponsiveVoice speak error: $e');
    }
  }

  /// Cancel current speech
  void cancel() {
    try {
      if (isReady()) {
        final responsiveVoice = js_util.getProperty(html.window, 'responsiveVoice');
        js_util.callMethod(responsiveVoice, 'cancel', []);
      }
    } catch (e) {
      print('ResponsiveVoice cancel error: $e');
    }
  }

  /// Get list of available voices
  List<String> getVoices() {
    try {
      if (!isReady()) return [];

      final responsiveVoice = js_util.getProperty(html.window, 'responsiveVoice');
      final voicesJs = js_util.callMethod(responsiveVoice, 'getVoices', []);

      if (voicesJs == null) return [];

      // Convert JS array to Dart list
      final List<String> voices = [];
      final length = js_util.getProperty(voicesJs, 'length');

      for (int i = 0; i < length; i++) {
        final voice = js_util.getProperty(voicesJs, i.toString());
        if (voice != null) {
          final name = js_util.getProperty(voice, 'name');
          if (name != null) {
            voices.add(name.toString());
          }
        }
      }
      return voices;
    } catch (e) {
      print('ResponsiveVoice getVoices error: $e');
      return [];
    }
  }
}
