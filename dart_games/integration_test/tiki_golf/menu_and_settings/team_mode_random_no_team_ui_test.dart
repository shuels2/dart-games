// integration_test/tiki_golf/menu_and_settings/team_mode_random_no_team_ui_test.dart
//
// Team+Random mode: panel looks identical to Solo — no Team Count dropdown,
// no trailing team-assign "Assign team" buttons (which only appear for
// selected players in Manual mode).
//
// NOTE: TikiGolfMenuKeys.teamBox(int) keys are not wired into
// TeamPlayerListPanel._buildTeamBox() — cannot assert on those keys.
// We assert on Team Count dropdown (present in Manual, absent in Random).
//
// Section 12B File 2 — Test 10 (team_mode_random_no_team_ui)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team+Random mode: no Team Count dropdown visible, panel mounted',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // ── Switch to Team mode (Random is default assignment) ───────────────
    await setGameModeTeam(tester);
    // Team Assignment defaults to Random — no extra action needed.

    // ── Verify no Team Count dropdown ─────────────────────────────────────
    final teamCountDropdown =
        ElementFinders.getTikiGolfTeamCountDropdown();
    expect(teamCountDropdown, findsNothing,
        reason:
            '[DIAG random_no_team_ui] Team Count dropdown should NOT appear in Team+Random mode');

    // ── Verify no "Assign team" trailing icons ─────────────────────────────
    // These only appear when players are selected in Manual mode.
    expect(find.text('Assign team'), findsNothing,
        reason:
            '[DIAG random_no_team_ui] "Assign team" trailing buttons should NOT appear in Team+Random mode');

    // ── Add player button is still present (panel is mounted) ─────────────
    bool isAddButtonMounted() {
      return ElementFinders.getTikiGolfAddPlayerButton().evaluate().isNotEmpty ||
          ElementFinders.getTikiGolfAddPlayerButtonEmptyState().evaluate().isNotEmpty;
    }
    expect(isAddButtonMounted(), isTrue,
        reason:
            '[DIAG random_no_team_ui] Add player button should still be present in Team+Random mode');

    // ── Switch to Manual — Team Count dropdown appears ────────────────────
    await setAssignmentManual(tester);

    expect(teamCountDropdown, findsOneWidget,
        reason:
            '[DIAG random_no_team_ui] Team Count dropdown should appear after switching to Manual');

    // ── Switch back to Random — Team Count dropdown disappears ────────────
    await setAssignmentRandom(tester);

    expect(teamCountDropdown, findsNothing,
        reason:
            '[DIAG random_no_team_ui] Team Count dropdown should disappear again when switching back to Random');
  });
}
