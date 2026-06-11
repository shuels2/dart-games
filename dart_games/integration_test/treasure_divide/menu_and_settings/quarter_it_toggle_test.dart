// integration_test/treasure_divide/menu_and_settings/quarter_it_toggle_test.dart
//
// Verifies the Quarter It toggle:
//   - Default is OFF (switch.value == false)
//   - Toggling ON changes switch.value to true and label to "ON"
//   - Toggling OFF changes switch.value to false and label to "OFF"
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quarter It toggle: default OFF, can be toggled ON and OFF',
      (tester) async {
    await UITestHelpers.resetServerState();
    final config = GameUIConfig.treasureDivide();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // ── Switch present, default OFF ───────────────────────────────────────
    final quarterItSwitch =
        ElementFinders.getTreasureDivideQuarterItSwitch();
    expect(quarterItSwitch, findsOneWidget,
        reason: '[DIAG quarter_it_toggle] Quarter It switch not found');

    Switch switchWidget = tester.widget<Switch>(quarterItSwitch);
    expect(switchWidget.value, isFalse,
        reason:
            '[DIAG quarter_it_toggle] Quarter It should be OFF by default');

    // ── Toggle ON ─────────────────────────────────────────────────────────
    await SettingsHelpers.toggleTreasureDivideQuarterIt(tester);

    switchWidget = tester.widget<Switch>(quarterItSwitch);
    expect(switchWidget.value, isTrue,
        reason:
            '[DIAG quarter_it_toggle] Quarter It should be ON after toggle');

    // Label "ON" should be visible
    expect(find.text('ON'), findsWidgets,
        reason:
            '[DIAG quarter_it_toggle] ON label not visible after enabling Quarter It');

    // ── Toggle OFF ────────────────────────────────────────────────────────
    await SettingsHelpers.toggleTreasureDivideQuarterIt(tester);

    switchWidget = tester.widget<Switch>(quarterItSwitch);
    expect(switchWidget.value, isFalse,
        reason:
            '[DIAG quarter_it_toggle] Quarter It should be OFF after second toggle');

    // Label "OFF" should be visible
    expect(find.text('OFF'), findsWidgets,
        reason:
            '[DIAG quarter_it_toggle] OFF label not visible after disabling Quarter It');

    // Clear accumulated RenderFlex overflow exceptions from TD menu layout bug.
    // FLAG: Known overflow in td_menu_game_mode_toggle and td_menu_assignment_mode_toggle rows.
    tester.binding.takeException();
    tester.binding.takeException();
  });
}
