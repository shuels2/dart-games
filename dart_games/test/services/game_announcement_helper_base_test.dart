import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/game_announcement_helper_base.dart';

/// WS02 §2.10. Two of these are source lints rather than behaviour tests
/// because what they guard is a shape a future game can silently break — and
/// the failure mode (the same line spoken twice through two queues) is
/// invisible in a widget test.
void main() {
  final helperFiles = Directory('lib/services')
      .listSync()
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('_announcement_helper.dart') &&
          !f.path.contains('helper_base'))
      .toList();

  group('GameAnnouncementHelperBase.joinWithAnd', () {
    test('handles every arity the tie announcements produce', () {
      expect(GameAnnouncementHelperBase.joinWithAnd([]), '');
      expect(GameAnnouncementHelperBase.joinWithAnd(['Alice']), 'Alice');
      expect(GameAnnouncementHelperBase.joinWithAnd(['Alice', 'Bob']),
          'Alice and Bob');
      expect(
          GameAnnouncementHelperBase.joinWithAnd(['Alice', 'Bob', 'Carol']),
          'Alice, Bob, and Carol');
      expect(
          GameAnnouncementHelperBase.joinWithAnd(
              ['Alice', 'Bob', 'Carol', 'Dan']),
          'Alice, Bob, Carol, and Dan');
    });
  });

  group('helper source shape', () {
    test('every game helper extends the base', () {
      expect(helperFiles, isNotEmpty, reason: 'no helpers found — bad path?');
      final offenders = <String>[];
      for (final f in helperFiles) {
        final src = f.readAsStringSync();
        if (!src.contains('extends GameAnnouncementHelperBase')) {
          offenders.add(f.uri.pathSegments.last);
        }
      }
      expect(offenders, isEmpty,
          reason: 'These helpers do not extend GameAnnouncementHelperBase, so '
              'they carry their own queue field, whenIdle and dispose: '
              '$offenders');
    });

    test('no helper re-declares a private joinWithAnd', () {
      final offenders = [
        for (final f in helperFiles)
          if (f.readAsStringSync().contains('String _joinWithAnd'))
            f.uri.pathSegments.last
      ];
      expect(offenders, isEmpty,
          reason: 'Use GameAnnouncementHelperBase.joinWithAnd: $offenders');
    });

    test('no helper declares pause or reconnect announcements', () {
      // GlobalConnectionAnnouncer owns these, wired once in main.dart. Every
      // helper used to carry dead copies whose doc comments claimed
      // DartboardStatusAnnouncer fired them — an invitation for game #11 to
      // wire both and have the line spoken twice through two queues.
      final offenders = <String>[];
      for (final f in [...helperFiles]) {
        final src = f.readAsStringSync();
        if (src.contains('announceGamePaused') ||
            src.contains('announceConnectionRestored')) {
          offenders.add(f.uri.pathSegments.last);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Pause/reconnect belong to GlobalConnectionAnnouncer only. '
              'Offenders: $offenders');
    });

    test('the base class itself declares no pause/reconnect methods', () {
      final src =
          File('lib/services/game_announcement_helper_base.dart').readAsStringSync();
      // Mentioned in the doc comment on purpose; must not be a declaration.
      expect(src.contains('void announceGamePaused'), isFalse);
      expect(src.contains('void announceConnectionRestored'), isFalse);
    });
  });
}
