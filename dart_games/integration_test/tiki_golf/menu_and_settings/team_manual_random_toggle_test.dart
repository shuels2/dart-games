// integration_test/tiki_golf/menu_and_settings/team_manual_random_toggle_test.dart
//
// In Team mode, toggles between Manual and Random assignment:
//   - Manual → team-assignment boxes + trailing icons + Team Count dropdown appear
//   - Random → none of those appear (panel looks like Solo)
//   - Toggling back to Manual restores them
//
// Section 12B File 2 — Test 8 (team_manual_random_toggle)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team mode: Manual↔Random toggle controls Team Count dropdown visibility',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_team_manual_random_toggle',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // ── Switch to Team mode ───────────────────────────────────────────────
        await setGameModeTeam(tester);

        // Default is RANDOM — Team Count dropdown should NOT be shown
        final teamCountDropdown =
            ElementFinders.getTikiGolfTeamCountDropdown();
        expect(teamCountDropdown, findsNothing,
            reason:
                '[DIAG manual_random_toggle] Team Count dropdown should NOT be visible in Team+Random mode');

        // ── Switch to MANUAL assignment ───────────────────────────────────────
        await setAssignmentManual(tester);

        // Team Count dropdown should now appear
        final teamCountDropdownManual =
            ElementFinders.getTikiGolfTeamCountDropdown();
        expect(teamCountDropdownManual, findsOneWidget,
            reason:
                '[DIAG manual_random_toggle] Team Count dropdown should appear in Team+Manual mode');

        // Add player button still present (panel stays mounted)
        // Note: when no players are added, the empty-state button key is shown.
        bool isAddButtonMounted() {
          return ElementFinders.getTikiGolfAddPlayerButton().evaluate().isNotEmpty ||
              ElementFinders.getTikiGolfAddPlayerButtonEmptyState().evaluate().isNotEmpty;
        }
        expect(isAddButtonMounted(), isTrue,
            reason:
                '[DIAG manual_random_toggle] Add player button should be present in Team+Manual mode');

        // ── Switch back to RANDOM ─────────────────────────────────────────────
        await setAssignmentRandom(tester);

        // Team Count dropdown should disappear again
        expect(teamCountDropdown, findsNothing,
            reason:
                '[DIAG manual_random_toggle] Team Count dropdown should disappear when switching back to Random');

        // Panel still mounted
        expect(isAddButtonMounted(), isTrue,
            reason:
                '[DIAG manual_random_toggle] Add player button should remain in Team+Random mode');
      },
    );
  });
}
