import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the one invariant that keeps the app talking:
///
///   **every path out of a speech engine must resolve the future it handed
///   back — including cancellation.**
///
/// `DartAnnouncerService.speak()` serializes every caller through a single
/// chain, because the per-game queue and `GlobalConnectionAnnouncer` share one
/// engine and must not talk over each other. The cost of that design is that
/// one utterance which never resolves stops ALL later speech for the session.
///
/// That is not hypothetical. On a real dartboard, Gladiator Arena announced
/// the game start and the first player and then went silent for the rest of
/// the session — while sound effects kept playing, because those are played by
/// the queue rather than by the engine, and the queue kept draining on its own
/// timeout. The cause was `ResponsiveVoiceServiceWeb.cancel()`: it stopped the
/// JS engine but left the Dart completer — which only the JS `onend` callback
/// ever completed — pending forever. `stopSpeaking()`, the watchdog whose
/// whole job is to rescue exactly this situation, therefore could not.
///
/// ─── Why a source-level lint ───────────────────────────────────────────────
/// `responsive_voice_service_web.dart` imports `dart:js_interop` and cannot be
/// compiled by the VM test runner, so no `flutter test` can execute it. Off
/// the web the conditional import resolves to a stub whose `speak()` completes
/// immediately, so the behavioural tests in
/// `test/services/dart_announcer_service_test.dart` exercise a fake that
/// encodes the fixed contract — they would not notice this file regressing.
/// Reading the source as text is the only check that reaches the real code.
void main() {
  final web = File('lib/services/responsive_voice_service_web.dart');
  final stub = File('lib/services/responsive_voice_service_stub.dart');

  group('ResponsiveVoice completion contract', () {
    test('the web implementation exists where the conditional import says',
        () {
      expect(web.existsSync(), isTrue,
          reason: 'lib/services/responsive_voice_service_web.dart is gone or '
              'moved. If the engine was replaced, this lint must be updated '
              'to point at whatever now owns the speak/cancel contract — do '
              'not simply delete it.');
      expect(stub.existsSync(), isTrue);
    });

    test('cancel() resolves the in-flight utterance', () {
      final source = web.readAsStringSync();

      // The pending utterance must be held somewhere cancel() can reach.
      expect(source, contains('Completer<void>? _pending'),
          reason: 'The in-flight utterance must be tracked in a field so '
              'cancel() can complete it. Without that, only the JS onend '
              'callback can ever resolve speak(), and a dropped onend '
              'silences the app for the whole session.');

      // Isolate cancel()'s body and prove it releases that completer on every
      // path — the engine being absent or throwing is exactly when this
      // matters most, so a release inside the `try` would not be enough.
      final cancelStart = source.indexOf('void cancel()');
      expect(cancelStart, greaterThan(-1),
          reason: 'cancel() not found in the web implementation');
      final cancelBody = source.substring(cancelStart);
      final nextMember = cancelBody.indexOf('\n  List<String> getVoices');
      final cancelOnly =
          nextMember > 0 ? cancelBody.substring(0, nextMember) : cancelBody;

      expect(cancelOnly, contains('_releasePending()'),
          reason: 'cancel() must resolve the pending utterance. This is the '
              'watchdog path — stopSpeaking() calls it precisely when the '
              'engine has stopped reporting completion — so it must not '
              'depend on the engine behaving.');
      expect(cancelOnly, contains('finally'),
          reason: 'The release must sit in a finally block. isReady() can be '
              'false and rv.cancel() can throw; both are cases where the '
              'caller is still waiting and must be let go.');
    });

    test('the announcer bounds its speech chain independently', () {
      final announcer =
          File('lib/services/dart_announcer_service.dart').readAsStringSync();

      // Belt and braces: even a well-behaved engine can be replaced by a
      // misbehaving one, so the chain itself must not be able to wedge.
      expect(announcer, contains('_chainWatchdogFor'),
          reason: 'speak() must bound each link of _speakChain. Without it, '
              'any engine that stops reporting completion silences every '
              'later utterance for the rest of the session.');
    });
  });

  group('no speech bypasses the serialization chain', () {
    // Three methods once talked to the engines directly instead of going
    // through _speakNow: announceDart, announceGameStart, and speak()'s own
    // body. Each could start an utterance over whatever the chain was already
    // saying, and on the browser path each one's completion resolved somebody
    // else's `_ttsCompleter` — the flutter_tts completion handler is global —
    // which advanced a game's queue mid-sentence.
    //
    // They were easy to miss because per-game helpers define methods with the
    // SAME NAMES that correctly call queue.announce(). Grepping for the name
    // finds the helpers and hides the bypass, so this lint anchors on the
    // engine calls themselves.

    test('the engines are only touched inside _speakNow', () {
      final path = 'lib/services/dart_announcer_service.dart';
      final lines = File(path).readAsLinesSync();

      // Find _speakNow's span by brace matching. An earlier version of this
      // walked backwards for a member declaration by regex and mistook
      // `await _setBrowserSpeechRate();` for one — indentation slipped into
      // the type pattern. Counting braces is exact.
      final start =
          lines.indexWhere((l) => l.contains('Future<void> _speakNow('));
      expect(start, greaterThan(-1), reason: '_speakNow not found');

      var depth = 0;
      var opened = false;
      var end = lines.length - 1;
      for (var i = start; i < lines.length; i++) {
        for (final ch in lines[i].split('')) {
          if (ch == '{') {
            depth++;
            opened = true;
          } else if (ch == '}') {
            depth--;
          }
        }
        if (opened && depth == 0) {
          end = i;
          break;
        }
      }

      // `_tts.speak` and `_responsiveVoice.speak` actually start speech.
      // Setter/config calls (setPitch, setSpeechRate, stop, cancel) are fine
      // anywhere — they do not produce an utterance.
      final engineCall = RegExp(r'(_tts|_responsiveVoice)\.speak\(');
      final offenders = <String>[];
      for (var i = 0; i < lines.length; i++) {
        if (!engineCall.hasMatch(lines[i])) continue;
        if (i < start || i > end) {
          offenders.add('line ${i + 1}: ${lines[i].trim()}');
        }
      }

      expect(offenders, isEmpty,
          reason: 'These start speech outside _speakNow, so they bypass '
              '_speakChain: they can talk over an in-flight utterance, and on '
              'the browser path their completion resolves another caller\'s '
              '_ttsCompleter. Route them through _enqueueSpeak() instead:\n'
              '${offenders.join('\n')}');
    });

    test('the personality tables are applied on both engine paths', () {
      final source =
          File('lib/services/dart_announcer_service.dart').readAsStringSync();

      // The ResponsiveVoice path used to pass bare _playbackRate and no pitch,
      // which made the announcer style inaudible on the DEFAULT engine.
      expect(source, contains('_effectiveResponsiveVoiceRate()'),
          reason: 'The ResponsiveVoice path must apply the personality rate, '
              'not just the playback slider.');
      expect(source, contains('_responsiveVoicePitch()'),
          reason: 'The ResponsiveVoice path must pass the personality pitch.');
      expect(source, contains('_browserBaseRate()'), reason: 'browser rate');
      expect(source, contains('_browserPitch()'), reason: 'browser pitch');

      // Both engine rates must be bounded. The browser path always clamped;
      // the ResponsiveVoice path did not, so drill (1.2) at the slider maximum
      // (1.5) asked for 1.8.
      final clamps = RegExp(r'\.clamp\(').allMatches(source).length;
      expect(clamps, greaterThanOrEqualTo(2),
          reason: 'Both the browser and ResponsiveVoice effective rates must '
              'be clamped before reaching an engine.');
    });
  });
}
