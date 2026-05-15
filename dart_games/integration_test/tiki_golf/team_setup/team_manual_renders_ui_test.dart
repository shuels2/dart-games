// integration_test/tiki_golf/team_setup/team_manual_renders_ui_test.dart
//
// Team+Manual mode: team-assignment UI (Team Count dropdown, assignment toggle,
// and per-player "Assign team" trailing buttons) all present.
//
// Note: TikiGolfMenuKeys.teamAssignDropdown keys are defined in test_keys.dart
// but NOT wired into TeamPlayerListPanel — the trailing buttons are ElevatedButton
// widgets with "Assign team" text (no per-player widget keys). We find them by text.
//
// Section 12B File 8 — Team setup test 3 (team_manual_renders_ui)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team+Manual renders Team Count dropdown, assignment toggle, per-player Assign buttons',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Switch to Team + Manual mode
    await setGameModeTeam(tester);
    await setAssignmentManual(tester);

    // ── Team Count dropdown present ────────────────────────────────────────
    expectTeamCountDropdownPresent(tester);

    // ── Assignment Mode toggle present ────────────────────────────────────
    expectAssignmentTogglePresent(tester);

    // ── Add players so we can verify trailing "Assign team" buttons ───────
    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── Per-player "Assign team" trailing buttons present ─────────────────
    // In Team+Manual mode, each selected player with no team assigned shows
    // an "Assign team" ElevatedButton trailing icon.
    // Use exact text 'Assign team' to avoid matching "Team Assignment" settings label.
    final assignBtns = find.text('Assign team');
    expect(assignBtns, findsWidgets,
        reason:
            '"Assign team" trailing buttons should be present for players in Team+Manual mode. '
            'Found ${assignBtns.evaluate().length} buttons for 3 players.');

    // MANUAL segment should be visible in assignment toggle
    final manualSegment = ElementFinders.getTikiGolfAssignmentModeManual();
    expect(manualSegment, findsOneWidget,
        reason: 'MANUAL segment should be visible in assignment toggle');
  });
}
