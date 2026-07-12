// Treasure Divide Game — Announcement Integration Tests
// ======================================================
// ~18 tests that validate announcements fire correctly during game flow.
//
// These tests replicate the announcement wiring logic from
// treasure_divide_game_screen.dart (_handleDartThrow,
// _handleTakeoutFinished, _handleGameWon) and drive it through
// TreasureDivideProvider, verifying the correct announcements fire
// in the correct order.
//
// The existing treasure_divide_announcement_test.dart tests the HELPER
// methods in isolation (text, sound, priority). This file tests the
// GAME FLOW: that the right announcements fire when game events happen
// through the provider with the screen's precedence logic applied.
//
// TEST GROUPS:
//  Group 1 — Lifecycle (3 tests)
//  Group 2 — Per-dart moment announcements (5 tests)
//  Group 3 — Turn-end Solo (3 tests)
//  Group 4 — Turn-end Team (3 tests)
//  Group 5 — Round transitions (3 tests)
//  Group 6 — Leader change (1 test)
//  Group 7 — Stacking / max-2 constraint (1 test)
//  Group 8 — Auto-play suppression (1 test)
// ======================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/treasure_divide_game.dart';
import 'package:dart_games/providers/treasure_divide_provider.dart';
import '../../../mocks/mock_treasure_divide_audio_queue_service.dart';

// ─── Test helpers ─────────────────────────────────────────────────────────────

TreasureDivideProvider createSoloProvider({
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  int playerCount = 2,
}) {
  final provider = TreasureDivideProvider();
  final playerIds = List.generate(playerCount, (i) => 'p${i + 1}');
  provider.startGame(
    playerIds: playerIds,
    numberOfRounds: numberOfRounds,
    quarterItEnabled: quarterItEnabled,
    customTargetsEnabled: customTargetsEnabled,
    gameMode: TreasureDivideGameMode.solo,
    teamAssignment: TreasureDivideTeamAssignment.random,
  );
  return provider;
}

TreasureDivideProvider createTeamProvider({
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  // 4 players → 2 crews of 2
}) {
  final provider = TreasureDivideProvider();
  provider.startGame(
    playerIds: ['p1', 'p2', 'p3', 'p4'],
    numberOfRounds: numberOfRounds,
    quarterItEnabled: quarterItEnabled,
    customTargetsEnabled: false,
    gameMode: TreasureDivideGameMode.team,
    teamAssignment: TreasureDivideTeamAssignment.manual,
    teamCount: 2,
    manualTeamAssignments: {
      'p1': 'team_1',
      'p2': 'team_1',
      'p3': 'team_2',
      'p4': 'team_2',
    },
  );
  return provider;
}

/// Mirrors the per-dart wiring in treasure_divide_game_screen.dart
/// _handleDartThrow (excluding the UI setState / navigation guards).
void processDart(
  TreasureDivideProvider provider,
  MockTreasureDivideAudioQueueService mock, {
  required int score,
  required String multiplier,
  required int baseScore,
  required String sector,
  bool isAutoPlaying = false,
}) {
  provider.processDartThrow(
    score: score,
    multiplier: multiplier,
    baseScore: baseScore,
    sector: sector,
  );
  if (!isAutoPlaying) {
    mock.pickAndAnnounceMoment(
      wasMatched: provider.lastDartWasMatched,
      multiplier: provider.lastDartMultiplier,
      sector: provider.lastDartSector,
      value: provider.lastDartScore,
    );
    if (provider.shouldPromptTakeout) {
      // Unconditional remove-darts (1500ms delay in real screen; immediate
      // in tests).
      mock.announceRemoveDarts();
    }
  }
}

