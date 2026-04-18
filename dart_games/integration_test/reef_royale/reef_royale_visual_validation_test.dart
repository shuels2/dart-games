import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/reef_royale_game.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

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

Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config, {
  bool showHints = false,
  bool bonusBuffs = false,
  bool cursedTide = false,
  bool neighborNumbers = false,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (cursedTide) {
    await SettingsHelpers.setReefRoyaleGameMode(tester, 'Cursed Tide');
  }
  if (showHints) {
    await SettingsHelpers.toggleReefRoyaleShowHints(tester);
  }
  if (neighborNumbers) {
    await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
  }
  if (bonusBuffs) {
    await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
  }

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Visual Validation Tests', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    tearDown(() async {
      // Reef Royale has continuous animations and multiple Future.delayed
      // callbacks. Wait for these to complete before starting the next test
      // to prevent widget tree corruption when app.main() is called again.
      await Future.delayed(const Duration(milliseconds: 500));
    });

    testWidgets('Test 1: Coral card updates after claim',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Coral card for 20 should exist before claiming
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(20)), findsOneWidget);

      // Claim target 20 with triple
      await throwDartViaMock(tester, 20, multiplier: 'triple');

      // Verify the claim happened in provider
      expect(
          ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
          isTrue);

      // Coral card should still be present (now in claimed state)
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(20)), findsOneWidget);
    });

    testWidgets('Test 2: Active player panel shows avatar and stats',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      expect(find.byKey(ReefRoyaleGameKeys.playerAvatar), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCounter), findsOneWidget);

      // No option badges should be visible with default settings
      expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsNothing);
      expect(find.byKey(ReefRoyaleGameKeys.neighborsBadge), findsNothing);
      expect(find.byKey(ReefRoyaleGameKeys.buffsBadge), findsNothing);
    });

    testWidgets('Test 3: Dart indicators show thrown darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // All 3 dart indicator slots should exist
      expect(find.byKey(ReefRoyaleGameKeys.dartIndicator(0)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.dartIndicator(1)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.dartIndicator(2)), findsOneWidget);

      // Throw a dart and verify indicator updates
      await throwDartViaMock(tester, 20);

      expect(
          ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);
    });

    testWidgets('Test 4: Buff banner displays when buff active',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, bonusBuffs: true);

      // Buffs badge should be visible in appbar
      expect(find.byKey(ReefRoyaleGameKeys.buffsBadge), findsOneWidget);

      // Programmatically set a buff
      ProviderHelpers.setReefRoyaleActiveBuff(tester, ReefBuff.riptideRush);
      await tester.pump();
      await tester.pump();

      // Buff banner should be visible
      expect(find.byKey(ReefRoyaleGameKeys.buffBanner), findsOneWidget);
    });

    testWidgets('Test 5: Opponent summary bar updates after scoring',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // Claim target 20 and score
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Now it's P2's turn - verify P1 appears in opponent tiles
      // The player tile for P1 should exist showing their stats
      expect(find.byKey(ReefRoyaleGameKeys.playerTile(playerId)),
          findsOneWidget);
    });

    testWidgets('Test 6: Hint overlay shows when enabled',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, showHints: true);

      expect(find.byKey(ReefRoyaleGameKeys.hintOverlay), findsOneWidget);
    });

    testWidgets('Test 7: Cursed Tide shows badge and visual changes',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, cursedTide: true);

      // Cursed badge should be visible
      expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsOneWidget);

      // Pearl counter should still be present
      expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
    });
  });
}
