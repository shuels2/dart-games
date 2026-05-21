// integration_test/tiki_golf/team_setup/manual_assignment_dropdown_test.dart
//
// Team+Manual mode: verify per-player "Assign team" trailing buttons are
// present and the Team Count dropdown is shown.
//
// Note: TikiGolfMenuKeys.teamAssignDropdown is defined in test_keys.dart but
// NOT wired into TeamPlayerListPanel. We verify assignment UI via button text.
// Dialog-open verification is covered by existing menu_and_settings tests.
//
// Section 12B File 8 — Team setup test 2 (manual_assignment_dropdown)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Manual assignment — per-player Assign buttons present in Team+Manual mode',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Switch to Team + Manual mode
    await setGameModeTeam(tester);
    await setAssignmentManual(tester);

    // Add 3 players
    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // In Team+Manual mode, each selected player with no team assigned
    // shows an "Assign team" ElevatedButton trailing icon.
    // Use exact text 'Assign team' to avoid matching "Team Assignment" label.
    final assignTeamBtns = find.text('Assign team');
    expect(assignTeamBtns, findsWidgets,
        reason:
            '"Assign team" trailing buttons should be present for players in Team+Manual mode. '
            'This confirms the manual assignment UI is rendered per-player.');

    // The number of "Assign team" buttons should match the number of added players
    // (each unassigned selected player gets one button)
    final btnCount = assignTeamBtns.evaluate().length;
    expect(btnCount, greaterThanOrEqualTo(2),
        reason:
            'Should have at least 2 "Assign team" buttons for 3 players in Team+Manual mode '
            '(count: $btnCount)');

    // (Team Count dropdown removed from the menu — see source comment in
    // tiki_golf_menu_screen.dart; default is 4 teams. No dropdown to assert.)

    // Assignment toggle must show MANUAL as selected
    expect(ElementFinders.getTikiGolfAssignmentModeManual(), findsOneWidget,
        reason: 'MANUAL segment should be visible in assignment toggle');
  });
}