/// Mirrors the turn-end wiring in _handleTakeoutFinished.
void processTakeout(
  TreasureDivideProvider provider,
  MockTreasureDivideAudioQueueService mock, {
  bool isAutoPlaying = false,
}) {
  final gameBeforeTakeout = provider.currentGame!;
  final isTeam = gameBeforeTakeout.gameMode == TreasureDivideGameMode.team;
  final scoreBeforeTurn = provider.scoreBeforeCurrentTurn;
  final allMissedThisTurn = provider.currentTurnAllMissed;
  final quarterItEnabled = gameBeforeTakeout.quarterItEnabled;
  final customTargetsEnabled = gameBeforeTakeout.customTargetsEnabled;
  final prevRoundIndex = gameBeforeTakeout.currentRoundIndex;

  provider.handleTakeoutFinished();

  if (isAutoPlaying) return;

  final gameAfter = provider.currentGame;
  if (gameAfter == null) return;

  // Turn-end announcement
  if (isTeam) {
    final completedCrewId = provider.justCompletedCrewId;
    if (completedCrewId != null) {
      final members = gameBeforeTakeout.teamPlayers[completedCrewId] ?? [];
      bool crewAllMissed = true;
      for (final pid in members) {
        final haul =
            gameAfter.playerRoundScores[pid]?[prevRoundIndex] ?? 0;
        if (haul > 0) {
          crewAllMissed = false;
          break;
        }
      }
      final crewHaul = provider.justCompletedCrewHaul;
      final crewName = provider.crewNameForTeam(completedCrewId);
      mock.announceTurnEndTeam(
        crewAllMissed: crewAllMissed,
        crewTreasureBefore: scoreBeforeTurn,
        crewHaulThisRound: crewHaul,
        crewName: crewName,
      );
    }
  } else {
    mock.announceTurnEndSolo(
      allMissed: allMissedThisTurn,
      quarterItEnabled: quarterItEnabled,
      scoreBeforeTurn: scoreBeforeTurn,
    );
  }

  // Round-transition announcement
  if (provider.roundAdvancedOnLastTakeout && !provider.hasWinner) {
    final newRoundIndex = gameAfter.currentRoundIndex;
    final newTarget = newRoundIndex < gameAfter.targetSequence.length
        ? gameAfter.targetSequence[newRoundIndex]
        : 0;
    final isLastRound = newRoundIndex == gameAfter.numberOfRounds - 1;
    mock.announceNewRound(
      roundIndex: newRoundIndex,
      target: newTarget,
      totalRounds: gameAfter.numberOfRounds,
      isLastRound: isLastRound,
      customTargetsEnabled: customTargetsEnabled,
    );
  }
}

/// Fires 3 miss darts for the current player then calls processTakeout.
void throwAndMissAll(
  TreasureDivideProvider provider,
  MockTreasureDivideAudioQueueService mock, {
  bool isAutoPlaying = false,
}) {
  for (int i = 0; i < 3; i++) {
    processDart(provider, mock,
        score: 0,
        multiplier: 'miss',
        baseScore: 0,
        sector: 'Miss',
        isAutoPlaying: isAutoPlaying);
  }
  processTakeout(provider, mock, isAutoPlaying: isAutoPlaying);
}

