import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/dart_announcer_service.dart';

/// Tests for the shared announcer's speech serialization.
///
/// These were impossible until `responsive_voice_service.dart` became a
/// conditional import: it pulled `dart:js_interop` into the import graph
/// unconditionally, so nothing that reached `DartAnnouncerService` would
/// compile under the VM test runner. With that fixed, flutter_tts's method
/// channel is all that stands in the way, and a mock handler covers it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Utterances the fake engine was asked to speak, in the order it got them.
  late List<String> spoken;

  /// Whether the fake engine is mid-utterance. Used to prove two callers never
  /// overlap.
  late bool speaking;
  late List<String> overlaps;

  /// Completes the current utterance the way the platform does — by calling
  /// back into flutter_tts, which fires the completion handler the announcer
  /// awaits.
  Future<void> finishUtterance() async {
    speaking = false;
    await messenger.handlePlatformMessage(
      'flutter_tts',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('speak.onComplete'),
      ),
      (_) {},
    );
  }

  setUp(() {
    spoken = [];
    overlaps = [];
    speaking = false;

    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'speak':
          final text = call.arguments as String;
          if (speaking) overlaps.add(text);
          speaking = true;
          spoken.add(text);
          return 1;
        case 'stop':
          speaking = false;
          return 1;
        case 'getVoices':
          // init polls this until it returns something; one entry is enough
          // and keeps construction fast.
          return <Object?>[
            <Object?, Object?>{'name': 'Test Voice', 'locale': 'en-AU'},
          ];
        case 'getLanguages':
          return <Object?>['en-AU'];
        default:
          return 1;
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('speak serialization', () {
    test('a second caller waits for the first utterance to finish', () async {
      final announcer = DartAnnouncerService();
      await announcer.ready;

      // Two queues share this singleton in the real app — the per-game one and
      // GlobalConnectionAnnouncer's. Before serialization they overwrote each
      // other's completer: the first caller's await hung until its queue timed
      // out, and the first utterance's completion resolved the SECOND
      // caller's future, advancing that queue mid-speech.
      final first = announcer.speak('first line');
      final second = announcer.speak('second line');

      await pumpEventQueue();
      expect(spoken, ['first line'],
          reason: 'The second utterance must not start yet');

      await finishUtterance();
      await first;
      await pumpEventQueue();

      expect(spoken, ['first line', 'second line']);
      expect(overlaps, isEmpty, reason: 'Utterances must never overlap');

      await finishUtterance();
      await second;
    });

    test('order is preserved across three callers', () async {
      final announcer = DartAnnouncerService();
      await announcer.ready;

      final futures = [
        announcer.speak('one'),
        announcer.speak('two'),
        announcer.speak('three'),
      ];

      for (var i = 0; i < 3; i++) {
        await pumpEventQueue();
        await finishUtterance();
      }
      await Future.wait(futures);

      expect(spoken, ['one', 'two', 'three']);
      expect(overlaps, isEmpty);
    });

    test('a caller that is never completed does not wedge the next one after '
        'stopSpeaking', () async {
      final announcer = DartAnnouncerService();
      await announcer.ready;

      final stuck = announcer.speak('stuck line');
      await pumpEventQueue();
      expect(spoken, ['stuck line']);

      // This is what the queue's timeout does: abandon the await and cancel
      // the utterance. Without it the engine keeps the line queued and the
      // next announcement talks over it.
      await announcer.stopSpeaking();
      await stuck;

      final next = announcer.speak('next line');
      await pumpEventQueue();
      expect(spoken, ['stuck line', 'next line']);
      expect(overlaps, isEmpty);

      await finishUtterance();
      await next;
    });
  });

  group('enabled flag', () {
    test('speak is a no-op while disabled, and works again once re-enabled',
        () async {
      final announcer = DartAnnouncerService();
      await announcer.ready;

      announcer.setEnabled(false);
      await announcer.speak('silenced');
      expect(spoken, isEmpty);

      // The queue used to set this false and never back to true, which
      // silenced every game for the rest of the session.
      announcer.setEnabled(true);
      final future = announcer.speak('audible');
      await pumpEventQueue();
      expect(spoken, ['audible']);

      await finishUtterance();
      await future;
    });
  });
}
