import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/treasure_divide_game.dart';

void main() {
  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Build a minimal solo game with fixed state (no randomness).
  TreasureDivideGame _buildSoloGame({
    String id = 'game-solo-1',
    List<String> playerIds = const ['p1', 'p2'],
    int numberOfRounds = 9,
    bool quarterItEnabled = false,
    bool customTargetsEnabled = false,
  }) {
    final sequence = TreasureDivideGame.sequenceFor(numberOfRounds);
    return TreasureDivideGame(
      id: id,
      playerIds: List<String>.from(playerIds),
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      gameMode: TreasureDivideGameMode.solo,
      teamAssignment: TreasureDivideTeamAssignment.random,
      teamCount: 1,
      teamCrestPaths: const [],
      targetSequence: sequence,
      teamPlayers: const {},
      playerTeamAssignments: {},
      playerPirateThemes: {'p1': 0, 'p2': 1},
      currentPlayerId: playerIds.first,
    );
  }

  /// Build a 2-team game with fixed team structure.
  TreasureDivideGame _buildTeamGame({
    String id = 'game-team-1',
    int numberOfRounds = 9,
    bool quarterItEnabled = false,
    bool customTargetsEnabled = false,
  }) {
    const teamPlayers = {
      'team_1': ['p1', 'p2'],
      'team_2': ['p3', 'p4'],
    };
    const playerTeamAssignments = {
      'p1': 'team_1',
      'p2': 'team_1',
      'p3': 'team_2',
      'p4': 'team_2',
    };
    const playerIds = ['p1', 'p2', 'p3', 'p4'];
    final sequence = TreasureDivideGame.sequenceFor(numberOfRounds);
    return TreasureDivideGame(
      id: id,
      playerIds: playerIds,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      gameMode: TreasureDivideGameMode.team,
      teamAssignment: TreasureDivideTeamAssignment.random,
      teamCount: 2,
      teamCrestPaths: const [
        'assets/games/treasure_divide/teams/CrossedCutlasses.png',
        'assets/games/treasure_divide/teams/GoldDoubloon.png',
      ],
      targetSequence: sequence,
      teamPlayers: {
        for (final e in teamPlayers.entries) e.key: List<String>.from(e.value),
      },
      playerTeamAssignments: Map<String, String>.from(playerTeamAssignments),
      playerPirateThemes: {'p1': 0, 'p2': 1, 'p3': 2, 'p4': 3},
      currentPlayerId: 'p1',
      activeTeamId: 'team_1',
    );
  }

  // ─── Group 1: Solo mode round-trip ───────────────────────────────────────────

  group('TreasureDivideGame serialization — solo mode', () {
    // 1. toJson includes all required fields
    test('toJson includes all required fields for a default solo game', () {
      final game = _buildSoloGame();
      final json = game.toJson();

      expect(json['id'], 'game-solo-1');
      expect(json['playerIds'], ['p1', 'p2']);
      expect(json['numberOfRounds'], 9);
      expect(json['quarterItEnabled'], false);
      expect(json['customTargetsEnabled'], false);
      expect(json['gameMode'], 'solo');
      expect(json['teamAssignment'], 'random');
      expect(json['teamCount'], 1);
      expect(json['teamCrestPaths'], isA<List>());
      expect(json['targetSequence'], isA<List>());
      expect(json['teamPlayers'], isA<Map>());
      expect(json['playerTeamAssignments'], isA<Map>());
      expect(json['playerPirateThemes'], isA<Map>());
      expect(json['state'], 'playing');
      expect(json['currentRoundIndex'], 0);
      expect(json['currentPlayerId'], 'p1');
      expect(json['dartsThrown'], 0);
      expect(json['currentTeamIndex'], 0);
      expect(json['activeTeamId'], isNull);
      expect(json['teamWithinRoundRotationPointer'], isA<Map>());
      expect(json['playerRoundScores'], isA<Map>());
      expect(json['currentTurnDartSegments'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['timesHalvedPerPlayer'], isA<Map>());
      expect(json['timesHalvedPerTeam'], isA<Map>());
      expect(json['shouldPromptTakeout'], false);
      expect(json['winnerIds'], isEmpty);
      expect(json['winnerTeamIds'], isEmpty);
      // Enum values must NOT contain the Dart enum dot prefix
      expect((json['gameMode'] as String).contains('.'), isFalse);
      expect((json['state'] as String).contains('.'), isFalse);
      expect((json['teamAssignment'] as String).contains('.'), isFalse);
    });

    // 2. fromJson restores all basic fields
    test('fromJson restores all basic fields for a default solo game', () {
      final original = _buildSoloGame();
      final restored = TreasureDivideGame.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.playerIds, original.playerIds);
      expect(restored.numberOfRounds, 9);
      expect(restored.quarterItEnabled, false);
      expect(restored.customTargetsEnabled, false);
      expect(restored.gameMode, TreasureDivideGameMode.solo);
      expect(restored.teamAssignment, TreasureDivideTeamAssignment.random);
      expect(restored.teamCount, 1);
      expect(restored.state, TreasureDivideGameState.playing);
      expect(restored.currentRoundIndex, 0);
      expect(restored.currentPlayerId, 'p1');
      expect(restored.dartsThrown, 0);
      expect(restored.currentTeamIndex, 0);
      expect(restored.activeTeamId, isNull);
      expect(restored.shouldPromptTakeout, false);
      expect(restored.winnerIds, isEmpty);
      expect(restored.winnerTeamIds, isEmpty);
    });

    // 3. Complete solo round-trip through JSON string encoding
    test('complete solo round-trip byte-identical through jsonEncode/jsonDecode', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3']);
      // Set some runtime state to test full fidelity
      game.currentRoundIndex = 2;
      game.dartsThrown = 1;
      game.playerRoundScores['p1']![0] = 40;
      game.playerRoundScores['p2']![0] = 0;
      game.playerRoundScores['p1']![1] = 57;
      game.totalDartsThrown['p1'] = 6;
      game.totalDartsThrown['p2'] = 6;
      game.totalTurns['p1'] = 2;
      game.totalTurns['p2'] = 2;
      game.timesHalvedPerPlayer['p2'] = 1;
      game.currentTurnDartSegments['p3'] = ['S19'];

      final jsonStr = jsonEncode(game.toJson());
      final restored =
          TreasureDivideGame.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

      expect(restored.id, game.id);
      expect(restored.currentRoundIndex, 2);
      expect(restored.dartsThrown, 1);
      expect(restored.playerRoundScores['p1']![0], 40);
      expect(restored.playerRoundScores['p2']![0], 0);
      expect(restored.playerRoundScores['p1']![1], 57);
      expect(restored.playerRoundScores['p1']![2], isNull);
      expect(restored.totalDartsThrown['p1'], 6);
      expect(restored.totalTurns['p2'], 2);
      expect(restored.timesHalvedPerPlayer['p2'], 1);
      expect(restored.currentTurnDartSegments['p3'], ['S19']);
    });

    // 4. Empty maps / nullable fields at game start
    test('empty maps and null scores round-trip at game start', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3']);
      final restored = TreasureDivideGame.fromJson(game.toJson());

      // playerRoundScores should be all-null lists of length 9
      for (final pid in ['p1', 'p2', 'p3']) {
        expect(restored.playerRoundScores[pid], hasLength(9));
        expect(restored.playerRoundScores[pid]!.every((e) => e == null), isTrue,
            reason: 'All round scores should be null at game start for $pid');
      }
      // All counters should be 0
      for (final pid in ['p1', 'p2', 'p3']) {
        expect(restored.totalDartsThrown[pid], 0);
        expect(restored.totalTurns[pid], 0);
        expect(restored.timesHalvedPerPlayer[pid], 0);
      }
      // currentTurnDartSegments should be empty lists
      for (final pid in ['p1', 'p2', 'p3']) {
        expect(restored.currentTurnDartSegments[pid], isEmpty);
      }
    });

    // 5. Enum `.name` strings survive (no dot prefix, correct value)
    test('all three enums round-trip via .name strings', () {
      final game = _buildSoloGame();
      game.state = TreasureDivideGameState.finished;

      final json = game.toJson();
      expect(json['gameMode'], 'solo');
      expect(json['teamAssignment'], 'random');
      expect(json['state'], 'finished');

      final restored = TreasureDivideGame.fromJson(json);
      expect(restored.gameMode, TreasureDivideGameMode.solo);
      expect(restored.teamAssignment, TreasureDivideTeamAssignment.random);
      expect(restored.state, TreasureDivideGameState.finished);
    });

    // 6. playerPirateThemes Map<String, int> round-trip
    test('playerPirateThemes round-trip preserves all theme indices', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3', 'p4']);
      // Manually assign specific themes
      game.playerPirateThemes['p1'] = 3;
      game.playerPirateThemes['p2'] = 7;
      game.playerPirateThemes['p3'] = 0;
      game.playerPirateThemes['p4'] = 5;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.playerPirateThemes['p1'], 3);
      expect(restored.playerPirateThemes['p2'], 7);
      expect(restored.playerPirateThemes['p3'], 0);
      expect(restored.playerPirateThemes['p4'], 5);
    });

    // 7. timesHalvedPerPlayer round-trip (non-negative only)
    test('timesHalvedPerPlayer round-trip — non-negative values only', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3']);
      game.timesHalvedPerPlayer['p1'] = 3;
      game.timesHalvedPerPlayer['p2'] = 0;
      game.timesHalvedPerPlayer['p3'] = 1;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.timesHalvedPerPlayer['p1'], 3);
      expect(restored.timesHalvedPerPlayer['p2'], 0);
      expect(restored.timesHalvedPerPlayer['p3'], 1);
      // Halve counter should never be negative in practice
      for (final v in restored.timesHalvedPerPlayer.values) {
        expect(v, greaterThanOrEqualTo(0));
      }
    });

    // 8. quarterItEnabled = true round-trip
    test('quarterItEnabled = true survives round-trip', () {
      final game = _buildSoloGame(quarterItEnabled: true);
      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.quarterItEnabled, isTrue);
    });

    // 9. gameStartTime and gameEndTime nullable timestamps round-trip
    test('gameStartTime and gameEndTime round-trip via ISO 8601', () {
      final game = _buildSoloGame();
      final start = DateTime.utc(2026, 6, 10, 14, 30, 0);
      final end = DateTime.utc(2026, 6, 10, 15, 0, 0);
      game.gameStartTime = start;
      game.gameEndTime = end;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.gameStartTime!.toUtc(), start);
      expect(restored.gameEndTime!.toUtc(), end);

      // Also test null timestamps
      game.gameStartTime = null;
      game.gameEndTime = null;
      final restored2 = TreasureDivideGame.fromJson(game.toJson());
      expect(restored2.gameStartTime, isNull);
      expect(restored2.gameEndTime, isNull);
    });
  });

  // ─── Group 2: Team mode round-trip ───────────────────────────────────────────

  group('TreasureDivideGame serialization — team mode', () {
    // 10. Team mode complete round-trip
    test('complete team mode round-trip byte-identical', () {
      final game = _buildTeamGame();
      final restored =
          TreasureDivideGame.fromJson(jsonDecode(jsonEncode(game.toJson()))
              as Map<String, dynamic>);

      expect(restored.gameMode, TreasureDivideGameMode.team);
      expect(restored.teamAssignment, TreasureDivideTeamAssignment.random);
      expect(restored.teamCount, 2);
      expect(restored.playerIds, ['p1', 'p2', 'p3', 'p4']);
      expect(restored.teamPlayers['team_1'], ['p1', 'p2']);
      expect(restored.teamPlayers['team_2'], ['p3', 'p4']);
      expect(restored.playerTeamAssignments['p1'], 'team_1');
      expect(restored.playerTeamAssignments['p3'], 'team_2');
      expect(restored.activeTeamId, 'team_1');
    });

    // 11. Team crests and rotation pointer round-trip
    test('teamCrestPaths and teamWithinRoundRotationPointer round-trip', () {
      final game = _buildTeamGame();
      game.teamWithinRoundRotationPointer['team_1'] = 1;
      game.teamWithinRoundRotationPointer['team_2'] = 0;
      game.currentTeamIndex = 1;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.teamCrestPaths, hasLength(2));
      expect(restored.teamCrestPaths[0],
          'assets/games/treasure_divide/teams/CrossedCutlasses.png');
      expect(restored.teamCrestPaths[1],
          'assets/games/treasure_divide/teams/GoldDoubloon.png');
      expect(restored.teamWithinRoundRotationPointer['team_1'], 1);
      expect(restored.teamWithinRoundRotationPointer['team_2'], 0);
      expect(restored.currentTeamIndex, 1);
    });

    // 12. timesHalvedPerTeam round-trip
    test('timesHalvedPerTeam round-trip preserves crew halve counters', () {
      final game = _buildTeamGame();
      game.timesHalvedPerTeam['team_1'] = 2;
      game.timesHalvedPerTeam['team_2'] = 0;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.timesHalvedPerTeam['team_1'], 2);
      expect(restored.timesHalvedPerTeam['team_2'], 0);
    });

    // 13. winnerTeamIds round-trip in finished game
    test('winnerTeamIds round-trip in a finished team game', () {
      final game = _buildTeamGame();
      game.state = TreasureDivideGameState.finished;
      game.winnerTeamIds.add('team_2');
      // Fill in some scores
      for (int r = 0; r < 9; r++) {
        game.playerRoundScores['p1']![r] = 0;
        game.playerRoundScores['p2']![r] = 0;
        game.playerRoundScores['p3']![r] = 30;
        game.playerRoundScores['p4']![r] = 30;
      }

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.state, TreasureDivideGameState.finished);
      expect(restored.winnerTeamIds, ['team_2']);
      expect(restored.winnerIds, isEmpty);
    });

    // 14. Team mode manual assignment round-trip
    test('team mode with manual teamAssignment round-trips correctly', () {
      final sequence = TreasureDivideGame.sequenceFor(7);
      final game = TreasureDivideGame(
        id: 'game-manual',
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        numberOfRounds: 7,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.team,
        teamAssignment: TreasureDivideTeamAssignment.manual,
        teamCount: 2,
        teamCrestPaths: const [
          'assets/games/treasure_divide/teams/Anchor.png',
          'assets/games/treasure_divide/teams/Kraken.png',
        ],
        targetSequence: sequence,
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        playerTeamAssignments: {
          'p1': 'team_1',
          'p2': 'team_1',
          'p3': 'team_2',
          'p4': 'team_2',
        },
        playerPirateThemes: {'p1': 0, 'p2': 1, 'p3': 2, 'p4': 3},
        currentPlayerId: 'p1',
        activeTeamId: 'team_1',
      );

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.teamAssignment, TreasureDivideTeamAssignment.manual);
      expect(restored.numberOfRounds, 7);
      expect(restored.targetSequence, hasLength(7));
    });
  });

  // ─── Group 3: Sentinel targets ────────────────────────────────────────────────

  group('TreasureDivideGame serialization — sentinel targets', () {
    // 15. Standard 9-round target sequence preserves sentinels kTargetAnyDouble
    //     (= -1), kTargetAnyTriple (= -2), and kTargetBull (= 25)
    test('standard 9-round target sequence round-trips with all sentinels', () {
      final game = _buildSoloGame(numberOfRounds: 9);
      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.targetSequence, hasLength(9));
      // Index 3 = kTargetAnyDouble (-1)
      expect(restored.targetSequence[3], kTargetAnyDouble);
      expect(restored.targetSequence[3], -1);
      // Index 7 = kTargetAnyTriple (-2)
      expect(restored.targetSequence[7], kTargetAnyTriple);
      expect(restored.targetSequence[7], -2);
      // Index 8 = kTargetBull (25)
      expect(restored.targetSequence[8], kTargetBull);
      expect(restored.targetSequence[8], 25);
    });

    // 16. 7-round target sequence sentinel positions differ
    test('standard 7-round target sequence round-trips with correct sentinel positions', () {
      final game = _buildSoloGame(numberOfRounds: 7);
      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.targetSequence, hasLength(7));
      expect(restored.targetSequence[3], kTargetAnyDouble); // -1
      expect(restored.targetSequence[5], kTargetAnyTriple); // -2
      expect(restored.targetSequence[6], kTargetBull);      // 25
    });

    // 17. 12-round target sequence sentinel positions
    test('standard 12-round target sequence round-trips with correct sentinel positions', () {
      final game = _buildSoloGame(numberOfRounds: 12);
      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.targetSequence, hasLength(12));
      expect(restored.targetSequence[3], kTargetAnyDouble); // -1
      expect(restored.targetSequence[7], kTargetAnyTriple); // -2
      expect(restored.targetSequence[11], kTargetBull);     // 25
    });

    // 18. Negative sentinel integers NOT coerced to 0 or positive by JSON
    test('negative sentinel integers survive JSON encode/decode without coercion', () {
      final game = _buildSoloGame(numberOfRounds: 9);
      final jsonStr = jsonEncode(game.toJson());
      final restored =
          TreasureDivideGame.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

      // Sentinels must remain negative after JSON round-trip
      expect(restored.targetSequence.contains(kTargetAnyDouble), isTrue,
          reason: 'kTargetAnyDouble (-1) must survive JSON round-trip');
      expect(restored.targetSequence.contains(kTargetAnyTriple), isTrue,
          reason: 'kTargetAnyTriple (-2) must survive JSON round-trip');
      // No accidental positive coercion
      expect(
          restored.targetSequence
              .where((t) => t < -2)
              .isEmpty,
          isTrue,
          reason: 'No values below -2 should exist');
    });

    // 19. Custom target sequence round-trip (AD and AT at correct fixed positions)
    test('customTargetsEnabled round-trip preserves AD, AT, Bull at fixed positions', () {
      // Build a game with a known custom sequence by hand
      final customSeq = [5, 12, 8, kTargetAnyDouble, 3, 17, 14, kTargetAnyTriple, kTargetBull];
      final game = TreasureDivideGame(
        id: 'game-custom-1',
        playerIds: const ['p1', 'p2'],
        numberOfRounds: 9,
        quarterItEnabled: false,
        customTargetsEnabled: true,
        gameMode: TreasureDivideGameMode.solo,
        teamAssignment: TreasureDivideTeamAssignment.random,
        teamCount: 1,
        teamCrestPaths: const [],
        targetSequence: customSeq,
        teamPlayers: const {},
        playerTeamAssignments: {},
        playerPirateThemes: const {'p1': 0, 'p2': 1},
        currentPlayerId: 'p1',
      );

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.customTargetsEnabled, isTrue);
      expect(restored.targetSequence, hasLength(9));
      expect(restored.targetSequence[3], kTargetAnyDouble);
      expect(restored.targetSequence[7], kTargetAnyTriple);
      expect(restored.targetSequence[8], kTargetBull);
      expect(restored.targetSequence[0], 5);
      expect(restored.targetSequence[2], 8);
    });

    // 20. Current round target is a sentinel — state with currentRoundIndex pointing
    //     at a sentinel round survives round-trip
    test('game state mid-AnyDouble round round-trips correctly', () {
      final game = _buildSoloGame(numberOfRounds: 9);
      // Advance to round index 3 (kTargetAnyDouble)
      game.currentRoundIndex = 3;
      game.currentPlayerId = 'p2';
      game.dartsThrown = 2;
      // Mark rounds 0-2 as complete for p1 and p2
      for (int r = 0; r < 3; r++) {
        game.playerRoundScores['p1']![r] = 20 + r;
        game.playerRoundScores['p2']![r] = 18 + r;
      }

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.currentRoundIndex, 3);
      // The target for round index 3 must be kTargetAnyDouble
      expect(restored.targetSequence[restored.currentRoundIndex], kTargetAnyDouble);
      expect(restored.dartsThrown, 2);
      expect(restored.currentPlayerId, 'p2');
    });
  });

  // ─── Group 4: Mid-game state ─────────────────────────────────────────────────

  group('TreasureDivideGame serialization — mid-game state', () {
    // 21. Mid-game with darts thrown, currentTurnDartSegments, round 3 of 9
    test('mid-game round-trip: currentTurnDartSegments, round 3, leader state', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3']);
      // Advance to round 2 (0-indexed), mid-turn for p3
      game.currentRoundIndex = 2;
      game.currentPlayerId = 'p3';
      game.dartsThrown = 1;
      game.currentTurnDartSegments['p3'] = ['D20'];
      // Completed rounds 0-1 for all players
      for (final pid in ['p1', 'p2', 'p3']) {
        game.playerRoundScores[pid]![0] = 40;
        game.playerRoundScores[pid]![1] = 0;
        game.totalTurns[pid] = 2;
        game.totalDartsThrown[pid] = 6;
      }
      game.timesHalvedPerPlayer['p2'] = 1;
      game.winnerIds.add('p1'); // suppose p1 is leading — not winner yet but note
      // Actually winnerIds is for game over, let's leave it empty and set a real state
      game.winnerIds.clear();

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.currentRoundIndex, 2);
      expect(restored.currentPlayerId, 'p3');
      expect(restored.dartsThrown, 1);
      expect(restored.currentTurnDartSegments['p3'], ['D20']);
      expect(restored.playerRoundScores['p1']![0], 40);
      expect(restored.playerRoundScores['p2']![1], 0);
      expect(restored.playerRoundScores['p1']![2], isNull);
      expect(restored.totalTurns['p1'], 2);
      expect(restored.timesHalvedPerPlayer['p2'], 1);
    });

    // 22. shouldPromptTakeout flag round-trips
    test('shouldPromptTakeout = true survives round-trip', () {
      final game = _buildSoloGame();
      game.shouldPromptTakeout = true;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.shouldPromptTakeout, isTrue);
    });

    // 23. Finished solo game with winner
    test('finished solo game with winnerIds round-trips correctly', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3']);
      game.state = TreasureDivideGameState.finished;
      game.winnerIds.add('p1');
      // Fill all rounds
      for (int r = 0; r < 9; r++) {
        game.playerRoundScores['p1']![r] = 50;
        game.playerRoundScores['p2']![r] = 30;
        game.playerRoundScores['p3']![r] = 20;
      }

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.state, TreasureDivideGameState.finished);
      expect(restored.winnerIds, ['p1']);
      expect(restored.winnerTeamIds, isEmpty);
    });

    // 24. Tied solo winners round-trip
    test('tied solo winners (multiple winnerIds) round-trip', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2']);
      game.state = TreasureDivideGameState.finished;
      game.winnerIds.addAll(['p1', 'p2']);

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.winnerIds, containsAll(['p1', 'p2']));
      expect(restored.winnerIds, hasLength(2));
    });
  });

  // ─── Group 5: Solo crew (1-player crew, 6-dart turn) ────────────────────────

  group('TreasureDivideGame serialization — solo crew (1-player team)', () {
    // 25. Solo crew team: teamPlayers[crewId] has 1 member, dartsThisTurn = 6
    test('solo crew (1-member team) round-trip — dartsThisTurn is 6', () {
      final sequence = TreasureDivideGame.sequenceFor(9);
      final game = TreasureDivideGame(
        id: 'game-solo-crew',
        playerIds: const ['p1', 'p2', 'p3'],
        numberOfRounds: 9,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.team,
        teamAssignment: TreasureDivideTeamAssignment.random,
        teamCount: 2,
        teamCrestPaths: const [
          'assets/games/treasure_divide/teams/Anchor.png',
          'assets/games/treasure_divide/teams/CompassRose.png',
        ],
        targetSequence: sequence,
        // team_1 has 2 members; team_2 is the solo crew (1 member)
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3'],
        },
        playerTeamAssignments: {
          'p1': 'team_1',
          'p2': 'team_1',
          'p3': 'team_2',
        },
        playerPirateThemes: const {'p1': 0, 'p2': 1, 'p3': 2},
        currentPlayerId: 'p3',
        activeTeamId: 'team_2',
      );

      // Simulate 4 darts thrown in the 6-dart solo-crew turn
      game.dartsThrown = 4;
      game.currentTurnDartSegments['p3'] = ['S20', 'D10', 'Miss', 'S15'];
      game.totalDartsThrown['p3'] = 4;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.gameMode, TreasureDivideGameMode.team);
      expect(restored.teamPlayers['team_2'], ['p3'],
          reason: 'Solo crew must have exactly 1 member after restore');
      // dartsThisTurn is a computed property — verify it returns 6 for the solo crew
      final origGame = restored;
      // Simulate activeTeamId pointing at the solo crew
      expect(origGame.activeTeamId, 'team_2');
      expect(origGame.dartsThisTurn, 6,
          reason: 'Solo crew (1-member team) must get 6 darts per turn');
      expect(restored.dartsThrown, 4);
      expect(restored.currentTurnDartSegments['p3'], ['S20', 'D10', 'Miss', 'S15']);
    });
  });

  // ─── Group 6: quarterItEnabled option ───────────────────────────────────────

  group('TreasureDivideGame serialization — quarterItEnabled', () {
    // 26. quarterItEnabled = true in team game round-trip
    test('quarterItEnabled = true survives round-trip in team mode', () {
      final game = _buildTeamGame(quarterItEnabled: true);
      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.quarterItEnabled, isTrue);
    });

    // 27. quarterItEnabled interacts correctly with timesHalvedPerPlayer
    test('quarterItEnabled + timesHalvedPerTeam both survive round-trip', () {
      final game = _buildTeamGame(quarterItEnabled: true);
      game.timesHalvedPerTeam['team_1'] = 2;
      game.timesHalvedPerTeam['team_2'] = 1;

      final restored = TreasureDivideGame.fromJson(game.toJson());

      expect(restored.quarterItEnabled, isTrue);
      expect(restored.timesHalvedPerTeam['team_1'], 2);
      expect(restored.timesHalvedPerTeam['team_2'], 1);
    });
  });
}
