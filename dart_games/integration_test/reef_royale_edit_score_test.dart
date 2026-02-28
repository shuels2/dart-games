import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import 'shared/ui_test_helpers.dart';
import 'shared/element_finders.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';
import 'shared/edit_score_helpers.dart';

// ==========================================================================
// HELPER METHODS
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number *
          (multiplier == 'double'
              ? 2
              : multiplier == 'triple'
                  ? 3
                  : 1),
      multiplier: multiplier,
      playerName: 'Player',
      baseScore: number,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'single',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> setupAndStartGame(
    WidgetTester tester, GameUIConfig config) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Edit Score Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Edit score button appears after 3 darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 19);
      await throwDartViaMock(tester, 18);

      // Wait for takeout prompt
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Edit score button should be visible
      final editButton = config.getEditScoreButton();
      expect(editButton, findsOneWidget);
    });

    testWidgets('Test 2: Edit score dialog opens with current darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 19);
      await throwDartViaMock(tester, 18);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Tap edit score
      final editButton = config.getEditScoreButton();
      await tester.tap(editButton);
      await PumpSequences.dialogOpen(tester);

      // Dialog should be visible
      expect(ElementFinders.getEditScoreDialog(), findsOneWidget);
    });

    testWidgets('Test 3: Cancel edit score preserves original darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwDartViaMock(tester, 20);
      final marksBefore =
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20);

      await throwDartViaMock(tester, 19);
      await throwDartViaMock(tester, 18);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Open and cancel edit score
      final editButton = config.getEditScoreButton();
      await tester.tap(editButton);
      await PumpSequences.dialogOpen(tester);

      await tester.tap(ElementFinders.getEditScoreCancelButton());
      await PumpSequences.dialogClose(tester);

      // Marks should be unchanged
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20),
          marksBefore);
    });

    testWidgets('Test 4: Edit score recalculates marks correctly',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // All marks should be 0
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Change dart 1 from Miss to Triple 20 (should add 3 marks = claim target 20)
      await EditScoreHelpers.setDart1(tester, 'T20');

      // Save
      await EditScoreHelpers.updateScore(tester);

      // Target 20 should now have 3 marks (claimed)
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 3);
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isTrue);
    });

    testWidgets('Test 5: Edit score removes claim if marks drop below threshold',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Claim target 20 with triple, then 2 misses
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Verify claimed
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isTrue);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Open edit score and change triple 20 to miss
      await EditScoreHelpers.openEditScore(tester, config);
      await EditScoreHelpers.setDart1(tester, 'Miss');
      await EditScoreHelpers.updateScore(tester);

      // Claim should be removed since marks dropped to 0
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isFalse);
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
    });

    testWidgets('Test 6: Edit score triggers win when final target claimed',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // P1 Turn 1: claim 20, 19, 18
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwDartViaMock(tester, 19, multiplier: 'triple');
      await throwDartViaMock(tester, 18, multiplier: 'triple');

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Click DARTS REMOVED
      final dartsRemovedButton = find.text('DARTS REMOVED');
      if (dartsRemovedButton.evaluate().isNotEmpty) {
        await tester.tap(dartsRemovedButton.first);
        await PumpSequences.simpleUpdate(tester);
      }

      // P2 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      final dartsRemovedButton2 = find.text('DARTS REMOVED');
      if (dartsRemovedButton2.evaluate().isNotEmpty) {
        await tester.tap(dartsRemovedButton2.first);
        await PumpSequences.simpleUpdate(tester);
      }

      // P1 Turn 2: claim 17, 16, 15
      await throwDartViaMock(tester, 17, multiplier: 'triple');
      await throwDartViaMock(tester, 16, multiplier: 'triple');
      await throwDartViaMock(tester, 15, multiplier: 'triple');

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      final dartsRemovedButton3 = find.text('DARTS REMOVED');
      if (dartsRemovedButton3.evaluate().isNotEmpty) {
        await tester.tap(dartsRemovedButton3.first);
        await PumpSequences.simpleUpdate(tester);
      }

      // P2 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      final dartsRemovedButton4 = find.text('DARTS REMOVED');
      if (dartsRemovedButton4.evaluate().isNotEmpty) {
        await tester.tap(dartsRemovedButton4.first);
        await PumpSequences.simpleUpdate(tester);
      }

      // P1 now has 6/7 targets claimed — verify
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isTrue);
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 15), isTrue);

      // P1 Turn 3: throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Edit score to claim Bull (7th target) — Bullseye + Outer Bull + Miss = 3 marks
      await EditScoreHelpers.openEditScore(tester, config);
      await EditScoreHelpers.setDart1(tester, 'Bull');
      await EditScoreHelpers.setDart2(tester, '25');
      await EditScoreHelpers.setDart3(tester, 'Miss');
      await EditScoreHelpers.updateScore(tester);

      // Game should detect win
      expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

      // Click DARTS REMOVED to trigger game won flow
      final dartsRemovedButton5 = find.text('DARTS REMOVED');
      if (dartsRemovedButton5.evaluate().isNotEmpty) {
        await tester.tap(dartsRemovedButton5.first);
        await PumpSequences.simpleUpdate(tester);
      }

      // Wait for results screen navigation (3000ms delay in _handleGameWon)
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Results screen should be visible with winner name
      final winnerName = ElementFinders.getReefRoyaleWinnerName();
      expect(winnerName, findsOneWidget);
    });
  });
}
