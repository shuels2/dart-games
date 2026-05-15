// integration_test/tiki_golf/menu_and_settings/max_strokes_persists_test.dart
//
// Verifies Max Strokes dropdown cycling:
//   - Default is 3
//   - Changes correctly to 4, 5, and 6
//   - Can be returned to 3
//
// Note: The provider only persists settings after a game is started.
// This test validates within-session dropdown interactions.
//
// Section 12B File 2 — Test 4 (max_strokes_dropdown_cycle)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Max Strokes dropdown: cycles through all valid values (3, 4, 5, 6)',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_max_strokes_persists',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // ── Verify default is 3 ──────────────────────────────────────────────
        final dropdownFinder = ElementFinders.getTikiGolfMaxStrokesDropdown();
        expect(dropdownFinder, findsOneWidget,
            reason: '[DIAG max_strokes_cycle] Max Strokes dropdown not found');

        expect(find.text('3'), findsWidgets,
            reason: '[DIAG max_strokes_cycle] Default value 3 not shown');

        // ── Change to 4 ──────────────────────────────────────────────────────
        await setMaxStrokes(tester, 4);
        expect(find.text('4'), findsWidgets,
            reason: '[DIAG max_strokes_cycle] Value 4 not showing after change');

        // ── Change to 5 ──────────────────────────────────────────────────────
        await setMaxStrokes(tester, 5);
        expect(find.text('5'), findsWidgets,
            reason: '[DIAG max_strokes_cycle] Value 5 not showing after change');

        // ── Change to 6 ──────────────────────────────────────────────────────
        await setMaxStrokes(tester, 6);
        expect(find.text('6'), findsWidgets,
            reason: '[DIAG max_strokes_cycle] Value 6 not showing after change');

        // ── Return to 3 ──────────────────────────────────────────────────────
        await setMaxStrokes(tester, 3);
        expect(find.text('3'), findsWidgets,
            reason: '[DIAG max_strokes_cycle] Value 3 not restored after cycling back');
      },
    );
  });
}
