import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/dart_announcer_service.dart';
import 'package:dart_games/services/game_announcement_models.dart';
import 'package:dart_games/services/game_announcement_queue_service.dart';

/// Behaviour tests for the announcement queue itself.
///
/// Companion to dart_announcer_service_test.dart — see the note there about
/// why these were previously impossible. The queue additionally needs the
/// audioplayers channels mocked, since it builds a SoundEffectPlayerPool.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ttsChannel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> spoken;
  late bool speaking;
  late List<String> overlaps;

  Future<void> finishUtterance() async {
    speaking = false;
    await messenger.handlePlatformMessage(
      'flutter_tts',
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('speak.onComplete')),
      (_) {},
    );
  }

  /// Drains the queue by completing each utterance as it starts, up to
  /// [maxUtterances] so a stuck queue fails the test instead of hanging.
  Future<void> drain({int maxUtterances = 10}) async {
    for (var i = 0; i < maxUtterances; i++) {
      await pumpEventQueue();
      if (!speaking) break;
      await finishUtterance();
    }
    await pumpEventQueue();
  }

  setUp(() {
    spoken = [];
    speaking = false;
    overlaps = [];

    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
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
          return <Object?>[
            <Object?, Object?>{'name': 'Test Voice', 'locale': 'en-AU'},
          ];
        case 'getLanguages':
          return <Object?>['en-AU'];
        default:
          return 1;
      }
    });

    // Sound effects are fire-and-forget; swallow every audioplayers call.
    for (final name in const [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => 1);
    }

    // The announcer is a shared singleton; make sure a previous test's
    // disabled state can't leak in.
    DartAnnouncerService.shared.setEnabled(true);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(ttsChannel, null);
  });

  group('queue drain', () {
    test('plays announcements in the order they were queued', () async {
      final queue = GameAnnouncementQueueService();

      queue.announce('first', AudioPriority.turnTransition);
      queue.announce('second', AudioPriority.victory);
      queue.announce('third', AudioPriority.hitConfirm);

      await drain();

      expect(spoken, ['first', 'second', 'third'],
          reason: 'Strict FIFO — a high-priority line queued later must not '
              'jump ahead');
      expect(overlaps, isEmpty);
      queue.dispose();
    });

    test('whenIdle resolves once the queue has drained', () async {
      final queue = GameAnnouncementQueueService();

      queue.announce('only line', AudioPriority.statusChange);
      var idle = false;
      unawaited(queue.whenIdle().then((_) => idle = true));

      await pumpEventQueue();
      expect(idle, isFalse, reason: 'Still speaking');

      await drain();
      expect(idle, isTrue);
      queue.dispose();
    });
  });

  group('staleness', () {
    test('a line that waited past its maxAge is dropped, not spoken', () async {
      final queue = GameAnnouncementQueueService();

      // Queue a long line first so the second one ages while it waits, then
      // let both reach the front.
      queue.announce('blocking line', AudioPriority.statusChange);
      queue.announce(
        'Alice, you are up',
        AudioPriority.turnTransition,
        // Already expired by the time it is dequeued.
        maxAge: Duration.zero,
      );

      await drain();

      expect(spoken, ['blocking line'],
          reason: 'A turn line that arrives after the moment has passed is '
              'worse than silence');
      queue.dispose();
    });

    test('a line still within its maxAge is spoken', () async {
      final queue = GameAnnouncementQueueService();

      queue.announce('Alice, you are up', AudioPriority.turnTransition,
          maxAge: const Duration(minutes: 1));

      await drain();

      expect(spoken, ['Alice, you are up']);
      queue.dispose();
    });
  });

  group('coalescing', () {
    test('a newer keyed line replaces the queued older one', () async {
      final queue = GameAnnouncementQueueService();

      queue.announce('blocking line', AudioPriority.statusChange);
      queue.announce('Alice, you are up', AudioPriority.turnTransition,
          coalesceKey: 'turn');
      queue.announce('Single 20', AudioPriority.hitConfirm);
      queue.announce('Bob, you are up', AudioPriority.turnTransition,
          coalesceKey: 'turn');

      await drain();

      expect(spoken, ['blocking line', 'Single 20', 'Bob, you are up'],
          reason: 'Only the latest turn line survives; unkeyed lines are '
              'left alone');
      queue.dispose();
    });

    test('the line already being spoken is never replaced', () async {
      final queue = GameAnnouncementQueueService();

      queue.announce('Alice, you are up', AudioPriority.turnTransition,
          coalesceKey: 'turn');
      await pumpEventQueue();
      expect(spoken, ['Alice, you are up'], reason: 'It started speaking');

      queue.announce('Bob, you are up', AudioPriority.turnTransition,
          coalesceKey: 'turn');
      await drain();

      expect(spoken, ['Alice, you are up', 'Bob, you are up']);
      queue.dispose();
    });
  });

  group('failure containment', () {
    test('one failing announcement does not strand the rest of the queue',
        () async {
      final queue = GameAnnouncementQueueService();

      // Make the engine throw for one specific line.
      messenger.setMockMethodCallHandler(ttsChannel, (call) async {
        switch (call.method) {
          case 'speak':
            final text = call.arguments as String;
            if (text == 'boom') throw PlatformException(code: 'engine-failure');
            if (speaking) overlaps.add(text);
            speaking = true;
            spoken.add(text);
            return 1;
          case 'stop':
            speaking = false;
            return 1;
          case 'getVoices':
            return <Object?>[
              <Object?, Object?>{'name': 'Test Voice', 'locale': 'en-AU'},
            ];
          case 'getLanguages':
            return <Object?>['en-AU'];
          default:
            return 1;
        }
      });

      queue.announce('before', AudioPriority.statusChange);
      queue.announce('boom', AudioPriority.statusChange);
      queue.announce('after', AudioPriority.statusChange);

      await drain();

      expect(spoken, contains('before'));
      expect(spoken, contains('after'),
          reason: 'A throw used to abort the whole drain, stranding every '
              'remaining line while whenIdle() resolved anyway');
      queue.dispose();
    });
  });
}
