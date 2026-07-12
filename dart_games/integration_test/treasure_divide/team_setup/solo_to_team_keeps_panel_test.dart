// integration_test/treasure_divide/team_setup/solo_to_team_keeps_panel_test.dart
//
// Phase 10 gap 1: Switching Solo→Team keeps the same player panel mounted;
// all previously added players are still visible after the mode switch.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Setup: Solo→Team keeps player panel mounted; all players still visible',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToMenu(tester);

    // Add 3 players while in default Solo mode
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
    expect(find.textContaining('Carol'), findsWidgets,
        reason: 'Carol should be visible in Solo mode');

    // ── Switch to Team mode ───────────────────────────────────────────────────
    await setGameModeTeam(tester);

    // All 3 players must still be visible (panel stays mounted across mode switch)
    expect(find.textContaining('Alice'), findsWidgets,
        reason: 'Alice should still be visible after switching to Team mode');
    expect(find.textContaining('Bob'), findsWidgets,
        reason: 'Bob should still be visible after switching to Team mode');
    expect(find.textContaining('Carol'), findsWidgets,
        reason: 'Carol should still be visible after switching to Team mode');

    // Assignment mode toggle must be present in Team mode
    expectAssignmentTogglePresent(tester);
  });
}
