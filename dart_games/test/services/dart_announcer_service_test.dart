import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/dart_announcer_service.dart';
import 'package:dart_games/services/responsive_voice_service.dart';

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

    test('an utterance that never completes does not silence the app forever',
        () async {
      // The failure this guards, seen on a real dartboard with Gladiator
      // Arena: the game announced its start and the first player, then never
      // spoke again for the rest of the session, while sound effects kept
      // playing normally.
      //
      // Cause: speak() serializes every caller through _speakChain, and the
      // tail link was only ever completed by the engine reporting completion.
      // One utterance whose completion never arrived left that link pending,
      // so every later speak() waited on it and _speakNow was never reached
      // again. The queue kept draining on its own timeout — which is why the
      // sound effects, played by the queue rather than the engine, carried on.
      //
      // The test above covers the case where stopSpeaking() rescues the chain.
      // This one covers the case where nothing does.
      final announcer = DartAnnouncerService(
        chainWatchdog: (_) => const Duration(milliseconds: 50),
      );
      await announcer.ready;

      final wedged = announcer.speak('wedged line');
      await pumpEventQueue();
      expect(spoken, ['wedged line']);

      // Deliberately no finishUtterance() and no stopSpeaking(): the engine
      // has simply gone quiet, exactly as the browser speech engine does when
      // an `onend` is dropped.
      final next = announcer.speak('later line');
      await pumpEventQueue();
      expect(spoken, ['wedged line'],
          reason: 'still correctly serialized behind the wedged utterance');

      // Once the watchdog fires the chain must move on by itself.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await pumpEventQueue();

      expect(spoken, ['wedged line', 'later line'],
          reason: 'a wedged utterance must not silence every later one');

      await finishUtterance();
      await next;
      // The wedged future is abandoned by design; nothing awaits it in
      // production either (the queue applies its own timeout).
      unawaited(wedged);
    });
  });

  group('ResponsiveVoice engine', () {
    // The DEFAULT engine in GameAnnouncementQueueService.loadSettings is
    // ResponsiveVoice, and it is what the kiosk speaks through. Off the web
    // the production implementation is a stub that reports "not ready", so
    // this path had no coverage at all — which is precisely where the
    // session-long silence came from.
    //
    // NOTE: this exercises the announcer's half of the contract using a fake.
    // The real browser implementation lives in responsive_voice_service_web
    // and cannot be compiled by the VM test runner; the invariant it must
    // uphold (cancel() completes the in-flight utterance) is guarded
    // separately by test/meta/responsive_voice_cancel_test.dart.

    test('stopSpeaking releases an utterance whose onend never fires',
        () async {
      final rv = _FakeResponsiveVoice();
      final announcer = DartAnnouncerService(responsiveVoice: rv);
      await announcer.ready;
      announcer.useResponsiveVoice();

      final stuck = announcer.speak('stuck line');
      await pumpEventQueue();
      expect(rv.spoken, ['stuck line']);

      // What the queue's watchdog does. Before the fix the ResponsiveVoice
      // completer was not tracked, so this stopped the JS engine but left the
      // Dart future pending — and the chain never moved again.
      await announcer.stopSpeaking();
      await stuck;

      final next = announcer.speak('next line');
      await pumpEventQueue();
      expect(rv.spoken, ['stuck line', 'next line']);

      rv.finish();
      await next;
    });

    test('the chain watchdog releases it even if stopSpeaking is never called',
        () async {
      final rv = _FakeResponsiveVoice();
      final announcer = DartAnnouncerService(
        responsiveVoice: rv,
        chainWatchdog: (_) => const Duration(milliseconds: 50),
      );
      await announcer.ready;
      announcer.useResponsiveVoice();

      unawaited(announcer.speak('wedged line'));
      await pumpEventQueue();
      expect(rv.spoken, ['wedged line']);

      final next = announcer.speak('later line');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await pumpEventQueue();

      expect(rv.spoken, ['wedged line', 'later line']);

      rv.finish();
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

/// A ResponsiveVoice engine that behaves like the browser one: [speak] resolves
/// only when the engine says so, via [finish] (the real `onend`) or [cancel].
///
/// The production off-web implementation is a no-op stub that reports "not
/// ready", so without this fake the ResponsiveVoice branch of `_speakNow` is
/// unreachable under `flutter test`.
class _FakeResponsiveVoice implements ResponsiveVoiceService {
  final List<String> spoken = [];
  Completer<void>? _pending;

  /// The real engine firing `onend`.
  void finish() {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  @override
  bool isReady() => true;

  @override
  Future<void> speak(
    String text, {
    String voiceName = 'US English Female',
    double pitch = 1.0,
    double rate = 1.0,
    double volume = 1.0,
  }) {
    spoken.add(text);
    final completer = Completer<void>();
    _pending = completer;
    return completer.future;
  }

  /// Mirrors the contract the web implementation must uphold: cancelling
  /// resolves whatever was in flight, because `onend` is not guaranteed to
  /// arrive for a cancelled utterance.
  @override
  void cancel() => finish();

  @override
  List<String> getVoices() => const [];
}
