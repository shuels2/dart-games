import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/target_tag_game.dart';

void main() {
  group('TargetTagGame serialization - solo mode', () {
    TargetTagGame _createSoloGameWithState() {
      final game = TargetTagGame.createSolo(
        playerIds: ['p1', 'p2', 'p3'],
        shieldMax: 5,
        heroBonus: true,
      );
      // Simulate gameplay: p1 hits own target to build shields
      final p1Target = game.targetNumbers['p1']!;
      game.processDartHit('p1', p1Target, 'single');
      game.processDartHit('p1', p1Target, 'double');
      game.processMiss('p1');
      game.advanceToNextPlayer();
      // p2 hits own target
      final p2Target = game.targetNumbers['p2']!;
      game.processDartHit('p2', p2Target, 'triple');
      return game;
    }

    test('toJson includes all fields', () {
      final game = _createSoloGameWithState();
      final json = game.toJson();

      expect(json['id'], game.id);
      expect(json['mode'], 'solo');
      expect(json['shieldMax'], 5);
      expect(json['soloHeroBonus'], true);
      expect(json['startedAt'], game.startedAt.toIso8601String());
      expect(json['maxDartsPerTurn'], 3);
      expect(json['playerIds'], ['p1', 'p2', 'p3']);
      expect(json['targetNumbers'], isA<Map>());
      expect(json['soloHeroBuffNumbers'], isA<Map>());
      expect(json['soloHeroBuffMultipliers'], isA<Map>());
      expect(json['shields'], isA<Map>());
      expect(json['taggedIn'], isA<Map>());
      expect(json['eliminated'], isA<Map>());
      expect(json['dartsThrown'], isA<Map>());
      expect(json['totalDartsThrown'], isA<Map>());
      expect(json['totalTurns'], isA<Map>());
      expect(json['dartThrowTaggedInStatus'], isA<Map>());
      expect(json['dartThrowHeroBonusHit'], isA<Map>());
      expect(json['dartThrowReachedMax'], isA<Map>());
      expect(json['dartThrowCausedElimination'], isA<Map>());
      expect(json['dartThrowHitOpponentTarget'], isA<Map>());
      expect(json['state'], 'playing');
    });

    test('toJson serializes enums as .name strings', () {
      final game = _createSoloGameWithState();
      final json = game.toJson();

      expect(json['mode'], 'solo');
      expect(json['state'], 'playing');
      expect(json['turnStartState'], isA<String>());
      // Should NOT contain enum class prefix
      expect(json['mode'].toString().contains('.'), false);
      expect(json['state'].toString().contains('.'), false);
    });

    test('fromJson restores all basic fields', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.mode, GameMode.solo);
      expect(restored.shieldMax, 5);
      expect(restored.soloHeroBonus, true);
      expect(restored.startedAt, original.startedAt);
      expect(restored.maxDartsPerTurn, 3);
      expect(restored.playerIds, original.playerIds);
      expect(restored.targetNumbers, original.targetNumbers);
      expect(restored.state, original.state);
      expect(restored.currentPlayerIndex, original.currentPlayerIndex);
      expect(restored.winnerId, original.winnerId);
    });

    test('fromJson restores hero bonus assignments', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      expect(restored.soloHeroBuffNumbers, original.soloHeroBuffNumbers);
      expect(restored.soloHeroBuffMultipliers,
          original.soloHeroBuffMultipliers);
    });

    test('fromJson restores shields and status', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.shields[playerId], original.shields[playerId]);
        expect(restored.taggedIn[playerId], original.taggedIn[playerId]);
        expect(restored.eliminated[playerId], original.eliminated[playerId]);
      }
    });

    test('round-trip preserves totalDartsThrown and totalTurns', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      // p1 threw 3 darts, p2 threw 1
      expect(restored.totalDartsThrown['p1'], 3);
      expect(restored.totalDartsThrown['p2'], 1);
      expect(restored.totalTurns['p1'], 1);
      expect(restored.totalTurns['p2'], 1);
    });

    test('round-trip preserves dart throw tracking arrays', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      for (final playerId in original.playerIds) {
        expect(restored.dartThrowTaggedInStatus[playerId],
            original.dartThrowTaggedInStatus[playerId]);
        expect(restored.dartThrowHeroBonusHit[playerId],
            original.dartThrowHeroBonusHit[playerId]);
        expect(restored.dartThrowReachedMax[playerId],
            original.dartThrowReachedMax[playerId]);
        expect(restored.dartThrowCausedElimination[playerId],
            original.dartThrowCausedElimination[playerId]);
        expect(restored.dartThrowHitOpponentTarget[playerId],
            original.dartThrowHitOpponentTarget[playerId]);
      }
    });

    test('round-trip preserves turn start state', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      expect(restored.turnStartShields, original.turnStartShields);
      expect(restored.turnStartTaggedIn, original.turnStartTaggedIn);
      expect(restored.turnStartEliminated, original.turnStartEliminated);
      expect(restored.turnStartWinnerId, original.turnStartWinnerId);
      expect(restored.turnStartState, original.turnStartState);
    });

    test('round-trip with null winnerId', () {
      final game = TargetTagGame.createSolo(
        playerIds: ['p1', 'p2'],
        shieldMax: 3,
        heroBonus: false,
      );
      final json = game.toJson();
      final restored = TargetTagGame.fromJson(json);

      expect(restored.winnerId, isNull);
      expect(restored.soloHeroBuffNumbers, isNull);
      expect(restored.soloHeroBuffMultipliers, isNull);
    });

    test('gameplay continues correctly after restore', () {
      final original = _createSoloGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      // Continue gameplay
      final currentPlayerId = restored.getCurrentPlayerId();
      final dartsBefore = restored.dartsThrown[currentPlayerId]!;
      restored.processMiss(currentPlayerId);

      expect(restored.dartsThrown[currentPlayerId], dartsBefore + 1);
    });
  });

  group('TargetTagGame serialization - team mode', () {
    TargetTagGame _createTeamGameWithState() {
      final teams = {
        'team1': ['p1', 'p2'],
        'team2': ['p3', 'p4'],
      };
      final game = TargetTagGame.createTeam(
        teams: teams,
        shieldMax: 5,
        soloHeroBonus: false,
      );
      // Simulate some gameplay
      final firstPlayer = game.getCurrentPlayerId();
      final firstTarget = game.targetNumbers[firstPlayer]!;
      game.processDartHit(firstPlayer, firstTarget, 'single');
      return game;
    }

    test('toJson includes team fields', () {
      final game = _createTeamGameWithState();
      final json = game.toJson();

      expect(json['mode'], 'team');
      expect(json['playerToTeam'], isA<Map>());
      expect(json['teamPlayers'], isA<Map>());
      expect(json['teamIcons'], isA<Map>());
    });

    test('fromJson restores team mappings', () {
      final original = _createTeamGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      expect(restored.mode, GameMode.team);
      expect(restored.playerToTeam, original.playerToTeam);
      expect(restored.teamPlayers, isNotNull);
      expect(restored.teamPlayers!['team1'], original.teamPlayers!['team1']);
      expect(restored.teamPlayers!['team2'], original.teamPlayers!['team2']);
      expect(restored.teamIcons, original.teamIcons);
    });

    test('round-trip team game with gameplay', () {
      final original = _createTeamGameWithState();
      final json = original.toJson();
      final restored = TargetTagGame.fromJson(json);

      // Verify entity-based state (team shields)
      for (final teamId in original.teamPlayers!.keys) {
        expect(restored.shields[teamId], original.shields[teamId]);
        expect(restored.taggedIn[teamId], original.taggedIn[teamId]);
        expect(restored.eliminated[teamId], original.eliminated[teamId]);
      }
    });
  });
}
