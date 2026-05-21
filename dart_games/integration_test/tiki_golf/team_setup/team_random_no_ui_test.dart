// integration_test/tiki_golf/team_setup/team_random_no_ui_test.dart
//
// Team+Random mode: NONE of the team-assignment-specific UI elements
// (Team Count dropdown, "Assign team" trailing buttons) are rendered.
// The panel should look like Solo mode.
//
// Note: TikiGolfMenuKeys.teamAssignDropdown is not wired; we verify absence
// of "Assign team" text buttons instead.
//
// Section 12B File 8 — Team setup test 4 (team_random_no_ui)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team+Random renders NO Team Count dropdown or Assign team buttons',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Switch to Team mode (default assignment is Random)
    await setGameModeTeam(tester);
    // Do NOT switch to Manual — stay in default Random mode

    // Team Count dropdown should NOT be shown
    expectTeamCountDropdownAbsent(tester);

    // Add players
    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // "Assign team" trailing buttons should NOT be present in Random mode
    // (the TeamPlayerListPanel renders no team-assignment UI in Random mode)
    // Note: "Team Assignment" label IS present (settings label), so we must
    // search for the exact button text 'Assign team' not just 'Assign'
    final assignTeamBtns = find.text('Assign team');
    expect(assignTeamBtns, findsNothing,
        reason:
            '"Assign team" trailing buttons should NOT be present in Team+Random mode — '
            'the panel looks like Solo mode in Random assignment');

    // Add player button still accessible (panel stays mounted)
    final addBtnPresent =
        ElementFinders.getTikiGolfAddPlayerButton().evaluate().isNotEmpty ||
        ElementFinders.getTikiGolfAddPlayerButtonEmptyState()
            .evaluate()
            .isNotEmpty;
    expect(addBtnPresent, isTrue,
        reason:
            'Add player button should still be accessible in Team+Random mode');
  });
}
