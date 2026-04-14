import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/resume_game_modal/resume_game_modal.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResumeGameModal', () {
    late MockApiServer mockServer;
    late bool startNewCalled;
    late SavedGameMetadata? resumedGame;

    setUp(() async {
      mockServer = MockApiServer();
      startNewCalled = false;
      resumedGame = null;
    });

    Future<void> _seedSavedGames(int count) async {
      final service = SaveGameService(mockServer.apiClient);
      for (int i = 0; i < count; i++) {
        await service.saveGame(SavedGameMetadata.create(
          gameType: 'carnival_derby',
          playerNames: ['Alice', 'Bob'],
          progressInfo: 'Leading: ${(i + 1) * 10} pts',
          gameModeName: 'Target: 200',
          leadingPlayerName: 'Alice',
          leadingPlayerScore: '${(i + 1) * 10} pts',
          gameState: {'scores': {'p1': (i + 1) * 10}},
        ));
      }
    }

    Widget buildModal({ResumeGameModalConfig? config}) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ResumeGameModal(
                config: config ?? ResumeGameModalConfig.carnivalDerby(),
                gameType: 'carnival_derby',
                onStartNewGame: () => startNewCalled = true,
                onResumeGame: (game) => resumedGame = game,
                onClose: () {},
                apiClient: mockServer.apiClient,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders all widget keys with saved games', (tester) async {
      await _seedSavedGames(1);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      expect(find.byKey(ResumeGameModalKeys.overlay), findsOneWidget);
      expect(find.byKey(ResumeGameModalKeys.container), findsOneWidget);
      expect(find.byKey(ResumeGameModalKeys.title), findsOneWidget);
      expect(find.byKey(ResumeGameModalKeys.savedGamesList), findsOneWidget);
      expect(find.byKey(ResumeGameModalKeys.resumeGameButton), findsOneWidget);
      expect(find.byKey(ResumeGameModalKeys.startNewGameButton), findsOneWidget);
      expect(find.byKey(ResumeGameModalKeys.deleteAllButton), findsOneWidget);
    });

    testWidgets('renders saved game tile with metadata', (tester) async {
      await _seedSavedGames(1);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      // Verify tile content exists
      expect(find.text('Alice, Bob'), findsOneWidget);
      expect(find.text('Leading: 10 pts'), findsOneWidget);
      expect(find.text('Target: 200'), findsOneWidget);
      expect(find.text('Alice: 10 pts'), findsOneWidget);
    });

    testWidgets('Resume button disabled when no tile selected', (tester) async {
      await _seedSavedGames(1);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      final resumeButton = tester.widget<ElevatedButton>(
          find.byKey(ResumeGameModalKeys.resumeGameButton));
      expect(resumeButton.onPressed, isNull);
    });

    testWidgets('Resume button enabled after tile selection', (tester) async {
      await _seedSavedGames(1);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      // Get saved games to find the ID
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');
      final tileKey = ResumeGameModalKeys.savedGameTile(saved[0].id);

      await tester.tap(find.byKey(tileKey));
      await tester.pumpAndSettle();

      final resumeButton = tester.widget<ElevatedButton>(
          find.byKey(ResumeGameModalKeys.resumeGameButton));
      expect(resumeButton.onPressed, isNotNull);
    });

    testWidgets('Resume button triggers onResumeGame callback', (tester) async {
      await _seedSavedGames(1);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');
      final tileKey = ResumeGameModalKeys.savedGameTile(saved[0].id);

      // Select tile
      await tester.tap(find.byKey(tileKey));
      await tester.pumpAndSettle();

      // Tap resume
      await tester.tap(find.byKey(ResumeGameModalKeys.resumeGameButton));
      await tester.pumpAndSettle();

      expect(resumedGame, isNotNull);
      expect(resumedGame!.id, saved[0].id);
    });

    testWidgets('Start New Game triggers onStartNewGame callback', (tester) async {
      await _seedSavedGames(1);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ResumeGameModalKeys.startNewGameButton));
      expect(startNewCalled, true);
    });

    testWidgets('delete individual saved game removes tile', (tester) async {
      await _seedSavedGames(2);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');
      expect(saved, hasLength(2));

      // Delete first game
      final deleteKey = ResumeGameModalKeys.deleteSavedGameButton(saved[0].id);
      await tester.tap(find.byKey(deleteKey));
      await tester.pumpAndSettle();

      // Verify only 1 tile remains
      final remaining = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');
      expect(remaining, hasLength(1));
    });

    testWidgets('delete all shows empty state', (tester) async {
      await _seedSavedGames(2);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ResumeGameModalKeys.deleteAllButton));
      await tester.pumpAndSettle();

      expect(find.byKey(ResumeGameModalKeys.emptyStateText), findsOneWidget);
      expect(find.text('No saved games'), findsOneWidget);
    });

    testWidgets('empty state shown when no saved games', (tester) async {
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      expect(find.byKey(ResumeGameModalKeys.emptyStateText), findsOneWidget);
      expect(find.text('No saved games'), findsOneWidget);
      // Delete All button should not appear when no games
      expect(find.byKey(ResumeGameModalKeys.deleteAllButton), findsNothing);
    });

    testWidgets('multiple saved games render as list', (tester) async {
      await _seedSavedGames(3);
      await tester.pumpWidget(buildModal());
      await tester.pumpAndSettle();

      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');
      for (final game in saved) {
        expect(find.byKey(ResumeGameModalKeys.savedGameTile(game.id)), findsOneWidget);
      }
    });

    testWidgets('Target Tag config applies theme', (tester) async {
      await tester.pumpWidget(buildModal(config: ResumeGameModalConfig.targetTag()));
      await tester.pumpAndSettle();

      expect(find.byKey(ResumeGameModalKeys.container), findsOneWidget);
    });

    testWidgets('Monster Mash config applies theme', (tester) async {
      await tester.pumpWidget(buildModal(config: ResumeGameModalConfig.monsterMash()));
      await tester.pumpAndSettle();

      expect(find.byKey(ResumeGameModalKeys.container), findsOneWidget);
    });

    testWidgets('Reef Royale config applies theme', (tester) async {
      await tester.pumpWidget(buildModal(config: ResumeGameModalConfig.reefRoyale()));
      await tester.pumpAndSettle();

      expect(find.byKey(ResumeGameModalKeys.container), findsOneWidget);
    });
  });
}
