import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Max Darts dropdown: default 3, change to 6, dropdown displays 6',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_max_strokes_dropdown',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Verify the Max Darts dropdown is present on the menu screen
        final dropdownFinder = ElementFinders.getTikiGolfMaxStrokesDropdown();
        expect(dropdownFinder, findsOneWidget,
            reason: 'Max Darts dropdown should be visible on the menu screen');

        // Verify default value is '3'
        expect(find.text('3'), findsWidgets,
            reason: 'Max Darts dropdown should show default value of 3');

        // Change Max Darts to 6 via the shared helper
        await setMaxStrokes(tester, 6);

        // Verify the dropdown now displays '6'
        expect(find.text('6'), findsWidgets,
            reason: 'Max Darts dropdown should display 6 after change');
      },
    );
  });
}
