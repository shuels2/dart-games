import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/pirates_grid_game.dart';

void main() {
  // ─── Helper builders ─────────────────────────────────────────────────────────

  /// Builds a fresh Easy/Bo1 grid for two players.
  PiratesGridGame _freshGame({
    TargetDifficulty difficulty = TargetDifficulty.easy,
    int bestOf = 1,
    bool stealMode = false,
    bool speedPlay = false,
  }) {
    final grid = List.generate(
      3,
      (r) => List.generate(
        3,
        (c) => GridCell(
          target: CellTarget(number: r * 3 + c + 1, requirement: CellRequirement.any),
        ),
      ),
    );
    return PiratesGridGame(
      id: 'game-001',
      startedAt: DateTime(2026, 5, 1, 10, 0, 0),
      playerIds: ['p1', 'p2'],
      targetDifficulty: difficulty,
      bestOf: bestOf,
      stealMode: stealMode,
      speedPlay: speedPlay,
      grid: grid,
    );
  }

  // ─── CellTarget tests ─────────────────────────────────────────────────────────

  group('CellTarget serialization', () {
    test('requirement=any round-trips with number preserved', () {
      const original = CellTarget(number: 20, requirement: CellRequirement.any);
      final json = original.toJson();
      final restored = CellTarget.fromJson(json);

      expect(restored.number, 20);
      expect(restored.requirement, CellRequirement.any);
      expect(json['requirement'], 'any');
      expect((json['requirement'] as String).contains('.'), false);
    });

    test('requirement=doubleOrTriple round-trips', () {
      const original = CellTarget(number: 18, requirement: CellRequirement.doubleOrTriple);
      final json = original.toJson();
      final restored = CellTarget.fromJson(json);

      expect(restored.number, 18);
      expect(restored.requirement, CellRequirement.doubleOrTriple);
      expect(json['requirement'], 'doubleOrTriple');
    });

    test('requirement=doubleOnly round-trips', () {
      const original = CellTarget(number: 16, requirement: CellRequirement.doubleOnly);
      final json = original.toJson();
      final restored = CellTarget.fromJson(json);

      expect(restored.number, 16);
      expect(restored.requirement, CellRequirement.doubleOnly);
      expect(json['requirement'], 'doubleOnly');
    });

    test('requirement=tripleOnly round-trips', () {
      const original = CellTarget(number: 14, requirement: CellRequirement.tripleOnly);
      final json = original.toJson();
      final restored = CellTarget.fromJson(json);

      expect(restored.number, 14);
      expect(restored.requirement, CellRequirement.tripleOnly);
      expect(json['requirement'], 'tripleOnly');
    });

    test('requirement=bull round-trips (number=0)', () {
      const original = CellTarget(number: 0, requirement: CellRequirement.bull);
      final json = original.toJson();
      final restored = CellTarget.fromJson(json);

      expect(restored.number, 0);
      expect(restored.requirement, CellRequirement.bull);
      expect(json['requirement'], 'bull');
    });
  });

  // ─── GridPosition tests ───────────────────────────────────────────────────────

  group('GridPosition serialization', () {
    test('row/col round-trip', () {
      const original = GridPosition(2, 1);
      final json = original.toJson();
      final restored = GridPosition.fromJson(json);

      expect(restored.row, 2);
      expect(restored.col, 1);
      expect(json['row'], 2);
      expect(json['col'], 1);
    });
  });

  // ─── GridCell tests ───────────────────────────────────────────────────────────

  group('GridCell serialization', () {
    test('empty cell (claimedBy=null) round-trips', () {
      final original = GridCell(
        target: const CellTarget(number: 20, requirement: CellRequirement.any),
      );
      final json = original.toJson();
      final restored = GridCell.fromJson(json);

      expect(restored.claimedBy, isNull);
      expect(restored.target.number, 20);
      expect(restored.target.requirement, CellRequirement.any);
      expect(json['claimedBy'], isNull);
    });

    test('claimed cell round-trips with nested CellTarget preserved', () {
      final original = GridCell(
        target: const CellTarget(number: 18, requirement: CellRequirement.doubleOnly),
        claimedBy: 'p1',
      );
      final json = original.toJson();
      final restored = GridCell.fromJson(json);

      expect(restored.claimedBy, 'p1');
      expect(restored.target.number, 18);
      expect(restored.target.requirement, CellRequirement.doubleOnly);
    });
  });

  // ─── PiratesGridGame tests ────────────────────────────────────────────────────

  group('PiratesGridGame serialization', () {
    test('default-state Easy/Bo1 game round-trips with all fields equal', () {
      final original = _freshGame();
      final json = original.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.startedAt, original.startedAt);
      expect(restored.playerIds, original.playerIds);
      expect(restored.targetDifficulty, TargetDifficulty.easy);
      expect(restored.bestOf, 1);
      expect(restored.stealMode, false);
      expect(restored.speedPlay, false);
      expect(restored.currentPlayerIndex, 0);
      expect(restored.currentRound, 1);
      expect(restored.currentRoundStartingPlayerIndex, 0);
      expect(restored.winnerId, isNull);
      expect(restored.isDraw, false);
      expect(restored.winningLine, isNull);
      expect(restored.matchWinnerId, isNull);
      expect(restored.isMatchDraw, false);
      expect(restored.state, GameState.playing);
      expect(restored.gameEndTime, isNull);
    });

    test('all four game options (difficulty/bestOf/stealMode/speedPlay) round-trip correctly', () {
      final original = _freshGame(
        difficulty: TargetDifficulty.hard,
        bestOf: 3,
        stealMode: true,
        speedPlay: true,
      );
      final json = original.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.targetDifficulty, TargetDifficulty.hard);
      expect(restored.bestOf, 3);
      expect(restored.stealMode, true);
      expect(restored.speedPlay, true);
    });

    test('mid-round game with claimed cells and dart segments round-trips', () {
      final game = _freshGame();
      game.grid[0][0].claimedBy = 'p1';
      game.grid[1][1].claimedBy = 'p2';
      game.dartsThrown['p1'] = 2;
      game.totalDartsThrown['p1'] = 2;
      game.totalTurns['p1'] = 1;
      game.currentTurnDartSegments['p1'] = ['S20', 'S1'];

      final json = game.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.grid[0][0].claimedBy, 'p1');
      expect(restored.grid[1][1].claimedBy, 'p2');
      expect(restored.grid[0][1].claimedBy, isNull);
      expect(restored.dartsThrown['p1'], 2);
      expect(restored.totalDartsThrown['p1'], 2);
      expect(restored.totalTurns['p1'], 1);
      expect(restored.currentTurnDartSegments['p1'], ['S20', 'S1']);
    });

    test('round-won state (winnerId and winningLine) round-trips', () {
      final game = _freshGame();
      game.winnerId = 'p1';
      game.winningLine = [
        const GridPosition(0, 0),
        const GridPosition(1, 1),
        const GridPosition(2, 2),
      ];
      game.roundsWon['p1'] = 1;

      final json = game.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.winnerId, 'p1');
      expect(restored.winningLine, isNotNull);
      expect(restored.winningLine!.length, 3);
      expect(restored.winningLine![0], const GridPosition(0, 0));
      expect(restored.winningLine![1], const GridPosition(1, 1));
      expect(restored.winningLine![2], const GridPosition(2, 2));
      expect(restored.roundsWon['p1'], 1);
    });

    test('match-won state (matchWinnerId) round-trips', () {
      final game = _freshGame(bestOf: 3);
      game.matchWinnerId = 'p2';
      game.state = GameState.finished;
      game.gameEndTime = DateTime(2026, 5, 1, 11, 30, 0);

      final json = game.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.matchWinnerId, 'p2');
      expect(restored.state, GameState.finished);
      expect(restored.gameEndTime, DateTime(2026, 5, 1, 11, 30, 0));
    });

    test('match-draw state (isMatchDraw=true) round-trips', () {
      final game = _freshGame(bestOf: 3);
      game.isMatchDraw = true;
      game.state = GameState.finished;

      final json = game.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.isMatchDraw, true);
      expect(restored.matchWinnerId, isNull);
      expect(restored.state, GameState.finished);
    });

    test('all three TargetDifficulty enum values serialize as .name strings', () {
      for (final difficulty in TargetDifficulty.values) {
        final game = _freshGame(difficulty: difficulty);
        final json = game.toJson();
        expect(json['targetDifficulty'], difficulty.name);
        expect((json['targetDifficulty'] as String).contains('.'), false);

        final restored = PiratesGridGame.fromJson(json);
        expect(restored.targetDifficulty, difficulty);
      }
    });

    test('all three GameState enum values serialize as .name strings', () {
      for (final state in GameState.values) {
        final game = _freshGame();
        game.state = state;
        final json = game.toJson();
        expect(json['state'], state.name);
        expect((json['state'] as String).contains('.'), false);

        final restored = PiratesGridGame.fromJson(json);
        expect(restored.state, state);
      }
    });

    test('all five CellRequirement enum values serialize as .name strings', () {
      for (final req in CellRequirement.values) {
        final target = CellTarget(number: 10, requirement: req);
        final json = target.toJson();
        expect(json['requirement'], req.name);
        expect((json['requirement'] as String).contains('.'), false);

        final restored = CellTarget.fromJson(json);
        expect(restored.requirement, req);
      }
    });

    test('Map<String,int> fields (dartsThrown, totalTurns, totalDartsThrown, roundsWon) preserve all entries', () {
      final game = _freshGame(bestOf: 3);
      game.dartsThrown['p1'] = 3;
      game.dartsThrown['p2'] = 1;
      game.totalDartsThrown['p1'] = 5;
      game.totalDartsThrown['p2'] = 2;
      game.totalTurns['p1'] = 2;
      game.totalTurns['p2'] = 1;
      game.roundsWon['p1'] = 1;
      game.roundsWon['p2'] = 0;

      final json = game.toJson();

      // Verify serialized as Map with String keys
      expect(json['dartsThrown'], isA<Map<String, dynamic>>());
      expect(json['totalDartsThrown'], isA<Map<String, dynamic>>());
      expect(json['totalTurns'], isA<Map<String, dynamic>>());
      expect(json['roundsWon'], isA<Map<String, dynamic>>());

      final restored = PiratesGridGame.fromJson(json);
      expect(restored.dartsThrown['p1'], 3);
      expect(restored.dartsThrown['p2'], 1);
      expect(restored.totalDartsThrown['p1'], 5);
      expect(restored.totalDartsThrown['p2'], 2);
      expect(restored.totalTurns['p1'], 2);
      expect(restored.totalTurns['p2'], 1);
      expect(restored.roundsWon['p1'], 1);
      expect(restored.roundsWon['p2'], 0);
    });

    test('Map<String,List<String>> (currentTurnDartSegments) preserves keys and order', () {
      final game = _freshGame();
      game.currentTurnDartSegments['p1'] = ['T20', 'D18', 'S16'];
      game.currentTurnDartSegments['p2'] = ['Miss'];

      final json = game.toJson();
      expect(json['currentTurnDartSegments'], isA<Map>());

      final restored = PiratesGridGame.fromJson(json);
      expect(restored.currentTurnDartSegments['p1'], ['T20', 'D18', 'S16']);
      expect(restored.currentTurnDartSegments['p2'], ['Miss']);
    });

    test('3x3 grid (List<List<GridCell>>) round-trips with nested structure', () {
      final game = _freshGame();
      // Claim a few cells
      game.grid[0][0].claimedBy = 'p1';
      game.grid[2][2].claimedBy = 'p2';

      final json = game.toJson();
      expect(json['grid'], isA<List>());
      expect((json['grid'] as List).length, 3);
      expect(((json['grid'] as List)[0] as List).length, 3);

      final restored = PiratesGridGame.fromJson(json);
      expect(restored.grid.length, 3);
      expect(restored.grid[0].length, 3);
      expect(restored.grid[0][0].claimedBy, 'p1');
      expect(restored.grid[2][2].claimedBy, 'p2');
      expect(restored.grid[1][1].claimedBy, isNull);

      // Verify target numbers preserved
      expect(restored.grid[0][0].target.number, game.grid[0][0].target.number);
      expect(restored.grid[2][2].target.number, game.grid[2][2].target.number);
    });

    test('winningLine=null (no winner yet) round-trips', () {
      final game = _freshGame();
      expect(game.winningLine, isNull);

      final json = game.toJson();
      expect(json['winningLine'], isNull);

      final restored = PiratesGridGame.fromJson(json);
      expect(restored.winningLine, isNull);
    });

    test('winningLine length-3 list round-trips correctly', () {
      final game = _freshGame();
      game.winningLine = [
        const GridPosition(0, 0),
        const GridPosition(0, 1),
        const GridPosition(0, 2),
      ];

      final json = game.toJson();
      expect((json['winningLine'] as List).length, 3);

      final restored = PiratesGridGame.fromJson(json);
      expect(restored.winningLine!.length, 3);
      expect(restored.winningLine![0].row, 0);
      expect(restored.winningLine![0].col, 0);
      expect(restored.winningLine![2].row, 0);
      expect(restored.winningLine![2].col, 2);
    });

    test('mid-match Bo3 state with currentRound and currentRoundStartingPlayerIndex round-trips', () {
      final game = _freshGame(bestOf: 3);
      game.currentRound = 2;
      game.currentRoundStartingPlayerIndex = 1;
      game.currentPlayerIndex = 1;
      game.roundsWon['p1'] = 1;
      game.roundsWon['p2'] = 0;

      final json = game.toJson();
      final restored = PiratesGridGame.fromJson(json);

      expect(restored.currentRound, 2);
      expect(restored.currentRoundStartingPlayerIndex, 1);
      expect(restored.currentPlayerIndex, 1);
      expect(restored.roundsWon['p1'], 1);
      expect(restored.roundsWon['p2'], 0);
    });

    test('DateTime (startedAt and gameEndTime) serialize via ISO 8601', () {
      final fixedStart = DateTime(2026, 5, 1, 9, 0, 0);
      final fixedEnd = DateTime(2026, 5, 1, 9, 45, 0);
      final game = _freshGame();
      // startedAt is already set; override via a direct game creation
      final gameWithTimes = PiratesGridGame(
        id: 'time-test',
        startedAt: fixedStart,
        playerIds: ['p1', 'p2'],
        targetDifficulty: TargetDifficulty.easy,
        bestOf: 1,
        stealMode: false,
        speedPlay: false,
        grid: game.grid,
        state: GameState.finished,
        gameEndTime: fixedEnd,
      );

      final json = gameWithTimes.toJson();
      expect(json['startedAt'], fixedStart.toIso8601String());
      expect(json['gameEndTime'], fixedEnd.toIso8601String());

      final restored = PiratesGridGame.fromJson(json);
      expect(restored.startedAt, fixedStart);
      expect(restored.gameEndTime, fixedEnd);
    });
  });
}
