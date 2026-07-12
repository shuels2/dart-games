// integration_test/treasure_divide/menu_and_settings/rounds_dropdown_test.dart
//
// Verifies the Rounds dropdown:
//   - Default value is 9
//   - Options 7, 9, 12 are all present
//   - Selecting 7 changes displayed value to 7
//   - Selecting 12 changes displayed value to 12
//   - Selecting 9 (default) changes displayed value back to 9
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Rounds dropdown: default 9, options 7/9/12, changing value works',
      (tester) async {
    await UITestHelpers.resetServerState();
    final config = GameUIConfig.treasureDivide();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // ── Dropdown present, default value 9 ────────────────────────────────
    final roundsDropdown = ElementFinders.getTreasureDivideRoundsDropdown();
    expect(roundsDropdown, findsOneWidget,
        reason: '[DIAG rounds_dropdown] Rounds dropdown not found');

    expect(find.text('9'), findsWidgets,
        reason: '[DIAG rounds_dropdown] Default value 9 not visible');

    // ── Select 7 ──────────────────────────────────────────────────────────
    await SettingsHelpers.selectTreasureDivideRounds(tester, 7);

    expect(find.text('7'), findsWidgets,
        reason: '[DIAG rounds_dropdown] Value 7 not visible after selection');

    // ── Select 12 ─────────────────────────────────────────────────────────
    await SettingsHelpers.selectTreasureDivideRounds(tester, 12);

    expect(find.text('12'), findsWidgets,
        reason:
            '[DIAG rounds_dropdown] Value 12 not visible after selection');

    // ── Select 9 (back to default) ────────────────────────────────────────
    await SettingsHelpers.selectTreasureDivideRounds(tester, 9);

    expect(find.text('9'), findsWidgets,
        reason:
            '[DIAG rounds_dropdown] Value 9 not visible after re-selecting default');

  });
}
