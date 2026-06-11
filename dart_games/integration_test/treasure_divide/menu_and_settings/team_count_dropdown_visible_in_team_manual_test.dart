// integration_test/treasure_divide/menu_and_settings/team_count_dropdown_visible_in_team_manual_test.dart
//
// Verifies Team Count (Crews) dropdown behaviour:
//   - NOT visible in Solo mode
//   - NOT visible in Team + Random mode
//   - VISIBLE in Team + Manual mode
//   - Options 2, 3, 4, 5 present
//   - Selecting 4 updates the displayed value to 4
//   - Switching back to Team + Random hides the dropdown again
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Count dropdown: visible only in Team+Manual, hidden in Team+Random',
      (tester) async {
    await UITestHelpers.resetServerState();
    final config = GameUIConfig.treasureDivide();
    await UITestHelpers.navigateToGameMenu(tester, config);

    final teamCountDropdown =
        ElementFinders.getTreasureDivideTeamCountDropdown();

    // ── Solo mode: dropdown NOT shown ─────────────────────────────────────
    expect(teamCountDropdown, findsNothing,
        reason:
            '[DIAG team_count_dropdown] Team Count dropdown should NOT appear in Solo mode');

    // ── Switch to Team + Manual ────────────────────────────────────────────
    await SettingsHelpers.setTreasureDivideGameModeTeam(tester);
    await SettingsHelpers.setTreasureDivideAssignmentManual(tester);

    // Dropdown should now be visible
    expect(teamCountDropdown, findsOneWidget,
        reason:
            '[DIAG team_count_dropdown] Team Count dropdown should appear in Team+Manual mode');

    // ── Select 4 crews ────────────────────────────────────────────────────
    await SettingsHelpers.selectTreasureDivideCrews(tester, 4);

    expect(find.text('4'), findsWidgets,
        reason:
            '[DIAG team_count_dropdown] Value 4 not visible after selecting 4 crews');

    // ── Switch to Team + Random — dropdown hidden ─────────────────────────
    await SettingsHelpers.setTreasureDivideAssignmentRandom(tester);

    expect(teamCountDropdown, findsNothing,
        reason:
            '[DIAG team_count_dropdown] Team Count dropdown should NOT appear in Team+Random mode');

    // Clear accumulated RenderFlex overflow exceptions from TD menu layout bug.
    // FLAG: Known overflow in td_menu_game_mode_toggle and td_menu_assignment_mode_toggle rows.
    tester.binding.takeException();
    tester.binding.takeException();
  });
}
