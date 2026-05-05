import 'package:flutter_test/flutter_test.dart';
import '../../../mocks/mock_lunar_lander_audio_queue_service.dart';

/// Lunar Lander Announcement Tests
///
/// Tests the announcement system via [MockLunarLanderAudioQueueService], which
/// mirrors the real [LunarLanderAnnouncementHelper] precedence logic exactly.
///
/// Coverage:
///   Group 1 — Lifecycle announcements (game start, player turn)
///   Group 2 — Moment announcements (one per dart, all 8 precedence tiers)
///   Group 3 — Stacking enforcement (≤ 2 announcements per dart event)
///   Group 4 — Text content (key phrases in announcement strings)

void main() {
  late MockLunarLanderAudioQueueService mock;

  setUp(() {
    mock = MockLunarLanderAudioQueueService();
  });

  tearDown(() {
    mock.dispose();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 1 — Lifecycle announcements
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 1 — Lifecycle announcements', () {
    test('1. announceGameStart fires with starting altitude in text', () {
      mock.announceGameStart(startingAltitude: 200);

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Mission control, altitude 200! Begin descent!',
      );
    });

    test('2. announceGameStart works for altitude 100', () {
      mock.announceGameStart(startingAltitude: 100);

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0],
          contains('altitude 100'));
    });

    test('3. announcePlayerTurn fires with player name', () {
      mock.announcePlayerTurn(playerName: 'Alice');

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Alice, you have the controls!',
      );
    });

    test('4. announcePlayerTurn uses provided name', () {
      mock.announcePlayerTurn(playerName: 'Rocket Bob');

      expect(mock.recordedAnnouncements[0], contains('Rocket Bob'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 2 — Moment announcements (one per dart, all 8 precedence tiers)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 2 — Moment announcements', () {
    test('5. Standard descent (dart 1-39, no other condition) plays standard descent', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: 200,
        newAltitude: 180,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      // Only 1 moment announcement
      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Alice descends 20! Altitude: 180!',
      );
    });

    test('6. Big descent (dart ≥40, no other condition) plays big descent', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 60, // triple-20
        previousAltitude: 200,
        newAltitude: 140,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Major burn! Alice drops 60! Altitude: 140!',
      );
    });

    test('7. Miss (dart 0, no other condition) plays drift sound', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 0,
        previousAltitude: 200,
        newAltitude: 200,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Alice drifts in orbit!',
      );
    });

    test('8. Near Landing (newAlt 1-20) plays near landing', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 15,
        previousAltitude: 35,
        newAltitude: 20, // exactly 20 — boundary
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Final approach! Alice at altitude 20!',
      );
    });

    test('9. Near Landing at altitude 1 plays near landing', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 19,
        previousAltitude: 20,
        newAltitude: 1,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Final approach'));
    });

    test('10. Crash Landing (HL ON + bust) plays crash landing and suppresses descent', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 60, // would be big descent without bust
        previousAltitude: 50,
        newAltitude: 50, // reverted after bust
        wasBust: true,
        hasWinner: false,
        hardLandingEnabled: true,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Crash landing! Alice pulls back to 50!',
      );
    });

    test('11. Touchdown (hasWinner=true) plays touchdown and suppresses all others', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: 20,
        newAltitude: 0, // exact landing
        wasBust: false,
        hasWinner: true,
        hardLandingEnabled: false,
      );

      // 2 entries: touchdown voice + victory fanfare sound-only
      expect(mock.announcementCount, 2);
      expect(
        mock.recordedAnnouncements[0],
        'Touchdown! Alice lands on the moon!',
      );
    });

    test('12. Climbing Back (HL OFF, prevAlt<0, newAlt>prevAlt, newAlt<0) plays climbing back', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 10, // subtracts from -20 to get -10 ... wait, ascending.
        // prevAlt=-20, dart makes it go up (subtract value from -20 -> -10)
        // Actually: altitude is SUBTRACTED by dart. So to go from -20 to -10,
        // dart score = 10, but -20 - 10 = -30. That's wrong.
        // Climbing back means: altitude was negative, and the NEW altitude is
        // LESS negative. But wait — in Lunar Lander, darts SUBTRACT from altitude.
        // If prevAlt=-30 and dart score=10, newAlt = -30 - 10 = -40. That's worse.
        //
        // Climbing back actually means: prevAlt < 0 AND newAlt > prevAlt AND newAlt < 0
        // This is technically only possible if dart score is negative, which can't happen.
        //
        // Re-reading the spec: "HL OFF, prevAlt < 0, newAlt > prevAlt, newAlt < 0"
        // means newAlt is CLOSER to 0 than prevAlt. But since darts subtract,
        // newAlt = prevAlt - dartValue. For newAlt > prevAlt to be true,
        // dartValue must be NEGATIVE, which is not possible with real darts.
        //
        // This condition covers cases where score editing (edit score dialog)
        // adjusts the altitude upward, or future expansion. We still need to test
        // the logic path, so we simulate the state directly.
        //
        // We provide raw values that satisfy the condition:
        //   previousAltitude = -30, newAltitude = -10 (closer to 0), newAlt < 0
        previousAltitude: -30,
        newAltitude: -10,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Alice is climbing back! Altitude: -10!',
      );
    });

    test('13. Negative Altitude (HL OFF, newAlt<0, not climbing-back) plays negative altitude', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: 10, // was positive
        newAltitude: -10, // went negative
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Alice overshot! Altitude: -10!',
      );
    });

    test('14. Negative Altitude also fires when deepening negative (HL OFF)', () {
      // prevAlt=-10, newAlt=-30 — not climbing back (newAlt < prevAlt), not winner
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: -10,
        newAltitude: -30,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('overshot'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 3 — Stacking enforcement (CRITICAL)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 3 — Stacking enforcement', () {
    test('15. Worst-case: near-landing (score ≥40 + alt 1-20) → only Near Landing fires (1 moment)', () {
      // score=40 would normally trigger Big Descent, but alt 20 triggers Near Landing
      // Near Landing has higher precedence than Big Descent
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 40,
        previousAltitude: 60,
        newAltitude: 20, // in Near Landing zone [1,20]
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      // Only 1 moment announcement — Near Landing wins over Big Descent
      expect(mock.announcementCount, 1);
      expect(
        mock.recordedAnnouncements[0],
        'Final approach! Alice at altitude 20!',
        reason: 'Near Landing must suppress Big Descent',
      );
    });

    test('16. Worst-case: big-descent + win simultaneously → only Touchdown fires (1 moment)', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 60, // big descent score
        previousAltitude: 60,
        newAltitude: 0, // touchdown
        wasBust: false,
        hasWinner: true, // win condition
        hardLandingEnabled: false,
      );

      // Touchdown voice + victory fanfare = 2 entries, but only 1 voice announcement
      // and the fanfare is sound-only (empty text). Touchdown won over Big Descent.
      expect(
        mock.recordedAnnouncements[0],
        'Touchdown! Alice lands on the moon!',
        reason: 'Touchdown must suppress Big Descent',
      );
      // No big-descent text
      expect(
        mock.recordedAnnouncements.any((a) => a.contains('Major burn')),
        isFalse,
        reason: 'Big Descent must be suppressed when Touchdown fires',
      );
    });

    test('17. After moment announcement + Remove Darts: total ≤ 2 announcements', () {
      // Standard descent moment
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: 200,
        newAltitude: 180,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );
      // Remove darts always fires unconditionally
      mock.announceRemoveDarts();

      // 1 moment + 1 remove = 2 total
      expect(
        mock.announcementCount,
        lessThanOrEqualTo(2),
        reason: 'Max 2 announcements per dart event (1 moment + Remove Darts)',
      );
      expect(mock.announcementCount, 2);
    });

    test('18. "Remove your darts" always plays — never suppressed by moment announcement', () {
      // Fire different moment announcements and verify remove darts still queues

      // After touchdown
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: 20,
        newAltitude: 0,
        wasBust: false,
        hasWinner: true,
        hardLandingEnabled: false,
      );
      mock.announceRemoveDarts(); // must always fire
      expect(
        mock.recordedAnnouncements.any((a) => a == 'Remove your darts'),
        isTrue,
        reason: 'Remove darts must fire even after Touchdown',
      );

      mock.clearAnnouncements();

      // After crash landing
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 60,
        previousAltitude: 30,
        newAltitude: 30,
        wasBust: true,
        hasWinner: false,
        hardLandingEnabled: true,
      );
      mock.announceRemoveDarts(); // must always fire
      expect(
        mock.recordedAnnouncements.any((a) => a == 'Remove your darts'),
        isTrue,
        reason: 'Remove darts must fire even after Crash Landing',
      );

      mock.clearAnnouncements();

      // After near landing
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 15,
        previousAltitude: 35,
        newAltitude: 20,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );
      mock.announceRemoveDarts();
      expect(
        mock.recordedAnnouncements.any((a) => a == 'Remove your darts'),
        isTrue,
        reason: 'Remove darts must fire even after Near Landing',
      );
    });

    test('19. Crash landing + remove darts: exactly 2 announcements total', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 60,
        previousAltitude: 30,
        newAltitude: 30, // reverted altitude after bust
        wasBust: true,
        hasWinner: false,
        hardLandingEnabled: true,
      );
      mock.announceRemoveDarts();

      expect(mock.announcementCount, 2,
          reason: 'Crash landing (1) + Remove darts (1) = 2 total');
      expect(mock.recordedAnnouncements[0],
          'Crash landing! Alice pulls back to 30!');
      expect(mock.recordedAnnouncements[1], 'Remove your darts');
    });

    test('20. Standard descent + remove darts: exactly 2 announcements', () {
      mock.announceMomentForDart(
        playerName: 'Bob',
        dartScore: 15,
        previousAltitude: 100,
        newAltitude: 85,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );
      mock.announceRemoveDarts();

      expect(mock.announcementCount, 2);
      expect(mock.recordedAnnouncements[1], 'Remove your darts');
    });

    test('21. Near Landing takes precedence over Big Descent (score=60, alt=15)', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 60,
        previousAltitude: 75,
        newAltitude: 15, // in [1,20] near-landing zone
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Final approach'));
      expect(mock.recordedAnnouncements.any((a) => a.contains('Major burn')), isFalse);
    });

    test('22. Touchdown takes precedence over Near Landing (newAlt=0 + win)', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 10,
        previousAltitude: 10,
        newAltitude: 0,
        wasBust: false,
        hasWinner: true,
        hardLandingEnabled: false,
      );

      expect(mock.recordedAnnouncements[0], contains('Touchdown'));
      expect(mock.recordedAnnouncements.any((a) => a.contains('Final approach')), isFalse);
    });

    test('23. Crash landing takes precedence over Big Descent (HL ON + bust)', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 50, // would trigger Big Descent without bust
        previousAltitude: 30,
        newAltitude: 30, // reverted
        wasBust: true,
        hasWinner: false,
        hardLandingEnabled: true,
      );

      expect(mock.announcementCount, 1);
      expect(mock.recordedAnnouncements[0], contains('Crash landing'));
      expect(mock.recordedAnnouncements.any((a) => a.contains('Major burn')), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Group 4 — Text content
  // ═══════════════════════════════════════════════════════════════════════════

  group('Group 4 — Text content', () {
    test('24. Touchdown text contains player name', () {
      mock.announceMomentForDart(
        playerName: 'Commander Alice',
        dartScore: 20,
        previousAltitude: 20,
        newAltitude: 0,
        wasBust: false,
        hasWinner: true,
        hardLandingEnabled: false,
      );

      expect(mock.recordedAnnouncements[0], contains('Commander Alice'));
      expect(mock.recordedAnnouncements[0], contains('Touchdown'));
      expect(mock.recordedAnnouncements[0], contains('moon'));
    });

    test('25. Crash landing text contains "Crash landing", player name, and reverted altitude', () {
      mock.announceMomentForDart(
        playerName: 'Bob',
        dartScore: 40,
        previousAltitude: 25,
        newAltitude: 25, // reverted after bust
        wasBust: true,
        hasWinner: false,
        hardLandingEnabled: true,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Crash landing'));
      expect(text, contains('Bob'));
      expect(text, contains('25'));
    });

    test('26. Near landing text contains "Final approach" and altitude', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 10,
        previousAltitude: 25,
        newAltitude: 15,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Final approach'));
      expect(text, contains('15'));
    });

    test('27. Standard descent text contains player name, score, and new altitude', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 20,
        previousAltitude: 150,
        newAltitude: 130,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Alice'));
      expect(text, contains('20'));
      expect(text, contains('130'));
    });

    test('28. Big descent text contains "Major burn", player name, score, and altitude', () {
      mock.announceMomentForDart(
        playerName: 'Bob',
        dartScore: 57, // triple-19
        previousAltitude: 200,
        newAltitude: 143,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Major burn'));
      expect(text, contains('Bob'));
      expect(text, contains('57'));
      expect(text, contains('143'));
    });

    test('29. Miss text contains player name and "drifts in orbit"', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 0,
        previousAltitude: 100,
        newAltitude: 100,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Alice'));
      expect(text, contains('drifts in orbit'));
    });

    test('30. Negative altitude text contains player name, "overshot", and negative altitude', () {
      mock.announceMomentForDart(
        playerName: 'Alice',
        dartScore: 30,
        previousAltitude: 20,
        newAltitude: -10,
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Alice'));
      expect(text, contains('overshot'));
      expect(text, contains('-10'));
    });

    test('31. Climbing back text contains player name, "climbing back", and altitude', () {
      mock.announceMomentForDart(
        playerName: 'Bob',
        dartScore: 0, // dartScore doesn't matter for this branch
        previousAltitude: -30,
        newAltitude: -10, // climbing toward 0
        wasBust: false,
        hasWinner: false,
        hardLandingEnabled: false,
      );

      final text = mock.recordedAnnouncements[0];
      expect(text, contains('Bob'));
      expect(text, contains('climbing back'));
      expect(text, contains('-10'));
    });

    test('32. Game start text includes altitude value', () {
      mock.announceGameStart(startingAltitude: 300);

      expect(mock.recordedAnnouncements[0], contains('300'));
      expect(mock.recordedAnnouncements[0], contains('Mission control'));
    });

    test('33. Player turn text includes player name and "controls"', () {
      mock.announcePlayerTurn(playerName: 'Pilot Joe');

      expect(mock.recordedAnnouncements[0], contains('Pilot Joe'));
      expect(mock.recordedAnnouncements[0], contains('controls'));
    });
  });
}
