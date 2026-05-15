// integration_test/tiki_golf/team_setup/manual_to_random_toggle_test.dart
//
// Switching Manual → Random hides Team Count dropdown and "Assign team" buttons.
//
// Section 12B File 8 — Team setup test 5 (manual_to_random_toggle)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Switching Manual→Random hides Team Count dropdown and Assign team buttons',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_team_setup_manual_to_random_toggle',
      () async {
        await UITestHelpers.resetServerState();
        await navigateToMenu(tester);

        // Start in Team+Manual mode
        await setGameModeTeam(tester);
        await setAssignmentManual(tester);

        // Add 2 players
        await addPlayer(tester, 'Alice');
        await addPlayer(tester, 'Bob');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Verify Manual UI is present
        expectTeamCountDropdownPresent(tester);
        // "Assign team" buttons present in Manual mode (exact text to avoid "Team Assignment" label)
        expect(find.text('Assign team'), findsWidgets,
            reason: '"Assign team" buttons should be present in Manual mode');

        // ── Switch to Random ──────────────────────────────────────────────────
        await setAssignmentRandom(tester);

        // Team Count dropdown should disappear
        expectTeamCountDropdownAbsent(tester);

        // "Assign team" buttons should disappear (exact text match to avoid "Team Assignment" label)
        expect(find.text('Assign team'), findsNothing,
            reason: '"Assign team" buttons should be hidden after switching to Random');

        // Player panel still mounted (add button accessible)
        final addBtnPresent =
            ElementFinders.getTikiGolfAddPlayerButton().evaluate().isNotEmpty ||
            ElementFinders.getTikiGolfAddPlayerButtonEmptyState()
                .evaluate()
                .isNotEmpty;
        expect(addBtnPresent, isTrue,
            reason: 'Player list panel should remain mounted after toggle');
      },
    );
  });
}
