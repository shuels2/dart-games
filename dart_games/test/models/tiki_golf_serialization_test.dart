import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/tiki_golf_game.dart';

void main() {
  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Fixed hole targets (9 distinct numbers, no duplicates, all in 1..20).
  const kTargets = [3, 7, 11, 15, 2, 18, 6, 14, 9];

  /// Fixed hole image paths (all 9 shuffled).
  const kImagePaths = [
    'assets/games/tiki_golf/pieces/Volcano.png',
    'assets/games/tiki_golf/pieces/Waterfall.png',
    'assets/games/tiki_golf/pieces/TikiStatue.png',
    'assets/games/tiki_golf/pieces/PalmTree.png',
    'assets/games/tiki_golf/pieces/Lagoon.png',
    'assets/games/tiki_golf/pieces/Shipwreck.png',
    'assets/games/tiki_golf/pieces/BambooTemple.png',
    'assets/games/tiki_golf/pieces/CoralReef.png',
    'assets/games/tiki_golf/pieces/SunsetPier.png',
  ];

  const kCrestSolo = <String>[];

  /// Build a minimal solo game with the given player ids.
  TikiGolfGame _buildSoloGame({
    List<String> playerIds = const ['p1', 'p2'],
    int maxStrokes = 3,
    bool mulliganEnabled = false,
  }) {
    return TikiGolfGame(
      id: 'game-solo-1',
      playerIds: playerIds,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      gameMode: TikiGolfGameMode.solo,
      teamAssignment: TikiGolfTeamAssignment.random,
      teamCount: 1,
      holeTargets: List<int>.from(kTargets),
      holeImagePaths: List<String>.from(kImagePaths),
      teamCrestPaths: kCrestSolo,
      teamPlayers: {},
      playerTeamAssignments: {},
    );
  }

  /// Build a 2-team game with the given team structure.
  TikiGolfGame _buildTeamGame({
    required Map<String, List<String>> teamPlayers,
    required Map<String, String> playerTeamAssignments,
    int teamCount = 2,
    int maxStrokes = 3,
    bool mulliganEnabled = false,
  }) {
    final allPlayerIds =
        teamPlayers.values.expand((list) => list).toList();
    final crests = [
      'assets/games/tiki_golf/teams/Sharks.png',
      'assets/games/tiki_golf/teams/SeaTurtles.png',
      'assets/games/tiki_golf/teams/Hibiscus.png',
      'assets/games/tiki_golf/teams/Volcanoes.png',
    ].take(teamCount).toList();

    return TikiGolfGame(
      id: 'game-team-1',
      playerIds: allPlayerIds,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      gameMode: TikiGolfGameMode.team,
      teamAssignment: TikiGolfTeamAssignment.manual,
      teamCount: teamCount,
      holeTargets: List<int>.from(kTargets),
      holeImagePaths: List<String>.from(kImagePaths),
      teamCrestPaths: crests,
      teamPlayers: {
        for (final e in teamPlayers.entries)
          e.key: List<String>.from(e.value),
      },
      playerTeamAssignments: Map<String, String>.from(playerTeamAssignments),
    );
  }

  // ─── Group 1: Solo mode serialization ────────────────────────────────────────

  group('TikiGolfGame serialization — solo mode', () {
    // 1. Serialize default game state (Solo)
    test('toJson includes all required fields for a default solo game', () {
      final game = _buildSoloGame();
      final json = game.toJson();

      expect(json['id'], 'game-solo-1');
      expect(json['playerIds'], ['p1', 'p2']);
      expect(json['maxStrokes'], 3);
      expect(json['mulliganEnabled'], false);
      expect(json['gameMode'], 'solo');
      expect(json['teamAssignment'], 'random');
      expect(json['teamCount'], 1);
      expect(json['holeTargets'], isA<List>());
      expect(json['holeImagePaths'], isA<List>());
      expect(json['teamCrestPaths'], isA<List>());
      expect(json['teamPlayers'], isA<Map>());
      expect(json['playerTeamAssignments'], isA<Map>());
      expect(json['state'], 'playing');
      expect(json['currentHole'], 1);
      expect(json['playerHoleScores'], isA<Map>());
      expect(json['playerMulligansUsed'], isA<Map>());
      expect(json['dartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['activePlayerId'], isNull);
      expect(json['activeTeamId'], isNull);
      expect(json['teamWithinHoleRotationPointer'], isA<Map>());
      expect(json['currentTeamIndex'], 0);
      expect(json['currentTurnEnded'], false);
      expect(json['winnerId'], isNull);
      expect(json['winnerTeamId'], isNull);
      // Enum values must NOT contain the Dart enum dot prefix
      expect((json['gameMode'] as String).contains('.'), isFalse);
      expect((json['state'] as String).contains('.'), isFalse);
    });

    // 2. Deserialize game state (Solo)
    test('fromJson restores all basic fields for a default solo game', () {
      final original = _buildSoloGame();
      final restored = TikiGolfGame.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.playerIds, original.playerIds);
      expect(restored.maxStrokes, 3);
      expect(restored.mulliganEnabled, false);
      expect(restored.gameMode, TikiGolfGameMode.solo);
      expect(restored.teamAssignment, TikiGolfTeamAssignment.random);
      expect(restored.teamCount, 1);
      expect(restored.state, TikiGolfGameState.playing);
      expect(restored.currentHole, 1);
      expect(restored.currentTeamIndex, 0);
      expect(restored.currentTurnEnded, false);
      expect(restored.winnerId, isNull);
      expect(restored.winnerTeamId, isNull);
    });

    // 3. Round-trip with scores for multiple holes (Solo)
    test('round-trip preserves per-player hole scores mid-game (solo)', () {
      final game = _buildSoloGame(playerIds: ['p1', 'p2', 'p3']);

      // Record some hole scores directly
      game.playerHoleScores['p1']![0] = 1; // birdie
      game.playerHoleScores['p1']![1] = 2; // par
      game.playerHoleScores['p2']![0] = 3; // bogey
      game.playerHoleScores['p3']![0] = 4; // splash (maxStrokes+1)
      game.currentHole = 3;
      game.dartsThrown['p1'] = 2;
      game.totalTurns['p1'] = 2;

      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.playerHoleScores['p1']![0], 1);
      expect(restored.playerHoleScores['p1']![1], 2);
      expect(restored.playerHoleScores['p1']![2], isNull);
      expect(restored.playerHoleScores['p2']![0], 3);
      expect(restored.playerHoleScores['p3']![0], 4);
      expect(restored.currentHole, 3);
      expect(restored.dartsThrown['p1'], 2);
      expect(restored.totalTurns['p1'], 2);
    });

    // 4. Round-trip preserves holeTargets exactly
    test('round-trip preserves holeTargets (9 distinct numbers in same order)', () {
      final game = _buildSoloGame();
      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.holeTargets, hasLength(9));
      expect(restored.holeTargets, equals(kTargets));
      // All values must be distinct and in 1..20
      final unique = restored.holeTargets.toSet();
      expect(unique.length, 9);
      expect(restored.holeTargets.every((t) => t >= 1 && t <= 20), isTrue);
    });

    // 5. Round-trip preserves holeImagePaths exactly
    test('round-trip preserves holeImagePaths (same shuffle order)', () {
      final game = _buildSoloGame();
      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.holeImagePaths, hasLength(9));
      expect(restored.holeImagePaths, equals(kImagePaths));
    });

    // 6. Round-trip with mulligan used state
    test('round-trip preserves playerMulligansUsed (per-player tracking)', () {
      final game = _buildSoloGame(
        playerIds: ['p1', 'p2', 'p3'],
        mulliganEnabled: true,
      );
      // p1 has used mulligan, p2 has not
      game.playerMulligansUsed['p1'] = 1;
      game.playerMulligansUsed['p2'] = 0;
      game.playerMulligansUsed['p3'] = 0;

      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.mulliganEnabled, isTrue);
      expect(restored.playerMulligansUsed['p1'], 1);
      expect(restored.playerMulligansUsed['p2'], 0);
      expect(restored.playerMulligansUsed['p3'], 0);
    });

    // 7. Round-trip with all options enabled including Max Strokes = 6
    test('round-trip with all options enabled and maxStrokes = 6', () {
      final game = _buildSoloGame(
        playerIds: ['p1', 'p2'],
        maxStrokes: 6,
        mulliganEnabled: true,
      );
      game.state = TikiGolfGameState.playing;
      game.currentHole = 5;

      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.maxStrokes, 6);
      expect(restored.mulliganEnabled, isTrue);
      expect(restored.currentHole, 5);
    });
  });

  // ─── Group 2: Team mode serialization ────────────────────────────────────────

  group('TikiGolfGame serialization — team mode', () {
    // 8. Round-trip with team config, team crests, and within-hole rotation pointer
    test('round-trip with team config, crests, and rotation pointer', () {
      final teamPlayers = {
        'team_1': ['p1', 'p2'],
        'team_2': ['p3', 'p4'],
      };
      final playerTeamAssignments = {
        'p1': 'team_1',
        'p2': 'team_1',
        'p3': 'team_2',
        'p4': 'team_2',
      };
      final game = _buildTeamGame(
        teamPlayers: teamPlayers,
        playerTeamAssignments: playerTeamAssignments,
        teamCount: 2,
      );
      game.activeTeamId = 'team_1';
      game.activePlayerId = 'p1';
      game.teamWithinHoleRotationPointer['team_1'] = 1;
      game.teamWithinHoleRotationPointer['team_2'] = 0;
      game.currentTeamIndex = 0;

      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.gameMode, TikiGolfGameMode.team);
      expect(restored.teamAssignment, TikiGolfTeamAssignment.manual);
      expect(restored.teamCount, 2);
      expect(restored.teamPlayers['team_1'], ['p1', 'p2']);
      expect(restored.teamPlayers['team_2'], ['p3', 'p4']);
      expect(restored.playerTeamAssignments['p1'], 'team_1');
      expect(restored.playerTeamAssignments['p3'], 'team_2');
      expect(restored.teamCrestPaths, hasLength(2));
      expect(restored.teamCrestPaths[0],
          'assets/games/tiki_golf/teams/Sharks.png');
      expect(restored.teamCrestPaths[1],
          'assets/games/tiki_golf/teams/SeaTurtles.png');
      expect(restored.activeTeamId, 'team_1');
      expect(restored.activePlayerId, 'p1');
      expect(restored.teamWithinHoleRotationPointer['team_1'], 1);
      expect(restored.teamWithinHoleRotationPointer['team_2'], 0);
      expect(restored.currentTeamIndex, 0);
    });

    // 9. Round-trip mid-hole with one team partway through its roster (pointer = 2)
    test('round-trip mid-hole team with rotation pointer = 2', () {
      final teamPlayers = {
        'team_1': ['p1', 'p2', 'p3'],
        'team_2': ['p4', 'p5', 'p6'],
      };
      final playerTeamAssignments = {
        'p1': 'team_1', 'p2': 'team_1', 'p3': 'team_1',
        'p4': 'team_2', 'p5': 'team_2', 'p6': 'team_2',
      };
      final game = _buildTeamGame(
        teamPlayers: teamPlayers,
        playerTeamAssignments: playerTeamAssignments,
        teamCount: 2,
      );
      // p1 and p2 have played on team_1 — pointer is at p3 (index 2)
      game.teamWithinHoleRotationPointer['team_1'] = 2;
      game.teamWithinHoleRotationPointer['team_2'] = 0;
      game.activeTeamId = 'team_1';
      game.activePlayerId = 'p3';
      game.currentTeamIndex = 0;
      game.currentHole = 2;

      // p1 and p2 have completed hole 1
      game.playerHoleScores['p1']![0] = 1;
      game.playerHoleScores['p2']![0] = 2;
      // p3 is mid-turn on hole 1 (score not yet recorded)
      game.dartsThrown['p3'] = 2;
      game.totalTurns['p3'] = 1;

      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.teamWithinHoleRotationPointer['team_1'], 2);
      expect(restored.teamWithinHoleRotationPointer['team_2'], 0);
      expect(restored.activeTeamId, 'team_1');
      expect(restored.activePlayerId, 'p3');
      expect(restored.currentTeamIndex, 0);
      expect(restored.currentHole, 2);
      expect(restored.playerHoleScores['p1']![0], 1);
      expect(restored.playerHoleScores['p2']![0], 2);
      expect(restored.playerHoleScores['p3']![0], isNull);
      expect(restored.dartsThrown['p3'], 2);
      expect(restored.totalTurns['p3'], 1);
    });

    // 10. Round-trip with per-player hole scores AND team best-ball scores both preserved
    test('round-trip preserves per-player scores and team best-ball is computable', () {
      final teamPlayers = {
        'team_1': ['p1', 'p2'],
        'team_2': ['p3', 'p4'],
      };
      final playerTeamAssignments = {
        'p1': 'team_1', 'p2': 'team_1',
        'p3': 'team_2', 'p4': 'team_2',
      };
      final game = _buildTeamGame(
        teamPlayers: teamPlayers,
        playerTeamAssignments: playerTeamAssignments,
        teamCount: 2,
      );
      // Hole 1: team_1 best-ball = 1 (p1=1, p2=3); team_2 best-ball = 2 (p3=4, p4=2)
      game.playerHoleScores['p1']![0] = 1;
      game.playerHoleScores['p2']![0] = 3;
      game.playerHoleScores['p3']![0] = 4;
      game.playerHoleScores['p4']![0] = 2;
      // Hole 2: team_1 best-ball = 2 (p1=2, p2=2); team_2 best-ball = 1 (p3=1, p4=3)
      game.playerHoleScores['p1']![1] = 2;
      game.playerHoleScores['p2']![1] = 2;
      game.playerHoleScores['p3']![1] = 1;
      game.playerHoleScores['p4']![1] = 3;
      game.currentHole = 3;

      final restored = TikiGolfGame.fromJson(game.toJson());

      // Verify individual player scores survived
      expect(restored.playerHoleScores['p1']![0], 1);
      expect(restored.playerHoleScores['p2']![0], 3);
      expect(restored.playerHoleScores['p3']![0], 4);
      expect(restored.playerHoleScores['p4']![0], 2);

      // Verify best-ball is correctly computable from restored state
      expect(restored.bestBallForTeam('team_1', 0), 1); // min(1,3)
      expect(restored.bestBallForTeam('team_2', 0), 2); // min(4,2)
      expect(restored.bestBallForTeam('team_1', 1), 2); // min(2,2)
      expect(restored.bestBallForTeam('team_2', 1), 1); // min(1,3)

      // Verify team totals
      expect(restored.totalForTeam('team_1'), 3); // 1+2
      expect(restored.totalForTeam('team_2'), 3); // 2+1
    });

    // 11. Round-trip with unequal team sizes [4,2,1,3]
    test('round-trip with 4 teams of unequal sizes [4,2,1,3]', () {
      // 10 players across 4 unequal teams
      final teamPlayers = {
        'team_1': ['p1', 'p2', 'p3', 'p4'],
        'team_2': ['p5', 'p6'],
        'team_3': ['p7'],
        'team_4': ['p8', 'p9', 'p10'],
      };
      final playerTeamAssignments = {
        'p1': 'team_1', 'p2': 'team_1', 'p3': 'team_1', 'p4': 'team_1',
        'p5': 'team_2', 'p6': 'team_2',
        'p7': 'team_3',
        'p8': 'team_4', 'p9': 'team_4', 'p10': 'team_4',
      };
      final game = _buildTeamGame(
        teamPlayers: teamPlayers,
        playerTeamAssignments: playerTeamAssignments,
        teamCount: 4,
      );

      final restored = TikiGolfGame.fromJson(game.toJson());

      expect(restored.teamPlayers['team_1'], hasLength(4));
      expect(restored.teamPlayers['team_2'], hasLength(2));
      expect(restored.teamPlayers['team_3'], hasLength(1));
      expect(restored.teamPlayers['team_4'], hasLength(3));
      expect(restored.teamCount, 4);
      expect(restored.playerIds, hasLength(10));

      // Verify inverse lookup round-trips
      expect(restored.playerTeamAssignments['p1'], 'team_1');
      expect(restored.playerTeamAssignments['p5'], 'team_2');
      expect(restored.playerTeamAssignments['p7'], 'team_3');
      expect(restored.playerTeamAssignments['p10'], 'team_4');

      // Verify rotation pointers exist for all 4 teams
      expect(restored.teamWithinHoleRotationPointer.keys.toSet(),
          {'team_1', 'team_2', 'team_3', 'team_4'});
    });
  });

  // ─── Group 3: Max Strokes variations ─────────────────────────────────────────

  group('TikiGolfGame serialization — maxStrokes variations', () {
    // 12. Round-trip with Max Strokes = 3, 4, 5, 6
    for (final strokes in [3, 4, 5, 6]) {
      test('round-trip with maxStrokes = $strokes', () {
        final game = _buildSoloGame(maxStrokes: strokes);
        // Set a splash score (maxStrokes + 1) for p1 on hole 0
        game.playerHoleScores['p1']![0] = strokes + 1;

        final restored = TikiGolfGame.fromJson(game.toJson());

        expect(restored.maxStrokes, strokes);
        expect(restored.playerHoleScores['p1']![0], strokes + 1,
            reason: 'Splash score (maxStrokes+1=${ strokes + 1}) must survive round-trip');
      });
    }
  });
}
