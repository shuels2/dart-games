import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/reef_royale_game.dart';

void main() {
  group('ReefRoyaleGame serialization', () {
    ReefRoyaleGame _createGameWithState() {
      final game = ReefRoyaleGame.create(
        playerIds: ['p1', 'p2', 'p3'],
        gameMode: ReefRoyaleGameMode.standard,
        easyClaim: false,
        neighborNumbers: true,
        randomReefs: false,
        bonusBuffsEnabled: true,
        showHints: true,
        speedPlayEnabled: true,
        roundLimit: 8,
      );
      game.saveInitialTurnStartState();
      // Simulate gameplay: p1 hits target 20 (standard first target)
      game.processDart('p1', 20, 'single', resolvedTargets: [20]);
      game.processDart('p1', 20, 'double', resolvedTargets: [20]);
      game.processDart('p1', 20, 'triple', resolvedTargets: [20]);
      // p1 claimed 20 (3+2+1 = 6 >= 3 marks threshold)
      game.advanceToNextPlayer();
      // p2 hits a target
      game.processDart('p2', 19, 'single', resolvedTargets: [19]);
      return game;
    }

    test('toJson includes all fields', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['id'], game.id);
      expect(json['startedAt'], game.startedAt.toIso8601String());
      expect(json['maxDartsPerTurn'], 3);
      expect(json['gameMode'], 'standard');
      expect(json['easyClaim'], false);
      expect(json['neighborNumbers'], true);
      expect(json['randomReefs'], false);
      expect(json['bonusBuffsEnabled'], true);
      expect(json['showHints'], true);
      expect(json['speedPlayEnabled'], true);
      expect(json['roundLimit'], 8);
      expect(json['playerIds'], ['p1', 'p2', 'p3']);
      expect(json['creatureAssignments'], isA<Map>());
      expect(json['activeTargets'], isA<List>());
      expect(json['coralOrder'], isA<List>());
      expect(json['state'], 'playing');
      expect(json['marks'], isA<Map>());
      expect(json['claimed'], isA<Map>());
      expect(json['locked'], isA<List>());
      expect(json['pearls'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['turnStartMarks'], isA<Map>());
      expect(json['turnStartClaimed'], isA<Map>());
      expect(json['turnStartLocked'], isA<List>());
      expect(json['turnStartPearls'], isA<Map>());
    });

    test('toJson serializes enums as .name strings', () {
      final game = _createGameWithState();
      final json = game.toJson();

      expect(json['gameMode'], 'standard');
      expect(json['state'], 'playing');
      for (final value
          in (json['creatureAssignments'] as Map).values) {
        expect(SeaCreature.values.any((e) => e.name == value), true);
      }
    });

    test('toJson serializes Sets as Lists', () {
      final game = _createGameWithState();
      final json = game.toJson();

      // claimed is Map<String, Set<int>> → Map<String, List>
      expect(json['claimed']['p1'], isA<List>());
      // locked is Set<int> → List
      expect(json['locked'], isA<List>());
      // turnStartClaimed and turnStartLocked same pattern
      expect(json['turnStartLocked'], isA<List>());
    });

    test('toJson serializes marks with string keys', () {
      final game = _createGameWithState();
      final json = game.toJson();

      // marks is Map<String, Map<int, int>> → inner map keys become strings
      final p1Marks = json['marks']['p1'] as Map;
      for (final key in p1Marks.keys) {
        expect(key, isA<String>());
      }
    });

    test('fromJson restores all basic fields', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.startedAt, original.startedAt);
      expect(restored.maxDartsPerTurn, original.maxDartsPerTurn);
      expect(restored.gameMode, original.gameMode);
      expect(restored.easyClaim, original.easyClaim);
      expect(restored.neighborNumbers, original.neighborNumbers);
      expect(restored.randomReefs, original.randomReefs);
      expect(restored.bonusBuffsEnabled, original.bonusBuffsEnabled);
      expect(restored.showHints, original.showHints);
      expect(restored.speedPlayEnabled, original.speedPlayEnabled);
      expect(restored.roundLimit, original.roundLimit);
      expect(restored.playerIds, original.playerIds);
      expect(restored.activeTargets, original.activeTargets);
      expect(restored.coralOrder, original.coralOrder);
      expect(restored.state, original.state);
      expect(restored.currentPlayerIndex, original.currentPlayerIndex);
      expect(restored.currentRound, original.currentRound);
      expect(restored.turnsCompletedThisRound,
          original.turnsCompletedThisRound);
    });

    test('fromJson restores creature assignments', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.creatureAssignments, original.creatureAssignments);
    });

    test('fromJson restores marks (Map<String, Map<int, int>>)', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.marks[playerId], original.marks[playerId]);
      }
    });

    test('fromJson restores claimed Sets', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.claimed[playerId], original.claimed[playerId]);
      }
      // p1 should have claimed target 20
      expect(restored.claimed['p1']!.contains(20), true);
    });

    test('fromJson restores locked Set', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.locked, original.locked);
    });

    test('round-trip preserves totalDartsThrown and totalTurns', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      // p1 threw 3 darts, p2 threw 1
      expect(restored.totalDartsThrown['p1'], 3);
      expect(restored.totalDartsThrown['p2'], 1);
      expect(restored.totalTurns['p1'], 1);
      expect(restored.totalTurns['p2'], 1);
    });

    test('round-trip preserves pearls', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.pearls, original.pearls);
    });

    test('round-trip preserves dart throw tracking arrays', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.dartThrowMarksAdded[playerId],
            original.dartThrowMarksAdded[playerId]);
        expect(restored.dartThrowPearlsScored[playerId],
            original.dartThrowPearlsScored[playerId]);
        expect(restored.dartThrowClaimedCoral[playerId],
            original.dartThrowClaimedCoral[playerId]);
        expect(restored.dartThrowLockedReef[playerId],
            original.dartThrowLockedReef[playerId]);
        expect(restored.dartThrowTargetNumber[playerId],
            original.dartThrowTargetNumber[playerId]);
        expect(restored.dartThrowIsNeighbor[playerId],
            original.dartThrowIsNeighbor[playerId]);
        expect(restored.dartThrowPearlRecipientId[playerId],
            original.dartThrowPearlRecipientId[playerId]);
        expect(restored.dartThrowTargetCount[playerId],
            original.dartThrowTargetCount[playerId]);
      }
    });

    test('round-trip preserves turn start state', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.turnStartMarks[playerId],
            original.turnStartMarks[playerId]);
        expect(restored.turnStartClaimed[playerId],
            original.turnStartClaimed[playerId]);
      }
      expect(restored.turnStartLocked, original.turnStartLocked);
      expect(restored.turnStartPearls, original.turnStartPearls);
      expect(restored.turnStartState, original.turnStartState);
      expect(restored.turnStartWinnerId, original.turnStartWinnerId);
      expect(restored.turnStartWinnerIds, original.turnStartWinnerIds);
    });

    test('round-trip with null winner', () {
      final game = ReefRoyaleGame.create(
        playerIds: ['p1', 'p2'],
        gameMode: ReefRoyaleGameMode.cursedTide,
        easyClaim: true,
        neighborNumbers: false,
        randomReefs: false,
        bonusBuffsEnabled: false,
        showHints: false,
        speedPlayEnabled: false,
        roundLimit: 10,
      );
      game.saveInitialTurnStartState();
      final json = game.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.winnerId, isNull);
      expect(restored.winnerIds, isNull);
      expect(restored.gameMode, ReefRoyaleGameMode.cursedTide);
      expect(restored.easyClaim, true);
    });

    test('round-trip with activeBuff', () {
      final game = _createGameWithState();
      game.activeBuff = ReefBuff.pearlFever;
      final json = game.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.activeBuff, ReefBuff.pearlFever);
    });

    test('round-trip with null activeBuff', () {
      final game = _createGameWithState();
      game.activeBuff = null;
      final json = game.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.activeBuff, isNull);
    });

    test('gameplay continues correctly after restore', () {
      final original = _createGameWithState();
      final json = original.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      // Continue gameplay
      final currentPlayerId = restored.getCurrentPlayerId();
      final dartsBefore = restored.dartsThrown[currentPlayerId]!;
      restored.processMiss(currentPlayerId);

      expect(restored.dartsThrown[currentPlayerId], dartsBefore + 1);
    });

    test('round-trip with empty claimed sets', () {
      final game = ReefRoyaleGame.create(
        playerIds: ['p1', 'p2'],
        gameMode: ReefRoyaleGameMode.standard,
        easyClaim: false,
        neighborNumbers: false,
        randomReefs: false,
        bonusBuffsEnabled: false,
        showHints: false,
        speedPlayEnabled: false,
        roundLimit: 10,
      );
      game.saveInitialTurnStartState();
      final json = game.toJson();
      final restored = ReefRoyaleGame.fromJson(json);

      expect(restored.claimed['p1'], isEmpty);
      expect(restored.claimed['p2'], isEmpty);
      expect(restored.locked, isEmpty);
    });
  });
}
