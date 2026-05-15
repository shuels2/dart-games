// integration_test/tiki_golf/team_setup/team_to_solo_keeps_panel_test.dart
//
// Switching Team→Solo hides all team UI; selected player list intact.
//
// Section 12B File 8 — Team setup test 7 (team_to_solo_keeps_panel)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Team→Solo hides all team UI; player list remains intact',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Start in Team+Manual mode with players
    await setGameModeTeam(tester);
    await setAssignmentManual(tester);

    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Verify Team+Manual UI present
    expectTeamCountDropdownPresent(tester);
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should be visible in Team+Manual mode');

    // ── Switch back to Solo ───────────────────────────────────────────────
    await setGameModeSolo(tester);

    // Team Count dropdown should disappear
    expectTeamCountDropdownAbsent(tester);

    // Players still listed (panel stays mounted, player selection preserved)
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should remain visible after switching to Solo mode');
    expect(find.textContaining('Bob'), findsWidgets,
        reason: 'Bob should remain visible after switching to Solo mode');
    expect(find.textContaining('Carol'), findsWidgets,
        reason: 'Carol should remain visible after switching to Solo mode');

    // Assignment mode toggle is now shown at 50% opacity but still present
    // (rendered but non-interactive in Solo mode)
    expect(ElementFinders.getTikiGolfAssignmentModeToggle(), findsOneWidget,
        reason:
            'Assignment mode toggle should still render in Solo mode (grayed out) — '
            'it is AbsorbPointer wrapped, not removed from widget tree');
  });
}
