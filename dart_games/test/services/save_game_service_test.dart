import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/save_game_service.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late SaveGameService service;

  setUp(() {
    mockServer = MockApiServer();
    service = SaveGameService(mockServer.apiClient);
  });

  SavedGameMetadata _createMetadata({
    String gameType = 'carnival_derby',
    String? id,
  }) {
    return SavedGameMetadata(
      id: id ?? 'test-id-${DateTime.now().millisecondsSinceEpoch}',
      gameType: gameType,
      savedAt: DateTime.now(),
      playerNames: ['Alice', 'Bob'],
      progressInfo: 'Leading: 120 pts',
      gameModeName: 'Target: 301',
      leadingPlayerName: 'Alice',
      leadingPlayerScore: '120 pts',
      gameState: {
        'id': 'game-1',
        'playerIds': ['p1', 'p2'],
        'scores': {'p1': 120, 'p2': 85},
      },
      waitingForTakeout: true,
    );
  }

  group('SaveGameService', () {
    test('save and load round-trip', () async {
      final metadata = _createMetadata(id: 'save-1');
      await service.saveGame(metadata);

      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, hasLength(1));
      expect(loaded[0].id, 'save-1');
      expect(loaded[0].gameType, 'carnival_derby');
      expect(loaded[0].playerNames, ['Alice', 'Bob']);
      expect(loaded[0].progressInfo, 'Leading: 120 pts');
      expect(loaded[0].gameModeName, 'Target: 301');
      expect(loaded[0].leadingPlayerName, 'Alice');
      expect(loaded[0].leadingPlayerScore, '120 pts');
      expect(loaded[0].waitingForTakeout, true);
      expect(loaded[0].gameState['scores'], {'p1': 120, 'p2': 85});
    });

    test('multiple saves accumulate', () async {
      await service.saveGame(_createMetadata(id: 'save-1'));
      await service.saveGame(_createMetadata(id: 'save-2'));
      await service.saveGame(_createMetadata(id: 'save-3'));

      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, hasLength(3));
    });

    test('loadSavedGames returns empty list when no saves', () async {
      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, isEmpty);
    });

    test('deleteSavedGame removes by ID', () async {
      await service.saveGame(_createMetadata(id: 'keep-1'));
      await service.saveGame(_createMetadata(id: 'delete-me'));
      await service.saveGame(_createMetadata(id: 'keep-2'));

      await service.deleteSavedGame('carnival_derby', 'delete-me');

      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, hasLength(2));
      expect(loaded.any((m) => m.id == 'delete-me'), false);
      expect(loaded.any((m) => m.id == 'keep-1'), true);
      expect(loaded.any((m) => m.id == 'keep-2'), true);
    });

    test('deleteAllSavedGames clears all for game type', () async {
      await service.saveGame(_createMetadata(id: 'save-1'));
      await service.saveGame(_createMetadata(id: 'save-2'));

      await service.deleteAllSavedGames('carnival_derby');

      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, isEmpty);
    });

    test('hasSavedGames returns true when saves exist', () async {
      expect(await service.hasSavedGames('carnival_derby'), false);

      await service.saveGame(_createMetadata());

      expect(await service.hasSavedGames('carnival_derby'), true);
    });

    test('hasSavedGames returns false after deleteAll', () async {
      await service.saveGame(_createMetadata());
      await service.deleteAllSavedGames('carnival_derby');

      expect(await service.hasSavedGames('carnival_derby'), false);
    });

    test('game types are independent', () async {
      await service.saveGame(
          _createMetadata(gameType: 'carnival_derby', id: 'cd-1'));
      await service.saveGame(
          _createMetadata(gameType: 'target_tag', id: 'tt-1'));
      await service.saveGame(
          _createMetadata(gameType: 'monster_mash', id: 'mm-1'));

      expect(await service.loadSavedGames('carnival_derby'), hasLength(1));
      expect(await service.loadSavedGames('target_tag'), hasLength(1));
      expect(await service.loadSavedGames('monster_mash'), hasLength(1));
      expect(await service.loadSavedGames('reef_royale'), isEmpty);

      // Deleting one game type doesn't affect others
      await service.deleteAllSavedGames('carnival_derby');
      expect(await service.loadSavedGames('carnival_derby'), isEmpty);
      expect(await service.loadSavedGames('target_tag'), hasLength(1));
    });

    test('savedAt is preserved through round-trip', () async {
      final savedAt = DateTime(2024, 6, 15, 14, 30, 0);
      final metadata = SavedGameMetadata(
        id: 'time-test',
        gameType: 'carnival_derby',
        savedAt: savedAt,
        playerNames: ['Alice'],
        progressInfo: 'Leading: 50 pts',
        gameModeName: 'Target: 100',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '50 pts',
        gameState: {'id': 'g1'},
      );
      await service.saveGame(metadata);

      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded[0].savedAt, savedAt);
    });

    test('delete non-existent ID is safe', () async {
      await service.saveGame(_createMetadata(id: 'existing'));
      await service.deleteSavedGame('carnival_derby', 'non-existent');

      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, hasLength(1));
      expect(loaded[0].id, 'existing');
    });

    test('deleteAll on empty game type is safe', () async {
      await service.deleteAllSavedGames('carnival_derby');
      final loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, isEmpty);
    });

    test('saving with same ID overwrites instead of duplicating', () async {
      await service.saveGame(_createMetadata(id: 'game-1'));
      await service.saveGame(_createMetadata(id: 'game-2'));

      var loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, hasLength(2));

      // Save again with same ID as game-1 (simulates resumed game re-save)
      final updated = SavedGameMetadata(
        id: 'game-1',
        gameType: 'carnival_derby',
        savedAt: DateTime.now(),
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Leading: 200 pts',
        gameModeName: 'Target: 301',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '200 pts',
        gameState: {'id': 'game-1', 'playerIds': ['p1', 'p2'], 'scores': {'p1': 200, 'p2': 85}},
      );
      await service.saveGame(updated);

      loaded = await service.loadSavedGames('carnival_derby');
      expect(loaded, hasLength(2)); // Still 2, not 3
      final overwritten = loaded.firstWhere((m) => m.id == 'game-1');
      expect(overwritten.progressInfo, 'Leading: 200 pts');
      expect(overwritten.gameState['scores']['p1'], 200);
    });

    test('complex gameState survives round-trip', () async {
      final metadata = SavedGameMetadata(
        id: 'complex-test',
        gameType: 'reef_royale',
        savedAt: DateTime.now(),
        playerNames: ['Alice', 'Bob', 'Charlie'],
        progressInfo: 'Round 3',
        gameModeName: 'Standard',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '4/7 corals',
        gameState: {
          'marks': {
            'p1': {'20': 3, '19': 1},
            'p2': {'20': 0, '19': 2},
          },
          'claimed': {
            'p1': [20],
            'p2': [],
          },
          'locked': [],
          'nullableField': null,
        },
      );
      await service.saveGame(metadata);

      final loaded = await service.loadSavedGames('reef_royale');
      expect(loaded[0].gameState['marks']['p1']['20'], 3);
      expect(loaded[0].gameState['claimed']['p1'], [20]);
      expect(loaded[0].gameState['nullableField'], isNull);
    });
  });
}
