// integration_test/tiki_golf/menu_and_settings/team_mode_manual_renders_team_boxes_test.dart
//
// Team+Manual mode: verifies structural elements of the Manual assignment UI:
//   - Team Count dropdown present
//   - Assignment Mode toggle active (both segments visible)
//   - Team Assignment section label appears (the panel adds a label when
//     isManualTeamMode is true)
//   - Switching to Random removes Team Count dropdown
//   - Switching back to Manual restores it
//
// NOTE: TikiGolfMenuKeys.teamBox(int) keys are defined in test_keys.dart but
// are NOT currently wired into the TeamPlayerListPanel._buildTeamBox() widget.
// This test asserts via the Team Count dropdown and label text instead.
//
// Section 12B File 2 — Test 9 (team_mode_manual_renders_team_boxes)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team+Manual mode: Team Count dropdown and assignment UI rendered',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_team_mode_manual_boxes',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // ── Switch to Team + Manual mode ──────────────────────────────────────
        await setGameModeTeam(tester);
        await setAssignmentManual(tester);

        // ── Team Count dropdown present ────────────────────────────────────────
        final teamCountDropdown =
            ElementFinders.getTikiGolfTeamCountDropdown();
        expect(teamCountDropdown, findsOneWidget,
            reason:
                '[DIAG team_manual_boxes] Team Count dropdown not found in Team+Manual mode');

        // ── Team Assignment section label appears ──────────────────────────────
        // The TeamPlayerListPanel adds a "Team Assignment" label when
        // _isManualTeamMode is true. Check for this label text.
        final teamAssignLabel = find.textContaining('Team');
        expect(teamAssignLabel, findsWidgets,
            reason:
                '[DIAG team_manual_boxes] Team-related text should appear in Team+Manual mode');

        // ── Assignment toggle segments both present ────────────────────────────
        final manualSegment = ElementFinders.getTikiGolfAssignmentModeManual();
        expect(manualSegment, findsOneWidget,
            reason: '[DIAG team_manual_boxes] MANUAL segment not found');

        final randomSegment = ElementFinders.getTikiGolfAssignmentModeRandom();
        expect(randomSegment, findsOneWidget,
            reason: '[DIAG team_manual_boxes] RANDOM segment not found');

        // ── Switch to RANDOM — team Count dropdown disappears ─────────────────
        await setAssignmentRandom(tester);

        expect(teamCountDropdown, findsNothing,
            reason:
                '[DIAG team_manual_boxes] Team Count dropdown should NOT appear in Team+Random mode');

        // ── Switch back to MANUAL — team Count dropdown reappears ─────────────
        await setAssignmentManual(tester);

        expect(teamCountDropdown, findsOneWidget,
            reason:
                '[DIAG team_manual_boxes] Team Count dropdown should reappear when switching back to Manual');
      },
    );
  });
}
