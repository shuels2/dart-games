import 'package:flutter_test/flutter_test.dart';
import '../../../mocks/mock_pirates_grid_audio_queue_service.dart';

/// Pirate's Grid Announcement Tests
///
/// Tests the announcement system via [MockPiratesGridAudioQueueService], which
/// mirrors the real [PiratesGridAnnouncementHelper] method signatures exactly.
///
/// Coverage:
///   Group 1 — Lifecycle announcements (game start, player turn, round transition, timer)
///   Group 2 — Per-dart moment announcements (all 10 event types)
///   Group 3 — Text content (key phrases in announcement strings)
///   Group 4 — Stacking enforcement (≤ 2 announcements per dart event)

void main() {
  late MockPiratesGridAudioQueueService mock;

  setUp(() {
    mock = MockPiratesGridAudioQueueService();
  });

  tearDown(() {
    mock.dispose();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 1 — Lifecycle announcements
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 1 — Lifecycle announcements', () {
    test('1. announceGameStart fires exactly 1 announcement with correct text', () {
      mock.announceGameStart();

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Set sail! The grid awaits, captains!',
      );
    });

    test('2. announcePlayerTurn fires with player name in text', () {
      mock.announcePlayerTurn('Anne Bonny');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Anne Bonny, take the helm!',
      );
    });

    test('3. announcePlayerTurn uses the provided name (different player)', () {
      mock.announcePlayerTurn('Blackbeard');

      expect(mock.recordedAnnouncements[0], contains('Blackbeard'));
      expect(mock.recordedAnnouncements[0], contains('take the helm'));
    });

    test('4. announceRoundTransition includes round number', () {
      mock.announceRoundTransition(2);

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Round 2! Reset the grid!',
      );
    });

    test('5. announceRoundTransition works for round 3', () {
      mock.announceRoundTransition(3);

      expect(mock.recordedAnnouncements[0], contains('Round 3'));
      expect(mock.recordedAnnouncements[0], contains('Reset the grid'));
    });

    test('6. announceTimerExpired fires with correct text', () {
      mock.announceTimerExpired();

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        "Time's up! The wind takes yer darts!",
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 2 — Per-dart moment announcements
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 2 — Per-dart moment announcements', () {
    test('7. announceFlagPlanted includes player name and target', () {
      mock.announceFlagPlanted('Captain Jack', 'T20');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Captain Jack plants a flag at T20!',
      );
    });

    test('8. announceSquareStolen includes player name and opponent name', () {
      mock.announceSquareStolen('Anne Bonny', 'Blackbeard');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Mutiny! Anne Bonny steals the square from Blackbeard!',
      );
    });

    test('9. announceMiss fires with correct text', () {
      mock.announceMiss();

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Lost at sea! No square claimed.',
      );
    });

    test('10. announceAlreadyClaimed(isOwn: true) fires with "flag already flies" text', () {
      mock.announceAlreadyClaimed(isOwn: true);

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Yer flag already flies there, captain!',
      );
    });

    test('11. announceAlreadyClaimed(isOwn: false) fires with "That square is defended" text', () {
      mock.announceAlreadyClaimed(isOwn: false);

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'That square is defended!',
      );
    });

    test('12. announceTwoInARow includes player name and "two in a row"', () {
      mock.announceTwoInARow('Davy Jones');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Davy Jones has two in a row! One more for treasure!',
      );
    });

    test('13. announceRoundVictory includes player name and "Treasure found"', () {
      mock.announceRoundVictory('Anne Bonny');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Treasure found! Anne Bonny claims the map!',
      );
    });

    test('14. announceRoundDraw fires with correct stalemate text', () {
      mock.announceRoundDraw();

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'A stalemate! Neither captain claims the map!',
      );
    });

    test('15. announceMatchVictory fires with "Captain {name} rules the seas!"', () {
      mock.announceMatchVictory('Captain Jack');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Captain Captain Jack rules the seas!',
      );
    });

    test('16. announceMatchDraw fires with correct match draw text', () {
      mock.announceMatchDraw();

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'The seas remain unclaimed! A true stalemate!',
      );
    });

    test('17. announceRemoveDarts includes player name', () {
      mock.announceRemoveDarts('Blackbeard');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Blackbeard, remove your darts',
      );
    });

    test('18. announceWinner is alias for announceMatchVictory', () {
      mock.announceWinner('Redbeard');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        contains('Redbeard'),
      );
      expect(
        mock.recordedAnnouncements[0],
        contains('rules the seas'),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 3 — Text content (key phrases)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 3 — Text content', () {
    test('19. Game start text contains "Set sail" and "captains"', () {
      mock.announceGameStart();

      expect(mock.recordedAnnouncements[0], contains('Set sail'));
      expect(mock.recordedAnnouncements[0], contains('captains'));
    });

    test('20. Flag planted text contains target label "D18"', () {
      mock.announceFlagPlanted('Anne', 'D18');

      expect(mock.recordedAnnouncements[0], contains('D18'));
      expect(mock.recordedAnnouncements[0], contains('Anne'));
      expect(mock.recordedAnnouncements[0], contains('plants a flag'));
    });

    test('21. Steal text contains "Mutiny", attacker name, and victim name', () {
      mock.announceSquareStolen('Jack', 'Edward');

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Mutiny'));
      expect(text, contains('Jack'));
      expect(text, contains('Edward'));
      expect(text, contains('steals the square'));
    });

    test('22. Two in a row text contains "two in a row" and "One more for treasure"', () {
      mock.announceTwoInARow('Davy');

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('two in a row'));
      expect(text, contains('One more for treasure'));
    });

    test('23. Match victory text contains "Captain" prefix and "rules the seas"', () {
      mock.announceMatchVictory('Jack Sparrow');

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Captain Jack Sparrow'));
      expect(text, contains('rules the seas'));
    });

    test('24. Round victory text contains "Treasure found" and "claims the map"', () {
      mock.announceRoundVictory('Redbeard');

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Treasure found'));
      expect(text, contains('claims the map'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 4 — Stacking enforcement
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 4 — Stacking enforcement', () {
    test('25. After any moment + Remove Darts: total ≤ 2 announcements', () {
      mock.announceFlagPlanted('Jack', 'S20');
      mock.announceRemoveDarts('Jack');

      expect(mock.announcementCount, lessThanOrEqualTo(2));
      expect(mock.announcementCount, 2);
    });

    test('26. "Remove your darts" always plays — never suppressed', () {
      // After match victory
      mock.announceMatchVictory('Jack');
      mock.announceRemoveDarts('Jack');

      expect(
        mock.recordedAnnouncements.any((a) => a.contains('remove your darts')),
        isTrue,
        reason: 'Remove darts must fire even after Match Victory',
      );

      mock.clearAnnouncements();

      // After round draw
      mock.announceRoundDraw();
      mock.announceRemoveDarts('Blackbeard');

      expect(
        mock.recordedAnnouncements.any((a) => a.contains('remove your darts')),
        isTrue,
        reason: 'Remove darts must fire even after Round Draw',
      );
    });

    test('27. clearAnnouncements resets count to zero', () {
      mock.announceGameStart();
      mock.announcePlayerTurn('Jack');
      expect(mock.announcementCount, 2);

      mock.clearAnnouncements();
      expect(mock.announcementCount, 0);
    });
  });
}
