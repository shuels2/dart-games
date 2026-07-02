import 'package:flutter_test/flutter_test.dart';
import '../../../mocks/mock_tiki_golf_audio_queue_service.dart';

/// Tiki Golf – Section 9 Announcement Tests
///
/// Verifies every announcement event fires with the correct text, and that
/// the precedence chain + stacking rules produce ≤ 2 announcements per dart.

void main() {
  group('TikiGolf Announcements – individual events', () {
    late MockTikiGolfAudioQueueService queue;

    setUp(() {
      queue = MockTikiGolfAudioQueueService();
    });

    // ── 1. Game Start ──────────────────────────────────────────────────────────

    test('announceGameStart fires correct text', () {
      queue.announceGameStart();
      expect(queue.announcements, equals(["Welcome to Tiki Golf! Let's tee off!"]));
    });

    // ── 2. Player Turn ─────────────────────────────────────────────────────────

    test('announcePlayerTurn fires correct text', () {
      queue.announcePlayerTurn('Alice');
      expect(queue.announcements, equals(["Alice, you're on the tee!"]));
    });

    // ── 3. New Hole (uses per-game-randomized target number) ──────────────────

    test('announceNewHole includes hole number and target number', () {
      queue.announceNewHole(3, 17);
      expect(queue.announcements, equals(['Hole 3: Aim for number 17!']));
    });

    test('announceNewHole uses different target for different holes', () {
      queue.announceNewHole(7, 4);
      expect(queue.announcements, equals(['Hole 7: Aim for number 4!']));
    });

    // ── 4. Birdie ──────────────────────────────────────────────────────────────

    test('announceBirdie fires correct text', () {
      queue.announceBirdie('Bob');
      expect(queue.announcements,
          equals(['Birdie! You sunk it on the first dart!']));
    });

    // ── 5. Par ────────────────────────────────────────────────────────────────

    test('announcePar fires correct text', () {
      queue.announcePar('Carol');
      expect(queue.announcements, equals(['Par! Solid shot!']));
    });

    // ── 6. Bogey ──────────────────────────────────────────────────────────────

    test('announceBogey fires correct text', () {
      queue.announceBogey('Dave');
      expect(queue.announcements, equals(['Bogey! Just squeaked that one in!']));
    });

    test('announceDoubleBogey fires correct text', () {
      queue.announceDoubleBogey('Dave');
      expect(queue.announcements,
          equals(['Double bogey! Squeaked it out!']));
    });

    test('announceTripleBogey fires correct text', () {
      queue.announceTripleBogey('Dave');
      expect(queue.announcements,
          equals(['Triple bogey! Barely hung in!']));
    });

    test('announceQuadrupleBogey fires correct text', () {
      queue.announceQuadrupleBogey('Dave');
      expect(queue.announcements,
          equals(['Quadruple bogey! That was a wild one!']));
    });

    // ── 7. Splash ─────────────────────────────────────────────────────────────

    test('announceSplash fires correct text', () {
      queue.announceSplash('Eve');
      expect(queue.announcements, equals(['Splash! Missed them all!']));
    });

    // ── 8. Miss (mid-turn) ─────────────────────────────────────────────────────

    test('announceMiss fires correct text', () {
      queue.announceMiss();
      expect(queue.announcements, equals(['That one went wide!']));
    });

    // ── 9. Almost There ───────────────────────────────────────────────────────

    test('announceAlmostThere fires correct text', () {
      queue.announceAlmostThere('Frank');
      expect(queue.announcements,
          equals(['One dart left to save par!']));
    });

    // ── 10. Mulligan Used ─────────────────────────────────────────────────────

    test('announceMulliganUsed fires correct text', () {
      queue.announceMulliganUsed('Grace');
      expect(queue.announcements,
          equals(['Mulligan! Grace gets a do-over!']));
    });

    // ── 11. Mulligan Reminder ─────────────────────────────────────────────────

    test('announceMulliganReminder fires correct text', () {
      queue.announceMulliganReminder();
      expect(queue.announcements, equals(['Splash! Use your mulligan?']));
    });

    // ── 12. Near Win ──────────────────────────────────────────────────────────

    test('announceNearWin fires correct text with lead count', () {
      queue.announceNearWin('Hank', 5);
      expect(queue.announcements, equals(['Final hole! Hank leads by 5!']));
    });

    // ── 13. Victory ───────────────────────────────────────────────────────────

    test('announceVictory: single winner uses "wins" phrasing', () {
      queue.announceVictory(['Iris']);
      expect(queue.announcements, equals(['Iris wins the Golden Tiki!']));
    });

    test('announceVictory: two-way tie uses "and … tie" phrasing', () {
      queue.announceVictory(['Iris', 'Jack']);
      expect(
        queue.announcements,
        equals(['Iris and Jack tie for the Golden Tiki!']),
      );
    });

    test('announceVictory: 3+ tie uses Oxford-comma "…, …, and … tie" phrasing',
        () {
      queue.announceVictory(['Iris', 'Jack', 'Kim']);
      expect(
        queue.announcements,
        equals(['Iris, Jack, and Kim tie for the Golden Tiki!']),
      );
    });

    test('announceVictory: empty list is a no-op (defensive)', () {
      queue.announceVictory(const []);
      expect(queue.announcements, isEmpty);
    });

    // ── 14. Hole Complete ─────────────────────────────────────────────────────

    test('announceHoleComplete fires correct text with next hole number', () {
      queue.announceHoleComplete(4);
      expect(queue.announcements, equals(['On to hole 4!']));
    });

    // ── 15. Remove Darts ──────────────────────────────────────────────────────

    test('announceRemoveDarts fires "Remove your darts"', () {
      queue.announceRemoveDarts('Jack');
      expect(queue.announcements, equals(['Remove your darts']));
    });
  });

  // ─── Precedence chain tests ──────────────────────────────────────────────────

  group('TikiGolf Announcements – precedence chain (pickAndAnnounceMoment)', () {
    late MockTikiGolfAudioQueueService queue;

    setUp(() {
      queue = MockTikiGolfAudioQueueService();
    });

    // ── Rank 1: Victory beats everything ──────────────────────────────────────

    test('Victory (rank 1) wins over Hole Complete, Birdie, Miss', () {
      queue.pickAndAnnounceMoment(
        victory: true,
        victoryWinnerNames: const ['Alice'],
        holeComplete: true,
        holeCompleteNextHole: 2,
        score: 'birdie',
        scorePlayerName: 'Alice',
        miss: true,
      );
      expect(queue.announcements, equals(['Alice wins the Golden Tiki!']));
    });

    test('Final-hole winning birdie: Victory plays, Birdie + Hole Complete suppressed', () {
      // Remove Darts is called unconditionally OUTSIDE this chain.
      // This test verifies only the moment-winner (Victory) fires.
      queue.pickAndAnnounceMoment(
        victory: true,
        victoryWinnerNames: const ['Alice'],
        holeComplete: true,
        holeCompleteNextHole: 10, // would be "On to hole 10" but suppressed
        score: 'birdie',
        scorePlayerName: 'Alice',
      );
      // Only Victory should be announced — Birdie and Hole Complete suppressed
      expect(queue.announcements.length, equals(1));
      expect(queue.announcements.first, contains('Golden Tiki'));
    });

    // ── Rank 2: Hole Complete beats Mulligan Reminder, Score ──────────────────

    test('Hole Complete (rank 2) beats Mulligan Reminder (rank 3)', () {
      queue.pickAndAnnounceMoment(
        holeComplete: true,
        holeCompleteNextHole: 3,
        mulliganReminder: true,
        score: 'splash',
        scorePlayerName: 'Bob',
      );
      expect(queue.announcements, equals(['On to hole 3!']));
    });

    test('Splash on last-player last-dart of hole with mulligan available: '
        'Hole Complete wins (rank 2 > rank 3)', () {
      // All players done → holeComplete = true.
      // This player splashed with mulligan available → mulliganReminder = true.
      // HoleComplete outranks MulliganReminder.
      queue.pickAndAnnounceMoment(
        holeComplete: true,
        holeCompleteNextHole: 2,
        mulliganReminder: true,
        score: 'splash',
        scorePlayerName: 'Bob',
      );
      expect(queue.announcements.length, equals(1));
      expect(queue.announcements.first, equals('On to hole 2!'));
    });

    // ── Rank 3: Mulligan Reminder beats Score ─────────────────────────────────

    test('Mid-hole Splash with mulligan available: Mulligan Reminder wins (rank 3 > rank 5)', () {
      // Turn ended as Splash + mulligan available, but the hole is NOT complete
      // yet (other players still to go) → mulliganReminder = true, holeComplete = false.
      queue.pickAndAnnounceMoment(
        mulliganReminder: true,
        score: 'splash',
        scorePlayerName: 'Carol',
      );
      expect(queue.announcements.length, equals(1));
      expect(queue.announcements.first, equals('Splash! Use your mulligan?'));
    });

    // ── Rank 4: Mulligan Used beats Score ─────────────────────────────────────

    test('Mulligan Used (rank 4) beats score announcements', () {
      queue.pickAndAnnounceMoment(
        mulliganUsed: true,
        mulliganUsedPlayerName: 'Dave',
        score: 'splash',
        scorePlayerName: 'Dave',
      );
      expect(queue.announcements, equals(['Mulligan! Dave gets a do-over!']));
    });

    // ── Rank 5: Score types are correctly selected ────────────────────────────

    test('Score=birdie fires Birdie announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'birdie',
        scorePlayerName: 'Eve',
      );
      expect(queue.announcements,
          equals(['Birdie! You sunk it on the first dart!']));
    });

    test('Score=par fires Par announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'par',
        scorePlayerName: 'Frank',
      );
      expect(queue.announcements, equals(['Par! Solid shot!']));
    });

    test('Score=bogey fires Bogey announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'bogey',
        scorePlayerName: 'Grace',
      );
      expect(queue.announcements, equals(['Bogey! Just squeaked that one in!']));
    });

    test('Score=doubleBogey fires Double Bogey announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'doubleBogey',
        scorePlayerName: 'Grace',
      );
      expect(queue.announcements,
          equals(['Double bogey! Squeaked it out!']));
    });

    test('Score=tripleBogey fires Triple Bogey announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'tripleBogey',
        scorePlayerName: 'Grace',
      );
      expect(queue.announcements,
          equals(['Triple bogey! Barely hung in!']));
    });

    test('Score=quadrupleBogey fires Quadruple Bogey announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'quadrupleBogey',
        scorePlayerName: 'Grace',
      );
      expect(queue.announcements,
          equals(['Quadruple bogey! That was a wild one!']));
    });

    test('Score=splash fires Splash announcement (rank 5)', () {
      queue.pickAndAnnounceMoment(
        score: 'splash',
        scorePlayerName: 'Hank',
      );
      expect(queue.announcements, equals(['Splash! Missed them all!']));
    });

    // ── Rank 6: Almost There beats Miss ──────────────────────────────────────

    test('Almost There (rank 6) beats Miss (rank 7)', () {
      queue.pickAndAnnounceMoment(
        almostThere: true,
        almostTherePlayerName: 'Iris',
        miss: true,
      );
      expect(queue.announcements, equals(['One dart left to save par!']));
    });

    // ── Rank 7: Miss fires mid-turn (NO Remove Darts) ────────────────────────

    test('Mid-turn miss on dart 2 of 5: Miss fires (rank 7); only 1 announcement total', () {
      // No turn-end → no Remove Darts. Miss is the only announcement budget item.
      queue.pickAndAnnounceMoment(miss: true);
      expect(queue.announcements.length, equals(1));
      expect(queue.announcements.first, equals('That one went wide!'));
    });

    // ── Rank 8-11: Lifecycle events fire when no higher-priority flag set ─────

    test('Game Start fires when no higher-priority flag set', () {
      queue.pickAndAnnounceMoment(gameStart: true);
      expect(queue.announcements,
          equals(["Welcome to Tiki Golf! Let's tee off!"]));
    });

    test('Player Turn fires when no higher-priority flag set', () {
      queue.pickAndAnnounceMoment(playerTurn: true, playerTurnName: 'Jack');
      expect(queue.announcements, equals(["Jack, you're on the tee!"]));
    });

    test('New Hole fires when no higher-priority flag set', () {
      queue.pickAndAnnounceMoment(
        newHole: true,
        newHoleNumber: 2,
        newHoleTargetNumber: 11,
      );
      expect(queue.announcements,
          equals(['Hole 2: Aim for number 11!']));
    });

    test('Near Win fires when no higher-priority flag set', () {
      queue.pickAndAnnounceMoment(
        nearWin: true,
        nearWinPlayerName: 'Kim',
        nearWinLeadBy: 3,
      );
      expect(queue.announcements, equals(['Final hole! Kim leads by 3!']));
    });
  });

  // ─── Stacking / budget tests ──────────────────────────────────────────────────

  group('TikiGolf Announcements – stacking rules', () {
    late MockTikiGolfAudioQueueService queue;

    setUp(() {
      queue = MockTikiGolfAudioQueueService();
    });

    test('Max 2 announcements per turn-end dart: moment + Remove Darts', () {
      // Worst-case dart: birdie that ends hole that ends game.
      // Moment selector picks Victory (rank 1).
      // Game screen then calls announceRemoveDarts unconditionally.
      queue.pickAndAnnounceMoment(
        victory: true,
        victoryWinnerNames: const ['Alice'],
        holeComplete: true,
        holeCompleteNextHole: 10,
        score: 'birdie',
        scorePlayerName: 'Alice',
      );
      queue.announceRemoveDarts('Alice'); // unconditional call from game screen

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Golden Tiki'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Remove Darts always fires on turn-end (cannot be suppressed)', () {
      // Even if only a score fires as the moment, Remove Darts still plays.
      queue.pickAndAnnounceMoment(
        score: 'par',
        scorePlayerName: 'Bob',
      );
      queue.announceRemoveDarts('Bob'); // unconditional

      expect(queue.announcements, contains('Remove your darts'));
    });

    test('Remove Darts does NOT fire mid-turn (no turn-end from game screen)', () {
      // Mid-turn miss: only Miss fires; Remove Darts is NOT called by game screen.
      queue.pickAndAnnounceMoment(miss: true);
      // Game screen does NOT call announceRemoveDarts here (no turn-end).

      expect(queue.announcements.length, equals(1));
      expect(queue.announcements.first, equals('That one went wide!'));
      expect(queue.announcements, isNot(contains('Remove your darts')));
    });

    test('pickAndAnnounceMoment fires exactly 1 announcement', () {
      // The precedence chain always picks exactly ONE winner.
      queue.pickAndAnnounceMoment(
        score: 'bogey',
        scorePlayerName: 'Carol',
        almostThere: true,
        almostTherePlayerName: 'Carol',
        miss: true,
        newHole: true,
        newHoleNumber: 5,
        newHoleTargetNumber: 9,
      );
      expect(queue.announcements.length, equals(1));
      // score (rank 5) beats almostThere (rank 6), miss (7), newHole (10)
      expect(queue.announcements.first, contains('Bogey'));
    });
  });
}
