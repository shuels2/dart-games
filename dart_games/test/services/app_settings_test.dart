import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings - Google API Key', () {
    test('saves and retrieves Google API key', () async {
      const testKey = 'test-api-key-12345';

      await AppSettings.saveGoogleApiKey(testKey);
      final retrieved = await AppSettings.getGoogleApiKey();

      expect(retrieved, testKey);
    });

    test('returns null when no API key is saved', () async {
      final retrieved = await AppSettings.getGoogleApiKey();

      expect(retrieved, isNull);
    });

    test('clears Google API key', () async {
      const testKey = 'test-api-key-12345';

      await AppSettings.saveGoogleApiKey(testKey);
      await AppSettings.clearGoogleApiKey();
      final retrieved = await AppSettings.getGoogleApiKey();

      expect(retrieved, isNull);
    });

    test('overwrites existing API key', () async {
      const firstKey = 'first-key';
      const secondKey = 'second-key';

      await AppSettings.saveGoogleApiKey(firstKey);
      await AppSettings.saveGoogleApiKey(secondKey);
      final retrieved = await AppSettings.getGoogleApiKey();

      expect(retrieved, secondKey);
    });

    test('handles empty API key string', () async {
      const emptyKey = '';

      await AppSettings.saveGoogleApiKey(emptyKey);
      final retrieved = await AppSettings.getGoogleApiKey();

      expect(retrieved, emptyKey);
    });

    test('handles long API key string', () async {
      final longKey = 'A' * 500;

      await AppSettings.saveGoogleApiKey(longKey);
      final retrieved = await AppSettings.getGoogleApiKey();

      expect(retrieved, longKey);
    });
  });

  group('AppSettings - Voice Engine', () {
    test('saves and retrieves voice engine preference', () async {
      const engine = 'browser';

      await AppSettings.saveVoiceEngine(engine);
      final retrieved = await AppSettings.getVoiceEngine();

      expect(retrieved, engine);
    });

    test('returns null when no engine preference is saved', () async {
      final retrieved = await AppSettings.getVoiceEngine();

      expect(retrieved, isNull);
    });

    test('overwrites existing engine preference', () async {
      const firstEngine = 'browser';
      const secondEngine = 'responsiveVoice';

      await AppSettings.saveVoiceEngine(firstEngine);
      await AppSettings.saveVoiceEngine(secondEngine);
      final retrieved = await AppSettings.getVoiceEngine();

      expect(retrieved, secondEngine);
    });

    test('handles different engine values', () async {
      final engines = ['browser', 'responsiveVoice', 'google'];

      for (final engine in engines) {
        await AppSettings.saveVoiceEngine(engine);
        final retrieved = await AppSettings.getVoiceEngine();
        expect(retrieved, engine);
      }
    });
  });

  group('AppSettings - Google Voice', () {
    test('saves and retrieves Google voice selection', () async {
      const voiceName = 'en-US-Standard-A';

      await AppSettings.saveGoogleVoice(voiceName);
      final retrieved = await AppSettings.getGoogleVoice();

      expect(retrieved, voiceName);
    });

    test('returns null when no voice is saved', () async {
      final retrieved = await AppSettings.getGoogleVoice();

      expect(retrieved, isNull);
    });

    test('overwrites existing voice selection', () async {
      const firstVoice = 'en-US-Standard-A';
      const secondVoice = 'en-GB-Standard-B';

      await AppSettings.saveGoogleVoice(firstVoice);
      await AppSettings.saveGoogleVoice(secondVoice);
      final retrieved = await AppSettings.getGoogleVoice();

      expect(retrieved, secondVoice);
    });

    test('handles various voice name formats', () async {
      final voiceNames = [
        'en-US-Standard-A',
        'en-AU-Wavenet-B',
        'en-GB-Neural2-C',
        'US English Female',
      ];

      for (final voiceName in voiceNames) {
        await AppSettings.saveGoogleVoice(voiceName);
        final retrieved = await AppSettings.getGoogleVoice();
        expect(retrieved, voiceName);
      }
    });
  });

  group('AppSettings - Voice Enabled', () {
    test('saves and retrieves voice enabled state', () async {
      await AppSettings.saveVoiceEnabled(false);
      final retrieved = await AppSettings.getVoiceEnabled();

      expect(retrieved, isFalse);
    });

    test('defaults to true when not set', () async {
      final retrieved = await AppSettings.getVoiceEnabled();

      expect(retrieved, isTrue);
    });

    test('toggles voice enabled state', () async {
      await AppSettings.saveVoiceEnabled(true);
      expect(await AppSettings.getVoiceEnabled(), isTrue);

      await AppSettings.saveVoiceEnabled(false);
      expect(await AppSettings.getVoiceEnabled(), isFalse);

      await AppSettings.saveVoiceEnabled(true);
      expect(await AppSettings.getVoiceEnabled(), isTrue);
    });
  });

  group('AppSettings - Integration', () {
    test('multiple settings can be stored independently', () async {
      const apiKey = 'test-key';
      const engine = 'browser';
      const voice = 'en-US-Standard-A';
      const enabled = false;

      await AppSettings.saveGoogleApiKey(apiKey);
      await AppSettings.saveVoiceEngine(engine);
      await AppSettings.saveGoogleVoice(voice);
      await AppSettings.saveVoiceEnabled(enabled);

      expect(await AppSettings.getGoogleApiKey(), apiKey);
      expect(await AppSettings.getVoiceEngine(), engine);
      expect(await AppSettings.getGoogleVoice(), voice);
      expect(await AppSettings.getVoiceEnabled(), enabled);
    });

    test('clearing one setting does not affect others', () async {
      const apiKey = 'test-key';
      const engine = 'browser';

      await AppSettings.saveGoogleApiKey(apiKey);
      await AppSettings.saveVoiceEngine(engine);

      await AppSettings.clearGoogleApiKey();

      expect(await AppSettings.getGoogleApiKey(), isNull);
      expect(await AppSettings.getVoiceEngine(), engine);
    });

    test('settings persist across multiple accesses', () async {
      const apiKey = 'persistent-key';

      await AppSettings.saveGoogleApiKey(apiKey);

      // Access multiple times
      expect(await AppSettings.getGoogleApiKey(), apiKey);
      expect(await AppSettings.getGoogleApiKey(), apiKey);
      expect(await AppSettings.getGoogleApiKey(), apiKey);
    });
  });
}
