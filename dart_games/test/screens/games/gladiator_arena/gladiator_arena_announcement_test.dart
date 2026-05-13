import 'package:flutter_test/flutter_test.dart';
import '../../../mocks/mock_gladiator_arena_audio_queue_service.dart';

/// Gladiator Arena Announcement Tests
///
/// Tests the announcement system via [MockGladiatorArenaAudioQueueService], which
/// mirrors the real [GladiatorArenaAnnouncementHelper] precedence logic exactly.
///
/// Coverage:
///   Group 1 — Lifecycle announcements (game start, player turn, shield, etc.)
///   Group 2 — Per-dart moment announcements (all 12 precedence tiers)
///   Group 3 — Stacking enforcement (≤ 1 moment per dart event)
///   Group 4 — Text content (key phrases in announcement strings)

void main() {
  late MockGladiatorArenaAudioQueueService mock;

  setUp(() {
    mock = MockGladiatorArenaAudioQueueService();
  });

  tearDown(() {
    mock.dispose();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 1 — Lifecycle announcements
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 1 — Lifecycle announcements', () {
    test('1. announceGameStart fires with target score in text', () {
      mock.announceGameStart(200);

      expect(mock.announcementCount, 1);
      expect(
        mock.queuedTexts[0],
        'Gladiators, enter the arena! Race to 200!',
      );
    });

    test('2. announceGameStart works for different target scores', () {
      mock.announceGameStart(300);

      expect(mock.queuedTexts[0], contains('300'));
      expect(mock.queuedTexts[0], contains('Gladiators'));
    });

    test('3. announcePlayerTurn fires with player name', () {
      mock.announcePlayerTurn('Alice');

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Alice, step into the arena!');
    });

    test('4. announcePlayerTurn includes provided player name', () {
      mock.announcePlayerTurn('Maximus');

      expect(mock.queuedTexts[0], contains('Maximus'));
      expect(mock.queuedTexts[0], contains('arena'));
    });

    test('5. announceShieldRoundStart fires with shield text', () {
      mock.announceShieldRoundStart();

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Shield round! The arena grants mercy!');
    });

    test('6. announceSpeedTimerWarning fires correct text', () {
      mock.announceSpeedTimerWarning();

      expect(mock.queuedTexts[0], 'The sands are running out!');
    });

    test('7. announceSpeedTimerExpired fires correct text', () {
      mock.announceSpeedTimerExpired();

      expect(mock.queuedTexts[0], 'Time! The arena waits for no one!');
    });

    test('8. announceRemoveDarts fires and sets removeDartsAnnounced flag', () {
      mock.announceRemoveDarts();

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Remove your darts');
      expect(mock.removeDartsAnnounced, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 2 — Per-dart moment announcements (all 12 precedence tiers)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 2 — Per-dart moment announcements', () {
    test('9. Victory fires "All hail" announcement', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 20,
        multiplier: 'double',
        sector: 'D10',
        hasWinner: true,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'All hail Alice, Champion of the Arena!');
    });

    test('10. Knockoff fires "knocked off" announcement', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 60,
        multiplier: 'triple',
        sector: 'T20',
        hasWinner: false,
        knockoffVictimName: 'Bob',
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Bob is knocked off! Back to zero!');
    });

    test('11. Shield block fires "Shields up" announcement', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 40,
        multiplier: 'double',
        sector: 'D20',
        hasWinner: false,
        shieldBlockedName: 'Bob',
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Shields up! Bob is protected!');
    });

    test('12. Bust (overshoot) fires "overshoots" announcement', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 60,
        multiplier: 'triple',
        sector: 'T20',
        hasWinner: false,
        wasBustOvershoot: true,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Alice overshoots! Score unchanged!');
    });

    test('13. Bust (no double) fires "Not a double" announcement', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 20,
        multiplier: 'single',
        sector: 'S20',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0],
          'Not a double! The champion must earn their laurel!');
    });

    test('14. Bull inner fires "Bullseye! 50 glory points!"', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 50,
        multiplier: 'bull',
        sector: 'Bull',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Bullseye! 50 glory points!');
    });

    test('15. Bull outer fires "Outer bull! 25 glory points!"', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 25,
        multiplier: 'single',
        sector: '25',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Outer bull! 25 glory points!');
    });

    test('16. Triple hit fires "A triple!" with dart value', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 60,
        multiplier: 'triple',
        sector: 'T20',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'A triple! 60 glory points!');
    });

    test('17. Great hit (D20=40, not triple) fires "crowd goes wild"', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 40,
        multiplier: 'double',
        sector: 'D20',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'The crowd goes wild! 40 points!');
    });

    test('18. Good hit (single 20) fires "A mighty strike!"', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 20,
        multiplier: 'single',
        sector: 'S20',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'A mighty strike! 20 points!');
    });

    test('19. Small hit (single 5) fires "scores N points"', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 5,
        multiplier: 'single',
        sector: 'S5',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'Alice scores 5 points.');
    });

    test('20. Miss fires "The dart finds only sand!"', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 0,
        multiplier: 'miss',
        sector: 'Miss',
        hasWinner: false,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], 'The dart finds only sand!');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 3 — Stacking enforcement (CRITICAL)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 3 — Stacking enforcement', () {
    test('21. Worst-case: P1 at 100 + T20 (value=60→score 160) matches P2 at 160 → Knockoff, NOT Triple', () {
      // This is the canonical worst-case stacking scenario:
      // P1 throws T20 (triple, value=60). P1 score goes 100→160.
      // P2 is also at 160 → knockoff fires.
      // Triple (priority 8) must be suppressed by Knockoff (priority 2).
      mock.pickAndAnnounceMoment(
        playerName: 'P1',
        dartValue: 60,
        multiplier: 'triple',
        sector: 'T20',
        hasWinner: false,
        knockoffVictimName: 'P2', // P2 was knocked off
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1,
          reason: 'Exactly one moment announcement per dart');
      expect(mock.queuedTexts[0], 'P2 is knocked off! Back to zero!',
          reason: 'Knockoff must suppress Triple Hit');
      expect(
        mock.queuedTexts.any((t) => t.contains('A triple')),
        isFalse,
        reason: 'Triple Hit must be suppressed when Knockoff fires',
      );
      expect(
        mock.queuedTexts.any((t) => t.contains('crowd goes wild')),
        isFalse,
        reason: 'Great Hit must also be suppressed',
      );
    });

    test('22. Victory suppresses Knockoff: hasWinner + knockoff → only Victory fires', () {
      // Extremely unlikely in practice but precedence must hold.
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 20,
        multiplier: 'double',
        sector: 'D10',
        hasWinner: true,
        knockoffVictimName: 'Bob', // would-be knockoff
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], contains('All hail Alice'),
          reason: 'Victory must suppress Knockoff');
      expect(
        mock.queuedTexts.any((t) => t.contains('knocked off')),
        isFalse,
      );
    });

    test('23. Knockoff suppresses Triple: triple + knockoff → only Knockoff fires', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 57,
        multiplier: 'triple',
        sector: 'T19',
        hasWinner: false,
        knockoffVictimName: 'Bob',
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.queuedTexts[0], contains('knocked off'));
      expect(mock.queuedTexts.any((t) => t.contains('triple')), isFalse);
    });

    test('24. Max 2 announcements per dart event: Knockoff + Remove Darts', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 60,
        multiplier: 'triple',
        sector: 'T20',
        hasWinner: false,
        knockoffVictimName: 'Bob',
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );
      // Remove darts fires UNCONDITIONALLY — not part of the precedence chain
      mock.announceRemoveDarts();

      expect(
        mock.announcementCount,
        lessThanOrEqualTo(2),
        reason: 'Max 2 announcements per dart event',
      );
      expect(mock.announcementCount, 2);
    });

    test('25. Remove Darts always plays — even after Victory', () {
      mock.pickAndAnnounceMoment(
        playerName: 'Alice',
        dartValue: 20,
        multiplier: 'double',
        sector: 'D10',
        hasWinner: true,
        wasBustOvershoot: false,
        wasBustNoDouble: false,
      );
      mock.announceRemoveDarts();

      expect(
        mock.queuedTexts.any((t) => t == 'Remove your darts'),
        isTrue,
        reason: 'Remove darts must fire even after Victory',
      );
      expect(mock.removeDartsAnnounced, isTrue);
    });

    test('26. Remove Darts always plays — even after 3 misses', () {
      for (int i = 0; i < 3; i++) {
        mock.pickAndAnnounceMoment(
          playerName: 'Alice',
          dartValue: 0,
          multiplier: 'miss',
          sector: 'Miss',
          hasWinner: false,
          wasBustOvershoot: false,
          wasBustNoDouble: false,
        );
      }
      mock.announceRemoveDarts();

      expect(
        mock.queuedTexts.last,
        'Remove your darts',
        reason: 'Remove darts must fire after 3 misses',
      );
      expect(mock.removeDartsAnnounced, isTrue);
    });

    test('27. clear() resets all state between tests', () {
      mock.announceGameStart(200);
      mock.announceRemoveDarts();
      expect(mock.announcementCount, 2);
      expect(mock.removeDartsAnnounced, isTrue);

      mock.clear();

      expect(mock.announcementCount, 0);
      expect(mock.removeDartsAnnounced, isFalse);
      expect(mock.queuedTexts, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 4 — Text content (key phrases)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 4 — Text content', () {
    test('28. Victory text contains player name and "Champion"', () {
      mock.announceVictory('Maximus');

      expect(mock.queuedTexts[0], contains('Maximus'));
      expect(mock.queuedTexts[0], contains('Champion'));
      expect(mock.queuedTexts[0], contains('Arena'));
    });

    test('29. Knockoff text contains victim name and "zero"', () {
      mock.announceKnockoff('Spartacus');

      expect(mock.queuedTexts[0], contains('Spartacus'));
      expect(mock.queuedTexts[0], contains('knocked off'));
      expect(mock.queuedTexts[0], contains('zero'));
    });

    test('30. Bust overshoot text contains player name and "overshoots"', () {
      mock.announceBustOvershoot('Alice');

      expect(mock.queuedTexts[0], contains('Alice'));
      expect(mock.queuedTexts[0], contains('overshoots'));
      expect(mock.queuedTexts[0], contains('unchanged'));
    });

    test('31. Triple hit text contains dart value', () {
      mock.announceTripleHit(57);

      expect(mock.queuedTexts[0], contains('57'));
      expect(mock.queuedTexts[0], contains('triple'));
    });

    test('32. Small hit text contains player name and score', () {
      mock.announceSmallHit('Bob', 7);

      expect(mock.queuedTexts[0], contains('Bob'));
      expect(mock.queuedTexts[0], contains('7'));
    });

    test('33. Game start text includes "arena" and target score', () {
      mock.announceGameStart(350);

      expect(mock.queuedTexts[0], contains('350'));
      expect(mock.queuedTexts[0], contains('arena'));
    });
  });
}
