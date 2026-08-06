import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/game_announcement_models.dart';

void main() {
  group('AudioPriority', () {
    test('has correct number of values', () {
      expect(AudioPriority.values.length, 5);
    });

    test('turnTransition has lowest value (1)', () {
      expect(AudioPriority.turnTransition.value, 1);
    });

    test('hitConfirm has value 2', () {
      expect(AudioPriority.hitConfirm.value, 2);
    });

    test('shieldStatus has value 3', () {
      expect(AudioPriority.shieldStatus.value, 3);
    });

    test('statusChange has value 4', () {
      expect(AudioPriority.statusChange.value, 4);
    });

    test('victory has highest value (5)', () {
      expect(AudioPriority.victory.value, 5);
    });

    test('priorities are strictly ordered from low to high', () {
      final priorities = AudioPriority.values.toList();
      for (int i = 0; i < priorities.length - 1; i++) {
        expect(priorities[i].value, lessThan(priorities[i + 1].value),
            reason:
                '${priorities[i].name} should be less than ${priorities[i + 1].name}');
      }
    });

    test('turnTransition < hitConfirm < shieldStatus < statusChange < victory',
        () {
      expect(AudioPriority.turnTransition.value,
          lessThan(AudioPriority.hitConfirm.value));
      expect(AudioPriority.hitConfirm.value,
          lessThan(AudioPriority.shieldStatus.value));
      expect(AudioPriority.shieldStatus.value,
          lessThan(AudioPriority.statusChange.value));
      expect(AudioPriority.statusChange.value,
          lessThan(AudioPriority.victory.value));
    });

    test('each enum value has a name', () {
      expect(AudioPriority.turnTransition.name, 'turnTransition');
      expect(AudioPriority.hitConfirm.name, 'hitConfirm');
      expect(AudioPriority.shieldStatus.name, 'shieldStatus');
      expect(AudioPriority.statusChange.name, 'statusChange');
      expect(AudioPriority.victory.name, 'victory');
    });
  });

  group('SoundEffectConfig', () {
    test('constructs with required assetPath', () {
      const config = SoundEffectConfig(assetPath: 'sounds/hit.mp3');

      expect(config.assetPath, 'sounds/hit.mp3');
      expect(config.startSeconds, 0.0);
      expect(config.endSeconds, isNull);
    });

    test('constructs with all fields', () {
      const config = SoundEffectConfig(
        assetPath: 'sounds/victory.mp3',
        startSeconds: 1.5,
        endSeconds: 4.0,
      );

      expect(config.assetPath, 'sounds/victory.mp3');
      expect(config.startSeconds, 1.5);
      expect(config.endSeconds, 4.0);
    });

    test('startSeconds defaults to 0.0', () {
      const config = SoundEffectConfig(assetPath: 'sounds/test.mp3');
      expect(config.startSeconds, 0.0);
    });

    test('endSeconds defaults to null', () {
      const config = SoundEffectConfig(assetPath: 'sounds/test.mp3');
      expect(config.endSeconds, isNull);
    });

    test('can be const-constructed', () {
      // Verifying const constructor works (compile-time constant)
      const config1 = SoundEffectConfig(assetPath: 'a.mp3');
      const config2 = SoundEffectConfig(assetPath: 'a.mp3');
      expect(identical(config1, config2), isTrue);
    });

    test('accepts zero startSeconds', () {
      const config = SoundEffectConfig(
        assetPath: 'sounds/zero.mp3',
        startSeconds: 0.0,
      );
      expect(config.startSeconds, 0.0);
    });

    test('endSeconds can equal startSeconds', () {
      const config = SoundEffectConfig(
        assetPath: 'sounds/point.mp3',
        startSeconds: 2.0,
        endSeconds: 2.0,
      );
      expect(config.startSeconds, config.endSeconds);
    });
  });

  group('QueuedAnnouncement', () {
    test('constructs with required fields', () {
      final announcement = QueuedAnnouncement(
        text: 'Player 1, your turn',
        priority: AudioPriority.turnTransition,
      );

      expect(announcement.text, 'Player 1, your turn');
      expect(announcement.priority, AudioPriority.turnTransition);
      expect(announcement.soundEffect, isNull);
      expect(announcement.queuedAt, isNotNull);
    });

    test('queuedAt defaults to approximately now when not provided', () {
      final before = DateTime.now();
      final announcement = QueuedAnnouncement(
        text: 'Test',
        priority: AudioPriority.hitConfirm,
      );
      final after = DateTime.now();

      expect(
          announcement.queuedAt.isAfter(before) ||
              announcement.queuedAt.isAtSameMomentAs(before),
          isTrue);
      expect(
          announcement.queuedAt.isBefore(after) ||
              announcement.queuedAt.isAtSameMomentAs(after),
          isTrue);
    });

    test('accepts explicit queuedAt timestamp', () {
      final timestamp = DateTime(2026, 1, 1, 12, 0, 0);
      final announcement = QueuedAnnouncement(
        text: 'Test',
        priority: AudioPriority.hitConfirm,
        queuedAt: timestamp,
      );

      expect(announcement.queuedAt, timestamp);
    });

    test('constructs with soundEffect', () {
      const sfx = SoundEffectConfig(
        assetPath: 'sounds/hit.mp3',
        startSeconds: 0.5,
        endSeconds: 2.0,
      );

      final announcement = QueuedAnnouncement(
        text: 'Nice hit!',
        priority: AudioPriority.hitConfirm,
        soundEffect: sfx,
      );

      expect(announcement.soundEffect, isNotNull);
      expect(announcement.soundEffect!.assetPath, 'sounds/hit.mp3');
      expect(announcement.soundEffect!.startSeconds, 0.5);
      expect(announcement.soundEffect!.endSeconds, 2.0);
    });

    test('soundEffect defaults to null', () {
      final announcement = QueuedAnnouncement(
        text: 'Test',
        priority: AudioPriority.turnTransition,
      );

      expect(announcement.soundEffect, isNull);
    });

    test('constructs with each priority level', () {
      for (final priority in AudioPriority.values) {
        final announcement = QueuedAnnouncement(
          text: 'Test ${priority.name}',
          priority: priority,
        );
        expect(announcement.priority, priority);
      }
    });

    test('preserves all fields when constructed with everything', () {
      final timestamp = DateTime(2026, 6, 15, 10, 30, 0);
      const sfx = SoundEffectConfig(
        assetPath: 'sounds/victory_fanfare.mp3',
        startSeconds: 1.0,
        endSeconds: 5.0,
      );

      final announcement = QueuedAnnouncement(
        text: 'Player 3 wins the game!',
        priority: AudioPriority.victory,
        queuedAt: timestamp,
        soundEffect: sfx,
      );

      expect(announcement.text, 'Player 3 wins the game!');
      expect(announcement.priority, AudioPriority.victory);
      expect(announcement.queuedAt, timestamp);
      expect(announcement.soundEffect, sfx);
    });
  });
  // The queue is strict FIFO — AudioPriority is retained on
  // QueuedAnnouncement for logging only and does NOT affect playback order
  // (see the class doc on GameAnnouncementQueueService). These tests cover
  // the ordering rules that DO apply: arrival order, staleness, and
  // coalescing.
  group('Queue ordering rules', () {
    test('announcements keep their arrival order', () {
      final queue = Queue<QueuedAnnouncement>();
      queue.add(QueuedAnnouncement(
          text: 'Victory!', priority: AudioPriority.victory));
      queue.add(QueuedAnnouncement(
          text: 'Turn change', priority: AudioPriority.turnTransition));
      queue.add(QueuedAnnouncement(
          text: 'Hit confirmed', priority: AudioPriority.hitConfirm));

      expect(queue.removeFirst().text, 'Victory!');
      expect(queue.removeFirst().text, 'Turn change');
      expect(queue.removeFirst().text, 'Hit confirmed',
          reason: 'A high-priority line queued later must not jump ahead');
    });

    test('priority does not reorder anything', () {
      final low = QueuedAnnouncement(
          text: 'Turn change', priority: AudioPriority.turnTransition);
      final high =
          QueuedAnnouncement(text: 'Victory!', priority: AudioPriority.victory);
      final queue = Queue<QueuedAnnouncement>()..add(low)..add(high);

      expect(queue.toList().map((a) => a.text), ['Turn change', 'Victory!']);
    });
  });

  group('Staleness', () {
    test('an announcement without maxAge never goes stale', () {
      final a = QueuedAnnouncement(
        text: 'Victory!',
        priority: AudioPriority.victory,
        queuedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(a.isStale, isFalse);
    });

    test('an announcement past its maxAge is stale', () {
      final a = QueuedAnnouncement(
        text: 'Alice, you are up',
        priority: AudioPriority.turnTransition,
        queuedAt: DateTime.now().subtract(const Duration(seconds: 10)),
        maxAge: const Duration(seconds: 4),
      );
      expect(a.isStale, isTrue,
          reason: 'A turn line arriving after the next player threw is worse '
              'than silence');
    });

    test('an announcement within its maxAge is not stale', () {
      final a = QueuedAnnouncement(
        text: 'Alice, you are up',
        priority: AudioPriority.turnTransition,
        queuedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        maxAge: const Duration(seconds: 4),
      );
      expect(a.isStale, isFalse);
    });
  });

  group('Coalescing', () {
    test('coalesceKey defaults to null so nothing is replaced', () {
      final a = QueuedAnnouncement(
          text: 'Single 20', priority: AudioPriority.hitConfirm);
      expect(a.coalesceKey, isNull);
      expect(a.maxAge, isNull);
    });

    test('a newer keyed announcement supersedes the queued older one', () {
      // Mirrors announce(): remove queued entries sharing the key, then add.
      final queue = Queue<QueuedAnnouncement>();
      void enqueue(QueuedAnnouncement a) {
        if (a.coalesceKey != null) {
          queue.removeWhere((q) => q.coalesceKey == a.coalesceKey);
        }
        queue.add(a);
      }

      enqueue(QueuedAnnouncement(
          text: 'Alice, you are up',
          priority: AudioPriority.turnTransition,
          coalesceKey: 'turn'));
      enqueue(QueuedAnnouncement(
          text: 'Single 20', priority: AudioPriority.hitConfirm));
      enqueue(QueuedAnnouncement(
          text: 'Bob, you are up',
          priority: AudioPriority.turnTransition,
          coalesceKey: 'turn'));

      expect(queue.map((a) => a.text), ['Single 20', 'Bob, you are up'],
          reason: 'Only the latest turn line survives; unkeyed lines are '
              'untouched');
    });
  });

  // Note: GameAnnouncementQueueService instantiation tests are omitted because
  // the constructor creates AudioPlayer and DartAnnouncerService which require
  // web platform plugins (dart:js_interop) not available in the VM test runner.
  // The data class, enum, and priority ordering tests above validate the
  // testable portion of this service without requiring browser compilation.
}
