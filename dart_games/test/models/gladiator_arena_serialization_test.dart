import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/gladiator_arena_game.dart';

void main() {
  group('GladiatorArenaGame serialization', () {
    // ──────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────

    GladiatorArenaGame _defaultGame() {
      return GladiatorArenaGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );
    }

    // ──────────────────────────────────────────────────────────────
    // 1. Default game state round-trip
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves default game state', () {
      final original = _defaultGame();
      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.startedAt, equals(original.startedAt));
      expect(restored.endedAt, isNull);
      expect(restored.playerIds, equals(original.playerIds));
      expect(restored.targetScore, equals(200));
      expect(restored.doubleFinishEnabled, isTrue);
      expect(restored.shieldRoundEnabled, isFalse);
      expect(restored.speedPlayEnabled, isFalse);
      expect(restored.state, equals(GladiatorArenaGameState.playing));
      expect(restored.currentPlayerIndex, equals(0));
      expect(restored.winnerId, isNull);
      expect(restored.round, equals(1));
    });

    // ──────────────────────────────────────────────────────────────
    // 2. Mid-game state: scores, dartsThrown, currentTurnDartValues,
    //    currentTurnDartSegments
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves mid-game dart state', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        targetScore: 300,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );

      // Simulate p1 mid-turn: 2 darts thrown
      original.scores['p1'] = 45;
      original.scores['p2'] = 20;
      original.scores['p3'] = 0;
      original.dartsThrown['p1'] = 2;
      original.totalDartsThrown['p1'] = 8;
      original.totalDartsThrown['p2'] = 6;
      original.totalTurns['p1'] = 3;
      original.totalTurns['p2'] = 2;
      original.currentTurnDartValues['p1'] = [20, 40];
      original.currentTurnDartSegments['p1'] = ['S20', 'D20'];
      original.round = 3;

      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.scores['p1'], equals(45));
      expect(restored.scores['p2'], equals(20));
      expect(restored.scores['p3'], equals(0));
      expect(restored.dartsThrown['p1'], equals(2));
      expect(restored.totalDartsThrown['p1'], equals(8));
      expect(restored.totalDartsThrown['p2'], equals(6));
      expect(restored.totalTurns['p1'], equals(3));
      expect(restored.totalTurns['p2'], equals(2));
      expect(restored.currentTurnDartValues['p1'], equals([20, 40]));
      expect(restored.currentTurnDartSegments['p1'], equals(['S20', 'D20']));
      expect(restored.round, equals(3));
      expect(restored.currentPlayerIndex, equals(original.currentPlayerIndex));
    });

    // ──────────────────────────────────────────────────────────────
    // 3. Knockoff fields: knockoffsDealt, knockoffsReceived,
    //    lastKnockoffVictimId, lastKnockoffAttackerId, lastKnockoffAt
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves knockoff stats', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );

      original.knockoffsDealt['p1'] = 3;
      original.knockoffsDealt['p2'] = 1;
      original.knockoffsReceived['p2'] = 2;
      original.knockoffsReceived['p3'] = 2;
      original.lastKnockoffVictimId = 'p3';
      original.lastKnockoffAttackerId = 'p1';
      original.lastKnockoffAt = DateTime(2026, 5, 9, 14, 30, 0);

      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.knockoffsDealt['p1'], equals(3));
      expect(restored.knockoffsDealt['p2'], equals(1));
      expect(restored.knockoffsReceived['p2'], equals(2));
      expect(restored.knockoffsReceived['p3'], equals(2));
      expect(restored.lastKnockoffVictimId, equals('p3'));
      expect(restored.lastKnockoffAttackerId, equals('p1'));
      expect(restored.lastKnockoffAt, equals(DateTime(2026, 5, 9, 14, 30, 0)));
    });

    test('round-trip preserves null lastKnockoff fields', () {
      final original = _defaultGame();
      // All lastKnockoff* fields are null by default
      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.lastKnockoffVictimId, isNull);
      expect(restored.lastKnockoffAttackerId, isNull);
      expect(restored.lastKnockoffAt, isNull);
    });

    // ──────────────────────────────────────────────────────────────
    // 4. All options enabled: targetScore 350, DF ON, Shield ON, Speed ON
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves all options enabled', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 350,
        doubleFinishEnabled: true,
        shieldRoundEnabled: true,
        speedPlayEnabled: true,
      );

      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.targetScore, equals(350));
      expect(restored.doubleFinishEnabled, isTrue);
      expect(restored.shieldRoundEnabled, isTrue);
      expect(restored.speedPlayEnabled, isTrue);
    });

    // ──────────────────────────────────────────────────────────────
    // 5. Speed Play time remaining
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves speedPlayTimeRemaining', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: true,
      );
      original.speedPlayTimeRemaining = 17;

      final restored = GladiatorArenaGame.fromJson(original.toJson());
      expect(restored.speedPlayTimeRemaining, equals(17));
    });

    test('round-trip preserves null speedPlayTimeRemaining', () {
      final original = _defaultGame();
      // speedPlayEnabled=false → speedPlayTimeRemaining null by default
      final restored = GladiatorArenaGame.fromJson(original.toJson());
      expect(restored.speedPlayTimeRemaining, isNull);
    });

    // ──────────────────────────────────────────────────────────────
    // 6. playerCharacterPaths populated (8-player game)
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves playerCharacterPaths for 8 players', () {
      final ids = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'];
      final paths = {
        'p1': 'assets/games/gladiator_arena/characters/gladiator_1.png',
        'p2': 'assets/games/gladiator_arena/characters/gladiator_2.png',
        'p3': 'assets/games/gladiator_arena/characters/gladiator_3.png',
        'p4': 'assets/games/gladiator_arena/characters/gladiator_4.png',
        'p5': 'assets/games/gladiator_arena/characters/gladiator_5.png',
        'p6': 'assets/games/gladiator_arena/characters/gladiator_6.png',
        'p7': 'assets/games/gladiator_arena/characters/gladiator_7.png',
        'p8': 'assets/games/gladiator_arena/characters/gladiator_8.png',
      };

      final original = GladiatorArenaGame.create(
        playerIds: ids,
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        playerCharacterPaths: paths,
      );

      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.playerIds, equals(ids));
      expect(restored.playerCharacterPaths.length, equals(8));
      for (final id in ids) {
        expect(restored.playerCharacterPaths[id], equals(paths[id]));
      }
    });

    test('round-trip preserves empty playerCharacterPaths', () {
      final original = _defaultGame();
      // No character paths assigned
      final restored = GladiatorArenaGame.fromJson(original.toJson());
      expect(restored.playerCharacterPaths, isEmpty);
    });

    // ──────────────────────────────────────────────────────────────
    // 7. Finished game: winnerId, state=finished, endedAt
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves finished game state with winnerId and endedAt',
        () {
      final endTime = DateTime(2026, 5, 9, 15, 0, 0);
      final original = GladiatorArenaGame(
        id: 'game-finished-id',
        startedAt: DateTime(2026, 5, 9, 14, 0, 0),
        endedAt: endTime,
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        state: GladiatorArenaGameState.finished,
        currentPlayerIndex: 0,
        winnerId: 'p1',
        scores: {'p1': 200, 'p2': 85},
        round: 7,
      );

      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.state, equals(GladiatorArenaGameState.finished));
      expect(restored.winnerId, equals('p1'));
      expect(restored.endedAt, equals(endTime));
      expect(restored.scores['p1'], equals(200));
      expect(restored.scores['p2'], equals(85));
      expect(restored.round, equals(7));
    });

    // ──────────────────────────────────────────────────────────────
    // 8. State enum round-trips as string (no dot-prefix)
    // ──────────────────────────────────────────────────────────────

    test('toJson serializes state enum as plain string', () {
      final game = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );
      final json = game.toJson();

      expect(json['state'], equals('playing'));
      expect(json['state'].toString().contains('.'), isFalse);
    });

    test('fromJson restores finished state from string "finished"', () {
      final game = GladiatorArenaGame(
        id: 'state-test',
        startedAt: DateTime(2026, 1, 1),
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        state: GladiatorArenaGameState.finished,
        winnerId: 'p1',
      );
      final json = game.toJson();
      expect(json['state'], equals('finished'));

      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.state, equals(GladiatorArenaGameState.finished));
    });

    // ──────────────────────────────────────────────────────────────
    // 9. DateTime ISO 8601 round-trip
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves DateTime fields via ISO 8601', () {
      final fixed = DateTime(2026, 5, 9, 10, 30, 0);
      final endFixed = DateTime(2026, 5, 9, 11, 0, 0);
      final knockoffFixed = DateTime(2026, 5, 9, 10, 45, 0);

      final game = GladiatorArenaGame(
        id: 'dt-test',
        startedAt: fixed,
        endedAt: endFixed,
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        state: GladiatorArenaGameState.finished,
        winnerId: 'p1',
        lastKnockoffAt: knockoffFixed,
      );

      final json = game.toJson();
      expect(json['startedAt'], equals(fixed.toIso8601String()));
      expect(json['endedAt'], equals(endFixed.toIso8601String()));
      expect(json['lastKnockoffAt'], equals(knockoffFixed.toIso8601String()));

      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.startedAt, equals(fixed));
      expect(restored.endedAt, equals(endFixed));
      expect(restored.lastKnockoffAt, equals(knockoffFixed));
    });

    // ──────────────────────────────────────────────────────────────
    // 10. toJson includes all expected keys
    // ──────────────────────────────────────────────────────────────

    test('toJson includes all expected keys', () {
      final game = _defaultGame();
      final json = game.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('startedAt'), isTrue);
      expect(json.containsKey('endedAt'), isTrue);
      expect(json.containsKey('playerIds'), isTrue);
      expect(json.containsKey('targetScore'), isTrue);
      expect(json.containsKey('doubleFinishEnabled'), isTrue);
      expect(json.containsKey('shieldRoundEnabled'), isTrue);
      expect(json.containsKey('speedPlayEnabled'), isTrue);
      expect(json.containsKey('state'), isTrue);
      expect(json.containsKey('currentPlayerIndex'), isTrue);
      expect(json.containsKey('winnerId'), isTrue);
      expect(json.containsKey('scores'), isTrue);
      expect(json.containsKey('dartsThrown'), isTrue);
      expect(json.containsKey('totalDartsThrown'), isTrue);
      expect(json.containsKey('totalTurns'), isTrue);
      expect(json.containsKey('currentTurnDartValues'), isTrue);
      expect(json.containsKey('currentTurnDartSegments'), isTrue);
      expect(json.containsKey('knockoffsDealt'), isTrue);
      expect(json.containsKey('knockoffsReceived'), isTrue);
      expect(json.containsKey('round'), isTrue);
      expect(json.containsKey('lastKnockoffVictimId'), isTrue);
      expect(json.containsKey('lastKnockoffAttackerId'), isTrue);
      expect(json.containsKey('lastKnockoffAt'), isTrue);
      expect(json.containsKey('speedPlayTimeRemaining'), isTrue);
      expect(json.containsKey('playerCharacterPaths'), isTrue);
    });

    // ──────────────────────────────────────────────────────────────
    // 11. Full JSON equality round-trip
    // ──────────────────────────────────────────────────────────────

    test('toJson → fromJson → toJson produces identical JSON', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        targetScore: 250,
        doubleFinishEnabled: true,
        shieldRoundEnabled: true,
        speedPlayEnabled: true,
        playerCharacterPaths: {
          'p1': 'assets/games/gladiator_arena/characters/gladiator_1.png',
          'p2': 'assets/games/gladiator_arena/characters/gladiator_2.png',
          'p3': 'assets/games/gladiator_arena/characters/gladiator_3.png',
        },
      );
      original.scores['p1'] = 100;
      original.scores['p2'] = 75;
      original.knockoffsDealt['p1'] = 1;
      original.knockoffsReceived['p2'] = 1;
      original.round = 4;
      original.currentTurnDartValues['p1'] = [20];
      original.currentTurnDartSegments['p1'] = ['S20'];
      original.dartsThrown['p1'] = 1;
      original.speedPlayTimeRemaining = 20;

      final json1 = original.toJson();
      final restored = GladiatorArenaGame.fromJson(json1);
      final json2 = restored.toJson();

      expect(json2, equals(json1));
    });

    // ──────────────────────────────────────────────────────────────
    // 12. Multi-dart turn values and segments list deep equality
    // ──────────────────────────────────────────────────────────────

    test('round-trip preserves currentTurnDartValues and currentTurnDartSegments lists', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );

      original.currentTurnDartValues['p1'] = [20, 40, 0];
      original.currentTurnDartSegments['p1'] = ['S20', 'D20', 'Miss'];
      original.dartsThrown['p1'] = 3;

      // p2 hasn't thrown yet this turn
      original.currentTurnDartValues['p2'] = [];
      original.currentTurnDartSegments['p2'] = [];

      final restored = GladiatorArenaGame.fromJson(original.toJson());

      expect(restored.currentTurnDartValues['p1'], equals([20, 40, 0]));
      expect(restored.currentTurnDartSegments['p1'], equals(['S20', 'D20', 'Miss']));
      expect(restored.dartsThrown['p1'], equals(3));
      expect(restored.currentTurnDartValues['p2'], equals([]));
      expect(restored.currentTurnDartSegments['p2'], equals([]));
    });

    // ──────────────────────────────────────────────────────────────
    // 13. Player map initialization on fromJson (no missing keys)
    // ──────────────────────────────────────────────────────────────

    test('fromJson initializes all player map keys from playerIds', () {
      final original = GladiatorArenaGame.create(
        playerIds: ['a', 'b', 'c'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );
      final restored = GladiatorArenaGame.fromJson(original.toJson());

      for (final id in ['a', 'b', 'c']) {
        expect(restored.scores.containsKey(id), isTrue);
        expect(restored.dartsThrown.containsKey(id), isTrue);
        expect(restored.totalDartsThrown.containsKey(id), isTrue);
        expect(restored.totalTurns.containsKey(id), isTrue);
        expect(restored.currentTurnDartValues.containsKey(id), isTrue);
        expect(restored.currentTurnDartSegments.containsKey(id), isTrue);
        expect(restored.knockoffsDealt.containsKey(id), isTrue);
        expect(restored.knockoffsReceived.containsKey(id), isTrue);
      }
    });
  });
}
