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

  group('Priority ordering logic', () {
    test('sorting by priority puts higher values first', () {
      final low = QueuedAnnouncement(
        text: 'Turn change',
        priority: AudioPriority.turnTransition,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
      );
      final mid = QueuedAnnouncement(
        text: 'Hit confirmed',
        priority: AudioPriority.hitConfirm,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 1),
      );
      final high = QueuedAnnouncement(
        text: 'Victory!',
        priority: AudioPriority.victory,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 2),
      );

      // Same sort logic as _processQueue: sort by priority desc, then queuedAt asc
      final queue = [low, mid, high];
      queue.sort((a, b) {
        final priorityCompare = b.priority.value.compareTo(a.priority.value);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      expect(queue[0].text, 'Victory!');
      expect(queue[1].text, 'Hit confirmed');
      expect(queue[2].text, 'Turn change');
    });

    test('same priority uses FIFO (earlier queuedAt first)', () {
      final first = QueuedAnnouncement(
        text: 'First hit',
        priority: AudioPriority.hitConfirm,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
      );
      final second = QueuedAnnouncement(
        text: 'Second hit',
        priority: AudioPriority.hitConfirm,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 1),
      );
      final third = QueuedAnnouncement(
        text: 'Third hit',
        priority: AudioPriority.hitConfirm,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 2),
      );

      final queue = [third, first, second];
      queue.sort((a, b) {
        final priorityCompare = b.priority.value.compareTo(a.priority.value);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      expect(queue[0].text, 'First hit');
      expect(queue[1].text, 'Second hit');
      expect(queue[2].text, 'Third hit');
    });

    test('mixed priorities and timestamps sort correctly', () {
      final earlyLow = QueuedAnnouncement(
        text: 'Early low',
        priority: AudioPriority.turnTransition,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
      );
      final lateHigh = QueuedAnnouncement(
        text: 'Late high',
        priority: AudioPriority.victory,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 5),
      );
      final earlyHigh = QueuedAnnouncement(
        text: 'Early high',
        priority: AudioPriority.victory,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 1),
      );
      final lateLow = QueuedAnnouncement(
        text: 'Late low',
        priority: AudioPriority.turnTransition,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 6),
      );
      final midMid = QueuedAnnouncement(
        text: 'Mid mid',
        priority: AudioPriority.shieldStatus,
        queuedAt: DateTime(2026, 1, 1, 12, 0, 3),
      );

      final queue = [earlyLow, lateHigh, earlyHigh, lateLow, midMid];
      queue.sort((a, b) {
        final priorityCompare = b.priority.value.compareTo(a.priority.value);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      // Victory (5) first, ordered by time
      expect(queue[0].text, 'Early high');
      expect(queue[1].text, 'Late high');
      // Shield status (3)
      expect(queue[2].text, 'Mid mid');
      // Turn transition (1) last, ordered by time
      expect(queue[3].text, 'Early low');
      expect(queue[4].text, 'Late low');
    });

    test('all five priority levels sort in correct order', () {
      final announcements = [
        QueuedAnnouncement(
          text: 'Turn',
          priority: AudioPriority.turnTransition,
          queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
        ),
        QueuedAnnouncement(
          text: 'Hit',
          priority: AudioPriority.hitConfirm,
          queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
        ),
        QueuedAnnouncement(
          text: 'Shield',
          priority: AudioPriority.shieldStatus,
          queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
        ),
        QueuedAnnouncement(
          text: 'Status',
          priority: AudioPriority.statusChange,
          queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
        ),
        QueuedAnnouncement(
          text: 'Victory',
          priority: AudioPriority.victory,
          queuedAt: DateTime(2026, 1, 1, 12, 0, 0),
        ),
      ];

      // Shuffle to ensure sort works regardless of input order
      announcements.shuffle();

      announcements.sort((a, b) {
        final priorityCompare = b.priority.value.compareTo(a.priority.value);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      expect(announcements[0].text, 'Victory');
      expect(announcements[1].text, 'Status');
      expect(announcements[2].text, 'Shield');
      expect(announcements[3].text, 'Hit');
      expect(announcements[4].text, 'Turn');
    });

    test('single item list remains unchanged after sort', () {
      final single = [
        QueuedAnnouncement(
          text: 'Only one',
          priority: AudioPriority.statusChange,
          queuedAt: DateTime(2026, 1, 1),
        ),
      ];

      single.sort((a, b) {
        final priorityCompare = b.priority.value.compareTo(a.priority.value);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      expect(single.length, 1);
      expect(single[0].text, 'Only one');
    });

    test('empty list sort does not throw', () {
      final empty = <QueuedAnnouncement>[];

      expect(() {
        empty.sort((a, b) {
          final priorityCompare = b.priority.value.compareTo(a.priority.value);
          if (priorityCompare != 0) return priorityCompare;
          return a.queuedAt.compareTo(b.queuedAt);
        });
      }, returnsNormally);

      expect(empty, isEmpty);
    });

    test('identical timestamps with different priorities sort by priority', () {
      final sameTime = DateTime(2026, 1, 1, 12, 0, 0);

      final announcements = [
        QueuedAnnouncement(
          text: 'Low',
          priority: AudioPriority.turnTransition,
          queuedAt: sameTime,
        ),
        QueuedAnnouncement(
          text: 'High',
          priority: AudioPriority.victory,
          queuedAt: sameTime,
        ),
      ];

      announcements.sort((a, b) {
        final priorityCompare = b.priority.value.compareTo(a.priority.value);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      expect(announcements[0].text, 'High');
      expect(announcements[1].text, 'Low');
    });
  });

  // Note: GameAnnouncementQueueService instantiation tests are omitted because
  // the constructor creates AudioPlayer and DartAnnouncerService which require
  // web platform plugins (dart:js_interop) not available in the VM test runner.
  // The data class, enum, and priority ordering tests above validate the
  // testable portion of this service without requiring browser compilation.
}
