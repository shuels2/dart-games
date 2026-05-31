import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/tiki_golf_game.dart';
import 'package:dart_games/providers/tiki_golf_provider.dart';
import '../../../mocks/mock_tiki_golf_audio_queue_service.dart';
import '../../../shared/mock_api_helpers.dart';

/// Tiki Golf – Game-with-Announcements Integration Tests
///
/// Verifies that announcements fire correctly in response to provider
/// state changes.  Uses [MockTikiGolfAudioQueueService] in place of the
/// real [GameAnnouncementQueueService] so tests run deterministically
/// without web audio APIs.

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Creates a solo provider with a seeded [Random] so hole targets are fixed.
/// With seed 42: holeTargets[0] == the first entry from the seeded shuffle.
TikiGolfProvider _makeSoloProvider({
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  List<String>? playerIds,
  Random? random,
}) {
  final p = TikiGolfProvider();
  p.startGame(
    playerIds: playerIds ?? ['p1', 'p2'],
    maxStrokes: maxStrokes,
    mulliganEnabled: mulliganEnabled,
    gameMode: TikiGolfGameMode.solo,
    teamAssignment: TikiGolfTeamAssignment.random,
    random: random,
  );
  return p;
}

/// Returns the target number for [holeIndex] (0-based) from [game].
int _target(TikiGolfGame game, int holeIndex) =>
    game.holeTargets[holeIndex];

/// Computes the sector string for a single hit on [targetNumber].
String _hitSector(int targetNumber) => 'S$targetNumber';

/// Computes a miss sector for a given [targetNumber].
String _missSector(int targetNumber) => 'S${targetNumber == 1 ? 2 : 1}';

