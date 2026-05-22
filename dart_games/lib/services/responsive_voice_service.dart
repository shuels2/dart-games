// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// JS interop definitions for ResponsiveVoice
@JS('responsiveVoice')
external ResponsiveVoiceJS? get responsiveVoice;

@JS()
extension type ResponsiveVoiceJS(JSObject _) implements JSObject {
  external bool voiceSupport();
  external void speak(JSString text, JSString voiceName, JSAny? options);
  external void cancel();
  external JSArray getVoices();
}

@JS()
extension type ResponsiveVoiceOptions._(JSObject _) implements JSObject {
  external factory ResponsiveVoiceOptions({
    JSNumber pitch,
    JSNumber rate,
    JSNumber volume,
    JSFunction? onend,
  });
}

@JS()
extension type ResponsiveVoiceVoice(JSObject _) implements JSObject {
  external JSString get name;
}

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
      final rv = responsiveVoice;
      if (rv == null) {
        print('ResponsiveVoice object not found on window');
        return false;
      }

      // Check if voiceSupport() returns true
      final voiceSupport = rv.voiceSupport();
      if (!voiceSupport) {
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

  /// Speak text using ResponsiveVoice.
  ///
  /// Returns a `Future<void>` that resolves when the underlying JS engine
  /// fires its `onend` callback (i.e. speech has actually finished). If the
  /// service is not ready or the call throws synchronously, the future
  /// resolves immediately (so callers can always `await` safely).
  ///
  /// The queue service relies on this future to know exactly when the
  /// current utterance ended, so the next announcement can start without
  /// the conservative wordCount-based estimate that used to gate it.
  Future<void> speak(String text, {
    String voiceName = 'US English Female',
    double pitch = 1.0,
    double rate = 1.0,
    double volume = 1.0,
  }) {
    final completer = Completer<void>();
    try {
      if (!isReady()) {
        print('ResponsiveVoice not ready, cannot speak');
        completer.complete();
        return completer.future;
      }

      final rv = responsiveVoice;
      if (rv == null) {
        completer.complete();
        return completer.future;
      }

      // onend fires when the JS engine has actually finished speaking. Wrap
      // the completion in a guard so a duplicate/late onend can't double-
      // complete the Completer.
      final onEndCallback = (() {
        if (!completer.isCompleted) completer.complete();
      }).toJS;

      final options = ResponsiveVoiceOptions(
        pitch: pitch.toJS,
        rate: rate.toJS,
        volume: volume.toJS,
        onend: onEndCallback,
      );

      // Call responsiveVoice.speak(text, voiceName, options)
      rv.speak(text.toJS, voiceName.toJS, options);
      print('Speaking: "$text" with voice: $voiceName (rate: $rate)');
    } catch (e) {
      print('ResponsiveVoice speak error: $e');
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  /// Cancel current speech
  void cancel() {
    try {
      if (isReady()) {
        final rv = responsiveVoice;
        if (rv != null) {
          rv.cancel();
        }
      }
    } catch (e) {
      print('ResponsiveVoice cancel error: $e');
    }
  }

  /// Get list of available voices
  List<String> getVoices() {
    try {
      if (!isReady()) return [];

      final rv = responsiveVoice;
      if (rv == null) return [];

      final voicesJs = rv.getVoices();

      // Convert JS array to Dart list
      final List<String> voices = [];
      final dartVoices = voicesJs.toDart;

      for (final voiceAny in dartVoices) {
        try {
          final voice = voiceAny as ResponsiveVoiceVoice;
          voices.add(voice.name.toDart);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
      return voices;
    } catch (e) {
      print('ResponsiveVoice getVoices error: $e');
      return [];
    }
  }
}
