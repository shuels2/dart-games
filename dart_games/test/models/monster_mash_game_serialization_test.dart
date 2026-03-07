import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/monster_mash_game.dart';

void main() {
  group('MonsterMashGame serialization', () {
    MonsterMashGame _createGameWithState() {
      final game = MonsterMashGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        healthMax: 20,
        bonusBuffsEnabled: true,
        speedPlayEnabled: true,
        roundLimit: 5,
      );
      game.saveInitialTurnStartState();
      // Simulate gameplay: p1 hits p2's target
      final p2Target = game.targetNumbers['p2']!;
      game.processDartHit('p1', p2Target, 'double');
      game.processMiss('p1');
      // p1 heals by hitting own target
      final p1Target = game.targetNumbers['p1']!;
      game.processDartHit('p1', p1Target, 'single');
      game.advanceToNextPlayer();
      // p2 throws one dart
      game.processMiss('p2');
      return game;
    }

    test('toJson includes all fields', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['id'], game.id);
      expect(json['startedAt'], game.startedAt.toIso8601String());
      expect(json['maxDartsPerTurn'], 3);
      expect(json['healthMax'], 20);
      expect(json['bonusBuffsEnabled'], true);
      expect(json['speedPlayEnabled'], true);
      expect(json['roundLimit'], 5);
      expect(json['playerIds'], ['p1', 'p2', 'p3']);
      expect(json['targetNumbers'], isA<Map>());
      expect(json['monsterAssignments'], isA<Map>());
      expect(json['state'], 'playing');
      expect(json['health'], isA<Map>());
      expect(json['eliminated'], isA<Map>());
      expect(json['currentRound'], isA<int>());
      expect(json['turnsCompletedThisRound'], isA<int>());
      expect(json['dartsThrown'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['totalDamageDealt'], isA<Map>());
      expect(json['dartThrowHealAmount'], isA<Map>());
      expect(json['dartThrowDamageDealt'], isA<Map>());
      expect(json['dartThrowTargetPlayerId'], isA<Map>());
      expect(json['turnStartHealth'], isA<Map>());
      expect(json['turnStartEliminated'], isA<Map>());
      expect(json['turnStartState'], isA<String>());
      expect(json['turnStartTotalDamageDealt'], isA<Map>());
    });

    test('toJson serializes enums as .name strings', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['state'], 'playing');
      // Monster assignments should be enum names
      for (final value in (json['monsterAssignments'] as Map).values) {
        expect(MonsterType.values.any((e) => e.name == value), true);
      }
    });

    test('toJson serializes activeBuff correctly', () {
      final game = _createGameWithState();
      // Manually set a buff for testing
      game.activeBuff = BonusBuff.bloodMoon;
      final json = game.toJson();
      expect(json['activeBuff'], 'bloodMoon');

      // Test null buff
      game.activeBuff = null;
      final json2 = game.toJson();
      expect(json2['activeBuff'], isNull);
    });

    test('fromJson restores all basic fields', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.startedAt, original.startedAt);
      expect(restored.maxDartsPerTurn, original.maxDartsPerTurn);
      expect(restored.healthMax, original.healthMax);
      expect(restored.bonusBuffsEnabled, original.bonusBuffsEnabled);
      expect(restored.speedPlayEnabled, original.speedPlayEnabled);
      expect(restored.roundLimit, original.roundLimit);
      expect(restored.playerIds, original.playerIds);
      expect(restored.targetNumbers, original.targetNumbers);
      expect(restored.state, original.state);
      expect(restored.currentPlayerIndex, original.currentPlayerIndex);
      expect(restored.currentRound, original.currentRound);
      expect(restored.turnsCompletedThisRound,
          original.turnsCompletedThisRound);
    });

    test('fromJson restores monster assignments', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      expect(restored.monsterAssignments, original.monsterAssignments);
    });

    test('fromJson restores health and elimination', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.health[playerId], original.health[playerId]);
        expect(restored.eliminated[playerId], original.eliminated[playerId]);
      }
    });

    test('round-trip preserves totalDartsThrown and totalTurns', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      // p1 threw 3 darts, p2 threw 1
      expect(restored.totalDartsThrown['p1'], 3);
      expect(restored.totalDartsThrown['p2'], 1);
      expect(restored.totalTurns['p1'], 1);
      expect(restored.totalTurns['p2'], 1);
    });

    test('round-trip preserves totalDamageDealt', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      expect(restored.totalDamageDealt, original.totalDamageDealt);
    });

    test('round-trip preserves dart throw tracking arrays', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.dartThrowHealAmount[playerId],
            original.dartThrowHealAmount[playerId]);
        expect(restored.dartThrowDamageDealt[playerId],
            original.dartThrowDamageDealt[playerId]);
        expect(restored.dartThrowTargetPlayerId[playerId],
            original.dartThrowTargetPlayerId[playerId]);
      }
    });

    test('round-trip preserves turn start state', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      expect(restored.turnStartHealth, original.turnStartHealth);
      expect(restored.turnStartEliminated, original.turnStartEliminated);
      expect(restored.turnStartState, original.turnStartState);
      expect(restored.turnStartWinnerId, original.turnStartWinnerId);
      expect(restored.turnStartWinnerIds, original.turnStartWinnerIds);
      expect(restored.turnStartTotalDamageDealt,
          original.turnStartTotalDamageDealt);
    });

    test('round-trip with null winner', () {
      final game = MonsterMashGame.create(
        playerIds: ['p1', 'p2'],
        healthMax: 10,
        bonusBuffsEnabled: false,
        speedPlayEnabled: false,
        roundLimit: 10,
      );
      game.saveInitialTurnStartState();
      final json = game.toJson();
      final restored = MonsterMashGame.fromJson(json);

      expect(restored.winnerId, isNull);
      expect(restored.winnerIds, isNull);
    });

    test('round-trip with activeBuff', () {
      final game = _createGameWithState();
      game.activeBuff = BonusBuff.shadowWalk;
      final json = game.toJson();
      final restored = MonsterMashGame.fromJson(json);

      expect(restored.activeBuff, BonusBuff.shadowWalk);
    });

    test('gameplay continues correctly after restore', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = MonsterMashGame.fromJson(json);

      // Continue gameplay
      final currentPlayerId = restored.getCurrentPlayerId();
      final dartsBefore = restored.dartsThrown[currentPlayerId]!;
      restored.processMiss(currentPlayerId);

      expect(restored.dartsThrown[currentPlayerId], dartsBefore + 1);
    });
  });
}
