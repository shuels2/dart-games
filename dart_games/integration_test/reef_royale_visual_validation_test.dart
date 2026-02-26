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

Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config,
    {bool showHints = false, bool bonusBuffs = false}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (showHints) {
    await SettingsHelpers.toggleReefRoyaleShowHints(tester);
  }
  if (bonusBuffs) {
    await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
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

  group('Reef Royale - Visual Validation Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Game screen renders coral tracker with 7 targets',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // All 7 standard coral cards should be present
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(20)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(19)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(18)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(17)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(16)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(15)), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCard(25)), findsOneWidget);
    });

    testWidgets('Test 2: Active player panel shows avatar and stats',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      expect(find.byKey(ReefRoyaleGameKeys.playerAvatar), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
      expect(find.byKey(ReefRoyaleGameKeys.coralCounter), findsOneWidget);
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

    testWidgets('Test 4: Hint overlay shows when enabled',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, showHints: true);

      expect(find.byKey(ReefRoyaleGameKeys.hintOverlay), findsOneWidget);
    });

    testWidgets('Test 5: Skip turn button is visible',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final skipButton = config.getSkipTurnButton();
      expect(skipButton, findsOneWidget);
    });
  });
}
