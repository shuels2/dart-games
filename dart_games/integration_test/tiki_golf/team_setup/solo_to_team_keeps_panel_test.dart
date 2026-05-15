// integration_test/tiki_golf/team_setup/solo_to_team_keeps_panel_test.dart
//
// Switching Solo→Team keeps same TeamPlayerListPanel mounted; team UI appears
// if assignment mode is Manual.
//
// Section 12B File 8 — Team setup test 6 (solo_to_team_keeps_panel)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Solo→Team keeps player panel mounted; Manual team UI appears',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Add players while in Solo mode
    await addPlayer(tester, 'Alice');
    await addPlayer(tester, 'Bob');
    await addPlayer(tester, 'Carol');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Verify players visible in Solo mode
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should be visible in Solo mode');
    expect(find.textContaining('Bob'), findsWidgets,
        reason: 'Bob should be visible in Solo mode');

    // Team Count dropdown should NOT be present in Solo mode
    expectTeamCountDropdownAbsent(tester);

    // ── Switch to Team mode ───────────────────────────────────────────────
    await setGameModeTeam(tester);

    // Players still visible (panel stays mounted)
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should still be visible after switching to Team mode');
    expect(find.textContaining('Bob'), findsWidgets,
        reason: 'Bob should still be visible after switching to Team mode');

    // Default is Random → Team Count dropdown still absent
    expectTeamCountDropdownAbsent(tester);

    // ── Switch to Manual assignment ───────────────────────────────────────
    await setAssignmentManual(tester);

    // Now Team Count dropdown should appear
    expectTeamCountDropdownPresent(tester);

    // Players still visible
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should still be visible in Team+Manual mode');
  });
}
