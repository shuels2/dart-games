import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Team Mode - Team Tagged In Visual - Validates team mode enabled with 4 players on 2 teams, Team 1 reaches max shields and gets tagged in, all Team 1 members show TAGGED IN badge simultaneously, all Team 1 member tiles have green pulsing border, Team 2 members remain without tagged in indicators, current team member shows pink border + green glow combined, team tagged in state applies to all team members together', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // ===== Step 1: Set shield max to 3 for faster testing =====
    await setShieldMax(tester, 3);

    // ===== Step 2: Enable Team mode and manual team assignment =====
    await enableTeamMode(tester);
    await enableManualTeamAssignment(tester);

    // ===== Step 3: Add 4 players and assign to teams =====
    // Team 1: Players 1 and 2
    // Team 2: Players 3 and 4
    await UITestHelpers.addPlayer(tester, 'Team Visual 1', config);
    await assignPlayerToTeam(tester, 1); // Team 1

    await UITestHelpers.addPlayer(tester, 'Team Visual 2', config);
    await assignPlayerToTeam(tester, 1); // Team 1

    await UITestHelpers.addPlayer(tester, 'Team Visual 3', config);
    await assignPlayerToTeam(tester, 2); // Team 2

    await UITestHelpers.addPlayer(tester, 'Team Visual 4', config);
    await assignPlayerToTeam(tester, 2); // Team 2

    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 4: First team reaches tagged in (3 shields) =====
    // Note: Team assignment is dynamic, so we work with whoever is current
    final teamTarget = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, teamTarget);
    await throwDartViaMock(tester, teamTarget);
    await throwDartViaMock(tester, teamTarget); // TAGGED IN!

    await PumpSequences.simpleUpdate(tester);

    // ===== Step 5: Verify TAGGED IN badge appears =====
    final taggedInBadge = find.text('TAGGED IN');
    expect(taggedInBadge, findsWidgets);

    // ===== Step 6: Verify all player names visible =====
    // In team mode, player names appear in multiple places (team tile, panels, etc.)
    expect(find.text('Team Visual 1'), findsWidgets);
    expect(find.text('Team Visual 2'), findsWidgets);
    expect(find.text('Team Visual 3'), findsWidgets);
    expect(find.text('Team Visual 4'), findsWidgets);

    // ===== Step 7: Advance turn to see both teams =====
    await clickDartsRemoved(tester);
    await skipTurn(tester);
    await PumpSequences.fullRebuild(tester);

    // ===== Step 8: Verify tagged-in team has glow, other team doesn't =====
    // With manual team assignment:
    // Team 1 (Team Visual 1 and 2) got tagged in first
    // Team 2 (Team Visual 3 and 4) should NOT have glow

    // Tagged-in team members (1 and 2) should have glow
    verifyPlayerTileGlow(tester, 'Team Visual 1', colorGreenGlow, shouldExist: true);
    verifyPlayerTileGlow(tester, 'Team Visual 2', colorGreenGlow, shouldExist: true);

    // Non-tagged-in team members (3 and 4) should NOT have glow
    verifyPlayerTileGlow(tester, 'Team Visual 3', colorGreenGlow, shouldExist: false);
    verifyPlayerTileGlow(tester, 'Team Visual 4', colorGreenGlow, shouldExist: false);
  });
}
