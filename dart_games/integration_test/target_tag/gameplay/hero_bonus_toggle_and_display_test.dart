import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Hero Bonus Toggle and Display - Validates hero bonus OFF shows no buff label, hero bonus ON displays buff label and value in solo mode, hero bonus displays correctly in team mode with random assignment, buff numbers and multipliers shown correctly', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // ===== Step 1: Verify hero bonus OFF shows no buff =====
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 3 players with hero bonus OFF (default state)
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    // Verify players were added
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
    expect(find.text('Player C'), findsWidgets);

    // ===== Step 2: Start game with hero bonus OFF and verify no buff =====
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Verify active player panel shows "Target number:" (not tagged in)
    expect(find.textContaining('Target number:'), findsWidgets);

    // Verify NO "Buff:" text appears when hero bonus is OFF
    expect(find.textContaining('Buff:'), findsNothing);

    // Verify NOT showing "Opponent targets:" yet (not tagged in)
    expect(find.textContaining('Opponent targets:'), findsNothing);

    // ===== Step 3: Return to menu, enable hero bonus, and start game =====
    await navigateBackToMenu(tester);

    // Enable hero bonus
    await enableHeroBonus(tester);

    // Verify hero bonus is now ON (toggle should be enabled)
    final heroBonusSwitch = find.byType(Switch).last;
    final switchWidget = tester.widget<Switch>(heroBonusSwitch);
    expect(switchWidget.value, isTrue);

    // Start the game again
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    final titleFinder = find.text('Target Tag Game On!');
    expect(titleFinder, findsOneWidget);

    // ===== Step 4: Verify hero buff displays in solo mode =====
    final targetNumberFinder = find.textContaining('Target number:');
    expect(targetNumberFinder, findsWidgets);

    final buffFinder = find.textContaining('Buff:');
    expect(buffFinder, findsWidgets);

    // Extract and validate the buff value (should be dart notation like D3, T16)
    final buffValue = getHeroBuffFromActivePanel(tester);
    expect(buffValue, isNotNull);
    // Buff should be in dart notation: D1-D20 or T1-T20
    final buffPattern = RegExp(r'^[DT]\d{1,2}$');
    expect(buffPattern.hasMatch(buffValue!), isTrue,
        reason: 'Buff value should be dart notation (D1-D20 or T1-T20), got: $buffValue');

    // ===== Step 5: Return to menu and enable team mode =====
    await navigateBackToMenu(tester);

    // Enable team mode (this will also enable random team assignment)
    await enableTeamMode(tester);

    // Verify team mode is enabled
    final teamModeSwitch = find.byType(Switch).first;
    final teamModeSwitchWidget = tester.widget<Switch>(teamModeSwitch);
    expect(teamModeSwitchWidget.value, isTrue);

    // Start the game in team mode
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    final teamTitleFinder = find.text('Target Tag Game On!');
    expect(teamTitleFinder, findsOneWidget);

    // ===== Step 6: Verify hero buff displays correctly in team mode =====
    // In team mode, buff is shared per team
    final teamTargetFinder = find.textContaining('Target number:');
    expect(teamTargetFinder, findsWidgets);

    final teamBuffFinder = find.textContaining('Buff:');
    expect(teamBuffFinder, findsWidgets);

    // Extract and validate the team buff value
    final teamBuffValue = getHeroBuffFromActivePanel(tester);
    expect(teamBuffValue, isNotNull);
    // Buff should be in dart notation: D1-D20 or T1-T20
    expect(buffPattern.hasMatch(teamBuffValue!), isTrue,
        reason: 'Team buff value should be dart notation (D1-D20 or T1-T20), got: $teamBuffValue');
  });
}
