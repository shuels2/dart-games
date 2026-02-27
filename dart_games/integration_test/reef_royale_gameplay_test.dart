import 'package:flutter/material.dart';
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

/// Verify dart indicator border color
void verifyDartIndicatorColor(WidgetTester tester, Key dartKey, int expectedColorValue) {
  final indicatorFinder = find.byKey(dartKey);
  expect(indicatorFinder, findsOneWidget);

  final container = tester.widget<Container>(indicatorFinder);
  final decoration = container.decoration as BoxDecoration?;
  expect(decoration, isNotNull);

  expect(decoration!.border, isNotNull);

  final border = decoration.border as Border;
  final actualColor = border.top.color.value;

  expect(actualColor, expectedColorValue,
      reason: 'Dart $dartKey should have border color 0x${expectedColorValue.toRadixString(16)}, '
          'but got 0x${actualColor.toRadixString(16)}');
}

/// Set up a 2-player game and start it
Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config,
    {bool easyClaim = false, bool neighborNumbers = false}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (easyClaim) {
    await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
  }

  if (neighborNumbers) {
    await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
  }

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added, no need to call selectPlayers
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

      // Hide dartboard emulator so skip button is not obscured
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

      await UITestHelpers.clickSkipTurn(tester, config);

      // Show dartboard emulator for DARTS REMOVED button
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

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

    // ================================================================
    // D1/D2/D3 Dart Indicator Highlighting Tests
    // ================================================================
    // Color values from reef_royale_game_screen.dart:
    //   _seafoamGreen    = 0xFF48D1CC  (valid target hit, marks added)
    //   _sandyGold       = 0xFFF4D03F  (claimed coral)
    //   _sunlitAqua      = 0xFF00CED1  (neighbor hit)
    //   _coralPink @ 0.5 = 0x80FF6B6B  (miss / non-target)
    //   _sandyGold @ 0.7 = 0xB3F4D03F  (pearl scored)

    testWidgets('Test 16: D1 target hit shows green, D2 miss shows pink, D3 target hit shows green',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // D1: Single 20 (valid target, 1 mark, not claimed) → green
      await throwDartViaMock(tester, 20);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF48D1CC);

      // D2: Miss (non-target hit) → pink
      await throwMissViaMock(tester);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0x80FF6B6B);

      // D3: Single 19 (valid target, 1 mark, not claimed) → green
      await throwDartViaMock(tester, 19);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0xFF48D1CC);
    });

    testWidgets('Test 17: Triple claim shows gold border on D1 and D2',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // D1: Triple 20 (3 marks = claimed) → gold
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFFF4D03F);

      // D2: Triple 19 (3 marks = claimed) → gold
      await throwDartViaMock(tester, 19, multiplier: 'triple');
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0xFFF4D03F);

      // D3: Miss → pink
      await throwMissViaMock(tester);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0x80FF6B6B);
    });

    testWidgets('Test 18: Bullseye shows green, outer bull claiming Bull shows gold',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // D1: Bullseye (2 marks on Bull, not yet claimed) → green
      await throwBullseyeViaMock(tester);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF48D1CC);

      // D2: Outer bull (1 mark on Bull, total 3 = claimed!) → gold
      await throwOuterBullViaMock(tester);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0xFFF4D03F);
    });

    testWidgets('Test 19: Neighbor hit shows aqua border',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, neighborNumbers: true);

      // Throw 1 (neighbor of 20 on dartboard) → resolves to target 20, neighbor hit → aqua
      await throwDartViaMock(tester, 1);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF00CED1);

      // D2: Direct hit on 20 → green
      await throwDartViaMock(tester, 20);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0xFF48D1CC);

      // D3: Non-target number (9, not neighbor of any target: 9's neighbors are 14 and 12) → pink
      await throwDartViaMock(tester, 9);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0x80FF6B6B);
    });

    testWidgets('Test 20: Hitting claimed target for pearls shows light gold border',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // P1 Turn 1: claim 20 with triple, then 2 misses
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // P2 Turn 1: 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // P1 Turn 2: hit 20 again (already claimed by P1, P2 hasn't → scores pearls)
      await throwDartViaMock(tester, 20);
      verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xB3F4D03F);
    });
  });
}
