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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Showcase Test', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Showcase: Full game with Easy Claim, Neighbors, and Buffs',
        (WidgetTester tester) async {
      // ─── Step 1: Navigate to Reef Royale menu ───
      await UITestHelpers.navigateToGameMenu(tester, config);

      // ─── Step 2: Enable Easy Claim, Neighbor Numbers, and Bonus Buffs ───
      await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
      await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
      await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);

      // ─── Step 3: Add 2 players (Nemo, Dory) ───
      await UITestHelpers.addPlayer(tester, 'Nemo', config);
      await UITestHelpers.addPlayer(tester, 'Dory', config);

      // ─── Step 4: Start game ───
      await UITestHelpers.startGame(tester, config);
      expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);

      // Verify neighbors and buffs badges are visible in appbar
      expect(find.byKey(ReefRoyaleGameKeys.neighborsBadge), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.buffsBadge), findsOneWidget);

      final p1Id = ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

      // ─── Step 5: P1 Turn 1, D1: Triple 20 ───
      // Easy Claim = 2 marks threshold, triple gives 3 marks = instant claim + 1 excess
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      expect(ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, p1Id, 20), isTrue);

      // ─── Step 6: P1 Turn 1, D2: Hit 3 (neighbor of 19) ───
      // Neighbor numbers enabled, 3 is neighbor of 19 → adds 1 mark to 19
      await throwDartViaMock(tester, 3);
      expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, p1Id, 19),
          greaterThan(0));

      // ─── Step 7: P1 Turn 1, D3: Miss ───
      await throwMissViaMock(tester);

      // ─── Finish P1 Turn 1: Darts removed ───
      await clickDartsRemoved(tester);

      // ─── Step 8: P2 Turn 1: 3 misses ───
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // ─── Step 9: P1 Turn 2: Triple 19, Triple 18, hit claimed 20 for pearls ───
      await throwDartViaMock(tester, 19, multiplier: 'triple');
      expect(ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, p1Id, 19), isTrue);

      await throwDartViaMock(tester, 18, multiplier: 'triple');
      expect(ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, p1Id, 18), isTrue);

      // Hit claimed 20 for pearls (opponent hasn't claimed)
      await throwDartViaMock(tester, 20);
      expect(ProviderHelpers.getReefRoyalePlayerPearls(tester, p1Id),
          greaterThan(0));

      await clickDartsRemoved(tester);

      // ─── Step 10: P2 Turn 2: 3 misses ───
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // ─── Step 11: P1 Turn 3: Triple 17, Triple 16, Triple 15 (6 corals) ───
      await throwDartViaMock(tester, 17, multiplier: 'triple');
      await throwDartViaMock(tester, 16, multiplier: 'triple');
      await throwDartViaMock(tester, 15, multiplier: 'triple');
      expect(ProviderHelpers.getReefRoyalePlayerClaimedCount(tester, p1Id), 6);
      await clickDartsRemoved(tester);

      // ─── Step 12: P2 Turn 3: 3 misses ───
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // ─── Step 13: Set Riptide Rush buff programmatically ───
      ProviderHelpers.setReefRoyaleActiveBuff(tester, ReefBuff.riptideRush);
      expect(ProviderHelpers.getReefRoyaleActiveBuff(tester),
          ReefBuff.riptideRush);

      // ─── Step 14: P1 Turn 4: Bullseye + Outer Bull → claims Bull (7th) → WIN ───
      // With Riptide Rush: Bullseye = 2 marks * 2 = 4 marks
      // Easy Claim threshold is 2, so bullseye alone claims Bull
      await throwBullseyeViaMock(tester);
      expect(ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, p1Id, 25), isTrue);
      expect(ProviderHelpers.getReefRoyalePlayerClaimedCount(tester, p1Id), 7);

      // Game should end with winner
      expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

      // ─── Step 15: Wait for results screen ───
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      await clickDartsRemoved(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // ─── Step 16: Verify results screen ───
      await UITestHelpers.verifyResultsScreen(tester, config);

      // ─── Step 17: Tap "Dive Again" (Play Again) → verify new game starts ───
      await UITestHelpers.clickPlayAgain(tester, config);
      expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);

      // ─── Step 18: Go back to home via menu navigation ───
      // We're in a new game, need to navigate back
      // Use the back button or end game flow
      // For simplicity, verify we're in a fresh game state
      expect(ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 0);
    });
  });
}