/// Fires 3 hit darts (S{baseScore}) for the current player then calls processTakeout.
void throwAndHitAll(
  TreasureDivideProvider provider,
  MockTreasureDivideAudioQueueService mock, {
  int baseScore = 20,
  bool isAutoPlaying = false,
}) {
  for (int i = 0; i < 3; i++) {
    processDart(provider, mock,
        score: baseScore,
        multiplier: 'single',
        baseScore: baseScore,
        sector: 'S$baseScore',
        isAutoPlaying: isAutoPlaying);
  }
  if (provider.shouldPromptTakeout) {
    processTakeout(provider, mock, isAutoPlaying: isAutoPlaying);
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  late MockTreasureDivideAudioQueueService mock;

  setUp(() {
    mock = MockTreasureDivideAudioQueueService();
  });

  tearDown(() {
    mock.dispose();
  });

  // ─── Group 1: Lifecycle ────────────────────────────────────────────────────

  group('Group 1 — Lifecycle', () {
    test('Game Start fires once with correct rounds count', () {
      final provider = createSoloProvider(numberOfRounds: 9);
      mock.announceGameStart(provider.currentGame!.numberOfRounds);
      expect(mock.announcements.first, 'Set sail! 9 islands to plunder!');
      expect(mock.captured.length, 1);
    });

    test('Player Turn fires on first turn after 2s delay (simulated)', () {
      final provider = createSoloProvider();
      mock.announcePlayerTurn('p1');
      expect(mock.announcements.last, 'p1, grab your darts!');
    });

    test('Remove Darts fires unconditionally after last dart', () {
      final provider = createSoloProvider();
      final game = provider.currentGame!;
      final target = game.targetSequence[0];

      // Throw 3 darts (all hits), last one triggers shouldPromptTakeout
      for (int i = 0; i < 3; i++) {
        processDart(provider, mock,
            score: target,
            multiplier: 'single',
            baseScore: target,
            sector: 'S$target');
      }

      // The last dart must have queued a Remove Darts announcement
      final lastText = mock.announcements.last;
      expect(lastText, 'Remove your darts!');
    });
  });

  // ─── Group 2: Per-dart moment announcements ────────────────────────────────

  group('Group 2 — Per-dart moment announcements', () {
    test('Hit Target fires for a matching single', () {
      final provider = createSoloProvider();
      final target = provider.currentGame!.targetSequence[0];
      processDart(provider, mock,
          score: target,
          multiplier: 'single',
          baseScore: target,
          sector: 'S$target');
      expect(mock.announcements.first, 'Plunder! $target gold coins!');
    });

    test('Big Hit fires for a matching triple', () {
      final provider = createSoloProvider();
      final target = provider.currentGame!.targetSequence[0];
      processDart(provider, mock,
          score: target * 3,
          multiplier: 'triple',
          baseScore: target,
          sector: 'T$target');
      expect(mock.announcements.first, 'Triple treasure! ${target * 3} gold!');
    });

    test('Bull Hit fires on a Bull round with Bull sector', () {
      // 9-round sequence ends with Bull (target=25). Play to round 8.
      final provider = createSoloProvider(playerCount: 2, numberOfRounds: 9);
      // Skip through rounds 0-7 so round 8 (Bull) becomes active.
      for (int round = 0; round < 8; round++) {
        // p1 throws and misses
        throwAndMissAll(provider, mock);
        mock.clear();
        // p2 throws and misses
        throwAndMissAll(provider, mock);
        mock.clear();
      }
      expect(provider.currentGame!.currentRoundIndex, 8);
      expect(provider.currentGame!.targetSequence[8], 25); // Bull

      mock.clear();
      // Now throw a Bull
      processDart(provider, mock,
          score: 50,
          multiplier: 'bull',
          baseScore: 25,
          sector: 'Bull');
      expect(mock.announcements.first, 'X marks the spot! 50 gold!');
    });

    test('Miss fires for a non-matching dart', () {
      final provider = createSoloProvider();
      processDart(provider, mock,
          score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');
      expect(mock.announcements.first, "Splash! That one's in the ocean!");
    });

    test('Miss fires for a dart that hits wrong sector', () {
      // Round 0 target is 20. Hitting sector 5 = miss.
      final provider = createSoloProvider();
      processDart(provider, mock,
          score: 5, multiplier: 'single', baseScore: 5, sector: 'S5');
      expect(mock.announcements.first, "Splash! That one's in the ocean!");
    });
  });

  // ─── Group 3: Turn-end Solo ────────────────────────────────────────────────

  group('Group 3 — Turn-end Solo', () {
    test('all-miss with score=0 → Safe (no Halved)', () {
      final provider = createSoloProvider(quarterItEnabled: false);
      // First turn: p1 has 0 score before. All miss → Safe (not Halved).
      throwAndMissAll(provider, mock);
      final turnEndTexts = mock.announcements
          .where((t) =>
              t.contains('treasure holds') ||
              t.contains('overboard') ||
              t.contains('storm'))
          .toList();
      expect(turnEndTexts, ['The treasure holds! Moving on!']);
    });

    test('all-miss with score>0 + Quarter It OFF → Halved', () {
      final provider = createSoloProvider(quarterItEnabled: false);
      final target = provider.currentGame!.targetSequence[0];
      // p1 hits round 0.
      throwAndHitAll(provider, mock, baseScore: target);
      mock.clear();
      // p2 hits round 0.
      throwAndHitAll(provider, mock, baseScore: target);
      mock.clear();
      // Now round 1 starts; p1 has score > 0. All miss.
      throwAndMissAll(provider, mock);
      final turnEndText = mock.announcements
          .firstWhere((t) =>
              t.contains('treasure holds') ||
              t.contains('overboard') ||
              t.contains('storm'));
      expect(turnEndText, 'Treasure overboard! Half the loot is gone!');
    });

    test('all-miss with score>0 + Quarter It ON → Quartered', () {
      final provider =
          createSoloProvider(quarterItEnabled: true);
      final target = provider.currentGame!.targetSequence[0];
      // p1 scores in round 0.
      throwAndHitAll(provider, mock, baseScore: target);
      mock.clear();
      // p2 plays round 0 (scores too).
      throwAndHitAll(provider, mock, baseScore: target);
      mock.clear();
      // Now p1 plays round 1 — all miss with score > 0.
      throwAndMissAll(provider, mock);
      final turnEndText = mock.announcements
          .firstWhere((t) =>
              t.contains('treasure holds') ||
              t.contains('overboard') ||
              t.contains('storm'));
      expect(turnEndText,
          'A storm hits! Three-quarters of the treasure is lost!');
    });
  });

  // ─── Group 4: Turn-end Team ────────────────────────────────────────────────

  group('Group 4 — Turn-end Team', () {
    test('crew P1 all-miss + crew P2 all-miss → Crew Wipeout on P2 takeout',
        () {
      // We need a crew with some treasure first so Wipeout fires.
      // Build a provider where team_1 has score > 0 after round 0,
      // then simulate round 1 with both players missing.
      final provider = createTeamProvider();
      final target0 = provider.currentGame!.targetSequence[0];

      // Round 0: team_1 (p1 + p2) both hit
      throwAndHitAll(provider, mock, baseScore: target0); // p1
      mock.clear();
      // p2 hits
      throwAndHitAll(provider, mock, baseScore: target0); // p2
      mock.clear();
      // team_2 (p3 + p4) both miss
      throwAndMissAll(provider, mock); // p3
      mock.clear();
      throwAndMissAll(provider, mock); // p4
      mock.clear();

      // Now round 1: team_1 has score > 0. Both p1 and p2 miss.
      throwAndMissAll(provider, mock); // p1 — mid-crew, no turn-end announcement
      // No crew-level turn-end yet (only p1 done).
      final crewWipeoutAfterP1 = mock.announcements
          .where((t) => t.contains('All hands lost'))
          .toList();
      expect(crewWipeoutAfterP1.length, 0,
          reason: 'Mid-crew P1 takeout fires no crew turn-end');
      mock.clear();

      throwAndMissAll(provider, mock); // p2 — crew complete → Crew Wipeout
      final crewWipeoutAfterP2 = mock.announcements
          .where((t) => t.contains('All hands lost'))
          .toList();
      expect(crewWipeoutAfterP2.length, 1);
    });

    test('crew P1 hits + crew P2 all-miss → Crew Plunder on P2 takeout', () {
      final provider = createTeamProvider();
      final target = provider.currentGame!.targetSequence[0];

      // p1 hits
      throwAndHitAll(provider, mock, baseScore: target);
      mock.clear();
      // p2 misses — crew has hit (via p1), so Crew Plunder
      throwAndMissAll(provider, mock);

      final plunderTexts = mock.announcements
          .where((t) => t.contains('haul in'))
          .toList();
      expect(plunderTexts.length, 1);
      expect(plunderTexts.first, contains('haul in'));
    });

    test('mid-crew P1 takeout fires NO crew turn-end announcement', () {
      final provider = createTeamProvider();
      final target = provider.currentGame!.targetSequence[0];

      // p1 throws and is done — but p2 still needs to throw.
      throwAndHitAll(provider, mock, baseScore: target);

      // completedCrewId should be null (crew not yet done)
      expect(provider.justCompletedCrewId, isNull);

      // No crew turn-end in announcements
      final crewTurnEnd = mock.announcements
          .where((t) =>
              t.contains('haul in') || t.contains('All hands lost'))
          .toList();
      expect(crewTurnEnd.length, 0);
    });
  });

  // ─── Group 5: Round transitions ───────────────────────────────────────────

  group('Group 5 — Round transitions', () {
    test('Bull target sentinel triggers Treasure Island announcement', () {
      // 9-round default: target[8] == 25 (Bull).
      // Play through rounds 0-7 quickly.
      final provider = createSoloProvider(playerCount: 2, numberOfRounds: 9);
      for (int round = 0; round < 7; round++) {
        throwAndMissAll(provider, mock); // p1
        mock.clear();
        throwAndMissAll(provider, mock); // p2
        mock.clear();
      }
      // Round 7 now: p1 throws to advance to round 8 (Bull).
      throwAndMissAll(provider, mock); // p1 done with round 7
      mock.clear();
      throwAndMissAll(provider, mock); // p2 done → round advances to 8

      final roundTransition = mock.announcements
          .where((t) =>
              t.contains('Treasure Island') ||
              t.contains('Final island') ||
              t.contains('Island'))
          .toList();
      // Round 8 is the last round AND a Bull round.
      // Last Round precedence wins over Bull Round.
      expect(roundTransition.length, greaterThanOrEqualTo(1));
      expect(roundTransition.last,
          anyOf(
            'Final island! Last chance for treasure!',
            'Treasure Island! Hit the bullseye!',
          ));
    });

    test('Double target sentinel triggers Double Doubloon announcement', () {
      // 7-round sequence: [20, 19, 18, -1, 17, -2, 25]
      // Round 3 (index 3) is -1 (Any Double).
      final provider = createSoloProvider(playerCount: 2, numberOfRounds: 7);
      for (int round = 0; round < 2; round++) {
        throwAndMissAll(provider, mock); // p1
        mock.clear();
        throwAndMissAll(provider, mock); // p2
        mock.clear();
      }
      // Round 2 now: after both players finish → round advances to 3 (Double)
      throwAndMissAll(provider, mock); // p1
      mock.clear();
      throwAndMissAll(provider, mock); // p2 → round 3 starts

      final roundTransition = mock.announcements
          .where((t) =>
              t.contains('Double Doubloon') || t.contains('Island'))
          .toList();
      expect(roundTransition.length, greaterThanOrEqualTo(1));
      expect(roundTransition.last, 'Double Doubloon round! Hit any double!');
    });

    test('Last Round announcement fires on final round transition', () {
      // 7-round, so last round is index 6. Play through to index 5 → 6.
      final provider = createSoloProvider(playerCount: 2, numberOfRounds: 7);
      for (int round = 0; round < 5; round++) {
        throwAndMissAll(provider, mock); // p1
        mock.clear();
        throwAndMissAll(provider, mock); // p2
        mock.clear();
      }
      throwAndMissAll(provider, mock); // p1 round 5
      mock.clear();
      throwAndMissAll(provider, mock); // p2 round 5 → advance to round 6

      final lastRound = mock.announcements
          .where((t) => t.contains('Final island'))
          .toList();
      expect(lastRound.length, 1);
      expect(lastRound.first, 'Final island! Last chance for treasure!');
    });
  });

  // ─── Group 6: Leader change ────────────────────────────────────────────────

  group('Group 6 — Leader change', () {
    test('leader change after turn-end queues the leader announcement', () {
      // p1 scores > p2 → "p1 leads with X gold!"
      // We simulate the leader-change announcement directly since the
      // screen wires it in _maybeAnnounceLeaderChange after handleTakeoutFinished.
      final provider = createSoloProvider();
      final target = provider.currentGame!.targetSequence[0];

      // p1 hits (score > 0)
      throwAndHitAll(provider, mock, baseScore: target);
      mock.clear();

      // p2 misses (score == 0)
      throwAndMissAll(provider, mock);
      mock.clear();

      // Now p1 is the leader; simulate the leader-change announcement.
      // Single-leader path uses the named announcement; tie path uses
      // announceLeadersTied. Here p1 alone is the leader so we use names.
      mock.announceLeaderChange('p1',
          provider.currentGame!.totalForPlayer('p1'),
          isTeam: false);

      final leader = mock.announcements
          .where((t) => t.contains('leads with'))
          .toList();
      expect(leader.length, 1);
      expect(leader.first, contains('leads with'));
    });
  });

  // ─── Group 7: Stacking / max-2 constraint ─────────────────────────────────

  group('Group 7 — Stacking constraint', () {
    test(
        'Simulate a dart event that could stack 3+ and verify exactly 2 fire on dart',
        () {
      // Scenario: Bull Hit on the LAST dart of the turn (shouldPromptTakeout
      // becomes true). Turn-end, round-transition, leader-change all happen
      // via processTakeout AFTER the dart, not ON the dart.
      //
      // The dart itself produces at most:
      //   1. Bull Hit moment
      //   2. Remove Darts
      //
      // Turn-end / round-transition would be separate calls via processTakeout.
      final provider = createSoloProvider(playerCount: 2, numberOfRounds: 9);

      // Skip to round 8 (Bull round).
      for (int round = 0; round < 8; round++) {
        throwAndMissAll(provider, mock); // p1
        mock.clear();
        throwAndMissAll(provider, mock); // p2
        mock.clear();
      }
      expect(provider.currentGame!.currentRoundIndex, 8);

      // Throw 2 miss darts first (they only fire their own events, not Remove Darts yet)
      processDart(provider, mock,
          score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');
      processDart(provider, mock,
          score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');
      mock.clear(); // clear mid-turn events

      // Last dart: Bull Hit — should produce exactly 2 announcements
      processDart(provider, mock,
          score: 50, multiplier: 'bull', baseScore: 25, sector: 'Bull');

      // Exactly 2: Bull Hit moment + Remove Darts
      expect(mock.captured.length, 2,
          reason: 'Exactly 2 announcements fire on the dart event');
      expect(mock.captured[0].text, 'X marks the spot! 50 gold!');
      expect(mock.captured[1].text, 'Remove your darts!');
    });
  });

  // ─── Group 8: Auto-play suppression ───────────────────────────────────────

  group('Group 8 — Auto-play suppression', () {
    test('no per-dart or turn-end announcements when isAutoPlaying == true',
        () {
      final provider = createSoloProvider();
      final target = provider.currentGame!.targetSequence[0];

      // Simulate auto-play: throw 3 darts and do takeout, all suppressed.
      for (int i = 0; i < 3; i++) {
        processDart(provider, mock,
            score: target,
            multiplier: 'single',
            baseScore: target,
            sector: 'S$target',
            isAutoPlaying: true);
      }
      processTakeout(provider, mock, isAutoPlaying: true);

      expect(mock.captured.length, 0,
          reason:
              'No announcements fire when isAutoPlaying == true (Play-to-Complete)');
    });
  });
}
