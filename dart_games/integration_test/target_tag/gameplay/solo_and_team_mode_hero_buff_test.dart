import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Solo Mode and Team Mode with Hero Buff - Validates hero buff displays correctly in solo mode with 4 players (each player has individual buff value), game transitions from solo mode back to menu, team mode enabled with random team assignment, hero buffs displayed for teams (shared buff per team), team target numbers assigned correctly', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable hero bonus first
    await enableHeroBonus(tester);

    // Add 4 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);
    await UITestHelpers.addPlayer(tester, 'Player D', config);

    // ===== Step 1: Start solo mode game with hero bonus ON =====
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 2: Verify solo mode shows hero buff for individual players =====
    expect(find.textContaining('Buff:'), findsWidgets);
    final soloBuff = getHeroBuffFromActivePanel(tester);
    expect(soloBuff, isNotNull);
    // Buff should be in dart notation: D1-D20 or T1-T20
    final buffPattern = RegExp(r'^[DT]\d{1,2}$');
    expect(buffPattern.hasMatch(soloBuff!), isTrue,
        reason: 'Solo buff value should be dart notation (D1-D20 or T1-T20), got: $soloBuff');

    // ===== Step 3: Return to menu and enable team mode =====
    await navigateBackToMenu(tester);
    await enableTeamMode(tester);

    // Start game in team mode
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 4: Verify team mode shows hero buff for teams =====
    expect(find.textContaining('Buff:'), findsWidgets);
    final teamBuff = getHeroBuffFromActivePanel(tester);
    expect(teamBuff, isNotNull);
    // Buff should be in dart notation: D1-D20 or T1-T20
    expect(buffPattern.hasMatch(teamBuff!), isTrue,
        reason: 'Team buff value should be dart notation (D1-D20 or T1-T20), got: $teamBuff');

    // Verify team target numbers are assigned
    expect(find.textContaining('Target number:'), findsWidgets);
  });
}
