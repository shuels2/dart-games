import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import 'shared/ui_test_helpers.dart';
import 'shared/element_finders.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';

// ==========================================================================
// HELPER METHODS
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

/// Throw a dart at a specific number with multiplier
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

/// Throw a bullseye (inner bull, 50 points, 2 marks on Bull target)
Future<void> throwBullseyeViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 50,
      multiplier: 'bullseye',
      playerName: 'Player',
      baseScore: 50,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Throw outer bull (25 points, 1 mark on Bull target)
Future<void> throwOuterBullViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 25,
      multiplier: 'outer_bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Throw a miss
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

/// Click DARTS REMOVED to advance turn
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Set up a 2-player game and start it
Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config,
    {bool easyClaim = false}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (easyClaim) {
    await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
  }

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  final players = ProviderHelpers.getAllPlayers(tester);
  final pA = players.firstWhere((p) => p.name == 'Player A');
  final pB = players.firstWhere((p) => p.name == 'Player B');
  await UITestHelpers.selectPlayers(tester, [pA.id, pB.id], config);

  await UITestHelpers.startGame(tester, config);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Gameplay Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Game starts with correct initial state',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
      expect(ProviderHelpers.getReefRoyaleCurrentPlayerId(tester), isNotNull);
      expect(
          ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 0);
    });

    testWidgets('Test 2: Single dart throw registers 1 mark',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwDartViaMock(tester, 20);

      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 1);
      expect(
          ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);
    });

    testWidgets('Test 3: Double dart throw registers 2 marks',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwDartViaMock(tester, 19, multiplier: 'double');

      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 19), 2);
    });

    testWidgets('Test 4: Triple dart throw claims coral (3 marks)',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwDartViaMock(tester, 20, multiplier: 'triple');

      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
          isTrue);
      expect(
          ProviderHelpers.getReefRoyalePlayerClaimedCount(tester, playerId),
          1);
    });

    testWidgets('Test 5: Miss does not add marks',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwMissViaMock(tester);

      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
      expect(
          ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);
    });

    testWidgets('Test 6: Three darts triggers takeout prompt',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 19);
      await throwDartViaMock(tester, 18);

      // After 3 darts, the remove darts modal should appear
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();
    });

    testWidgets('Test 7: Turn advances after darts removed',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final firstPlayerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await clickDartsRemoved(tester);

      final secondPlayerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester);
      expect(secondPlayerId, isNot(equals(firstPlayerId)));
    });

    testWidgets('Test 8: Claiming scores pearls on subsequent hits',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Claim target 20 with triple
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
          isTrue);

      // Hit target 20 again for pearls
      await throwDartViaMock(tester, 20);
      expect(ProviderHelpers.getReefRoyalePlayerPearls(tester, playerId),
          greaterThan(0));
    });

    testWidgets('Test 9: Skip turn advances to next player',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final firstPlayerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await UITestHelpers.clickSkipTurn(tester, config);

      await clickDartsRemoved(tester);

      final secondPlayerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester);
      expect(secondPlayerId, isNot(equals(firstPlayerId)));
    });

    testWidgets('Test 10: Easy claim requires only 2 marks',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, easyClaim: true);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Double should claim with easy claim (2 marks needed)
      await throwDartViaMock(tester, 20, multiplier: 'double');

      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
          isTrue);
    });

    testWidgets('Test 11: Non-target number does not add marks',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Hit number 10 (not a standard target)
      await throwDartViaMock(tester, 10);

      // No marks should be added to any target
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 19), 0);
    });

    testWidgets('Test 12: Bullseye adds 2 marks to Bull target',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwBullseyeViaMock(tester);

      // Bull target is 25, bullseye gives 2 marks
      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 25), 2);
    });

    testWidgets('Test 13: Outer bull adds 1 mark to Bull target',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      await throwOuterBullViaMock(tester);

      expect(
          ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 25), 1);
    });

    testWidgets('Test 14: Locked target gives no marks',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // P1 claims target 20
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // P2 claims target 20
      await throwDartViaMock(tester, 20, multiplier: 'triple');

      // Target 20 should be locked (both players claimed)
      expect(
          ProviderHelpers.isReefRoyaleTargetLocked(tester, 20), isTrue);
    });

    testWidgets('Test 15: Game ends when player claims all 7 targets',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // P1 claims all 7 targets using triples
      // Turn 1: claim 20, 19, 18
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwDartViaMock(tester, 19, multiplier: 'triple');
      await throwDartViaMock(tester, 18, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // P2 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Turn 2: claim 17, 16, 15
      await throwDartViaMock(tester, 17, multiplier: 'triple');
      await throwDartViaMock(tester, 16, multiplier: 'triple');
      await throwDartViaMock(tester, 15, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // P2 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Turn 3: claim Bull
      await throwBullseyeViaMock(tester); // 2 marks
      await throwOuterBullViaMock(tester); // 1 mark = 3 total = claimed!

      // Game should end
      expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

      // Wait for results screen
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    });
  });
}
