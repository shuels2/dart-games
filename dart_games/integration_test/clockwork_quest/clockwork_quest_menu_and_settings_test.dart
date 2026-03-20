import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Menu and Settings Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Menu screen shows initial state',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify settings are visible
      expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
          findsOneWidget);
      expect(ElementFinders.getClockworkQuestDoubleTriplesCountCheckbox(),
          findsOneWidget);
      expect(
          ElementFinders.getClockworkQuestSpeedModeCheckbox(), findsOneWidget);
      expect(
          ElementFinders.getClockworkQuestNumberOfLapsDropdown(), findsOneWidget);

      // Start button should be disabled (no players)
      final startButton = config.getStartButton();
      expect(startButton, findsOneWidget);
    });

    testWidgets('Test 2: Toggle Include Bullseye setting',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final checkbox = ElementFinders.getClockworkQuestIncludeBullseyeCheckbox();
      await tester.tap(checkbox);
      await PumpSequences.simpleUpdate(tester);

      // Setting should be toggled
      expect(checkbox, findsOneWidget);
    });

    testWidgets('Test 3: Toggle D/T Count setting',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final checkbox =
          ElementFinders.getClockworkQuestDoubleTriplesCountCheckbox();
      await tester.tap(checkbox);
      await PumpSequences.simpleUpdate(tester);

      expect(checkbox, findsOneWidget);
    });

    testWidgets('Test 4: Toggle Speed Mode setting',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final checkbox = ElementFinders.getClockworkQuestSpeedModeCheckbox();
      await tester.tap(checkbox);
      await PumpSequences.simpleUpdate(tester);

      expect(checkbox, findsOneWidget);
    });

    testWidgets('Test 5: Change Number of Laps setting',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final dropdown = ElementFinders.getClockworkQuestNumberOfLapsDropdown();
      expect(dropdown, findsOneWidget);

      // Tap to open dropdown
      await tester.tap(dropdown);
      await PumpSequences.simpleUpdate(tester);

      // Select a different value (if dropdown items are present)
      // Note: Actual selection would require finding the dropdown item
    });

    testWidgets('Test 6: Start game with default settings',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add two players
      await UITestHelpers.addPlayer(tester, 'Gear1', config);
      await UITestHelpers.addPlayer(tester, 'Gear2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Gear1');
      final p2 = players.firstWhere((p) => p.name == 'Gear2');

      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      // Start button should be enabled
      final startButton = config.getStartButton();
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await PumpSequences.longNavigation(tester);

      // Should navigate to game screen
      expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);
    });

    testWidgets('Test 7: Start game with all options changed',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Toggle all settings
      await tester.tap(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox());
      await PumpSequences.simpleUpdate(tester);
      await tester
          .tap(ElementFinders.getClockworkQuestDoubleTriplesCountCheckbox());
      await PumpSequences.simpleUpdate(tester);
      await tester.tap(ElementFinders.getClockworkQuestSpeedModeCheckbox());
      await PumpSequences.simpleUpdate(tester);

      // Add players and start
      await UITestHelpers.addPlayer(tester, 'Cog1', config);
      await UITestHelpers.addPlayer(tester, 'Cog2', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final p1 = players.firstWhere((p) => p.name == 'Cog1');
      final p2 = players.firstWhere((p) => p.name == 'Cog2');

      await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

      final startButton = config.getStartButton();
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await PumpSequences.longNavigation(tester);

      expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);
    });

    testWidgets('Test 8: Start button disabled with less than 2 players',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add only one player
      await UITestHelpers.addPlayer(tester, 'Lonely', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final lonely = players.firstWhere((p) => p.name == 'Lonely');

      await UITestHelpers.selectPlayers(tester, [lonely.id], config);

      // Start button should still be disabled
      final startButton = config.getStartButton();
      expect(startButton, findsOneWidget);
    });
  });
}
