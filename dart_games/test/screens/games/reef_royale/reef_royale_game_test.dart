import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/utils/dartboard_layout.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';

void main() {
  // ─── Helper to create a standard 2-player game ───
  ReefRoyaleGame createGame({
    List<String>? playerIds,
    ReefRoyaleGameMode gameMode = ReefRoyaleGameMode.standard,
    bool easyClaim = false,
    bool neighborNumbers = false,
    bool randomReefs = false,
    bool bonusBuffsEnabled = false,
    bool showHints = true,
    bool speedPlayEnabled = false,
    int roundLimit = 10,
  }) {
    final ids = playerIds ?? ['p1', 'p2'];
    return ReefRoyaleGame.create(
      playerIds: ids,
      gameMode: gameMode,
      easyClaim: easyClaim,
      neighborNumbers: neighborNumbers,
      randomReefs: randomReefs,
      bonusBuffsEnabled: bonusBuffsEnabled,
      showHints: showHints,
      speedPlayEnabled: speedPlayEnabled,
      roundLimit: roundLimit,
    );
  }

  // Helper: force targets to standard for predictable tests
  ReefRoyaleGame createStandardGame({
    List<String>? playerIds,
    ReefRoyaleGameMode gameMode = ReefRoyaleGameMode.standard,
    bool easyClaim = false,
    bool neighborNumbers = false,
    bool bonusBuffsEnabled = false,
    bool speedPlayEnabled = false,
    int roundLimit = 10,
  }) {
    final ids = playerIds ?? ['p1', 'p2'];
    return ReefRoyaleGame(
      id: 'test-game',
      startedAt: DateTime.now(),
      maxDartsPerTurn: 3,
      gameMode: gameMode,
      easyClaim: easyClaim,
      neighborNumbers: neighborNumbers,
      randomReefs: false,
      bonusBuffsEnabled: bonusBuffsEnabled,
      showHints: true,
      speedPlayEnabled: speedPlayEnabled,
      roundLimit: roundLimit,
      playerIds: ids,
      creatureAssignments: {
        for (int i = 0; i < ids.length; i++)
          ids[i]: SeaCreature.values[i]
      },
      activeTargets: ReefRoyaleGame.standardTargets,
      coralOrder: ReefRoyaleGame.standardCoralOrder,
      state: ReefRoyaleGameState.playing,
      currentPlayerIndex: 0,
    );
  }

  // ═══════════════════════════════════════════════════
  // DartboardLayout Tests
  // ═══════════════════════════════════════════════════
  group('DartboardLayout', () {
    test('clockwiseOrder has 20 elements', () {
      expect(DartboardLayout.clockwiseOrder.length, 20);
    });

    test('clockwiseOrder contains all numbers 1-20', () {
      final sorted = List<int>.from(DartboardLayout.clockwiseOrder)..sort();
      expect(sorted, List.generate(20, (i) => i + 1));
    });

    test('getNeighbors returns two elements for valid numbers', () {
      for (int i = 1; i <= 20; i++) {
        expect(DartboardLayout.getNeighbors(i).length, 2);
      }
    });

    test('getNeighbors for 20 returns [5, 1]', () {
      expect(DartboardLayout.getNeighbors(20), [5, 1]);
    });

    test('getNeighbors for 19 returns [3, 7]', () {
      expect(DartboardLayout.getNeighbors(19), [3, 7]);
    });

    test('getNeighbors for 18 returns [1, 4]', () {
      expect(DartboardLayout.getNeighbors(18), [1, 4]);
    });

    test('getNeighbors for 17 returns [2, 3]', () {
      expect(DartboardLayout.getNeighbors(17), [2, 3]);
    });

    test('getNeighbors for 16 returns [7, 8]', () {
      expect(DartboardLayout.getNeighbors(16), [7, 8]);
    });

    test('getNeighbors for 15 returns [10, 2]', () {
      expect(DartboardLayout.getNeighbors(15), [10, 2]);
    });

    test('isNeighbor correctly identifies adjacent numbers', () {
      expect(DartboardLayout.isNeighbor(1, 20), true);
      expect(DartboardLayout.isNeighbor(5, 20), true);
      expect(DartboardLayout.isNeighbor(3, 19), true);
      expect(DartboardLayout.isNeighbor(7, 19), true);
    });

    test('isNeighbor rejects non-adjacent numbers', () {
      expect(DartboardLayout.isNeighbor(10, 20), false);
      expect(DartboardLayout.isNeighbor(20, 19), false);
    });

    test('isNeighbor rejects out-of-range numbers', () {
      expect(DartboardLayout.isNeighbor(0, 20), false);
      expect(DartboardLayout.isNeighbor(21, 20), false);
      expect(DartboardLayout.isNeighbor(5, 0), false);
    });

    test('getNeighbors returns empty for invalid number', () {
      expect(DartboardLayout.getNeighbors(0), isEmpty);
      expect(DartboardLayout.getNeighbors(21), isEmpty);
    });

    test('findNeighborTarget finds correct target', () {
      final targets = [20, 19, 18, 17, 16, 15];
      expect(DartboardLayout.findNeighborTarget(1, targets), 20);
      expect(DartboardLayout.findNeighborTarget(5, targets), 20);
      expect(DartboardLayout.findNeighborTarget(3, targets), 19);
      expect(DartboardLayout.findNeighborTarget(7, targets), 19);
    });

    test('findNeighborTarget returns null for non-neighbors', () {
      final targets = [20, 19];
      expect(DartboardLayout.findNeighborTarget(9, targets), isNull);
      expect(DartboardLayout.findNeighborTarget(11, targets), isNull);
    });

    test('findAllNeighborTargets returns all matching targets for shared neighbors', () {
      final targets = [20, 19, 18, 17, 16, 15];
      // 1 is neighbor of both 20 and 18
      expect(DartboardLayout.findAllNeighborTargets(1, targets), containsAll([20, 18]));
      expect(DartboardLayout.findAllNeighborTargets(1, targets), hasLength(2));
      // 3 is neighbor of both 19 and 17
      expect(DartboardLayout.findAllNeighborTargets(3, targets), containsAll([19, 17]));
      expect(DartboardLayout.findAllNeighborTargets(3, targets), hasLength(2));
      // 7 is neighbor of both 19 and 16
      expect(DartboardLayout.findAllNeighborTargets(7, targets), containsAll([19, 16]));
      expect(DartboardLayout.findAllNeighborTargets(7, targets), hasLength(2));
      // 2 is neighbor of both 17 and 15
      expect(DartboardLayout.findAllNeighborTargets(2, targets), containsAll([17, 15]));
      expect(DartboardLayout.findAllNeighborTargets(2, targets), hasLength(2));
    });

    test('findAllNeighborTargets returns single target for non-shared neighbors', () {
      final targets = [20, 19, 18, 17, 16, 15];
      // 5 is neighbor of only 20
      expect(DartboardLayout.findAllNeighborTargets(5, targets), [20]);
    });

    test('findAllNeighborTargets returns empty for non-neighbors', () {
      final targets = [20, 19];
      expect(DartboardLayout.findAllNeighborTargets(9, targets), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════
  // ReefRoyaleGame.create Tests
  // ═══════════════════════════════════════════════════
  group('ReefRoyaleGame.create', () {
    test('creates game in playing state', () {
      final game = createGame();
      expect(game.state, ReefRoyaleGameState.playing);
      expect(game.currentPlayerIndex, 0);
      expect(game.currentRound, 1);
    });

    test('assigns unique creatures to all players', () {
      final game = createGame(playerIds: ['p1', 'p2', 'p3', 'p4']);
      final creatures = game.creatureAssignments.values.toSet();
      expect(creatures.length, 4); // All unique
    });

    test('uses standard targets when randomReefs is off', () {
      final game = createGame(randomReefs: false);
      expect(game.activeTargets, [20, 19, 18, 17, 16, 15, 25]);
    });

    test('uses 6 random + Bull when randomReefs is on', () {
      final game = createGame(randomReefs: true);
      expect(game.activeTargets.length, 7);
      expect(game.activeTargets.last, 25); // Bull always last
      // First 6 should be unique numbers 1-20
      final numberTargets = game.activeTargets.sublist(0, 6);
      expect(numberTargets.toSet().length, 6);
      for (final t in numberTargets) {
        expect(t, inInclusiveRange(1, 20));
      }
    });

    test('initializes marks to zero for all targets', () {
      final game = createGame();
      for (final pid in game.playerIds) {
        for (final target in game.activeTargets) {
          expect(game.getPlayerMarks(pid, target), 0);
        }
      }
    });

    test('initializes pearls to zero', () {
      final game = createGame();
      for (final pid in game.playerIds) {
        expect(game.getPlayerPearls(pid), 0);
      }
    });

    test('stores all game options correctly', () {
      final game = createGame(
        gameMode: ReefRoyaleGameMode.cursedTide,
        easyClaim: true,
        neighborNumbers: true,
        speedPlayEnabled: true,
        roundLimit: 15,
      );
      expect(game.gameMode, ReefRoyaleGameMode.cursedTide);
      expect(game.easyClaim, true);
      expect(game.neighborNumbers, true);
      expect(game.speedPlayEnabled, true);
      expect(game.roundLimit, 15);
    });
  });

  // ═══════════════════════════════════════════════════
  // processMiss Tests
  // ═══════════════════════════════════════════════════
  group('processMiss', () {
    test('increments dart count', () {
      final game = createStandardGame();
      game.processMiss('p1');
      expect(game.dartsThrown['p1'], 1);
      expect(game.totalDartsThrown['p1'], 1);
    });

    test('tracks miss in tracking arrays', () {
      final game = createStandardGame();
      game.processMiss('p1');
      expect(game.dartThrowTargetNumber['p1']!.last, isNull);
      expect(game.dartThrowMarksAdded['p1']!.last, 0);
      expect(game.dartThrowPearlsScored['p1']!.last, 0);
    });

    test('does not affect marks or pearls', () {
      final game = createStandardGame();
      game.processMiss('p1');
      expect(game.getPlayerMarks('p1', 20), 0);
      expect(game.getPlayerPearls('p1'), 0);
    });

    test('rejects when max darts thrown', () {
      final game = createStandardGame();
      game.processMiss('p1');
      game.processMiss('p1');
      game.processMiss('p1');
      game.processMiss('p1'); // 4th should be rejected
      expect(game.dartsThrown['p1'], 3);
    });

    test('rejects when wrong player', () {
      final game = createStandardGame();
      game.processMiss('p2'); // p1's turn
      expect(game.dartsThrown['p2'], 0);
    });
  });

  // ═══════════════════════════════════════════════════
  // processDart - Marking Tests
  // ═══════════════════════════════════════════════════
  group('processDart - marking', () {
    test('single adds 1 mark', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 1);
      expect(game.dartThrowMarksAdded['p1']!.last, 1);
    });

    test('double adds 2 marks', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'double',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 2);
      expect(game.dartThrowMarksAdded['p1']!.last, 2);
    });

    test('triple adds 3 marks', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 3);
      expect(game.dartThrowMarksAdded['p1']!.last, 3);
    });

    test('inner bull adds 2 marks', () {
      final game = createStandardGame();
      game.processDart('p1', 50, 'single',
          resolvedTargets: [25]);
      expect(game.getPlayerMarks('p1', 25), 2);
    });

    test('outer bull adds 1 mark', () {
      final game = createStandardGame();
      game.processDart('p1', 25, 'single',
          resolvedTargets: [25]);
      expect(game.getPlayerMarks('p1', 25), 1);
    });

    test('marks accumulate across darts', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 2);
    });
  });

  // ═══════════════════════════════════════════════════
  // processDart - Claiming Tests
  // ═══════════════════════════════════════════════════
  group('processDart - claiming', () {
    test('claims at 3 marks in standard mode', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), false);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), true);
    });

    test('claims at 2 marks in easy claim mode', () {
      final game = createStandardGame(easyClaim: true);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), false);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), true);
    });

    test('triple instantly claims in standard mode', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), true);
      expect(game.dartThrowClaimedCoral['p1']!.last, true);
    });

    test('double instantly claims in easy claim mode', () {
      final game = createStandardGame(easyClaim: true);
      game.processDart('p1', 20, 'double',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), true);
    });

    test('excess marks score pearls on unclaimed opponent', () {
      final game = createStandardGame();
      // p1 has 2 marks on 20, hits triple (3 marks) → total 5, claim at 3, excess 2
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      // Excess 2 marks * 20 (face value) = 40 pearls
      expect(game.hasPlayerClaimed('p1', 20), true);
      expect(game.getPlayerPearls('p1'), 40);
    });

    test('excess marks do not score when all opponents claimed', () {
      final game = createStandardGame();
      // p2 claims 20 first
      game.advanceToNextPlayer(); // switch to p2
      game.processDart('p2', 20, 'triple',
          resolvedTargets: [20]);
      game.advanceToNextPlayer(); // switch to p1
      // p1 has 0 marks, hits triple → total 3, claim at 3, excess 0
      // But even if there were excess, p2 already claimed, so locked
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), true);
      expect(game.isTargetLocked(20), true);
      expect(game.getPlayerPearls('p1'), 0);
    });

    test('locks target when all players claim', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      expect(game.isTargetLocked(20), false);
      game.advanceToNextPlayer();
      game.processDart('p2', 20, 'triple',
          resolvedTargets: [20]);
      expect(game.isTargetLocked(20), true);
      expect(game.dartThrowLockedReef['p2']!.last, true);
    });
  });

  // ═══════════════════════════════════════════════════
  // processDart - Scoring Tests
  // ═══════════════════════════════════════════════════
  group('processDart - scoring', () {
    test('scores pearls when claimed and opponent unclaimed', () {
      final game = createStandardGame();
      // p1 claims 20
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processDart('p1', 19, 'single',
          resolvedTargets: [19]);
      game.processDart('p1', 19, 'single',
          resolvedTargets: [19]);
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      // p1 scores on claimed 20, p2 hasn't claimed it
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 20);
    });

    test('pearl value equals target times multiplier', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      // D20 when claimed = 40 pearls
      game.processDart('p1', 20, 'double',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 40);
    });

    test('inner bull scores 50 pearls when claimed', () {
      final game = createStandardGame();
      // Claim bull: triple doesn't apply to bull, use multiple darts
      game.processDart('p1', 50, 'single',
          resolvedTargets: [25]); // 2 marks
      game.processDart('p1', 25, 'single',
          resolvedTargets: [25]); // 3 marks = claimed
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      // Score with inner bull
      game.processDart('p1', 50, 'single',
          resolvedTargets: [25]);
      expect(game.getPlayerPearls('p1'), 50);
    });

    test('outer bull scores 25 pearls when claimed', () {
      final game = createStandardGame();
      game.processDart('p1', 50, 'single',
          resolvedTargets: [25]); // 2 marks
      game.processDart('p1', 25, 'single',
          resolvedTargets: [25]); // 3 marks = claimed
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      game.processDart('p1', 25, 'single',
          resolvedTargets: [25]);
      expect(game.getPlayerPearls('p1'), 25);
    });

    test('no scoring on locked target', () {
      final game = createStandardGame();
      // Both claim 20
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processDart('p2', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      // 20 is locked, scoring should have no effect
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 0);
    });
  });

  // ═══════════════════════════════════════════════════
  // processDart - Cursed Tide Tests
  // ═══════════════════════════════════════════════════
  group('processDart - Cursed Tide', () {
    test('pearls go to unclaimed opponents', () {
      final game = createStandardGame(
          gameMode: ReefRoyaleGameMode.cursedTide);
      // p1 claims 20
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      // p1 scores on 20 → pearls go to p2 (who hasn't claimed)
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 0);
      expect(game.getPlayerPearls('p2'), 20);
    });

    test('cursed tide ranking uses lowest pearls', () {
      final game = createStandardGame(
          gameMode: ReefRoyaleGameMode.cursedTide);
      game.pearls['p1'] = 100;
      game.pearls['p2'] = 50;
      final ranked = game.getRankedPlayerIds();
      // p2 has fewer pearls → ranked first in cursed tide
      // (assuming same coral count)
      expect(ranked.first, 'p2');
    });

    test('records pearl recipient in tracking', () {
      final game = createStandardGame(
          gameMode: ReefRoyaleGameMode.cursedTide);
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.dartThrowPearlRecipientId['p1']!.last, 'p2');
    });
  });

  // ═══════════════════════════════════════════════════
  // processDart - Neighbor Numbers Tests
  // ═══════════════════════════════════════════════════
  group('processDart - Neighbor Numbers', () {
    test('neighbor hit adds 1 mark', () {
      final game = createStandardGame(neighborNumbers: true);
      // Hit 1, which is neighbor of 20
      game.processDart('p1', 1, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 1);
    });

    test('neighbor hit respects multiplier (double=2, triple=3)', () {
      final game = createStandardGame(neighborNumbers: true);
      // D1 (double 1, neighbor of 20) gives 2 marks
      game.processDart('p1', 1, 'double',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 2);

      // T1 (triple 1, neighbor of 18) gives 3 marks
      game.processDart('p1', 1, 'triple',
          resolvedTargets: [18]);
      expect(game.getPlayerMarks('p1', 18), 3);
    });

    test('neighbor hit records isNeighbor in tracking', () {
      final game = createStandardGame(neighborNumbers: true);
      game.processDart('p1', 5, 'single',
          resolvedTargets: [20]);
      expect(game.dartThrowIsNeighbor['p1']!.last, true);
      expect(game.dartThrowTargetNumber['p1']!.last, 20);
    });

    test('resolveTarget finds neighbor targets', () {
      final game = createStandardGame(neighborNumbers: true);
      expect(game.resolveTarget(1), 20); // neighbor of 20
      expect(game.resolveTarget(5), 20); // neighbor of 20
      expect(game.resolveTarget(3), 19); // neighbor of 19
      expect(game.resolveTarget(7), 19); // neighbor of 19
    });

    test('resolveTarget returns null for non-neighbor non-target', () {
      final game = createStandardGame(neighborNumbers: true);
      // 9 is not a neighbor of any standard target
      expect(game.resolveTarget(9), isNull);
    });

    test('resolveTarget without neighbor mode rejects non-targets', () {
      final game = createStandardGame(neighborNumbers: false);
      expect(game.resolveTarget(1), isNull);
      expect(game.resolveTarget(5), isNull);
    });

    test('resolveAllTargets returns multiple targets for shared neighbors', () {
      final game = createStandardGame(neighborNumbers: true);
      // 1 is neighbor of both 20 and 18
      final targets1 = game.resolveAllTargets(1);
      expect(targets1, containsAll([20, 18]));
      expect(targets1, hasLength(2));
      // 3 is neighbor of both 19 and 17
      final targets3 = game.resolveAllTargets(3);
      expect(targets3, containsAll([19, 17]));
      expect(targets3, hasLength(2));
    });

    test('resolveAllTargets returns single target for direct hits', () {
      final game = createStandardGame(neighborNumbers: true);
      expect(game.resolveAllTargets(20), [20]);
      expect(game.resolveAllTargets(19), [19]);
    });

    test('target number is never treated as a neighbor of another target', () {
      // With random reefs, adjacent targets could exist (e.g. 1 and 18 are
      // physically adjacent on the dartboard). Hitting 1 should only count
      // as a direct hit on 1, never as a neighbor of 18.
      final game = ReefRoyaleGame(
        id: 'test',
        startedAt: DateTime.now(),
        maxDartsPerTurn: 3,
        gameMode: ReefRoyaleGameMode.standard,
        easyClaim: false,
        neighborNumbers: true,
        randomReefs: true,
        bonusBuffsEnabled: false,
        showHints: false,
        speedPlayEnabled: false,
        roundLimit: 10,
        playerIds: ['p1', 'p2'],
        creatureAssignments: {},
        activeTargets: [1, 18, 20, 4, 13, 6, 25], // 1 and 18 are adjacent, 18 and 20 are near-adjacent via 1
        coralOrder: ['brain', 'fan', 'fire', 'mushroom', 'staghorn', 'table', 'bubble'],
        state: ReefRoyaleGameState.playing,
      );

      // Hit 1 — it IS a target, so only direct hit on 1
      final result1 = game.resolveAllTargets(1);
      expect(result1, [1]);
      expect(result1.contains(18), isFalse); // NOT also a neighbor of 18
      expect(result1.contains(20), isFalse); // NOT also a neighbor of 20

      // Hit 18 — it IS a target, so only direct hit on 18
      final result18 = game.resolveAllTargets(18);
      expect(result18, [18]);
      expect(result18.contains(1), isFalse);

      // Hit 20 — it IS a target, so only direct hit on 20
      final result20 = game.resolveAllTargets(20);
      expect(result20, [20]);
    });

    test('resolveAllTargets returns empty for non-targets', () {
      final game = createStandardGame(neighborNumbers: true);
      expect(game.resolveAllTargets(9), isEmpty);
    });

    test('shared neighbor hit adds 1 mark to each target', () {
      final game = createStandardGame(neighborNumbers: true);
      // Hit 1, which is neighbor of both 20 and 18
      final targets = game.resolveAllTargets(1);
      for (final target in targets) {
        game.processDart('p1', 1, 'single',
            resolvedTargets: [target]);
      }
      expect(game.getPlayerMarks('p1', 20), 1);
      expect(game.getPlayerMarks('p1', 18), 1);
    });

    test('shared neighbor hit does not affect unrelated targets', () {
      final game = createStandardGame(neighborNumbers: true);
      // Hit 1 (neighbor of 20 and 18), should not affect 19, 17, 16, 15
      final targets = game.resolveAllTargets(1);
      for (final target in targets) {
        game.processDart('p1', 1, 'single',
            resolvedTargets: [target]);
      }
      expect(game.getPlayerMarks('p1', 19), 0);
      expect(game.getPlayerMarks('p1', 17), 0);
      expect(game.getPlayerMarks('p1', 16), 0);
      expect(game.getPlayerMarks('p1', 15), 0);
    });

    test('dartThrowTargetCount tracks multi-target shared neighbor hits', () {
      final provider = ReefRoyaleProvider();
      final players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          true, false, false, true, false, 10); // neighborNumbers: true
      // Hit 1 — shared neighbor of 20 and 18
      provider.processDartThrow('S1');
      final targetCount = provider.getDartThrowTargetCount('p1');
      expect(targetCount.length, 1);
      expect(targetCount[0], 2); // Hit 2 targets
    });

    test('dartThrowTargetCount is 1 for single target hits', () {
      final provider = ReefRoyaleProvider();
      final players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      final targetCount = provider.getDartThrowTargetCount('p1');
      expect(targetCount.length, 1);
      expect(targetCount[0], 1); // Hit 1 target
    });

    test('dartThrowTargetCount is 0 for misses', () {
      final provider = ReefRoyaleProvider();
      final players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('None');
      final targetCount = provider.getDartThrowTargetCount('p1');
      expect(targetCount.length, 1);
      expect(targetCount[0], 0); // Miss = 0 targets
    });
  });

  // ═══════════════════════════════════════════════════
  // Bonus Buff Tests
  // ═══════════════════════════════════════════════════
  group('Bonus Buffs', () {
    test('Riptide Rush doubles marks', () {
      final game = createStandardGame();
      game.activeBuff = ReefBuff.riptideRush;
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 2); // 1 * 2
    });

    test('Pearl Fever doubles pearl scoring', () {
      final game = createStandardGame();
      // Claim 20 for p1
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      // Activate Pearl Fever
      game.activeBuff = ReefBuff.pearlFever;
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 40); // 20 * 2
    });

    test('Ink Cloud has no logic effect on marks or pearls', () {
      final game = createStandardGame();
      game.activeBuff = ReefBuff.inkCloud;
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 1); // Unchanged
    });

    test('Riptide Rush doubles marks on neighbor hits', () {
      final game = createStandardGame(neighborNumbers: true);
      game.activeBuff = ReefBuff.riptideRush;
      game.processDart('p1', 1, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 2); // 1 * 2
    });

    test('buff only lasts one round (cleared on advance)', () {
      final game = createStandardGame(bonusBuffsEnabled: true);
      game.activeBuff = ReefBuff.riptideRush;
      // Complete p1 turn
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      // Complete p2 turn → new round triggers buff re-roll
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      // After advancing, buff may be replaced or cleared by random selection
      // The key invariant: the old buff doesn't persist across rounds
      // With bonusBuffs enabled, advanceToNextPlayer will call _shouldTriggerBuff
      game.advanceToNextPlayer();
      // We can't test exact buff value due to randomness, but we verify
      // the mechanism runs (buff is either null or a different/same random buff)
      // The important thing is the previous manual assignment doesn't persist
      // if the system re-rolls at round boundary
      expect(game.currentRound, 2);
    });

    test('only one buff at a time (replacement)', () {
      final game = createStandardGame();
      game.activeBuff = ReefBuff.riptideRush;
      expect(game.activeBuff, ReefBuff.riptideRush);
      // Setting a new buff replaces the old one
      game.activeBuff = ReefBuff.pearlFever;
      expect(game.activeBuff, ReefBuff.pearlFever);
      // Only one buff active
      expect(game.activeBuff, isNot(ReefBuff.riptideRush));
    });
  });

  // ═══════════════════════════════════════════════════
  // Win Condition Tests
  // ═══════════════════════════════════════════════════
  group('Win conditions', () {
    test('wins when all 7 claimed and pearl lead', () {
      final game = createStandardGame();
      // p1 claims all 7 targets
      for (final target in game.activeTargets) {
        game.claimed['p1']!.add(target);
      }
      game.pearls['p1'] = 100;
      game.pearls['p2'] = 50;
      // Trigger win check by processing a dart
      // Actually, we need to trigger _checkWinCondition
      // Let's just call it via processDart on a claimed target
      // Reset dart count first
      game.dartsThrown['p1'] = 0;
      // The win condition is only checked in _processMarking when claiming
      // So let's test it directly by unclaiming one target and reclaiming
      game.claimed['p1']!.remove(20);
      game.marks['p1']![20] = 2;
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.state, ReefRoyaleGameState.finished);
      expect(game.winnerId, 'p1');
    });

    test('does not win with all 7 claimed but behind in pearls', () {
      final game = createStandardGame();
      // p1 claims all 7 targets but p2 has more pearls
      for (final target in game.activeTargets) {
        game.claimed['p1']!.add(target);
      }
      game.pearls['p1'] = 50;
      game.pearls['p2'] = 100;
      game.claimed['p1']!.remove(20);
      game.marks['p1']![20] = 2;
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      // Game should NOT be finished since p1 is behind in pearls
      expect(game.state, ReefRoyaleGameState.playing);
    });

    test('game ends when all targets locked', () {
      final game = createStandardGame();
      // Both players claim all targets
      for (final target in game.activeTargets) {
        game.claimed['p1']!.add(target);
        game.claimed['p2']!.add(target);
        game.locked.add(target);
      }
      // Remove one lock to trigger via processDart
      game.locked.remove(20);
      game.claimed['p2']!.remove(20);
      game.marks['p2']![20] = 2;
      game.dartsThrown['p1'] = 0;
      // Switch to p2's turn
      game.currentPlayerIndex = 1;
      game.processDart('p2', 20, 'single',
          resolvedTargets: [20]);
      expect(game.state, ReefRoyaleGameState.finished);
    });

    test('speed play ends at round limit', () {
      final game =
          createStandardGame(speedPlayEnabled: true, roundLimit: 2);
      // Simulate 2 rounds
      game.currentRound = 2;
      game.turnsCompletedThisRound = 1;
      // Advancing should end the game at round limit without incrementing past it
      game.advanceToNextPlayer();
      expect(game.currentRound, 2); // Stays at limit, doesn't exceed
      expect(game.state, ReefRoyaleGameState.finished);
    });

    test('ranking uses corals then pearls (standard)', () {
      final game = createStandardGame();
      game.claimed['p1']!.addAll([20, 19, 18]);
      game.claimed['p2']!.addAll([20, 19]);
      game.pearls['p1'] = 30;
      game.pearls['p2'] = 100;
      final ranked = game.getRankedPlayerIds();
      expect(ranked.first, 'p1'); // More corals
    });

    test('ranking tiebreaker uses pearls when corals equal', () {
      final game = createStandardGame();
      game.claimed['p1']!.addAll([20, 19]);
      game.claimed['p2']!.addAll([20, 19]);
      game.pearls['p1'] = 30;
      game.pearls['p2'] = 100;
      final ranked = game.getRankedPlayerIds();
      expect(ranked.first, 'p2'); // More pearls
    });

    test('cursed tide tiebreaker uses lowest pearls', () {
      final game = createStandardGame(
          gameMode: ReefRoyaleGameMode.cursedTide);
      game.claimed['p1']!.addAll([20, 19]);
      game.claimed['p2']!.addAll([20, 19]);
      game.pearls['p1'] = 30;
      game.pearls['p2'] = 100;
      final ranked = game.getRankedPlayerIds();
      expect(ranked.first, 'p1'); // Fewer pearls wins in cursed tide
    });
  });

  // ═══════════════════════════════════════════════════
  // Turn Management Tests
  // ═══════════════════════════════════════════════════
  group('Turn management', () {
    test('advanceToNextPlayer cycles through players', () {
      final game = createStandardGame();
      expect(game.getCurrentPlayerId(), 'p1');
      game.advanceToNextPlayer();
      expect(game.getCurrentPlayerId(), 'p2');
      game.advanceToNextPlayer();
      expect(game.getCurrentPlayerId(), 'p1');
    });

    test('round advances after all players take turns', () {
      final game = createStandardGame();
      expect(game.currentRound, 1);
      game.advanceToNextPlayer(); // p1 → p2, turns completed = 1
      game.advanceToNextPlayer(); // p2 → p1, round 2
      expect(game.currentRound, 2);
    });

    test('dart tracking resets on advance', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      game.advanceToNextPlayer();
      expect(game.dartsThrown['p1'], 0);
      expect(game.dartThrowMarksAdded['p1'], isEmpty);
    });

    test('totalTurns increments on first dart only', () {
      final game = createStandardGame();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.totalTurns['p1'], 1);
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.totalTurns['p1'], 1); // Still 1
    });
  });

  // ═══════════════════════════════════════════════════
  // Edit Score Tests
  // ═══════════════════════════════════════════════════
  group('Edit score', () {
    test('resetToStartOfTurn restores marks', () {
      final game = createStandardGame();
      game.saveInitialTurnStartState();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerMarks('p1', 20), 1);
      game.resetToStartOfTurn('p1');
      expect(game.getPlayerMarks('p1', 20), 0);
    });

    test('resetToStartOfTurn restores pearls', () {
      final game = createStandardGame();
      game.claimed['p1']!.add(20);
      game.saveInitialTurnStartState();
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 20);
      game.resetToStartOfTurn('p1');
      expect(game.getPlayerPearls('p1'), 0);
    });

    test('resetToStartOfTurn restores claimed and locked', () {
      final game = createStandardGame();
      game.saveInitialTurnStartState();
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      expect(game.hasPlayerClaimed('p1', 20), true);
      game.resetToStartOfTurn('p1');
      expect(game.hasPlayerClaimed('p1', 20), false);
    });
  });

  // ═══════════════════════════════════════════════════
  // Target Resolution Tests
  // ═══════════════════════════════════════════════════
  group('Target resolution', () {
    test('resolves direct target hit', () {
      final game = createStandardGame();
      expect(game.resolveTarget(20), 20);
      expect(game.resolveTarget(15), 15);
    });

    test('resolves bull correctly', () {
      final game = createStandardGame();
      expect(game.resolveTarget(50), 25); // Inner bull → Bull target
      expect(game.resolveTarget(25), 25); // Outer bull → Bull target
    });

    test('returns null for non-target without neighbors', () {
      final game = createStandardGame();
      expect(game.resolveTarget(1), isNull);
      expect(game.resolveTarget(14), isNull);
    });
  });

  // ═══════════════════════════════════════════════════
  // Display Helper Tests
  // ═══════════════════════════════════════════════════
  group('Display helpers', () {
    test('getCreatureFileName returns correct filenames', () {
      expect(ReefRoyaleGame.getCreatureFileName(SeaCreature.coralClownfish),
          'CoralClownfish');
      expect(ReefRoyaleGame.getCreatureFileName(SeaCreature.finnDolphin),
          'FinnDolphin');
    });

    test('getCreatureDisplayName returns correct names', () {
      expect(
          ReefRoyaleGame.getCreatureDisplayName(SeaCreature.coralClownfish),
          'Coral the Clownfish');
      expect(
          ReefRoyaleGame.getCreatureDisplayName(SeaCreature.captainCrab),
          'Captain Crab');
    });

    test('getCoralName returns correct names for standard targets', () {
      expect(ReefRoyaleGame.getCoralName(20), 'Fire Coral');
      expect(ReefRoyaleGame.getCoralName(25), 'Pearl Oyster');
      expect(ReefRoyaleGame.getCoralName(15), 'Tube Coral');
    });

    test('getTargetDisplayName returns correct display', () {
      final game = createStandardGame();
      expect(game.getTargetDisplayName(20), '20');
      expect(game.getTargetDisplayName(25), 'Bull');
    });

    test('getBuffDisplayName returns correct names', () {
      expect(ReefRoyaleGame.getBuffDisplayName(ReefBuff.riptideRush),
          'Riptide Rush');
      expect(ReefRoyaleGame.getBuffDisplayName(ReefBuff.pearlFever),
          'Pearl Fever');
      expect(ReefRoyaleGame.getBuffDisplayName(ReefBuff.inkCloud),
          'Ink Cloud');
    });

    test('getBuffDescription returns correct descriptions', () {
      expect(ReefRoyaleGame.getBuffDescription(ReefBuff.riptideRush),
          'Double marks this round!');
      expect(ReefRoyaleGame.getBuffDescription(ReefBuff.pearlFever),
          'Double pearls this round!');
      expect(ReefRoyaleGame.getBuffDescription(ReefBuff.inkCloud),
          'All opponent info is hidden this round!');
    });

    test('getCoralImagePath returns correct paths', () {
      final game = createStandardGame();
      expect(game.getCoralImagePath(20, false),
          'assets/games/reef_royale/corals/FireCoral-Unclaimed.png');
      expect(game.getCoralImagePath(20, true),
          'assets/games/reef_royale/corals/FireCoral-Claimed.png');
    });

    test('getCoralDisplayName returns human readable names', () {
      final game = createStandardGame();
      expect(game.getCoralDisplayName(20), 'Fire Coral');
      expect(game.getCoralDisplayName(25), 'Pearl Oyster');
    });

    test('getCreatureImagePath returns correct path', () {
      final game = createStandardGame();
      final path = game.getCreatureImagePath('p1');
      expect(path, startsWith('assets/games/reef_royale/characters/'));
      expect(path, endsWith('.png'));
    });
  });

  // ═══════════════════════════════════════════════════
  // Provider Tests
  // ═══════════════════════════════════════════════════
  group('ReefRoyaleProvider', () {
    late ReefRoyaleProvider provider;
    late List<Player> players;

    setUp(() {
      provider = ReefRoyaleProvider();
      players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
    });

    test('starts game successfully', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      expect(provider.currentGame, isNotNull);
      expect(provider.isGameActive, true);
    });

    test('rejects fewer than 2 players', () {
      provider.startGame([players[0]], ReefRoyaleGameMode.standard,
          false, false, false, false, true, false, 10);
      expect(provider.currentGame, isNull);
    });

    test('processDartThrow handles valid target', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      expect(provider.getPlayerMarks('p1', 20), 1);
    });

    test('processDartThrow handles miss', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('None');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('processDartThrow handles bull', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('Bull');
      expect(provider.getPlayerMarks('p1', 25), 2); // Inner bull = 2 marks
    });

    test('processDartThrow handles outer bull', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('25');
      expect(provider.getPlayerMarks('p1', 25), 1);
    });

    test('processDartThrow sets waitingForTakeout after 3 darts', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      expect(provider.shouldPromptTakeout, true);
    });

    test('handleTakeoutFinished advances player', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      provider.handleTakeoutFinished();
      expect(provider.getCurrentPlayerId(), 'p2');
      expect(provider.shouldPromptTakeout, false);
    });

    test('skipTurn fills remaining darts and prompts takeout', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      provider.skipTurn();
      expect(provider.shouldPromptTakeout, true);
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3); // 1 real + 2 skip
      expect(darts[1], 'Skip');
      expect(darts[2], 'Skip');
    });

    test('non-target number is treated as miss', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S1'); // 1 is not a standard target
      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getPlayerMarks('p1', 20), 0); // No marks added
      // Non-target displays the sector info
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts[0], 'S1');
    });

    test('complete miss (None) displays as Miss in dart label', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('None');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts[0], 'Miss');
    });

    test('empty sector displays as Miss in dart label', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts[0], 'Miss');
    });

    test('updateAllDartScores replays with new sectors', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      provider.processDartThrow('S20');
      provider.processDartThrow('S20');
      // p1 should have 3 marks on 20 = claimed
      expect(provider.hasPlayerClaimed('p1', 20), true);
      // Edit to all misses
      provider.updateAllDartScores('p1', ['Miss', 'Miss', 'Miss']);
      expect(provider.hasPlayerClaimed('p1', 20), false);
      expect(provider.getPlayerMarks('p1', 20), 0);
    });

    test('clearGame resets state', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.clearGame();
      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
    });

    test('processDartThrow ignores when waiting for takeout', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      provider.processDartThrow('S20');
      provider.processDartThrow('S20');
      // Now waiting for takeout
      provider.processDartThrow('S19'); // Should be ignored
      expect(provider.getPlayerMarks('p1', 19), 0);
    });

    test('setActiveBuff sets buff via provider', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.setActiveBuff(ReefBuff.riptideRush);
      expect(provider.getActiveBuff(), ReefBuff.riptideRush);
      provider.setActiveBuff(null);
      expect(provider.getActiveBuff(), isNull);
    });

    test('getGameMode returns current game mode', () {
      provider.startGame(players, ReefRoyaleGameMode.cursedTide, false,
          false, false, false, true, false, 10);
      expect(provider.getGameMode(), ReefRoyaleGameMode.cursedTide);
    });

    test('getRankedPlayerIds returns sorted list', () {
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      final ranked = provider.getRankedPlayerIds();
      expect(ranked.length, 2);
    });
  });

  // ═══════════════════════════════════════════════════
  // Random Reefs Tests
  // ═══════════════════════════════════════════════════
  group('Random Reefs', () {
    test('random targets change each new game (statistical check)', () {
      // Create multiple random reef games and check targets differ
      bool foundDifferent = false;
      List<int>? firstTargets;
      for (int attempt = 0; attempt < 10; attempt++) {
        final game = createGame(randomReefs: true);
        final targets = game.activeTargets.sublist(0, 6);
        firstTargets ??= targets;
        if (!_listEquals(targets, firstTargets)) {
          foundDifferent = true;
          break;
        }
      }
      // With 6 random picks from 20, extremely unlikely to get same 10 times
      expect(foundDifferent, isTrue,
          reason: 'Random reefs should produce different targets across games');
    });
  });

  // ═══════════════════════════════════════════════════
  // Multi-player Scoring Tests
  // ═══════════════════════════════════════════════════
  group('Multi-player scoring', () {
    test('standard mode: only claiming player gets pearls', () {
      final game = createStandardGame(playerIds: ['p1', 'p2', 'p3']);
      // p1 claims target 20
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      game.processMiss('p3');
      game.processMiss('p3');
      game.processMiss('p3');
      game.advanceToNextPlayer();
      // p1 scores on claimed 20
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 20);
      expect(game.getPlayerPearls('p2'), 0);
      expect(game.getPlayerPearls('p3'), 0);
    });

    test('cursed tide: pearls distributed to ALL unclaimed opponents', () {
      final game = createStandardGame(
        playerIds: ['p1', 'p2', 'p3'],
        gameMode: ReefRoyaleGameMode.cursedTide,
      );
      // p1 claims target 20
      game.processDart('p1', 20, 'triple',
          resolvedTargets: [20]);
      game.processMiss('p1');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      game.processMiss('p2');
      game.processMiss('p2');
      game.processMiss('p2');
      game.advanceToNextPlayer();
      game.processMiss('p3');
      game.processMiss('p3');
      game.processMiss('p3');
      game.advanceToNextPlayer();
      // p1 scores on claimed 20 → pearls go to both p2 and p3
      game.processDart('p1', 20, 'single',
          resolvedTargets: [20]);
      expect(game.getPlayerPearls('p1'), 0);
      // Both opponents get pearls
      expect(game.getPlayerPearls('p2'), 20);
      expect(game.getPlayerPearls('p3'), 20);
    });
  });

  // ═══════════════════════════════════════════════════
  // Skip Turn Edge Cases
  // ═══════════════════════════════════════════════════
  group('Skip turn edge cases', () {
    test('skip turn with 0 darts thrown fills all 3 as Skip', () {
      final provider = ReefRoyaleProvider();
      final players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      // Skip with no darts thrown
      provider.skipTurn();
      expect(provider.shouldPromptTakeout, true);
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3);
      expect(darts[0], 'Skip');
      expect(darts[1], 'Skip');
      expect(darts[2], 'Skip');
    });

    test('skip turn after 1 dart shows Skip for remaining 2 darts', () {
      final provider = ReefRoyaleProvider();
      final players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
      provider.skipTurn();
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3);
      expect(darts[0], 'S20');
      expect(darts[1], 'Skip');
      expect(darts[2], 'Skip');
      // dartsThrown only counts actual throws, not skips
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('skip turn after 2 darts shows Skip for remaining 1 dart', () {
      final provider = ReefRoyaleProvider();
      final players = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      ];
      provider.startGame(players, ReefRoyaleGameMode.standard, false,
          false, false, false, true, false, 10);
      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      expect(provider.getCurrentPlayerDartsThrown(), 2);
      provider.skipTurn();
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3);
      expect(darts[0], 'S20');
      expect(darts[1], 'S19');
      expect(darts[2], 'Skip');
      // dartsThrown only counts actual throws, not skips
      expect(provider.getCurrentPlayerDartsThrown(), 2);
    });
  });
}

/// Helper to compare two int lists for equality
bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