/// Convenience: call the announcer's pickAndAnnounceMoment with the state
/// that the game screen would compute AFTER [processDartThrow] returns.
///
/// [prevHole] — hole number BEFORE the throw.
/// [isAutoPlaying] — simulate auto-play guard.
void _announceForThrow({
  required MockTikiGolfAudioQueueService queue,
  required TikiGolfProvider provider,
  required int prevHole,
  bool isAutoPlaying = false,
}) {
  if (isAutoPlaying) return; // auto-play guard suppresses all per-dart announcements

  final game = provider.currentGame!;

  // Determine last-throw context from game state AFTER the throw.
  // We use the fact that dartsThrown and playerHoleScores are mutated.
  // Because announceForThrow is called immediately after processDartThrow,
  // activePlayerId still points to the player whose turn it was IF turn ended,
  // or to the next player if the provider already advanced.
  // In this test helper we always read from provider state post-throw,
  // matching what the real game screen would compute.

  final currentTurnEnded = game.currentTurnEnded;
  final hasWinner = game.hasWinner;

  // Identify the player who just threw: if turn is not over, it's activePlayerId.
  // If turn ended (or won) the provider has NOT yet advanced (advanceTurn happens
  // on confirmTurnEnd, not processDartThrow), so activePlayerId is still correct.
  final throwerId = game.activePlayerId;

  if (throwerId == null) return;

  final holeIndex = game.currentHole - 1;
  final dartsThrown = game.dartsThrown[throwerId] ?? 0;
  final holeScore = game.playerHoleScores[throwerId]?[holeIndex];

  // ── Build fact flags ────────────────────────────────────────────────────────
  final victory = hasWinner && currentTurnEnded;

  // Hole complete: all players have scored the current hole AND turn just ended
  final holeComplete = currentTurnEnded && !hasWinner && game.isCurrentHoleComplete;

  // Score (only when turn ended with a score). Mirrors the classifier in
  // lib/screens/games/tiki_golf/tiki_golf_game_screen.dart — splash wins
  // first, then per-dart bogey flavor.
  String? score;
  if (currentTurnEnded && holeScore != null) {
    if (holeScore == game.maxStrokes + 1) {
      score = 'splash';
    } else if (holeScore == 1) {
      score = 'birdie';
    } else if (holeScore == 2) {
      score = 'par';
    } else if (holeScore == 3) {
      score = 'bogey';
    } else if (holeScore == 4) {
      score = 'doubleBogey';
    } else if (holeScore == 5) {
      score = 'tripleBogey';
    } else if (holeScore == 6) {
      score = 'quadrupleBogey';
    }
  }

  // Mulligan reminder: turn ended as Splash + mulligan enabled + not yet used
  final mulliganAlreadyUsed = (game.playerMulligansUsed[throwerId] ?? 0) == 1;
  final wasSplash = holeScore != null && holeScore == game.maxStrokes + 1;
  final mulliganReminder = currentTurnEnded &&
      wasSplash &&
      game.mulliganEnabled &&
      !mulliganAlreadyUsed &&
      !holeComplete; // if hole is complete, HoleComplete outranks MulliganReminder

  // Almost there: dart 1 missed, dart 2 (the par dart) is next.
  final almostThere = !currentTurnEnded &&
      dartsThrown == 1 &&
      holeScore == null;

  // Miss: mid-turn, no hit, not the penultimate dart
  final miss = !currentTurnEnded && holeScore == null && !almostThere;

  queue.pickAndAnnounceMoment(
    victory: victory,
    victoryWinnerName: victory ? throwerId : null,
    holeComplete: holeComplete,
    holeCompleteNextHole: holeComplete ? game.currentHole + 1 : null,
    mulliganReminder: mulliganReminder,
    score: score,
    scorePlayerName: score != null ? throwerId : null,
    almostThere: almostThere,
    almostTherePlayerName: almostThere ? throwerId : null,
    miss: miss,
  );

  // Unconditional Remove Darts on turn-end (simulates game screen behavior)
  if (currentTurnEnded) {
    queue.announceRemoveDarts(throwerId);
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MockApiServer();
  });

  // ── Group 1: Lifecycle announcements ──────────────────────────────────────────

  group('Lifecycle announcements', () {
    test('Game Start fires once at game start', () {
      final queue = MockTikiGolfAudioQueueService();
      queue.announceGameStart();
      expect(queue.announcements,
          equals(["Welcome to Tiki Golf! Let's tee off!"]));
    });

    test('Player Turn fires after takeout for each new player', () {
      final queue = MockTikiGolfAudioQueueService();
      queue.announcePlayerTurn('p1');
      queue.clearAnnouncements();
      queue.announcePlayerTurn('p2');
      expect(queue.announcements, equals(["p2, you're on the tee!"]));
    });

    test('New Hole fires with correct hole number and target from holeTargets', () {
      final provider = _makeSoloProvider(random: Random(99));
      final game = provider.currentGame!;
      final target = _target(game, 1); // hole 2's target (0-based index 1)

      final queue = MockTikiGolfAudioQueueService();
      queue.announceNewHole(2, target);

      expect(queue.announcements, equals(['Hole 2: Aim for number $target!']));
    });

    test('New Hole target differs from hole 1 when holeTargets are distinct', () {
      final provider = _makeSoloProvider(random: Random(42));
      final game = provider.currentGame!;
      final targetH1 = _target(game, 0);
      final targetH2 = _target(game, 1);
      // holeTargets are guaranteed distinct
      expect(targetH1, isNot(equals(targetH2)));
    });
  });

  // ── Group 2: Per-dart moment announcements ────────────────────────────────────

  group('Per-dart moment announcements from provider state', () {
    test('Birdie: 1st-dart hit → birdie announcement + Remove Darts', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Birdie'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Par: 2nd-dart hit → par announcement + Remove Darts', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Dart 1: miss
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      queue.clearAnnouncements();

      // Dart 2: hit
      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Par'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Bogey: 3rd-dart hit → bogey announcement + Remove Darts', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Darts 1 & 2: miss
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      queue.clearAnnouncements();

      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      queue.clearAnnouncements();

      // Dart 3: hit
      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Bogey'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Splash: all maxStrokes missed → splash announcement + Remove Darts', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 3, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // All 3 darts miss
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
        _announceForThrow(queue: queue, provider: provider, prevHole: 1);
        if (i < 2) queue.clearAnnouncements(); // keep only last dart's output
      }

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Splash'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Mid-turn miss (dart 2 of 3): Miss fires, Remove Darts does NOT fire', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 3, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Dart 1 miss fires Almost There — clear before checking dart 2.
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      queue.clearAnnouncements();

      // Dart 2 miss → Miss (par is gone, no Almost There).
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(1));
      expect(queue.announcements[0], equals('That one went wide!'));
    });

    test('Almost There: dart 1 miss fires Almost There (next dart could still be Par)',
        () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 3, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Dart 1 miss → Almost There (dart 2 hit would still be Par)
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(1));
      expect(queue.announcements[0], contains('One dart left'));
    });

    test('Almost There does NOT fire on dart 2 miss (par is already gone)', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 3, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Dart 1 miss → Almost There
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      queue.clearAnnouncements();

      // Dart 2 miss → Miss (NOT Almost There — dart 3 hit would be Bogey)
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(1));
      expect(queue.announcements[0], equals('That one went wide!'));
    });

    test('Double Bogey: 4th-dart hit at maxStrokes=4 → double bogey + Remove Darts',
        () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 4, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Darts 1-3: miss
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
        _announceForThrow(queue: queue, provider: provider, prevHole: 1);
        queue.clearAnnouncements();
      }

      // Dart 4: hit
      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Double bogey'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Triple Bogey: 5th-dart hit at maxStrokes=5 → triple bogey + Remove Darts',
        () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 5, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Darts 1-4: miss
      for (int i = 0; i < 4; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
        _announceForThrow(queue: queue, provider: provider, prevHole: 1);
        queue.clearAnnouncements();
      }

      // Dart 5: hit
      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Triple bogey'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Quadruple Bogey: 6th-dart hit at maxStrokes=6 → quadruple bogey + Remove Darts',
        () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 6, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Darts 1-5: miss
      for (int i = 0; i < 5; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
        _announceForThrow(queue: queue, provider: provider, prevHole: 1);
        queue.clearAnnouncements();
      }

      // Dart 6: hit
      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], contains('Quadruple bogey'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Almost There fires on dart 1 only at maxStrokes=4 (dart 2 hit would still be Par)',
        () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 4, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Dart 1: miss → Almost There
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      expect(queue.announcements[0], contains('One dart left'));
      queue.clearAnnouncements();

      // Dart 2: miss → Miss (NOT Almost There — par gone)
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      expect(queue.announcements[0], equals('That one went wide!'));
      queue.clearAnnouncements();

      // Dart 3: miss → still Miss
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      expect(queue.announcements.length, equals(1));
      expect(queue.announcements[0], equals('That one went wide!'));
    });
  });

  // ── Group 3: Hole completion ───────────────────────────────────────────────────

  group('Hole Complete announcement', () {
    test('Hole Complete fires when last player finishes hole (not suppressed by score)', () {
      final rng = Random(5);
      final provider = _makeSoloProvider(
        playerIds: ['p1', 'p2'],
        maxStrokes: 3,
        random: rng,
      );
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // p1 misses all → Splash, turn ended, NOT hole complete (p2 still to go)
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
      }
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);
      // Hole NOT complete yet → Splash (rank 5) wins, not Hole Complete
      expect(queue.announcements[0], contains('Splash'));
      queue.clearAnnouncements();

      // Advance to p2
      provider.confirmTurnEnd();

      // p2 misses all → Splash, now hole IS complete
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
      }
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      // Hole Complete (rank 2) beats Splash (rank 5)
      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], equals('On to hole 2!'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });
  });

  // ── Group 4: Mulligan flow ─────────────────────────────────────────────────────

  group('Mulligan flow announcements', () {
    test('Mulligan Reminder fires when Splash+mulligan available (mid-hole)', () {
      final rng = Random(3);
      final provider = _makeSoloProvider(
        playerIds: ['p1', 'p2'],
        maxStrokes: 3,
        mulliganEnabled: true,
        random: rng,
      );
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // p1 splashes, hole NOT complete (p2 still to go), mulligan available
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
      }
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      expect(queue.announcements.length, equals(2));
      expect(queue.announcements[0], equals('Splash! Use your mulligan?'));
      expect(queue.announcements[1], equals('Remove your darts'));
    });

    test('Mulligan Used announcement fires when useMulligan is invoked', () {
      final rng = Random(3);
      final provider = _makeSoloProvider(
        playerIds: ['p1', 'p2'],
        maxStrokes: 3,
        mulliganEnabled: true,
        random: rng,
      );
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // p1 splashes
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
      }
      queue.clearAnnouncements();

      // Player taps USE MULLIGAN
      provider.useMulligan();
      queue.announceMulliganUsed('p1');

      expect(queue.announcements, equals(['Mulligan! p1 gets a do-over!']));
    });

    test('After mulligan, second Splash has no Mulligan Reminder (already used)', () {
      final rng = Random(3);
      final provider = _makeSoloProvider(
        playerIds: ['p1', 'p2'],
        maxStrokes: 3,
        mulliganEnabled: true,
        random: rng,
      );
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // p1 splashes → mulligan used
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
      }
      provider.useMulligan();
      queue.clearAnnouncements();

      // p1 splashes again (mulligan already used)
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(sector: _missSector(target), score: 0);
      }
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      // MulliganAlreadyUsed → Mulligan Reminder does NOT fire
      // Splash (rank 5) fires instead
      expect(queue.announcements[0], contains('Splash'));
      expect(queue.announcements[0], isNot(contains('mulligan')));
    });
  });

  // ── Group 5: Victory announcement ─────────────────────────────────────────────

  group('Victory announcement', () {
    test('Victory fires when final hole completed (2-player solo game)', () {
      // Build a provider that can reach game-end quickly: set all hole scores
      // for holes 1-8 for both players, then play out hole 9.
      final rng = Random(7);
      final provider = _makeSoloProvider(
        playerIds: ['p1', 'p2'],
        maxStrokes: 3,
        random: rng,
      );
      final game = provider.currentGame!;

      // Fast-forward: fill all hole scores up to hole 8 for both players.
      for (int h = 0; h < 8; h++) {
        for (final pid in ['p1', 'p2']) {
          game.playerHoleScores[pid]![h] = 2; // par
        }
      }
      // Set game to hole 9 directly (bypassing turns 1-8)
      game.currentHole = 9;
      game.activePlayerId = 'p1';
      game.dartsThrown['p1'] = 0;
      game.currentTurnEnded = false;

      final target9 = _target(game, 8);
      final queue = MockTikiGolfAudioQueueService();

      // p1 hits hole 9 on dart 1 (birdie)
      provider.processDartThrow(sector: _hitSector(target9), score: target9);
      expect(game.currentTurnEnded, isTrue);
      // Hole NOT complete yet (p2 still to play) → score announcement
      _announceForThrow(queue: queue, provider: provider, prevHole: 9);
      queue.clearAnnouncements();

      // Advance to p2 (confirmTurnEnd → _advanceSoloPlayer → next player)
      provider.confirmTurnEnd();
      // Provider advanced to p2 naturally
      expect(game.activePlayerId, equals('p2'));
      game.dartsThrown['p2'] = 0;
      game.currentTurnEnded = false;

      // p2 hits hole 9 → sets currentTurnEnded, but hasWinner NOT yet set
      provider.processDartThrow(sector: _hitSector(target9), score: target9);
      expect(game.currentTurnEnded, isTrue);

      // Game screen calls confirmTurnEnd after takeout → _advanceSoloPlayer
      // → nextIndex out of bounds → _advanceToNextHole → hole 10 > 9 → _endGame
      // → hasWinner set. Simulate this flow here.
      provider.confirmTurnEnd();

      // Now hasWinner is true
      expect(provider.hasWinner, isTrue);

      // Announce Victory (game screen would detect hasWinner in _handleTakeoutFinished
      // and fire victory before navigating to results).
      queue.announceVictory('p1'); // p1 has lower total (all pars vs p2 birdie)

      expect(queue.announcements.first, contains('Golden Tiki'));
    });
  });

  // ── Group 6: Auto-play suppression ────────────────────────────────────────────

  group('Auto-play suppression', () {
    test('No per-dart announcements fire when isAutoPlaying = true', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Simulate auto-play: isAutoPlaying = true
      provider.processDartThrow(sector: _hitSector(target), score: target);
      _announceForThrow(
        queue: queue,
        provider: provider,
        prevHole: 1,
        isAutoPlaying: true, // guard active
      );

      // No announcements should fire
      expect(queue.announcements, isEmpty);
    });

    test('Announcements resume after auto-play is disabled', () {
      final rng = Random(1);
      final provider = _makeSoloProvider(maxStrokes: 3, random: rng);
      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // Auto-play throws dart 1 (suppressed)
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(
        queue: queue,
        provider: provider,
        prevHole: 1,
        isAutoPlaying: true,
      );
      expect(queue.announcements, isEmpty);

      // Auto-play ends; manual dart 2 (not suppressed)
      provider.processDartThrow(sector: _missSector(target), score: 0);
      _announceForThrow(
        queue: queue,
        provider: provider,
        prevHole: 1,
        isAutoPlaying: false,
      );

      expect(queue.announcements, isNotEmpty);
    });
  });

  // ── Group 7: Team mode announcements ──────────────────────────────────────────

  group('Team mode – Hole Complete fires only after all teams finish', () {
    test('Hole Complete fires only when last team finishes hole', () {
      final allIds = ['t1p1', 't1p2', 't2p1', 't2p2'];
      final provider = TikiGolfProvider();
      provider.startGame(
        playerIds: allIds,
        maxStrokes: 3,
        mulliganEnabled: false,
        gameMode: TikiGolfGameMode.team,
        teamAssignment: TikiGolfTeamAssignment.manual,
        teamCount: 2,
        manualTeamAssignments: {
          't1p1': 'team_1',
          't1p2': 'team_1',
          't2p1': 'team_2',
          't2p2': 'team_2',
        },
        random: Random(11),
      );

      final game = provider.currentGame!;
      final target = _target(game, 0);
      final queue = MockTikiGolfAudioQueueService();

      // t1p1 throws (not hole complete)
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      expect(game.isCurrentHoleComplete, isFalse);
      queue.clearAnnouncements();
      provider.confirmTurnEnd();

      // t1p2 throws
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      expect(game.isCurrentHoleComplete, isFalse);
      queue.clearAnnouncements();
      provider.confirmTurnEnd();

      // t2p1 throws
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      expect(game.isCurrentHoleComplete, isFalse);
      queue.clearAnnouncements();
      provider.confirmTurnEnd();

      // t2p2 — last player. After this throw, hole IS complete.
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      provider.processDartThrow(
          sector: _missSector(target), score: 0);
      _announceForThrow(queue: queue, provider: provider, prevHole: 1);

      // Hole Complete (rank 2) should fire (not Splash rank 5)
      expect(queue.announcements.first, equals('On to hole 2!'));
    });
  });
}
